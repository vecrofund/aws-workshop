# output "key1prop" {
#     value = aws_kms_key.key1
  
# }
output "secret-id" {
    value = aws_secretsmanager_secret.topsecret1.id
  
}