resource "kubernetes_service_account" "service_account" {
  count = module.this.enabled ? 1 : 0

  metadata {
    name        = coalesce(var.deployment_name, module.this.id, "tfc-agent")
    namespace   = coalesce(var.kubernetes_namespace, var.namespace, "default")
    annotations = var.service_account_annotations
  }
}

resource "kubernetes_deployment" "tfc_cloud_agent" {
  count = module.this.enabled ? 1 : 0

  metadata {
    name      = coalesce(var.deployment_name, module.this.id, "tfc-agent")
    namespace = coalesce(var.kubernetes_namespace, var.namespace, "default")
    labels    = module.this.tags
  }
  spec {
    selector {
      match_labels = var.selector_match_labels
    }
    replicas = var.replicas

    template {
      metadata {
        labels      = module.this.tags
        annotations = var.deployment_annotations
      }
      spec {
        service_account_name            = kubernetes_service_account.service_account.0.metadata.0.name
        automount_service_account_token = true
        container {
          image = var.agent_image
          name  = "tfc-agent"
          env {
            name  = "TFC_AGENT_TOKEN"
            value = var.tfc_agent_token
          }
          env {
            name  = "TFC_AGENT_NAME"
            value = coalesce(module.this.id, "tfc-agent")
          }
          env {
            name  = "TFC_AGENT_LOG_LEVEL"
            value = var.tfc_agent_log_level
          }
          env {
            name  = "TFC_AGENT_DATA_DIR"
            value = var.tfc_agent_data_dir
          }
          env {
            name  = "TFC_AGENT_SINGLE"
            value = var.tfc_agent_single
          }
          env {
            name  = "TFC_AGENT_DISABLE_UPDATE"
            value = var.tfc_agent_disable_update
          }
          env {
            name  = "TFC_ADDRESS"
            value = var.tfc_address
          }
          resources {
            limits {
              cpu    = var.resource_limits_cpu
              memory = var.resource_limits_memory
            }
            requests {
              cpu    = var.resource_requests_cpu
              memory = var.resource_requests_memory
            }
          }
        }
      }
    }
  }
}