"""
Script simplificado para preencher valores null com dados mock
Mantém todas as colunas originais, apenas substitui 'null' por valores realistas
"""

import pandas as pd
import random
from datetime import datetime, timedelta

# Configurações
INPUT_FILE = r"C:\Users\leode\Downloads\bases_tratados\bases_tratados\tabelao_tratado.csv"
OUTPUT_FILE = r"C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo.csv"

# ========================================
# DADOS MOCK REALISTAS
# ========================================

CIDADES_BR = {
    'SP': ['SAO PAULO', 'CAMPINAS', 'SANTOS', 'RIBEIRAO PRETO', 'SOROCABA'],
    'RJ': ['RIO DE JANEIRO', 'NITEROI', 'DUQUE DE CAXIAS', 'NOVA IGUACU'],
    'MG': ['BELO HORIZONTE', 'UBERLANDIA', 'CONTAGEM', 'JUIZ DE FORA'],
    'PR': ['CURITIBA', 'LONDRINA', 'MARINGA', 'PONTA GROSSA'],
    'RS': ['PORTO ALEGRE', 'CAXIAS DO SUL', 'PELOTAS', 'CANOAS'],
    'BA': ['SALVADOR', 'FEIRA DE SANTANA', 'VITORIA DA CONQUISTA'],
    'SC': ['FLORIANOPOLIS', 'JOINVILLE', 'BLUMENAU', 'SAO JOSE'],
    'GO': ['GOIANIA', 'APARECIDA DE GOIANIA', 'ANAPOLIS'],
    'PE': ['RECIFE', 'JABOATAO DOS GUARARAPES', 'OLINDA'],
    'CE': ['FORTALEZA', 'CAUCAIA', 'JUAZEIRO DO NORTE']
}

LIVROS_BRASIL = [
    'DOM CASMURRO', 'GRANDE SERTAO: VEREDAS', 'MACUNAIMA',
    'CAPITAES DA AREIA', 'MEMORIAS POSTUMAS DE BRAS CUBAS',
    'O CORTICO', 'VIDAS SECAS', 'A HORA DA ESTRELA',
    'SAO BERNARDO', 'QUINCAS BORBA', 'IRACEMA', 'O GUARANI',
    'MEMORIAS DE UM SARGENTO DE MILICIAS', 'GABRIELA CRAVO E CANELA',
    'A MORENINHA', 'SENHORA', 'LUCIOLA', 'O PRIMO BASILIO',
    'OS SERTOES', 'CASA GRANDE & SENZALA', 'RAIZES DO BRASIL',
    'O MULATO', 'CLARA DOS ANJOS', 'MENINO DO ENGENHO'
]

CATEGORIAS = ['LIVROS_INTERESSE_GERAL', 'LIVROS_TECNICOS', 'LIVROS_IMPORTADOS']
FORMAS_PAGAMENTO = ['PIX', 'CREDITO', 'DEBITO', 'BOLETO', 'GRU']
DIAS_SEMANA = ['SEGUNDA-FEIRA', 'TERCA-FEIRA', 'QUARTA-FEIRA', 
               'QUINTA-FEIRA', 'SEXTA-FEIRA', 'SABADO', 'DOMINGO']

# ========================================
# FUNÇÕES AUXILIARES
# ========================================

def gerar_data_aleatoria():
    """Gera data entre 2017-01-01 e 2018-12-31"""
    start_date = datetime(2017, 1, 1)
    days = random.randint(0, 729)  # 2 anos
    random_date = start_date + timedelta(days=days)
    
    random_hour = random.randint(8, 20)
    random_minute = random.randint(0, 59)
    random_second = random.randint(0, 59)
    
    random_date = random_date.replace(
        hour=random_hour, minute=random_minute, second=random_second
    )
    
    return random_date.strftime('%Y-%m-%d %H:%M:%S')

def gerar_preco():
    """Gera preço realista"""
    precos = [10.00, 15.00, 20.00, 25.00, 27.00, 30.00, 35.00, 
              40.00, 45.00, 50.00, 60.00, 75.00, 80.00]
    return random.choice(precos)

def formatar_preco(preco):
    """Formata preço para R$ XX,XX"""
    return f"R$ {preco:.2f}".replace('.', ',')

def gerar_cep():
    """Gera CEP brasileiro"""
    return f"{random.randint(1000, 9999)}{random.randint(100, 999)}"

def gerar_id():
    """Gera ID alfanumérico"""
    chars = '0123456789abcdef'
    return ''.join(random.choice(chars) for _ in range(32))

# ========================================
# PROCESSAMENTO
# ========================================

print("=" * 70)
print("PREENCHIMENTO DE VALORES NULL - DADOS MOCK")
print("=" * 70)

print(f"\n1. Lendo arquivo: {INPUT_FILE}")
df = pd.read_csv(INPUT_FILE, low_memory=False)
print(f"   Total de linhas: {len(df)}")
print(f"   Total de colunas: {len(df.columns)}")

# Análise inicial de nulls
print("\n2. Análise de valores NULL/null:")
total_nulls = 0
for col in df.columns:
    null_count = df[col].isna().sum() + (df[col] == 'null').sum()
    if null_count > 0:
        pct = (null_count / len(df)) * 100
        print(f"   {col}: {null_count} ({pct:.1f}%)")
        total_nulls += null_count

