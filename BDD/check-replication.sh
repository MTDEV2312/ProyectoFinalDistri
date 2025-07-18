#!/bin/bash

echo "=== Verificando Estado de Replicación ==="

echo "--- Estado del Maestro ---"
docker exec mysql_master mysql -uroot -proot -e "SHOW MASTER STATUS;"

echo ""
echo "--- Estado del Esclavo ---"
docker exec mysql_slave mysql -uroot -proot -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_Error"

echo ""
echo "--- Comparando Datos ---"
echo "Datos de productos en el maestro:"
docker exec mysql_master mysql -uroot -proot -e "SELECT COUNT(*) as total_productos FROM db_informacion.productos;"

echo "Datos de productos en el esclavo:"
docker exec mysql_slave mysql -uroot -proot -e "SELECT COUNT(*) as total_productos FROM db_informacion.productos;"

echo ""
echo "Datos de usuarios en el maestro:"
docker exec mysql_master mysql -uroot -proot -e "SELECT COUNT(*) as total_usuarios FROM db_informacion.usuarios;"

echo "Datos de usuarios en el esclavo:"
docker exec mysql_slave mysql -uroot -proot -e "SELECT COUNT(*) as total_usuarios FROM db_informacion.usuarios;"

echo ""
echo "--- Test de Replicación ---"
echo "Insertando dato de prueba en productos en el maestro..."
docker exec mysql_master mysql -uroot -proot -e "INSERT INTO db_informacion.productos (codigo, nombre, descripcion, unidad, categoria) 
VALUES (1, 'Producto Test $(date +%s)', 'Descripción del producto de prueba', 10, 'Categoria Test');"

echo ""
echo "Insertando usuario admin en el maestro..."
docker exec mysql_master mysql -uroot -proot -e "INSERT INTO db_informacion.usuarios (correo, contrasenia) 
VALUES ('admin@admin.com', 'admin') ON DUPLICATE KEY UPDATE contrasenia='admin';"

echo "Esperando replicación..."
sleep 3

echo ""
echo "Verificando productos en el esclavo:"
docker exec mysql_slave mysql -uroot -proot -e "SELECT * FROM db_informacion.productos ORDER BY codigo DESC LIMIT 3;"

echo ""
echo "Verificando usuarios en el esclavo:"
docker exec mysql_slave mysql -uroot -proot -e "SELECT id, correo, day_entered FROM db_informacion.usuarios ORDER BY id DESC LIMIT 3;"
