"""
Script para preencher valores null usando dados REAIS do próprio CSV
Mantém consistência com os dados já existentes
"""

import pandas as pd
import random
import csv
from datetime import datetime, timedelta

# Configurações
INPUT_FILE = r"C:\Users\leode\Downloads\bases_tratados\bases_tratados\tabelao_tratado.csv"
OUTPUT_FILE = r"C:\Users\leode\Downloads\infrastructure-iac\Codigos-IaC\tabelao_tratado_completo_v2.csv"

print("=" * 70)
print("PREENCHIMENTO DE NULLS COM DADOS REAIS DO CSV")
print("=" * 70)

print(f"\n1. Lendo arquivo: {INPUT_FILE}")
df = pd.read_csv(INPUT_FILE, low_memory=False)
print(f"   Total de linhas: {len(df)}")
print(f"   Total de colunas: {len(df.columns)}")

# Identificar colunas que vamos usar (do ETL)
colunas_etl = [
    'order_purchase_timestamp',
    'product_category_name',
    'seller_city',
    'seller_state',
    'Quantidade',
    'Obra Vendida',
    'Valor Pago',
    'Forma de Pagamento '
]

print("\n2. Extraindo valores válidos para cada coluna...")

# Extrair valores REAIS não-nulos
valores_validos = {}

for col in colunas_etl:
    if col in df.columns:
        # Pegar valores não-nulos
        validos = df[col][
            (df[col].notna()) & 
            (df[col] != 'null') & 
            (df[col] != '')
        ].unique().tolist()
        
        if len(validos) > 0:
            valores_validos[col] = validos
            print(f"   {col}: {len(validos)} valores únicos válidos")
        else:
            valores_validos[col] = None
            print(f"   {col}: NENHUM valor válido encontrado")

# Criar mapeamento de cidades por estado
print("\n3. Criando mapeamento cidade-estado...")
cidade_estado_map = {}
for idx, row in df.iterrows():
    if (pd.notna(row.get('seller_state')) and 
        pd.notna(row.get('seller_city')) and
        row.get('seller_state') != 'null' and 
        row.get('seller_city') != 'null'):
        
        estado = str(row['seller_state']).strip()
        cidade = str(row['seller_city']).strip()
        
        if estado not in cidade_estado_map:
            cidade_estado_map[estado] = []
        if cidade not in cidade_estado_map[estado]:
            cidade_estado_map[estado].append(cidade)

print(f"   Estados encontrados: {len(cidade_estado_map)}")
for estado in list(cidade_estado_map.keys())[:5]:
    print(f"   {estado}: {len(cidade_estado_map[estado])} cidades")

# Função para gerar data baseada em datas reais
def gerar_data_real():
    """Gera data baseada no range de datas válidas do CSV"""
    if 'order_purchase_timestamp' in valores_validos and valores_validos['order_purchase_timestamp']:
        # Pegar uma data válida aleatória
        data_sample = random.choice(valores_validos['order_purchase_timestamp'])
        try:
            dt = pd.to_datetime(data_sample)
            # Adicionar variação de +/- 30 dias
            dias_variacao = random.randint(-30, 30)
            nova_data = dt + timedelta(days=dias_variacao)
            return nova_data.strftime('%Y-%m-%d %H:%M:%S')
        except:
            pass
    
    # Fallback: 2017-2018
    start = datetime(2017, 1, 1)
    days = random.randint(0, 729)
    dt = start + timedelta(days=days)
    return dt.strftime('%Y-%m-%d %H:%M:%S')

# Calcular dia da semana
DIAS_SEMANA = {
    0: 'SEGUNDA-FEIRA',
    1: 'TERCA-FEIRA',
    2: 'QUARTA-FEIRA',
    3: 'QUINTA-FEIRA',
    4: 'SEXTA-FEIRA',
    5: 'SABADO',
    6: 'DOMINGO'
}

print("\n4. Preenchendo valores null com dados reais...")
modificacoes = 0

