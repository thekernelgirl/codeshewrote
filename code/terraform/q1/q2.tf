# Define variables for the Quake 2 server configuration
variable "quake2_server_name" {
  description = "Name for the Quake 2 server"
  type        = string
}

variable "quake2_server_port" {
  description = "Port for the Quake 2 server"
  type        = number
}

# Create a Kubernetes Deployment for the Quake 2 server
resource "kubernetes_deployment" "quake2_server" {
  metadata {
    name = "quake2-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "quake2-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "quake2-server"
        }
      }

      spec {
        containers {
          name  = "quake2-server"
          image = "your-quake2-server-image:latest" # Replace with the Quake 2 server Docker image

          ports {
            container_port = var.quake2_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "QUAKE_SERVER_NAME"
            value = var.quake2_server_name
          }
        }
      }
    }
  }
}

# Expose the Quake 2 server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "quake2_server" {
  metadata {
    name = "quake2-server-service"
  }

  spec {
    selector = {
      app = "quake2-server"
    }

    port {
      port        = var.quake2_server_port
      target_port = var.quake2_server_port
    }

    type = "NodePort"
  }
}

