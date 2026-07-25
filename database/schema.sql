-- ===================================================================
-- SCRIPT DDL - Proyecto: U-Linker
-- ===================================================================

DROP SCHEMA IF EXISTS u_linker;
CREATE SCHEMA u_linker;
USE u_linker;

-- =====================================================
-- TABLA: usuario
-- =====================================================
CREATE TABLE u_linker.usuario (
    id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL,
    perfil_foto     VARCHAR(255) NULL,
    area            VARCHAR(100) NOT NULL,
    rol             VARCHAR(30) NOT NULL,
    saldo_tokens    INT NOT NULL DEFAULT 0,
    fecha_creacion  DATE NOT NULL DEFAULT (CURRENT_DATE)
);

-- =====================================================
-- TABLA: estudiante (hereda 1:1 de usuario)
-- =====================================================
CREATE TABLE u_linker.estudiante (
    id_estudiante INT PRIMARY KEY,
    semestre      INT NOT NULL,

    CONSTRAINT fk_estudiante_usuario
        FOREIGN KEY (id_estudiante)
        REFERENCES u_linker.usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: tutor (hereda 1:1 de usuario)
-- =====================================================
CREATE TABLE u_linker.tutor (
    id_tutor        INT PRIMARY KEY,
    descripcion     TEXT NULL,
    calif_promedio  FLOAT NOT NULL DEFAULT 0.0,

    CONSTRAINT fk_tutor_usuario
        FOREIGN KEY (id_tutor)
        REFERENCES u_linker.usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: materia (con auto-relacion de prerequisito)
-- =====================================================
CREATE TABLE u_linker.materia (
    id_materia       INT AUTO_INCREMENT PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL UNIQUE,
    creditos         INT NOT NULL,
    id_prerequisito  INT NULL,

    CONSTRAINT fk_materia_prerequisito
        FOREIGN KEY (id_prerequisito)
        REFERENCES u_linker.materia(id_materia)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: materia_aprobada_tutor (M:N con atributo nota >= 4.0)
-- =====================================================
CREATE TABLE u_linker.materia_aprobada_tutor (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    id_tutor    INT NOT NULL,
    id_materia  INT NOT NULL,
    nota        FLOAT NOT NULL,

    CONSTRAINT chk_mat_tutor_nota
        CHECK (nota >= 4.0),

    CONSTRAINT uq_mat_tutor
        UNIQUE (id_tutor, id_materia),

    CONSTRAINT fk_mat_tutor_tutor
        FOREIGN KEY (id_tutor)
        REFERENCES u_linker.tutor(id_tutor)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_mat_tutor_materia
        FOREIGN KEY (id_materia)
        REFERENCES u_linker.materia(id_materia)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: servicio
-- =====================================================
CREATE TABLE u_linker.servicio (
    id_servicio    INT AUTO_INCREMENT PRIMARY KEY,
    id_tutor       INT NOT NULL,
    id_materia     INT NOT NULL,
    nombre         VARCHAR(120) NOT NULL,
    precio_tokens  INT NOT NULL,
    modalidad      VARCHAR(50) NOT NULL,
    descripcion    TEXT NULL,

    CONSTRAINT chk_servicio_precio
        CHECK (precio_tokens > 0),

    CONSTRAINT fk_servicio_tutor
        FOREIGN KEY (id_tutor)
        REFERENCES u_linker.tutor(id_tutor)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_servicio_materia
        FOREIGN KEY (id_materia)
        REFERENCES u_linker.materia(id_materia)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: reunion (M:N estudiante-servicio con atributos propios)
-- =====================================================
CREATE TABLE u_linker.reunion (
    id_reunion       INT AUTO_INCREMENT PRIMARY KEY,
    id_tutor         INT NOT NULL,
    id_estudiante    INT NOT NULL,
    id_servicio      INT NOT NULL,
    fecha            DATE NOT NULL,
    hora_inicio      TIME NOT NULL,
    hora_fin         TIME NOT NULL,
    tema             VARCHAR(255) NULL,
    estado           VARCHAR(30) NOT NULL DEFAULT 'Agendada',
    tokens_cobrados  INT NOT NULL,

    CONSTRAINT chk_reunion_horario
        CHECK (hora_fin > hora_inicio),

    CONSTRAINT chk_reunion_estado
        CHECK (estado IN ('Agendada', 'Finalizada', 'Cancelada')),

    CONSTRAINT fk_reunion_tutor
        FOREIGN KEY (id_tutor)
        REFERENCES u_linker.tutor(id_tutor)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_reunion_estudiante
        FOREIGN KEY (id_estudiante)
        REFERENCES u_linker.estudiante(id_estudiante)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_reunion_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES u_linker.servicio(id_servicio)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: resena (evaluacion de tutor por estudiante y materia)
-- =====================================================
CREATE TABLE u_linker.resena (
    id_resena      INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante  INT NOT NULL,
    id_tutor       INT NOT NULL,
    id_materia     INT NOT NULL,
    calificacion   INT NOT NULL,
    texto          TEXT NULL,

    CONSTRAINT chk_resena_calificacion
        CHECK (calificacion BETWEEN 1 AND 5),

    CONSTRAINT uq_resena
        UNIQUE (id_estudiante, id_tutor, id_materia),

    CONSTRAINT fk_resena_estudiante
        FOREIGN KEY (id_estudiante)
        REFERENCES u_linker.estudiante(id_estudiante)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_resena_tutor
        FOREIGN KEY (id_tutor)
        REFERENCES u_linker.tutor(id_tutor)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_resena_materia
        FOREIGN KEY (id_materia)
        REFERENCES u_linker.materia(id_materia)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: baneos
-- =====================================================
CREATE TABLE u_linker.baneos (
    id_baneo      INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario    INT NOT NULL,
    motivo        TEXT NOT NULL,
    fecha_inicio  DATETIME NOT NULL,
    fecha_fin     DATETIME NOT NULL,

    CONSTRAINT chk_baneo_rango
        CHECK (fecha_fin > fecha_inicio),

    CONSTRAINT fk_baneo_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES u_linker.usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =====================================================
-- TABLA: movimiento_token (auditoria de transacciones)
-- =====================================================
CREATE TABLE u_linker.movimiento_token (
    id_movimiento  INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario     INT NOT NULL,
    cantidad       INT NOT NULL,
    fecha          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_movtoken_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES u_linker.usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);