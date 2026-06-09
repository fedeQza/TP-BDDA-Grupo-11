/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Script de pruebas para los procedimientos
             almacenados de lógica de negocio.

             Se validan las operaciones de registro de ventas,
             gestión de concesiones, pagos de canon,
             transferencia de guardaparques y actualización de
             precios de entrada, verificando tanto escenarios
             exitosos como el comportamiento ante datos
             inválidos.

             Orden de ejecución:
               1. ScriptCreacionTablasYSchemas.sql
               2. ScriptABM_SPs.sql
               3. ScriptLogicaNegocio_SPs.sql
               4. Este script
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- PREPARACIÓN DE DATOS PREREQUISITOS
-- (Las tablas están vacías; se insertan los datos mínimos
--  necesarios para testear los SPs de lógica de negocio)
-- ==============================================================

PRINT '==============================================================';
PRINT ' PREPARACIÓN — Inserción de datos base para los tests';
PRINT '==============================================================';

DECLARE
    @id_tipo_parque      INT,
    @id_tipo_visitante   INT,
    @id_tipo_visitante2  INT,
    @id_forma_pago       INT,
    @id_tipo_atraccion   INT,
    @id_parque           INT,
    @id_parque2          INT,
    @id_empresa          INT,
    @id_guardaparque     INT,
    @id_historial_precio INT,
    @id_historial_precio2 INT,
    @id_atraccion_tour   INT;

SET NOCOUNT ON

-- TipoParque
EXEC parques.sp_InsertarTipoParque @p_descripcion = 'Parque Nacional LN-TEST';
SELECT @id_tipo_parque = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional LN-TEST';
PRINT 'OK — TipoParque insertado. ID: ' + CAST(@id_tipo_parque AS VARCHAR(10));

-- TipoVisitante
EXEC ventas.sp_InsertarTipoVisitante @p_descripcion = 'Adulto LN-TEST';
SELECT @id_tipo_visitante = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Adulto LN-TEST';
PRINT 'OK — TipoVisitante insertado. ID: ' + CAST(@id_tipo_visitante AS VARCHAR(10));

EXEC ventas.sp_InsertarTipoVisitante @p_descripcion = 'Jubilado LN-TEST';
SELECT @id_tipo_visitante2 = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado LN-TEST';
PRINT 'OK — TipoVisitante 2 insertado. ID: ' + CAST(@id_tipo_visitante2 AS VARCHAR(10));

-- FormaPago
EXEC ventas.sp_InsertarFormaPago @p_descripcion = 'Efectivo LN-TEST';
SELECT @id_forma_pago = id_forma_pago FROM ventas.FormaPago WHERE descripcion = 'Efectivo LN-TEST';
PRINT 'OK — FormaPago insertado. ID: ' + CAST(@id_forma_pago AS VARCHAR(10));

-- TipoAtraccion
EXEC turismo.sp_InsertarTipoAtraccion @p_descripcion = 'Senderismo LN-TEST';
SELECT @id_tipo_atraccion = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo LN-TEST';
PRINT 'OK — TipoAtraccion insertado. ID: ' + CAST(@id_tipo_atraccion AS VARCHAR(10));

-- Parque
EXEC parques.sp_InsertarParque
    @p_codigo_oficial = 'PN-LN-TEST-01',
    @p_nombre         = 'Parque Lógica Negocio TEST',
    @p_ubicacion      = 'Provincia de Testing, Argentina',
    @p_superficie     = 15000.00,
    @p_id_tipo_parque = @id_tipo_parque;
SELECT @id_parque = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-LN-TEST-01';
PRINT 'OK — Parque insertado. ID: ' + CAST(@id_parque AS VARCHAR(10));

-- Parque 2 (para tests con múltiples parques)
EXEC parques.sp_InsertarParque
    @p_codigo_oficial = 'PN-LN-TEST-02',
    @p_nombre         = 'Parque Lógica Negocio 2 TEST',
    @p_ubicacion      = 'Buenos Aires, Argentina',
    @p_superficie     = 8000.00,
    @p_id_tipo_parque = @id_tipo_parque;
SELECT @id_parque2 = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-LN-TEST-02';
PRINT 'OK — Parque 2 insertado. ID: ' + CAST(@id_parque2 AS VARCHAR(10));

