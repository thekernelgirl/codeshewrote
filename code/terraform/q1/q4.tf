# Define variables for the Quake 4 server configuration
variable "quake4_server_name" {
  description = "Name for the Quake 4 server"
  type        = string
}

variable "quake4_server_port" {
  description = "Port for the Quake 4 server"
  type        = number
}

# Create a Kubernetes Deployment for the Quake 4 server
resource "kubernetes_deployment" "quake4_server" {
  metadata {
    name = "quake4-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "quake4-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "quake4-server"
        }
      }

      spec {
        containers {
          name  = "quake4-server"
          image = "your-quake4-server-image:latest" # Replace with the Quake 4 server Docker image

          ports {
            container_port = var.quake4_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "QUAKE_SERVER_NAME"
            value = var.quake4_server_name
          }
        }
      }
    }
  }
}

# Expose the Quake 4 server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "quake4_server" {
  metadata {
    name = "quake4-server-service"
  }

  spec {
    selector = {
      app = "quake4-server"
    }

    port {
      port        = var.quake4_server_port
      target_port = var.quake4_server_port
    }

    type = "NodePort"
  }
}

