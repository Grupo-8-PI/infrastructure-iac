import json
import boto3
import csv
import io
import os
from datetime import datetime

s3_client = boto3.client('s3')

# Colunas que queremos manter
COLUNAS_DESEJADAS = [
    'order_purchase_timestamp',  # Data e hora da compra
    'product_category_name',
    'seller_city',
    'seller_state',
    'quantidade',
    'obra vendida',
    'valor pago',
    'forma de pagamento'
]


def normalizar_coluna(col):
    """Normaliza nomes de colunas para comparação"""
    return col.strip().lower()


def calcular_dia_semana(timestamp_str):
    """Calcula o dia da semana a partir de um timestamp"""
    try:
        # Parse timestamp (formato: 2018-04-04 08:39:50)
        data = datetime.strptime(timestamp_str.split()[0], '%Y-%m-%d')
        dias_semana = {
            0: 'SEGUNDA-FEIRA',
            1: 'TERCA-FEIRA',
            2: 'QUARTA-FEIRA',
            3: 'QUINTA-FEIRA',
            4: 'SEXTA-FEIRA',
            5: 'SABADO',
            6: 'DOMINGO'
        }
        return dias_semana[data.weekday()]
    except Exception as e:
        print(f"Erro ao calcular dia da semana: {e}")
        return 'null'


def lambda_handler(event, context):
    """
    Lambda que processa arquivos CSV/Excel do bucket Staging para Trusted.
    Filtra apenas as colunas especificadas e preenche vazios com null.
    """
    
    print("Evento recebido:", json.dumps(event))
    
    try:
        # Obter informações do arquivo do evento S3
        for record in event['Records']:
            bucket_name = record['s3']['bucket']['name']
            file_key = record['s3']['object']['key']
            
            print(f"Processando arquivo: s3://{bucket_name}/{file_key}")
            
            # Verificar se é CSV ou Excel
            if not (file_key.endswith('.csv') or file_key.endswith('.xlsx')):
                print(f"Arquivo ignorado (não é CSV nem XLSX): {file_key}")
                continue
            
            # Baixar arquivo do S3
            response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
            file_content = response['Body'].read()
            
            # Processar baseado no tipo de arquivo
            if file_key.endswith('.csv'):
                dados_processados = processar_csv(file_content)
            elif file_key.endswith('.xlsx'):
                dados_processados = processar_excel(file_content)
            
            # Gerar nome do arquivo de saída
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            base_name = file_key.split('/')[-1].rsplit('.', 1)[0]
            output_key = f"trusted/{base_name}_trusted_{timestamp}.csv"
            
            # Obter bucket trusted do ambiente
            trusted_bucket = os.environ.get(
                'TRUSTED_BUCKET',
                context.function_name.replace(
                    'staging-to-trusted',
                    'trusted-bucket'
                )
            )
            
            # Upload para bucket Trusted
            s3_client.put_object(
                Bucket=trusted_bucket,
                Key=output_key,
                Body=dados_processados,
                ContentType='text/csv'
            )
            
            output_location = f"s3://{trusted_bucket}/{output_key}"
            print(f"Arquivo processado salvo em: {output_location}")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Arquivo processado com sucesso',
                    'source': f's3://{bucket_name}/{file_key}',
                    'destination': f's3://{trusted_bucket}/{output_key}',
                    'colunas_mantidas': COLUNAS_DESEJADAS
                })
            }
            
    except Exception as e:
        print(f"Erro ao processar arquivo: {str(e)}")
        raise e


def processar_csv(file_content):
    """Processa arquivo CSV e retorna apenas colunas desejadas"""
    
    # Ler CSV removendo BOM (Byte Order Mark) se existir
    # utf-8-sig remove BOM automaticamente
    csv_data = file_content.decode('utf-8-sig')
    csv_reader = csv.DictReader(io.StringIO(csv_data))
    
    # Mapear colunas originais para colunas normalizadas
    fieldnames_originais = csv_reader.fieldnames
    mapeamento = {}
    
    # Criar mapeamento case-insensitive
    for col_original in fieldnames_originais:
        col_normalizada = normalizar_coluna(col_original)
        for col_desejada in COLUNAS_DESEJADAS:
            if normalizar_coluna(col_desejada) == col_normalizada:
                # Usar o nome ORIGINAL da coluna mas SEM espaços extras
                nome_limpo = col_original.strip()
                # Renomear order_purchase_timestamp para Data
                if nome_limpo == 'order_purchase_timestamp':
                    nome_limpo = 'Data'
                mapeamento[col_original] = nome_limpo
                break
    
    print(f"Colunas encontradas: {list(mapeamento.keys())}")
    print(f"Total de colunas no arquivo: {len(fieldnames_originais)}")
    print(f"Colunas mantidas: {len(mapeamento)}")
    
    # Criar CSV de saída com nomes limpos das colunas + Dia da Semana
    output = io.StringIO()
    colunas_saida = ['Data', 'Dia da Semana'] + [
        col for col in mapeamento.values()
        if col != 'Data'
    ]
    writer = csv.DictWriter(output, fieldnames=colunas_saida)
    writer.writeheader()
    
    linhas_processadas = 0
    for row in csv_reader:
        nova_linha = {}
        
        # Processar colunas normais
        for col_original, col_saida in mapeamento.items():
            valor = row.get(col_original, '').strip()
            # Se vazio, colocar null
            nova_linha[col_saida] = valor if valor else 'null'
        
        # Calcular Dia da Semana baseado na Data
        if 'Data' in nova_linha and nova_linha['Data'] != 'null':
            nova_linha['Dia da Semana'] = calcular_dia_semana(
                nova_linha['Data']
            )
        else:
            nova_linha['Dia da Semana'] = 'null'
        
        writer.writerow(nova_linha)
        linhas_processadas += 1
    
    print(f"Total de linhas processadas: {linhas_processadas}")
    
    return output.getvalue().encode('utf-8')


def processar_excel(file_content):
    """
    Para arquivos Excel, retorna instruções para converter para CSV.
    Excel requer pandas/openpyxl que não estão instalados no Lambda.
    """
    print("=" * 60)
    print("ARQUIVO EXCEL DETECTADO")
    print("=" * 60)
    print("INSTRUÇÕES:")
    print("1. Converta o arquivo Excel para CSV antes de enviar")
    print("2. Ou instale um Lambda Layer com pandas + openpyxl")
    print()
    print("COMANDO PARA CONVERTER (local):")
    print("  python -c \"import pandas as pd; "
          "pd.read_excel('arquivo.xlsx').to_csv('arquivo.csv', "
          "index=False)\"")
    print("=" * 60)
    
    # Criar CSV com instruções
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUNAS_DESEJADAS)
    writer.writeheader()
    
    # Adicionar linha explicativa
    instrucao = {
        col: 'CONVERTA PARA CSV - Excel requer pandas layer'
        for col in COLUNAS_DESEJADAS
    }
    writer.writerow(instrucao)
    
    return output.getvalue().encode('utf-8')
