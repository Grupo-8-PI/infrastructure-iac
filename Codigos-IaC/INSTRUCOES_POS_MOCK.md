# 📝 INSTRUÇÕES - APÓS PREENCHER DADOS MOCK

## ✅ O que foi feito:

O script `fill_nulls_simple.py` processou **99.441 linhas** e preencheu aproximadamente **2.2 milhões de valores null** com dados mock realistas:

### Dados preenchidos:
- **Datas**: 2017-2018 com horários aleatórios
- **Dias da semana**: Segunda a Domingo
- **Categorias**: LIVROS_INTERESSE_GERAL, LIVROS_TECNICOS, LIVROS_IMPORTADOS
- **Cidades/Estados**: 10 estados brasileiros + cidades principais
- **Livros**: 24 clássicos da literatura brasileira
- **Preços**: R$ 10,00 a R$ 80,00
- **Formas de pagamento**: PIX, CREDITO, DEBITO, BOLETO, GRU
- **IDs**: Alfanuméricos de 32 caracteres
- **CEPs**: Formato brasileiro válido
- **Status**: 'delivered'
- **Scores**: 1 a 5 estrelas
- **Medidas**: 10 a 500 (peso, altura, largura)

---

## 🚀 PRÓXIMOS PASSOS

### **PASSO 1: Verificar arquivo gerado**

```powershell
# Ver primeiras linhas
Get-Content "C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo.csv" -Head 10

# Ver tamanho do arquivo
Get-Item "C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo.csv" | Select-Object Name, Length
```

---

### **PASSO 2: Fazer upload para bucket S3 Staging**

```powershell
# Obter nome do bucket staging
terraform output etl_staging_bucket

# Fazer upload do arquivo completo
aws s3 cp "C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo.csv" s3://SEU_BUCKET_STAGING/tabelao_tratado_completo.csv

# Exemplo:
# aws s3 cp "C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo.csv" s3://aej-staging-bucket-bfb246a6/
```

---

### **PASSO 3: Acompanhar processamento ETL**

O pipeline ETL irá processar automaticamente:

**Staging → Trusted (Lambda 1)**
- Filtra 9 colunas importantes
- Calcula dia da semana
- Remove coluna Feriado
- Output: `trusted/tabelao_tratado_completo_trusted_TIMESTAMP.csv`

**Trusted → Cured (Lambda 2)**
- Filtra apenas livros (product_category_name contém 'livro')
- Output: `cured/tabelao_tratado_completo_cured_TIMESTAMP.csv`

```powershell
# Monitorar logs do Lambda Staging→Trusted
aws logs tail /aws/lambda/staging-to-trusted-etl --follow

# Monitorar logs do Lambda Trusted→Cured
aws logs tail /aws/lambda/trusted-to-cured-etl --follow
```

---

### **PASSO 4: Verificar dados no Athena**

Aguardar 2-3 minutos após upload e executar query:

```sql
-- No AWS Athena Console
-- Workgroup: livros_analytics_workgroup
-- Database: livros_analytics_db

SELECT COUNT(*) as total_registros
FROM vendas_livros;

-- Deve retornar aproximadamente 370-400 registros de livros

SELECT *
FROM vendas_livros
LIMIT 10;
```

---

### **PASSO 5: Criar dashboards no Grafana**

Com dados completos, as queries do Grafana funcionarão perfeitamente:

1. **Acesse Grafana**: http://SEU_IP_PUBLICO:3000
    **Para acessar com mais facilidade, utilize o seguinte código:**

    **aws ecs list-tasks --cluster grafana-livros-cluster --service-name grafana-livros-service --output text**

    **aws ecs describe-tasks --cluster grafana-livros-cluster --tasks $taskArn --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text**

    **aws ec2 describe-network-interfaces --network-interface-ids eni-0c6e2bc31e36b6251 --query 'NetworkInterfaces[0].Association.PublicIp' --output text**

