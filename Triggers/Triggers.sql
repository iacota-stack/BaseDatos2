/* =========================================================
   TRIGGERS Y PROCEDIMIENTOS ALMACENADOS
   BASE DE DATOS UNIVERSIDAD
   ========================================================= */


/* =========================================================
   1. TRIGGER - VALIDAR CUPO DEL GRUPO
   ========================================================= */

CREATE OR REPLACE FUNCTION validar_cupo_grupo()
RETURNS TRIGGER
AS $$
DECLARE
    total_inscritos INT;
    limite_grupo INT;
BEGIN

    SELECT COUNT(*)
    INTO total_inscritos
    FROM inscripciones
    WHERE id_grupo = NEW.id_grupo
      AND estado = 'INSCRITO';


    SELECT cupo_maximo
    INTO limite_grupo
    FROM grupos
    WHERE id_grupo = NEW.id_grupo;


    IF total_inscritos >= limite_grupo THEN
        RAISE EXCEPTION
        'No se puede realizar la inscripción. El grupo está lleno.';
    END IF;


    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_cupo_grupo
BEFORE INSERT
ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION validar_cupo_grupo();



/* =========================================================
   PRUEBA DEL TRIGGER
   ========================================================= */

SELECT
    g.id_grupo,
    m.nombre AS materia,
    g.grupo,
    g.cupo_maximo,
    COUNT(i.id_inscripcion) AS alumnos_inscritos
FROM grupos g
INNER JOIN materias m
    ON g.id_materia = m.id_materia
LEFT JOIN inscripciones i
    ON g.id_grupo = i.id_grupo
    AND i.estado = 'INSCRITO'
GROUP BY
    g.id_grupo,
    m.nombre,
    g.grupo,
    g.cupo_maximo
ORDER BY g.id_grupo;


/*
Ejemplo:

INSERT INTO inscripciones
(id_estudiante, id_grupo, id_periodo)
VALUES
(4, 1, 2);
*/



/* =========================================================
   2. TRIGGER - VALIDAR QUE EL ESTUDIANTE PERTENEZCA
   A LA MISMA CARRERA QUE LA MATERIA
   ========================================================= */

CREATE OR REPLACE FUNCTION validar_carrera_inscripcion()
RETURNS TRIGGER
AS $$
DECLARE
    carrera_estudiante INT;
    carrera_materia INT;
BEGIN

    SELECT id_carrera
    INTO carrera_estudiante
    FROM estudiantes
    WHERE id_estudiante = NEW.id_estudiante;


    SELECT m.id_carrera
    INTO carrera_materia
    FROM grupos g
    INNER JOIN materias m
        ON g.id_materia = m.id_materia
    WHERE g.id_grupo = NEW.id_grupo;


    IF carrera_estudiante <> carrera_materia THEN

        RAISE EXCEPTION
        'El estudiante no pertenece a la carrera correspondiente a esta materia.';

    END IF;


    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_carrera_inscripcion
BEFORE INSERT
ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION validar_carrera_inscripcion();



/* =========================================================
   PRUEBA
   Ana pertenece a Biología y el grupo 1 corresponde a IDS.
   Debería generar ERROR.
   ========================================================= */

/*
INSERT INTO inscripciones
(id_estudiante, id_grupo, id_periodo)
VALUES
(4, 1, 2);
*/



/* =========================================================
   3. TRIGGER - NO PERMITIR INSCRIBIR ESTUDIANTES INACTIVOS
   ========================================================= */

CREATE OR REPLACE FUNCTION validar_estudiante_activo()
RETURNS TRIGGER
AS $$
DECLARE
    estado_estudiante VARCHAR(20);
BEGIN

    SELECT estado
    INTO estado_estudiante
    FROM estudiantes
    WHERE id_estudiante = NEW.id_estudiante;


    IF estado_estudiante <> 'ACTIVO' THEN

        RAISE EXCEPTION
        'No se puede realizar la inscripción. El estudiante está inactivo.';

    END IF;


    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_estudiante_activo
BEFORE INSERT
ON inscripciones
FOR EACH ROW
EXECUTE FUNCTION validar_estudiante_activo();



/* =========================================================
   PRUEBA
   ========================================================= */

/*
UPDATE estudiantes
SET estado = 'INACTIVO'
WHERE id_estudiante = 2;


INSERT INTO inscripciones
(id_estudiante, id_grupo, id_periodo)
VALUES
(2, 3, 2);
*/


