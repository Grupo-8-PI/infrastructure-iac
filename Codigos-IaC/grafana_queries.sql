-- ========================================
-- QUERIES GRAFANA - ANÁLISE DE VENDAS DE LIVROS (CORRIGIDAS)
-- ========================================
-- Dataset: vendas_livros (AWS Athena)
-- Colunas corretas (com underscore):
--   Data, Dia_da_Semana, product_category_name, seller_city, 
--   seller_state, Quantidade, Obra_Vendida, Valor_Pago, Forma_de_Pagamento
-- IMPORTANTE: Colunas usam UNDERSCORE, não espaços!
-- ========================================

-- ========================================
-- QUERY 1: TOP 5 LIVROS MAIS VENDIDOS
-- ========================================
-- Objetivo: Identificar os livros mais vendidos por quantidade
-- Gráfico recomendado: Bar Chart
-- Responde perguntas: Quais livros vendem mais

SELECT 
    Obra_Vendida as obra_vendida,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_vendida
FROM vendas_livros
WHERE Obra_Vendida IS NOT NULL
  AND Quantidade IS NOT NULL
GROUP BY Obra_Vendida
ORDER BY quantidade_vendida DESC
LIMIT 5;

-- ========================================
-- QUERY 2: CATEGORIAS DE LIVROS MAIS VENDIDAS
-- ========================================
-- Objetivo: Mostrar distribuição de vendas por categoria de livro
-- Gráfico recomendado: Bar Chart
-- Responde perguntas: Quais categorias de livros vendem mais

SELECT 
    product_category_name as categoria,
    COUNT(*) as total_vendas
FROM vendas_livros
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY total_vendas DESC
LIMIT 5;

-- ========================================
-- QUERY 3: ANÁLISE DE SAZONALIDADE MENSAL
-- ========================================
-- Objetivo: Identificar sazonalidade nas vendas (mês a mês)
-- Gráfico recomendado: Line Chart (Time Series)
-- Responde perguntas: 7 (sazonalidade), 8 (picos fora do padrão)

SELECT 
    DATE_TRUNC('month', CAST(Data AS TIMESTAMP)) as mes,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_mensal
FROM vendas_livros
WHERE Data IS NOT NULL
  AND Valor_Pago IS NOT NULL
  AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
GROUP BY DATE_TRUNC('month', CAST(Data AS TIMESTAMP))
ORDER BY mes;

-- ========================================
-- QUERY 4: EVOLUÇÃO DE VENDAS POR DIA DA SEMANA
-- ========================================
-- Objetivo: Identificar padrão de vendas por dia da semana
-- Gráfico recomendado: Bar Chart
-- Responde perguntas: Quais dias da semana vendem mais

SELECT 
    Dia_da_Semana as dia_semana,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE Dia_da_Semana IS NOT NULL
  AND Valor_Pago IS NOT NULL
GROUP BY Dia_da_Semana
ORDER BY 
    CASE Dia_da_Semana
        WHEN 'SEGUNDA-FEIRA' THEN 1
        WHEN 'TERCA-FEIRA' THEN 2
        WHEN 'QUARTA-FEIRA' THEN 3
        WHEN 'QUINTA-FEIRA' THEN 4
        WHEN 'SEXTA-FEIRA' THEN 5
        WHEN 'SABADO' THEN 6
        WHEN 'DOMINGO' THEN 7
    END;

-- ========================================
-- KPIs - STAT PANELS
-- ========================================

-- QUERY FERIADOS COMERCIAIS: Análise de vendas em datas que impulsionam vendas
-- Objetivo: Mostrar receita em feriados comerciais importantes
-- Gráfico recomendado: Bar Chart
-- Feriados incluídos: Natal, Dia das Crianças, Dia das Mães, Dia dos Pais, Dia dos Namorados, Ano Novo
SELECT 
    CASE 
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1) THEN 'Ano Novo'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia das Mães'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia dos Namorados'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia dos Pais'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia das Crianças'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25) THEN 'Natal'
    END as feriado,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE Data IS NOT NULL
  AND Valor_Pago IS NOT NULL
  AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
  AND (
      (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25)
  )
GROUP BY 
    CASE 
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1) THEN 'Ano Novo'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia das Mães'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia dos Namorados'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia dos Pais'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia das Crianças'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25) THEN 'Natal'
    END
ORDER BY receita_total DESC;

-- QUERY FERIADOS COMERCIAIS (com quantidade): Versão com total_vendas
-- Feriados que impulsionam vendas: Natal, Dia das Crianças, Dia das Mães, Dia dos Pais, Dia dos Namorados, Ano Novo
SELECT 
    CASE 
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1) THEN 'Ano Novo'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia das Mães'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia dos Namorados'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia dos Pais'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia das Crianças'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25) THEN 'Natal'
    END as feriado,
    COUNT(*) as total_vendas,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE Data IS NOT NULL
  AND Valor_Pago IS NOT NULL
  AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
  AND (
      (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12)
      OR (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25)
  )
