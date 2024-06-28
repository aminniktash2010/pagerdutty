variable "business_services" {
  description = "List of business services to be created in PagerDuty"
  type = list(object({
    name = string
  }))
}



variable "services" {
  description = "List of services to be created"
  type = map(object({
    customer_name               = string
    product_name                = string
    service_id                  = string
    match_summary               = string
    match_source                = string
    business_service_name       = string
  }))
}
