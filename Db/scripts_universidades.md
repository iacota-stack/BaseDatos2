# 1. Creacion de la base de Datos
Primero lo que debemo realizar es la creacion de la base de datos, en este caso podemos revisar los comandos docker que ya tenemos puestos


# 2. Creacion de la tabla de Facultades
Vamos a Crear la tabla de Facultades.


CREATE TABLE facultades (
    id_facultad SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    decano VARCHAR(100),
    telefono VARCHAR(20)
);

INSERT INTO facultades (nombre, codigo, decano, telefono)
VALUES
('Facultad de Ingeniería', 'ING', 'Carlos Mendoza', '6121234567'),
('Facultad de Ciencias', 'CIE', 'Laura Ramírez', '6122345678'),
('Facultad de Administración', 'ADM', 'Roberto López', '6123456789');


# 3. Creacion de la Tabla de Carreras. 
Una facultad puede tener muchas carreras.

CREATE TABLE carreras (
    id_carrera SERIAL PRIMARY KEY,
    id_facultad INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    duracion_semestres INT NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVA',

    CONSTRAINT fk_carrera_facultad
        FOREIGN KEY (id_facultad)
        REFERENCES facultades(id_facultad)
);

INSERT INTO carreras
(id_facultad, nombre, codigo, duracion_semestres)
VALUES
(1, 'Ingeniería en Desarrollo de Software', 'IDS', 8),
(1, 'Ingeniería en Tecnologías Computacionales', 'ITC', 8),
(2, 'Licenciatura en Biología', 'BIO', 8),
(3, 'Licenciatura en Administración', 'LAE', 8);

# 4. Tabla estudiantes
Cada estudiante pertenece a una carrera

CREATE TABLE estudiantes (
    id_estudiante SERIAL PRIMARY KEY,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    id_carrera INT NOT NULL,
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(20) DEFAULT 'ACTIVO',

    CONSTRAINT fk_estudiante_carrera
        FOREIGN KEY (id_carrera)
        REFERENCES carreras(id_carrera)
);

INSERT INTO estudiantes
(matricula, nombre, apellido, email, telefono, fecha_nacimiento, id_carrera)
VALUES
('20260001', 'Juan', 'Pérez', 'juan@universidad.mx', '6121111111', '2005-05-10', 1),
('20260002', 'María', 'López', 'maria@universidad.mx', '6122222222', '2004-08-15', 1),
('20260003', 'Carlos', 'Ramírez', 'carlos@universidad.mx', '6123333333', '2005-01-20', 2),
('20260004', 'Ana', 'Torres', 'ana@universidad.mx', '6124444444', '2004-11-03', 3);


# 5. Tabla docentes

CREATE TABLE docentes (
    id_docente SERIAL PRIMARY KEY,
    numero_empleado VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    id_facultad INT NOT NULL,
    es_tiempo_completo BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_docente_facultad
        FOREIGN KEY (id_facultad)
        REFERENCES facultades(id_facultad)
);


INSERT INTO docentes
(numero_empleado, nombre, apellido, email, telefono, id_facultad, es_tiempo_completo)
VALUES
('EMP001', 'Pedro', 'Martínez', 'pedro@universidad.mx', '6125551111', 1, TRUE),
('EMP002', 'Sofía', 'Hernández', 'sofia@universidad.mx', '6125552222', 1, TRUE),
('EMP003', 'Miguel', 'García', 'miguel@universidad.mx', '6125553333', 2, FALSE);


# 6. Tabla Materias

CREATE TABLE materias (
    id_materia SERIAL PRIMARY KEY,
    id_carrera INT NOT NULL,
    clave VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    creditos INT NOT NULL,
    tipo VARCHAR(50),
    descripcion TEXT,

    CONSTRAINT fk_materia_carrera
        FOREIGN KEY (id_carrera)
        REFERENCES carreras(id_carrera)
);

INSERT INTO materias
(id_carrera, clave, nombre, creditos, tipo, descripcion)
VALUES
(1, 'IDS101', 'Metodología de la Programación', 8, 'Obligatoria', 'Fundamentos de programación'),
(1, 'IDS201', 'Programación Web', 8, 'Obligatoria', 'Desarrollo de aplicaciones web'),
(1, 'IDS301', 'Base de Datos II', 8, 'Obligatoria', 'Bases de datos avanzadas'),
(2, 'ITC101', 'Redes de Computadoras', 7, 'Obligatoria', 'Fundamentos de redes');


# 7. Tabla aulas

CREATE TABLE aulas (
    id_aula SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    edificio VARCHAR(100),
    capacidad INT NOT NULL,
    tipo VARCHAR(50)
);

INSERT INTO aulas (codigo, edificio, capacidad, tipo)
VALUES
('A-101', 'Edificio A', 30, 'Laboratorio'),
('A-102', 'Edificio A', 40, 'Aula'),
('B-201', 'Edificio B', 25, 'Laboratorio'),
('B-202', 'Edificio B', 35, 'Aula');


# 8. Tabla periodos_academicos

CREATE TABLE periodos_academicos (
    id_periodo SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVO'
);

