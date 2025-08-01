Write-Host "=== MONITOREO DEL BALANCEADOR DE CARGA NGINX ===" -ForegroundColor Green
Write-Host ""

# Verificar estado de NGINX
Write-Host "Estado del balanceador NGINX:" -ForegroundColor Cyan
try {
    $nginxStatus = Invoke-RestMethod -Uri "http://localhost/nginx-status"
    Write-Host "NGINX: OK" -ForegroundColor Green
} catch {
    Write-Host "NGINX: Error - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Ejecutando prueba de distribucion (20 peticiones):" -ForegroundColor Yellow

$instance1_count = 0
$instance2_count = 0  
$instance3_count = 0
$total_requests = 20
$errors = 0

for ($i = 1; $i -le $total_requests; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost/instance-info" -Method Get -TimeoutSec 5
        $instance = $response.instance
        
        switch ($instance) {
            "Instance-1" { 
                $instance1_count++
                Write-Host "[$i] Instance-1" -ForegroundColor Green
            }
            "Instance-2" { 
                $instance2_count++
                Write-Host "[$i] Instance-2" -ForegroundColor Blue
            }
            "Instance-3" { 
                $instance3_count++
                Write-Host "[$i] Instance-3" -ForegroundColor Magenta
            }
        }
        Start-Sleep -Milliseconds 100
    }
    catch {
        $errors++
        Write-Host "[$i] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== RESULTADOS ===" -ForegroundColor Cyan
$instance1_percent = [math]::Round($instance1_count * 100 / $total_requests, 1)
$instance2_percent = [math]::Round($instance2_count * 100 / $total_requests, 1)  
$instance3_percent = [math]::Round($instance3_count * 100 / $total_requests, 1)

Write-Host "Instance-1 (Peso 5): $instance1_count peticiones ($instance1_percent%)"
Write-Host "Instance-2 (Peso 3): $instance2_count peticiones ($instance2_percent%)"
Write-Host "Instance-3 (Peso 2): $instance3_count peticiones ($instance3_percent%)"
Write-Host "Errores: $errors"

Write-Host ""
Write-Host "Distribucion esperada:"
Write-Host "Instance-1: ~50% (peso 5/10)"
Write-Host "Instance-2: ~30% (peso 3/10)"  
Write-Host "Instance-3: ~20% (peso 2/10)"

Write-Host ""
Write-Host "Endpoints disponibles:"
Write-Host "- Aplicacion: http://localhost"
Write-Host "- Info instancias: http://localhost/instance-info"  
Write-Host "- phpMyAdmin: http://localhost:8081"
