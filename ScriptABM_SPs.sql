/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Stored Procedures para operaciones ABM (Alta,
             Baja, Modificación) de todas las tablas del
             sistema de gestión de Parques Nacionales.
             Ninguna operación ABM debe realizarse accediendo
             directamente a las tablas.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- SCHEMA: parques  |  TABLA: TipoParque
-- ==============================================================

CREATE PROCEDURE parques.sp_InsertarTipoParque
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción del tipo de parque es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de parque con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO parques.TipoParque (descripcion) VALUES (@p_descripcion);
END
GO

CREATE PROCEDURE parques.sp_ModificarTipoParque
    @p_id_tipo_parque INT,
    @p_descripcion    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @p_descripcion AND id_tipo_parque != @p_id_tipo_parque)
        SET @errores += N'- Ya existe otro tipo de parque con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE parques.TipoParque SET descripcion = @p_descripcion WHERE id_tipo_parque = @p_id_tipo_parque;
END
GO

CREATE PROCEDURE parques.sp_EliminarTipoParque
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No se puede eliminar: existen parques asociados a este tipo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: TipoVisitante
-- ==============================================================

CREATE PROCEDURE ventas.sp_InsertarTipoVisitante
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de visitante con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO ventas.TipoVisitante (descripcion) VALUES (@p_descripcion);
END
GO

CREATE PROCEDURE ventas.sp_ModificarTipoVisitante
    @p_id_tipo_visitante INT,
    @p_descripcion       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @p_descripcion AND id_tipo_visitante != @p_id_tipo_visitante)
        SET @errores += N'- Ya existe otro tipo de visitante con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE ventas.TipoVisitante SET descripcion = @p_descripcion WHERE id_tipo_visitante = @p_id_tipo_visitante;
END
GO

CREATE PROCEDURE ventas.sp_EliminarTipoVisitante
    @p_id_tipo_visitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No se puede eliminar: existen precios asociados a este tipo de visitante.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No se puede eliminar: existen detalles de ticket asociados a este tipo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: FormaPago
-- ==============================================================

CREATE PROCEDURE ventas.sp_InsertarFormaPago
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe una forma de pago con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO ventas.FormaPago (descripcion) VALUES (@p_descripcion);
END
GO

CREATE PROCEDURE ventas.sp_ModificarFormaPago
    @p_id_forma_pago INT,
    @p_descripcion   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE ventas.FormaPago SET descripcion = @p_descripcion WHERE id_forma_pago = @p_id_forma_pago;
END
GO

CREATE PROCEDURE ventas.sp_EliminarFormaPago
    @p_id_forma_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No se puede eliminar: existen tickets asociados a esta forma de pago.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: TipoAtraccion
-- ==============================================================

CREATE PROCEDURE turismo.sp_InsertarTipoAtraccion
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de atracción con esa descripción.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO turismo.TipoAtraccion (descripcion) VALUES (@p_descripcion);
END
GO

CREATE PROCEDURE turismo.sp_ModificarTipoAtraccion
    @p_id_tipo_atraccion INT,
    @p_descripcion       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No existe un tipo de atracción con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE turismo.TipoAtraccion SET descripcion = @p_descripcion WHERE id_tipo_atraccion = @p_id_tipo_atraccion;
END
GO

CREATE PROCEDURE turismo.sp_EliminarTipoAtraccion
    @p_id_tipo_atraccion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No existe un tipo de atracción con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No se puede eliminar: existen atracciones/tours asociados a este tipo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion;
END
GO

-- ==============================================================
-- SCHEMA: personal  |  TABLA: Guardaparque
-- Baja lógica: se marca activo = 0
-- ==============================================================

CREATE PROCEDURE personal.sp_InsertarGuardaparque
    @p_nombre   VARCHAR(50),
    @p_apellido VARCHAR(50),
    @p_dni      VARCHAR(20),
    @p_email    VARCHAR(100) = NULL,
    @p_telefono VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @p_dni)
        SET @errores += N'- Ya existe un guardaparque registrado con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO personal.Guardaparque (nombre, apellido, dni, email, telefono, activo)
    VALUES (@p_nombre, @p_apellido, @p_dni, @p_email, @p_telefono, 1);