for idx, row in df.iterrows():
    modificado = False
    
    # DATA/TIMESTAMP
    if 'order_purchase_timestamp' in df.columns:
        val = row['order_purchase_timestamp']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            nova_data = gerar_data_real()
            df.at[idx, 'order_purchase_timestamp'] = nova_data
            modificado = True
            
            # Atualizar Data e Dia da Semana também
            if 'Data' in df.columns:
                df.at[idx, 'Data'] = nova_data
            if 'Dia da Semana' in df.columns:
                dt = pd.to_datetime(nova_data)
                df.at[idx, 'Dia da Semana'] = DIAS_SEMANA[dt.weekday()]
    
    # DIA DA SEMANA
    if 'Dia da Semana' in df.columns:
        val = row['Dia da Semana']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            # Calcular do timestamp se disponível
            if pd.notna(row.get('order_purchase_timestamp')):
                try:
                    dt = pd.to_datetime(row['order_purchase_timestamp'])
                    df.at[idx, 'Dia da Semana'] = DIAS_SEMANA[dt.weekday()]
                    modificado = True
                except:
                    pass
    
    # CATEGORIA
    if 'product_category_name' in df.columns:
        val = row['product_category_name']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            if valores_validos.get('product_category_name'):
                df.at[idx, 'product_category_name'] = random.choice(
                    valores_validos['product_category_name']
                )
                modificado = True
    
    # SELLER STATE e CITY (manter consistência)
    if 'seller_state' in df.columns:
        estado = row.get('seller_state')
        cidade = row.get('seller_city')
        
        if pd.isna(estado) or str(estado).strip().lower() == 'null':
            # Escolher estado aleatório dos válidos
            if len(cidade_estado_map) > 0:
                novo_estado = random.choice(list(cidade_estado_map.keys()))
                nova_cidade = random.choice(cidade_estado_map[novo_estado])
                df.at[idx, 'seller_state'] = novo_estado
                df.at[idx, 'seller_city'] = nova_cidade
                modificado = True
        elif pd.isna(cidade) or str(cidade).strip().lower() == 'null':
            # Estado existe, preencher cidade compatível
            if estado in cidade_estado_map and len(cidade_estado_map[estado]) > 0:
                df.at[idx, 'seller_city'] = random.choice(
                    cidade_estado_map[estado]
                )
                modificado = True
    
    # QUANTIDADE
    if 'Quantidade' in df.columns:
        val = row['Quantidade']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            if valores_validos.get('Quantidade'):
                df.at[idx, 'Quantidade'] = random.choice(
                    valores_validos['Quantidade']
                )
            else:
                df.at[idx, 'Quantidade'] = 1.0
            modificado = True
    
    # OBRA VENDIDA
    if 'Obra Vendida' in df.columns:
        val = row['Obra Vendida']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            if valores_validos.get('Obra Vendida'):
                df.at[idx, 'Obra Vendida'] = random.choice(
                    valores_validos['Obra Vendida']
                )
                modificado = True
    
    # VALOR PAGO
    if 'Valor Pago' in df.columns:
        val = row['Valor Pago']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            if valores_validos.get('Valor Pago'):
                df.at[idx, 'Valor Pago'] = random.choice(
                    valores_validos['Valor Pago']
                )
                modificado = True
    
    # FORMA DE PAGAMENTO
    if 'Forma de Pagamento ' in df.columns:
        val = row['Forma de Pagamento ']
        if pd.isna(val) or str(val).strip().lower() == 'null':
            if valores_validos.get('Forma de Pagamento '):
                df.at[idx, 'Forma de Pagamento '] = random.choice(
                    valores_validos['Forma de Pagamento ']
                )
                modificado = True
    
    if modificado:
        modificacoes += 1
    
    if (idx + 1) % 10000 == 0:
        print(f"   Processadas {idx + 1} linhas...")

print(f"\n   Total de linhas modificadas: {modificacoes}")

# Salvar com encoding UTF-8 e quoting para lidar com quebras de linha
print(f"\n5. Salvando arquivo: {OUTPUT_FILE}")
df.to_csv(
    OUTPUT_FILE,
    index=False,
    encoding='utf-8-sig',
    quoting=csv.QUOTE_MINIMAL,
    line_terminator='\n'
)

# Verificação final
print("\n6. Verificação final...")
null_count = 0
for col in colunas_etl:
    if col in df.columns:
        nulls = (df[col].isna().sum() + (df[col] == 'null').sum())
        if nulls > 0:
            print(f"   {col}: {nulls} nulls restantes")
            null_count += nulls

print("\n" + "=" * 70)
if null_count == 0:
    print("✅ SUCESSO! Todos os valores das colunas ETL preenchidos!")
else:
    print(f"⚠️  {null_count} nulls restantes nas colunas ETL")

print(f"\nArquivo salvo: {OUTPUT_FILE}")
print(f"Total de linhas: {len(df)}")
print("=" * 70)
