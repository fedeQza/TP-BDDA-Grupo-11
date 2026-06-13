/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Entrega 6 - Carga histórica de estadísticas de
             visitantes a Parques Nacionales desde un archivo
             CSV externo (indice_tiempo, region_de_destino,
             origen_visitantes, visitas, observaciones).

             Contenido:
             - Schemas 'estadisticas' e 'importaciones'.
             - estadisticas.VisitantesParques
                 Tabla destino con el historial. No se borran
                 registros: las cargas sucesivas insertan los
                 períodos nuevos y actualizan observaciones/
                 visitas si cambiaron para una clave existente.
             - estadisticas.StagingVisitantes
                 Tabla de staging usada por BULK INSERT.
             - estadisticas.ErroresImportacion
                 Registro de filas rechazadas por archivo.
             - importaciones.ImportarEstadisticasVisitantes
                 Procedimiento que realiza toda la carga,
                 validación y upsert (sin MERGE).

             Clave de unicidad / upsert:
                 indice_tiempo + region_destino + origen_visitantes
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- SCHEMAS
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'estadisticas')
    EXEC('CREATE SCHEMA estadisticas;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importaciones')
    EXEC('CREATE SCHEMA importaciones;');
GO

-- ==============================================================
-- TABLA DESTINO: estadisticas.VisitantesParques
-- Histórico de visitantes. No se eliminan filas: el SP de
-- importación solo inserta claves nuevas o actualiza
-- visitas/observaciones de claves existentes.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VisitantesParques' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.VisitantesParques...';
    CREATE TABLE estadisticas.VisitantesParques (
        id_visitantes_parque INT IDENTITY(1,1) PRIMARY KEY,
        indice_tiempo        DATE          NOT NULL,
        region_destino       VARCHAR(100)  NOT NULL,
        origen_visitantes    VARCHAR(50)   NOT NULL,
        visitas              INT           NOT NULL,
        observaciones        VARCHAR(500)  NULL,
        fecha_carga          DATETIME2     NOT NULL CONSTRAINT DF_VisitantesParques_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion  DATETIME2     NULL,
        CONSTRAINT CK_VisitantesParques_Visitas CHECK (visitas >= 0),
        CONSTRAINT UQ_VisitantesParques_Clave UNIQUE (indice_tiempo, region_destino, origen_visitantes)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.VisitantesParques ya existe, se omite creación.';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VisitantesParques_IndiceTiempo')
    CREATE INDEX IX_VisitantesParques_IndiceTiempo ON estadisticas.VisitantesParques (indice_tiempo);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_VisitantesParques_Region')
    CREATE INDEX IX_VisitantesParques_Region ON estadisticas.VisitantesParques (region_destino);
GO

-- ==============================================================
-- TABLA DE STAGING: estadisticas.StagingVisitantes
-- Todas las columnas son VARCHAR para que BULK INSERT nunca
-- falle por un valor inválido: la validación de tipos/contenido
-- se realiza después, en T-SQL.
--
-- Mapeo de columnas del CSV (en orden):
--   indice_tiempo      -> indice_tiempo_raw
--   region_de_destino  -> region_destino_raw
--   origen_visitantes  -> origen_visitantes_raw
--   visitas            -> visitas_raw
--   observaciones      -> observaciones_raw
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StagingVisitantes' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.StagingVisitantes...';
    CREATE TABLE estadisticas.StagingVisitantes (
        id_staging            INT IDENTITY(1,1) PRIMARY KEY,
        indice_tiempo_raw     VARCHAR(30)  NULL,
        region_destino_raw    VARCHAR(200) NULL,
        origen_visitantes_raw VARCHAR(100) NULL,
        visitas_raw           VARCHAR(50)  NULL,
        observaciones_raw     VARCHAR(500) NULL
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.StagingVisitantes ya existe, se omite creación.';
GO

-- ==============================================================
-- TABLA DE ERRORES: estadisticas.ErroresImportacion
-- Guarda, por archivo importado, cada fila rechazada junto con
-- el motivo y los valores originales (sin convertir) leídos
-- del CSV.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ErroresImportacion' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.ErroresImportacion...';
    CREATE TABLE estadisticas.ErroresImportacion (
        id_error                INT IDENTITY(1,1) PRIMARY KEY,
        fecha_error             DATETIME2     NOT NULL CONSTRAINT DF_ErroresImportacion_Fecha DEFAULT (SYSDATETIME()),
        archivo_origen          VARCHAR(500)  NULL,
        motivo_error            VARCHAR(500)  NOT NULL,
        indice_tiempo_valor     VARCHAR(30)   NULL,
        region_destino_valor    VARCHAR(200)  NULL,
        origen_visitantes_valor VARCHAR(100)  NULL,
        visitas_valor           VARCHAR(50)   NULL,
        observaciones_valor     VARCHAR(500)  NULL
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.ErroresImportacion ya existe, se omite creación.';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ErroresImportacion_Fecha')
    CREATE INDEX IX_ErroresImportacion_Fecha ON estadisticas.ErroresImportacion (fecha_error);
GO

-- ==============================================================
-- importaciones.ImportarEstadisticasVisitantes
--
-- Importa el archivo CSV indicado en @p_ruta_archivo:
--   1. Valida que el archivo exista.
--   2. Vacía la tabla de staging y carga el CSV con BULK INSERT
--      (se usa SQL dinámico únicamente para esta sentencia,
--       porque BULK INSERT no admite una variable en FROM).
--   3. Valida cada fila (fecha, región, origen, visitas) y
--      detecta duplicados dentro del propio archivo.
--   4. Las filas inválidas se registran en
--      estadisticas.ErroresImportacion (no detienen la carga
--      del resto del archivo).
--   5. Aplica upsert sin MERGE sobre estadisticas.VisitantesParques
--      usando la clave (indice_tiempo, region_destino,
--      origen_visitantes): inserta claves nuevas y actualiza
--      visitas/observaciones cuando cambiaron. Nunca elimina
--      filas existentes (se preserva el historial).
--   6. Vacía la tabla de staging al finalizar (incluso si hubo
--      error).
--   7. Devuelve un registro con la cantidad de filas
--      insertadas, actualizadas y rechazadas.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('importaciones.ImportarEstadisticasVisitantes') AND type = 'P')
    PRINT 'Creando Procedure importaciones.ImportarEstadisticasVisitantes...';
