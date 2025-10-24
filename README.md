# Infraestrutura AWS com Terraform - Modular

Este projeto contém uma infraestrutura AWS modularizada usando Terraform, onde cada componente está organizado em sua própria pasta para facilitar a manutenção e reutilização.

## Estrutura do Projeto

```
infrastructure-iac/
├── main.tf                     # Arquivo principal que chama todos os módulos
├── variables.tf                # Variáveis principais do projeto
├── outputs.tf                  # Outputs principais da infraestrutura
├── modules/                    # Pasta contendo todos os módulos
│   ├── vpc/                    # Módulo VPC
│   │   └── main.tf            # Variables, Resources e Outputs da VPC
│   ├── subnets/                # Módulo Subnets
│   │   └── main.tf            # Variables, Resources e Outputs das Subnets
│   ├── internet-gateway/       # Módulo Internet Gateway
│   │   └── main.tf            # Variables, Resources e Outputs do IGW
│   ├── route-tables/           # Módulo Route Tables
│   │   └── main.tf            # Variables, Resources e Outputs das Route Tables
│   ├── security-groups/        # Módulo Security Groups
│   │   └── main.tf            # Variables, Resources e Outputs dos Security Groups
│   ├── ec2/                    # Módulo EC2
│   │   └── main.tf            # Variables, Resources e Outputs das instâncias EC2
│   ├── s3/                     # Módulo S3
│   │   └── main.tf            # Variables, Resources e Outputs dos buckets S3
│   └── load-balancer/          # Módulo Load Balancer
│       └── main.tf            # Variables, Resources e Outputs do ELB
```

## Recursos Criados

### VPC e Rede
- **VPC**: Rede virtual privada (10.0.0.0/24)
- **Subnets**: 
  - Subnet pública (10.0.0.0/25)
  - Subnet privada (10.0.0.128/25)
- **Internet Gateway**: Para acesso à internet
- **Route Tables**: Tabelas de roteamento para subnets

### Segurança
- **Security Groups**:
  - SG Público: Permite SSH (porta 22) de qualquer IP
  - SG Privado: Permite SSH apenas da VPC

### Computação
- **EC2 Instances**:
  - Instância pública (com IP público)
  - Instância privada (apenas IP privado)
- **Load Balancer**: ELB clássico na subnet pública

### Armazenamento
- **S3 Buckets**:
  - **aej-public-bucket**: Bucket público para website e processamento Excel
  - **aej-staging-bucket**: Dados brutos do pipeline ETL
  - **aej-trusted-bucket**: Dados limpos (colunas filtradas)
  - **aej-cured-bucket**: Dados refinados (apenas livros)

### Processamento de Dados
- **Lambda Functions**:
  - **excel-processor**: Processa arquivos Excel enviados ao S3
  - **staging-to-trusted-etl**: Filtra colunas específicas dos dados brutos
  - **trusted-to-cured-etl**: Filtra apenas registros de livros

## Como Usar

### Pré-requisitos
- Terraform instalado (>= 1.2)
- AWS CLI configurado com credenciais válidas
- Acesso à AWS com permissões adequadas

### Comandos Básicos

1. **Inicializar o Terraform**:
   ```bash
   terraform init
   ```

2. **Aplicar a infraestrutura**:
   ```bash
   terraform apply
   ```

3. **Destruir a infraestrutura**:
   ```bash
   terraform destroy
   ```

### Customização

Você pode customizar a infraestrutura editando as variáveis em `variables.tf` ou passando valores via linha de comando:

```bash
terraform apply -var="aws_region=us-west-2" -var="environment=prod"
```

## Vantagens da Estrutura Simplificada

1. **Simplicidade**: Cada módulo tem apenas um arquivo, facilitando a navegação
2. **Reutilização**: Módulos podem ser reutilizados em diferentes projetos
3. **Manutenibilidade**: Cada componente está isolado e pode ser atualizado independentemente
4. **Legibilidade**: Código mais organizado e fácil de entender
5. **Funcionalidade Completa**: Cada arquivo `main.tf` contém tudo necessário (variables, resources, outputs)

## Módulos Funcionais

Cada módulo é completamente funcional e autocontido em um único arquivo `main.tf`, que inclui:
- **Variables**: Definições de variáveis de entrada
- **Resources**: Recursos da AWS a serem criados
- **Outputs**: Valores de saída do módulo

### Exemplo de uso individual de um módulo:

```hcl
module "vpc_example" {
  source = "./modules/vpc"
  
  vpc_cidr = "10.1.0.0/16"
  vpc_name = "my-custom-vpc"
}
```

## Outputs Disponíveis

A infraestrutura expõe vários outputs úteis que podem ser consumidos por outros projetos ou usados para referência:

