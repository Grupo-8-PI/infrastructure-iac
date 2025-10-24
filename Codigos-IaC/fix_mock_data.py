"""
Script para limpar e mockar dados do CSV de vendas de livros
Remove coluna 'Feriado', corrige datas inválidas e preenche nulls com dados realistas
"""

import pandas as pd
import random
from datetime import datetime, timedelta

# Configurações
INPUT_FILE = r"C:\Users\leode\Downloads\bases_tratados\bases_tratados\tabelao_tratado.csv"
OUTPUT_FILE = r"c:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\vendas_livros_limpo.csv"

# ========================================
# DADOS MOCK REALISTAS
# ========================================

CIDADES_BR = {
    'SP': ['SAO PAULO', 'CAMPINAS', 'SANTOS', 'RIBEIRAO PRETO', 'SOROCABA', 
           'SAO JOSE DOS CAMPOS', 'GUARULHOS', 'OSASCO', 'BAURU', 'PIRACICABA'],
    'RJ': ['RIO DE JANEIRO', 'NITEROI', 'DUQUE DE CAXIAS', 'NOVA IGUACU', 
           'SAO GONCALO', 'CAMPOS DOS GOYTACAZES', 'PETROPOLIS'],
    'MG': ['BELO HORIZONTE', 'UBERLANDIA', 'CONTAGEM', 'JUIZ DE FORA', 
           'BETIM', 'MONTES CLAROS', 'RIBEIRAO DAS NEVES'],
    'PR': ['CURITIBA', 'LONDRINA', 'MARINGA', 'PONTA GROSSA', 'CASCAVEL', 
           'SAO JOSE DOS PINHAIS', 'FOZ DO IGUACU'],
    'RS': ['PORTO ALEGRE', 'CAXIAS DO SUL', 'PELOTAS', 'CANOAS', 'SANTA MARIA', 
           'GRAVATAI', 'NOVO HAMBURGO'],
    'BA': ['SALVADOR', 'FEIRA DE SANTANA', 'VITORIA DA CONQUISTA', 'CAMACARI', 
           'ITABUNA', 'JUAZEIRO', 'LAURO DE FREITAS'],
    'SC': ['FLORIANOPOLIS', 'JOINVILLE', 'BLUMENAU', 'SAO JOSE', 'CHAPECO', 
           'CRICIUMA', 'ITAJAI'],
    'GO': ['GOIANIA', 'APARECIDA DE GOIANIA', 'ANAPOLIS', 'RIO VERDE', 
           'LUZIANIA', 'AGUAS LINDAS DE GOIAS'],
    'PE': ['RECIFE', 'JABOATAO DOS GUARARAPES', 'OLINDA', 'CARUARU', 
           'PETROLINA', 'PAULISTA', 'CABO DE SANTO AGOSTINHO'],
    'CE': ['FORTALEZA', 'CAUCAIA', 'JUAZEIRO DO NORTE', 'MARACANAU', 
           'SOBRAL', 'CRATO', 'ITAPIPOCA']
}

LIVROS_BRASIL = [
    'DOM CASMURRO',
    'GRANDE SERTAO: VEREDAS',
    'MACUNAIMA',
    'CAPITAES DA AREIA',
    'MEMÓRIAS PÓSTUMAS DE BRÁS CUBAS',
    'O CORTIÇO',
    'VIDAS SECAS',
    'A HORA DA ESTRELA',
    'SÃO BERNARDO',
    'QUINCAS BORBA',
    'IRACEMA',
    'O GUARANI',
    'MEMÓRIAS DE UM SARGENTO DE MILÍCIAS',
    'TRISTE FIM DE POLICARPO QUARESMA',
    'GABRIELA, CRAVO E CANELA',
    'A MORENINHA',
    'SENHORA',
    'LUCÍOLA',
    'O PRIMO BASÍLIO',
    'OS SERTÕES',
    'CASA GRANDE & SENZALA',
    'RAÍZES DO BRASIL',
    'O MULATO',
    'CLARA DOS ANJOS',
    'MENINO DO ENGENHO',
    'FOGO MORTO',
    'MENINO DE ENGENHO',
    'A BAGACEIRA',
    'AMAR, VERBO INTRANSITIVO',
    'TERRA SONÂMBULA',
    'O AUTO DA COMPADECIDA',
    'A PAIXÃO SEGUNDO G.H.',
    'LAÇOS DE FAMÍLIA',
    'FELICIDADE CLANDESTINA',
    'SAGARANA',
    'PRIMEIRAS ESTÓRIAS',
    'AVE, PALAVRA',
    'MAR MORTO',
    'JUBIABÁ',
    'TERRAS DO SEM FIM',
    'TOCAIA GRANDE',
    'DONA FLOR E SEUS DOIS MARIDOS',
    'TENDA DOS MILAGRES',
    'O TEMPO E O VENTO',
    'INCIDENTE EM ANTARES',
    'AGOSTO',
    'UM COPO DE CÓLERA',
    'LAVOURA ARCAICA',
    'CIDADE DE DEUS',
    'O FILHO ETERNO'
]

