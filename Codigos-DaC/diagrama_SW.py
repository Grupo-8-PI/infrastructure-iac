from diagrams import Diagram, Cluster
from diagrams.onprem.database import MySQL
from diagrams.onprem.client import Users
from diagrams.onprem.compute import Server
from diagrams.programming.framework import React
from diagrams.custom import Custom

with Diagram("Arquitetura SW", show=False, direction="LR"):

    user = Users("Usuário")

    with Cluster("Sistema"):
        db = MySQL("DATABASE\n[Container: MYSQL]\nArmazena os dados")
        micro = Server("MICROSERVICE\n[Container: SpringBoot]\nRegistra e valida cadastro")
        web = React("CLIENT SIDE WEB\n[Container: React]\nTela cadastro/login")

        micro >> db
        web >> micro

    isbn = Custom("ISBN - Application\n[Container: ISBN API]", "./isbn_icon.png")
    gpt = Custom("GPT3.5 - Application\n[Container: GPT3.5 API]", "./chatgpt_icon.png")

    isbn >> micro
    gpt >> micro
    user >> web
