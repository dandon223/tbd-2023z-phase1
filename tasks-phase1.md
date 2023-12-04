IMPORTANT ❗ ❗ ❗ Please remember to destroy all the resources after each work session. You can recreate infrastructure by creating new PR and merging it to master.
  
![img.png](doc/figures/destroy.png)


1. Authors:

   ***gr-4***

   ***https://github.com/dandon223/tbd-2023z-phase1***
   
2. Fork https://github.com/bdg-tbd/tbd-2023z-phase1 and follow all steps in README.md.

3. Select your project and set budget alerts on 5%, 25%, 50%, 80% of 50$ (in cloud console -> billing -> budget & alerts -> create buget; unclick discounts and promotions&others while creating budget).

  ![img.png](doc/figures/discounts.png)

4. From avaialble Github Actions select and run destroy on main branch.

5. Create new git branch and add two resources in ```/modules/data-pipeline/main.tf```:
    1. resource "google_storage_bucket" "tbd-data-bucket" -> the bucket to store data. Set the following properties:
        * project  // look for variable in variables.tf
        * name  // look for variable in variables.tf
        * location // look for variable in variables.tf
        * uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
        * force_destroy               = true
        * public_access_prevention    = "enforced"
        * if checkcov returns error, add other properties if needed
       
    2. resource "google_storage_bucket_iam_member" "tbd-data-bucket-iam-editor" -> assign role storage.objectUser to data service account. Set the following properties:
        * bucket // refere to bucket name from tbd-data-bucket
        * role   // follow the instruction above
        * member = "serviceAccount:${var.data_service_account}"

Link: <https://github.com/dandon223/tbd-2023z-phase1/blob/master/modules/data-pipeline/main.tf>

Terraform snipet:

```

resource "google_storage_bucket" "tbd-data-bucket" {
  project                     = var.project_name
  name                        = var.data_bucket_name
  location                    = var.region
  uniform_bucket_level_access = false #tfsec:ignore:google-storage-enable-ubla
  force_destroy               = true

  #checkov:skip=CKV_GCP_62: "Bucket should log access"
  #checkov:skip=CKV_GCP_29: "Ensure that Cloud Storage buckets have uniform bucket-level access enabled"
  #checkov:skip=CKV_GCP_78: "Ensure Cloud storage has versioning enabled"
  public_access_prevention = "enforced"
}

resource "google_storage_bucket_iam_member" "tbd-data-bucket-iam-editor" {
  bucket = google_storage_bucket.tbd-data-bucket.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${var.data_service_account}"
}

```

Create PR from this branch to **YOUR** master and merge it to make new release. 

![img.png](doc/figures/task_5_2.png)
    

6. Analyze terraform code. Play with terraform plan, terraform graph to investigate different modules.

    Wybrany moduł: modules/composer

    Pozwala on na zarządzanie przepływu pracy na platformie Apache Airflow.

    Plik main.tf jest plikiem głównym, który zawiera opis zasobów jakie terraform powołuje dla tego modułu.
    * Zasób google_service_account umożliwia zarządzaniem kontem usługi google cloud.
    * Zasób google_project_iam_member pozwala przypisywać nowe role kontom google cloud.
    * Zasób google_project_service umożliwia zarządzanie pojedynczą usługą API dla projektu platformy google cloud.
    * Zasób google_compute_subnetwork tworzy podsieć w wirtualnej sieci projektu w podanym regionie.

    Przy użyciu komendy ```terraform plan -out=plan``` w folderze modules/composer wyświetla się plan dla tego modułu oraz jest on zapisany w folderze plan. Następnie należało podać ręcznie kilka zmiennych. Poniżej jest zamieszczona końcówka wyniku komendy.
