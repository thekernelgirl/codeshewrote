# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "quick_sight_admin_email" {
  description = "Email address of the QuickSight admin user"
}

variable "quick_sight_users" {
  description = "List of email addresses for QuickSight users"
  type        = list(string)
}

resource "aws_quicksight_user" "admin_user" {
  user_name = "admin"
  email     = var.quick_sight_admin_email
  role      = "ADMIN"
}

resource "aws_quicksight_group" "users_group" {
  group_name = "users"
}

resource "aws_quicksight_group_membership" "user_group_membership" {
  group_name = aws_quicksight_group.users_group.name
  member_name = aws_quicksight_user.admin_user.name
}

resource "aws_quicksight_group_membership" "multiple_user_group_membership" {
  count        = length(var.quick_sight_users)
  group_name   = aws_quicksight_group.users_group.name
  member_name  = var.quick_sight_users[count.index]
}

