# Define variables for the Counter-Strike: Source server configuration
variable "cs_source_server_name" {
  description = "Name for the Counter-Strike: Source server"
  type        = string
}

variable "cs_source_server_port" {
  description = "Port for the Counter-Strike: Source server"
  type        = number
}

variable "cs_source_server_rcon_password" {
  description = "RCON password for server administration"
  type        = string
}

# Create a Kubernetes Deployment for the Counter-Strike: Source server
resource "kubernetes_deployment" "cs_source_server" {
  metadata {
    name = "cs-source-server"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cs-source-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "cs-source-server"
        }
      }

      spec {
        containers {
          name  = "cs-source-server"
          image = "ubuntu:latest" # Use an Ubuntu base image

          # You would need to install Counter-Strike: Source within this container
          # This could involve using tools like apt to install the necessary dependencies and game server software

          # Expose the game server port
          ports {
            container_port = var.cs_source_server_port
          }

          # You can specify environment variables here for game server settings
          env {
            name  = "CS_SERVER_NAME"
            value = var.cs_source_server_name
          }

          # Example: Setting the RCON password as an environment variable
          env {
            name  = "RCON_PASSWORD"
            value = var.cs_source_server_rcon_password
          }
        }
      }
    }
  }
}

# Expose the Counter-Strike: Source server via a Kubernetes Service (NodePort type)
resource "kubernetes_service" "cs_source_server" {
  metadata {
    name = "cs-source-server-service"
  }

  spec {
    selector = {
      app = "cs-source-server"
    }

    port {
      port        = var.cs_source_server_port
      target_port = var.cs_source_server_port
    }

    type = "NodePort"
  }
}