```
  # module.composer.google_project_iam_member.composer_agent_service_account[0] will be created
  + resource "google_project_iam_member" "composer_agent_service_account" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = (known after apply)
      + project = "tbd"
      + role    = "roles/composer.ServiceAgentV2Ext"
    }

Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + data_service_account = (known after apply)
  + gcs_bucket           = (known after apply)

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

Graf udalo się uzyskać poprzez użycie komendy ```terraform graph -plan=plan | dot -Tpng > graph.png``` w folderze modules/composer. 
![img.png](doc/figures/graph.png)
    
7. Reach YARN UI
   
   W konsoli google cloud należy udać się do zasobu dataproc, wejść w szczegóły klastra tbd-cluster i postępować zgodnie z instrukcją pod zakładką interfejsy internetowe. Gdy utworzymy tunel możemy dostać się do YARN UI porzez adres <http://tbd-cluster-m:8088/cluster>.
   ![img.png](doc/figures/yarn.png)
   
8. Draw an architecture diagram (e.g. in draw.io) that includes:
    1. VPC topology with service assignment to subnets
    2. Description of the components of service accounts
    3. List of buckets for disposal
    4. Description of network communication (ports, why it is necessary to specify the host for the driver) of Apache Spark running from Vertex AI Workbech
  
    Architektura została stworzona na podstawie takich zakładek w google cloud jak topologia sieci, sieć VPN, Dataproc, Compute Engine, Administracja oraz przez pliki .tf dostępne w projekcie.

    Konta serwisu:

    * Konto tbd-terraform ma role owner
    * iac ma role iam.workloadIdentityUser, które w tym przypadku pozwala na automatyzację uwierzytelnienia podczas uruchamiania github actions
    * tbd-composer-sa ma role composer.worker, dataproc.editor, iam.serviceAccountUser

    Apache Spark, który uruchomiony jest w naszym przypadku w Vertex AI Workbech wykorzystuje argumenty spark.driver.port oraz spark.driver.host aby nasłuchiwać odpowiedni port oraz maszyny z której będą przychodziły zadania. W tym prjekcie ```spark.driver.host``` ma nazwe ${PROJECT_NAME}-notebook oraz ```spark.driver.port``` 16384 co można zbadać w pliku ```modules/docker_image/resources/Dockerfile```. Dany port nasłuchuje nadzorca, który rozsyła zadania po swoich węzłach roboczych. W naszym przypadku są dostępne dwie takie maszyny.

    ![img.png](doc/figures/diagram.drawio.png)

9. Add costs by entering the expected consumption into Infracost

  Zgodnie z <https://www.infracost.io/docs/features/usage_based_resources/> został utworzony plik infracost-usage.yml przy pomocy komendy ```infracost breakdown --sync-usage-file --usage-file infracost-usage.yml --path /code```. Następnie dla wstępnego oszacowania kosztów dla wygenerowanych pozycji zostało podane zużycie równe 1.

   ```
   # You can use this file to define resource usage estimates for Infracost to use when calculating
# the cost of usage-based resource, such as AWS S3 or Lambda.
# `infracost breakdown --usage-file infracost-usage.yml [other flags]`
# See https://infracost.io/usage-file/ for docs
version: 0.1
resource_type_default_usage:
  google_compute_router_nat:
    assigned_vms: 1 # Number of VM instances assigned to the NAT gateway
    monthly_data_processed_gb: 1.0 # Monthly data processed (ingress and egress) by the NAT gateway in GB
  google_container_registry:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 1 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 1 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
  google_storage_bucket:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
