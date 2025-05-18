vpc = {
  map = {
    cidr = "10.0.0.0/16"
  }
}


ec2_instance= {
  ec2-vm = {
  instance_type         = "t3.micro"
  key_name               = "my-ec2-key"
 }
}