print(f"\n   Total de valores NULL: {total_nulls}")

# Preencher valores null por tipo de coluna
print("\n3. Preenchendo valores null...")

linhas_processadas = 0
for idx, row in df.iterrows():
    modificado = False
    
    for col in df.columns:
        valor = row[col]
        
        # Verificar se é null (string 'null' ou pd.NA)
        if pd.isna(valor) or str(valor).strip().lower() == 'null':
            col_lower = col.lower().strip()
            
            # DATAS
            if 'timestamp' in col_lower or col_lower in ['data', 'data.1']:
                df.at[idx, col] = gerar_data_aleatoria()
                modificado = True
            
            # DIA DA SEMANA
            elif 'dia' in col_lower and 'semana' in col_lower:
                df.at[idx, col] = random.choice(DIAS_SEMANA)
                modificado = True
            
            # CATEGORIAS
            elif 'category_name' in col_lower and 'english' not in col_lower:
                df.at[idx, col] = random.choice(CATEGORIAS)
                modificado = True
            
            elif 'category_name_english' in col_lower:
                df.at[idx, col] = random.choice(['general_interest', 
                                                  'technical', 'imported'])
                modificado = True
            
            # CIDADES
            elif 'city' in col_lower:
                estado = df.at[idx, 'seller_state']
                if pd.isna(estado) or str(estado) == 'null':
                    estado = random.choice(list(CIDADES_BR.keys()))
                    df.at[idx, 'seller_state'] = estado
                
                if estado in CIDADES_BR:
                    df.at[idx, col] = random.choice(CIDADES_BR[estado])
                else:
                    estado_novo = random.choice(list(CIDADES_BR.keys()))
                    df.at[idx, col] = random.choice(CIDADES_BR[estado_novo])
                modificado = True
            
            # ESTADOS
            elif 'state' in col_lower:
                df.at[idx, col] = random.choice(list(CIDADES_BR.keys()))
                modificado = True
            
            # CEP
            elif 'zip_code' in col_lower:
                df.at[idx, col] = gerar_cep()
                modificado = True
            
            # IDs
            elif '_id' in col_lower:
                df.at[idx, col] = gerar_id()
                modificado = True
            
            # QUANTIDADE
            elif 'quantidade' in col_lower:
                df.at[idx, col] = random.choice([1.0, 1.0, 1.0, 2.0, 3.0])
                modificado = True
            
            # OBRA VENDIDA
            elif 'obra' in col_lower:
                df.at[idx, col] = random.choice(LIVROS_BRASIL)
                modificado = True
            
            # VALORES
            elif 'valor' in col_lower or 'price' in col_lower:
                df.at[idx, col] = formatar_preco(gerar_preco())
                modificado = True
            
            # FORMA DE PAGAMENTO
            elif 'pagamento' in col_lower or 'payment' in col_lower:
                df.at[idx, col] = random.choice(FORMAS_PAGAMENTO)
                modificado = True
            
            # STATUS
            elif 'status' in col_lower:
                df.at[idx, col] = 'delivered'
                modificado = True
            
            # SCORES/RATINGS
            elif 'score' in col_lower or 'rating' in col_lower:
                df.at[idx, col] = random.randint(1, 5)
                modificado = True
            
            # MEDIDAS (weight, length, height, width)
            elif any(x in col_lower for x in ['weight', 'length', 'height', 
                                                'width', 'photos']):
                df.at[idx, col] = random.randint(10, 500)
                modificado = True
            
            # MÊS
            elif col_lower == 'mês':
                df.at[idx, col] = random.choice(['Janeiro', 'Fevereiro', 
                                                  'Março', 'Abril', 'Maio'])
                modificado = True
            
            # TEXTO GENÉRICO
            elif 'comment' in col_lower or 'message' in col_lower:
                df.at[idx, col] = 'Produto conforme descrito'
                modificado = True
            
            # OUTROS (número genérico)
            else:
                df.at[idx, col] = random.randint(1, 100)
                modificado = True
    
    if modificado:
        linhas_processadas += 1
    
    if (idx + 1) % 10000 == 0:
        print(f"   Processadas {idx + 1} linhas...")

print(f"   Total de linhas modificadas: {linhas_processadas}")

# Salvar arquivo
print(f"\n4. Salvando arquivo: {OUTPUT_FILE}")
df.to_csv(OUTPUT_FILE, index=False)

# Verificação final
print("\n5. Verificação final de nulls:")
nulls_restantes = 0
for col in df.columns:
    null_count = df[col].isna().sum() + (df[col] == 'null').sum()
    if null_count > 0:
        print(f"   {col}: {null_count} nulls restantes")
        nulls_restantes += null_count

print("\n" + "=" * 70)
if nulls_restantes == 0:
    print("✅ SUCESSO! Todos os valores null foram preenchidos!")
else:
    print(f"⚠️  {nulls_restantes} valores null restantes")

print(f"\nArquivo salvo: {OUTPUT_FILE}")
print(f"Total de linhas: {len(df)}")
print("\nPróximos passos:")
print("1. Upload para bucket staging:")
print(f"   aws s3 cp {OUTPUT_FILE} s3://SEU_BUCKET_STAGING/")
print("=" * 70)
