
# Creating 3 EC2 Instances:

resource "aws_instance" "instance" {
  count                = length(aws_subnet.public_subnet.*.id)
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = element(aws_subnet.public_subnet.*.id, count.index)
  security_groups      = [aws_security_group.sg.id, ]
  key_name             = "Task1-KP"
 # iam_instance_profile = data.aws_iam_role.iam_role.name

  tags = {
    "Name"        = "Task1-Instance-${count.index}"
    "Environment" = "Test"
  }

  timeouts {
    create = "10m"
  }

}

resource "null_resource" "null" {
  count = length(aws_subnet.public_subnet.*.id)

  provisioner "file" {
    source      = "./udata.sh"
    destination = "/home/ec2-user/udata.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/udata.sh",
      "sh /home/ec2-user/udata.sh",
    ]
    on_failure = continue
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    port        = "22"
    host        = element(aws_eip.eip.*.public_ip, count.index)
    private_key = file(var.ssh_private_key)
  }

}

# Creating 3 Elastic IPs:

resource "aws_eip" "eip" {
  count            = length(aws_instance.instance.*.id)
  instance         = element(aws_instance.instance.*.id, count.index)
  public_ipv4_pool = "amazon"
  vpc              = true

  tags = {
    "Name" = "Task1-EIP-${count.index}"
  }
}


# Creating EIP association with EC2 Instances:


resource "aws_eip_association" "eip_association" {
  count         = length(aws_eip.eip)
  instance_id   = element(aws_instance.instance.*.id, count.index)
  allocation_id = element(aws_eip.eip.*.id, count.index)
}