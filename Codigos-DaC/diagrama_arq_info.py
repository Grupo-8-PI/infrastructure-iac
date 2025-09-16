from diagrams import Diagram, Cluster
from diagrams.custom import Custom

with Diagram("Arquitetura da Informação", show=False, direction="TB"):

    with Cluster("VERSÃO COM INTEGRAÇÃO"):
        entrada_com = Custom("Entrada no website Aej", "./icons/web.png")
        login_com = Custom("Login/Cadastro", "./icons/login.png")
        menu_com = Custom("MENU", "./icons/menu.png")
        navegacao_normal = Custom("Navegação normal", "./icons/flow.png")
        botao_aejhub = Custom("Clicou no botão para AejHub", "./icons/flow.png")

        entrada_com >> login_com >> menu_com
        login_com >> navegacao_normal
        login_com >> botao_aejhub >> menu_com

    with Cluster("VERSÃO SEM INTEGRAÇÃO"):
        entrada_sem = Custom("Entrada no website Aejhub", "./icons/web.png")
        login_sem = Custom("Login/Cadastro", "./icons/login.png")
        menu_sem = Custom("MENU", "./icons/menu.png")

        entrada_sem >> login_sem >> menu_sem

    with Cluster("TELA PERSONA (JOSÉ)"):
        catalogo_jose = Custom("Catálogo", "./icons/catalog.png")
        pesquisa = Custom("Pesquisa", "./icons/search.png")
        reservar = Custom("Reservar", "./icons/book.png")
        user_area = Custom("Área do usuário", "./icons/user.png")
        carrinho = Custom("Meu Carrinho", "./icons/cart.png")
        finalizar = Custom("Finalizar reservas", "./icons/finish.png")
        verificar = Custom("Verificar reservas", "./icons/check.png")
        modificar = Custom("Modificar reservas", "./icons/edit.png")
        add_prod = Custom("Adicionar produto", "./icons/add.png")
        rem_prod = Custom("Remover produto", "./icons/remove.png")

        pesquisa >> catalogo_jose
        catalogo_jose >> reservar
        catalogo_jose >> user_area
        catalogo_jose >> carrinho
        catalogo_jose >> verificar

        user_area >> carrinho
        user_area >> verificar
        user_area >> modificar

        carrinho >> add_prod
        carrinho >> rem_prod
        carrinho >> finalizar

    with Cluster("TELA PERSONA ADM (ANA LÚCIA)"):
        catalogo_ana = Custom("Catálogo", "./icons/catalog.png")
        atualizar = Custom("Atualizar status do livro", "./icons/update.png")
        add_livro = Custom("Adicionar livros (1 ou mais)", "./icons/addbook.png")
        gestao = Custom("Gestão", "./icons/manage.png")
        reservas_ana = Custom("Verificar reservas", "./icons/check.png")
        adm_ops = Custom("Modificar acessos de ADM", "./icons/admin.png")

        catalogo_ana >> atualizar
        catalogo_ana >> add_livro
        catalogo_ana >> reservas_ana
        catalogo_ana >> gestao
        gestao >> adm_ops