GROUP BY 
    CASE 
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 1 AND DAY(CAST(Data AS TIMESTAMP)) = 1) THEN 'Ano Novo'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 5 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia das Mães'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 6 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia dos Namorados'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 8 AND DAY(CAST(Data AS TIMESTAMP)) BETWEEN 8 AND 14 AND DAY_OF_WEEK(CAST(Data AS TIMESTAMP)) = 7) THEN 'Dia dos Pais'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 10 AND DAY(CAST(Data AS TIMESTAMP)) = 12) THEN 'Dia das Crianças'
        WHEN (MONTH(CAST(Data AS TIMESTAMP)) = 12 AND DAY(CAST(Data AS TIMESTAMP)) = 25) THEN 'Natal'
    END
ORDER BY receita_total DESC;

-- KPI 1: RECEITA TOTAL
SELECT 
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total
FROM vendas_livros
WHERE Valor_Pago IS NOT NULL;

-- KPI 2: TOTAL DE VENDAS (da semana que mais vendeu - para demonstração)
SELECT COUNT(*) as total_vendas
FROM vendas_livros
WHERE Data IS NOT NULL
  AND DATE_TRUNC('week', CAST(Data AS TIMESTAMP)) = (
      SELECT DATE_TRUNC('week', CAST(Data AS TIMESTAMP)) as semana
      FROM vendas_livros
      WHERE Data IS NOT NULL
        AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
      GROUP BY DATE_TRUNC('week', CAST(Data AS TIMESTAMP))
      ORDER BY COUNT(*) DESC
      LIMIT 1
  );

-- KPI 3: TICKET MÉDIO
SELECT 
    ROUND(
        AVG(
            CAST(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                        '\.', ''
                    ),
                    ',', '.'
                ) AS DOUBLE
            )
        ),
        2
    ) as ticket_medio
FROM vendas_livros
WHERE Valor_Pago IS NOT NULL;

-- KPI 4: TOTAL DE OBRAS DIFERENTES
SELECT 
    COUNT(DISTINCT Obra_Vendida) as obras_unicas
FROM vendas_livros
WHERE Obra_Vendida IS NOT NULL;

-- KPI 5: CRESCIMENTO MENSAL (%)
WITH receita_mensal AS (
    SELECT 
        DATE_TRUNC('month', CAST(Data AS TIMESTAMP)) as mes,
        SUM(
            CAST(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(Valor_Pago, 'R\$\s*', ''),
                        '\.', ''
                    ),
                    ',', '.'
                ) AS DOUBLE
            )
        ) as receita
    FROM vendas_livros
    WHERE Data IS NOT NULL
      AND Valor_Pago IS NOT NULL
      AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
    GROUP BY DATE_TRUNC('month', CAST(Data AS TIMESTAMP))
    ORDER BY mes DESC
    LIMIT 2
)
SELECT 
    ROUND(
        ((MAX(receita) - MIN(receita)) / NULLIF(MIN(receita), 0)) * 100,
        2
    ) as crescimento_percentual
FROM receita_mensal;

-- KPI 6: TOP CATEGORIA DO MÊS
SELECT 
    product_category_name as categoria_lider,
    COUNT(*) as vendas
FROM vendas_livros
WHERE product_category_name IS NOT NULL
  AND DATE_TRUNC('month', CAST(Data AS TIMESTAMP)) = (
      SELECT MAX(DATE_TRUNC('month', CAST(Data AS TIMESTAMP)))
      FROM vendas_livros
      WHERE Data IS NOT NULL
  )
GROUP BY product_category_name
ORDER BY vendas DESC
LIMIT 1;

-- ========================================
-- REFERÊNCIA DE COLUNAS
-- ========================================
-- Nome no Athena          | Tipo    | Descrição
-- ------------------------|---------|---------------------------
-- Data                    | string  | Data e hora da compra
-- Dia_da_Semana           | string  | Dia da semana (SEGUNDA-FEIRA, etc)
-- product_category_name   | string  | Categoria do produto
-- seller_city             | string  | Cidade do vendedor
-- seller_state            | string  | Estado do vendedor (SP, RJ, etc)
-- Quantidade              | double  | Quantidade vendida
-- Obra_Vendida            | string  | Nome do livro
-- Valor_Pago              | string  | Valor no formato "R$ XX,XX"
-- Forma_de_Pagamento      | string  | PIX, CREDITO, DEBITO, etc
-- ========================================

-- ========================================
-- CONFIGURAÇÃO GRAFANA - LAYOUT SUGERIDO
-- ========================================
-- LINHA 1 - KPIs (4 Stat Panels):
--   1. Receita Total (KPI 1) - cor verde
--   2. Total de Vendas (KPI 2) - cor azul
--   3. Ticket Médio (KPI 3) - cor laranja
--   4. Obras Únicas (KPI 4) - cor roxo

-- LINHA 2 - Gráficos Principais:
--   5. Top 5 Livros (Query 1) - Bar Chart vertical
--   6. Top 10 por Receita (Query 5) - Horizontal Bar

-- LINHA 3 - Análise Temporal:
--   7. Sazonalidade Mensal (Query 3) - Time Series Line
--   8. Vendas por Dia da Semana (Query 4) - Bar Chart

-- LINHA 4 - Análise Segmentada:
--   9. Vendas por Estado (Query 6) - Pie Chart
--   10. Formas de Pagamento (Query 7) - Donut Chart

-- Cores sugeridas:
--   Receita: #73BF69 (verde)
--   Vendas: #5794F2 (azul)
--   Ticket: #FF9830 (laranja)
--   Estados: Cores automáticas do Grafana

-- Refresh: 5 minutos
-- Time Range: Last 2 years
