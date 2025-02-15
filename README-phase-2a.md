IMPORTANT ❗ ❗ ❗ Please remember to destroy all the resources after each work session. You can recreate infrastructure by creating new PR and merging it to master.

![img.png](doc/figures/destroy.png)

0. The goal of this phase is to create infrastructure, perform benchmarking/scalability tests of sample three-tier lakehouse solution and analyze the results using:
* [TPC-DI benchmark](https://www.tpc.org/tpcdi/)
* [dbt - data transformation tool](https://www.getdbt.com/)
* [GCP Composer - managed Apache Airflow](https://cloud.google.com/composer?hl=pl)
* [GCP Dataproc - managed Apache Spark](https://spark.apache.org/)
* [GCP Vertex AI Workbench - managed JupyterLab](https://cloud.google.com/vertex-ai-notebooks?hl=pl)

Worth to read:
* https://docs.getdbt.com/docs/introduction
* https://airflow.apache.org/docs/apache-airflow/stable/index.html
* https://spark.apache.org/docs/latest/api/python/index.html
* https://medium.com/snowflake/loading-the-tpc-di-benchmark-dataset-into-snowflake-96011e2c26cf
* https://www.databricks.com/blog/2023/04/14/how-we-performed-etl-one-billion-records-under-1-delta-live-tables.html

2. Authors:

   group 4

   https://github.com/dandon223/tbd-2023z-phase1

3. Replace your `main.tf` (in the root module) from the phase 1 with [main.tf](https://github.com/bdg-tbd/tbd-workshop-1/blob/v1.0.36/main.tf)
and change each module `source` reference from the repo relative path to a github repo tag `v1.0.36` , e.g.:
```hcl
module "dbt_docker_image" {
  depends_on = [module.composer]
  source             = "github.com/bdg-tbd/tbd-workshop-1.git?ref=v1.0.36/modules/dbt_docker_image"
  registry_hostname  = module.gcr.registry_hostname
  registry_repo_name = coalesce(var.project_name)
  project_name       = var.project_name
  spark_version      = local.spark_version
}
```


4. Provision your infrastructure.

    a) setup Vertex AI Workbench `pyspark` kernel as described in point [8](https://github.com/bdg-tbd/tbd-workshop-1/tree/v1.0.32#project-setup) 

    b) upload [tpc-di-setup.ipynb](https://github.com/bdg-tbd/tbd-workshop-1/blob/v1.0.36/notebooks/tpc-di-setup.ipynb) to 
the running instance of your Vertex AI Workbench

5. In `tpc-di-setup.ipynb` modify cell under section ***Clone tbd-tpc-di repo***:

   a)first, fork https://github.com/mwiewior/tbd-tpc-di.git to your github organization.

   b)create new branch (e.g. 'notebook') in your fork of tbd-tpc-di and modify profiles.yaml by commenting following lines:
   ```  
        #"spark.driver.port": "30000"
        #"spark.blockManager.port": "30001"
        #"spark.driver.host": "10.11.0.5"  #FIXME: Result of the command (kubectl get nodes -o json |  jq -r '.items[0].status.addresses[0].address')
        #"spark.driver.bindAddress": "0.0.0.0"
   ```
   This lines are required to run dbt on airflow but have to be commented while running dbt in notebook.

   c)update git clone command to point to ***your fork***.

 


6. Access Vertex AI Workbench and run cell by cell notebook `tpc-di-setup.ipynb`.

    a) in the first cell of the notebook replace: `%env DATA_BUCKET=tbd-2023z-9910-data` with your data bucket.


   b) in the cell:
         ```%%bash
         mkdir -p git && cd git
         git clone https://github.com/mwiewior/tbd-tpc-di.git
         cd tbd-tpc-di
         git pull
         ```
      replace repo with your fork. Next checkout to 'notebook' branch.
   
    c) after running first cells your fork of `tbd-tpc-di` repository will be cloned into Vertex AI  enviroment (see git folder).

    d) take a look on `git/tbd-tpc-di/profiles.yaml`. This file includes Spark parameters that can be changed if you need to increase the number of executors and
  ```
   server_side_parameters:
       "spark.driver.memory": "2g"
       "spark.executor.memory": "4g"
       "spark.executor.instances": "2"
       "spark.hadoop.hive.metastore.warehouse.dir": "hdfs:///user/hive/warehouse/"
  ```


