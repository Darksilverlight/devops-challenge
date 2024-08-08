#replace backened as needed
terraform {
    backend "s3" {
        bucket         = "darksilverlight-devops-challenge-tfstate"
        key            = "global/s3/terraform.tfstate"
        region         = "us-east-1"

        dynamodb_table = "terraform-state-locks"
        encrypt        = true
    }
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.24"
        }
    }

    required_version = ">= 1.2.0"
}


provider "aws" {
    region  = "us-east-1"
}

#networking logic start
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnets" {
    for_each          = { for idx, cidr_block in var.public_subnet_cidrs: cidr_block => idx}
    vpc_id            = aws_vpc.main.id
    cidr_block        = each.key
    availability_zone = element(var.azs, each.value)
    

 
}

resource "aws_subnet" "private_app_subnets" {

    for_each          = { for idx, cidr_block in var.private_app_subnet_cidrs: cidr_block => idx}
    vpc_id            = aws_vpc.main.id
    cidr_block        = each.key
    availability_zone = element(var.azs, each.value)
    
}

resource "aws_subnet" "private_data_subnets" {

    for_each          = { for idx, cidr_block in var.private_data_subnet_cidrs: cidr_block => idx}
    vpc_id            = aws_vpc.main.id
    cidr_block        = each.key
    availability_zone = element(var.azs, each.value)
    
}

resource "aws_internet_gateway" "gateway" {

    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }
}

resource "aws_route_table_association" "public_route_association" {
    for_each = aws_subnet.public_subnets
    subnet_id = each.value.id
    route_table_id = aws_route_table.public_route.id
}

resource "aws_eip" "nat_gateway_eip" {
    for_each = aws_subnet.public_subnets
    domain = "vpc"
}

resource "aws_nat_gateway" "aws_nat_gateway" {
    for_each = { for idx, cidr_block in var.public_subnet_cidrs: cidr_block => idx}
    subnet_id = aws_subnet.public_subnets[keys(aws_subnet.public_subnets)[each.value]].id
    allocation_id = aws_eip.nat_gateway_eip[keys(aws_eip.nat_gateway_eip)[each.value]].id
}

resource "aws_route_table" "private_app_route" {
    
    vpc_id = aws_vpc.main.id
    for_each  = { for idx, cidr_block in var.private_app_subnet_cidrs: cidr_block => idx}
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.aws_nat_gateway[keys(aws_nat_gateway.aws_nat_gateway)[each.value]].id
    }
}

resource "aws_route_table_association" "private_route_association" {
    for_each  = { for idx, cidr_block in var.private_app_subnet_cidrs: cidr_block => idx}
    subnet_id = aws_subnet.private_app_subnets[keys(aws_subnet.private_app_subnets)[each.value]].id
    route_table_id = aws_route_table.private_app_route[keys(aws_route_table.private_app_route)[each.value]].id
}

#networking logic end

#security group start

resource "aws_security_group" "loadbalancer_sg" {
    vpc_id = aws_vpc.main.id
}   

resource "aws_security_group" "app_sg" {
    vpc_id = aws_vpc.main.id
}   

resource "aws_security_group" "data_sg" {
    vpc_id = aws_vpc.main.id
}   

resource "aws_vpc_security_group_ingress_rule" "loadbalancer_self" {
    security_group_id = aws_security_group.loadbalancer_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.loadbalancer_sg.id
    description = "Allow connection to self"
}

resource "aws_vpc_security_group_ingress_rule" "loadbalancer_all_external" {
    security_group_id = aws_security_group.loadbalancer_sg.id
    ip_protocol = -1
    cidr_ipv4 = "0.0.0.0/0"
    description = "Allow all inbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "app_self" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.app_sg.id
    description = "Allow connection to self"
}

resource "aws_vpc_security_group_ingress_rule" "data_self" {
    security_group_id = aws_security_group.data_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.data_sg.id
    description = "Allow connection to self"
}

