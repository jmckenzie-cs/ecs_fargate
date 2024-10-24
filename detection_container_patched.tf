provider "aws" {
  region = "us-east-1"  # Use your preferred AWS region
}

# Define the ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "detection_container_task" {
  family                   = "detection_container_xs_guide"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "detection-container",
      image     = "517716713836.dkr.ecr.us-east-1.amazonaws.com/mckenzie-images:detection-container_amd64",
      cpu       = 0,
      essential = true,
      entryPoint = [
        "/tmp/CrowdStrike/rootfs/lib64/ld-linux-x86-64.so.2",
        "--library-path", "/tmp/CrowdStrike/rootfs/lib64",
        "/tmp/CrowdStrike/rootfs/bin/bash",
        "/tmp/CrowdStrike/rootfs/entrypoint-ecs.sh",
        "/entrypoint.sh"
      ],
      dependsOn = [
        {
          "condition" = "COMPLETE",
          "containerName" = "crowdstrike-falcon-init-container"
        }
      ],
      environment = [
        {
          "name" = "FALCONCTL_OPTS",
          "value" = "--cid=#############################-##"
        }
      ],
      logConfiguration = {
        "logDriver" = "awslogs",
        "options" = {
          "awslogs-create-group" = "true",
          "awslogs-group"        = "/ecs/mckenzie_detection",
          "awslogs-region"       = "us-east-1",
          "awslogs-stream-prefix" = "ecs"
        }
      },
      linuxParameters = {
        "capabilities" = {
          "add" = ["SYS_PTRACE"]
        }
      },
      portMappings = [
        {
          "containerPort" = 80,
          "hostPort"      = 80,
          "protocol"      = "tcp"
        }
      ],
      mountPoints = [
        {
          "containerPath" = "/tmp/CrowdStrike",
          "sourceVolume"  = "crowdstrike-falcon-volume",
          "readOnly"      = true
        }
      ]
    },
    {
      name      = "crowdstrike-falcon-init-container",
      image     = "517716713836.dkr.ecr.us-east-1.amazonaws.com/mckenzie-images:falcon-container-sensor-latest",
      essential = false,
      entryPoint = [
        "/bin/bash",
        "-c",
        "chmod u+rwx /tmp/CrowdStrike && mkdir /tmp/CrowdStrike/rootfs && cp -r /bin /etc /lib64 /usr /entrypoint-ecs.sh /tmp/CrowdStrike/rootfs && chmod -R a=rX /tmp/CrowdStrike"
      ],
      mountPoints = [
        {
          "containerPath" = "/tmp/CrowdStrike",
          "sourceVolume"  = "crowdstrike-falcon-volume",
          "readOnly"      = false
        }
      ],
      readonlyRootFilesystem = true,
      user                   = "0:0"
    }
  ])

  volume {
    name = "crowdstrike-falcon-volume"
  }
}

# Optional: ECS Service Definition (if you want to run it as part of a service)
resource "aws_ecs_service" "detection_service" {
  name            = "detection-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.detection_container_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets = ["subnet-abc123"]
    security_groups = ["sg-123456"]
    assign_public_ip = true
  }
}
