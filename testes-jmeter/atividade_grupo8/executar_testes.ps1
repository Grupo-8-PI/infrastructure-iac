# ========================================
# Script PowerShell para executar testes JMeter
# Gera Dashboard HTML e Aggregate Report CSV
# ========================================
# Grupo 8 - PI - Testes de Performance
# ========================================

param(
    [string]$JMeterHome = $env:JMETER_HOME,
    [string]$Teste = "todos"  # todos, a, b, c
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TESTES JMETER - GRUPO 8 - PI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se JMETER_HOME está configurado
if ([string]::IsNullOrEmpty($JMeterHome)) {
    Write-Host "[ERRO] JMETER_HOME não está configurado!" -ForegroundColor Red
    Write-Host "Por favor, configure a variável de ambiente JMETER_HOME ou passe como parâmetro"
    Write-Host "Exemplo: .\executar_testes.ps1 -JMeterHome 'C:\apache-jmeter-5.6.3'"
    exit 1
}

$JMeterBin = Join-Path $JMeterHome "bin"
$JMeterExe = Join-Path $JMeterBin "jmeter.bat"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResultsDir = Join-Path $ScriptDir "results"

# Verificar se JMeter existe
if (-not (Test-Path $JMeterExe)) {
    Write-Host "[ERRO] JMeter não encontrado em: $JMeterExe" -ForegroundColor Red
    exit 1
}

# Criar diretório de resultados se não existir
if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir | Out-Null
}

function Run-JMeterTest {
    param(
        [string]$TestName,
        [string]$TestFile,
        [string]$Description,
        [string]$Users
    )
    
    $testResultDir = Join-Path $ResultsDir $TestName
    
    # Limpar resultados anteriores
    if (Test-Path $testResultDir) {
        Remove-Item -Recurse -Force $testResultDir
    }
    New-Item -ItemType Directory -Path $testResultDir | Out-Null
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Executando $TestName - $Description ($Users users/sec)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $testFilePath = Join-Path $ScriptDir $TestFile
    $resultsJtl = Join-Path $testResultDir "results.jtl"
    $dashboardDir = Join-Path $testResultDir "dashboard"
    $logFile = Join-Path $testResultDir "jmeter.log"
    
    # Executar JMeter em modo non-GUI com geração de dashboard
    $arguments = @(
        "-n",
        "-t", "`"$testFilePath`"",
        "-l", "`"$resultsJtl`"",
        "-e", "-o", "`"$dashboardDir`"",
        "-j", "`"$logFile`""
    )
    
    Write-Host "[INFO] Executando: $JMeterExe $($arguments -join ' ')" -ForegroundColor Gray
    
    $process = Start-Process -FilePath $JMeterExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] $TestName concluído com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] $TestName finalizado com código: $($process.ExitCode)" -ForegroundColor Yellow
    }
    
    # Gerar Aggregate Report CSV a partir do statistics.json do dashboard
    $statsJson = Join-Path $dashboardDir "statistics.json"
    $aggregateCsv = Join-Path $testResultDir "aggregate_report.csv"
    
    if (Test-Path $statsJson) {
        Write-Host "[INFO] Gerando Aggregate Report CSV..." -ForegroundColor Gray
        
        try {
            $stats = Get-Content $statsJson | ConvertFrom-Json
            
            # Header do CSV
            $csvContent = "Label,# Samples,Average,Median,90% Line,95% Line,99% Line,Min,Max,Error %,Throughput,Received KB/sec,Sent KB/sec`n"
            
            # Adicionar cada sampler
            foreach ($key in $stats.PSObject.Properties.Name) {
                $s = $stats.$key
                $line = "$($s.transaction),$($s.sampleCount),$($s.meanResTime),$($s.medianResTime),$($s.pct1ResTime),$($s.pct2ResTime),$($s.pct3ResTime),$($s.minResTime),$($s.maxResTime),$($s.errorPct),$($s.throughput),$($s.receivedKBytesPerSec),$($s.sentKBytesPerSec)"
                $csvContent += "$line`n"
            }
            
            $csvContent | Out-File -FilePath $aggregateCsv -Encoding UTF8
            Write-Host "[OK] Aggregate Report salvo em: $aggregateCsv" -ForegroundColor Green
        }
        catch {
            Write-Host "[AVISO] Não foi possível gerar o Aggregate Report CSV: $_" -ForegroundColor Yellow
        }
    }
    
    return $testResultDir
}

# Executar testes conforme seleção
$testResults = @()

if ($Teste -eq "todos" -or $Teste -eq "a") {
    $result = Run-JMeterTest -TestName "teste_a" -TestFile "teste_a_post_jwt.jmx" -Description "POST JWT Authentication" -Users "50"
    $testResults += $result
}

if ($Teste -eq "todos" -or $Teste -eq "b") {
    $result = Run-JMeterTest -TestName "teste_b" -TestFile "teste_b_get_endpoints.jmx" -Description "GET Endpoints" -Users "50"
    $testResults += $result
}

if ($Teste -eq "todos" -or $Teste -eq "c") {
    $result = Run-JMeterTest -TestName "teste_c" -TestFile "teste_c_frontend_nginx.jmx" -Description "Frontend Nginx" -Users "20"
    $testResults += $result
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   TESTES FINALIZADOS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resultados disponíveis em:" -ForegroundColor Cyan

foreach ($result in $testResults) {
    $dashboardPath = Join-Path $result "dashboard\index.html"
    $csvPath = Join-Path $result "aggregate_report.csv"
    $jtlPath = Join-Path $result "results.jtl"
    
    Write-Host ""
    Write-Host "  Dashboard: $dashboardPath" -ForegroundColor White
    Write-Host "  CSV:       $csvPath" -ForegroundColor White
    Write-Host "  JTL:       $jtlPath" -ForegroundColor White
}

Write-Host ""
Write-Host "Para abrir os dashboards no navegador:" -ForegroundColor Yellow
Write-Host "  Start-Process '$ResultsDir\teste_a\dashboard\index.html'"
Write-Host "  Start-Process '$ResultsDir\teste_b\dashboard\index.html'"
Write-Host "  Start-Process '$ResultsDir\teste_c\dashboard\index.html'"
Write-Host ""
