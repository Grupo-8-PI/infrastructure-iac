import json
import boto3
import csv
import io
import os
from datetime import datetime

s3_client = boto3.client('s3')


def lambda_handler(event, context):
    """
    Lambda que processa arquivos CSV do bucket Trusted para Cured.
    Filtra apenas linhas onde product_category_name contém 'livro'.
    Preenche campos vazios com 'null'.
    """
    
    print("Evento recebido:", json.dumps(event))
    
    try:
        # Obter informações do arquivo do evento S3
        for record in event['Records']:
            bucket_name = record['s3']['bucket']['name']
            file_key = record['s3']['object']['key']
            
            print(f"Processando arquivo: s3://{bucket_name}/{file_key}")
            
            # Verificar se é CSV
            if not file_key.endswith('.csv'):
                print(f"Arquivo ignorado (não é CSV): {file_key}")
                continue
            
            # Baixar arquivo do S3
            response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
            file_content = response['Body'].read()
            
            # Processar CSV
            dados_processados, stats = processar_csv_livros(file_content)
            
            # Gerar nome do arquivo de saída
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            base_name = file_key.split('/')[-1].rsplit('.', 1)[0]
            base_name = base_name.replace('_trusted', '')
            output_key = f"cured/{base_name}_cured_{timestamp}.csv"
            
            # Obter bucket cured do ambiente
            cured_bucket = os.environ.get(
                'CURED_BUCKET',
                context.function_name.replace(
                    'trusted-to-cured',
                    'cured-bucket'
                )
            )
            
            # Upload para bucket Cured
            s3_client.put_object(
                Bucket=cured_bucket,
                Key=output_key,
                Body=dados_processados,
                ContentType='text/csv'
            )
            
            output_location = f"s3://{cured_bucket}/{output_key}"
            print(f"Arquivo processado salvo em: {output_location}")
            print(f"Estatísticas: {stats}")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Arquivo processado com sucesso',
                    'source': f's3://{bucket_name}/{file_key}',
                    'destination': output_location,
                    'statistics': stats
                })
            }
            
    except Exception as e:
        print(f"Erro ao processar arquivo: {str(e)}")
        raise e


def processar_csv_livros(file_content):
    """
    Processa arquivo CSV mantendo apenas linhas com 'livro'
    em product_category_name.
    Preenche campos vazios com 'null'.
    """
    
    # Ler CSV
    csv_data = file_content.decode('utf-8')
    csv_reader = csv.DictReader(io.StringIO(csv_data))
    
    fieldnames = csv_reader.fieldnames
    print(f"Colunas do arquivo: {fieldnames}")
    
    # Criar CSV de saída
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=fieldnames)
    writer.writeheader()
    
    linhas_total = 0
    linhas_livros = 0
    linhas_descartadas = 0
    
    for row in csv_reader:
        linhas_total += 1
        
        # Verificar se é livro
        category = row.get('product_category_name', '').lower().strip()
        
        # Aceitar se contém 'livro' ou variações
        eh_livro = (
            'livro' in category or
            'book' in category or
            'literatura' in category
        )
        
        if eh_livro:
            # Preencher campos vazios com null
            nova_linha = {}
            for coluna in fieldnames:
                valor = row.get(coluna, '').strip()
                nova_linha[coluna] = valor if valor else 'null'
            
            writer.writerow(nova_linha)
            linhas_livros += 1
        else:
            linhas_descartadas += 1
    
    stats = {
        'total_linhas': linhas_total,
        'linhas_livros': linhas_livros,
        'linhas_descartadas': linhas_descartadas,
        'percentual_livros': round(
            (linhas_livros / linhas_total * 100)
            if linhas_total > 0 else 0,
            2
        )
    }
    
    print(f"Processamento concluído: {stats}")
    
    return output.getvalue().encode('utf-8'), stats
