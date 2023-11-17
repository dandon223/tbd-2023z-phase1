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

    Przy użyciu komendy ```terraform plan -out=plan``` w folderze modules/composer wyświetla się plan dla tego modułu oraz jest on zapisany w folderze plan. Należało podać niektóre zmienne ręcznie. Poniżej jest zamieszczona końcówka wyniku komendy.
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
   
   ***place the port and the screenshot of YARN UI here***
   
8. Draw an architecture diagram (e.g. in draw.io) that includes:
    1. VPC topology with service assignment to subnets
    2. Description of the components of service accounts
    3. List of buckets for disposal
    4. Description of network communication (ports, why it is necessary to specify the host for the driver) of Apache Spark running from Vertex AI Workbech
  
    ***place your diagram here***

9. Add costs by entering the expected consumption into Infracost

   ***place the expected consumption you entered here***

   ***place the screenshot from infracost output here***

10. Some resources are not supported by infracost yet. Estimate manually total costs of infrastructure based on pricing costs for region used in the project. Include costs of cloud composer, dataproc and AI vertex workbanch and them to infracost estimation.

    ***place your estimation and references here***

    ***what are the options for cost optimization?***
    
12. Create a BigQuery dataset and an external table
    
    ***place the code and output here***
   
    ***why does ORC not require a table schema?***
  
13. Start an interactive session from Vertex AI workbench (steps 7-9 in README):

    ***place the screenshot of notebook here***
   
14. Find and correct the error in spark-job.py

    ***describe the cause and how to find the error***

15. Additional tasks using Terraform:

    1. Add support for arbitrary machine types and worker nodes for a Dataproc cluster and JupyterLab instance

    ***place the link to the modified file and inserted terraform code***
    
    3. Add support for preemptible/spot instances in a Dataproc cluster

    ***place the link to the modified file and inserted terraform code***
    
    3. Perform additional hardening of Jupyterlab environment, i.e. disable sudo access and enable secure boot
    
    ***place the link to the modified file and inserted terraform code***

    4. (Optional) Get access to Apache Spark WebUI

    ***place the link to the modified file and inserted terraform code***