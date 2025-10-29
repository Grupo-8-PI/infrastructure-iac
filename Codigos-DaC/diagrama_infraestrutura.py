from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import  InternetGateway, RouteTable
from diagrams.aws.compute import EC2, ECS, Lambda
from diagrams.aws.analytics import Glue, GlueCrawlers, Athena
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.client import Users
from diagrams.onprem.analytics import Metabase as Grafana

with Diagram("Arquitetura AWS - Pipeline ETL Analytics de Livros",
             show=False, direction="LR",
             filename="diagrama_infraestrutura"):

    users = Users("Usuários")

    with Cluster("AWS Cloud - us-east-1"):
        igw = InternetGateway("Internet Gateway")
        
        with Cluster("VPC 10.0.0.0/24"):
            
            with Cluster("Subnet Pública (10.0.0.0/25)"):
                route_pub = RouteTable("Route Table Pública")
                
                ec2_pub_a = EC2("EC2 Pública A\n(SSH + HTTP)")
                ec2_pub_b = EC2("EC2 Pública B\n(SSH + HTTP)")
                
                with Cluster("ECS Fargate - Grafana"):
                    ecs_cluster = ECS("Cluster Grafana")
                    grafana = Grafana("Grafana:3000\nCredentials: admin/aej2025grafana")
                    logs_grafana = Cloudwatch("CloudWatch Logs")
            
            with Cluster("Subnet Privada (10.0.0.128/25)"):
                ec2_priv = EC2("EC2 Privada\n(SSH)")
        
        with Cluster("Pipeline ETL - 3 Camadas"):
            with Cluster("Camada Staging"):
                s3_staging = S3("S3 Staging Bucket\n(Dados Brutos)")
            
            with Cluster("Camada Trusted"):
                lambda_staging = Lambda("Lambda Staging→Trusted\n(9 colunas + dia da semana)")
                s3_trusted = S3("S3 Trusted Bucket\n(Dados Filtrados)")
                logs_staging = Cloudwatch("CloudWatch Logs")
            
            with Cluster("Camada Cured"):
                lambda_trusted = Lambda("Lambda Trusted→Cured\n(Filtra apenas livros)")
                s3_cured = S3("S3 Cured Bucket\n(Só Livros)")
                logs_trusted = Cloudwatch("CloudWatch Logs")
        
        with Cluster("Analytics Layer"):
            glue_db = Glue("Glue Database\nlivros_analytics_db")
            glue_table = GlueCrawlers("Glue Table\nvendas_livros")
            athena = Athena("Athena Workgroup\nlivros_analytics_workgroup")
            s3_athena = S3("S3 Athena Results\n(Query Results)")
        
        s3_public = S3("S3 Public Website\n(Static Hosting)")
    
    # Fluxo de dados
    users >> Edge(label="HTTP/SSH") >> igw
    igw >> route_pub
    route_pub >> Edge(label="SSH:22") >> ec2_pub_a
    route_pub >> Edge(label="SSH:22") >> ec2_pub_b
    route_pub >> Edge(label="HTTP:3000") >> ecs_cluster
    ecs_cluster >> grafana
    grafana >> logs_grafana
    
    # Pipeline ETL
    s3_staging >> Edge(label="S3 Event Trigger") >> lambda_staging
    lambda_staging >> Edge(label="Transform & Load") >> s3_trusted
    lambda_staging >> logs_staging
    
    s3_trusted >> Edge(label="S3 Event Trigger") >> lambda_trusted
    lambda_trusted >> Edge(label="Filter Books") >> s3_cured
    lambda_trusted >> logs_trusted
    
    # Analytics
    s3_cured >> Edge(label="External Table") >> glue_table
    glue_table >> glue_db
    glue_db >> Edge(label="Query Data") >> athena
    athena >> Edge(label="Store Results") >> s3_athena
    
    # Grafana lê do Athena
    grafana >> Edge(label="Athena Plugin\nSQL Queries") >> athena
    
    # Public website
    users >> Edge(label="HTTP") >> s3_public

