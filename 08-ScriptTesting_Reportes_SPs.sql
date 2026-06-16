
/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       15/06/2026
Descripción: Script para la ejecución y prueba de los Store Procedures
             de reportes desarrollados en la Entrega 7.
==============================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO TESTING DE REPORTES (ENTREGA 7)';
PRINT 'Nota: Se requiere tener datos insertados en las tablas para ver resultados.';
PRINT '=========================================================================';
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: Reporte de visitas por semana, mes y año, por parque';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.SP_Reporte_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Ingresos por parque por semana, mes y año (Consolidado)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.SP_Ingresos_Parque;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Deudores de Concesiones (Formato XML)';
PRINT '-------------------------------------------------------------------------';
-- Nota en SSMS: El resultado XML aparecerá como un link azul en la grilla.
-- Al hacerle clic, se abrirá una nueva pestaña con el XML formateado.
EXEC dbo.SP_Deudores_XML;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Matriz de visitas (Tabla Cruzada / Pivot de meses)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.SP_Matriz_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Parques y Concesiones (Formato XML Anidado)';
PRINT '-------------------------------------------------------------------------';
-- Nota en SSMS: El resultado XML aparecerá como un link azul en la grilla.
EXEC dbo.SP_Parques_Concesiones_XML;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE REPORTES';
PRINT '=========================================================================';
GO