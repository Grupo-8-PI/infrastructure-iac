from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, ELB, InternetGateway, RouteTable
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS
from diagrams.aws.storage import S3

with Diagram("AWS VPC Architecture", show=False, direction="TB"):

    client = "Cliente"

    igw = InternetGateway("Internet Gateway")
    elb = ELB("Amazon ELB")
    rt = RouteTable("Router Tables")

    with Cluster("Amazon Cloud"):
        with Cluster("Virtual Private Cloud (10.0.0.0/16)"):
            
            with Cluster("Public Subnet (10.0.1.0/24)"):
                ec2_pub1 = EC2("Instance 1")
                ec2_pub2 = EC2("Instance 2")

            with Cluster("Private Subnet (10.0.2.0/24)"):
                ec2_priv1 = EC2("Instance 1")
                ec2_priv2 = EC2("Instance 2")
                rds = RDS("Database")

            s3 = [S3("Bucket1"), S3("Bucket2"), S3("Bucket3")]

    # Conexões
    client >> igw >> elb >> rt
    rt >> ec2_pub1
    rt >> ec2_pub2
    rt >> ec2_priv1
    rt >> ec2_priv2

    ec2_priv1 >> rds
    ec2_priv2 >> rds

    rds >> s3
