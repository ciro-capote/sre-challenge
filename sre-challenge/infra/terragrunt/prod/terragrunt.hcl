# terragrunt.hcl - Production Environment
terraform {
  source = "../../modules/gke-cluster"
}

# SRE Note: Em produção real, adicionaríamos um bloco 'remote_state' apontando para um bucket GCS.

inputs = {
  cluster_name = "gke-prod-cluster"
  region       = "us-central1-a"

  node_pools = {
    "prod-pool" = {
      node_count   = 2 # Alta disponibilidade para PROD
      machine_type = "e2-medium"
      labels = { environment = "prod" } # CORRIGIDO
      taints = [{ key = "environment", value = "prod", effect = "NO_SCHEDULE" }]
    }
  }
}