7. Explore files created by generator and describe them, including format, content, total size.

Stworzone pliki można podejrzeć poprzez google cloud terminal będąc w zakłądce google storage. W zasobniku tbd-2023z-300215-data/tpc-di
zostało utworzonych 217 plików o łącznej wadze 960.2 MiB. Jest 11 plików z rozrzerzeniem txt. Aż 5 z nich ma rozmiar większy od 100 MiB. Kolumny są w nick rozdzielane znakiem '|'. Dla przykłądu plik TaxRate.txt zawiera wysokość podatku dochodowego dla różnych osób w różnych miejscach.

Poza tym są dwa plik z rozszerzeniem csv. Są to Prospect.csv, która opisuje osoby oraz ich zasoby takie jak wartość ich portfela oraz HR.csv gdzie podane są dane osobowe pracowników oraz do jakiego menadżera są przypisani. W plikach tych występują wartości NUll w niektórych komórkach tabeli.

Jest ponadto jeden plik xml. Jest to CustomerMgmt.xml. Niestety po jego otworzeniu trudno jest zrozumieć to co przedstawia.

Reszta plików to pliki z nazwą zaczynającą się jako 'FINWIRE'. Po obejrzeniu kilku z nich w notatniku można założyć, że charakteryzują się one tym, że kolumny w poszczególnych wierszach zaczynają się w równych odległościach.

8. Analyze tpcdi.py. What happened in the loading stage?

   Na początku przebiego inicjalizacja bazy danych. Powstają bazy danych 'digen', 'bronze', 'silver' oraz 'gold'. Dzieje się to w metodzie 'get_session'.

   Część odpowiedzialna za ładowanie (loading) obsługuje po kolei różne typy plików. Z każdego pliku tworzony jest obiekt klasy 'StructType'. Dla plików txt oraz csv robi to się za pomocą tworzonych na sztywno schem z wykorzystaniem klas 'StructField' oraz 'StructType'. Dla pliku xml wykorzystywany jest 'col' z modułu pyspark. Pliki typu 'FINWIRE' są wczytywane w całości linia po linii. Następnie wyodrębniane są określone kolumny w oparciu o typy rekordów (CMP, SEC, FIN) i zapisuje każdą ramkę danych jako osobną tabelę typu 'StructType' o nazwach 'cmp', 'sec' oraz 'fin'.

   Następnie tak przerobione obiekty typu 'StructType' są z pomocą metody 'load_csv' zapisywane jako tabele w w Sparku.

   Stworzone logi po zakończeniu działania tego programu sugerują poprawne zakończenie programu i załadowanie wszystkich tabel. Pojawiło się kilka ostrzeżeń dotyczących zasobów tej samej ścieżki dodanych wielokrotnie do rozproszonej pamięci podręcznej oraz o zmianie silnika egzekutora hive. 

9. Using SparkSQL answer: how many table were created in each layer?

   ![img.png](doc/figures/layers.png)

10. Add some 3 more [dbt tests](https://docs.getdbt.com/docs/build/tests) and explain what you are testing. ***Add new tests to your repository.***

   Poniższy test sprawdza czy tabela reference_date ma wpisane poprawne dni tygodnia.
   ```
   select 
    DAY_OF_WEEK_NUM
   from {{ ref('reference_date') }} 
   where DAY_OF_WEEK_NUM < 1 or DAY_OF_WEEK_NUM > 7
   ```
   Poniższy test sprawdza czy tabela syndicated_prospect nie ma wartości NULL dla kolumny LAST_NAME.
   ```
   select LAST_NAME
   from {{ ref('syndicated_prospect') }} 
   where LAST_NAME is null
   ```

   Poniższy test sprawdza czy tabela trades ma poprawne (nie mniejsze od zera) wartości w kolumnie tax.
   ```
   select
    tax
   from {{ ref('trades') }} 
   where tax < 0  
   ```
   Jak widać na poniższym obrazku, podane wyżej testy przechodzą bez błędów.
   ![img.png](doc/figures/dbt_test.png)

11. In main.tf update
   ```
   dbt_git_repo            = "https://github.com/mwiewior/tbd-tpc-di.git"
   dbt_git_repo_branch     = "main"
   ```
   so dbt_git_repo points to your fork of tbd-tpc-di. 

12. Redeploy infrastructure and check if the DAG finished with no errors:

***The screenshot of Apache Aiflow UI***
