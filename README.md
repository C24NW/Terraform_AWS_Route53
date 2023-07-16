# Terraform_AWS_Route53

Terraform AWS Route 53 Training Project \
 -creates aws vpc to contain resources \
 -creates subnet in vpc \
 -creates internet gateway that will create public subnet \
 -creates route table \
 -associates route table with subnet \
 -creates security group to control traffic access to vm's \
 -creates ingress security group rules for HTTPS, HTTP and SSH \
 -creates egress security group rule for all outgoing traffic \
 -creates route 53 zone and associates with vpc \
 -creates two a records for ipv4 to domain name mapping \
 -creates two instances and adds to subnet and security group \
 -creates two elastic ip's and associates with instances \
 -uses two scripts to install apache and a html web page on the instances 
