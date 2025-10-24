# 📊 SETUP GRAFANA - DASHBOARD VENDAS DE LIVROS

## 🎯 Objetivo
Criar dashboards interativos no Grafana para análise de vendas de livros usando dados do AWS Athena.

---

## 🔧 PRÉ-REQUISITOS

1. **Grafana rodando no ECS** (após `terraform apply`)
2. **Dados processados** no bucket `cured` (pipeline ETL completo)
3. **Athena workgroup** configurado: `livros_analytics_workgroup`
4. **Tabela Athena** criada: `vendas_livros` no database `livros_analytics_db`

---

## 📈 DASHBOARDS CRIADOS

### **DASHBOARD 1: Análise Temporal de Vendas**
**Queries usadas:** Query 1 (Dia da Semana) + Query 3 (Sazonalidade Mensal)

#### Painéis:
1. **Vendas por Dia da Semana** (Bar Chart)
   - Identifica picos de vendas
   - Responde: "Existe pico de vendas por dia da semana?"
   
2. **Evolução Mensal de Vendas** (Time Series)
   - Identifica sazonalidade
   - Responde: "Existe sazonalidade nas vendas?"

---

### **DASHBOARD 2: Produtos e Receita**
**Query usada:** Query 2 (Top 15 Livros por Receita)

#### Painéis:
1. **Top 15 Livros por Receita** (Horizontal Bar Chart)
   - Identifica best-sellers
   - Responde: "Quais livros geraram maior receita?"
   
2. **Métricas Principais** (Stat Panels)
   - Receita total
   - Ticket médio
   - Total de vendas

---

### **DASHBOARD 3: Análise Geográfica**
**Query usada:** Query 4 (Distribuição por Estados)

#### Painéis:
1. **Vendas por Estado** (Geo Map ou Pie Chart)
   - Identifica principais mercados
   - Responde: "Quais regiões vendem mais?"
   
2. **Top 10 Estados** (Table)
   - Detalha receita, vendas e ticket médio por estado

---

### **DASHBOARD 4: Formas de Pagamento**
**Query usada:** Query Bônus 5 (Formas de Pagamento)

#### Painéis:
1. **Distribuição de Pagamentos** (Donut Chart)
   - Identifica preferências de pagamento
   
2. **Receita por Forma de Pagamento** (Bar Chart)

---

## 🚀 PASSO A PASSO - CONFIGURAÇÃO GRAFANA

### **PASSO 1: Acessar Grafana**

```bash
# 1. Obter IP público do container ECS
aws ecs describe-tasks \
  --cluster grafana-livros-cluster \
  --tasks $(aws ecs list-tasks --cluster grafana-livros-cluster --service-name grafana-livros-service --query 'taskArns[0]' --output text) \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text

# 2. Com o Network Interface ID, obter IP público
aws ec2 describe-network-interfaces \
  --network-interface-ids <ENI_ID> \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

**Acessar:** `http://<IP_PUBLICO>:3000`

**Credenciais:**
- Usuário: `admin`
- Senha: `aej2025grafana`

---

### **PASSO 2: Configurar Datasource Athena**

1. **Settings** (engrenagem) → **Data sources** → **Add data source**
2. Procurar por **"Amazon Athena"**
3. Configurar:

```
Name: Athena - Vendas Livros
Authentication Provider: AWS SDK Default
Default Region: us-east-1
Database: livros_analytics_db
Workgroup: livros_analytics_workgroup
Output Location: s3://athena-results-livros-<SUFFIX>/query-results/
```

4. **Save & Test** (deve aparecer "Data source is working")

---

### **PASSO 3: Criar Dashboard - Análise Temporal**

#### 3.1. Criar Dashboard
1. **+ (Plus)** → **Dashboard** → **Add new panel**

#### 3.2. Painel 1 - Vendas por Dia da Semana
```sql
SELECT 
    dia_da_semana,
    COUNT(*) as total_vendas,
    SUM(CAST(quantidade AS DOUBLE)) as quantidade_total,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE valor_pago != 'null' 
  AND quantidade != 'null'
  AND dia_da_semana != 'null'
GROUP BY dia_da_semana
ORDER BY 
    CASE dia_da_semana
        WHEN 'SEGUNDA-FEIRA' THEN 1
        WHEN 'TERCA-FEIRA' THEN 2
        WHEN 'QUARTA-FEIRA' THEN 3
        WHEN 'QUINTA-FEIRA' THEN 4
        WHEN 'SEXTA-FEIRA' THEN 5
        WHEN 'SABADO' THEN 6
        WHEN 'DOMINGO' THEN 7
    END;
```

**Configurações:**
- Visualization: **Bar Chart**
- X-axis: `dia_da_semana`
- Y-axis: `total_vendas`, `receita_total`
- Title: "Vendas por Dia da Semana"

#### 3.3. Painel 2 - Evolução Mensal
```sql
SELECT 
    DATE_TRUNC('month', CAST(data AS TIMESTAMP)) as mes,
    COUNT(*) as total_vendas,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_mensal
FROM vendas_livros
WHERE data != 'null' 
  AND valor_pago != 'null'
  AND YEAR(CAST(data AS TIMESTAMP)) BETWEEN 2016 AND 2020
GROUP BY DATE_TRUNC('month', CAST(data AS TIMESTAMP))
ORDER BY mes;
```

