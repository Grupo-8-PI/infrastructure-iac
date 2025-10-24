
def lambda_handler(event, context):
    return f"Uma coisa é certa: {event.get('body', '')}"

    import pandas as pd
    from pathlib import Path

    # Caminho da pasta com os datasets
    datasets_folder = r"C:\Users\leode\Downloads\bases_tratados\bases_tratados"

    # Caminho de saída
    output_path = r"C:\Users\leode\Downloads\bases_tratados\tabelao_tratado.xlsx"

    try:
        # Buscar todos os arquivos Excel na pasta (exceto o arquivo de saída)
        print("Buscando arquivos Excel na pasta...")
        excel_files = []

        for file in Path(datasets_folder).glob("*.xlsx"):
            if file.name != "tabelao_tratado.xlsx":
                excel_files.append(file)

        print(f"Arquivos encontrados: {[f.name for f in excel_files]}")

        if not excel_files:
            print("Nenhum arquivo Excel encontrado na pasta!")
            exit()

        # Carregar todos os datasets
        dataframes = []
        print("\nCarregando datasets...")

        for file_path in excel_files:
            print(f"Carregando: {file_path.name}")
            df = pd.read_excel(file_path)
            print(f"  - Dimensões: {df.shape}")
            dataframes.append(df)

            # Encontrar o maior número de linhas
        max_rows = max(len(df) for df in dataframes)
        print(f"\nMaior número de linhas: {max_rows}")

        # Redimensionar todos os dataframes para ter o mesmo número de linhas
        print("Padronizando número de linhas...")
        dataframes_resized = []
        for df in dataframes:
            df_resized = df.reindex(range(max_rows))
            dataframes_resized.append(df_resized)

        # Concatenar horizontalmente
        print("Concatenando datasets...")
        tabelao = pd.concat(dataframes_resized, axis=1)

        # Salvar o tabelão
        print("Salvando tabelão...")
        tabelao.to_excel(output_path, index=False)

        print("\nTabelão criado com sucesso!")
        print(f"Dimensões finais: {tabelao.shape}")
        print(f"Arquivo salvo em: {output_path}")

    except Exception as e:
        print(f"Erro: {e}")
