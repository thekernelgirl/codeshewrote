# Define variables for the Quake 1 server configuration
variable "quake1_server_name" {
  description = "Name for the Quake 1 server"
  type        = string
}

variable "quake1_server_port" {
  description = "Port for the Quake 1 server"
  type        = number
}

# Create a Kubernetes Deployment for the Quake 1 server
resource "kubernetes_deployment" "quake1_server" {
  metadata {
    name = "quake1-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "quake1-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "quake1-server"
        }
      }

      spec {
        containers {
          name  = "quake1-server"
          image = "your-quake1-server-image:latest" # Replace with the Quake 1 server Docker image

          ports {
            container_port = var.quake1_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "QUAKE_SERVER_NAME"
            value = var.quake1_server_name
          }
        }
      }
    }
  }
}

# Expose the Quake 1 server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "quake1_server" {
  metadata {
    name = "quake1-server-service"
  }

  spec {
    selector = {
      app = "quake1-server"
    }

    port {
      port        = var.quake1_server_port
      target_port = var.quake1_server_port
    }

    type = "NodePort"
  }
}

