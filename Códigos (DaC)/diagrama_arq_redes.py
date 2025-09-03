from diagrams import Diagram, Cluster
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, InternetGateway, RouteTable
from diagrams.aws.compute import EC2
from diagrams.onprem.network import Internet

with Diagram("AWS Network Architecture", show=False, direction="LR"):

    internet = Internet("Internet")

    igw = InternetGateway("Internet Gateway\n192.168.1.1")
    router = RouteTable("Router")

    with Cluster("Amazon Cloud"):
        with Cluster("Virtual Private Cloud\n192.168.1.10"):

            with Cluster("Public Subnet\n192.168.1.10"):
                ec2_public = EC2("Instance\nSecurity Group")

            with Cluster("Private Subnet\n192.168.1.20"):
                ec2_private1 = EC2("Instance\nSecurity Group")

            with Cluster("Private Subnet\n192.168.1.21"):
                ec2_private2 = EC2("Instance\nSecurity Group")

            with Cluster("Private Subnet\n192.168.1.22"):
                ec2_private3 = EC2("Instance\nSecurity Group")

    internet >> igw >> router
    router >> ec2_public
    router >> ec2_private1
    router >> ec2_private2
    router >> ec2_private3
