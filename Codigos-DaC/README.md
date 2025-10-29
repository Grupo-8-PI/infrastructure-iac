# Diagramas de Arquitetura - Infraestrutura IaC

Este diretório contém os scripts Python para geração automática dos diagramas de arquitetura do projeto.

## 📋 Diagramas Disponíveis

1. **diagrama_infraestrutura.py** - Arquitetura completa da infraestrutura AWS
2. **diagrama_arq_redes.py** - Topologia de redes (VPC, Subnets, Security Groups)
3. **diagrama_arq_info.py** - Arquitetura de informação (fluxo de dados)
4. **diagrama_SW.py** - Arquitetura de software (componentes e tecnologias)

## 🚀 Como Executar

### Passo 1: Corrigir Importações do Grafana

Execute o seguinte comando para substituir as importações do Grafana (que não existe na biblioteca) por Metabase:

```powershell
cd "C:\Users\leode\Downloads\infrastructure-iac\Codigos-DaC"; (Get-Content diagrama_infraestrutura.py) | ForEach-Object { $_ -replace 'from diagrams.onprem.analytics import Grafana', 'from diagrams.onprem.analytics import Metabase as Grafana' } | Set-Content diagrama_infraestrutura.py; (Get-Content diagrama_arq_redes.py) | ForEach-Object { $_ -replace 'from diagrams.onprem.analytics import Grafana', 'from diagrams.onprem.analytics import Metabase as Grafana' } | Set-Content diagrama_arq_redes.py; (Get-Content diagrama_arq_info.py) | ForEach-Object { $_ -replace 'from diagrams.onprem.analytics import Grafana', 'from diagrams.onprem.analytics import Metabase as Grafana' } | Set-Content diagrama_arq_info.py; (Get-Content diagrama_SW.py) | ForEach-Object { $_ -replace 'from diagrams.onprem.analytics import Grafana', 'from diagrams.onprem.analytics import Metabase as Grafana' } | Set-Content diagrama_SW.py
```

### Passo 2: Gerar os Diagramas

Execute os scripts Python para gerar os arquivos PNG:

```powershell
python diagrama_infraestrutura.py; python diagrama_arq_redes.py; python diagrama_arq_info.py; python diagrama_SW.py; ls *.png
```

## 📊 Saída Esperada

Após a execução, serão gerados 4 arquivos PNG:

- `diagrama_infraestrutura.png` (~323 KB) - Pipeline ETL completo com S3, Lambda, Glue, Athena e Grafana
- `diagrama_arq_redes.png` (~107 KB) - VPC 10.0.0.0/24 com subnets públicas/privadas
- `diagrama_arq_info.png` (~318 KB) - Fluxo de informação em 4 camadas (Ingestão → Transformação → Análise → Visualização)
- `diagrama_SW.py` (~242 KB) - Stack de software (Lambda Python, Glue Schema, Athena, Grafana)

## 🔧 Requisitos

- Python 3.x
- Biblioteca `diagrams` instalada: `pip install diagrams`
- Graphviz instalado no sistema

## 📝 Notas

- **Workaround Grafana**: A biblioteca `diagrams` não possui um ícone nativo para Grafana, por isso usamos o ícone do Metabase com alias `as Grafana`
- **Imports Corrigidos**: Glue e Athena estão em `diagrams.aws.analytics` (não em `diagrams.aws.database`)
- Os diagramas refletem a arquitetura atual implementada no Terraform (`infra__aej.tf`)

## 🏗️ Arquitetura Implementada

### Componentes Principais:
- **VPC**: 10.0.0.0/24
- **Subnets**: Pública (10.0.0.0/25) e Privada (10.0.0.128/25)
- **S3 Buckets**: staging, trusted, cured, athena-results
- **Lambda Functions**: staging-to-trusted-etl, trusted-to-cured-etl (Python 3.9)
- **AWS Glue**: Database `livros_analytics_db`, Table `vendas_livros` (OpenCSVSerde)
- **AWS Athena**: Workgroup `livros_analytics_workgroup`
- **ECS Grafana**: Cluster `grafana-livros-cluster`, Public IP: 13.220.218.141:3000
- **Dados**: 99.441 registros → 3.139 livros (230 obras únicas)

---

**Projeto**: Plataforma de Analytics - Vendas de Livros da Biblioteca Nacional  
**Última Atualização**: Outubro 2025