2. **Login**: admin / aej2025grafana
3. **Copie queries** de `grafana_queries.sql`
4. **Crie painéis** conforme `GRAFANA_SETUP.md`

---

## 📊 QUERIES GRAFANA ATUALIZADAS

Agora **SEM valores null**, as queries retornarão dados completos:

### Query 1: Vendas por Dia da Semana
```sql
SELECT 
    dia_da_semana,
    COUNT(*) as total_vendas,
    SUM(TRY_CAST(quantidade AS DOUBLE)) as quantidade_total
FROM vendas_livros
WHERE dia_da_semana != 'null'
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

**Resultado esperado**: 7 linhas (uma para cada dia)

---

### Query 2: Top Livros por Receita
```sql
SELECT 
    obra_vendida,
    COUNT(*) as numero_vendas,
    SUM(
        TRY_CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(valor_pago, 'R\$\s*', ''),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE obra_vendida != 'null'
GROUP BY obra_vendida
ORDER BY receita_total DESC
LIMIT 15;
```

**Resultado esperado**: 15-24 livros diferentes

---

### Query 3: Sazonalidade Mensal
```sql
SELECT 
    DATE_TRUNC('month', CAST(data AS TIMESTAMP)) as mes,
    COUNT(*) as total_vendas
FROM vendas_livros
WHERE data != 'null'
  AND YEAR(CAST(data AS TIMESTAMP)) BETWEEN 2017 AND 2018
GROUP BY DATE_TRUNC('month', CAST(data AS TIMESTAMP))
ORDER BY mes;
```

**Resultado esperado**: 24 meses (2017-2018)

---

### Query 4: Distribuição Geográfica
```sql
SELECT 
    seller_state as estado,
    COUNT(*) as total_vendas
FROM vendas_livros
WHERE seller_state != 'null'
GROUP BY seller_state
ORDER BY total_vendas DESC
LIMIT 10;
```

**Resultado esperado**: 10 estados brasileiros

---

## ✅ CHECKLIST FINAL

- [ ] Script `fill_nulls_simple.py` executado com sucesso
- [ ] Arquivo `tabelao_tratado_completo.csv` gerado (sem nulls)
- [ ] Upload para bucket S3 staging realizado
- [ ] Pipeline ETL processou arquivo (verificar logs)
- [ ] Dados aparecem no bucket `cured`
- [ ] Athena mostra ~370 registros de livros
- [ ] Grafana conectado ao Athena
- [ ] Dashboards criados e funcionando
- [ ] Queries retornam dados completos (sem nulls)

---

## 🎯 RESULTADO ESPERADO

Com dados mock completos:
- **99.441 linhas** processadas
- **~370 registros de livros** no cured
- **Todos os campos preenchidos** (zero nulls)
- **Datas válidas** (2017-2018)
- **Análises completas** no Grafana
- **Gráficos funcionais** sem erros de tipo

---

## 🐛 TROUBLESHOOTING

### Problema: "TYPE_MISMATCH" no Athena
**Solução**: Queries já usam `TRY_CAST`, deve funcionar

### Problema: Poucos dados no Grafana
**Solução**: Verificar filtro `WHERE valor_pago != 'null'` - agora não há nulls

### Problema: Pipeline ETL não executou
**Solução**: Verificar trigger S3 e permissões Lambda

### Problema: Grafana não mostra dados
**Solução**: 
1. Verificar workgroup: `livros_analytics_workgroup`
2. Verificar database: `livros_analytics_db`
3. Verificar tabela: `vendas_livros`

---

## 📚 ARQUIVOS RELACIONADOS

- `fill_nulls_simple.py` - Script de preenchimento
- `grafana_queries.sql` - Queries SQL para Grafana
- `GRAFANA_SETUP.md` - Guia completo de setup
- `infra__aej.tf` - Infraestrutura Terraform
- `staging_to_trusted_lambda.py` - ETL stage 1
- `trusted_to_cured_lambda.py` - ETL stage 2
