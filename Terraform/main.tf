data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
}
        owners = ["099720109477"]
}

resource "aws_instance" "instance_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "for_ansible"
  security_groups = ["second_security"]
  tags = {
    Name = "instance_1"
  }
}

resource "aws_security_group" "second_security" {
  name        = "second_security"
  description = "security group for terraform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
    Name = "second_security"
  }
}

resource "aws_autoscaling_group" "asg_1" {
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  max_size           = 4
  min_size           = 2
  load_balancers = [aws_elb.raj_terra.id]
  launch_configuration = aws_launch_configuration.launch_conf.id

  lifecycle {
      create_before_destroy = true
  }
}

resource "aws_elb" "raj_terra" {
  name               = "raj"
  availability_zones = ["eu-central-1a", "eu-central-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.instance_1.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "instance_2"
  }
}

resource "aws_launch_configuration" "launch_conf" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "for_ansible"
  security_groups = ["second_security"]
  user_data = filebase64("raj.sh")

  lifecycle {
      create_before_destroy = true
  }
}