/* Regresar al estudiante a ACTIVO */

/*
UPDATE estudiantes
SET estado = 'ACTIVO'
WHERE id_estudiante = 2;
*/



/* =========================================================
   4. TRIGGER - EVITAR PAGOS DUPLICADOS
   ========================================================= */

CREATE OR REPLACE FUNCTION validar_pago_duplicado()
RETURNS TRIGGER
AS $$
BEGIN

    IF EXISTS (

        SELECT 1
        FROM pagos
        WHERE id_estudiante = NEW.id_estudiante
          AND id_periodo = NEW.id_periodo
          AND concepto = NEW.concepto
          AND estado = 'PAGADO'

    ) THEN

        RAISE EXCEPTION
        'El estudiante ya tiene registrado este pago para el periodo.';

    END IF;


    RETURN NEW;

END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_pago_duplicado
BEFORE INSERT
ON pagos
FOR EACH ROW
EXECUTE FUNCTION validar_pago_duplicado();



/* =========================================================
   PRUEBA
   Juan ya tiene un pago de inscripción del periodo 2.
   ========================================================= */

/*
INSERT INTO pagos
(
    id_estudiante,
    id_periodo,
    concepto,
    monto,
    metodo_pago,
    referencia
)
VALUES
(
    1,
    2,
    'Inscripción',
    3500,
    'Tarjeta',
    'REF999'
);
*/



/* =========================================================
   5. PROCEDIMIENTO - CAMBIAR ESTADO DE ESTUDIANTE
   ========================================================= */

CREATE OR REPLACE PROCEDURE cambiar_estado_estudiante(
    p_matricula VARCHAR,
    p_estado VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    UPDATE estudiantes
    SET estado = p_estado
    WHERE matricula = p_matricula;


    IF NOT FOUND THEN

        RAISE EXCEPTION
        'No existe un estudiante con la matrícula %',
        p_matricula;

    END IF;


    RAISE NOTICE
    'Estado del estudiante actualizado correctamente.';

END;
$$;



/* =========================================================
   EJECUTAR PROCEDIMIENTO
   ========================================================= */

CALL cambiar_estado_estudiante(
    '20260001',
    'INACTIVO'
);


/* Verificar */

SELECT
    matricula,
    nombre,
    apellido,
    estado
FROM estudiantes
WHERE matricula = '20260001';


/* Regresarlo a ACTIVO */

CALL cambiar_estado_estudiante(
    '20260001',
    'ACTIVO'
);



/* =========================================================
   6. PROCEDIMIENTO - REGISTRAR UN PAGO POR MATRÍCULA
   ========================================================= */

CREATE OR REPLACE PROCEDURE registrar_pago(
    p_matricula VARCHAR,
    p_id_periodo INT,
    p_concepto VARCHAR,
    p_monto DECIMAL,
    p_metodo VARCHAR,
    p_referencia VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    estudiante_encontrado INT;
BEGIN

    SELECT id_estudiante
    INTO estudiante_encontrado
    FROM estudiantes
    WHERE matricula = p_matricula;


    IF estudiante_encontrado IS NULL THEN

        RAISE EXCEPTION
        'No existe el estudiante con matrícula %',
        p_matricula;

    END IF;


    INSERT INTO pagos
    (
        id_estudiante,
        id_periodo,
        concepto,
        monto,
        metodo_pago,
        referencia
    )
    VALUES
    (
        estudiante_encontrado,
        p_id_periodo,
        p_concepto,
        p_monto,
        p_metodo,
        p_referencia
    );


    RAISE NOTICE
    'Pago registrado correctamente para la matrícula %',
    p_matricula;

END;
$$;



/* =========================================================
   EJECUTAR PROCEDIMIENTO
   ========================================================= */

CALL registrar_pago(
    '20260004',
    2,
    'Inscripción',
    3500,
    'Transferencia',
    'REF004'
);



/* Consultar pago */

SELECT
    e.matricula,
    e.nombre,
    e.apellido,
    p.concepto,
    p.monto,
    p.metodo_pago,
    p.referencia,
    p.fecha_pago
FROM pagos p
INNER JOIN estudiantes e
    ON p.id_estudiante = e.id_estudiante
WHERE e.matricula = '20260004';
