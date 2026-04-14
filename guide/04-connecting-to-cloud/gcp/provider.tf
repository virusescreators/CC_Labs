terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region

  # Credentials are read from:
  # 1. GOOGLE_APPLICATION_CREDENTIALS environment variable (path to service account JSON)
  # 2. gcloud CLI: `gcloud auth application-default login`
  # 3. Compute Engine default service account (when running on GCE)
}
