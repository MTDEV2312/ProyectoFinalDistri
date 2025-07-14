#!/bin/bash

echo "=== Configurando Replicación Maestro-Esclavo ==="

# Esperar a que los contenedores estén listos
echo "Esperando a que los servidores MySQL estén listos..."
sleep 30

# Obtener información del maestro
echo "Obteniendo información del servidor maestro..."
MASTER_STATUS=$(docker exec mysql_master mysql -uroot -proot -e "SHOW MASTER STATUS\G")
echo "$MASTER_STATUS"

# Extraer archivo y posición del binlog
MASTER_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
MASTER_POSITION=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

echo "Archivo del maestro: $MASTER_FILE"
echo "Posición del maestro: $MASTER_POSITION"

# Configurar el esclavo
echo "Configurando el servidor esclavo..."
docker exec mysql_slave mysql -uroot -proot -e "
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO 
    MASTER_HOST='db-master',
    MASTER_USER='root',
    MASTER_PASSWORD='root',
    MASTER_LOG_FILE='$MASTER_FILE',
    MASTER_LOG_POS=$MASTER_POSITION;
START SLAVE;
"

# Verificar el estado del esclavo
echo "Verificando estado de replicación..."
docker exec mysql_slave mysql -uroot -proot -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_Error|Last_IO_Error"

echo "=== Configuración de replicación completada ==="
echo ""
echo "Para verificar que la replicación funciona:"
echo "1. Conecta al maestro: docker exec -it mysql_master mysql -uroot -proot"
echo "2. Inserta datos en db_informacion.productos"
echo "3. Conecta al esclavo: docker exec -it mysql_slave mysql -uroot -proot"
echo "4. Verifica que los datos se replicaron"
