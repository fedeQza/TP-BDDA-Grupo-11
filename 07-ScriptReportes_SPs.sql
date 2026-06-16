/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       15/06/2026
Descripción: Entrega 7 - Store Procedures para Reportes Transaccionales y XML
==============================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO CREACIÓN DE STORE PROCEDURES DE REPORTES (ENTREGA 7)';
PRINT '=========================================================================';
GO

-- =========================================================================
-- 1. REPORTE DE VISITAS POR SEMANA, MES Y AÑO, POR PARQUE
-- =========================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_Reporte_Visitas' AND type = 'P')
BEGIN
    PRINT 'Eliminando versión anterior de dbo.SP_Reporte_Visitas...';
    DROP PROCEDURE dbo.SP_Reporte_Visitas;
END
GO

PRINT 'Creando Store Procedure dbo.SP_Reporte_Visitas...';
GO
CREATE PROCEDURE dbo.SP_Reporte_Visitas
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.nombre AS Parque,
        YEAR(td.fecha_acceso) AS Anio,
        MONTH(td.fecha_acceso) AS Mes,
        DATEPART(WEEK, td.fecha_acceso) AS Semana,
        SUM(td.cantidad) AS Total_Visitas
    FROM ventas.TicketDetalle td
    JOIN parques.Parque p ON td.id_parque = p.id_parque
    GROUP BY 
        p.nombre, 
        YEAR(td.fecha_acceso), 
        MONTH(td.fecha_acceso), 
        DATEPART(WEEK, td.fecha_acceso)
    ORDER BY 
        Parque, Anio, Mes, Semana;
END;
GO
PRINT 'OK - Store Procedure dbo.SP_Reporte_Visitas creado con éxito.';
GO

--------------------------------------------------------------------------------------------------
--1. SP_Reporte_Visitas (Reporte de visitas por semana, mes y año, por parque)
--------------------------------------------------------------------------------------------------
--* Origen de datos: Hacemos un JOIN entre ventas.TicketDetalle (que tiene la cantidad de visitantes) y parques.Parque para obtener el nombre real del parque.
--* Funciones de Fecha: Para separar la fecha de acceso usamos las funciones nativas de SQL Server: YEAR(), MONTH() y DATEPART(WEEK, fecha).
--* Agrupación: Usamos GROUP BY sobre el nombre del parque y las partes de la fecha, sumando (SUM) la cantidad de personas para obtener el total consolidado por esa franja de tiempo.

-- =========================================================================
-- 2. INGRESOS POR PARQUE POR SEMANA, MES Y AÑO
-- =========================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_Ingresos_Parque' AND type = 'P')
BEGIN
    PRINT 'Eliminando versión anterior de dbo.SP_Ingresos_Parque...';
    DROP PROCEDURE dbo.SP_Ingresos_Parque;
END
GO

