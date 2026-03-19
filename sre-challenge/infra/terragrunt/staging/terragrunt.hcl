# terragrunt.hcl - Staging Environment
terraform {
  source = "../../modules/gke-cluster"
}

# SRE Note: Em produção real, adicionaríamos um bloco 'remote_state' apontando para um bucket GCS.

inputs = {
  cluster_name = "gke-staging-cluster"
  region       = "us-central1-a"
  
  node_pools = {
    "staging-pool" = {
      node_count   = 1
      machine_type = "e2-medium"
      labels = { environment = "staging" }
      taints = [{ key = "environment", value = "staging", effect = "NO_SCHEDULE" }]
    }
  }
}
