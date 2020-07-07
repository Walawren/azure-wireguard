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