END
GO

CREATE PROCEDURE personal.sp_ModificarGuardaparque
    @p_id_guardaparque INT,
    @p_nombre          VARCHAR(50),
    @p_apellido        VARCHAR(50),
    @p_dni             VARCHAR(20),
    @p_email           VARCHAR(100) = NULL,
    @p_telefono        VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @p_dni AND id_guardaparque != @p_id_guardaparque)
        SET @errores += N'- Ya existe otro guardaparque con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE personal.Guardaparque
    SET nombre = @p_nombre, apellido = @p_apellido, dni = @p_dni,
        email = @p_email, telefono = @p_telefono
    WHERE id_guardaparque = @p_id_guardaparque;
END
GO

CREATE PROCEDURE personal.sp_EliminarGuardaparque
    @p_id_guardaparque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque AND activo = 0)
        SET @errores += N'- El guardaparque ya se encuentra inactivo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE personal.Guardaparque SET activo = 0 WHERE id_guardaparque = @p_id_guardaparque;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: Guia
-- ==============================================================

CREATE PROCEDURE turismo.sp_InsertarGuia
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni = @p_dni)
        SET @errores += N'- Ya existe un guía registrado con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO turismo.Guia (nombre, apellido, dni, especialidad, vigencia_autorizacion)
    VALUES (@p_nombre, @p_apellido, @p_dni, @p_especialidad, @p_vigencia_autorizacion);
END
GO

CREATE PROCEDURE turismo.sp_ModificarGuia
    @p_id_guia               INT,
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No existe un guía con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni = @p_dni AND id_guia != @p_id_guia)
        SET @errores += N'- Ya existe otro guía con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE turismo.Guia
    SET nombre = @p_nombre, apellido = @p_apellido, dni = @p_dni,
        especialidad = @p_especialidad, vigencia_autorizacion = @p_vigencia_autorizacion
    WHERE id_guia = @p_id_guia;
END
GO

CREATE PROCEDURE turismo.sp_EliminarGuia
    @p_id_guia INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No existe un guía con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia)
        SET @errores += N'- No se puede eliminar: el guía tiene habilitaciones en parques registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No se puede eliminar: el guía está asignado a uno o más tours.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM turismo.Guia WHERE id_guia = @p_id_guia;
END
GO

-- ==============================================================
-- SCHEMA: parques  |  TABLA: Parque
-- ==============================================================

CREATE PROCEDURE parques.sp_InsertarParque
    @p_codigo_oficial VARCHAR(50),
    @p_nombre         VARCHAR(100),
    @p_ubicacion      VARCHAR(255),
    @p_superficie     DECIMAL(12,2),
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_codigo_oficial, ''))) = ''
        SET @errores += N'- El código oficial es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial = @p_codigo_oficial)
        SET @errores += N'- Ya existe un parque con ese código oficial.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre del parque es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_ubicacion, ''))) = ''
        SET @errores += N'- La ubicación del parque es obligatoria.' + CHAR(13);
    IF ISNULL(@p_superficie, 0) <= 0
        SET @errores += N'- La superficie debe ser mayor a cero.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- El tipo de parque indicado no existe.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO parques.Parque (codigo_oficial, nombre, ubicacion, superficie, id_tipo_parque)
    VALUES (@p_codigo_oficial, @p_nombre, @p_ubicacion, @p_superficie, @p_id_tipo_parque);
END
GO