CATEGORIAS = [
    'LIVROS_INTERESSE_GERAL',
    'LIVROS_TECNICOS',
    'LIVROS_IMPORTADOS'
]

FORMAS_PAGAMENTO = ['PIX', 'CREDITO', 'DEBITO', 'BOLETO', 'GRU']

DIAS_SEMANA = {
    0: 'SEGUNDA-FEIRA',
    1: 'TERCA-FEIRA',
    2: 'QUARTA-FEIRA',
    3: 'QUINTA-FEIRA',
    4: 'SEXTA-FEIRA',
    5: 'SABADO',
    6: 'DOMINGO'
}

# ========================================
# FUNÇÕES AUXILIARES
# ========================================

def gerar_data_aleatoria():
    """Gera data entre 2017-01-01 e 2018-12-31"""
    start_date = datetime(2017, 1, 1)
    end_date = datetime(2018, 12, 31)
    time_between = end_date - start_date
    days_between = time_between.days
    random_days = random.randint(0, days_between)
    random_date = start_date + timedelta(days=random_days)
    
    # Adicionar horário aleatório
    random_hour = random.randint(8, 20)
    random_minute = random.randint(0, 59)
    random_second = random.randint(0, 59)
    
    random_date = random_date.replace(
        hour=random_hour,
        minute=random_minute,
        second=random_second
    )
    
    return random_date

def calcular_dia_semana(data_str):
    """Calcula dia da semana a partir de string de data"""
    try:
        if pd.isna(data_str) or data_str == 'null':
            return None
        data = pd.to_datetime(data_str)
        return DIAS_SEMANA[data.weekday()]
    except:
        return None

def gerar_preco():
    """Gera preço realista de livro"""
    precos = [10.00, 15.00, 20.00, 25.00, 27.00, 30.00, 35.00, 40.00, 45.00, 
              50.00, 60.00, 75.00, 80.00, 90.00, 100.00]
    return random.choice(precos)

def formatar_preco(preco):
    """Formata preço para padrão brasileiro"""
    return f"R$ {preco:.2f}".replace('.', ',')

# ========================================
# PROCESSAMENTO DO CSV
# ========================================

print("=" * 60)
print("LIMPEZA E MOCK DE DADOS - VENDAS DE LIVROS")
print("=" * 60)

# Ler CSV
print(f"\n1. Lendo arquivo: {INPUT_FILE}")
df = pd.read_csv(INPUT_FILE, low_memory=False)
print(f"   Total de linhas: {len(df)}")
print(f"   Total de colunas: {len(df.columns)}")

# Identificar colunas que precisamos
colunas_necessarias = {
    'data': None,
    'dia_da_semana': None,
    'product_category_name': None,
    'seller_city': None,
    'seller_state': None,
    'quantidade': None,
    'obra_vendida': None,
    'valor_pago': None,
    'forma_de_pagamento': None
}

# Mapear colunas existentes para as necessárias
print("\n2. Identificando colunas necessárias...")
for col in df.columns:
    col_lower = col.lower().strip()
    
    if 'order_purchase_timestamp' in col_lower or (col_lower == 'data' and colunas_necessarias['data'] is None):
        colunas_necessarias['data'] = col
        print(f"   Data: {col}")
    elif 'dia da semana' in col_lower or 'dia_da_semana' in col_lower:
        colunas_necessarias['dia_da_semana'] = col
        print(f"   Dia da Semana: {col}")
    elif col_lower == 'product_category_name':
        colunas_necessarias['product_category_name'] = col
        print(f"   Categoria: {col}")
    elif col_lower == 'seller_city':
        colunas_necessarias['seller_city'] = col
        print(f"   Cidade: {col}")
    elif col_lower == 'seller_state':
        colunas_necessarias['seller_state'] = col
        print(f"   Estado: {col}")
    elif 'quantidade' in col_lower:
        colunas_necessarias['quantidade'] = col
        print(f"   Quantidade: {col}")
    elif 'obra vendida' in col_lower or 'obra_vendida' in col_lower:
        colunas_necessarias['obra_vendida'] = col
        print(f"   Obra: {col}")
    elif 'valor pago' in col_lower or 'valor_pago' in col_lower:
        colunas_necessarias['valor_pago'] = col
        print(f"   Valor: {col}")
    elif 'forma de pagamento' in col_lower or 'forma_de_pagamento' in col_lower:
        colunas_necessarias['forma_de_pagamento'] = col
        print(f"   Forma Pagamento: {col}")