-- HistorialPrecio (entrada para Adulto en Parque 1)
EXEC ventas.sp_InsertarHistorialPrecio
    @p_precio            = 3500.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque,
    @p_id_tipo_visitante = @id_tipo_visitante;
SELECT @id_historial_precio = id_historial_precio
FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante;
PRINT 'OK — HistorialPrecio insertado. ID: ' + CAST(@id_historial_precio AS VARCHAR(10));

-- HistorialPrecio (entrada para Jubilado en Parque 1)
EXEC ventas.sp_InsertarHistorialPrecio
    @p_precio            = 1750.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque,
    @p_id_tipo_visitante = @id_tipo_visitante2;
SELECT @id_historial_precio2 = id_historial_precio
FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante2;
PRINT 'OK — HistorialPrecio 2 insertado. ID: ' + CAST(@id_historial_precio2 AS VARCHAR(10));

-- AtraccionTour
EXEC turismo.sp_InsertarAtraccionTour
    @p_id_parque         = @id_parque,
    @p_id_tipo_atraccion = @id_tipo_atraccion,
    @p_nombre            = 'Tour Cascada LN-TEST',
    @p_costo             = 2000.00,
    @p_cupo_maximo       = 15,
    @p_duracion          = 120;
SELECT @id_atraccion_tour = id_atraccion_tour
FROM turismo.AtraccionTour WHERE nombre = 'Tour Cascada LN-TEST';
PRINT 'OK — AtraccionTour insertado. ID: ' + CAST(@id_atraccion_tour AS VARCHAR(10));

-- Empresa (necesaria para tests de concesiones)
EXEC comercial.sp_InsertarEmpresa
    @p_cuit         = '30712345678',
    @p_razon_social = 'Concesiones Patagónicas S.A. LN-TEST',
    @p_telefono     = '0299-555-1234',
    @p_email        = 'contacto@concpat.lntest',
    @p_direccion    = 'Av. San Martín 200, Neuquén';
SELECT @id_empresa = id_empresa FROM comercial.Empresa WHERE cuit = '30712345678';
PRINT 'OK — Empresa insertada. ID: ' + CAST(@id_empresa AS VARCHAR(10));

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 1 — ventas.sp_RegistrarVenta: CASOS EXITOSOS';
PRINT '==============================================================';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-01: Venta exitosa con 1 línea de entrada ---';
-- ---------------------------------------------------------------
DECLARE @detalles01 ventas.tt_DetalleVenta;
INSERT INTO @detalles01 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 2, 3500.00, 7000.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-00000001',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 7000.00,
        @p_detalles      = @detalles01;
    PRINT 'OK — Venta registrada correctamente (1 línea de entrada).';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia
SELECT 'Ticket LN-01' AS test, t.id_ticket, t.punto_venta, t.numero, t.total
FROM ventas.Ticket t WHERE t.numero = 'LN-00000001';
SELECT 'Detalle LN-01' AS test, td.id_detalle, td.cantidad, td.precio_unitario, td.subtotal
FROM ventas.TicketDetalle td
JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket
WHERE t.numero = 'LN-00000001';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-02: Venta exitosa con 1 línea de atracción/tour ---';
-- ---------------------------------------------------------------
DECLARE @detalles02 ventas.tt_DetalleVenta;
INSERT INTO @detalles02 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, NULL, NULL, @id_atraccion_tour, '2026-06-16', 3, 2000.00, 6000.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-00000002',
        @p_fecha_venta   = '2026-06-09 11:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 6000.00,
        @p_detalles      = @detalles02;
    PRINT 'OK — Venta registrada correctamente (1 línea de tour).';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia
SELECT 'Ticket LN-02' AS test, t.id_ticket, t.punto_venta, t.numero, t.total
FROM ventas.Ticket t WHERE t.numero = 'LN-00000002';
SELECT 'Detalle LN-02' AS test, td.id_detalle, td.id_atraccion_tour, td.cantidad, td.subtotal
FROM ventas.TicketDetalle td
JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket
WHERE t.numero = 'LN-00000002';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-03: Venta exitosa con múltiples líneas mixtas ---';
-- ---------------------------------------------------------------
DECLARE @detalles03 ventas.tt_DetalleVenta;
-- Línea 1: 2 entradas Adulto
INSERT INTO @detalles03 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-20', 2, 3500.00, 7000.00);
-- Línea 2: 1 entrada Jubilado
INSERT INTO @detalles03 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio2, @id_tipo_visitante2, NULL, '2026-06-20', 1, 1750.00, 1750.00);
-- Línea 3: 3 tours
INSERT INTO @detalles03 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, NULL, NULL, @id_atraccion_tour, '2026-06-20', 3, 2000.00, 6000.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0002',
        @p_numero        = 'LN-00000003',
        @p_fecha_venta   = '2026-06-09 12:30:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 14750.00,
        @p_detalles      = @detalles03;
    PRINT 'OK — Venta registrada correctamente (3 líneas mixtas). Total: 14750.00';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia
