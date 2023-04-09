# resource "hcloud_firewall" "main" {
#   name = "main-firewall"
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "80"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "22"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
#   rule {
#     direction = "in"
#     protocol  = "tcp"
#     port      = "443"
#     source_ips = [
#       "0.0.0.0/0",
#       "::/0"
#     ]
#   }
# }

# resource "hcloud_firewall_attachment" "main" {
#   firewall_id = hcloud_firewall.main.id
#   server_ids  = [hcloud_server.main.id]
# }