# Verificar se encontramos todas as colunas
colunas_faltantes = [k for k, v in colunas_necessarias.items() if v is None]
if colunas_faltantes:
    print(f"\n⚠️  ATENÇÃO: Colunas não encontradas: {colunas_faltantes}")
    print("   Usando colunas padrão...")
    
    # Fallback para colunas padrão
    if colunas_necessarias['data'] is None:
        if 'order_purchase_timestamp' in df.columns:
            colunas_necessarias['data'] = 'order_purchase_timestamp'
        elif 'Data' in df.columns:
            colunas_necessarias['data'] = 'Data'
    
    for col_necessaria, col_original in colunas_necessarias.items():
        if col_original is None:
            # Tentar encontrar coluna similar
            for col in df.columns:
                if col_necessaria.replace('_', ' ').lower() in col.lower():
                    colunas_necessarias[col_necessaria] = col
                    break

# Selecionar apenas as colunas necessárias
print("\n3. Selecionando colunas necessárias...")
colunas_validas = [v for v in colunas_necessarias.values() if v is not None and v in df.columns]
df = df[colunas_validas].copy()

# Renomear colunas para padrão final
print("\n4. Renomeando colunas para padrão...")
rename_map = {v: k for k, v in colunas_necessarias.items() if v is not None}
df = df.rename(columns=rename_map)
print(f"   Colunas finais: {list(df.columns)}")

# Remover coluna 'Feriado' se existir
if 'feriado' in df.columns or 'Feriado' in df.columns:
    print("\n5. Removendo coluna 'Feriado'...")
    df = df.drop(columns=['feriado'], errors='ignore')
    df = df.drop(columns=['Feriado'], errors='ignore')

# Análise de nulls
print("\n4. Análise de valores NULL:")
nulls_por_coluna = df.isnull().sum() | (df == 'null').sum()
for col, count in nulls_por_coluna.items():
    if count > 0:
        print(f"   {col}: {count} nulls ({count/len(df)*100:.1f}%)")

# Corrigir datas inválidas (futuro ou muito antigas)
print("\n5. Corrigindo datas inválidas...")
datas_corrigidas = 0
for idx, row in df.iterrows():
    data_atual = row['data']
    
    # Se data é null ou inválida
    if pd.isna(data_atual) or data_atual == 'null':
        nova_data = gerar_data_aleatoria()
        df.at[idx, 'data'] = nova_data.strftime('%Y-%m-%d %H:%M:%S')
        df.at[idx, 'dia_da_semana'] = DIAS_SEMANA[nova_data.weekday()]
        datas_corrigidas += 1
    else:
        try:
            data_parsed = pd.to_datetime(data_atual)
            ano = data_parsed.year
            
            # Se ano está fora do range 2017-2018
            if ano < 2017 or ano > 2018:
                nova_data = gerar_data_aleatoria()
                df.at[idx, 'data'] = nova_data.strftime('%Y-%m-%d %H:%M:%S')
                df.at[idx, 'dia_da_semana'] = DIAS_SEMANA[nova_data.weekday()]
                datas_corrigidas += 1
            # Se dia da semana está null, recalcular
            elif pd.isna(row['dia_da_semana']) or row['dia_da_semana'] == 'null':
                df.at[idx, 'dia_da_semana'] = DIAS_SEMANA[data_parsed.weekday()]
        except:
            nova_data = gerar_data_aleatoria()
            df.at[idx, 'data'] = nova_data.strftime('%Y-%m-%d %H:%M:%S')
            df.at[idx, 'dia_da_semana'] = DIAS_SEMANA[nova_data.weekday()]
            datas_corrigidas += 1

print(f"   Datas corrigidas: {datas_corrigidas}")

# Preencher nulls de product_category_name
print("\n6. Preenchendo categorias null...")
cat_preenchidas = 0
for idx, row in df.iterrows():
    if pd.isna(row['product_category_name']) or row['product_category_name'] == 'null':
        df.at[idx, 'product_category_name'] = random.choice(CATEGORIAS)
        cat_preenchidas += 1
print(f"   Categorias preenchidas: {cat_preenchidas}")