SELECT 'Ticket LN-03' AS test, t.id_ticket, t.punto_venta, t.numero, t.total
FROM ventas.Ticket t WHERE t.numero = 'LN-00000003';
SELECT 'Detalles LN-03' AS test, td.id_detalle, td.cantidad, td.precio_unitario, td.subtotal, td.id_historial_precio, td.id_atraccion_tour
FROM ventas.TicketDetalle td
JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket
WHERE t.numero = 'LN-00000003';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-04: Venta exitosa con total cero (entrada gratuita) ---';
-- ---------------------------------------------------------------
DECLARE @detalles04 ventas.tt_DetalleVenta;
INSERT INTO @detalles04 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-21', 1, 0.00, 0.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-00000004',
        @p_fecha_venta   = '2026-06-09 09:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 0.00,
        @p_detalles      = @detalles04;
    PRINT 'OK — Venta con total $0 registrada correctamente (entrada gratuita).';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 2 — ventas.sp_RegistrarVenta: CASOS DE ERROR';
PRINT '==============================================================';
PRINT 'Cada test espera recibir un error. Si el bloque CATCH no';
PRINT 'ejecuta, la validación falla.';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-05: Punto de venta inválido (no numérico) ---';
-- ---------------------------------------------------------------
DECLARE @detalles05 ventas.tt_DetalleVenta;
INSERT INTO @detalles05 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = 'AB01',
        @p_numero        = 'LN-ERR-001',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles05;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-06: Número de ticket vacío ---';
-- ---------------------------------------------------------------
DECLARE @detalles06 ventas.tt_DetalleVenta;
INSERT INTO @detalles06 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = '',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles06;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-07: Fecha de venta NULL ---';
-- ---------------------------------------------------------------
DECLARE @detalles07 ventas.tt_DetalleVenta;
INSERT INTO @detalles07 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-003',
        @p_fecha_venta   = NULL,
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles07;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-08: Forma de pago inexistente ---';
-- ---------------------------------------------------------------
DECLARE @detalles08 ventas.tt_DetalleVenta;
INSERT INTO @detalles08 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-004',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = 999999,
        @p_total         = 3500.00,
        @p_detalles      = @detalles08;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-09: Total negativo ---';
-- ---------------------------------------------------------------
DECLARE @detalles09 ventas.tt_DetalleVenta;
INSERT INTO @detalles09 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-005',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = -100.00,
        @p_detalles      = @detalles09;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-10: Sin líneas de detalle (tabla vacía) ---';
-- ---------------------------------------------------------------
DECLARE @detalles10 ventas.tt_DetalleVenta;
-- No insertamos nada en @detalles10

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-006',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 0.00,
        @p_detalles      = @detalles10;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-11: Detalle sin historial_precio ni atraccion_tour ---';
-- ---------------------------------------------------------------
DECLARE @detalles11 ventas.tt_DetalleVenta;
INSERT INTO @detalles11 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, NULL, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-007',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles11;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-12: Detalle con cantidad <= 0 ---';
-- ---------------------------------------------------------------
DECLARE @detalles12 ventas.tt_DetalleVenta;
INSERT INTO @detalles12 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 0, 3500.00, 0.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-008',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 0.00,
        @p_detalles      = @detalles12;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-13: Detalle con precio unitario negativo ---';
-- ---------------------------------------------------------------
DECLARE @detalles13 ventas.tt_DetalleVenta;
INSERT INTO @detalles13 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, -500.00, -500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-009',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = -500.00,
        @p_detalles      = @detalles13;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-14: Detalle con subtotal negativo ---';
