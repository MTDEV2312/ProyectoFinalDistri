-- Inicialización de la base de datos para el sistema de gestión de productos
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

USE db_informacion;

-- Crea tabla de categorías
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónicos', 'Productos electrónicos y dispositivos tecnológicos'),
('Alimentos', 'Productos alimenticios y comestibles'),
('Bebidas', 'Bebidas alcohólicas y no alcohólicas'),
('Limpieza', 'Productos de limpieza y aseo'),
('Oficina', 'Artículos de oficina y papelería'),
('Hogar', 'Productos para el hogar y decoración'),
('Ropa', 'Prendas de vestir y accesorios'),
('Juguetes', 'Juguetes y artículos para niños'),
('Deportes', 'Artículos deportivos y equipamiento'),
('Salud', 'Productos de salud y cuidado personal');

CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    categoria_id INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    UNIQUE KEY (nombre)
);

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    correo VARCHAR(255) NOT NULL UNIQUE,
    contrasenia VARCHAR(255) NOT NULL,
    day_entered TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Configurar binlog
SET GLOBAL binlog_format = 'ROW';