CREATE PROCEDURE parques.sp_ModificarParque
    @p_id_parque      INT,
    @p_codigo_oficial VARCHAR(50),
    @p_nombre         VARCHAR(100),
    @p_ubicacion      VARCHAR(255),
    @p_superficie     DECIMAL(12,2),
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No existe un parque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_codigo_oficial, ''))) = ''
        SET @errores += N'- El código oficial es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial = @p_codigo_oficial AND id_parque != @p_id_parque)
        SET @errores += N'- Ya existe otro parque con ese código oficial.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre del parque es obligatorio.' + CHAR(13);
    IF ISNULL(@p_superficie, 0) <= 0
        SET @errores += N'- La superficie debe ser mayor a cero.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- El tipo de parque indicado no existe.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE parques.Parque
    SET codigo_oficial = @p_codigo_oficial, nombre = @p_nombre, ubicacion = @p_ubicacion,
        superficie = @p_superficie, id_tipo_parque = @p_id_tipo_parque
    WHERE id_parque = @p_id_parque;
END
GO

CREATE PROCEDURE parques.sp_EliminarParque
    @p_id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No existe un parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene concesiones registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.HistorialGuardaparque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene historial de guardaparques.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene atracciones/tours registrados.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene historial de precios registrado.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM parques.Parque WHERE id_parque = @p_id_parque;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: Empresa
-- ==============================================================

CREATE PROCEDURE comercial.sp_InsertarEmpresa
    @p_cuit         CHAR(11),
    @p_razon_social VARCHAR(150),
    @p_telefono     VARCHAR(30)  = NULL,
    @p_email        VARCHAR(100) = NULL,
    @p_direccion    VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_cuit, ''))) = ''
        SET @errores += N'- El CUIT es obligatorio.' + CHAR(13);
    IF ISNULL(@p_cuit, '') NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        SET @errores += N'- El CUIT debe contener exactamente 11 dígitos numéricos.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit = @p_cuit)
        SET @errores += N'- Ya existe una empresa registrada con ese CUIT.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_razon_social, ''))) = ''
        SET @errores += N'- La razón social es obligatoria.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO comercial.Empresa (cuit, razon_social, telefono, email, direccion)
    VALUES (@p_cuit, @p_razon_social, @p_telefono, @p_email, @p_direccion);
END
GO

CREATE PROCEDURE comercial.sp_ModificarEmpresa
    @p_id_empresa   INT,
    @p_cuit         CHAR(11),
    @p_razon_social VARCHAR(150),
    @p_telefono     VARCHAR(30)  = NULL,
    @p_email        VARCHAR(100) = NULL,
    @p_direccion    VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No existe una empresa con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_cuit, '') NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        SET @errores += N'- El CUIT debe contener exactamente 11 dígitos numéricos.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit = @p_cuit AND id_empresa != @p_id_empresa)
        SET @errores += N'- Ya existe otra empresa registrada con ese CUIT.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_razon_social, ''))) = ''
        SET @errores += N'- La razón social es obligatoria.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE comercial.Empresa
    SET cuit = @p_cuit, razon_social = @p_razon_social, telefono = @p_telefono,
        email = @p_email, direccion = @p_direccion
    WHERE id_empresa = @p_id_empresa;
END
GO

CREATE PROCEDURE comercial.sp_EliminarEmpresa
    @p_id_empresa INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No existe una empresa con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No se puede eliminar: la empresa tiene concesiones registradas.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM comercial.Empresa WHERE id_empresa = @p_id_empresa;
END
GO

-- ==============================================================
-- SCHEMA: personal  |  TABLA: HistorialGuardaparque
-- ==============================================================

CREATE PROCEDURE personal.sp_InsertarHistorialGuardaparque
    @p_id_guardaparque INT,
    @p_id_parque       INT,
    @p_fecha_ingreso   DATE,
    @p_fecha_egreso    DATE         = NULL,
    @p_motivo_egreso   VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- El guardaparque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF @p_fecha_ingreso IS NULL
        SET @errores += N'- La fecha de ingreso es obligatoria.' + CHAR(13);
    IF @p_fecha_egreso IS NOT NULL AND @p_fecha_egreso < @p_fecha_ingreso
        SET @errores += N'- La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13);
    IF @p_fecha_egreso IS NULL AND @p_motivo_egreso IS NOT NULL
        SET @errores += N'- No se puede registrar motivo de egreso sin una fecha de egreso.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM personal.HistorialGuardaparque
        WHERE id_guardaparque = @p_id_guardaparque AND fecha_egreso IS NULL
    )
        SET @errores += N'- El guardaparque ya tiene un período activo sin fecha de egreso. Ciérrelo antes de iniciar uno nuevo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO personal.HistorialGuardaparque (id_guardaparque, id_parque, fecha_ingreso, fecha_egreso, motivo_egreso)
    VALUES (@p_id_guardaparque, @p_id_parque, @p_fecha_ingreso, @p_fecha_egreso, @p_motivo_egreso);
