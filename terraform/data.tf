data "aws_ami" "ami_info" {
  most_recent = true
  owners      = ["973714476881"] # Amazon Linux AMI Owner ID

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}