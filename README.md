# Proyecto final Aplicaciones Distribuidas

## Autores

- Mathías Terán
- Paul Cabrera
- Nicolas Luna

## Ejecución del Proyecto

A continuación se detallan los pasos para levantar el entorno de desarrollo y configurar la replicación de la base de datos.

### 1. Levantar los Contenedores

Para iniciar los servicios definidos en el archivo `Docker-compose.yml` (bases de datos y phpMyAdmin), ejecuta el siguiente comando en la raíz del proyecto:

```bash
docker-compose up -d
```

Este comando creará e iniciará los contenedores en segundo plano.

- **db-master**: Contenedor con la base de datos maestra, accesible en el puerto `3306`.
- **db-slave**: Contenedor con la base de datos esclava, accesible en el puerto `3307`.
- **phpmyadmin**: Interfaz de administración de bases de datos, accesible en `http://localhost:8081`.

### 2. Configurar la Replicación de la Base de Datos

Una vez que los contenedores de MySQL estén en funcionamiento (espera al menos 30 segundos después de levantarlos), puedes configurar la replicación maestro-esclavo.

Primero, asegúrate de que el script tenga permisos de ejecución:

```bash
chmod +x BDD/setup-replication.sh
```

Luego, ejecuta el script:

```bash
./BDD/setup-replication.sh
```

Este script configurará automáticamente el servidor `db-slave` para que replique los datos desde `db-master`.

### 3. Verificar la Replicación

Para comprobar que la replicación funciona correctamente, puedes usar el script `check-replication.sh`.

Primero, dale permisos de ejecución:

```bash
chmod +x BDD/check-replication.sh
```

Luego, ejecútalo:

```bash
./BDD/check-replication.sh
```

Este script mostrará el estado de ambos servidores, insertará un dato de prueba en el maestro y verificará que se haya replicado en el esclavo.
