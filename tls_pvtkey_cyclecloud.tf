resource "tls_private_key" "vm_cc" {
  algorithm = "RSA"
  rsa_bits  = 2048 # Limiting to 2048 since the vm AVM throws error for 4096 and for ED25519
}