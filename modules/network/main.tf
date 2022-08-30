# declaring all avaialability zones in AWS available
data "aws_availability_zones" "available-zones" {
  state = "available"
}

# create vpc
resource "aws_vpc" "awe-vpc" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support

  tags = {
    Name = var.resource_tag
  }
}

# create dhcp options
resource "aws_vpc_dhcp_options" "awe-dhcp-option" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = var.resource_tag
  }
}

# associate dhcp options
resource "aws_vpc_dhcp_options_association" "awe-dns_resolver" {
  vpc_id          = aws_vpc.awe-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.awe-dhcp-option.id
}

# create subnet
resource "aws_subnet" "awe-subnet" {
  vpc_id                  = aws_vpc.awe-vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = var.resource_tag
  }
}


# create internet gateway and attach to vpc
resource "aws_internet_gateway" "awe-ig" {
  vpc_id = aws_vpc.awe-vpc.id
  tags = {
    Name = var.resource_tag
  }
}


# create route table
resource "aws_route_table" "awe-rtb" {
  vpc_id = aws_vpc.awe-vpc.id

  tags = {
    Name = var.resource_tag
  }
}

# create route for internet gateway
resource "aws_route" "awe-internet-gateway" {
  route_table_id         = "${aws_route_table.awe-rtb.id}"
  destination_cidr_block = var.all_ips
  gateway_id             = "${aws_internet_gateway.awe-ig.id}"
  depends_on             = [aws_route_table.awe-rtb]
}


# associate subnet to the route table
resource "aws_route_table_association" "awe-association" {
  subnet_id      = aws_subnet.awe-subnet.id
  route_table_id = aws_route_table.awe-rtb.id
}


/////////////////////////////////////////////////////////////////////////


////////////////////////  SECURITY GROUPS ////////////////////////

resource "aws_security_group" "awe-sg" {
  name        = "awe-sg"
  vpc_id      = aws_vpc.awe-vpc.id
  description = "Creating Inbound Traffic"

  # Create Inbound traffic for SSH from anywhere (Do not do this in production. Limit access ONLY to IPs or CIDR that MUST connect)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all_ips]
  }

  # Create ICMP ingress for all types
  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.all_ips]
  }

  # Create inbound traffic to port 10250

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.all_ips]
  }


  # Create Inbound traffic for kafka consumer and producer
  ingress {
    description = "for kafka producer and  consumer"
    from_port   = 9092
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr]
  }

  
///////////////////////////////

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ips]
  }

  tags = {
    Name = var.resource_tag
  }
}