import json
import boto3
import os
from datetime import datetime


def lambda_handler(event, context):
    """
    Lambda function para ser triggado por upload de Excel no S3
    Esta versão inicial apenas detecta uploads e registra logs
    """
    
    # Configurações
    s3_client = boto3.client('s3')
    
    try:
        # Informações do evento S3
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        object_key = event['Records'][0]['s3']['object']['key']
        event_name = event['Records'][0]['eventName']
        
        print(f"Evento detectado: {event_name}")
        print(f"Bucket: {bucket_name}")
        print(f"Arquivo: {object_key}")
        
        # Verificar se é um arquivo Excel
        if not object_key.endswith('.xlsx'):
            return {
                'statusCode': 200,
                'body': json.dumps('Arquivo não é Excel, ignorando')
            }
        
        # Listar todos os arquivos Excel na pasta datasets/
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix='datasets/',
        )
        
        excel_files = []
        if 'Contents' in response:
            excel_files = [
                obj['Key'] for obj in response['Contents']
                if obj['Key'].endswith('.xlsx') and 
                'tabelao_tratado' not in obj['Key']
            ]
        
        print(f"Arquivos Excel encontrados na pasta datasets/: {excel_files}")
        
        # Criar um relatório simples em JSON
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        report = {
            "timestamp": timestamp,
            "trigger_file": object_key,
            "total_excel_files": len(excel_files),
            "excel_files_list": excel_files,
            "status": "detected",
            "message": "Excel files detected - ready for processing"
        }
        
        # Salvar relatório no S3
        report_key = f'outputs/processing_report_{timestamp}.json'
        s3_client.put_object(
            Bucket=bucket_name,
            Key=report_key,
            Body=json.dumps(report, indent=2),
            ContentType='application/json'
        )
        
        print(f"Relatório salvo em: s3://{bucket_name}/{report_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Arquivos Excel detectados com sucesso!',
                'total_files': len(excel_files),
                'report_location': f's3://{bucket_name}/{report_key}',
                'files_found': excel_files
            })
        }
        
    except Exception as e:
        print(f"Erro: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Erro ao processar evento S3'
            })
        }