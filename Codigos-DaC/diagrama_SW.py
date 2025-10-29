from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Lambda, ECS
from diagrams.aws.storage import S3
from diagrams.aws.analytics import Glue, Athena
from diagrams.programming.language import Python
from diagrams.onprem.analytics import Metabase as Grafana
from diagrams.onprem.client import Users

with Diagram("Arquitetura de Software - Pipeline ETL Analytics",
             show=False, direction="TB",
             filename="diagrama_SW"):

    users = Users("Analistas\nBiblioteca Nacional")

    with Cluster("Storage Layer - S3"):
        s3_staging = S3("Staging\nCSV Bruto")
        s3_trusted = S3("Trusted\nDados Filtrados")
        s3_cured = S3("Cured\nSó Livros")
        s3_athena = S3("Athena Results\nQuery Cache")
    
    with Cluster("Processing Layer - Lambda Functions"):
        with Cluster("staging_to_trusted_lambda.py"):
            lambda_1 = Lambda("Lambda 1\nPython 3.9")
            code_1 = Python("csv.DictReader\ncsv.QUOTE_MINIMAL\nCalcula dia_da_semana")
        
        with Cluster("trusted_to_cured_lambda.py"):
            lambda_2 = Lambda("Lambda 2\nPython 3.9")
            code_2 = Python("Filtra product_category_name\ncontains 'livro'")
    
    with Cluster("Data Catalog Layer - AWS Glue"):
        glue_db = Glue("Glue Database\nlivros_analytics_db")
        glue_schema = Glue("Table Schema\n9 colunas:\nData, Dia da Semana,\nproduct_category_name,\nseller_city, seller_state,\nQuantidade, Obra Vendida,\nValor Pago, Forma de Pagamento")
    
    with Cluster("Query Layer - Amazon Athena"):
        athena_engine = Athena("Athena Engine\nPresto SQL")
        athena_serde = Athena("OpenCSVSerde\nquoteChar='\"'\nescapeChar='\\\\'")
    
    with Cluster("Visualization Layer - Grafana"):
        grafana_container = ECS("ECS Fargate\nGrafana Container")
        grafana_app = Grafana("Grafana v10+\nAthena Plugin\nPort 3000")
        
        with Cluster("Dashboard Components"):
            queries = Python("grafana_queries.sql\n5 Queries + 3 KPIs")
            kpis = Grafana("KPIs: Obras, Crescimento,\nCategoria")
            charts = Grafana("Charts: Top Livros,\nSazonalidade,\nDia da Semana,\nEvolução")
    
    # Fluxo de software
    users >> Edge(label="Upload CSV") >> s3_staging
    
    s3_staging >> Edge(label="S3 Event\nTrigger") >> lambda_1
    lambda_1 >> code_1
    code_1 >> Edge(label="Write CSV\nQUOTE_MINIMAL") >> s3_trusted
    
    s3_trusted >> Edge(label="S3 Event\nTrigger") >> lambda_2
    lambda_2 >> code_2
    code_2 >> Edge(label="Write CSV\nFiltered") >> s3_cured
    
    s3_cured >> Edge(label="External\nTable") >> glue_schema
    glue_schema >> glue_db
    
    glue_db >> Edge(label="Catalog\nMetadata") >> athena_engine
    athena_engine >> athena_serde
    athena_serde >> Edge(label="Parse CSV\nwith quotes") >> athena_engine
    
    athena_engine >> Edge(label="Store\nResults") >> s3_athena
    
    grafana_container >> grafana_app
    grafana_app >> queries
    queries >> Edge(label="Execute\nSQL") >> athena_engine
    athena_engine >> Edge(label="Return\nData") >> queries
    
    queries >> kpis
    queries >> charts
    
    users >> Edge(label="Access\nDashboard") >> grafana_app

