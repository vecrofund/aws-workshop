terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_regionname  
}

data "aws_availability_zones" "case1-azs" {
  state = "available"
  
}

data "aws_ami" "amzonami" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "case1-vpc" {
    tags = {
      Name = "case1-vpc"
    }
    cidr_block = var.aws_vpc_cidr
}
resource "aws_internet_gateway" "case1-igw" {
    vpc_id = aws_vpc.case1-vpc.id
    tags = {
      Name = "case1-igw"
    }
  
}
resource "aws_subnet" "case1-subnet" {
    count = length(data.aws_availability_zones.case1-azs.names)
    vpc_id = aws_vpc.case1-vpc.id
    map_public_ip_on_launch = true
    cidr_block = "10.0.${count.index + 1}.0/24"
    availability_zone = data.aws_availability_zones.case1-azs.names[count.index]
    tags = {
        Name = "case1-subnet-${count.index + 1}"
    }
  
}
resource "aws_route_table" "case1-pub-route-table" {
    vpc_id = aws_vpc.case1-vpc.id
    tags = {
      Name = "case1-pub-route-table"
    } 
}
resource "aws_route" "case1-pub-route" {
    route_table_id         = aws_route_table.case1-pub-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.case1-igw.id
}
resource "aws_route_table_association" "case1-pub-subnet-assoc" {
    count = length(data.aws_availability_zones.case1-azs.names)
    subnet_id      = aws_subnet.case1-subnet[count.index].id
    route_table_id = aws_route_table.case1-pub-route-table.id
}
resource "aws_security_group" "case1-sg-lb" {
    name        = "case1-sg-lb"
    description = "Allow HTTP and HTTPS traffic"
    vpc_id      = aws_vpc.case1-vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "case1-sg-ec2" {
    name        = "case1-sg-ec2"
    description = "Allow traffic from Load Balancer"
    vpc_id      = aws_vpc.case1-vpc.id

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.case1-sg-lb.id]
    }
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
        
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_launch_template" "case1-ec2-temp" {
    name_prefix   = "case1-ec2-temp-"
    image_id      = data.aws_ami.amzonami.id
    instance_type = "t3.micro"
    key_name = "awsdev"
    monitoring {
        enabled = true
    }

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "case1-ec2-instance"
        }
    }
    vpc_security_group_ids = [aws_security_group.case1-sg-ec2.id]
    user_data = base64encode(file("user_data.sh"))

    lifecycle {
        create_before_destroy = true
    }
    

  
}

resource "aws_autoscaling_group" "case1-asg" {
    desired_capacity     = 1
    max_size             = 6
    min_size             = 1
    vpc_zone_identifier  = aws_subnet.case1-subnet[*].id
    launch_template {
        id      = aws_launch_template.case1-ec2-temp.id
        version = "$Latest"
    }
    target_group_arns    = [aws_lb_target_group.case1-tg.arn]
    tag {
        key                 = "Name"
        value               = "case1-asg-instance"
        propagate_at_launch = true
    }
    health_check_type         = "EC2"
    health_check_grace_period = 60  
}

resource "aws_lb" "case1-lb" {
    name               = "case1-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.case1-sg-lb.id]
    subnets            = aws_subnet.case1-subnet[*].id

    tags = {
      Name = "case1-lb"
    } 
  
}
resource "aws_lb_target_group" "case1-tg" {
    name     = "case1-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.case1-vpc.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }

    tags = {
      Name = "case1-tg"
    } 
  
}
resource "aws_lb_listener" "case1-lb-listener" {
    load_balancer_arn = aws_lb.case1-lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.case1-tg.arn
    }
  
}

resource "aws_autoscaling_policy" "scale_out_cpu" {
    name = "cpuout"
    autoscaling_group_name = aws_autoscaling_group.case1-asg.name
    policy_type = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
    
}

resource "aws_autoscaling_policy" "scale_in_cpu" {
    name = "cpuscalein"
    autoscaling_group_name = aws_autoscaling_group.case1-asg.name
    policy_type = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 30.0
    }
    
}

resource "aws_cloudwatch_metric_alarm" "serversideerror" {
    alarm_name          = "High-5xx-Error-Rate"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    metric_name         = "HTTPCode_Target_5XX_Count"
    namespace           = "AWS/ApplicationELB"
    period              = 60
    statistic           = "Sum"
    threshold           = 10
    alarm_description   = "This metric monitors high 5xx error rates"
    dimensions = {
        LoadBalancer = aws_lb.case1-lb.dns_name
    }
    alarm_actions = [aws_autoscaling_policy.scale_out_cpu.arn]
    ok_actions    = [aws_autoscaling_policy.scale_in_cpu.arn]
  
}

resource "aws_route53_record" "r53" {
    zone_id = "Z02006811XA543NMXJYU3"
    name    = "mywebsite"
    type    = "A"
    
    alias {
        name                   = aws_lb.case1-lb.dns_name
        zone_id                = aws_lb.case1-lb.zone_id
        evaluate_target_health = true
    }
  
}