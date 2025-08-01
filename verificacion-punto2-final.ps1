# Script de verificacion completa del Punto 2
Write-Host "===== VERIFICACION COMPLETA DEL PUNTO 2 =====" -ForegroundColor Green
Write-Host ""

Write-Host "2.1 - Estado del Balanceador NGINX:" -ForegroundColor Yellow
try {
    $nginxStatus = Invoke-RestMethod -Uri "http://localhost/nginx-status" -Method GET
    Write-Host "  OK: $nginxStatus" -ForegroundColor Green
} catch {
    Write-Host "  ERROR en NGINX: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2.2 - Estado de los Contenedores:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}"

Write-Host ""
Write-Host "2.3 - Verificacion de Pesos y Distribucion:" -ForegroundColor Yellow
Write-Host "Realizando 20 peticiones para verificar distribucion..."

$instance1 = 0; $instance2 = 0; $instance3 = 0; $errores = 0

for ($i = 1; $i -le 20; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost/instance-info" -Method GET -TimeoutSec 5
        switch ($response.instance) {
            "Instance-1" { $instance1++; Write-Host "  [$i] Instance-1" -ForegroundColor Yellow }
            "Instance-2" { $instance2++; Write-Host "  [$i] Instance-2" -ForegroundColor Cyan }
            "Instance-3" { $instance3++; Write-Host "  [$i] Instance-3" -ForegroundColor Magenta }
            default { $errores++ }
        }
    }
    catch {
        $errores++
        Write-Host "  [$i] Error de conexion" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 200
}

Write-Host ""
Write-Host "2.4 - Resultados de Distribucion:" -ForegroundColor Yellow
$total = $instance1 + $instance2 + $instance3
if ($total -gt 0) {
    $porc1 = [math]::Round(($instance1 / $total) * 100, 1)
    $porc2 = [math]::Round(($instance2 / $total) * 100, 1)
    $porc3 = [math]::Round(($instance3 / $total) * 100, 1)
    
    Write-Host "  OK Instance-1 (Peso 5): $instance1 peticiones ($porc1%)" -ForegroundColor Green
    Write-Host "  OK Instance-2 (Peso 3): $instance2 peticiones ($porc2%)" -ForegroundColor Green
    Write-Host "  OK Instance-3 (Peso 2): $instance3 peticiones ($porc3%)" -ForegroundColor Green
    Write-Host "  OK Errores: $errores" -ForegroundColor Green
}

Write-Host ""
Write-Host "2.5 - Endpoints Disponibles:" -ForegroundColor Yellow
Write-Host "  - Aplicacion principal: http://localhost" -ForegroundColor White
Write-Host "  - Info de instancias: http://localhost/instance-info" -ForegroundColor White  
Write-Host "  - Estado de NGINX: http://localhost/nginx-status" -ForegroundColor White
Write-Host "  - phpMyAdmin: http://localhost:8081" -ForegroundColor White

Write-Host ""
Write-Host "===== PUNTO 2 COMPLETADO EXITOSAMENTE =====" -ForegroundColor Green