# Preencher nulls de seller_state e seller_city
print("\n7. Preenchendo estados e cidades null...")
estados_preenchidos = 0
for idx, row in df.iterrows():
    if pd.isna(row['seller_state']) or row['seller_state'] == 'null':
        estado = random.choice(list(CIDADES_BR.keys()))
        cidade = random.choice(CIDADES_BR[estado])
        df.at[idx, 'seller_state'] = estado
        df.at[idx, 'seller_city'] = cidade
        estados_preenchidos += 1
    elif pd.isna(row['seller_city']) or row['seller_city'] == 'null':
        estado = row['seller_state']
        if estado in CIDADES_BR:
            df.at[idx, 'seller_city'] = random.choice(CIDADES_BR[estado])
        else:
            estado = random.choice(list(CIDADES_BR.keys()))
            df.at[idx, 'seller_state'] = estado
            df.at[idx, 'seller_city'] = random.choice(CIDADES_BR[estado])
        estados_preenchidos += 1

print(f"   Estados/Cidades preenchidos: {estados_preenchidos}")

# Preencher nulls de quantidade
print("\n8. Preenchendo quantidade null...")
qtd_preenchidas = 0
for idx, row in df.iterrows():
    if pd.isna(row['quantidade']) or row['quantidade'] == 'null':
        df.at[idx, 'quantidade'] = random.choice([1.0, 1.0, 1.0, 2.0, 3.0])  # Maioria 1
        qtd_preenchidas += 1
print(f"   Quantidades preenchidas: {qtd_preenchidas}")

# Preencher nulls de obra_vendida
print("\n9. Preenchendo obras null...")
obras_preenchidas = 0
for idx, row in df.iterrows():
    if pd.isna(row['obra_vendida']) or row['obra_vendida'] == 'null':
        df.at[idx, 'obra_vendida'] = random.choice(LIVROS_BRASIL)
        obras_preenchidas += 1
print(f"   Obras preenchidas: {obras_preenchidas}")

# Preencher nulls de valor_pago
print("\n10. Preenchendo valores null...")
valores_preenchidos = 0
for idx, row in df.iterrows():
    if pd.isna(row['valor_pago']) or row['valor_pago'] == 'null':
        preco = gerar_preco()
        df.at[idx, 'valor_pago'] = formatar_preco(preco)
        valores_preenchidos += 1
print(f"   Valores preenchidos: {valores_preenchidos}")

# Preencher nulls de forma_de_pagamento
print("\n11. Preenchendo formas de pagamento null...")
formas_preenchidas = 0
for idx, row in df.iterrows():
    if pd.isna(row['forma_de_pagamento']) or row['forma_de_pagamento'] == 'null':
        df.at[idx, 'forma_de_pagamento'] = random.choice(FORMAS_PAGAMENTO)
        formas_preenchidas += 1
print(f"   Formas de pagamento preenchidas: {formas_preenchidas}")

# Ordenar por data
print("\n12. Ordenando por data...")
df['data_sort'] = pd.to_datetime(df['data'])
df = df.sort_values('data_sort')
df = df.drop(columns=['data_sort'])
df = df.reset_index(drop=True)

# Salvar arquivo limpo
print(f"\n13. Salvando arquivo limpo: {OUTPUT_FILE}")
df.to_csv(OUTPUT_FILE, index=False)

# Estatísticas finais
print("\n" + "=" * 60)
print("ESTATÍSTICAS FINAIS")
print("=" * 60)
print(f"Total de registros: {len(df)}")
print(f"\nDistribuição por categoria:")
print(df['product_category_name'].value_counts())
print(f"\nDistribuição por estado (Top 10):")
print(df['seller_state'].value_counts().head(10))
print(f"\nDistribuição por dia da semana:")
print(df['dia_da_semana'].value_counts())
print(f"\nDistribuição por forma de pagamento:")
print(df['forma_de_pagamento'].value_counts())
print(f"\nRange de datas:")
print(f"  Início: {df['data'].min()}")
print(f"  Fim: {df['data'].max()}")

# Verificar se ainda há nulls
nulls_restantes = (df.isnull().sum() | (df == 'null').sum()).sum()
if nulls_restantes == 0:
    print(f"\n✅ SUCESSO! Nenhum valor NULL restante.")
else:
    print(f"\n⚠️  ATENÇÃO! Ainda há {nulls_restantes} valores NULL.")

print("\n" + "=" * 60)
print("ARQUIVO LIMPO GERADO COM SUCESSO!")
print("=" * 60)
print(f"\nPróximos passos:")
print(f"1. Fazer upload para S3 staging:")
print(f"   aws s3 cp {OUTPUT_FILE} s3://SEU_BUCKET_STAGING/")
print(f"2. Pipeline ETL irá processar automaticamente")
print(f"3. Dados limpos estarão em bucket cured")
print(f"4. Tabela Athena será atualizada")
print(f"5. Grafana terá dados completos para análise")
