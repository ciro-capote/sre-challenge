variable "cluster_name" { type = string }
variable "region" { type = string }
variable "node_pools" {
  description = "Configuração dinâmica dos Node Pools"
  type = map(object({
    node_count   = number
    machine_type = string
    labels       = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}
