variable "business_services" {
  description = "List of business services to be created in PagerDuty"
  type = list(object({
    name        = string
    used_by     = optional(list(string))
    using_on    = optional(list(string))
  }))
}

variable "services" {
  description = "List of services to be created in PagerDuty"
  type = list(object({
    customer_name         = string
    product_name          = string
    service_id            = string
    conditions    = list(object({
      expression = string
    }))
  }))
}

variable "team" {
  description = "Please defin what team is assign to the escalation_policy"
  type = string
}

variable "escalation_policy" {
  description = "Escalation policy details"
  type = object({
    name      = string
    schedule  = string
  })
}

variable "first_escalation_user" {
  description = "Email of the user to escalate to after 2H"
  type        = string
}
variable "second_escalation_user" {
  description = "Email of the user to escalate to after 4H"
  type        = string
}

variable "schedule" {
  description = "Schedule details"
  type = object({
    name        = string
    time_zone   = string
    description = optional(string)
    usa_users   = list(string)
    india_users = list(string)
  })
}


variable "event_orchestration" {
  description = "Event orchestration details"
  type = object({
    name = string
  })
}