resource "aws_vpc_security_group_ingress_rule" "app_allow_loadbalancer" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.loadbalancer_sg.id
    description = "Allow loadbalancer inbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "data_allow_app" {
    security_group_id = aws_security_group.data_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.app_sg.id
    description = "Allow app inbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "data_allow_app" {
    security_group_id = aws_security_group.data_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.app_sg.id
    description = "Allow app outbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "loadbalancer_allow_app" {
    security_group_id = aws_security_group.loadbalancer_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.app_sg.id
    description = "Allow app outbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "app_allow_all" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = -1
    cidr_ipv4 = "0.0.0.0/0"
    description = "Allow all outbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "loadbalancer_self" {
    security_group_id = aws_security_group.loadbalancer_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.loadbalancer_sg.id
    description = "Allow connection to self"
}

resource "aws_vpc_security_group_egress_rule" "app_self" {
    security_group_id = aws_security_group.app_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.app_sg.id
    description = "Allow connection to self"
}

resource "aws_vpc_security_group_egress_rule" "data_self" {
    security_group_id = aws_security_group.data_sg.id
    ip_protocol = -1
    referenced_security_group_id = aws_security_group.data_sg.id
    description = "Allow connection to self"
}

#security group end

resource "aws_lb" "loadbalancer" {
    security_groups = [aws_security_group.loadbalancer_sg.id]
    subnets = [for subnet in aws_subnet.public_subnets : subnet.id]
}

resource "aws_db_subnet_group" "main_subnet_group" {
    name = "private_data_subnets"
    subnet_ids = [for subnet in aws_subnet.private_data_subnets : subnet.id]
}
/*
#database start
resource "aws_rds_cluster" "main_database" {
    manage_master_user_password = true
    master_username = "postgres"
    engine = "postgres"
    storage_encrypted = true
    storage_type = "gp3"
    allocated_storage = 20
    iops = 3000
    cluster_identifier = "main"
    db_cluster_instance_class = "db.c6gd.medium"
    vpc_security_group_ids = [aws_security_group.data_sg.id]
    db_subnet_group_name = aws_db_subnet_group.main_subnet_group.name
    skip_final_snapshot = true
}
*/

#ecs start

data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}
resource "aws_launch_template" "ecs_lt" {
 image_id      = "ami-04ca2090011ea0a25"
 instance_type = "t2.micro"
 vpc_security_group_ids = [aws_security_group.app_sg.id]
 iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }

user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )

}

resource "aws_autoscaling_group" "ecs_asg" {

 vpc_zone_identifier = [for subnet in aws_subnet.private_app_subnets : subnet.id]
 desired_capacity    = 2
 max_size            = 3
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
 }

}

resource "aws_lb_target_group" "ecs_tg" {
 name        = "ecs-target-group"
 port        = 80
 protocol    = "HTTP"
 vpc_id      = aws_vpc.main.id
  health_check {
   path = "/"
 }

}

resource "aws_lb_listener" "ecs_alb_listener" {

 load_balancer_arn = aws_lb.loadbalancer.arn
 port              = 80
 protocol          = "HTTP"
  default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.ecs_tg.arn
 }

}

resource "aws_ecs_capacity_provider" "capacity_provider" {

 name = "capacity-test"
 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
   managed_draining = "DISABLED"

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 2
   }
 }

}


resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_capacity" {

 cluster_name = aws_ecs_cluster.main.name
 capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]
 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
 }

}

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "test-logs" {
  name = "test-logs"
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = "bridge"
 cpu                = 256
 task_role_arn      = aws_iam_role.ecs_task_role.arn
 execution_role_arn = aws_iam_role.ecs_exec_role.arn
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }

 container_definitions = jsonencode([
   {
     name      = "devops-challenge-task"
     image     = "021891597647.dkr.ecr.us-east-1.amazonaws.com/prod:latest"
     cpu       = 256
     memory    = 256
     essential = true
     logConfiguration = {
        logDriver="awslogs"
        options = {
          awslogs-region = "us-east-1"
          awslogs-group = aws_cloudwatch_log_group.test-logs.name
        }
     }
     portMappings = [
       {
         containerPort = 8000
         protocol      = "tcp"
       }
     ]
   }
 ])
}

resource "aws_ecs_service" "ecs_service" {

 name            = "devops-challenge-service"
 cluster         = aws_ecs_cluster.main.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

 force_new_deployment = true

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = "devops-challenge-task"
   container_port   = 8000
 }

}