END
GO

CREATE PROCEDURE personal.sp_ModificarHistorialGuardaparque
    @p_id_historial  INT,
    @p_fecha_egreso  DATE         = NULL,
    @p_motivo_egreso VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @fecha_ingreso DATE;

    SELECT @fecha_ingreso = fecha_ingreso
    FROM personal.HistorialGuardaparque
    WHERE id_historial = @p_id_historial;

    IF @fecha_ingreso IS NULL
        SET @errores += N'- No existe un historial con el ID indicado.' + CHAR(13);
    IF @p_fecha_egreso IS NOT NULL AND @fecha_ingreso IS NOT NULL AND @p_fecha_egreso < @fecha_ingreso
        SET @errores += N'- La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13);
    IF @p_fecha_egreso IS NULL AND @p_motivo_egreso IS NOT NULL
        SET @errores += N'- No se puede registrar motivo de egreso sin una fecha de egreso.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE personal.HistorialGuardaparque
    SET fecha_egreso = @p_fecha_egreso, motivo_egreso = @p_motivo_egreso
    WHERE id_historial = @p_id_historial;
END
GO

CREATE PROCEDURE personal.sp_EliminarHistorialGuardaparque
    @p_id_historial INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.HistorialGuardaparque WHERE id_historial = @p_id_historial)
        SET @errores += N'- No existe un historial con el ID indicado.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM personal.HistorialGuardaparque WHERE id_historial = @p_id_historial;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: GuiaParque
-- ==============================================================

CREATE PROCEDURE turismo.sp_InsertarGuiaParque
    @p_id_guia             INT,
    @p_id_parque           INT,
    @p_fecha_autorizacion  DATE,
    @p_estado_autorizacion BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- El guía indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- El guía ya tiene una habilitación registrada para ese parque.' + CHAR(13);
    IF @p_fecha_autorizacion IS NULL
        SET @errores += N'- La fecha de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO turismo.GuiaParque (id_guia, id_parque, fecha_autorizacion, estado_autorizacion)
    VALUES (@p_id_guia, @p_id_parque, @p_fecha_autorizacion, @p_estado_autorizacion);
END
GO

CREATE PROCEDURE turismo.sp_ModificarGuiaParque
    @p_id_guia             INT,
    @p_id_parque           INT,
    @p_fecha_autorizacion  DATE,
    @p_estado_autorizacion BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- No existe una habilitación para el guía y parque indicados.' + CHAR(13);
    IF @p_fecha_autorizacion IS NULL
        SET @errores += N'- La fecha de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE turismo.GuiaParque
    SET fecha_autorizacion = @p_fecha_autorizacion, estado_autorizacion = @p_estado_autorizacion
    WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque;
END
GO

CREATE PROCEDURE turismo.sp_EliminarGuiaParque
    @p_id_guia   INT,
    @p_id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- No existe una habilitación para el guía y parque indicados.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: AtraccionTour
-- ==============================================================

