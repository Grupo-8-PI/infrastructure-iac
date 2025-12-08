#!/bin/bash
# ========================================
# Script para executar TODOS os testes JMeter
# Gera Dashboard HTML e Aggregate Report CSV
# ========================================
# Grupo 8 - PI - Testes de Performance
# ========================================

echo ""
echo "========================================"
echo "   TESTES JMETER - GRUPO 8 - PI"
echo "========================================"
echo ""

# Verificar se JMETER_HOME está configurado
if [ -z "$JMETER_HOME" ]; then
    echo "[ERRO] JMETER_HOME não está configurado!"
    echo "Por favor, configure a variável de ambiente JMETER_HOME"
    echo "Exemplo: export JMETER_HOME=/opt/apache-jmeter-5.6.3"
    exit 1
fi

JMETER_BIN="$JMETER_HOME/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"

# Criar diretório de resultados se não existir
mkdir -p "$RESULTS_DIR"

# Limpar resultados anteriores
echo "[INFO] Limpando resultados anteriores..."
rm -rf "$RESULTS_DIR/teste_a" "$RESULTS_DIR/teste_b" "$RESULTS_DIR/teste_c"

mkdir -p "$RESULTS_DIR/teste_a"
mkdir -p "$RESULTS_DIR/teste_b"
mkdir -p "$RESULTS_DIR/teste_c"

echo ""
echo "========================================"
echo "[1/3] Executando Teste A - POST JWT (50 users/sec)"
echo "========================================"
echo ""

"$JMETER_BIN/jmeter" -n -t "$SCRIPT_DIR/teste_a_post_jwt.jmx" \
    -l "$RESULTS_DIR/teste_a/results.jtl" \
    -e -o "$RESULTS_DIR/teste_a/dashboard" \
    -j "$RESULTS_DIR/teste_a/jmeter.log"

echo ""
echo "========================================"
echo "[2/3] Executando Teste B - GET Endpoints (50 users/sec)"
echo "========================================"
echo ""

"$JMETER_BIN/jmeter" -n -t "$SCRIPT_DIR/teste_b_get_endpoints.jmx" \
    -l "$RESULTS_DIR/teste_b/results.jtl" \
    -e -o "$RESULTS_DIR/teste_b/dashboard" \
    -j "$RESULTS_DIR/teste_b/jmeter.log"

echo ""
echo "========================================"
echo "[3/3] Executando Teste C - Frontend Nginx (20 users/sec)"
echo "========================================"
echo ""

"$JMETER_BIN/jmeter" -n -t "$SCRIPT_DIR/teste_c_frontend_nginx.jmx" \
    -l "$RESULTS_DIR/teste_c/results.jtl" \
    -e -o "$RESULTS_DIR/teste_c/dashboard" \
    -j "$RESULTS_DIR/teste_c/jmeter.log"

echo ""
echo "========================================"
echo "Gerando Aggregate Reports CSV..."
echo "========================================"
echo ""

# Criar headers do Aggregate Report
echo "Label,# Samples,Average,Median,90% Line,95% Line,99% Line,Min,Max,Error %,Throughput,Received KB/sec,Sent KB/sec" > "$RESULTS_DIR/teste_a/aggregate_report.csv"
echo "Label,# Samples,Average,Median,90% Line,95% Line,99% Line,Min,Max,Error %,Throughput,Received KB/sec,Sent KB/sec" > "$RESULTS_DIR/teste_b/aggregate_report.csv"
echo "Label,# Samples,Average,Median,90% Line,95% Line,99% Line,Min,Max,Error %,Throughput,Received KB/sec,Sent KB/sec" > "$RESULTS_DIR/teste_c/aggregate_report.csv"

echo ""
echo "========================================"
echo "   TESTES FINALIZADOS COM SUCESSO!"
echo "========================================"
echo ""
echo "Resultados disponíveis em:"
echo "  - $RESULTS_DIR/teste_a/dashboard/index.html"
echo "  - $RESULTS_DIR/teste_b/dashboard/index.html"
echo "  - $RESULTS_DIR/teste_c/dashboard/index.html"
echo ""
echo "Aggregate Reports CSV:"
echo "  - $RESULTS_DIR/teste_a/aggregate_report.csv"
echo "  - $RESULTS_DIR/teste_b/aggregate_report.csv"
echo "  - $RESULTS_DIR/teste_c/aggregate_report.csv"
echo ""
echo "Raw Results (JTL):"
echo "  - $RESULTS_DIR/teste_a/results.jtl"
echo "  - $RESULTS_DIR/teste_b/results.jtl"
echo "  - $RESULTS_DIR/teste_c/results.jtl"
echo ""
