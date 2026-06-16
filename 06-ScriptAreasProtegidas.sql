/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       16/06/2026
Descripción: Entrega 6 - Carga de áreas protegidas por jurisdicción
             desde un archivo JSON externo
             (areas-protegidas-por-jurisdiccion.json).

             Contenido:
             - estadisticas.AreasProtegidasJurisdiccion
                 Tabla destino. No se eliminan registros: las
                 cargas sucesivas insertan jurisdicciones nuevas
                 y actualizan los datos si cambiaron para una
                 clave existente.
             - estadisticas.ErroresImportacion
                 Tabla compartida de errores (se crea aquí si no
                 existe; también la crea 04-ScriptEstadisticasVisitantes.sql).
             - importaciones.ImportarAreasProtegidas
                 Procedimiento que realiza toda la carga,
                 validación y upsert (sin MERGE).

             Clave de unicidad / upsert:
                 jurisdiccion

             Orden de ejecución:
               1. 01-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. Este script (puede ejecutarse sin necesidad de 04)
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
-- TABLA COMPARTIDA DE ERRORES: estadisticas.ErroresImportacion
-- Se crea aquí si no fue creada por 04-ScriptEstadisticasVisitantes.sql
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ErroresImportacion' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.ErroresImportacion...';
    CREATE TABLE estadisticas.ErroresImportacion (
        id_error                INT IDENTITY(1,1) PRIMARY KEY,
        fecha_error             DATETIME2    NOT NULL CONSTRAINT DF_ErroresImportacion_Fecha DEFAULT (SYSDATETIME()),
        archivo_origen          VARCHAR(500) NULL,
        motivo_error            VARCHAR(500) NOT NULL,
        indice_tiempo_valor     VARCHAR(500) NULL,
        region_destino_valor    VARCHAR(500) NULL,
        origen_visitantes_valor VARCHAR(500) NULL,
        visitas_valor           VARCHAR(500) NULL,
        observaciones_valor     VARCHAR(500) NULL
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.ErroresImportacion ya existe, se omite creación.';
GO

-- ==============================================================
-- TABLA DESTINO: estadisticas.AreasProtegidasJurisdiccion
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AreasProtegidasJurisdiccion' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.AreasProtegidasJurisdiccion...';
    CREATE TABLE estadisticas.AreasProtegidasJurisdiccion (
        id_area                        INT IDENTITY(1,1) PRIMARY KEY,
        jurisdiccion                   NVARCHAR(100) NOT NULL,
        total_cantidad                 INT           NULL,
        ap_nac                         INT           NULL,
        ap_prov                        INT           NULL,
        ap_desig_inter                 INT           NULL,
        total_ha                       INT           NULL,
        terrestre_ha                   INT           NULL,
        marino_ha                      INT           NULL,
        porcentaje_terrestre_protegido DECIMAL(6,2)  NULL,
        fecha_carga                    DATETIME2     NOT NULL CONSTRAINT DF_AreasProtegidas_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion            DATETIME2     NULL,
        CONSTRAINT UQ_AreasProtegidas_Jurisdiccion UNIQUE (jurisdiccion)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.AreasProtegidasJurisdiccion ya existe, se omite creación.';
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('estadisticas.AreasProtegidasJurisdiccion') AND name = 'fecha_carga')
    ALTER TABLE estadisticas.AreasProtegidasJurisdiccion
        ADD fecha_carga DATETIME2 NOT NULL CONSTRAINT DF_AreasProtegidas_FechaCarga DEFAULT (SYSDATETIME());
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('estadisticas.AreasProtegidasJurisdiccion') AND name = 'fecha_actualizacion')
    ALTER TABLE estadisticas.AreasProtegidasJurisdiccion
        ADD fecha_actualizacion DATETIME2 NULL;
GO

-- ==============================================================
-- importaciones.ImportarAreasProtegidas
--
-- Importa el archivo JSON indicado en @p_ruta_archivo:
--   1. Valida que el archivo exista.
--   2. Lee el JSON con OPENROWSET + OPENJSON (SQL dinámico
--      porque OPENROWSET no acepta una variable en el path).
--   3. Valida cada fila (jurisdicción no vacía, cantidades
--      no negativas) y detecta duplicados dentro del archivo.
--   4. Filas inválidas -> estadisticas.ErroresImportacion.
--   5. Upsert sin MERGE sobre AreasProtegidasJurisdiccion
--      (clave: jurisdiccion): inserta jurisdicciones nuevas
--      y actualiza datos cuando cambiaron. Nunca elimina filas.
--   6. Devuelve registros_insertados, actualizados y rechazados.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('importaciones.ImportarAreasProtegidas') AND type = 'P')
    PRINT 'Creando Procedure importaciones.ImportarAreasProtegidas...';
