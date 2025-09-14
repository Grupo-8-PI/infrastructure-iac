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