-- ---------------------------------------------------------------
DECLARE @detalles14 ventas.tt_DetalleVenta;
INSERT INTO @detalles14 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, -3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-010',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = -3500.00,
        @p_detalles      = @detalles14;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-15: Parque inexistente en detalle ---';
-- ---------------------------------------------------------------
DECLARE @detalles15 ventas.tt_DetalleVenta;
INSERT INTO @detalles15 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (999999, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-011',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles15;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-16: Historial de precio inexistente en detalle ---';
-- ---------------------------------------------------------------
DECLARE @detalles16 ventas.tt_DetalleVenta;
INSERT INTO @detalles16 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, 999999, @id_tipo_visitante, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-012',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles16;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-17: Tipo de visitante inexistente en detalle ---';
-- ---------------------------------------------------------------
DECLARE @detalles17 ventas.tt_DetalleVenta;
INSERT INTO @detalles17 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, 999999, NULL, '2026-06-15', 1, 3500.00, 3500.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-013',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 3500.00,
        @p_detalles      = @detalles17;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-18: Atracción/tour inexistente en detalle ---';
-- ---------------------------------------------------------------
DECLARE @detalles18 ventas.tt_DetalleVenta;
INSERT INTO @detalles18 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, NULL, NULL, 999999, '2026-06-15', 1, 2000.00, 2000.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-014',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 2000.00,
        @p_detalles      = @detalles18;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-19: Total no coincide con suma de subtotales ---';
-- ---------------------------------------------------------------
DECLARE @detalles19 ventas.tt_DetalleVenta;
INSERT INTO @detalles19 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@id_parque, @id_historial_precio, @id_tipo_visitante, NULL, '2026-06-15', 2, 3500.00, 7000.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = '0001',
        @p_numero        = 'LN-ERR-015',
        @p_fecha_venta   = '2026-06-09 10:00:00',
        @p_id_forma_pago = @id_forma_pago,
        @p_total         = 5000.00,  -- Declaramos 5000, pero subtotal es 7000
        @p_detalles      = @detalles19;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-20: Múltiples errores simultáneos (acumula mensajes) ---';
-- ---------------------------------------------------------------
DECLARE @detalles20 ventas.tt_DetalleVenta;
-- Detalle con parque inexistente, sin historial_precio ni atraccion_tour, cantidad 0
INSERT INTO @detalles20 (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (999999, NULL, NULL, NULL, '2026-06-15', 0, -10.00, -10.00);

BEGIN TRY
    EXEC ventas.sp_RegistrarVenta
        @p_punto_venta   = 'XXXX',   -- punto de venta inválido
        @p_numero        = '',        -- número vacío
        @p_fecha_venta   = NULL,      -- fecha NULL
        @p_id_forma_pago = 999999,    -- forma de pago inexistente
        @p_total         = -1.00,     -- total negativo
        @p_detalles      = @detalles20;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Errores acumulados esperados:';
    PRINT ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 3 — EVIDENCIA FINAL Y LIMPIEZA';
PRINT '==============================================================';

-- Resumen de tickets generados exitosamente
SELECT 'Resumen Tickets Generados' AS seccion,
       t.id_ticket, t.punto_venta, t.numero, t.total,
       (SELECT COUNT(*) FROM ventas.TicketDetalle td WHERE td.id_ticket = t.id_ticket) AS cant_detalles
FROM ventas.Ticket t
WHERE t.numero LIKE 'LN-%';

-- Limpieza de datos de testing
DELETE FROM ventas.TicketDetalle WHERE id_ticket IN (SELECT id_ticket FROM ventas.Ticket WHERE numero LIKE 'LN-%');
DELETE FROM ventas.Ticket WHERE numero LIKE 'LN-%';
DELETE FROM turismo.AtraccionTour WHERE nombre = 'Tour Cascada LN-TEST';
DELETE FROM ventas.HistorialPrecio WHERE id_parque IN (SELECT id_parque FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%');
DELETE FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%';
DELETE FROM parques.TipoParque WHERE descripcion = 'Parque Nacional LN-TEST';
DELETE FROM ventas.TipoVisitante WHERE descripcion IN ('Adulto LN-TEST', 'Jubilado LN-TEST');
DELETE FROM ventas.FormaPago WHERE descripcion = 'Efectivo LN-TEST';
DELETE FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo LN-TEST';

PRINT 'OK — Datos de testing eliminados.';

-- Verificar limpieza
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin tickets LN-TEST residuales'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' tickets' END AS resultado
FROM ventas.Ticket WHERE numero LIKE 'LN-%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin parques LN-TEST residuales'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' parques' END AS resultado
FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%';

PRINT '';
PRINT '==============================================================';
PRINT ' Testing ventas.sp_RegistrarVenta completado.';
PRINT '==============================================================';

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 3 — comercial.sp_RegistrarConcesionConObligaciones:';
PRINT '              CASOS EXITOSOS';
PRINT '==============================================================';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-21: Concesión 6 meses con día vencimiento default (10) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Gastronomía LN-TEST',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00;
    PRINT 'OK — Concesión registrada (6 meses, venc. día 10). Debe generar 6 obligaciones.';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia
SELECT 'Concesión LN-21' AS test, c.id_concesion, c.tipo_actividad, c.fecha_inicio, c.fecha_fin, c.canon_mensual
FROM comercial.Concesion c
WHERE c.tipo_actividad = 'Gastronomía LN-TEST';

SELECT 'Obligaciones LN-21' AS test, oc.id_obligacion, oc.mes, oc.anio, oc.monto_obligado, oc.estado, oc.fecha_vencimiento
FROM comercial.ObligacionCanon oc
JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion
WHERE c.tipo_actividad = 'Gastronomía LN-TEST'
ORDER BY oc.anio, oc.mes;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-22: Concesión 1 mes (período mínimo) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Kiosco LN-TEST',
        @p_fecha_inicio    = '2026-03-01',
        @p_fecha_fin       = '2026-03-31',
        @p_canon_mensual   = 20000.00,
        @p_dia_vencimiento = 15;
    PRINT 'OK — Concesión registrada (1 mes). Debe generar 1 obligación.';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia
SELECT 'Obligaciones LN-22' AS test, oc.mes, oc.anio, oc.monto_obligado, oc.fecha_vencimiento
FROM comercial.ObligacionCanon oc
JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion
WHERE c.tipo_actividad = 'Kiosco LN-TEST';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-23: Concesión 12 meses con día vencimiento personalizado (20) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque2,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Excursiones acuáticas LN-TEST',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-12-31',
        @p_canon_mensual   = 75000.00,
        @p_dia_vencimiento = 20;
    PRINT 'OK — Concesión registrada (12 meses, venc. día 20). Debe generar 12 obligaciones.';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia: verificar que se generaron 12 obligaciones con vencimiento el día 20
SELECT 'Cant. Obligaciones LN-23' AS test,
       COUNT(*) AS total_obligaciones,
       MIN(fecha_vencimiento) AS primer_vencimiento,
       MAX(fecha_vencimiento) AS ultimo_vencimiento
FROM comercial.ObligacionCanon oc
JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion
WHERE c.tipo_actividad = 'Excursiones acuáticas LN-TEST';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-24: Concesión que cruza fin de año (Nov 2025 - Feb 2026) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Alquiler equipos LN-TEST',
        @p_fecha_inicio    = '2025-11-01',
        @p_fecha_fin       = '2026-02-28',
        @p_canon_mensual   = 30000.00,
        @p_dia_vencimiento = 5;
    PRINT 'OK — Concesión registrada (cruza fin de año). Debe generar 4 obligaciones (Nov, Dic, Ene, Feb).';
END TRY
BEGIN CATCH
    PRINT 'FALLO — ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia: 4 obligaciones cruzando el año
SELECT 'Obligaciones LN-24' AS test, oc.mes, oc.anio, oc.fecha_vencimiento
FROM comercial.ObligacionCanon oc
JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion
WHERE c.tipo_actividad = 'Alquiler equipos LN-TEST'
ORDER BY oc.anio, oc.mes;

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 4 — comercial.sp_RegistrarConcesionConObligaciones:';
PRINT '              CASOS DE ERROR';
PRINT '==============================================================';
PRINT 'Cada test espera recibir un error. Si el bloque CATCH no';
PRINT 'ejecuta, la validación falla.';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-25: Parque inexistente ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = 999999,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-26: Empresa inexistente ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = 999999,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-27: Tipo de actividad vacío ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = '',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-28: Fechas NULL (inicio y fin) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = NULL,
        @p_fecha_fin       = NULL,
        @p_canon_mensual   = 50000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-29: Fecha fin anterior a fecha inicio ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-06-01',
        @p_fecha_fin       = '2026-01-01',
        @p_canon_mensual   = 50000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-30: Canon mensual negativo ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = -5000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-31: Canon mensual igual a cero ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 0.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-32: Día de vencimiento fuera de rango (0) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00,
        @p_dia_vencimiento = 0;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-33: Día de vencimiento fuera de rango (29) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = @id_parque,
        @p_id_empresa      = @id_empresa,
        @p_tipo_actividad  = 'Actividad error',
        @p_fecha_inicio    = '2026-01-01',
        @p_fecha_fin       = '2026-06-30',
        @p_canon_mensual   = 50000.00,
        @p_dia_vencimiento = 29;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST LN-34: Múltiples errores simultáneos (acumula mensajes) ---';
-- ---------------------------------------------------------------
BEGIN TRY
    EXEC comercial.sp_RegistrarConcesionConObligaciones
        @p_id_parque       = 999999,    -- parque inexistente
        @p_id_empresa      = 999999,    -- empresa inexistente
        @p_tipo_actividad  = '',        -- vacío
        @p_fecha_inicio    = '2026-06-01',
        @p_fecha_fin       = '2026-01-01',  -- fin < inicio
        @p_canon_mensual   = -100.00,   -- negativo
        @p_dia_vencimiento = 30;        -- fuera de rango
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Errores acumulados esperados:';
    PRINT ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 5 — EVIDENCIA FINAL Y LIMPIEZA';
PRINT '==============================================================';

-- Resumen de tickets generados exitosamente
SELECT 'Resumen Tickets Generados' AS seccion,
       t.id_ticket, t.punto_venta, t.numero, t.total,
       (SELECT COUNT(*) FROM ventas.TicketDetalle td WHERE td.id_ticket = t.id_ticket) AS cant_detalles
FROM ventas.Ticket t
WHERE t.numero LIKE 'LN-%';

-- Resumen de concesiones generadas exitosamente
SELECT 'Resumen Concesiones Generadas' AS seccion,
       c.id_concesion, c.tipo_actividad, c.canon_mensual,
       (SELECT COUNT(*) FROM comercial.ObligacionCanon oc WHERE oc.id_concesion = c.id_concesion) AS cant_obligaciones
FROM comercial.Concesion c
WHERE c.tipo_actividad LIKE '%LN-TEST';

-- Limpieza de datos de testing
DELETE FROM comercial.ObligacionCanon WHERE id_concesion IN (SELECT id_concesion FROM comercial.Concesion WHERE tipo_actividad LIKE '%LN-TEST');
DELETE FROM comercial.Concesion WHERE tipo_actividad LIKE '%LN-TEST';
DELETE FROM ventas.TicketDetalle WHERE id_ticket IN (SELECT id_ticket FROM ventas.Ticket WHERE numero LIKE 'LN-%');
DELETE FROM ventas.Ticket WHERE numero LIKE 'LN-%';
DELETE FROM turismo.AtraccionTour WHERE nombre = 'Tour Cascada LN-TEST';
DELETE FROM ventas.HistorialPrecio WHERE id_parque IN (SELECT id_parque FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%');
DELETE FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%';
DELETE FROM comercial.Empresa WHERE cuit = '30712345678';
DELETE FROM parques.TipoParque WHERE descripcion = 'Parque Nacional LN-TEST';
DELETE FROM ventas.TipoVisitante WHERE descripcion IN ('Adulto LN-TEST', 'Jubilado LN-TEST');
DELETE FROM ventas.FormaPago WHERE descripcion = 'Efectivo LN-TEST';
DELETE FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo LN-TEST';

PRINT 'OK — Datos de testing eliminados.';

-- Verificar limpieza
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin tickets LN-TEST residuales'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' tickets' END AS resultado
FROM ventas.Ticket WHERE numero LIKE 'LN-%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin concesiones LN-TEST residuales'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' concesiones' END AS resultado
FROM comercial.Concesion WHERE tipo_actividad LIKE '%LN-TEST';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin parques LN-TEST residuales'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' parques' END AS resultado
FROM parques.Parque WHERE codigo_oficial LIKE 'PN-LN-TEST%';

GO

PRINT '';
PRINT '==============================================================';
PRINT ' Testing Lógica de Negocio completado.';
PRINT '==============================================================';