CREATE PROCEDURE turismo.sp_InsertarAtraccionTour
    @p_id_parque         INT,
    @p_id_tipo_atraccion INT,
    @p_nombre            VARCHAR(100),
    @p_costo             DECIMAL(12,2),
    @p_cupo_maximo       INT,
    @p_duracion          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- El tipo de atracción indicado no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre de la atracción/tour es obligatorio.' + CHAR(13);
    IF ISNULL(@p_costo, -1) < 0
        SET @errores += N'- El costo no puede ser negativo (use 0 para atracciones gratuitas).' + CHAR(13);
    IF ISNULL(@p_cupo_maximo, 0) <= 0
        SET @errores += N'- El cupo máximo debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_duracion, 0) <= 0
        SET @errores += N'- La duración debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO turismo.AtraccionTour (id_parque, id_tipo_atraccion, nombre, costo, cupo_maximo, duracion)
    VALUES (@p_id_parque, @p_id_tipo_atraccion, @p_nombre, @p_costo, @p_cupo_maximo, @p_duracion);
END
GO

CREATE PROCEDURE turismo.sp_ModificarAtraccionTour
    @p_id_atraccion_tour INT,
    @p_id_tipo_atraccion INT,
    @p_nombre            VARCHAR(100),
    @p_costo             DECIMAL(12,2),
    @p_cupo_maximo       INT,
    @p_duracion          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No existe una atracción/tour con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- El tipo de atracción indicado no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF ISNULL(@p_costo, -1) < 0
        SET @errores += N'- El costo no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_cupo_maximo, 0) <= 0
        SET @errores += N'- El cupo máximo debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_duracion, 0) <= 0
        SET @errores += N'- La duración debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE turismo.AtraccionTour
    SET id_tipo_atraccion = @p_id_tipo_atraccion, nombre = @p_nombre, costo = @p_costo,
        cupo_maximo = @p_cupo_maximo, duracion = @p_duracion
    WHERE id_atraccion_tour = @p_id_atraccion_tour;
END
GO

CREATE PROCEDURE turismo.sp_EliminarAtraccionTour
    @p_id_atraccion_tour INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No existe una atracción/tour con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No se puede eliminar: la atracción/tour tiene ventas registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No se puede eliminar: la atracción/tour tiene guías asignados.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: TourGuia
-- ==============================================================

CREATE PROCEDURE turismo.sp_InsertarTourGuia
    @p_id_atraccion_tour INT,
    @p_id_guia           INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @id_parque_tour INT;

    SELECT @id_parque_tour = id_parque
    FROM turismo.AtraccionTour
    WHERE id_atraccion_tour = @p_id_atraccion_tour;

    IF @id_parque_tour IS NULL
        SET @errores += N'- La atracción/tour indicada no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- El guía indicado no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia)
        SET @errores += N'- El guía ya está asignado a esa atracción/tour.' + CHAR(13);
    IF @id_parque_tour IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM turismo.GuiaParque
        WHERE id_guia = @p_id_guia AND id_parque = @id_parque_tour AND estado_autorizacion = 1
    )
        SET @errores += N'- El guía no tiene habilitación activa en el parque al que pertenece el tour.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO turismo.TourGuia (id_atraccion_tour, id_guia)
    VALUES (@p_id_atraccion_tour, @p_id_guia);
END
GO

CREATE PROCEDURE turismo.sp_EliminarTourGuia
    @p_id_atraccion_tour INT,
    @p_id_guia           INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia)
        SET @errores += N'- No existe la asignación entre el guía y la atracción/tour indicados.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: HistorialPrecio
-- ==============================================================

CREATE PROCEDURE ventas.sp_InsertarHistorialPrecio
    @p_precio            DECIMAL(12,2),
    @p_fecha_desde       DATE,
    @p_id_parque         INT,
    @p_id_tipo_visitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF ISNULL(@p_precio, -1) < 0
        SET @errores += N'- El precio no puede ser negativo.' + CHAR(13);
    IF @p_fecha_desde IS NULL
        SET @errores += N'- La fecha de vigencia es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO ventas.HistorialPrecio (precio, fecha_desde, id_parque, id_tipo_visitante)
    VALUES (@p_precio, @p_fecha_desde, @p_id_parque, @p_id_tipo_visitante);
END
GO

