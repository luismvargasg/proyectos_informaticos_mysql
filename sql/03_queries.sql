-- queries.sql (MySQL 8.0+)

-- =====================================================================
-- Los siguientes queries están diseñados para ser ejecutados después de
-- haber cargado completamente los scripts de 'schema.sql' y 'seed.sql'.
-- =====================================================================

-- Q0: Usa la base de datos 'proyectos_informaticos' para todas las operaciones.
USE proyectos_informaticos;

-- Q1: Lista todos los proyectos y el nombre del docente que los lidera.
-- Esta consulta une la información de la tabla 'proyecto' con la de 'docente'
-- para mostrar el nombre del proyecto junto con el nombre del docente_jefe.
SELECT
    p.proyecto_id,
    p.nombre AS proyecto,
    d.nombre AS docente_jefe
FROM
    proyecto p
JOIN
    docente d ON d.docente_id = p.jefe_docente_id;

-- Q2: Obtiene el total de horas de proyectos para cada docente.
-- Esta consulta utiliza la función definida por el usuario 'fn_total_horas_por_docente'
-- para calcular y mostrar el total de horas asignadas a proyectos por cada docente.
SELECT
    d.docente_id,
    d.nombre,
    fn_total_horas_por_docente(d.docente_id) AS total_horas
FROM
    docente d;

-- Q3: Muestra las últimas 10 entradas en la tabla de auditoría para docentes actualizados.
-- Esta consulta permite verificar que el trigger 'tr_docente_after_update' está
-- funcionando correctamente, registrando las modificaciones de los docentes.
SELECT
    *
FROM
    copia_actualizados_docente
ORDER BY
    auditoria_id DESC
LIMIT 10;

-- Q4: Muestra las últimas 10 entradas en la tabla de auditoría para docentes eliminados.
-- Esta consulta verifica el funcionamiento del trigger 'tr_docente_after_delete',
-- mostrando una copia de los docentes que han sido eliminados del sistema.
SELECT
    *
FROM
    copia_eliminados_docente
ORDER BY
    auditoria_id DESC
LIMIT 10;

-- Q5: Valida que los datos de los proyectos cumplan con las restricciones 'CHECK'.
-- Esta consulta selecciona solo los proyectos donde las fechas, el presupuesto
-- y las horas previstas cumplen con las reglas de validación definidas en el esquema.
SELECT
    proyecto_id,
    nombre,
    fecha_inicio,
    fecha_fin,
    presupuesto,
    jefe_horas_previstas
FROM
    proyecto
WHERE
    (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
AND
    presupuesto >= 0
AND
    jefe_horas_previstas >= 0;

-- Q6: Lista cada docente con todos los proyectos que lidera.
-- Esta consulta usa un LEFT JOIN para incluir a todos los docentes, incluso
-- aquellos que no tienen proyectos asignados, mostrando su ID y nombre junto
-- con los proyectos asociados (si los hay).
SELECT
    d.docente_id,
    d.nombre,
    p.proyecto_id,
    p.nombre AS proyecto_nombre
FROM
    docente d
LEFT JOIN
    proyecto p ON d.docente_id = p.jefe_docente_id
ORDER BY
    d.docente_id;

-- Q7: Calcula el total de horas de todos los proyectos para cada docente.
-- Esta consulta agrupa los proyectos por docente y suma las horas previstas
-- de cada uno, proporcionando un resumen del total de horas trabajadas por cada líder de proyecto.
SELECT
    d.docente_id,
    d.nombre,
    SUM(p.jefe_horas_previstas) AS total_horas
FROM
    docente d
LEFT JOIN
    proyecto p ON d.docente_id = p.jefe_docente_id
GROUP BY
    d.docente_id,
    d.nombre;

-- Q8: Inserta nuevos docentes y proyectos usando procedimientos almacenados.
-- Este bloque de código demuestra cómo usar los procedimientos 'sp_docente_create'
-- y 'sp_proyecto_create' para agregar nuevos registros de manera segura y controlada,
-- respetando la lógica de negocio de la base de datos.
SET @id_ana     := (SELECT docente_id FROM docente WHERE numero_documento='CC3001');
SET @id_carlos  := (SELECT docente_id FROM docente WHERE numero_documento='CC1002');
CALL sp_proyecto_create('Plataforma Académica', 'Módulos de matrícula', '2025-01-01', NULL, 25000000, 800, 0, @id_ana);
CALL sp_proyecto_create('Chat Soporte TI', 'Chat universitario', '2025-02-01', '2025-06-30', 12000000, 450, 0, @id_carlos);

-- Q9: Inserta un nuevo docente y un proyecto directamente en las tablas.
-- Este bloque es una alternativa a los procedimientos almacenados, insertando
-- registros directamente en las tablas 'docente' y 'proyecto'. Muestra cómo
-- se puede usar una subconsulta para obtener el ID del docente para el proyecto.
INSERT INTO docente (numero_documento, nombre, titulo, anios_experiencia, direccion)
VALUES ('CC2001','María López','Esp. Gestión de Proyectos',7,'Av. Siempre Viva 742');
INSERT INTO proyecto (nombre, descripcion, fecha_inicio, fecha_fin, presupuesto, jefe_horas_previstas, jefe_coste, jefe_docente_id)
VALUES ('App Biblioteca','App móvil de préstamos','2025-03-01',NULL, 9000000, 320, 0,
    (SELECT docente_id FROM docente WHERE numero_documento='CC2001'));