output "ecs_cluster_id" {
  description = "The ID of ECS Cluster"
  value       = { for k, v in aws_ecs_cluster.ecs_cluster : k => v.id }
}

output "task_definition_arn" {
  description = "The ARN of ECS Task Definition"
  value       = { for k, v in aws_ecs_task_definition.task_definition : k => v.arn }
}

output "ecs_service_name" {
  description = "The name of ECS Service (if created)"
  value       = var.create_service ? { for k, v in aws_ecs_service.ecs_service : k => v.name } : {}
}
