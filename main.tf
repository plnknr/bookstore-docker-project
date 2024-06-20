terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = var.git-token
}

# update according to your own information
variable "git-name" {
  default = "plnknr"
}

# update according to your own information
variable "git-token" {
  default = "XXXXXXX"
} # If we embed this part in the AWS parameter store, it will be easier and safer to use.
# AWS system manager -> parameter store -> create parameter name is given and token value section is written -> create parameter is called and created
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter#value
# data "aws_ssm_parameter" "foo" {
#   name = "foo"
# }
# Values ​​are retrieved by writing "user-data-git-token = data.aws_ssm_parameter.token.value" in the user data section.

# update according to your own information
variable "key-name" {
  default = "mykey"
}

resource "github_repository" "myrepo" {
  name = "bookstore-api-repo"
  visibility = "private"
  auto_init = true
}

# it creates github branch
resource "github_branch_default" "main" {
  branch = "main"
  repository = github_repository.myrepo.name
}

variable "files" {
  default = ["bookstore-api.py", "docker-compose.yml", "requirements.txt", "Dockerfile"]
}

resource "github_repository_file" "app-files" {
  for_each = toset(var.files)
  content = file(each.value)
  file = each.value
  repository = github_repository.myrepo.name
  #branch = github_branch_default.default.branch
  branch = "main" # Hardcoding the branch name makes the configuration less flexible and harder to maintain if the default branch name ever changes.
  commit_message = "managed by terraform"
  commit_author = "xxxxx"
  commit_email = "xxx@xxx.com"
  overwrite_on_create = true
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-sec-gr-203"
  tags = {
    Name = "docker-sec-group-203"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tf-docker-ec2" {
  ami = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  key_name = var.key-name
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  tags = {
    Name = "Web Server of Bookstore"
  }
  user_data = templatefile("user-data.sh", { user-data-git-token = var.git-token, user-data-git-name = var.git-name })
  depends_on = [github_repository.myrepo, github_repository_file.app-files]
}

output "website" {
  value = "http://${aws_instance.tf-docker-ec2.public_dns}"
}