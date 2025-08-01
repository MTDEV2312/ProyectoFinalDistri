# Script extendido para probar el balanceador de carga con mas peticiones
Write-Host "=== PRUEBA EXTENDIDA DEL BALANCEADOR (100 peticiones) ===" -ForegroundColor Green

# Contadores
$instance1 = 0
$instance2 = 0
$instance3 = 0
$errores = 0

# Realizar 100 peticiones
for ($i = 1; $i -le 100; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost/instance-info" -Method GET -TimeoutSec 10
        
        switch ($response.instance) {
            "Instance-1" { $instance1++; Write-Host "[$i] Instance-1" -ForegroundColor Yellow }
            "Instance-2" { $instance2++; Write-Host "[$i] Instance-2" -ForegroundColor Cyan }
            "Instance-3" { $instance3++; Write-Host "[$i] Instance-3" -ForegroundColor Magenta }
            default { $errores++; Write-Host "[$i] Error: $($response.instance)" -ForegroundColor Red }
        }
    }
    catch {
        $errores++
        Write-Host "[$i] Error de conexion" -ForegroundColor Red
    }
    
    # Pequena pausa para no saturar
    Start-Sleep -Milliseconds 100
}

# Calcular porcentajes
$total = $instance1 + $instance2 + $instance3
$porc1 = if ($total -gt 0) { [math]::Round(($instance1 / $total) * 100, 1) } else { 0 }
$porc2 = if ($total -gt 0) { [math]::Round(($instance2 / $total) * 100, 1) } else { 0 }
$porc3 = if ($total -gt 0) { [math]::Round(($instance3 / $total) * 100, 1) } else { 0 }

# Mostrar resultados
Write-Host ""
Write-Host "=== RESULTADOS DETALLADOS ===" -ForegroundColor Green
Write-Host "Instance-1 (Peso 5): $instance1 peticiones ($porc1%)" -ForegroundColor Yellow
Write-Host "Instance-2 (Peso 3): $instance2 peticiones ($porc2%)" -ForegroundColor Cyan  
Write-Host "Instance-3 (Peso 2): $instance3 peticiones ($porc3%)" -ForegroundColor Magenta
Write-Host "Errores: $errores" -ForegroundColor Red
Write-Host ""
Write-Host "Distribucion esperada con pesos 5:3:2:" -ForegroundColor White
Write-Host "Instance-1: ~50% (peso 5/10)" -ForegroundColor Yellow
Write-Host "Instance-2: ~30% (peso 3/10)" -ForegroundColor Cyan
Write-Host "Instance-3: ~20% (peso 2/10)" -ForegroundColor Magenta