INSERT INTO periodos_academicos
(nombre, fecha_inicio, fecha_fin, estado)
VALUES
('2026-1', '2026-01-20', '2026-06-15', 'FINALIZADO'),
('2026-2', '2026-08-10', '2026-12-15', 'ACTIVO');



#  9. Tabla grupos
Esta tabla es especialmente importante para explicar el tema de  arquitectura.

Una materia existe independientemente, por ejemplo:

Programación Web

Pero un grupo representa que esa materia será impartida por un docente, en un aula y durante un periodo determinado.

CREATE TABLE grupos (
    id_grupo SERIAL PRIMARY KEY,
    id_materia INT NOT NULL,
    id_docente INT NOT NULL,
    id_periodo INT NOT NULL,
    id_aula INT NOT NULL,
    grupo VARCHAR(10) NOT NULL,
    horario VARCHAR(100),
    cupo_maximo INT DEFAULT 30,

    CONSTRAINT fk_grupo_materia
        FOREIGN KEY (id_materia)
        REFERENCES materias(id_materia),

    CONSTRAINT fk_grupo_docente
        FOREIGN KEY (id_docente)
        REFERENCES docentes(id_docente),

    CONSTRAINT fk_grupo_periodo
        FOREIGN KEY (id_periodo)
        REFERENCES periodos_academicos(id_periodo),

    CONSTRAINT fk_grupo_aula
        FOREIGN KEY (id_aula)
        REFERENCES aulas(id_aula)
);

INSERT INTO grupos
(id_materia, id_docente, id_periodo, id_aula, grupo, horario, cupo_maximo)
VALUES
(1, 1, 2, 1, 'A', 'Lunes y Miércoles 08:00-10:00', 30),
(2, 2, 2, 2, 'A', 'Martes y Jueves 10:00-12:00', 35),
(3, 1, 2, 3, 'A', 'Lunes y Miércoles 12:00-14:00', 25);


# 10. Tabla inscripciones
 Una relación muchos a muchos.

Un estudiante puede estar en muchos grupos y un grupo puede tener muchos estudiantes.

Por eso necesitamos una tabla intermedia.

CREATE TABLE inscripciones (
    id_inscripcion SERIAL PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_grupo INT NOT NULL,
    id_periodo INT NOT NULL,
    fecha_inscripcion DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(20) DEFAULT 'INSCRITO',

    CONSTRAINT fk_inscripcion_estudiante
        FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes(id_estudiante),

    CONSTRAINT fk_inscripcion_grupo
        FOREIGN KEY (id_grupo)
        REFERENCES grupos(id_grupo),

    CONSTRAINT fk_inscripcion_periodo
        FOREIGN KEY (id_periodo)
        REFERENCES periodos_academicos(id_periodo),

    CONSTRAINT uq_estudiante_grupo
        UNIQUE(id_estudiante, id_grupo)
);

INSERT INTO inscripciones
(id_estudiante, id_grupo, id_periodo)
VALUES
(1, 1, 2),
(1, 2, 2),
(1, 3, 2),

(2, 1, 2),
(2, 2, 2),

(3, 1, 2);

# 11. Tabla calificaciones
CREATE TABLE calificaciones (
    id_calificacion SERIAL PRIMARY KEY,
    id_inscripcion INT NOT NULL,
    calificacion DECIMAL(5,2),
    fecha_registro DATE DEFAULT CURRENT_DATE,
    observaciones TEXT,
    tipo_evaluacion VARCHAR(50),

    CONSTRAINT fk_calificacion_inscripcion
        FOREIGN KEY (id_inscripcion)
        REFERENCES inscripciones(id_inscripcion),

    CONSTRAINT chk_calificacion
        CHECK (calificacion >= 0 AND calificacion <= 100)
);

INSERT INTO calificaciones
(id_inscripcion, calificacion, observaciones, tipo_evaluacion)
VALUES
(1, 90, 'Buen desempeño', 'Final'),
(2, 85, 'Cumplió con las actividades', 'Final'),
(3, 95, 'Excelente desempeño', 'Final'),
(4, 78, 'Debe mejorar prácticas', 'Final'),
(5, 88, 'Buen desempeño', 'Final');


# 12. Tabla pagos

CREATE TABLE pagos (
    id_pago SERIAL PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_periodo INT NOT NULL,
    concepto VARCHAR(100) NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metodo_pago VARCHAR(30),
    referencia VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'PAGADO',

    CONSTRAINT fk_pago_estudiante
        FOREIGN KEY (id_estudiante)
        REFERENCES estudiantes(id_estudiante),

    CONSTRAINT fk_pago_periodo
        FOREIGN KEY (id_periodo)
        REFERENCES periodos_academicos(id_periodo),

    CONSTRAINT chk_monto
        CHECK (monto > 0)
);


INSERT INTO pagos
(id_estudiante, id_periodo, concepto, monto, metodo_pago, referencia)
VALUES
(1, 2, 'Inscripción', 3500.00, 'Tarjeta', 'REF001'),
(2, 2, 'Inscripción', 3500.00, 'Transferencia', 'REF002'),
(3, 2, 'Inscripción', 3500.00, 'Efectivo', 'REF003');