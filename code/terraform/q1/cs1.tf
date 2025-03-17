# Define variables for the Counter-Strike server configuration
variable "cs_server_name" {
  description = "Name for the Counter-Strike server"
  type        = string
}

variable "cs_server_port" {
  description = "Port for the Counter-Strike server"
  type        = number
}

# Create a Kubernetes Deployment for the Counter-Strike server
resource "kubernetes_deployment" "cs_server" {
  metadata {
    name = "cs-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cs-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "cs-server"
        }
      }

      spec {
        containers {
          name  = "cs-server"
          image = "ubuntu:latest" # Use an Ubuntu base image

          # You would need to install Counter-Strike within this container
          # This could involve using tools like apt to install the necessary dependencies and Counter-Strike software

          # Expose the game server port
          ports {
            container_port = var.cs_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "CS_SERVER_NAME"
            value = var.cs_server_name
          }
        }
      }
    }
  }
}

# Expose the Counter-Strike server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "cs_server" {
  metadata {
    name = "cs-server-service"
  }

  spec {
    selector = {
      app = "cs-server"
    }

    port {
      port        = var.cs_server_port
      target_port = var.cs_server_port
    }

    type = "NodePort"
  }
}

