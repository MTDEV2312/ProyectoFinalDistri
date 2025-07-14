-- Crear tabla de ejemplo si no existe
USE db_informacion;
CREATE TABLE IF NOT EXISTS productos (
    codigo INT PRIMARY KEY NOT NULL,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NOT NULL,
    unidad INT NOT NULL DEFAULT 0,
    categoria VARCHAR(100) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
