-- ========================================
-- QUERIES GRAFANA - ANÁLISE DE VENDAS DE LIVROS (ATUALIZADAS)
-- ========================================
-- Dataset: vendas_livros (AWS Athena)
-- Colunas: Data, "Dia da Semana", product_category_name, seller_city, 
--          seller_state, Quantidade, "Obra Vendida", "Valor Pago", 
--          "Forma de Pagamento"
-- IMPORTANTE: Colunas com espaços usam aspas duplas
-- ========================================

-- ========================================
-- QUERY 1: VENDAS POR DIA DA SEMANA (TIME SERIES)
-- ========================================
-- Objetivo: Identificar picos de vendas por dia da semana
-- Gráfico recomendado: Bar Chart ou Time Series
-- Responde perguntas: 6 (pico de vendas por dia)

SELECT 
    "Dia da Semana" as dia_da_semana,
    COUNT(*) as total_vendas,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_total,
    -- Calcular receita removendo 'R$', pontos de milhar e convertendo vírgula em ponto
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total,
    -- Ticket médio
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as ticket_medio
FROM vendas_livros
WHERE "Valor Pago" IS NOT NULL
  AND Quantidade IS NOT NULL
  AND "Dia da Semana" IS NOT NULL
GROUP BY "Dia da Semana"
ORDER BY 
    CASE "Dia da Semana"
        WHEN 'SEGUNDA-FEIRA' THEN 1
        WHEN 'TERCA-FEIRA' THEN 2
        WHEN 'QUARTA-FEIRA' THEN 3
        WHEN 'QUINTA-FEIRA' THEN 4
        WHEN 'SEXTA-FEIRA' THEN 5
        WHEN 'SABADO' THEN 6
        WHEN 'DOMINGO' THEN 7
    END;


-- ========================================
-- QUERY 2: TOP 15 LIVROS POR RECEITA
-- ========================================
-- Objetivo: Identificar quais livros geraram maior receita
-- Gráfico recomendado: Horizontal Bar Chart
-- Responde perguntas: 5 (livros com maior receita), 3 (categorias vendendo mais)

SELECT 
    "Obra Vendida" as obra_vendida,
    product_category_name as categoria,
    COUNT(*) as numero_vendas,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_vendida,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total,
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as preco_medio
FROM vendas_livros
WHERE "Obra Vendida" IS NOT NULL
  AND "Valor Pago" IS NOT NULL
GROUP BY "Obra Vendida", product_category_name
ORDER BY receita_total DESC
LIMIT 15;


-- ========================================
-- QUERY 3: ANÁLISE DE SAZONALIDADE MENSAL
-- ========================================
-- Objetivo: Identificar sazonalidade nas vendas (mês a mês)
-- Gráfico recomendado: Line Chart (Time Series)
-- Responde perguntas: 7 (sazonalidade), 8 (picos fora do padrão)

SELECT 
    DATE_TRUNC('month', CAST(Data AS TIMESTAMP)) as mes,
    COUNT(*) as total_vendas,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_total,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_mensal,
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as ticket_medio_mensal,
    -- Contagem de livros únicos vendidos no mês
    COUNT(DISTINCT "Obra Vendida") as livros_unicos
FROM vendas_livros
WHERE Data IS NOT NULL
  AND "Valor Pago" IS NOT NULL
  AND Quantidade IS NOT NULL
  -- Filtrar apenas dados válidos (anos entre 2017-2018)
  AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
GROUP BY DATE_TRUNC('month', CAST(Data AS TIMESTAMP))
ORDER BY mes;


-- ========================================
-- QUERY 4: DISTRIBUIÇÃO GEOGRÁFICA DE VENDAS (TOP ESTADOS)
-- ========================================
-- Objetivo: Identificar principais mercados por estado
-- Gráfico recomendado: Pie Chart ou Geo Map
-- Responde perguntas: 2 (categoria que menos sai por região), análise regional

SELECT 
    seller_state as estado,
    COUNT(*) as total_vendas,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_vendida,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_estado,
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as ticket_medio,
    -- Percentual em relação ao total
    ROUND(
        CAST(COUNT(*) AS DOUBLE) * 100.0 / 
        (SELECT COUNT(*) FROM vendas_livros WHERE seller_state IS NOT NULL),
        2
    ) as percentual_vendas
FROM vendas_livros
WHERE seller_state IS NOT NULL
  AND "Valor Pago" IS NOT NULL
GROUP BY seller_state
ORDER BY receita_estado DESC
LIMIT 10;


-- ========================================
-- QUERY BÔNUS 5: ANÁLISE DE FORMAS DE PAGAMENTO
-- ========================================
-- Objetivo: Entender preferências de pagamento
-- Gráfico recomendado: Donut Chart

SELECT 
    "Forma de Pagamento" as forma_de_pagamento,
    COUNT(*) as total_transacoes,
    SUM(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_total,
    AVG(
        CAST(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as ticket_medio,
    ROUND(
        CAST(COUNT(*) AS DOUBLE) * 100.0 / 
        (SELECT COUNT(*) FROM vendas_livros WHERE "Forma de Pagamento" IS NOT NULL),
        2
    ) as percentual
FROM vendas_livros
WHERE "Forma de Pagamento" IS NOT NULL
  AND "Valor Pago" IS NOT NULL
GROUP BY "Forma de Pagamento"
ORDER BY total_transacoes DESC;


-- ========================================
-- OBSERVAÇÕES IMPORTANTES
-- ========================================
-- 1. As queries usam 'Valor Pago' no formato 'R$ XX,XX'
-- 2. Colunas com espaços requerem aspas duplas: "Dia da Semana", "Obra Vendida", etc.
-- 3. Dados mock gerados com valores realistas (2017-2018)
-- 4. Total de ~67.000 registros de livros disponíveis
-- 5. Todas as queries testadas e funcionando

-- ========================================
-- CONFIGURAÇÃO GRAFANA
-- ========================================
-- 1. Criar datasource Athena
-- 2. Para cada query, criar um novo panel
-- 3. Query 1 → Bar Chart (X: dia_da_semana, Y: total_vendas)
-- 4. Query 2 → Horizontal Bar (X: receita_total, Y: obra_vendida)
-- 5. Query 3 → Time Series (X: mes, Y: receita_mensal, total_vendas)
-- 6. Query 4 → Geo Map ou Pie Chart (Values: receita_estado, Label: estado)
-- 7. Query 5 → Donut Chart (Values: total_transacoes, Label: forma_de_pagamento)
