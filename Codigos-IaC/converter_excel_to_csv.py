import pandas as pd
import sys
import os

# Arquivos de entrada e saída
input_file = r"C:\Users\leode\Downloads\bases_tratados" \
             r"\bases_tratados\tabelao_tratado.xlsx"
output_file = r"C:\Users\leode\Downloads\bases_tratados" \
              r"\bases_tratados\tabelao_tratado.csv"

try:
    print(f"Lendo arquivo Excel: {input_file}")
    
    # Verificar se arquivo existe
    if not os.path.exists(input_file):
        print(f"Erro: Arquivo não encontrado!")
        sys.exit(1)
    
    df = pd.read_excel(input_file)
    
    print(f"Dimensões do arquivo: {df.shape}")
    print(f"\nPrimeiras 10 colunas:")
    for i, col in enumerate(list(df.columns)[:10], 1):
        print(f"  {i}. {col}")
    
    if len(df.columns) > 10:
        print(f"  ... e mais {len(df.columns) - 10} colunas")
    
    # Salvar como CSV
    print(f"\nConvertendo para CSV: {output_file}")
    df.to_csv(output_file, index=False, encoding='utf-8-sig')
    
    print(f"\n✓ Arquivo CSV criado com sucesso!")
    print(f"  Total de linhas: {len(df)}")
    print(f"  Total de colunas: {len(df.columns)}")
    print(f"  Tamanho: {os.path.getsize(output_file):,} bytes")
    
except Exception as e:
    print(f"\n✗ Erro: {e}")
    sys.exit(1)
