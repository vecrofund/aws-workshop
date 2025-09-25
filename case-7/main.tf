resource "aws_kms_key" "key1" {
    description = "my key1"
  
}
resource "aws_kms_alias" "key1-alias" {
    name          = "alias/key1"
    target_key_id = aws_kms_key.key1.key_id  
}

resource "aws_secretsmanager_secret" "topsecret1" {
    name        = "topsecret1"
    description = "My secret description"
    kms_key_id  = aws_kms_key.key1.key_id
    # secret_string = "my_secret_value"
}

data "aws_iam_policy_document" "example" {
  statement {
    sid    = "DenyGetSecretValue"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::619512840514:root"]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.topsecret1.arn
  policy     = data.aws_iam_policy_document.example.json
}