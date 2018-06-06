resource "aws_vpc" "vpc" {
  cidr_block = "10.11.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "psn" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "10.11.${count.index}.0/24"
  availability_zone = "${element(var.availability_zones, count.index)}"
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = "${length(var.availability_zones)}"
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id      = "${element(aws_subnet.psn.*.id, count.index)}"
}
