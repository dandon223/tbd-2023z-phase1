variable "project_name" {
  type        = string
  description = "Project name"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "GCP region"
}

variable "ai_notebook_instance_owner" {
  type        = string
  description = "Vertex AI workbench owner"
}

variable "machine_type_jupyterlab" {
  description = "The machine type for JupyterLab instance"
  default     = "e2-standard-2"
}

variable "machine_type_dataproc" {
  description = "The machine type for the Dataproc cluster"
  default     = "e2-standard-2"
}

variable "num_worker_nodes_dataproc" {
  description = "The number of worker nodes for the Dataproc cluster"
  default     = 2
}