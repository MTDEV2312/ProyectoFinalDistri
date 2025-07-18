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

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    correo VARCHAR(255) NOT NULL UNIQUE,
    contrasenia VARCHAR(255) NOT NULL,
    day_entered TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
