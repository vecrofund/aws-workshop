resource "aws_launch_template" "case3-ec2-temp" {
    name_prefix   = "case3-ec2-temp-"
    image_id      = data.aws_ami.amzonami.id
    instance_type = "t3.medium"
    key_name = "awsdev"
    monitoring {
        enabled = true
    }
    iam_instance_profile {
        name = aws_iam_instance_profile.case3-iam-instance-profile.name
    }

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "case3-ec2-instance"
        }
    }
    vpc_security_group_ids = [aws_security_group.case3-public-web.id]
    user_data = base64encode(templatefile("user_data_web.sh", {
        app_url = "http://${aws_instance.app.private_ip}:8080"
    }))

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
            volume_size = 30
            volume_type = "gp3"
            delete_on_termination = true 
        }
    }
    # block_device_mappings {
    #     device_name = "/dev/xvdb"

    #     ebs {
    #         volume_size = 50
    #         volume_type = "gp3"
    #         delete_on_termination = false 
    #     }
    # }
    
  
}

resource "aws_autoscaling_group" "case3-asg" {
    desired_capacity     = 2
    max_size             = 6
    min_size             = 2
    vpc_zone_identifier  = aws_subnet.case3-public-subnet[*].id
    launch_template {
        id      = aws_launch_template.case3-ec2-temp.id
        version = "$Latest"
    }
    target_group_arns    = [aws_lb_target_group.case3-tg.arn]
    tag {
        key                 = "Name"
        value               = "case3-asg-instance"
        propagate_at_launch = true
    }
    health_check_type         = "EC2"
    health_check_grace_period = 60  
}

resource "aws_lb" "case3-lb" {
    name               = "case3-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.case3-public-lb.id]
    subnets            = aws_subnet.case3-public-subnet[*].id

    tags = {
      Name = "case3-lb"
    }

}
resource "aws_lb_target_group" "case3-tg" {
    name     = "case3-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.case3-vpc.id

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
      Name = "case3-tg"
    } 
  
}
resource "aws_lb_listener" "case3-lb-listener" {
    load_balancer_arn = aws_lb.case3-lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.case3-tg.arn
    }
  
}

resource "aws_autoscaling_policy" "scale_out_cpu" {
    name = "cpuout"
    autoscaling_group_name = aws_autoscaling_group.case3-asg.name
    policy_type = "TargetTrackingScaling"
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
    
}

resource "aws_iam_instance_profile" "case3-iam-instance-profile" {
  name = "case3-iam-instance-profile"
  role = aws_iam_role.case3-ec2-iam-role.name
}
resource "aws_iam_role" "case3-ec2-iam-role" {
    name = "case3-ec2-iam-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        },
        ]
    })
  
}
resource "aws_iam_role_policy_attachment" "case3-attach-policy" {
    role       = aws_iam_role.case3-ec2-iam-role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}