**Configurações:**
- Visualization: **Time Series**
- X-axis: `mes` (Time field)
- Y-axis: `receita_mensal`, `total_vendas`
- Title: "Evolução Mensal de Vendas"

**Salvar Dashboard:** Nome: "Análise Temporal de Vendas"

---

### **PASSO 4: Criar Dashboard - Produtos e Receita**

#### 4.1. Criar novo Dashboard
**+ (Plus)** → **Dashboard** → **Add new panel**

#### 4.2. Painel 1 - Top 15 Livros
```sql
SELECT 
    obra_vendida,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total,
    COUNT(*) as numero_vendas
FROM vendas_livros
WHERE obra_vendida != 'null' 
  AND valor_pago != 'null'
GROUP BY obra_vendida
ORDER BY receita_total DESC
LIMIT 15;
```

**Configurações:**
- Visualization: **Bar Chart (Horizontal)**
- X-axis: `receita_total`
- Y-axis: `obra_vendida`
- Title: "Top 15 Livros por Receita"
- Legend: Mostrar `numero_vendas`

#### 4.3. Painel 2 - Métricas Principais (Stat Panels)

**Receita Total:**
```sql
SELECT 
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE valor_pago != 'null';
```

**Configurações:**
- Visualization: **Stat**
- Title: "Receita Total"
- Unit: `currency (BRL)`

**Total de Vendas:**
```sql
SELECT COUNT(*) as total_vendas
FROM vendas_livros;
```

**Ticket Médio:**
```sql
SELECT 
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as ticket_medio
FROM vendas_livros
WHERE valor_pago != 'null';
```

**Salvar Dashboard:** Nome: "Produtos e Receita"

---

### **PASSO 5: Criar Dashboard - Análise Geográfica**

#### 5.1. Painel 1 - Vendas por Estado
```sql
SELECT 
    seller_state as estado,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_estado,
    COUNT(*) as total_vendas
FROM vendas_livros
WHERE seller_state != 'null' 
  AND valor_pago != 'null'
GROUP BY seller_state
ORDER BY receita_estado DESC
LIMIT 10;
```

**Configurações:**
- Visualization: **Pie Chart** ou **Geomap**
- Title: "Top 10 Estados por Receita"

**Salvar Dashboard:** Nome: "Análise Geográfica"

---

## 🎨 CUSTOMIZAÇÕES RECOMENDADAS

### Cores
- **Receita:** Verde (#73BF69)
- **Vendas:** Azul (#5794F2)
- **Quantidade:** Laranja (#FF9830)

### Unidades
- Receita: `currency (BRL)` ou `R$`
- Vendas/Quantidade: `short`
- Percentuais: `percent (0-100)`

### Refresh
- Auto-refresh: **5 minutos** (para dados atualizados)

---

## 📊 RESPOSTAS ÀS PERGUNTAS DO NEGÓCIO

| Pergunta | Query | Dashboard |
|----------|-------|-----------|
| **6. Pico de vendas por dia?** | Query 1 | Análise Temporal |
| **7. Sazonalidade?** | Query 3 | Análise Temporal |
| **5. Livros com maior receita?** | Query 2 | Produtos e Receita |
| **3. Categorias vendendo mais?** | Query 2 | Produtos e Receita |
| **Análise regional** | Query 4 | Análise Geográfica |

### Perguntas NÃO respondidas (dados faltantes):
- **1. Saída mínima para lucro** → Precisa custo de aquisição
- **2. Categoria menos sai** → Precisa inventário completo
- **4. Tempo médio venda** → Precisa data_doacao
- **8. Picos fora do padrão** → Pode calcular com Query 3 + análise estatística
- **9. Excesso estoque** → Precisa dados de estoque atual
- **10. Valor estoque** → Precisa dados de estoque atual

---

## ✅ CHECKLIST FINAL

- [ ] Grafana rodando e acessível
- [ ] Datasource Athena configurado e testado
- [ ] Query 1 funcionando (dia da semana)
- [ ] Query 2 funcionando (top livros)
- [ ] Query 3 funcionando (sazonalidade)
- [ ] Query 4 funcionando (estados)
- [ ] Dashboard "Análise Temporal" criado
- [ ] Dashboard "Produtos e Receita" criado
- [ ] Dashboard "Análise Geográfica" criado
- [ ] Painéis com cores e unidades corretas
- [ ] Auto-refresh configurado

---

## 🐛 TROUBLESHOOTING

### Erro: "No output location provided"
**Solução:** Verificar workgroup `livros_analytics_workgroup` está selecionado

### Erro: "Table not found"
**Solução:** Verificar que pipeline ETL processou dados para bucket `cured`

### Erro: Query timeout
**Solução:** Adicionar `LIMIT` nas queries ou otimizar com partições

### Grafana não carrega
**Solução:** Verificar Security Group permite porta 3000 e ECS task está Running

---

## 📚 RECURSOS ADICIONAIS

- [Grafana Athena Plugin Docs](https://grafana.com/grafana/plugins/grafana-athena-datasource/)
- [AWS Athena SQL Reference](https://docs.aws.amazon.com/athena/latest/ug/ddl-sql-reference.html)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
