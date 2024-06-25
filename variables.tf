variable "services" {
  description = "List of services to be created"
  type = map(object({
    customer_name               = string
    product_name                = string
    service_id                  = string
    match_summary               = string
    match_source                = string
  }))
}