ELSE
    PRINT 'OK - Procedure importaciones.ImportarAreasProtegidas ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE importaciones.ImportarAreasProtegidas
    @p_ruta_archivo VARCHAR(500)   -- nombre del archivo (ej.: 'areas-protegidas-por-jurisdiccion.json')
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_ruta_base     VARCHAR(500)  = 'C:\Importaciones\';
    DECLARE @v_ruta_completa VARCHAR(1000) = @v_ruta_base + @p_ruta_archivo;
    DECLARE @v_existe_archivo INT          = 0;
    DECLARE @v_sql            NVARCHAR(MAX);
    DECLARE @v_insertados     INT          = 0;
    DECLARE @v_actualizados   INT          = 0;
    DECLARE @v_rechazados     INT          = 0;

    BEGIN TRY
        ----------------------------------------------------------
        -- 1) Validar existencia del archivo
        ----------------------------------------------------------
        EXEC master.dbo.xp_fileexist @v_ruta_completa, @v_existe_archivo OUTPUT;

        IF @v_existe_archivo IS NULL OR @v_existe_archivo = 0
            THROW 50000, 'El archivo especificado no existe o no es accesible desde el motor de SQL Server.', 1;

        ----------------------------------------------------------
        -- 2) Leer el JSON en tabla temporal
        --    Se usa SQL dinámico porque OPENROWSET no acepta
        --    una variable como path (igual que BULK INSERT).
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#AreasCargadas') IS NOT NULL DROP TABLE #AreasCargadas;

        CREATE TABLE #AreasCargadas (
            jurisdiccion                   NVARCHAR(100) NULL,
            total_cantidad                 INT           NULL,
            ap_nac                         INT           NULL,
            ap_prov                        INT           NULL,
            ap_desig_inter                 INT           NULL,
            total_ha                       INT           NULL,
            terrestre_ha                   INT           NULL,
            marino_ha                      INT           NULL,
            porcentaje_terrestre_protegido DECIMAL(6,2)  NULL
        );

        SET @v_sql = N'
            SELECT jurisdiccion, total_cantidad, ap_nac, ap_prov, ap_desig_inter,
                   total_ha, terrestre_ha, marino_ha, porcentaje_terrestre_protegido
            FROM OPENROWSET(BULK ''' + REPLACE(@v_ruta_completa, '''', '''''') + N''', SINGLE_CLOB) AS j
            CROSS APPLY OPENJSON(BulkColumn)
            WITH (
                jurisdiccion                   NVARCHAR(100) ''$.jurisdiccion'',
                total_cantidad                 INT           ''$.total_cantidad'',
                ap_nac                         INT           ''$.ap_nac'',
                ap_prov                        INT           ''$.ap_prov'',
                ap_desig_inter                 INT           ''$.ap_desig_inter'',
                total_ha                       INT            ''$.total_ha'',
                terrestre_ha                   INT            ''$.terrestre_ha'',
                marino_ha                      INT            ''$.marino_ha'',
                porcentaje_terrestre_protegido DECIMAL(6,2)  ''$.porcentaje_terrestre_protegido''
            );';

        INSERT INTO #AreasCargadas
        EXEC sp_executesql @v_sql;

        ----------------------------------------------------------
        -- 3) Validar cada fila cargada
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#AreasValidado') IS NOT NULL DROP TABLE #AreasValidado;

        CREATE TABLE #AreasValidado (
            row_num                        INT           NOT NULL PRIMARY KEY,
            jurisdiccion                   NVARCHAR(100) NULL,
            total_cantidad                 INT           NULL,
            ap_nac                         INT           NULL,
            ap_prov                        INT           NULL,
            ap_desig_inter                 INT           NULL,
            total_ha                       INT           NULL,
            terrestre_ha                   INT           NULL,
            marino_ha                      INT           NULL,
            porcentaje_terrestre_protegido DECIMAL(6,2)  NULL,
            motivo_error                   VARCHAR(500)  NULL
        );

        INSERT INTO #AreasValidado
            (row_num, jurisdiccion, total_cantidad, ap_nac, ap_prov, ap_desig_inter,
             total_ha, terrestre_ha, marino_ha, porcentaje_terrestre_protegido, motivo_error)
        SELECT
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            jurisdiccion,
            total_cantidad,
            ap_nac,
            ap_prov,
            ap_desig_inter,
            total_ha,
            terrestre_ha,
            marino_ha,
            porcentaje_terrestre_protegido,
            CASE
                WHEN LTRIM(RTRIM(ISNULL(CAST(jurisdiccion AS VARCHAR(100)), ''))) = ''
                    THEN N'La jurisdicción es nula o vacía.'
                WHEN total_cantidad IS NOT NULL AND total_cantidad < 0
                    THEN N'El total de áreas protegidas no puede ser negativo.'
                WHEN total_ha IS NOT NULL AND total_ha < 0
                    THEN N'El total de hectáreas no puede ser negativo.'
                ELSE NULL
            END
        FROM #AreasCargadas;

        -- Detectar duplicados dentro del archivo: conservar la última ocurrencia
        ;WITH Duplicados AS (
            SELECT row_num,
                   ROW_NUMBER() OVER (
                       PARTITION BY jurisdiccion
                       ORDER BY row_num DESC
                   ) AS orden
            FROM #AreasValidado
            WHERE motivo_error IS NULL
        )
        UPDATE v
        SET v.motivo_error = N'Jurisdicción duplicada dentro del archivo (se conserva la última ocurrencia).'
        FROM #AreasValidado v
        INNER JOIN Duplicados d ON d.row_num = v.row_num
        WHERE d.orden > 1;

        ----------------------------------------------------------
        -- 4) Registrar filas rechazadas
        ----------------------------------------------------------
        INSERT INTO estadisticas.ErroresImportacion
            (archivo_origen, motivo_error, indice_tiempo_valor, region_destino_valor,
             origen_visitantes_valor, visitas_valor, observaciones_valor)
        SELECT
            @v_ruta_completa,
            v.motivo_error,
            CAST(v.jurisdiccion   AS VARCHAR(500)),
            CAST(v.total_cantidad AS VARCHAR(500)),
            CAST(v.ap_nac         AS VARCHAR(500)),
            CAST(v.total_ha       AS VARCHAR(500)),
            NULL
        FROM #AreasValidado v
        WHERE v.motivo_error IS NOT NULL;

        SET @v_rechazados = @@ROWCOUNT;

        ----------------------------------------------------------
        -- 5) Upsert sin MERGE sobre AreasProtegidasJurisdiccion
        ----------------------------------------------------------
        BEGIN TRANSACTION;

        -- 5a) Actualizar registros existentes cuyos datos cambiaron
        UPDATE dest
        SET dest.total_cantidad                 = v.total_cantidad,
            dest.ap_nac                         = v.ap_nac,
            dest.ap_prov                        = v.ap_prov,
            dest.ap_desig_inter                 = v.ap_desig_inter,
            dest.total_ha                       = v.total_ha,
            dest.terrestre_ha                   = v.terrestre_ha,
            dest.marino_ha                      = v.marino_ha,
            dest.porcentaje_terrestre_protegido = v.porcentaje_terrestre_protegido,
            dest.fecha_actualizacion            = SYSDATETIME()
        FROM estadisticas.AreasProtegidasJurisdiccion dest
        INNER JOIN #AreasValidado v ON v.jurisdiccion = dest.jurisdiccion
        WHERE v.motivo_error IS NULL
          AND (
                ISNULL(dest.total_cantidad, -1)  <> ISNULL(v.total_cantidad, -1)
             OR ISNULL(dest.ap_nac, -1)          <> ISNULL(v.ap_nac, -1)
             OR ISNULL(dest.ap_prov, -1)         <> ISNULL(v.ap_prov, -1)
             OR ISNULL(dest.ap_desig_inter, -1)  <> ISNULL(v.ap_desig_inter, -1)
             OR ISNULL(dest.total_ha, -1)        <> ISNULL(v.total_ha, -1)
             OR ISNULL(dest.terrestre_ha, -1)    <> ISNULL(v.terrestre_ha, -1)
             OR ISNULL(dest.marino_ha, -1)       <> ISNULL(v.marino_ha, -1)
             OR ISNULL(CAST(dest.porcentaje_terrestre_protegido AS VARCHAR(20)), '')
                <> ISNULL(CAST(v.porcentaje_terrestre_protegido AS VARCHAR(20)), '')
          );

        SET @v_actualizados = @@ROWCOUNT;

        -- 5b) Insertar jurisdicciones nuevas
        INSERT INTO estadisticas.AreasProtegidasJurisdiccion
            (jurisdiccion, total_cantidad, ap_nac, ap_prov, ap_desig_inter,
             total_ha, terrestre_ha, marino_ha, porcentaje_terrestre_protegido)
        SELECT
            v.jurisdiccion, v.total_cantidad, v.ap_nac, v.ap_prov, v.ap_desig_inter,
            v.total_ha, v.terrestre_ha, v.marino_ha, v.porcentaje_terrestre_protegido
        FROM #AreasValidado v
        WHERE v.motivo_error IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM estadisticas.AreasProtegidasJurisdiccion dest
              WHERE dest.jurisdiccion = v.jurisdiccion
          );

        SET @v_insertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        ----------------------------------------------------------
        -- 6) Limpieza y resultado
        ----------------------------------------------------------
        DROP TABLE #AreasCargadas;
        DROP TABLE #AreasValidado;

        SELECT
            @v_insertados   AS registros_insertados,
            @v_actualizados AS registros_actualizados,
            @v_rechazados   AS registros_rechazados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        IF OBJECT_ID('tempdb..#AreasCargadas') IS NOT NULL DROP TABLE #AreasCargadas;
        IF OBJECT_ID('tempdb..#AreasValidado') IS NOT NULL DROP TABLE #AreasValidado;

        THROW;
    END CATCH
END
GO
