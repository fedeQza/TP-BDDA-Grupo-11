IF DB_ID('ParquesNacionalesDB') IS NULL
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END
GO

USE ParquesNacionalesDB;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'parques')
    EXEC('CREATE SCHEMA parques;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'personal')
    EXEC('CREATE SCHEMA personal;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'turismo')
    EXEC('CREATE SCHEMA turismo;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'comercial')
    EXEC('CREATE SCHEMA comercial;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ventas')
    EXEC('CREATE SCHEMA ventas;');
GO

-- 1. TABLAS MAESTRAS INDEPENDIENTES (Nivel 0)

CREATE TABLE parques.TipoParque (
    id_tipo_parque INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

GO
CREATE TABLE ventas.TipoVisitante (
    id_tipo_visitante INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

GO
CREATE TABLE comercial.Empresa (
    id_empresa INT IDENTITY(1,1) PRIMARY KEY,
    cuit CHAR(11) NOT NULL UNIQUE,
    razon_social VARCHAR(150) NOT NULL,
    telefono VARCHAR(30) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL
);

GO
CREATE TABLE ventas.FormaPago (
    id_forma_pago INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

GO
CREATE TABLE turismo.TipoAtraccion (
    id_tipo_atraccion INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

GO
CREATE TABLE personal.Guardaparque (
    id_guardaparque INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NULL,
    telefono VARCHAR(50) NULL,
    activo BIT NOT NULL DEFAULT 1
);

GO
CREATE TABLE turismo.Guia (
    id_guia INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    especialidad VARCHAR(100) NULL,
    vigencia_autorizacion DATE NOT NULL
);

GO

-- 2. TABLAS CON DEPENDENCIAS DIRECTAS (Nivel 1)

CREATE TABLE parques.Parque (
    id_parque INT IDENTITY(1,1) PRIMARY KEY,
    codigo_oficial VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    superficie DECIMAL(12,2) NOT NULL,
    id_tipo_parque INT NOT NULL,
    CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (id_tipo_parque) REFERENCES parques.TipoParque(id_tipo_parque)
);

GO
CREATE TABLE ventas.Ticket (
    id_ticket INT IDENTITY(1,1) PRIMARY KEY,
    punto_venta CHAR(4) NOT NULL,
    numero VARCHAR(50) NOT NULL,
    fecha_venta DATETIME2 NOT NULL,
    id_forma_pago INT NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_Ticket_FormaPago FOREIGN KEY (id_forma_pago) REFERENCES ventas.FormaPago(id_forma_pago)
);

GO

-- 3. TABLAS ASOCIATIVAS Y HISTORIALES (Nivel 2)

CREATE TABLE personal.HistorialGuardaparque (
    id_historial INT IDENTITY(1,1) PRIMARY KEY,
    id_guardaparque INT NOT NULL,
    id_parque INT NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_egreso DATE NULL,
    motivo_egreso VARCHAR(255) NULL,
    CONSTRAINT FK_HistorialGP_Guardaparque FOREIGN KEY (id_guardaparque) REFERENCES personal.Guardaparque(id_guardaparque),
    CONSTRAINT FK_HistorialGP_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque)
);

GO
CREATE TABLE turismo.GuiaParque (
    id_guia INT NOT NULL,
    id_parque INT NOT NULL,
    fecha_autorizacion DATE NOT NULL,
    estado_autorizacion BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_GuiaParque PRIMARY KEY (id_guia, id_parque),
    CONSTRAINT FK_GuiaParque_Guia FOREIGN KEY (id_guia) REFERENCES turismo.Guia(id_guia),
    CONSTRAINT FK_GuiaParque_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque)
);

GO
CREATE TABLE comercial.Concesion (
    id_concesion INT IDENTITY(1,1) PRIMARY KEY,
    id_parque INT NOT NULL,
    id_empresa INT NOT NULL,
    tipo_actividad VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    canon_mensual DECIMAL(12,2) NOT NULL,
    CONSTRAINT CK_Concesion_Fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT FK_Concesion_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
    CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (id_empresa) REFERENCES comercial.Empresa(id_empresa)
);

GO
CREATE TABLE turismo.AtraccionTour (
    id_atraccion_tour INT IDENTITY(1,1) PRIMARY KEY,
    id_parque INT NOT NULL,
    id_tipo_atraccion INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    costo DECIMAL(12,2) NOT NULL,
    cupo_maximo INT NOT NULL,
    duracion INT NOT NULL,
    CONSTRAINT FK_AtraccionTour_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
    CONSTRAINT FK_AtraccionTour_TipoAtraccion FOREIGN KEY (id_tipo_atraccion) REFERENCES turismo.TipoAtraccion(id_tipo_atraccion)
);

GO
CREATE TABLE ventas.HistorialPrecio (
    id_historial_precio INT IDENTITY(1,1) PRIMARY KEY,
    precio DECIMAL(12,2) NOT NULL,
    fecha_desde DATE NOT NULL,
    id_parque INT NOT NULL,
    id_tipo_visitante INT NOT NULL,
    CONSTRAINT FK_HistorialPrecio_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
    CONSTRAINT FK_HistorialPrecio_TipoVisitante FOREIGN KEY (id_tipo_visitante) REFERENCES ventas.TipoVisitante(id_tipo_visitante)
);

GO

-- 4. DEPENDENCIAS DE ÚLTIMO NIVEL (Nivel 3)

CREATE TABLE turismo.TourGuia (
    id_atraccion_tour INT NOT NULL,
    id_guia INT NOT NULL,
    CONSTRAINT PK_TourGuia PRIMARY KEY (id_atraccion_tour, id_guia),
    CONSTRAINT FK_TourGuia_AtraccionTour FOREIGN KEY (id_atraccion_tour) REFERENCES turismo.AtraccionTour(id_atraccion_tour),
    CONSTRAINT FK_TourGuia_Guia FOREIGN KEY (id_guia) REFERENCES turismo.Guia(id_guia)
);

GO
CREATE TABLE comercial.ObligacionCanon (
    id_obligacion INT IDENTITY(1,1) PRIMARY KEY,
    id_concesion INT NOT NULL,
    mes TINYINT NOT NULL,
    anio SMALLINT NOT NULL,
    monto_obligado DECIMAL(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    CONSTRAINT CK_ObligacionCanon_Mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT UQ_Concesion_Periodo UNIQUE (id_concesion, anio, mes),
    CONSTRAINT FK_ObligacionCanon_Concesion FOREIGN KEY (id_concesion) REFERENCES comercial.Concesion(id_concesion)
);

GO
CREATE TABLE comercial.PagoCanon (
    id_pago INT IDENTITY(1,1) PRIMARY KEY,
    id_obligacion INT NOT NULL,
    fecha_pago DATE NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_PagoCanon_ObligacionCanon FOREIGN KEY (id_obligacion) REFERENCES comercial.ObligacionCanon(id_obligacion)
);

GO
CREATE TABLE ventas.TicketDetalle (
    id_detalle INT IDENTITY(1,1) PRIMARY KEY,
    id_ticket INT NOT NULL,
    id_parque INT NOT NULL,                  
    id_historial_precio INT NULL,            
    id_tipo_visitante INT NULL,              
    id_atraccion_tour INT NULL,
    fecha_acceso DATE NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_TicketDetalle_Ticket FOREIGN KEY (id_ticket) REFERENCES ventas.Ticket(id_ticket),
    CONSTRAINT FK_TicketDetalle_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
    CONSTRAINT FK_TicketDetalle_HistorialPrecio FOREIGN KEY (id_historial_precio) REFERENCES ventas.HistorialPrecio(id_historial_precio),
    CONSTRAINT FK_TicketDetalle_TipoVisitante FOREIGN KEY (id_tipo_visitante) REFERENCES ventas.TipoVisitante(id_tipo_visitante),
    CONSTRAINT FK_TicketDetalle_AtraccionTour FOREIGN KEY (id_atraccion_tour) REFERENCES turismo.AtraccionTour(id_atraccion_tour)
);