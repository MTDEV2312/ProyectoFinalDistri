#!/bin/bash

echo "=== Verificando Balanceo de Carga ==="
echo ""

echo "🔍 Haciendo 20 peticiones al endpoint /instance-info para verificar distribución..."
echo ""

# Contadores para cada instancia
instance1_count=0
instance2_count=0
instance3_count=0

for i in {1..20}; do
    response=$(curl -s http://localhost/instance-info)
    instance=$(echo $response | grep -o '"instance":"[^"]*"' | cut -d'"' -f4)
    
    case $instance in
        "Instance-1")
            instance1_count=$((instance1_count + 1))
            ;;
        "Instance-2")
            instance2_count=$((instance2_count + 1))
            ;;
        "Instance-3")
            instance3_count=$((instance3_count + 1))
            ;;
    esac
    
    echo "Petición $i: $instance"
    sleep 0.1
done

echo ""
echo "📊 RESULTADOS DEL BALANCEO:"
echo "Instance-1 (peso 5): $instance1_count peticiones ($(echo "scale=1; $instance1_count * 100 / 20" | bc)%)"
echo "Instance-2 (peso 3): $instance2_count peticiones ($(echo "scale=1; $instance2_count * 100 / 20" | bc)%)"
echo "Instance-3 (peso 2): $instance3_count peticiones ($(echo "scale=1; $instance3_count * 100 / 20" | bc)%)"
echo ""
echo "💡 Distribución esperada:"
echo "Instance-1: ~50% (peso 5/10)"
echo "Instance-2: ~30% (peso 3/10)"
echo "Instance-3: ~20% (peso 2/10)"
