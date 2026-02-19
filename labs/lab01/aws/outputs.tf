output "student_user_name" {
  value = aws_iam_user.student_user.name
}

output "student_user_access_key_id" {
  value = aws_iam_access_key.student_user.id
}

output "student_user_secret_access_key" {
  value     = aws_iam_access_key.student_user.secret
  sensitive = true
}
