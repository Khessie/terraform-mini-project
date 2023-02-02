#defining the provider

provider "aws" {
  region     = var.aws-region
  access_key = var.access_key
  secret_key = var.secret_key
}

#creating the ec2 instances

resource "aws_instance" "server1" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  key_name          = "serverKey"
  security_groups   = [aws_security_group.sg-rule.id]
  subnet_id         = aws_subnet.public_subnet1.id
  availability_zone = "eu-west-2a"

  tags = {
    Name = "server1"
  }
}

resource "aws_instance" "server2" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  security_groups   = [aws_security_group.sg-rule.id]
  subnet_id         = aws_subnet.public_subnet2.id
  availability_zone = "eu-west-2b"
  key_name          = "serverKey"

  tags = {
    Name = "server2"
  }
}

resource "aws_instance" "server3" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  security_groups   = [aws_security_group.sg-rule.id]
  subnet_id         = aws_subnet.public_subnet2.id
  availability_zone = "eu-west-2b"
  key_name          = "serverKey"

  tags = {
    Name = "server3"
  }
}



#creating the vpc1 vpc
resource "aws_vpc" "vpc1" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "vpc1"
  }
}

#creating a security group for the load balancer

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group to allow port 22, 80 and 443

resource "aws_security_group" "sg-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.vpc1.id
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "sg-rule"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "internet_gateway"
  }
}



#creating a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "public_rt"
  }
}

#associating two public subnets to the pubic route table

resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

#creating two public subnets

resource "aws_subnet" "public_subnet1" {

  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {

  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"
  tags = {
    Name = "public_subnet2"
  }
}

#configuring the network acl to control traffic

resource "aws_network_acl" "network-acl" {
  vpc_id     = aws_vpc.vpc1.id
  subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "network-acl"
  }
}

#creating a file to store ip addresses of the ec2 instances

resource "local_file" "Ip_address" {
  filename = "/Desktop/assignment/host-inventory"
  content  = <<EOT
${aws_instance.server1.public_ip}
${aws_instance.server2.public_ip}
${aws_instance.server3.public_ip}
  EOT
}


#creating ALB

resource "aws_lb" "load-balancer" {
  name                       = "load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.load_balancer_sg.id]
  subnets                    = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  enable_deletion_protection = false
  depends_on                 = [aws_instance.server1, aws_instance.server2, aws_instance.server3]
}

#creating the target group
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc1.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

#creating a listener

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

#creating the listener rule

resource "aws_lb_listener_rule" "lb_listener_rule" {
  listener_arn = aws_lb_listener.lb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

}

#attaching target group to lb
resource "aws_lb_target_group_attachment" "tg-attach1" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg-attach2" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.server2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg-attach3" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.server3.id
  port             = 80
}