- IDs de recursos (VPC, subnets, instâncias, etc.)
- IPs das instâncias
- DNS do Load Balancer
- IDs dos buckets S3

## Sistema de Processamento de Excel via Lambda e S3

Este projeto inclui uma função Lambda que processa automaticamente arquivos Excel (.xlsx) enviados para o bucket S3.

### 📋 Funcionalidades

- **Trigger Automático**: O Lambda é acionado automaticamente quando arquivos `.xlsx` são enviados para a pasta `datasets/` no S3
- **Processamento Assíncrono**: Arquivos são processados em background sem necessidade de intervenção
- **Relatórios JSON**: Gera relatórios de processamento na pasta `outputs/` do bucket
- **Logs Detalhados**: CloudWatch mantém logs de todas as execuções

### 🚀 Como Usar

#### 1. Após o Deploy da Infraestrutura

Execute o Terraform para criar todos os recursos:

```bash
cd Codigos-IaC
terraform init
terraform apply -auto-approve
```

#### 2. Obter Informações do Bucket

Após o deploy, veja as informações importantes:

```bash
terraform output
```

Você verá informações como:
- `s3_bucket_name`: Nome do bucket S3 criado
- `excel_lambda_function_name`: Nome da função Lambda
- `excel_processing_instructions`: Instruções de uso
- `s3_website_endpoint`: Endpoint público do bucket

#### 3. Enviar Arquivos Excel para Processamento

**Usando AWS CLI:**

```bash
# Enviar um único arquivo
aws s3 cp seu_arquivo.xlsx s3://aej-public-bucket-XXXXXX/datasets/

# Enviar múltiplos arquivos
aws s3 cp arquivo1.xlsx s3://aej-public-bucket-XXXXXX/datasets/
aws s3 cp arquivo2.xlsx s3://aej-public-bucket-XXXXXX/datasets/

# Enviar uma pasta inteira
aws s3 cp ./meus_excels/ s3://aej-public-bucket-XXXXXX/datasets/ --recursive
```

**Usando Console AWS:**
1. Acesse o S3 Console
2. Navegue até o bucket `aej-public-bucket-XXXXXX`
3. Entre na pasta `datasets/`
4. Clique em "Upload" e selecione seus arquivos `.xlsx`

#### 4. Verificar os Resultados

**Listar arquivos processados:**

```bash
# Ver relatórios gerados
aws s3 ls s3://aej-public-bucket-XXXXXX/outputs/

# Baixar um relatório específico
aws s3 cp s3://aej-public-bucket-XXXXXX/outputs/processing_report_2025-10-19_21-33-09.json .

# Baixar todos os resultados
aws s3 cp s3://aej-public-bucket-XXXXXX/outputs/ ./resultados/ --recursive
```

**Ver logs da execução:**

```bash
# Listar últimas execuções do Lambda
aws logs describe-log-streams \
  --log-group-name "/aws/lambda/excel-processor-terraform" \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Ver logs de uma execução específica
aws logs filter-log-events \
  --log-group-name "/aws/lambda/excel-processor-terraform" \
  --start-time <timestamp_em_ms>
```

#### 5. Estrutura de Pastas no S3

```
s3://aej-public-bucket-XXXXXX/
├── datasets/              # ← Coloque seus arquivos .xlsx aqui
│   ├── arquivo1.xlsx
│   ├── arquivo2.xlsx
│   └── tabelao_tratado.xlsx
└── outputs/               # ← Relatórios processados aparecem aqui
    ├── processing_report_2025-10-19_21-29-53.json
    └── processing_report_2025-10-19_21-33-09.json
```

### 🔧 Arquivos do Lambda

- **`excel_processor_lambda.py`**: Código Python da função Lambda
- **`excel_processor_lambda.zip`**: Pacote ZIP criado automaticamente pelo Terraform

### ⚙️ Configurações Importantes

**Recursos do Lambda:**
- Runtime: Python 3.9
- Memória: 3008 MB (máximo disponível)
- Timeout: 900 segundos (15 minutos)
- Trigger: S3 ObjectCreated em `datasets/*.xlsx`

**Permissões:**
- Usa `LabRole` existente no AWS Labs
- Acesso de leitura/escrita no bucket S3
- Logs no CloudWatch

### 🧹 Limpeza e Destroy

**Importante**: Antes de destruir a infraestrutura, esvazie o bucket S3:

```bash
# Remover todos os arquivos do bucket
aws s3 rm s3://aej-public-bucket-XXXXXX --recursive

# Depois destruir a infraestrutura
terraform destroy -auto-approve
```

**Ou configure force_destroy no Terraform** (opcional):

