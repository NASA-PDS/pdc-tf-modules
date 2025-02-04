#Load YAML configuration based on the environmtn
locals {
  config = yamldecode(file(var.config_file))
}

#Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  for_each = tomap({ for cluster in local.config["clusters"] : cluster["cluster_name"] => cluster })
  name     = each.value["cluster_name"]
}

#Create Task Definition
resource "aws_ecs_task_definition" "task_definition" {
  for_each = tomap({ for taskdefinition in local.config["task_definitions"] : taskdefinition["task_family"] => taskdefinition })

  family                   = each.value["task_family"]
  container_definitions    = jsonencode(each.value["container_definitions"])
  requires_compatibilities = each.value["requires_compatibilities"]
  network_mode             = each.value["network_mode"]
  cpu                      = each.value["cpu"]
  memory                   = each.value["memory"]
  execution_role_arn       = each.value["execution_role_arn"]
  task_role_arn            = each.value["task_role_arn"]
  runtime_platform {
    operating_system_family = lookup(each.value, "runtimePlatform", {})["operatingSystemFamily"]
    cpu_architecture        = lookup(each.value, "runtimePlatform", {})["cpuArchitecture"]
  }
}

#Create ECS Service (conditionally)
resource "aws_ecs_service" "ecs_service" {
  for_each = var.create_service ? tomap({ for service in local.config["services"] : "${service["cluster_name"]}-${service["service_name"]}" => service }) : {}

  name            = each.value["service_name"]
  cluster         = aws_ecs_cluster.ecs_cluster[each.value["cluster_name"]].id
  task_definition = aws_ecs_task_definition.task_definition[each.value["task_family"]].arn
  desired_count   = local.config["desired_count"]
  launch_type     = local.config["launch_type"]

  load_balancer {
    target_group_arn = each.value["load_balancer"]["target_group_arn"]
    container_name   = each.value["load_balancer"]["container_name"]
    container_port   = each.value["load_balancer"]["container_port"]
  }

  network_configuration {
    subnets          = each.value["network_configuration"]["subnets"]
    security_groups  = each.value["network_configuration"]["security_groups"]
    assign_public_ip = each.value["network_configuration"]["assign_public_ip"]
  }

  deployment_controller {
    type = each.value["deployment_controller_type"]
  }

  depends_on = [aws_ecs_task_definition.task_definition]
}
