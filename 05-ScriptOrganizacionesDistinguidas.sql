/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Entrega 6 - Carga de organizaciones distinguidas
             desde un archivo CSV externo
             (registro-organizaciones-distinguidas.csv).

             Contenido:
             - estadisticas.OrganizacionesDistinguidas
                 Tabla destino. No se eliminan registros: las
                 cargas sucesivas insertan organizaciones nuevas
                 y actualizan los datos de contacto/programa
                 si cambiaron para una clave existente.
             - estadisticas.StagingOrganizaciones
                 Tabla de staging usada por BULK INSERT. El INSERT
                 especifica la lista de columnas para saltear el
                 IDENTITY y cargar directamente sobre la tabla.
             - Reutiliza estadisticas.ErroresImportacion
                 (creada en 04-ScriptEstadisticasVisitantes.sql).
             - importaciones.ImportarOrganizacionesDistinguidas
                 Procedimiento que realiza toda la carga,
                 validación y upsert (sin MERGE).

             Clave de unicidad / upsert:
                 organizacion + calle + numero
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- TABLA DESTINO: estadisticas.OrganizacionesDistinguidas
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrganizacionesDistinguidas' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.OrganizacionesDistinguidas...';
    CREATE TABLE estadisticas.OrganizacionesDistinguidas (
        id_organizacion     INT IDENTITY(1,1) PRIMARY KEY,
        organizacion        VARCHAR(200)  NOT NULL,
        rubro               VARCHAR(100)  NULL,
        subrubro            VARCHAR(100)  NULL,
        calle               VARCHAR(200)  NULL,
        numero              VARCHAR(50)   NULL,
        pais                VARCHAR(100)  NULL,
        provincia           VARCHAR(100)  NULL,
        ciudad              VARCHAR(100)  NULL,
        telefono            VARCHAR(100)  NULL,
        facebook            VARCHAR(200)  NULL,
        web                 VARCHAR(200)  NULL,
        programa            VARCHAR(200)  NULL,
        fecha_distincion    DATE          NULL,
        fecha_revalidacion  DATE          NULL,
        fecha_carga         DATETIME2     NOT NULL CONSTRAINT DF_OrganizacionesDistinguidas_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2     NULL,
        CONSTRAINT UQ_OrganizacionesDistinguidas_Clave UNIQUE (organizacion, calle, numero)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.OrganizacionesDistinguidas ya existe, se omite creación.';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrganizacionesDistinguidas_Provincia')
    CREATE INDEX IX_OrganizacionesDistinguidas_Provincia ON estadisticas.OrganizacionesDistinguidas (provincia);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrganizacionesDistinguidas_Rubro')
    CREATE INDEX IX_OrganizacionesDistinguidas_Rubro ON estadisticas.OrganizacionesDistinguidas (rubro);
GO

-- ==============================================================
-- TABLA DE STAGING: estadisticas.StagingOrganizaciones
-- Todas las columnas son VARCHAR para que BULK INSERT nunca
-- falle por un valor inválido.
--
-- Mapeo de columnas del CSV (en orden):
--   organizacion       -> organizacion_raw
--   rubro              -> rubro_raw
--   subrubro           -> subrubro_raw
--   calle              -> calle_raw
--   numero             -> numero_raw
--   pais               -> pais_raw
--   provincia          -> provincia_raw
--   ciudad             -> ciudad_raw
--   telefono           -> telefono_raw
--   facebook           -> facebook_raw
--   web                -> web_raw
--   programa           -> programa_raw
--   fecha_distincion   -> fecha_distincion_raw
--   fecha_revalidacion -> fecha_revalidacion_raw
-- ==============================================================

IF OBJECT_ID('estadisticas.StagingOrganizaciones', 'U') IS NOT NULL
    DROP TABLE estadisticas.StagingOrganizaciones;