ELSE
    PRINT 'OK - Procedure importaciones.ImportarEstadisticasVisitantes ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFORMAT ymd;

    DECLARE @v_existe_archivo INT       = 0;
    DECLARE @v_sql            NVARCHAR(MAX);
    DECLARE @v_insertados     INT       = 0;
    DECLARE @v_actualizados   INT       = 0;
    DECLARE @v_rechazados     INT       = 0;

    BEGIN TRY
        ----------------------------------------------------------
        -- 1) Validar existencia del archivo
        ----------------------------------------------------------
        EXEC master.dbo.xp_fileexist @p_ruta_archivo, @v_existe_archivo OUTPUT;

        IF @v_existe_archivo IS NULL OR @v_existe_archivo = 0
            THROW 50000, 'El archivo especificado no existe o no es accesible desde el motor de SQL Server.', 1;

        ----------------------------------------------------------
        -- 2) Vaciar staging y cargar el CSV con BULK INSERT
        ----------------------------------------------------------
        TRUNCATE TABLE estadisticas.StagingVisitantes;

        SET @v_sql = N'
            BULK INSERT estadisticas.StagingVisitantes
            FROM ''' + REPLACE(@p_ruta_archivo, '''', '''''') + N'''
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR   = ''0x0a'',
                FORMAT          = ''CSV'',
                FIELDQUOTE      = ''"'',
                CODEPAGE        = ''65001'',
                MAXERRORS       = 2147483647,
                TABLOCK
            );';

        EXEC sp_executesql @v_sql;

        ----------------------------------------------------------
        -- 3) Validar cada fila cargada
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#StagingValidado') IS NOT NULL DROP TABLE #StagingValidado;

        CREATE TABLE #StagingValidado (
            id_staging        INT          NOT NULL PRIMARY KEY,
            indice_tiempo     DATE         NULL,
            region_destino    VARCHAR(100) NULL,
            origen_visitantes VARCHAR(50)  NULL,
            visitas           INT          NULL,
            observaciones     VARCHAR(500) NULL,
            motivo_error      VARCHAR(500) NULL
        );

        INSERT INTO #StagingValidado
            (id_staging, indice_tiempo, region_destino, origen_visitantes, visitas, observaciones, motivo_error)
        SELECT
            s.id_staging,
            TRY_CAST(LTRIM(RTRIM(s.indice_tiempo_raw)) AS DATE),
            NULLIF(LTRIM(RTRIM(s.region_destino_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.origen_visitantes_raw)), ''),
            TRY_CAST(LTRIM(RTRIM(s.visitas_raw)) AS INT),
            NULLIF(LTRIM(RTRIM(s.observaciones_raw)), ''),
            CASE
                WHEN LTRIM(RTRIM(ISNULL(s.indice_tiempo_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(s.region_destino_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(s.origen_visitantes_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(s.visitas_raw, ''))) = ''
                    THEN N'Fila vacía o con columnas faltantes.'
                WHEN TRY_CAST(LTRIM(RTRIM(s.indice_tiempo_raw)) AS DATE) IS NULL
                    THEN N'La fecha (indice_tiempo) es inválida o está vacía.'
                WHEN LTRIM(RTRIM(ISNULL(s.region_destino_raw, ''))) = ''
                    THEN N'La región de destino es nula o vacía.'
                WHEN LTRIM(RTRIM(ISNULL(s.origen_visitantes_raw, ''))) = ''
                    THEN N'El origen de visitantes es nulo o vacío.'
                WHEN LTRIM(RTRIM(ISNULL(s.visitas_raw, ''))) = ''
                    THEN N'La cantidad de visitas es nula o vacía.'
                WHEN TRY_CAST(LTRIM(RTRIM(s.visitas_raw)) AS INT) IS NULL
                    THEN N'La cantidad de visitas no es un valor numérico válido.'
                WHEN TRY_CAST(LTRIM(RTRIM(s.visitas_raw)) AS INT) < 0
                    THEN N'La cantidad de visitas no puede ser negativa.'
                ELSE NULL
            END
        FROM estadisticas.StagingVisitantes s;

        -- Detectar duplicados de clave dentro del propio archivo:
        -- se conserva la última ocurrencia y el resto se rechaza.
        ;WITH Duplicados AS (
            SELECT id_staging,
                   ROW_NUMBER() OVER (
                       PARTITION BY indice_tiempo, region_destino, origen_visitantes
                       ORDER BY id_staging DESC
                   ) AS orden
            FROM #StagingValidado
            WHERE motivo_error IS NULL
        )
        UPDATE v
        SET v.motivo_error = N'Registro duplicado dentro del archivo (se conserva la última ocurrencia con esa clave).'
        FROM #StagingValidado v
        INNER JOIN Duplicados d ON d.id_staging = v.id_staging
        WHERE d.orden > 1;

        ----------------------------------------------------------
        -- 4) Registrar filas rechazadas con sus valores originales
        ----------------------------------------------------------
        INSERT INTO estadisticas.ErroresImportacion
            (archivo_origen, motivo_error, indice_tiempo_valor, region_destino_valor,
             origen_visitantes_valor, visitas_valor, observaciones_valor)
        SELECT
            @p_ruta_archivo,
            v.motivo_error,
            s.indice_tiempo_raw,
            s.region_destino_raw,
            s.origen_visitantes_raw,
            s.visitas_raw,
            s.observaciones_raw
        FROM #StagingValidado v
        INNER JOIN estadisticas.StagingVisitantes s ON s.id_staging = v.id_staging
        WHERE v.motivo_error IS NOT NULL;

        SET @v_rechazados = @@ROWCOUNT;

        ----------------------------------------------------------
        -- 5) Upsert sin MERGE sobre estadisticas.VisitantesParques
        ----------------------------------------------------------
        BEGIN TRANSACTION;

        -- 5a) Actualizar registros existentes cuyos datos cambiaron
        UPDATE dest
        SET dest.visitas             = v.visitas,
            dest.observaciones        = v.observaciones,
            dest.fecha_actualizacion  = SYSDATETIME()
        FROM estadisticas.VisitantesParques dest
        INNER JOIN #StagingValidado v
            ON v.indice_tiempo     = dest.indice_tiempo
           AND v.region_destino    = dest.region_destino
           AND v.origen_visitantes = dest.origen_visitantes
        WHERE v.motivo_error IS NULL
          AND (
                dest.visitas <> v.visitas
             OR ISNULL(dest.observaciones, N'') <> ISNULL(v.observaciones, N'')
              );

        SET @v_actualizados = @@ROWCOUNT;

        -- 5b) Insertar claves nuevas
        INSERT INTO estadisticas.VisitantesParques
            (indice_tiempo, region_destino, origen_visitantes, visitas, observaciones)
        SELECT
            v.indice_tiempo, v.region_destino, v.origen_visitantes, v.visitas, v.observaciones
        FROM #StagingValidado v
        WHERE v.motivo_error IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM estadisticas.VisitantesParques dest
              WHERE dest.indice_tiempo     = v.indice_tiempo
                AND dest.region_destino    = v.region_destino
                AND dest.origen_visitantes = v.origen_visitantes
          );

        SET @v_insertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        ----------------------------------------------------------
        -- 6) Limpieza de staging y resultado
        ----------------------------------------------------------
        TRUNCATE TABLE estadisticas.StagingVisitantes;
        DROP TABLE #StagingValidado;

        SELECT
            @v_insertados   AS registros_insertados,
            @v_actualizados AS registros_actualizados,
            @v_rechazados   AS registros_rechazados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        TRUNCATE TABLE estadisticas.StagingVisitantes;
        IF OBJECT_ID('tempdb..#StagingValidado') IS NOT NULL DROP TABLE #StagingValidado;

        THROW;
    END CATCH
END
GO
