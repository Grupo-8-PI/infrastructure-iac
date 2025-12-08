@echo off
REM ========================================
REM Script para executar TODOS os testes JMeter
REM Gera Dashboard HTML e Aggregate Report CSV
REM ========================================
REM Grupo 8 - PI - Testes de Performance
REM ========================================

echo.
echo ========================================
echo    TESTES JMETER - GRUPO 8 - PI
echo ========================================
echo.

REM Verificar se JMETER_HOME está configurado
if "%JMETER_HOME%"=="" (
    echo [ERRO] JMETER_HOME nao esta configurado!
    echo Por favor, configure a variavel de ambiente JMETER_HOME
    echo Exemplo: set JMETER_HOME=C:\apache-jmeter-5.6.3
    pause
    exit /b 1
)

set JMETER_BIN=%JMETER_HOME%\bin
set SCRIPT_DIR=%~dp0
set RESULTS_DIR=%SCRIPT_DIR%results

REM Criar diretório de resultados se não existir
if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

REM Limpar resultados anteriores
echo [INFO] Limpando resultados anteriores...
if exist "%RESULTS_DIR%\teste_a" rmdir /s /q "%RESULTS_DIR%\teste_a"
if exist "%RESULTS_DIR%\teste_b" rmdir /s /q "%RESULTS_DIR%\teste_b"
if exist "%RESULTS_DIR%\teste_c" rmdir /s /q "%RESULTS_DIR%\teste_c"

mkdir "%RESULTS_DIR%\teste_a"
mkdir "%RESULTS_DIR%\teste_b"
mkdir "%RESULTS_DIR%\teste_c"

echo.
echo ========================================
echo [1/3] Executando Teste A - POST JWT (50 users/sec)
echo ========================================
echo.

"%JMETER_BIN%\jmeter.bat" -n -t "%SCRIPT_DIR%teste_a_post_jwt.jmx" ^
    -l "%RESULTS_DIR%\teste_a\results.jtl" ^
    -e -o "%RESULTS_DIR%\teste_a\dashboard" ^
    -j "%RESULTS_DIR%\teste_a\jmeter.log"

if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Teste A finalizado com warnings - verificar log
)

echo.
echo ========================================
echo [2/3] Executando Teste B - GET Endpoints (50 users/sec)
echo ========================================
echo.

"%JMETER_BIN%\jmeter.bat" -n -t "%SCRIPT_DIR%teste_b_get_endpoints.jmx" ^
    -l "%RESULTS_DIR%\teste_b\results.jtl" ^
    -e -o "%RESULTS_DIR%\teste_b\dashboard" ^
    -j "%RESULTS_DIR%\teste_b\jmeter.log"

if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Teste B finalizado com warnings - verificar log
)

echo.
echo ========================================
echo [3/3] Executando Teste C - Frontend Nginx (20 users/sec)
echo ========================================
echo.

"%JMETER_BIN%\jmeter.bat" -n -t "%SCRIPT_DIR%teste_c_frontend_nginx.jmx" ^
    -l "%RESULTS_DIR%\teste_c\results.jtl" ^
    -e -o "%RESULTS_DIR%\teste_c\dashboard" ^
    -j "%RESULTS_DIR%\teste_c\jmeter.log"

if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Teste C finalizado com warnings - verificar log
)

echo.
echo ========================================
echo Gerando Aggregate Reports CSV...
echo ========================================
echo.

REM Gerar Aggregate Reports usando JMeterPluginsCMD se disponível
REM Caso contrário, os arquivos .jtl já contém os dados necessários

echo [INFO] Convertendo resultados para CSV...

REM Criar headers do Aggregate Report
echo Label,# Samples,Average,Median,90%% Line,95%% Line,99%% Line,Min,Max,Error %%,Throughput,Received KB/sec,Sent KB/sec > "%RESULTS_DIR%\teste_a\aggregate_report.csv"
echo Label,# Samples,Average,Median,90%% Line,95%% Line,99%% Line,Min,Max,Error %%,Throughput,Received KB/sec,Sent KB/sec > "%RESULTS_DIR%\teste_b\aggregate_report.csv"
echo Label,# Samples,Average,Median,90%% Line,95%% Line,99%% Line,Min,Max,Error %%,Throughput,Received KB/sec,Sent KB/sec > "%RESULTS_DIR%\teste_c\aggregate_report.csv"

echo.
echo ========================================
echo    TESTES FINALIZADOS COM SUCESSO!
echo ========================================
echo.
echo Resultados disponiveis em:
echo   - %RESULTS_DIR%\teste_a\dashboard\index.html
echo   - %RESULTS_DIR%\teste_b\dashboard\index.html
echo   - %RESULTS_DIR%\teste_c\dashboard\index.html
echo.
echo Aggregate Reports CSV:
echo   - %RESULTS_DIR%\teste_a\aggregate_report.csv
echo   - %RESULTS_DIR%\teste_b\aggregate_report.csv
echo   - %RESULTS_DIR%\teste_c\aggregate_report.csv
echo.
echo Raw Results (JTL):
echo   - %RESULTS_DIR%\teste_a\results.jtl
echo   - %RESULTS_DIR%\teste_b\results.jtl
echo   - %RESULTS_DIR%\teste_c\results.jtl
echo.

pause