CREATE PROCEDURE ventas.sp_ModificarHistorialPrecio
    @p_id_historial_precio INT,
    @p_precio              DECIMAL(12,2),
    @p_fecha_desde         DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No existe un registro de precio con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_precio, -1) < 0
        SET @errores += N'- El precio no puede ser negativo.' + CHAR(13);
    IF @p_fecha_desde IS NULL
        SET @errores += N'- La fecha de vigencia es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE ventas.HistorialPrecio
    SET precio = @p_precio, fecha_desde = @p_fecha_desde
    WHERE id_historial_precio = @p_id_historial_precio;
END
GO

CREATE PROCEDURE ventas.sp_EliminarHistorialPrecio
    @p_id_historial_precio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No existe un registro de precio con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No se puede eliminar: el precio está referenciado en detalles de tickets.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: Concesion
-- ==============================================================

CREATE PROCEDURE comercial.sp_InsertarConcesion
    @p_id_parque      INT,
    @p_id_empresa     INT,
    @p_tipo_actividad VARCHAR(100),
    @p_fecha_inicio   DATE,
    @p_fecha_fin      DATE,
    @p_canon_mensual  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- La empresa indicada no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_tipo_actividad, ''))) = ''
        SET @errores += N'- El tipo de actividad es obligatorio.' + CHAR(13);
    IF @p_fecha_inicio IS NULL OR @p_fecha_fin IS NULL
        SET @errores += N'- Las fechas de inicio y fin son obligatorias.' + CHAR(13);
    IF @p_fecha_inicio IS NOT NULL AND @p_fecha_fin IS NOT NULL AND @p_fecha_fin < @p_fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + CHAR(13);
    IF ISNULL(@p_canon_mensual, 0) <= 0
        SET @errores += N'- El canon mensual debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO comercial.Concesion (id_parque, id_empresa, tipo_actividad, fecha_inicio, fecha_fin, canon_mensual)
    VALUES (@p_id_parque, @p_id_empresa, @p_tipo_actividad, @p_fecha_inicio, @p_fecha_fin, @p_canon_mensual);
END
GO

CREATE PROCEDURE comercial.sp_ModificarConcesion
    @p_id_concesion   INT,
    @p_tipo_actividad VARCHAR(100),
    @p_fecha_inicio   DATE,
    @p_fecha_fin      DATE,
    @p_canon_mensual  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No existe una concesión con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_tipo_actividad, ''))) = ''
        SET @errores += N'- El tipo de actividad es obligatorio.' + CHAR(13);
    IF @p_fecha_inicio IS NOT NULL AND @p_fecha_fin IS NOT NULL AND @p_fecha_fin < @p_fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + CHAR(13);
    IF ISNULL(@p_canon_mensual, 0) <= 0
        SET @errores += N'- El canon mensual debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE comercial.Concesion
    SET tipo_actividad = @p_tipo_actividad, fecha_inicio = @p_fecha_inicio,
        fecha_fin = @p_fecha_fin, canon_mensual = @p_canon_mensual
    WHERE id_concesion = @p_id_concesion;
END
GO

CREATE PROCEDURE comercial.sp_EliminarConcesion
    @p_id_concesion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No existe una concesión con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No se puede eliminar: la concesión tiene obligaciones de canon registradas.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM comercial.Concesion WHERE id_concesion = @p_id_concesion;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: ObligacionCanon
-- ==============================================================

