output "uat_vpc_id" {
  value = aws_vpc.uat.id
}
output "prod_vpc_id" {
  value = aws_vpc.prod.id
}
output "uat_subnets" {
  value = [aws_subnet.uat_app.id, aws_subnet.uat_db.id]
}
output "prod_subnets" {
  value = [aws_subnet.prod_app.id, aws_subnet.prod_db.id]
}
output "uat_app_instance_id" { value = aws_instance.uat_app.id }
output "uat_db_instance_id"  { value = aws_instance.uat_db.id }
output "prod_app_instance_id"{ value = aws_instance.prod_app.id }
output "prod_db_instance_id" { value = aws_instance.prod_db.id }
output "transit_gateway_id"  { value = aws_ec2_transit_gateway.tgw.id }
output "vpn_connection_id"   { value = aws_vpn_connection.tgw_vpn.id }
