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
  - staging-bucket-aej
  - trusted-bucket-aej
  - cured-bucket-aej

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
