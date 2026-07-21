resource "aws_instance" "monitoring" {
  for_each               = toset(var.instances)
  ami                    = data.aws_ami.ami_info.id
  instance_type          = contains(["prometheus", "elk"], each.key) ? "t3.medium" : "t3.micro"
  key_name               = null
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = each.key == "prometheus" ? var.prometheus_iam_instance_profile : null
  tags = merge(
    { Name = each.key },
    contains(["node-1", "node-2"], each.key) ? { Monitoring = "true" } : {}
  )
}