from diagrams import Diagram, Cluster
from diagrams.onprem.database import MySQL
from diagrams.onprem.client import Users
from diagrams.onprem.compute import Server
from diagrams.saas.chat import Chatgpt
from diagrams.programming.framework import React
from diagrams.custom import Custom

with Diagram("Arquitetura SW", show=False, direction="LR"):

    user = Users("Usuário")

    with Cluster("Sistema"):
        db = MySQL("DATABASE\n[Container: MYSQL]\nArmazena os dados")
        micro = Server("MICROSERVICE\n[Container: SpringBoot]\nRegistra e valida cadastro")
        web = React("CLIENT SIDE WEB\n[Container: React]\nTela cadastro/login")

        # conexões internas
        micro >> db
        web >> micro

    # APIs externas
    isbn = Custom("ISBN - Application\n[Container: ISBN API]", "./isbn_icon.png")
    gpt = Chatgpt("GPT3.5 - Application\n[Container: GPT3.5 API]")

    # conexões externas
    isbn >> micro
    gpt >> micro
    user >> web