CREATE PROCEDURE comercial.sp_InsertarObligacionCanon
    @p_id_concesion      INT,
    @p_mes               TINYINT,
    @p_anio              SMALLINT,
    @p_monto_obligado    DECIMAL(12,2),
    @p_estado            VARCHAR(20),
    @p_fecha_vencimiento DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- La concesión indicada no existe.' + CHAR(13);
    IF ISNULL(@p_mes, 0) NOT BETWEEN 1 AND 12
        SET @errores += N'- El mes debe estar entre 1 y 12.' + CHAR(13);
    IF ISNULL(@p_anio, 0) NOT BETWEEN 2000 AND 2100
        SET @errores += N'- El año debe estar entre 2000 y 2100.' + CHAR(13);
    IF ISNULL(@p_monto_obligado, 0) <= 0
        SET @errores += N'- El monto obligado debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_estado, '') NOT IN ('PENDIENTE', 'PAGADO', 'VENCIDO', 'PARCIAL')
        SET @errores += N'- El estado debe ser uno de los siguientes: PENDIENTE, PAGADO, VENCIDO, PARCIAL.' + CHAR(13);
    IF @p_fecha_vencimiento IS NULL
        SET @errores += N'- La fecha de vencimiento es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_concesion = @p_id_concesion AND anio = @p_anio AND mes = @p_mes)
        SET @errores += N'- Ya existe una obligación para esa concesión en el período indicado.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
    VALUES (@p_id_concesion, @p_mes, @p_anio, @p_monto_obligado, @p_estado, @p_fecha_vencimiento);
END
GO

CREATE PROCEDURE comercial.sp_ModificarObligacionCanon
    @p_id_obligacion     INT,
    @p_monto_obligado    DECIMAL(12,2),
    @p_estado            VARCHAR(20),
    @p_fecha_vencimiento DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No existe una obligación con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_monto_obligado, 0) <= 0
        SET @errores += N'- El monto obligado debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_estado, '') NOT IN ('PENDIENTE', 'PAGADO', 'VENCIDO', 'PARCIAL')
        SET @errores += N'- El estado debe ser uno de los siguientes: PENDIENTE, PAGADO, VENCIDO, PARCIAL.' + CHAR(13);
    IF @p_fecha_vencimiento IS NULL
        SET @errores += N'- La fecha de vencimiento es obligatoria.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE comercial.ObligacionCanon
    SET monto_obligado = @p_monto_obligado, estado = @p_estado, fecha_vencimiento = @p_fecha_vencimiento
    WHERE id_obligacion = @p_id_obligacion;
END
GO

CREATE PROCEDURE comercial.sp_EliminarObligacionCanon
    @p_id_obligacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No existe una obligación con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.PagoCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No se puede eliminar: la obligación tiene pagos registrados.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: PagoCanon
-- ==============================================================

CREATE PROCEDURE comercial.sp_InsertarPagoCanon
    @p_id_obligacion INT,
    @p_fecha_pago    DATE,
    @p_monto_pagado  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- La obligación indicada no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion AND estado = 'PAGADO')
        SET @errores += N'- La obligación ya se encuentra completamente pagada.' + CHAR(13);
    IF @p_fecha_pago IS NULL
        SET @errores += N'- La fecha de pago es obligatoria.' + CHAR(13);
    IF ISNULL(@p_monto_pagado, 0) <= 0
        SET @errores += N'- El monto pagado debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO comercial.PagoCanon (id_obligacion, fecha_pago, monto_pagado)
    VALUES (@p_id_obligacion, @p_fecha_pago, @p_monto_pagado);
END
GO

CREATE PROCEDURE comercial.sp_EliminarPagoCanon
    @p_id_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.PagoCanon WHERE id_pago = @p_id_pago)
        SET @errores += N'- No existe un pago con el ID indicado.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM comercial.PagoCanon WHERE id_pago = @p_id_pago;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: Ticket
-- ==============================================================

CREATE PROCEDURE ventas.sp_InsertarTicket
    @p_punto_venta   CHAR(4),
    @p_numero        VARCHAR(50),
    @p_fecha_venta   DATETIME2,
    @p_id_forma_pago INT,
    @p_total         DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF ISNULL(@p_punto_venta, '') NOT LIKE '[0-9][0-9][0-9][0-9]'
        SET @errores += N'- El punto de venta debe contener exactamente 4 dígitos numéricos.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_numero, ''))) = ''
        SET @errores += N'- El número de ticket es obligatorio.' + CHAR(13);
    IF @p_fecha_venta IS NULL
        SET @errores += N'- La fecha de venta es obligatoria.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- La forma de pago indicada no existe.' + CHAR(13);
    IF ISNULL(@p_total, -1) < 0
        SET @errores += N'- El total no puede ser negativo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
    VALUES (@p_punto_venta, @p_numero, @p_fecha_venta, @p_id_forma_pago, @p_total);
