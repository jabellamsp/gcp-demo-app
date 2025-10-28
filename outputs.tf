output "public_ip" {
  value = google_compute_address.static_ip.address
  description = "Public IP of the demo web server"
}

output "instance_name" {
  value = google_compute_instance.demo_vm.name
}
