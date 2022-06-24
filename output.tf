output "fs_id" {
  value = aws_efs_file_system.storage.*.id
}

output "access_point_id" {
  value = aws_efs_access_point.default_access_point.*.id
}