END
GO

CREATE PROCEDURE ventas.sp_ModificarTicket
    @p_id_ticket     INT,
    @p_id_forma_pago INT,
    @p_total         DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No existe un ticket con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- La forma de pago indicada no existe.' + CHAR(13);
    IF ISNULL(@p_total, -1) < 0
        SET @errores += N'- El total no puede ser negativo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE ventas.Ticket
    SET id_forma_pago = @p_id_forma_pago, total = @p_total
    WHERE id_ticket = @p_id_ticket;
END
GO

CREATE PROCEDURE ventas.sp_EliminarTicket
    @p_id_ticket INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No existe un ticket con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No se puede eliminar: el ticket tiene líneas de detalle asociadas.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM ventas.Ticket WHERE id_ticket = @p_id_ticket;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: TicketDetalle
-- ==============================================================

CREATE PROCEDURE ventas.sp_InsertarTicketDetalle
    @p_id_ticket           INT,
    @p_id_parque           INT,
    @p_id_historial_precio INT          = NULL,
    @p_id_tipo_visitante   INT          = NULL,
    @p_id_atraccion_tour   INT          = NULL,
    @p_fecha_acceso        DATE,
    @p_cantidad            INT,
    @p_precio_unitario     DECIMAL(12,2),
    @p_subtotal            DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- El ticket indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF @p_id_historial_precio IS NULL AND @p_id_atraccion_tour IS NULL
        SET @errores += N'- El detalle debe corresponder a una entrada (precio) o a una atracción/tour.' + CHAR(13);
    IF @p_id_historial_precio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- El historial de precio indicado no existe.' + CHAR(13);
    IF @p_id_tipo_visitante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF @p_id_atraccion_tour IS NOT NULL AND NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- La atracción/tour indicada no existe.' + CHAR(13);
    IF @p_fecha_acceso IS NULL
        SET @errores += N'- La fecha de acceso es obligatoria.' + CHAR(13);
    IF ISNULL(@p_cantidad, 0) <= 0
        SET @errores += N'- La cantidad debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_precio_unitario, -1) < 0
        SET @errores += N'- El precio unitario no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_subtotal, -1) < 0
        SET @errores += N'- El subtotal no puede ser negativo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    INSERT INTO ventas.TicketDetalle
        (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour,
         fecha_acceso, cantidad, precio_unitario, subtotal)
    VALUES
        (@p_id_ticket, @p_id_parque, @p_id_historial_precio, @p_id_tipo_visitante, @p_id_atraccion_tour,
         @p_fecha_acceso, @p_cantidad, @p_precio_unitario, @p_subtotal);
END
GO

CREATE PROCEDURE ventas.sp_ModificarTicketDetalle
    @p_id_detalle      INT,
    @p_cantidad        INT,
    @p_precio_unitario DECIMAL(12,2),
    @p_subtotal        DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle)
        SET @errores += N'- No existe un detalle de ticket con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_cantidad, 0) <= 0
        SET @errores += N'- La cantidad debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_precio_unitario, -1) < 0
        SET @errores += N'- El precio unitario no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_subtotal, -1) < 0
        SET @errores += N'- El subtotal no puede ser negativo.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    UPDATE ventas.TicketDetalle
    SET cantidad = @p_cantidad, precio_unitario = @p_precio_unitario, subtotal = @p_subtotal
    WHERE id_detalle = @p_id_detalle;
END
GO

CREATE PROCEDURE ventas.sp_EliminarTicketDetalle
    @p_id_detalle INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle)
        SET @errores += N'- No existe un detalle de ticket con el ID indicado.' + CHAR(13);

    IF @errores != N'' BEGIN RAISERROR(@errores, 16, 1); RETURN; END

    DELETE FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle;
END
GO
