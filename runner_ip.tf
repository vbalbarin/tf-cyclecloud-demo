data "http" "runner_ip" {
  count = length(var.remote_access_ip) > 0 ? 0 : 1
  url   = "https://ipecho.net/plain"
}