PRINT 'Creando tabla estadisticas.StagingOrganizaciones...';
CREATE TABLE estadisticas.StagingOrganizaciones (
    organizacion_raw       VARCHAR(300) NULL,
    rubro_raw              VARCHAR(200) NULL,
    subrubro_raw           VARCHAR(200) NULL,
    calle_raw              VARCHAR(300) NULL,
    numero_raw             VARCHAR(100) NULL,
    pais_raw               VARCHAR(200) NULL,
    provincia_raw          VARCHAR(200) NULL,
    ciudad_raw             VARCHAR(200) NULL,
    telefono_raw           VARCHAR(200) NULL,
    facebook_raw           VARCHAR(300) NULL,
    web_raw                VARCHAR(300) NULL,
    programa_raw           VARCHAR(300) NULL,
    fecha_distincion_raw   VARCHAR(50)  NULL,
    fecha_revalidacion_raw VARCHAR(50)  NULL
);
GO

-- Ampliar columnas de ErroresImportacion para que quepan valores
-- más largos provenientes de otros datasets (organizaciones, etc.)
IF COL_LENGTH('estadisticas.ErroresImportacion', 'indice_tiempo_valor') < 500
    ALTER TABLE estadisticas.ErroresImportacion
        ALTER COLUMN indice_tiempo_valor VARCHAR(500) NULL;
GO
IF COL_LENGTH('estadisticas.ErroresImportacion', 'region_destino_valor') < 500
    ALTER TABLE estadisticas.ErroresImportacion
        ALTER COLUMN region_destino_valor VARCHAR(500) NULL;
GO
IF COL_LENGTH('estadisticas.ErroresImportacion', 'origen_visitantes_valor') < 500
    ALTER TABLE estadisticas.ErroresImportacion
        ALTER COLUMN origen_visitantes_valor VARCHAR(500) NULL;
GO
IF COL_LENGTH('estadisticas.ErroresImportacion', 'visitas_valor') < 500
    ALTER TABLE estadisticas.ErroresImportacion
        ALTER COLUMN visitas_valor VARCHAR(500) NULL;
GO

IF OBJECT_ID('estadisticas.StagingOrganizacionesImport', 'V') IS NOT NULL
    DROP VIEW estadisticas.StagingOrganizacionesImport;
GO

-- ==============================================================
-- importaciones.ImportarOrganizacionesDistinguidas
--
-- Importa el CSV indicado en @p_ruta_archivo:
--   1. Valida que el archivo exista.
--   2. Vacía el staging y carga el CSV con BULK INSERT.
--   3. Valida cada fila y detecta duplicados dentro del archivo.
--   4. Filas inválidas -> estadisticas.ErroresImportacion.
--   5. Upsert sin MERGE sobre OrganizacionesDistinguidas
--      (clave: organizacion + calle + numero):
--      inserta filas nuevas y actualiza datos de contacto y
--      programa cuando cambiaron. Nunca elimina filas.
--   6. Vacía el staging al finalizar (incluso si hubo error).
--   7. Devuelve registros_insertados, actualizados y rechazados.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('importaciones.ImportarOrganizacionesDistinguidas') AND type = 'P')
    PRINT 'Creando Procedure importaciones.ImportarOrganizacionesDistinguidas...';
