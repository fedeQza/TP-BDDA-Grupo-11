/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Script de pruebas para
             importaciones.ImportarEstadisticasVisitantes.

             Orden de ejecución:
               1. 01-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. 04-ScriptEstadisticasVisitantes.sql
               5. Este script

             ANTES DE EJECUTAR: crear los dos archivos CSV
             descriptos más abajo y ajustar las rutas en las
             variables @v_archivo_principal y
             @v_archivo_casos_error según donde se hayan
             guardado en el servidor de SQL Server.

             --------------------------------------------------
             Archivo 1 (@v_archivo_principal) - dataset real,
             por ejemplo "estadisticas_visitantes.csv":

                 indice_tiempo,region_de_destino,origen_visitantes,visitas,observaciones
                 2008-1-01,buenos aires,no residentes,0,
                 2008-1-01,buenos aires,residentes,885,
                 2008-1-01,buenos aires,total,885,
                 2008-1-01,cordoba,no residentes,145,
                 2008-1-01,cordoba,residentes,717,
                 2008-1-01,cordoba,total,862,

             --------------------------------------------------
             Archivo 2 (@v_archivo_casos_error) - casos de
             error y duplicados, por ejemplo
             "estadisticas_visitantes_casos_error.csv":

                 indice_tiempo,region_de_destino,origen_visitantes,visitas,observaciones
                 2024-1-01,santa cruz,residentes,500,Carga inicial
                 2024-1-01,santa cruz,residentes,550,Correccion de carga
                 2024-1-01,chubut,residentes,-10,Visitas negativas - debe rechazarse
                 2024-99-01,neuquen,residentes,300,Fecha invalida - debe rechazarse
                 2024-1-01,,no residentes,120,Region vacia - debe rechazarse
                 2024-1-01,misiones,total,abc,Visitas no numericas - debe rechazarse

             Las dos primeras filas de este archivo comparten
             la misma clave (2024-1-01, santa cruz, residentes):
             se espera que la primera se rechace como
             "duplicado dentro del archivo" y se conserve la
             segunda (visitas=550).
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- Solo se pasa el nombre del archivo; el SP busca automáticamente
-- en C:\Users\secon\OneDrive\Escritorio\TP-BDDA\
DECLARE @v_archivo_principal    VARCHAR(500) = 'estadisticas_visitantes.csv';
DECLARE @v_archivo_casos_error  VARCHAR(500) = 'estadisticas_visitantes_casos_error.csv';
DECLARE @v_archivo_inexistente  VARCHAR(500) = 'no_existe.csv';

PRINT '==============================================================';
PRINT ' CASO 1 - Importación exitosa del archivo principal';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = @v_archivo_principal;

-- Evidencia: filas cargadas en la tabla destino
SELECT * FROM estadisticas.VisitantesParques ORDER BY indice_tiempo, region_destino, origen_visitantes;
GO

DECLARE @v_archivo_principal VARCHAR(500) = 'estadisticas_visitantes.csv';

PRINT '==============================================================';
PRINT ' CASO 2 - Reimportación del mismo archivo (no debe duplicar)';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = @v_archivo_principal;
-- Se espera registros_insertados = 0 y registros_actualizados = 0

-- Evidencia: la cantidad de filas no cambió respecto al CASO 1
SELECT COUNT(*) AS total_filas_visitantes FROM estadisticas.VisitantesParques;
GO

DECLARE @v_archivo_casos_error VARCHAR(500) = 'estadisticas_visitantes_casos_error.csv';

PRINT '==============================================================';
PRINT ' CASO 3 - Archivo con: visitas negativas, fecha inválida,';
PRINT '          región vacía, visitas no numéricas y duplicados';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = @v_archivo_casos_error;
-- Se espera registros_insertados = 1 (santa cruz / residentes, visitas=550)
-- y registros_rechazados = 5

-- Evidencia: la fila válida quedó cargada con el valor de la última ocurrencia
SELECT * FROM estadisticas.VisitantesParques
WHERE region_destino = 'santa cruz' AND origen_visitantes = 'residentes';

-- Evidencia: detalle de las filas rechazadas para este archivo
DECLARE @v_ruta_completa_error VARCHAR(1000) = 'C:\Users\secon\OneDrive\Escritorio\TP-BDDA\' + @v_archivo_casos_error;
SELECT *
FROM estadisticas.ErroresImportacion
WHERE archivo_origen = @v_ruta_completa_error
ORDER BY id_error;
GO

PRINT '==============================================================';
PRINT ' CASO 4 - Reimportación del archivo de casos de error';
PRINT '          (la fila ya existente con su valor corregido no';
PRINT '           debe volver a actualizarse ni duplicarse)';
PRINT '==============================================================';

DECLARE @v_archivo_casos_error VARCHAR(500) = 'estadisticas_visitantes_casos_error.csv';

EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = @v_archivo_casos_error;
-- Se espera registros_insertados = 0, registros_actualizados = 0,
-- registros_rechazados = 5 (se vuelven a registrar como errores)
GO

PRINT '==============================================================';
PRINT ' CASO 5 - Archivo inexistente';
PRINT '==============================================================';

DECLARE @v_archivo_inexistente VARCHAR(500) = 'no_existe.csv';

BEGIN TRY
    EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = @v_archivo_inexistente;
END TRY
BEGIN CATCH
    PRINT 'OK - Error esperado: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '==============================================================';
PRINT ' Verificación final: la tabla de staging quedó vacía';
PRINT '==============================================================';

SELECT COUNT(*) AS filas_en_staging FROM estadisticas.StagingVisitantes;
GO
