# main.tf - Módulo SRE Standard para GKE
# Decisão Técnica: Removemos o default_node_pool para ter controle total do ciclo de vida dos workers.
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1

  # Observabilidade Nativa GCP (Requisito 7)
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

# Criação dinâmica de Node Pools baseada no map de variáveis
resource "google_container_node_pool" "dynamic_pools" {
  for_each = var.node_pools

  name       = each.key
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = each.value.node_count

  node_config {
    machine_type = each.value.machine_type
    labels       = each.value.labels

    # Aplica Taints dinamicamente para isolamento de workloads
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
