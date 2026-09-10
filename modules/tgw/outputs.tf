output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_route_table_id" {
  description = "ID of the Transit Gateway route table"
  value       = aws_ec2_transit_gateway_route_table.this.id
}

output "bastion_attachment_id" {
  description = "Transit Gateway attachment ID for the bastion VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.bastion.id
}

output "app_attachment_id" {
  description = "Transit Gateway attachment ID for the app VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.app.id
}
