from diagrams import Diagram, Cluster, Edge
from diagrams.aws.storage import S3
from diagrams.aws.compute import Lambda
from diagrams.aws.analytics import Glue, Athena
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.analytics import Metabase as Grafana
from diagrams.onprem.client import Users

with Diagram("Arquitetura da Informação - Pipeline ETL Analytics",
             show=False, direction="LR",
             filename="diagrama_arq_info"):

    users = Users("Analistas\nBiblioteca Nacional")
    
    with Cluster("Camada de Ingestão - Dados Brutos"):
        raw_data = S3("S3 Staging Bucket\nDados CSV Brutos\n(99.441 linhas)")
    
    with Cluster("Camada de Transformação - ETL Pipeline"):
        with Cluster("Staging → Trusted"):
            lambda_1 = Lambda("Lambda ETL 1\nFiltra 9 colunas\nCalcula dia da semana")
            trusted = S3("S3 Trusted Bucket\nDados Filtrados")
            logs_1 = Cloudwatch("CloudWatch Logs\nMonitora execução")
        
        with Cluster("Trusted → Cured"):
            lambda_2 = Lambda("Lambda ETL 2\nFiltra apenas livros\nFormata valores")
            cured = S3("S3 Cured Bucket\nSó Livros\n(~3.139 linhas)")
            logs_2 = Cloudwatch("CloudWatch Logs\nMonitora execução")
    
    with Cluster("Camada de Análise - Data Catalog"):
        glue_db = Glue("Glue Database\nlivros_analytics_db")
        glue_table = Glue("Glue Table\nvendas_livros\n(9 colunas)")
        athena = Athena("Athena\nSQL Queries\nAgregações")
        results = S3("S3 Athena Results\nQuery Results")
    
    with Cluster("Camada de Visualização"):
        grafana = Grafana("Grafana Dashboard\nhttp://IP:3000\nCredentials: admin/aej2025grafana")
        
        with Cluster("KPIs e Métricas"):
            kpi_obras = Grafana("230 Obras Únicas")
            kpi_crescimento = Grafana("60.1% Crescimento")
            kpi_categoria = Grafana("Top Categoria")
        
        with Cluster("Análises"):
            top_livros_qtd = Grafana("Top 5 Livros\n(Quantidade)")
            top_livros_receita = Grafana("Top 10 Livros\n(Receita)")
            sazonalidade = Grafana("Receita Mensal\n(2017-2018)")
            dia_semana = Grafana("Receita por\nDia da Semana")
            evolucao = Grafana("Evolução Semanal\n(Múltiplas métricas)")
    
    # Fluxo de dados
    users >> Edge(label="Upload CSV") >> raw_data
    raw_data >> Edge(label="S3 Trigger") >> lambda_1
    lambda_1 >> trusted
    lambda_1 >> logs_1
    
    trusted >> Edge(label="S3 Trigger") >> lambda_2
    lambda_2 >> cured
    lambda_2 >> logs_2
    
    cured >> Edge(label="External Table") >> glue_table
    glue_table >> glue_db
    glue_db >> Edge(label="Query") >> athena
    athena >> Edge(label="Store") >> results
    
    athena >> Edge(label="Athena Plugin\nSQL Queries") >> grafana
    grafana >> kpi_obras
    grafana >> kpi_crescimento
    grafana >> kpi_categoria
    grafana >> top_livros_qtd
    grafana >> top_livros_receita
    grafana >> sazonalidade
    grafana >> dia_semana
    grafana >> evolucao
    
    users >> Edge(label="Visualiza\nDashboards") >> grafana

