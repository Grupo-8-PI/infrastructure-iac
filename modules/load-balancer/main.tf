# Variables
variable "elb_name" {
  description = "Nome do Elastic Load Balancer"
  type        = string
  default     = "elb-aej"
}

variable "public_subnet_id" {
  description = "ID da subnet pública onde o ELB será criado"
  type        = string
}

variable "public_instance_id" {
  description = "ID da instância EC2 pública para anexar ao ELB"
  type        = string
}

variable "instance_port" {
  description = "Porta da instância"
  type        = number
  default     = 80
}

variable "instance_protocol" {
  description = "Protocolo da instância"
  type        = string
  default     = "HTTP"
}

variable "lb_port" {
  description = "Porta do load balancer"
  type        = number
  default     = 80
}

variable "lb_protocol" {
  description = "Protocolo do load balancer"
  type        = string
  default     = "HTTP"
}

variable "health_check_target" {
  description = "Target do health check"
  type        = string
  default     = "HTTP:80/"
}

variable "health_check_interval" {
  description = "Intervalo do health check"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout do health check"
  type        = number
  default     = 5
}

variable "unhealthy_threshold" {
  description = "Threshold para considerar instância não saudável"
  type        = number
  default     = 2
}

variable "healthy_threshold" {
  description = "Threshold para considerar instância saudável"
  type        = number
  default     = 2
}

# Resources
resource "aws_elb" "elb_aej" {
  name    = var.elb_name
  subnets = [var.public_subnet_id]

  listener {
    instance_port     = var.instance_port
    instance_protocol = var.instance_protocol
    lb_port           = var.lb_port
    lb_protocol       = var.lb_protocol
  }

  health_check {
    target              = var.health_check_target
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.unhealthy_threshold
    healthy_threshold   = var.healthy_threshold
  }

  instances = [var.public_instance_id]

  tags = {
    Name = var.elb_name
  }
}

# Outputs
output "elb_id" {
  description = "ID do Elastic Load Balancer"
  value       = aws_elb.elb_aej.id
}

output "elb_dns_name" {
  description = "DNS name do Elastic Load Balancer"
  value       = aws_elb.elb_aej.dns_name
}
