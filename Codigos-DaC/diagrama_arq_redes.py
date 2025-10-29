from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import InternetGateway, RouteTable
from diagrams.aws.compute import EC2, ECS
from diagrams.onprem.network import Internet
from diagrams.onprem.analytics import Metabase as Grafana

with Diagram("Arquitetura de Redes AWS - VPC", show=False,
             direction="TB", filename="diagrama_arq_redes"):

    internet = Internet("Internet\n0.0.0.0/0")
    
    igw = InternetGateway("Internet Gateway\nigw_aej")
    
    with Cluster("AWS Cloud - us-east-1"):
        with Cluster("VPC (10.0.0.0/24)"):
            
            route_pub = RouteTable("Route Table Pública\n0.0.0.0/0 → IGW")
            route_priv = RouteTable("Route Table Privada\nLocal only")
            
            with Cluster("Subnet Pública (10.0.0.0/25)\nAZ: us-east-1b"):
                sg_pub = EC2("SG: sg_publica\nSSH: 22")
                sg_http = EC2("SG: sg_publica_http\nHTTP: 80")
                
                ec2_pub_a = EC2("EC2 Pública A\n10.0.0.X")
                ec2_pub_b = EC2("EC2 Pública B\n10.0.0.Y")
                
                sg_grafana = ECS("SG: sg_grafana\nHTTP: 3000")
                ecs_grafana = Grafana("ECS Fargate\nGrafana\n10.0.0.Z")
            
            with Cluster("Subnet Privada (10.0.0.128/25)\nAZ: us-east-1c"):
                sg_priv = EC2("SG: sg_privada\nSSH: 22")
                ec2_priv = EC2("EC2 Privada\n10.0.0.130")
    
    # Fluxo de rede
    internet >> Edge(label="HTTP/SSH") >> igw
    igw >> Edge(label="Public Traffic") >> route_pub
    
    route_pub >> Edge(label="SSH:22") >> sg_pub
    sg_pub >> ec2_pub_a
    sg_pub >> ec2_pub_b
    
    route_pub >> Edge(label="HTTP:80") >> sg_http
    sg_http >> ec2_pub_a
    sg_http >> ec2_pub_b
    
    route_pub >> Edge(label="HTTP:3000") >> sg_grafana
    sg_grafana >> ecs_grafana
    
    route_priv >> Edge(label="SSH:22") >> sg_priv
    sg_priv >> ec2_priv

