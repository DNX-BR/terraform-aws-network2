resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.public.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-ACL-Public"
      "Scheme"  = "public"
      "EnvName" = var.name
    }
  )
}

###########
# EGRESS
###########

# resource "aws_network_acl_rule" "out_public_local" {
#   network_acl_id = aws_network_acl.public.id
#   rule_number    = 1
#   egress         = true
#   protocol       = -1
#   rule_action    = "allow"
#   cidr_block     = aws_vpc.default.cidr_block
#   from_port      = 0
#   to_port        = 0
# }

resource "aws_network_acl_rule" "out_public_world" {
  count          = var.is_service_acccount ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

 resource "aws_network_acl_rule" "out_public_tcp_world" {
   count          = var.is_service_acccount ? 0 : 1
   network_acl_id = aws_network_acl.public.id
   rule_number    = 101
   egress         = true
   protocol       = "tcp"
   rule_action    = "allow"
   cidr_block     = "0.0.0.0/0"
   from_port      = 22
   to_port        = 65535
 }
 resource "aws_network_acl_rule" "out_public_udp_world" {
   count          = var.is_service_acccount ? 0 : 1
   network_acl_id = aws_network_acl.public.id
   rule_number    = 200
   egress         = true
   protocol       = "udp"
   rule_action    = "allow"
   cidr_block     = "0.0.0.0/0"
   from_port      = 22
   to_port        = 65535
 }

#  resource "aws_network_acl_rule" "out_public_tcp_range_world" {
#    count = var.is_service_acccount ? 0 : 1
#    network_acl_id = aws_network_acl.public.id
#    rule_number    = 300
#    egress         = true
#    protocol       = "tcp"
#    rule_action    = "allow"
#    cidr_block     = "0.0.0.0/0"
#    from_port      = var.public_nacl_out_tcp_port_range_from_private_subnet
#    to_port        = var.public_nacl_out_tcp_port_range_to_private_subnet
#  }
#  resource "aws_network_acl_rule" "out_public_udp_range_world" {
#    count = var.is_service_acccount ? 0 : 1
#    network_acl_id = aws_network_acl.public.id
#    rule_number    = 400
#    egress         = true
#    protocol       = "tcp"
#    rule_action    = "allow"
#    cidr_block     = "0.0.0.0/0"
#    from_port      = var.public_nacl_out_udp_port_range_from_private_subnet
#    to_port        = var.public_nacl_out_udp_port_range_to_private_subnet
#  }




###########
# INGRESS
###########

resource "aws_network_acl_rule" "in_public_local" {
  count = var.is_service_acccount ? 1 : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = 1
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_vpc.default.cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "in_public_tcp" {
  count          = length(var.public_nacl_inbound_tcp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.public_nacl_inbound_tcp_ports[count.index]
  to_port        = var.public_nacl_inbound_tcp_ports[count.index]
}

resource "aws_network_acl_rule" "in_public_tcp_return" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_public_udp" {
  count          = length(var.public_nacl_inbound_udp_ports)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 301
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_public_udp_return" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 401
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_public_icmp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 501
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_public_from_private" {
  count          = var.is_service_acccount ? length(aws_subnet.private.*.cidr_block) : 0
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 601
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 0
  to_port        = 0
}

locals {
  rules = distinct(flatten([
    for port in var.public_nacl_in_tcp_ports_private_subnet : [
      for subnet_cidr in aws_subnet.private.*.cidr_block : {
        port = port
        cird_block = subnet_cidr
      }
    ]
  ]))
}



resource "aws_network_acl_rule" "in_public_from_private_range_tcp" {
  count          = var.is_service_acccount ? 0 : length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 901
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 22
  to_port        = 65535
}

resource "aws_network_acl_rule" "in_public_from_private_range_udp" {
  count          = var.is_service_acccount ? 0 : length(aws_subnet.private.*.cidr_block)
  network_acl_id = aws_network_acl.public.id
  rule_number    = count.index + 1001
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = 22
  to_port        = 65535
}  