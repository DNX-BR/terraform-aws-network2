locals {
  nat_quantity = var.multi_nat ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 1
}

resource "aws_eip" "nat_eip" {
  count = var.create_nat ? var.byoip ? 0 : local.nat_quantity : 0
  vpc   = true

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-EIP-${count.index}"
      "EnvName" = var.name
    },
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.create_nat ? local.nat_quantity : 0
  allocation_id = var.byoip ? var.eip_allocation_ids[count.index] : aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-NATGW-${count.index}"
      "EnvName" = var.name
    },
  )
}
