
data "hcloud_image" "unix_img" {
  name               = "${var.unix_distro}"
  with_architecture  = var.image_architecture
  most_recent        = true
  with_status        = "available"
  include_deprecated = false
}