No arquivo `infra__aej.tf`, adicione `force_destroy = true` no recurso do bucket:

```hcl
resource "aws_s3_bucket" "aej_public" {
  bucket        = "aej-public-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true  # ← Remove automaticamente objetos no destroy
}
```

⚠️ **Atenção**: Com `force_destroy = true`, todos os arquivos serão deletados automaticamente ao executar `terraform destroy`.

### 📊 Exemplo de Relatório Gerado

```json
{
  "timestamp": "2025-10-19_21-33-09",
  "trigger_file": "datasets/tabelao_tratado.xlsx",
  "total_excel_files": 2,
  "excel_files_list": [
    "datasets/teste.xlsx",
    "datasets/tabelao_tratado.xlsx"
  ],
  "status": "detected",
  "message": "Excel files detected - ready for processing"
}
```

### 🐛 Troubleshooting

**Problema**: Lambda não está sendo acionado
- Verifique se o arquivo tem extensão `.xlsx`
- Confirme que está enviando para a pasta `datasets/`
- Verifique os logs no CloudWatch

**Problema**: Erro de permissão ao fazer destroy
- Execute: `aws s3 rm s3://seu-bucket --recursive`
- Depois execute: `terraform destroy`

**Problema**: Arquivo muito grande (timeout)
- O timeout está configurado para 15 minutos (máximo)
- Para arquivos gigantes, considere aumentar recursos ou dividir o arquivo

---

## Pipeline ETL Automatizado (Staging → Trusted → Cured)

Este projeto inclui um pipeline ETL completo e automatizado com três estágios de processamento de dados.

### 📊 Arquitetura do Pipeline

```
┌─────────────┐      Lambda 1       ┌─────────────┐      Lambda 2       ┌─────────────┐
│   STAGING   │  ─────────────────> │   TRUSTED   │  ─────────────────> │    CURED    │
│ (dados raw) │   Filtra Colunas    │ (dados      │   Filtra Livros     │ (livros     │
│             │   Preenche null     │  limpos)    │   Preenche null     │  apenas)    │
└─────────────┘                     └─────────────┘                     └─────────────┘
     CSV/XLSX                            CSV                                  CSV
```

### 🔄 Estágios do Pipeline

#### **Estágio 1: STAGING (Dados Brutos)**
Armazena dados originais sem processamento.

#### **Estágio 2: TRUSTED (Dados Limpos)**
**Lambda**: `staging-to-trusted-etl`

**Transformações aplicadas:**
- Filtra **apenas** as seguintes colunas:
  - `data`
  - `dia da semana`
  - `feriado`
  - `product_category_name`
  - `seller_city`
  - `seller_state`
  - `quantidade`
  - `obra vendida`
  - `valor pago`
  - `forma de pagamento`
- Preenche campos vazios com `null`
- Normaliza nomes de colunas (case-insensitive)

#### **Estágio 3: CURED (Dados Refinados)**
**Lambda**: `trusted-to-cured-etl`

**Transformações aplicadas:**
- Mantém **apenas** registros onde `product_category_name` contém:
  - `livro`
  - `book`
  - `literatura`
- Remove todas as outras categorias
- Mantém preenchimento de `null` para campos vazios
- Gera estatísticas de processamento

### 🚀 Como Usar o Pipeline ETL

#### 1. **Enviar Dados Brutos ao Staging**

```bash
# Enviar arquivo CSV
aws s3 cp meus_dados.csv s3://aej-staging-bucket-XXXXXX/

# Enviar múltiplos arquivos
aws s3 cp ./dados/ s3://aej-staging-bucket-XXXXXX/ --recursive --exclude "*" --include "*.csv"
```

⚠️ **Importante**: Use arquivos **CSV** para melhor compatibilidade. Excel (.xlsx) requer layer com pandas.

#### 2. **Aguardar Processamento Automático**

O pipeline é totalmente automático:

1. **Lambda 1** detecta arquivo no Staging → processa → salva no Trusted
2. **Lambda 2** detecta arquivo no Trusted → processa → salva no Cured

```bash
# Monitorar logs em tempo real
aws logs tail /aws/lambda/staging-to-trusted-etl --follow
aws logs tail /aws/lambda/trusted-to-cured-etl --follow
```

#### 3. **Baixar Dados Processados**

```bash
# Listar arquivos processados
aws s3 ls s3://aej-trusted-bucket-XXXXXX/trusted/
aws s3 ls s3://aej-cured-bucket-XXXXXX/cured/

# Baixar dados limpos (todas colunas filtradas)
aws s3 cp s3://aej-trusted-bucket-XXXXXX/trusted/ ./dados_trusted/ --recursive

# Baixar dados refinados (apenas livros)
aws s3 cp s3://aej-cured-bucket-XXXXXX/cured/ ./dados_cured/ --recursive
```