resource_usage:
  module.vpc.module.cloud-router.google_compute_router_nat.nats["nat-gateway"]:
    assigned_vms: 0 # Number of VM instances assigned to the NAT gateway
    monthly_data_processed_gb: 1.0 # Monthly data processed (ingress and egress) by the NAT gateway in GB
  module.data-pipelines.google_storage_bucket.tbd-code-bucket:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
  module.data-pipelines.google_storage_bucket.tbd-data-bucket:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
  module.gcr.google_container_registry.registry:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
  module.vertex_ai_workbench.google_storage_bucket.notebook-conf-bucket:
    storage_gb: 1.0 # Total size of bucket in GB.
    monthly_class_a_operations: 0 # Monthly number of class A operations (object adds, bucket/object list).
    monthly_class_b_operations: 0 # Monthly number of class B operations (object gets, retrieve bucket/object metadata).
    monthly_data_retrieval_gb: 1.0 # Monthly amount of data retrieved in GB.
    monthly_egress_data_transfer_gb:
      same_continent: 1.0 # Same continent.
      worldwide: 1.0 # Worldwide excluding Asia, Australia.
      asia: 1.0 # Asia excluding China, but including Hong Kong.
      china: 1.0 # China excluding Hong Kong.
      australia: 1.0 # Australia.
   ```

   Otrzymane wyniki przedstawiają się następująco.


   ![img.png](doc/figures/koszt.png)

10. Some resources are not supported by infracost yet. Estimate manually total costs of infrastructure based on pricing costs for region used in the project. Include costs of cloud composer, dataproc and AI vertex workbanch and them to infracost estimation.

  Po uruchomieniu powyższej komendy z flagą show-skipped znaleźć można nazwy 3 zasobów, które nie są obsługiwane przez infracost.
  * 1 x google_composer_environment
  * 1 x google_dataproc_cluster
  * 1 x google_notebooks_instance

    ![img.png](doc/figures/est.png)
   

    ***what are the options for cost optimization?***
    
11. Create a BigQuery dataset and an external table

  Zgodnie z sekcją ```Create a definition file for self-describing formats``` instrukcji <https://cloud.google.com/bigquery/docs/external-table-definition> do stworzenia zewnętrznej tabeli zostały użyte następujące komendy:
  
  ```
  bq mk tbd_test
  bq mk --table --external_table_definition=@ORC=gs://tbd-2023z-300215-data/data/shakespeare/part-00046-810bb950-eb12-41fd-8f28-296e766b195f-c000.snappy.orc tbd_test.table_test
  ```
   Zgodnie z powyższą instrukcją format ORC jest formatem samo opisującym się i daltego nie potrzebuje on dodatkowej schemy.
  
12. Start an interactive session from Vertex AI workbench (steps 7-9 in README):

    ![img.png](doc/figures/notebook.png)
   
13. Find and correct the error in spark-job.py

  Źródło błędu można znaleźć poprzez logi. Należy w konsoli google cloud przejść do omposera. Następnie do joba composera (airflow) środowiska demo-lab. Dalej należy przejść do dataproc_job. W zakładce graph widać zadanie któ©e zakończyło się błędem (pyspark_task). Należy na nie kliknąć a następnie wybrać log. W nim można znaleźć następujący status:
  ![img.png](doc/figures/log.png)

  Należy kliknąć w link. W logach dataproc widać przyczynę. Jest to błędnie podana nazwa kubełka.

  ![img.png](doc/figures/log_2.png)

  Nazwę tą należy zmienić w pliku ```modules/data-pipeline/resources/spark-job.py```. Jest ona podana jako zmienna DATA_BUCKET.
  ```
  DATA_BUCKET = "gs://tbd-2023z-9910-data/data/shakespeare/"
  DATA_BUCKET = "gs://tbd-2023z-300215-data/data/shakespeare/"
  ```
  Po ponownym uruchomieniu zadanie w airflow przechodzi bez błędów.

  ![img.png](doc/figures/pyspark_2.png)

14. Additional tasks using Terraform:

    1. Add support for arbitrary machine types and worker nodes for a Dataproc cluster and JupyterLab instance

    * W main.tf i variables.tf zostały dodane zmienne num_worker_nodes_dataproc, machine_type_dataproc i machine_type_jupyterlab.
    * W modules/dataproc/main.tf i modules/dataproc/variables.tf została dodana zmienna num_workers.
    * W modules/vertex-ai-workbench/main.tf i modules/vertex-ai-workbench/variables.tf została dodana zmienna machine_type.

    Link z pull requestu ze zmienionymi plikami <https://github.com/dandon223/tbd-2023z-phase1/pull/11>.
    
    2. Add support for preemptible/spot instances in a Dataproc cluster

    ***place the link to the modified file and inserted terraform code***
    
    3. Perform additional hardening of Jupyterlab environment, i.e. disable sudo access and enable secure boot
    
    ***place the link to the modified file and inserted terraform code***

    4. (Optional) Get access to Apache Spark WebUI

    ***place the link to the modified file and inserted terraform code***