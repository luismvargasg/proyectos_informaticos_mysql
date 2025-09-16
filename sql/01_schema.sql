-- schema.sql (MySQL 8.0+)

-- =====================================================================
-- CREACIÓN DE TABLAS
-- =====================================================================

-- Se crea la tabla DOCENTE con sus respectivas restricciones.
CREATE TABLE docente (
  docente_id        INT AUTO_INCREMENT PRIMARY KEY,
  numero_documento  VARCHAR(20)  NOT NULL,
  nombre            VARCHAR(120) NOT NULL,
  direccion         VARCHAR(180),
  titulo            VARCHAR(120),
  anios_experiencia INT NOT NULL DEFAULT 0,
  CONSTRAINT uq_docente_documento UNIQUE (numero_documento),
  CONSTRAINT ck_docente_anios CHECK (anios_experiencia >= 0)
) ENGINE=InnoDB;

-- Se crea la tabla PROYECTO con sus respectivas restricciones.
CREATE TABLE proyecto (
  proyecto_id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre               VARCHAR(120) NOT NULL,
  descripcion          VARCHAR(400),
  presupuesto          DECIMAL(12,2) NOT NULL DEFAULT 0,
  fecha_inicio         DATE NOT NULL,
  fecha_fin            DATE,
  jefe_horas_previstas INT NOT NULL DEFAULT 0,
  jefe_coste           DECIMAL(15,2) NOT NULL DEFAULT 0,
  jefe_docente_id      INT NOT NULL,
  CONSTRAINT ck_proyecto_pres CHECK (presupuesto >= 0),
  CONSTRAINT ck_proyecto_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  CONSTRAINT ck_proyecto_horas CHECK (jefe_horas_previstas >= 0),
  CONSTRAINT ck_proyecto_coste CHECK (jefe_coste >= 0),
  CONSTRAINT fk_proyecto_docente FOREIGN KEY (jefe_docente_id) REFERENCES docente(docente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =====================================================================
-- TABLAS DE AUDITORÍA
-- =====================================================================

-- Se crea la tabla de auditoría para almacenar copias de los DOCENTES actualizados.
CREATE TABLE copia_actualizados_docente (
  auditoria_id      INT AUTO_INCREMENT PRIMARY KEY,
  docente_id        INT NOT NULL,
  numero_documento  VARCHAR(20) NOT NULL,
  nombre            VARCHAR(120) NOT NULL,
  titulo            VARCHAR(120),
  anios_experiencia INT NOT NULL,
  direccion         VARCHAR(180),
  accion_fecha      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql       VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- Se crea la tabla de auditoría para almacenar copias de los DOCENTES eliminados.
CREATE TABLE copia_eliminados_docente (
  auditoria_id      INT AUTO_INCREMENT PRIMARY KEY,
  docente_id        INT NOT NULL,
  numero_documento  VARCHAR(20) NOT NULL,
  nombre            VARCHAR(120) NOT NULL,
  titulo            VARCHAR(120),
  anios_experiencia INT NOT NULL,
  direccion         VARCHAR(180),
  accion_fecha      DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql       VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- Se crea la tabla de auditoría para almacenar copias de los PROYECTOS actualizados.
CREATE TABLE copia_actualizados_proyecto (
  auditoria_id        INT AUTO_INCREMENT PRIMARY KEY,
  proyecto_id         INT NOT NULL,
  nombre              VARCHAR(120) NOT NULL,
  descripcion         VARCHAR(400),
  presupuesto         DECIMAL(12,2) NOT NULL,
  fecha_inicio        DATE NOT NULL,
  fecha_fin           DATE,
  jefe_horas_previstas INT NOT NULL,
  jefe_coste          DECIMAL(15,2) NOT NULL,
  jefe_docente_id     INT NOT NULL,
  accion_fecha        DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql         VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- Se crea la tabla de auditoría para almacenar copias de los PROYECTOS eliminados.
CREATE TABLE copia_eliminados_proyecto (
  auditoria_id        INT AUTO_INCREMENT PRIMARY KEY,
  proyecto_id         INT NOT NULL,
  nombre              VARCHAR(120) NOT NULL,
  descripcion         VARCHAR(400),
  presupuesto         DECIMAL(12,2) NOT NULL,
  fecha_inicio        DATE NOT NULL,
  fecha_fin           DATE,
  jefe_horas_previstas INT NOT NULL,
  jefe_coste          DECIMAL(15,2) NOT NULL,
  jefe_docente_id     INT NOT NULL,
  accion_fecha        DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  usuario_sql         VARCHAR(128) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- =====================================================================
-- PROCEDIMIENTOS ALMACENADOS (CRUD DOCENTE)
-- =====================================================================

-- Se cambia temporalmente el delimitador para permitir el uso de ; dentro de los procedimientos almacenados.
DELIMITER $$

-- Procedimiento para crear un nuevo DOCENTE.
CREATE PROCEDURE sp_docente_create(
  IN p_numero_documento VARCHAR(20),
  IN p_nombre           VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180)
)
BEGIN
  INSERT INTO docente (numero_documento, nombre, titulo, anios_experiencia, direccion)
  VALUES (p_numero_documento, p_nombre, p_titulo, IFNULL(p_anios_experiencia,0), p_direccion);
  SELECT LAST_INSERT_ID() AS docente_id_creado;
END$$

-- Procedimiento para consultar un DOCENTE por su ID.
CREATE PROCEDURE sp_docente_read(IN p_docente_id INT)
BEGIN
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- Procedimiento para actualizar los datos de un DOCENTE.
CREATE PROCEDURE sp_docente_update(
  IN p_docente_id       INT,
  IN p_numero_documento VARCHAR(20),
  IN p_nombre           VARCHAR(120),
  IN p_titulo           VARCHAR(120),
  IN p_anios_experiencia INT,
  IN p_direccion        VARCHAR(180)
)
BEGIN
  UPDATE docente
     SET numero_documento = p_numero_documento,
         nombre = p_nombre,
         titulo = p_titulo,
         anios_experiencia = IFNULL(p_anios_experiencia,0),
         direccion = p_direccion
   WHERE docente_id = p_docente_id;
  SELECT * FROM docente WHERE docente_id = p_docente_id;
END$$

-- Procedimiento para eliminar un DOCENTE.
CREATE PROCEDURE sp_docente_delete(IN p_docente_id INT)
BEGIN
  DELETE FROM docente WHERE docente_id = p_docente_id;
END$$

-- =====================================================================
-- PROCEDIMIENTOS ALMACENADOS (CRUD PROYECTO)
-- =====================================================================

-- Procedimiento para crear un nuevo PROYECTO.
CREATE PROCEDURE sp_proyecto_create(
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicio     DATE,
  IN p_fecha_fin        DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_coste            DECIMAL(15,2),
  IN p_docente_id_jefe  INT
)
BEGIN
  INSERT INTO proyecto (nombre, descripcion, fecha_inicio, fecha_fin, presupuesto, jefe_horas_previstas, jefe_coste, jefe_docente_id)
  VALUES (p_nombre, p_descripcion, p_fecha_inicio, p_fecha_fin, IFNULL(p_presupuesto,0), IFNULL(p_horas,0), IFNULL(p_coste,0), p_docente_id_jefe);
  SELECT LAST_INSERT_ID() AS proyecto_id_creado;
END$$

-- Procedimiento para consultar un PROYECTO por su ID.
CREATE PROCEDURE sp_proyecto_read(IN p_proyecto_id INT)
BEGIN
  SELECT p.*, d.nombre AS nombre_docente_jefe
  FROM proyecto p
  JOIN docente d ON d.docente_id = p.jefe_docente_id
  WHERE p.proyecto_id = p_proyecto_id;
END$$

-- Procedimiento para actualizar los datos de un PROYECTO.
CREATE PROCEDURE sp_proyecto_update(
  IN p_proyecto_id      INT,
  IN p_nombre           VARCHAR(120),
  IN p_descripcion      VARCHAR(400),
  IN p_fecha_inicio     DATE,
  IN p_fecha_fin        DATE,
  IN p_presupuesto      DECIMAL(12,2),
  IN p_horas            INT,
  IN p_coste            DECIMAL(15,2),
  IN p_docente_id_jefe  INT
)
BEGIN
  UPDATE proyecto
     SET nombre = p_nombre,
         descripcion = p_descripcion,
         fecha_inicio = p_fecha_inicio,
         fecha_fin = p_fecha_fin,
         presupuesto = IFNULL(p_presupuesto,0),
         jefe_horas_previstas = IFNULL(p_horas,0),
         jefe_coste = IFNULL(p_coste,0),
         jefe_docente_id = p_docente_id_jefe
   WHERE proyecto_id = p_proyecto_id;
  CALL sp_proyecto_read(p_proyecto_id);
END$$

-- Procedimiento para eliminar un PROYECTO.
CREATE PROCEDURE sp_proyecto_delete(IN p_proyecto_id INT)
BEGIN
  DELETE FROM proyecto WHERE proyecto_id = p_proyecto_id;
END$$

DELIMITER ;

-- =====================================================================
-- FUNCIÓN DEFINIDA POR EL USUARIO (UDF)
-- =====================================================================

-- Se crea una función que devuelve el TOTAL de horas previstas
-- en todos los proyectos en los que un DOCENTE es jefe.
DROP FUNCTION IF EXISTS fn_total_horas_por_docente;
DELIMITER $$
CREATE FUNCTION fn_total_horas_por_docente(p_docente_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total INT;
  SELECT IFNULL(SUM(jefe_horas_previstas),0) INTO v_total
  FROM proyecto
  WHERE jefe_docente_id = p_docente_id;
  RETURN v_total;
END$$
DELIMITER ;

-- =====================================================================
-- TRIGGERS DE AUDITORÍA (DOCENTE)
-- =====================================================================
DELIMITER $$

-- Trigger que guarda una copia de los DOCENTES actualizados.
CREATE TRIGGER tr_docente_after_update
AFTER UPDATE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_actualizados_docente
    (docente_id, numero_documento, nombre, titulo, anios_experiencia, direccion)
  VALUES
    (NEW.docente_id, NEW.numero_documento, NEW.nombre, NEW.titulo, NEW.anios_experiencia, NEW.direccion);
END$$

-- Trigger que guarda una copia de los DOCENTES eliminados.
CREATE TRIGGER tr_docente_after_delete
AFTER DELETE ON docente
FOR EACH ROW
BEGIN
  INSERT INTO copia_eliminados_docente
    (docente_id, numero_documento, nombre, titulo, anios_experiencia, direccion)
  VALUES
    (OLD.docente_id, OLD.numero_documento, OLD.nombre, OLD.titulo, OLD.anios_experiencia, OLD.direccion);
END$$

-- =====================================================================
-- TRIGGERS DE AUDITORÍA (PROYECTO)
-- =====================================================================

-- Trigger que guarda una copia de los PROYECTOS actualizados.
CREATE TRIGGER tr_proyecto_after_update
AFTER UPDATE ON proyecto
FOR EACH ROW
BEGIN
  INSERT INTO copia_actualizados_proyecto
    (proyecto_id, nombre, descripcion, presupuesto, fecha_inicio, fecha_fin, jefe_horas_previstas, jefe_coste, jefe_docente_id)
  VALUES
    (NEW.proyecto_id, NEW.nombre, NEW.descripcion, NEW.presupuesto, NEW.fecha_inicio, NEW.fecha_fin, NEW.jefe_horas_previstas, NEW.jefe_coste, NEW.jefe_docente_id);
END$$

-- Trigger que guarda una copia de los PROYECTOS eliminados.
CREATE TRIGGER tr_proyecto_after_delete
AFTER DELETE ON proyecto
FOR EACH ROW
BEGIN
  INSERT INTO copia_eliminados_proyecto
    (proyecto_id, nombre, descripcion, presupuesto, fecha_inicio, fecha_fin, jefe_horas_previstas, jefe_coste, jefe_docente_id)
  VALUES
    (OLD.proyecto_id, OLD.nombre, OLD.descripcion, OLD.presupuesto, OLD.fecha_inicio, OLD.fecha_fin, OLD.jefe_horas_previstas, OLD.jefe_coste, OLD.jefe_docente_id);
END$$

DELIMITER ;

-- =====================================================================
-- ÍNDICES DE APOYO
-- =====================================================================

-- Se crea un índice para optimizar la búsqueda de proyectos por docente jefe.
CREATE INDEX ix_proyecto_docente ON proyecto(jefe_docente_id);

-- Se crea un índice para optimizar la búsqueda de docentes por documento.
CREATE INDEX ix_docente_documento ON docente(numero_documento);
