# Define variables for the Quake 3 server configuration
variable "quake3_server_name" {
  description = "Name for the Quake 3 server"
  type        = string
}

variable "quake3_server_port" {
  description = "Port for the Quake 3 server"
  type        = number
}

# Create a Kubernetes Deployment for the Quake 3 server
resource "kubernetes_deployment" "quake3_server" {
  metadata {
    name = "quake3-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "quake3-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "quake3-server"
        }
      }

      spec {
        containers {
          name  = "quake3-server"
          image = "your-quake3-server-image:latest" # Replace with the Quake 3 server Docker image

          ports {
            container_port = var.quake3_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "QUAKE_SERVER_NAME"
            value = var.quake3_server_name
          }
        }
      }
    }
  }
}

# Expose the Quake 3 server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "quake3_server" {
  metadata {
    name = "quake3-server-service"
  }

  spec {
    selector = {
      app = "quake3-server"
    }

    port {
      port        = var.quake3_server_port
      target_port = var.quake3_server_port
    }

    type = "NodePort"
  }
}

