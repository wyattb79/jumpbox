locals {
  bucket_name = element(split("/", var.s3_pem_path), 2)
}