PRINT 'Creando Store Procedure dbo.SP_Ingresos_Parque...';
GO
CREATE PROCEDURE dbo.SP_Ingresos_Parque
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Parque, 
        Anio, 
        Mes, 
        Semana,
        SUM(Ingreso_Entradas) AS Total_Entradas,
        SUM(Ingreso_Tours) AS Total_Tours,
        SUM(Ingreso_Concesiones) AS Total_Concesiones,
        SUM(Ingreso_Entradas + Ingreso_Tours + Ingreso_Concesiones) AS Total_General
    FROM (
        -- Ingresos por Entradas y Tours
        SELECT 
            p.nombre AS Parque,
            YEAR(td.fecha_acceso) AS Anio,
            MONTH(td.fecha_acceso) AS Mes,
            DATEPART(WEEK, td.fecha_acceso) AS Semana,
            SUM(CASE WHEN td.id_atraccion_tour IS NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Entradas,
            SUM(CASE WHEN td.id_atraccion_tour IS NOT NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Tours,
            0 AS Ingreso_Concesiones
        FROM ventas.TicketDetalle td
        JOIN parques.Parque p ON td.id_parque = p.id_parque
        GROUP BY p.nombre, td.fecha_acceso

        UNION ALL

        -- Ingresos por Concesiones
        SELECT 
            p.nombre AS Parque,
            YEAR(pc.fecha_pago) AS Anio,
            MONTH(pc.fecha_pago) AS Mes,
            DATEPART(WEEK, pc.fecha_pago) AS Semana,
            0, 0,
            SUM(pc.monto_pagado) AS Ingreso_Concesiones
        FROM comercial.PagoCanon pc
        JOIN comercial.ObligacionCanon oc ON pc.id_obligacion = oc.id_obligacion
        JOIN comercial.Concesion c ON oc.id_concesion = c.id_concesion
        JOIN parques.Parque p ON c.id_parque = p.id_parque
        GROUP BY p.nombre, pc.fecha_pago
    ) AS consolidados
    GROUP BY Parque, Anio, Mes, Semana
    ORDER BY Parque, Anio, Mes, Semana;
END;
GO
PRINT 'OK - Store Procedure dbo.SP_Ingresos_Parque creado con éxito.';
GO

--------------------------------------------------------------------------------------------------
--2. SP_Ingresos_Parque (Ingresos por parque por semana, mes y año)
--------------------------------------------------------------------------------------------------
--*  Creamos una "tabla temporal en memoria" (Subconsulta). 
-- La parte superior busca los tickets. Usamos un CASE WHEN para separar si es entrada normal (id_atraccion_tour IS NULL) o tour (IS NOT NULL).Rellenamos "Ingreso_Concesiones" con 0.
-- La parte inferior busca los pagos de canon. Rellenamos Entradas y Tours con 0.
-- El UNION ALL une ambas consultas verticalmente.
--* Resultado: A esa tabla unificada le hacemos un GROUP BY final sumando todos los conceptos.

-- =========================================================================
-- 3. DEUDORES (RETORNA XML)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_Deudores_XML' AND type = 'P')
BEGIN
    PRINT 'Eliminando versión anterior de dbo.SP_Deudores_XML...';
    DROP PROCEDURE dbo.SP_Deudores_XML;
END
GO

PRINT 'Creando Store Procedure dbo.SP_Deudores_XML...';
GO
CREATE PROCEDURE dbo.SP_Deudores_XML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.razon_social AS 'Empresa',
        c.tipo_actividad AS 'Actividad',
        oc.mes AS 'Mes',
        oc.anio AS 'Anio',
        (oc.monto_obligado - ISNULL(SUM(pc.monto_pagado), 0)) AS 'MontoAdeudado'
    FROM comercial.ObligacionCanon oc
    JOIN comercial.Concesion c ON oc.id_concesion = c.id_concesion
    JOIN comercial.Empresa e ON c.id_empresa = e.id_empresa
    LEFT JOIN comercial.PagoCanon pc ON oc.id_obligacion = pc.id_obligacion
    WHERE oc.fecha_vencimiento < CAST(GETDATE() AS DATE)
    GROUP BY e.razon_social, c.tipo_actividad, oc.id_obligacion, oc.mes, oc.anio, oc.monto_obligado
    HAVING (oc.monto_obligado - ISNULL(SUM(pc.monto_pagado), 0)) > 0
    FOR XML PATH('Deudor'), ROOT('ReporteDeudores');
END;
GO
PRINT 'OK - Store Procedure dbo.SP_Deudores_XML creado con éxito.';
GO

--------------------------------------------------------------------------------------------------
--3. SP_Deudores_XML (Concesiones atrasadas detallando meses y montos en XML)
--------------------------------------------------------------------------------------------------
--* Búsqueda de morosos: Comparamos las Obligaciones contra los Pagos.
--* LEFT JOIN: Es crítico usar LEFT JOIN hacia los pagos. Si usáramos INNER JOIN, las empresas que NUNCA pagaron (las más deudoras) no aparecerían en el reporte.
--* Manejo de Nulos (ISNULL): Si una empresa nunca pagó, la suma de sus pagos da NULL. En SQL, restar (Deuda - NULL) da error. Usamos ISNULL(SUM(pago), 0) para convertir ese vacío en 0.
--* Generación XML: Usamos FOR XML PATH('Deudor'). Esto convierte cada fila en una etiqueta XML y ROOT('ReporteDeudores') envuelve todo el resultado.

-- =========================================================================
-- 4. MATRIZ DE VISITAS (PIVOT)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_Matriz_Visitas' AND type = 'P')
BEGIN
    PRINT 'Eliminando versión anterior de dbo.SP_Matriz_Visitas...';
    DROP PROCEDURE dbo.SP_Matriz_Visitas;
END
GO

PRINT 'Creando Store Procedure dbo.SP_Matriz_Visitas...';
GO
CREATE PROCEDURE dbo.SP_Matriz_Visitas
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombre AS Parque,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 1 THEN td.cantidad ELSE 0 END) AS Ene,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 2 THEN td.cantidad ELSE 0 END) AS Feb,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 3 THEN td.cantidad ELSE 0 END) AS Mar,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 4 THEN td.cantidad ELSE 0 END) AS Abr,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 5 THEN td.cantidad ELSE 0 END) AS May,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 6 THEN td.cantidad ELSE 0 END) AS Jun,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 7 THEN td.cantidad ELSE 0 END) AS Jul,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 8 THEN td.cantidad ELSE 0 END) AS Ago,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 9 THEN td.cantidad ELSE 0 END) AS Sep,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 10 THEN td.cantidad ELSE 0 END) AS Oct,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 11 THEN td.cantidad ELSE 0 END) AS Nov,
        SUM(CASE WHEN MONTH(td.fecha_acceso) = 12 THEN td.cantidad ELSE 0 END) AS Dic
    FROM ventas.TicketDetalle td
    JOIN parques.Parque p ON td.id_parque = p.id_parque
    GROUP BY p.nombre
    ORDER BY p.nombre;