ELSE
    PRINT 'OK - Procedure importaciones.ImportarOrganizacionesDistinguidas ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo VARCHAR(500)   -- nombre del archivo (ej.: 'registro-organizaciones-distinguidas.csv')
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFORMAT ymd;

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
        -- 2) Vaciar staging y cargar el CSV con BULK INSERT
        ----------------------------------------------------------
        TRUNCATE TABLE estadisticas.StagingOrganizaciones;

        SET @v_sql = N'
            BULK INSERT estadisticas.StagingOrganizaciones
            FROM ''' + REPLACE(@v_ruta_completa, '''', '''''') + N'''
            WITH (
                FIELDTERMINATOR = '','',
                ROWTERMINATOR   = ''0x0a'',
                FIRSTROW        = 2,
                CODEPAGE        = ''65001'',
                MAXERRORS       = 2147483647
            );';

        EXEC sp_executesql @v_sql;

        ----------------------------------------------------------
        -- 3) Validar cada fila cargada
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#OrgValidado') IS NOT NULL DROP TABLE #OrgValidado;

        CREATE TABLE #OrgValidado (
            row_num              INT           NOT NULL PRIMARY KEY,
            organizacion_raw     VARCHAR(300)  NULL,
            rubro_raw            VARCHAR(200)  NULL,
            calle_raw            VARCHAR(300)  NULL,
            numero_raw           VARCHAR(100)  NULL,
            fecha_distincion_raw VARCHAR(50)   NULL,
            organizacion         VARCHAR(200)  NULL,
            rubro                VARCHAR(100)  NULL,
            subrubro             VARCHAR(100)  NULL,
            calle                VARCHAR(200)  NULL,
            numero               VARCHAR(50)   NULL,
            pais                 VARCHAR(100)  NULL,
            provincia            VARCHAR(100)  NULL,
            ciudad               VARCHAR(100)  NULL,
            telefono             VARCHAR(100)  NULL,
            facebook             VARCHAR(200)  NULL,
            web                  VARCHAR(200)  NULL,
            programa             VARCHAR(200)  NULL,
            fecha_distincion     DATE          NULL,
            fecha_revalidacion   DATE          NULL,
            motivo_error         VARCHAR(500)  NULL
        );

        INSERT INTO #OrgValidado
            (row_num, organizacion_raw, rubro_raw, calle_raw, numero_raw, fecha_distincion_raw,
             organizacion, rubro, subrubro, calle, numero, pais, provincia,
             ciudad, telefono, facebook, web, programa, fecha_distincion,
             fecha_revalidacion, motivo_error)
        SELECT
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            s.organizacion_raw,
            s.rubro_raw,
            s.calle_raw,
            s.numero_raw,
            s.fecha_distincion_raw,
            NULLIF(LTRIM(RTRIM(s.organizacion_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.rubro_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.subrubro_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.calle_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.numero_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.pais_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.provincia_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.ciudad_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.telefono_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.facebook_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.web_raw)), ''),
            NULLIF(LTRIM(RTRIM(s.programa_raw)), ''),
            TRY_CAST(LTRIM(RTRIM(REPLACE(s.fecha_distincion_raw,   CHAR(13), ''))) AS DATE),
            TRY_CAST(LTRIM(RTRIM(REPLACE(s.fecha_revalidacion_raw, CHAR(13), ''))) AS DATE),
            CASE
                WHEN LTRIM(RTRIM(ISNULL(s.organizacion_raw, ''))) = ''
                    THEN N'El nombre de la organización es nulo o vacío.'
                WHEN LTRIM(RTRIM(ISNULL(s.rubro_raw, ''))) = ''
                    THEN N'El rubro es nulo o vacío.'
                WHEN LTRIM(RTRIM(REPLACE(ISNULL(s.fecha_distincion_raw, ''),   CHAR(13), ''))) <> ''
                 AND TRY_CAST(LTRIM(RTRIM(REPLACE(s.fecha_distincion_raw,   CHAR(13), ''))) AS DATE) IS NULL
                    THEN N'La fecha de distinción es inválida.'
                WHEN LTRIM(RTRIM(REPLACE(ISNULL(s.fecha_revalidacion_raw, ''), CHAR(13), ''))) <> ''
                 AND TRY_CAST(LTRIM(RTRIM(REPLACE(s.fecha_revalidacion_raw, CHAR(13), ''))) AS DATE) IS NULL
                    THEN N'La fecha de revalidación es inválida.'
                ELSE NULL
            END
        FROM estadisticas.StagingOrganizaciones s;

        -- Detectar duplicados de clave dentro del propio archivo
        ;WITH Duplicados AS (
            SELECT row_num,
                   ROW_NUMBER() OVER (
                       PARTITION BY organizacion, calle, numero
                       ORDER BY row_num DESC
                   ) AS orden
            FROM #OrgValidado
            WHERE motivo_error IS NULL
        )
        UPDATE v
        SET v.motivo_error = N'Registro duplicado dentro del archivo (se conserva la última ocurrencia con esa clave).'
        FROM #OrgValidado v
        INNER JOIN Duplicados d ON d.row_num = v.row_num
        WHERE d.orden > 1;

        ----------------------------------------------------------
        -- 4) Registrar filas rechazadas con sus valores originales
        ----------------------------------------------------------
        INSERT INTO estadisticas.ErroresImportacion
            (archivo_origen, motivo_error, indice_tiempo_valor, region_destino_valor,
             origen_visitantes_valor, visitas_valor, observaciones_valor)
        SELECT
            @v_ruta_completa,
            v.motivo_error,
            v.organizacion_raw,
            v.rubro_raw,
            v.calle_raw,
            v.numero_raw,
            v.fecha_distincion_raw
        FROM #OrgValidado v
        WHERE v.motivo_error IS NOT NULL;

        SET @v_rechazados = @@ROWCOUNT;

        ----------------------------------------------------------
        -- 5) Upsert sin MERGE sobre OrganizacionesDistinguidas
        ----------------------------------------------------------
        BEGIN TRANSACTION;

        -- 5a) Actualizar registros existentes cuyos datos cambiaron
        UPDATE dest
        SET dest.rubro              = v.rubro,
            dest.subrubro           = v.subrubro,
            dest.pais               = v.pais,
            dest.provincia          = v.provincia,
            dest.ciudad             = v.ciudad,
            dest.telefono           = v.telefono,
            dest.facebook           = v.facebook,
            dest.web                = v.web,
            dest.programa           = v.programa,
            dest.fecha_distincion   = v.fecha_distincion,
            dest.fecha_revalidacion = v.fecha_revalidacion,
            dest.fecha_actualizacion = SYSDATETIME()
        FROM estadisticas.OrganizacionesDistinguidas dest
        INNER JOIN #OrgValidado v
            ON v.organizacion = dest.organizacion
           AND ISNULL(v.calle, '')  = ISNULL(dest.calle, '')
           AND ISNULL(v.numero, '') = ISNULL(dest.numero, '')
        WHERE v.motivo_error IS NULL
          AND (
                ISNULL(dest.rubro, '')              <> ISNULL(v.rubro, '')
             OR ISNULL(dest.subrubro, '')           <> ISNULL(v.subrubro, '')
             OR ISNULL(dest.pais, '')               <> ISNULL(v.pais, '')
             OR ISNULL(dest.provincia, '')          <> ISNULL(v.provincia, '')
             OR ISNULL(dest.ciudad, '')             <> ISNULL(v.ciudad, '')
             OR ISNULL(dest.telefono, '')           <> ISNULL(v.telefono, '')
             OR ISNULL(dest.facebook, '')           <> ISNULL(v.facebook, '')
             OR ISNULL(dest.web, '')                <> ISNULL(v.web, '')
             OR ISNULL(dest.programa, '')           <> ISNULL(v.programa, '')
             OR ISNULL(CAST(dest.fecha_distincion AS VARCHAR(20)), '')
                <> ISNULL(CAST(v.fecha_distincion AS VARCHAR(20)), '')
             OR ISNULL(CAST(dest.fecha_revalidacion AS VARCHAR(20)), '')
                <> ISNULL(CAST(v.fecha_revalidacion AS VARCHAR(20)), '')
              );

        SET @v_actualizados = @@ROWCOUNT;

        -- 5b) Insertar organizaciones nuevas
        INSERT INTO estadisticas.OrganizacionesDistinguidas
            (organizacion, rubro, subrubro, calle, numero, pais, provincia, ciudad,
             telefono, facebook, web, programa, fecha_distincion, fecha_revalidacion)
        SELECT
            v.organizacion, v.rubro, v.subrubro, v.calle, v.numero, v.pais,
            v.provincia, v.ciudad, v.telefono, v.facebook, v.web, v.programa,
            v.fecha_distincion, v.fecha_revalidacion
        FROM #OrgValidado v
        WHERE v.motivo_error IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM estadisticas.OrganizacionesDistinguidas dest
              WHERE dest.organizacion      = v.organizacion
                AND ISNULL(dest.calle, '')  = ISNULL(v.calle, '')
                AND ISNULL(dest.numero, '') = ISNULL(v.numero, '')
          );

        SET @v_insertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        ----------------------------------------------------------
        -- 6) Limpieza de staging y resultado
        ----------------------------------------------------------
        TRUNCATE TABLE estadisticas.StagingOrganizaciones;
        DROP TABLE #OrgValidado;

        SELECT
            @v_insertados   AS registros_insertados,
            @v_actualizados AS registros_actualizados,
            @v_rechazados   AS registros_rechazados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        TRUNCATE TABLE estadisticas.StagingOrganizaciones;
        IF OBJECT_ID('tempdb..#OrgValidado') IS NOT NULL DROP TABLE #OrgValidado;

        THROW;
    END CATCH
END
GO
