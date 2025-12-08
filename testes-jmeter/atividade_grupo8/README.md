# 🧪 Testes de Performance JMeter - Grupo 8 - PI

## 📋 Descrição dos Testes

Este diretório contém 3 projetos de teste JMeter para análise de performance da aplicação de vendas de livros.

### Teste A - POST com JWT Authentication (50 users/sec)
- **Arquivo:** `teste_a_post_jwt.jmx`
- **Objetivo:** Testar endpoint POST que recebe token JWT
- **Carga:** 50 usuários por segundo
- **Duração:** 60 segundos
- **Endpoints testados:**
  - `POST /api/auth/login` - Autenticação e obtenção do JWT
  - `POST /api/pedidos` - Criação de pedido com JWT no header

### Teste B - GET Endpoints (50 users/sec)
- **Arquivo:** `teste_b_get_endpoints.jmx`
- **Objetivo:** Testar endpoints GET da API
- **Carga:** 50 usuários por segundo
- **Duração:** 60 segundos
- **Endpoints testados:**
  - `GET /api/livros` - Listar todos os livros
  - `GET /api/livros/1` - Buscar livro por ID
  - `GET /api/categorias` - Listar categorias
  - `GET /api/vendas` - Listar vendas

### Teste C - Frontend via Nginx (20 users/sec)
- **Arquivo:** `teste_c_frontend_nginx.jmx`
- **Objetivo:** Testar página do Frontend com todas as requisições
- **Carga:** 20 usuários por segundo
- **Duração:** 60 segundos
- **Requisições testadas:**
  - `GET /` - Página HTML principal
  - `GET /assets/css/main.css` - CSS
  - `GET /assets/js/main.js` - JavaScript
  - `GET /favicon.ico` - Favicon
  - `AJAX GET /api/livros` - Chamada API
  - `AJAX GET /api/categorias` - Chamada API
  - `AJAX GET /api/dashboard/stats` - Chamada API

---

## 🔧 Pré-requisitos

1. **Apache JMeter 5.6+** instalado
2. **Java 8+** instalado
3. Variável de ambiente `JMETER_HOME` configurada

```powershell
# Windows PowerShell
$env:JMETER_HOME = "C:\apache-jmeter-5.6.3"

# Linux/Mac
export JMETER_HOME=/opt/apache-jmeter-5.6.3
```

---

## 🚀 Como Executar

### Opção 1: Script PowerShell (Recomendado para Windows)

```powershell
# Executar todos os testes
.\executar_testes.ps1

# Executar apenas o teste A
.\executar_testes.ps1 -Teste a

# Executar apenas o teste B
.\executar_testes.ps1 -Teste b

# Executar apenas o teste C
.\executar_testes.ps1 -Teste c

# Especificar caminho do JMeter
.\executar_testes.ps1 -JMeterHome "C:\apache-jmeter-5.6.3"
```

### Opção 2: Script BAT (Windows)

```cmd
executar_todos_testes.bat
```

### Opção 3: Script Bash (Linux/Mac)

```bash
chmod +x executar_todos_testes.sh
./executar_todos_testes.sh
```

### Opção 4: Linha de Comando JMeter (Manual)

```powershell
# Teste A
& "$env:JMETER_HOME\bin\jmeter.bat" -n -t teste_a_post_jwt.jmx -l results/teste_a/results.jtl -e -o results/teste_a/dashboard

# Teste B
& "$env:JMETER_HOME\bin\jmeter.bat" -n -t teste_b_get_endpoints.jmx -l results/teste_b/results.jtl -e -o results/teste_b/dashboard

# Teste C
& "$env:JMETER_HOME\bin\jmeter.bat" -n -t teste_c_frontend_nginx.jmx -l results/teste_c/results.jtl -e -o results/teste_c/dashboard
```

---

## 📊 Resultados Gerados

Após a execução, os seguintes arquivos são gerados:

```
results/
├── teste_a/
│   ├── dashboard/           # Dashboard HTML interativo
│   │   ├── index.html       # Página principal do dashboard
│   │   ├── content/         # Gráficos e relatórios
│   │   └── statistics.json  # Dados estatísticos
│   ├── results.jtl          # Resultados raw
│   ├── aggregate_report.csv # Aggregate Report em CSV
│   └── jmeter.log           # Log de execução
├── teste_b/
│   └── (mesma estrutura)
└── teste_c/
    └── (mesma estrutura)
```

### I. Dashboard HTML

O Dashboard é gerado automaticamente via CLI com a flag `-e -o`:
- Abra `results/teste_X/dashboard/index.html` no navegador
- Contém gráficos de Response Time, Throughput, Erros, etc.

### II. Aggregate Report CSV

O Aggregate Report é exportado automaticamente para CSV com as seguintes métricas:
- Label (nome do sampler)
- \# Samples (quantidade de requisições)
- Average (tempo médio de resposta em ms)
- Median (mediana)
- 90%, 95%, 99% Line (percentis)
- Min/Max (tempo mínimo e máximo)
- Error % (percentual de erros)
- Throughput (requisições por segundo)
- KB/sec (bytes recebidos/enviados)

---

## ⚙️ Configuração dos Endpoints

Os testes usam variáveis que podem ser alteradas diretamente nos arquivos `.jmx` ou via linha de comando:

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `BASE_URL` / `FE_URL` | localhost | Host da aplicação |
| `PORT` / `FE_PORT` | 8080 / 80 | Porta da aplicação |
| `API_URL` | localhost | Host da API (para teste C) |
| `API_PORT` | 8080 | Porta da API (para teste C) |
| `PROTOCOL` | http | Protocolo (http/https) |

### Alterando via Linha de Comando

```powershell
& "$env:JMETER_HOME\bin\jmeter.bat" -n -t teste_a_post_jwt.jmx `
    -JBASE_URL=192.168.1.100 `
    -JPORT=3000 `
    -l results.jtl -e -o dashboard
```

---

## 📝 Requisitos do Ambiente Local

### Para Teste A e B (API)
- API Backend rodando em `localhost:8080`
- Endpoints REST disponíveis

### Para Teste C (Frontend)
- **IMPORTANTE:** O Frontend deve estar rodando via **Nginx**, não via Node.js
- Nginx servindo arquivos estáticos na porta 80
- API Backend disponível para chamadas AJAX

#### Exemplo de configuração Nginx (nginx.conf):

```nginx
server {
    listen 80;
    server_name localhost;
    
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 🔍 Interpretando os Resultados

### Métricas Importantes

| Métrica | Bom | Aceitável | Ruim |
|---------|-----|-----------|------|
| Response Time (Avg) | < 200ms | 200-500ms | > 500ms |
| Error % | 0% | < 1% | > 1% |
| Throughput | > 100/sec | 50-100/sec | < 50/sec |

### Gráficos do Dashboard

1. **Response Times Over Time** - Mostra a evolução do tempo de resposta
2. **Throughput** - Requisições processadas por segundo
3. **Response Time Percentiles** - Distribuição dos tempos de resposta
4. **Errors** - Taxa de erros ao longo do tempo

---

## 👥 Grupo 8 - PI

- Projeto de análise de vendas de livros
- Testes de performance para validar escalabilidade
- Ambiente: AWS + Terraform + ECS
