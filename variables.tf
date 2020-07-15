variable "wg_server_cidr" {
  type        = string
  description = "The internal network to use for WireGuard. Remember to place the clients in the same subnet."
  default     = "10.1.3.0/24"
}

variable "wg_server_port" {
  type        = number
  description = "The port WireGuard should listen on."
  default     = 51820
}

variable "wg_server_name" {
  type        = string
  description = "Name of the network interface (e.g. 'wg0')"
  default     = "wg0"
}

variable "personal_vpn_tunnels" {
  type        = list(string)
  description = "Pascal cased names of tunnels"
  default = [
    "Pixel4",
    "WindowsLaptop"
  ]
}

variable "personal_vpn_tunnels" {
  type = list(object({
    name         = string
    email        = string
    phone_number = string
  }))
  description = "Pascal cased names of tunnels"
  default = [
    "Pixel4",
    "WindowsLaptop"
  ]
}

variable "dns_server" {
  type        = string
  description = "IP address for dns resolution"
  default     = "1.1.1.1"
}

variable "persistent_keep_alive" {
  type    = number
  default = 20
}