### 📁 Estrutura de Arquivos nos Buckets

```
📦 aej-staging-bucket-XXXXXX/
└── vendas_2024.csv                    # Dados originais

📦 aej-trusted-bucket-XXXXXX/
└── trusted/
    └── vendas_2024_trusted_20251019_143022.csv   # Colunas filtradas

📦 aej-cured-bucket-XXXXXX/
└── cured/
    └── vendas_2024_cured_20251019_143025.csv     # Apenas livros
```

### 📋 Exemplo de Transformação

**Entrada (Staging):**
```csv
data,dia da semana,feriado,product_category_name,seller_city,quantidade,outra_coluna
2024-01-01,Segunda,Sim,livros_tecnicos,São Paulo,5,valor_ignorado
2024-01-02,Terça,Não,eletronicos,Rio de Janeiro,3,outro_valor
2024-01-03,Quarta,Não,livros_ficcao,Curitiba,2,mais_dados
```

**Saída Trusted (colunas filtradas):**
```csv
data,dia da semana,feriado,product_category_name,seller_city,seller_state,quantidade,obra vendida,valor pago,forma de pagamento
2024-01-01,Segunda,Sim,livros_tecnicos,São Paulo,null,5,null,null,null
2024-01-02,Terça,Não,eletronicos,Rio de Janeiro,null,3,null,null,null
2024-01-03,Quarta,Não,livros_ficcao,Curitiba,null,2,null,null,null
```

**Saída Cured (apenas livros):**
```csv
data,dia da semana,feriado,product_category_name,seller_city,seller_state,quantidade,obra vendida,valor pago,forma de pagamento
2024-01-01,Segunda,Sim,livros_tecnicos,São Paulo,null,5,null,null,null
2024-01-03,Quarta,Não,livros_ficcao,Curitiba,null,2,null,null,null
```

### ⚙️ Configurações dos Lambdas ETL

| Lambda | Memória | Timeout | Trigger | Output |
|--------|---------|---------|---------|--------|
| staging-to-trusted | 512 MB | 5 min | S3 `.csv` no Staging | Trusted bucket |
| trusted-to-cured | 512 MB | 5 min | S3 `.csv` no Trusted | Cured bucket |

### 🔍 Monitoramento e Logs

**Ver execuções recentes:**
```bash
# Listar streams de log
aws logs describe-log-streams \
  --log-group-name "/aws/lambda/staging-to-trusted-etl" \
  --order-by LastEventTime \
  --descending \
  --max-items 5

# Filtrar logs por período
aws logs filter-log-events \
  --log-group-name "/aws/lambda/trusted-to-cured-etl" \
  --start-time $(date -d '1 hour ago' +%s)000
```

**Logs incluem:**
- Arquivo de origem processado
- Colunas encontradas e mapeadas
- Número de linhas processadas
- Estatísticas (total, aceitas, descartadas)
- Localização do arquivo de saída

### 🧹 Limpeza dos Buckets ETL

Antes de destruir a infraestrutura:

```bash
# Esvaziar todos os buckets ETL
aws s3 rm s3://aej-staging-bucket-XXXXXX --recursive
aws s3 rm s3://aej-trusted-bucket-XXXXXX --recursive
aws s3 rm s3://aej-cured-bucket-XXXXXX --recursive

# Depois destruir
terraform destroy -auto-approve
```

**Ou configure `force_destroy = true`** (já configurado por padrão nos buckets ETL).

### 🐛 Troubleshooting ETL

**Problema**: Lambda não está processando
- Verifique se o arquivo é `.csv` (Excel requer layer pandas)
- Confirme que enviou para o bucket correto (staging)
- Verifique logs no CloudWatch

**Problema**: Colunas não encontradas
- O Lambda normaliza nomes (case-insensitive)
- Verifique se as colunas existem no CSV original
- Veja logs para mapeamento de colunas

**Problema**: Nenhum livro no Cured
- Verifique se `product_category_name` contém 'livro', 'book' ou 'literatura'
- Veja estatísticas nos logs do Lambda

**Problema**: Arquivo muito grande
- Aumente `timeout` e `memory_size` dos Lambdas no Terraform
- Considere dividir arquivos grandes em chunks menores

### 💡 Dicas de Uso

1. **Use CSV em vez de Excel** para melhor performance e compatibilidade
2. **Monitore os logs** durante o primeiro processamento para validar mapeamento de colunas
3. **Teste com arquivo pequeno** primeiro para validar o pipeline
4. **Revise os outputs** do Terraform para ver nomes dos buckets criados

---