END;
GO
PRINT 'OK - Store Procedure dbo.SP_Matriz_Visitas creado con éxito.';
GO

--------------------------------------------------------------------------------------------------
--4. SP_Matriz_Visitas (Tabla cruzada/Pivot mostrando visitas por mes y parque)
--------------------------------------------------------------------------------------------------
--* Lógica: Para la columna 'Ene', le decimos a SQL: "Suma la cantidad de visitantes SOLO si el mes es 1, de lo contrario suma 0". Se repite esto 12 veces, una por mes.

-- =========================================================================
-- 5. PARQUES Y CONCESIONES (RETORNA XML ANIDADO)
-- =========================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_Parques_Concesiones_XML' AND type = 'P')
BEGIN
    PRINT 'Eliminando versión anterior de dbo.SP_Parques_Concesiones_XML...';
    DROP PROCEDURE dbo.SP_Parques_Concesiones_XML;
END
GO

PRINT 'Creando Store Procedure dbo.SP_Parques_Concesiones_XML...';
GO
CREATE PROCEDURE dbo.SP_Parques_Concesiones_XML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombre AS '@Nombre',
        (
            SELECT 
                e.razon_social AS 'Titular',
                c.tipo_actividad AS 'Servicio',
                c.fecha_inicio AS 'FechaInicio'
            FROM comercial.Concesion c
            JOIN comercial.Empresa e ON c.id_empresa = e.id_empresa
            WHERE c.id_parque = p.id_parque
            FOR XML PATH('Concesion'), TYPE
        )
    FROM parques.Parque p
    FOR XML PATH('Parque'), ROOT('SistemaParques');
END;
GO
PRINT 'OK - Store Procedure dbo.SP_Parques_Concesiones_XML creado con éxito.';
GO

PRINT '=========================================================================';
PRINT 'FIN DEL SCRIPT: TODOS LOS STORE PROCEDURES FUERON CREADOS';
PRINT '=========================================================================';
GO

--------------------------------------------------------------------------------------------------
--5. SP_Parques_Concesiones_XML (Listado de parques y vector anidado con concesiones)
--------------------------------------------------------------------------------------------------
--* Subconsultas Correlacionadas: Hacemos un SELECT a la tabla Parques. Adentro de sus columnas, abrimos un ( SELECT ... ) anidado que busca las concesiones SOLO para ese parque específico (WHERE c.id_parque = p.id_parque).
--* El comando TYPE: Al FOR XML PATH interno le agregamos la cláusula ", TYPE". Esto le avisa a SQL Server que el resultado de esa subconsulta ya es un bloque XML válido y debe anidarlo como etiquetas reales (y no como texto plano).
--* Atributos XML: Usamos "AS '@Nombre'" para que el nombre del parque quede como un atributo en la etiqueta principal: <Parque Nombre="Iguazú">.