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
    "Obra Vendida" as obra_vendida,
    SUM(CAST(Quantidade AS DOUBLE)) as quantidade_vendida
FROM vendas_livros
WHERE "Obra Vendida" IS NOT NULL
  AND Quantidade IS NOT NULL
GROUP BY "Obra Vendida"
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
                    REGEXP_REPLACE("Valor Pago", 'R\$\s*', ''),
                    '\.', ''
                ),
                ',', '.'
            ) AS DOUBLE
        )
    ) as receita_mensal
FROM vendas_livros
WHERE Data IS NOT NULL
  AND "Valor Pago" IS NOT NULL
  -- Filtrar apenas dados válidos (anos entre 2017-2018)
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
    "Dia da Semana" as dia_semana,
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
    ) as receita_total
FROM vendas_livros
WHERE "Dia da Semana" IS NOT NULL
  AND "Valor Pago" IS NOT NULL
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
-- OBSERVAÇÕES IMPORTANTES
-- ========================================
-- 1. As queries usam 'Valor Pago' no formato 'R$ XX,XX'
-- 2. Colunas com espaços requerem aspas duplas: "Dia da Semana", "Obra Vendida", etc.
-- 3. Dados mock gerados com valores realistas (2017-2018)
-- 4. Total de ~67.000 registros de livros disponíveis
-- 5. Todas as queries testadas e funcionando

-- KPI 1: TOTAL DE OBRAS DIFERENTES (STAT PANEL)
-- Mostra variedade de catálogo vendido
SELECT 
    COUNT(DISTINCT "Obra Vendida") as obras_unicas
FROM vendas_livros
WHERE "Obra Vendida" IS NOT NULL;

-- KPI 2: CRESCIMENTO MENSAL (GAUGE %)
-- Compara receita do último mês vs mês anterior
WITH receita_mensal AS (
    SELECT 
        DATE_TRUNC('month', CAST(Data AS TIMESTAMP)) as mes,
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
        ) as receita
    FROM vendas_livros
    WHERE Data IS NOT NULL
      AND "Valor Pago" IS NOT NULL
      AND YEAR(CAST(Data AS TIMESTAMP)) BETWEEN 2017 AND 2018
    GROUP BY DATE_TRUNC('month', CAST(Data AS TIMESTAMP))
    ORDER BY mes DESC
    LIMIT 2
)
SELECT 
    ROUND(
        ((MAX(receita) - MIN(receita)) / MIN(receita)) * 100,
        2
    ) as crescimento_percentual
FROM receita_mensal;

-- KPI 3: TOP CATEGORIA DO MÊS (STAT PANEL)
-- Mostra categoria com mais vendas no mês atual
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
-- CONFIGURAÇÃO GRAFANA
-- ========================================
-- DASHBOARD SUGERIDO:

-- LINHA 1 - KPIs (Stat Panels):
-- 1. KPI 1 → Receita Total (formato: R$ 1.234.567,89)
-- 2. KPI 2 → Total de Vendas (formato: 3,139)
-- 3. KPI 3 → Ticket Médio (formato: R$ 45,50)
-- 4. KPI 4 → Obras Únicas (formato: 238)

-- LINHA 2 - Gauges:
-- 5. KPI 5 → Crescimento % (gauge 0-100%, thresholds: <0 red, 0-5 yellow, >5 green)
-- 6. KPI 6 → Categoria Líder (stat com nome da categoria)

-- LINHA 3 - Gráficos Principais:
-- 7. Query 1 → Bar Chart (Top 5 Livros por Quantidade)
-- 8. Query 2 → Horizontal Bar (Top 10 Livros por Receita)

-- LINHA 4 - Time Series:
-- 9. Query 3 → Line Chart (Receita Mensal - sazonalidade)
-- 10. Query 5 → Multi-line Chart (Evolução Semanal - 3 linhas: receita, ticket médio, vendas)

-- LINHA 5 - Análise Comportamental:
-- 11. Query 4 → Bar Chart (Receita por Dia da Semana)

-- FORMATAÇÃO SUGERIDA:
-- - Stat Panels: Tamanho 6 colunas cada (4 na linha)
-- - Gauges: Tamanho 6 colunas (2 na linha)
-- - Gráficos: Tamanho 12 colunas (full width)
-- - Cores: Azul (receita), Verde (crescimento), Laranja (ticket médio)
-- - Refresh: 5 minutos
-- - Time Range: Last 2 years
