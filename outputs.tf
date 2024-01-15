output "instance_ids" {
  value = aws_instance.test_instance.*.id
}
