variable "pagerduty_token" {
  description = "PagerDuty Api Access token"
  type = string
  sensitive  = true
}

variable "integrations" {
  description = "PagerDuty Event Orchestration Integration"
  type =  list(object({
    event_orchestration = string  # ID of the Event Orchestration
    label = string
  }))
}

variable "priorities" {
  description = "PagerDuty RuleSet Priority"
  type = set(string)
  default = ["P1", "P2", "P3", "P4", "P5"]
}

variable "orchestrations" {
  description = "PagerDuty Event Orchestrations"
  type =  list(object({
    name = string
    team = optional(string)
    description = optional(string)
  }))
}
variable "service_route" {
  type = list(object({
    label      = string
    conditions = list(object({
      expression = string
    }))
  }))
  description = "List of service routes with conditions"
}
variable "service_orchestrations" {
  type = list(object({
    service_name = string
    rules = list(object({
      label = string
      condition = string
      severity = string
      annotate = string
      suspend = bool
      automation_actions = list(object({
        name = string
        url = string
        auto_send = bool
        parameters = list(object({
          key = string
          value = string
        }))
        headers = list(object({
          key = string
          value = string
        }))
      }))
    }))
  }))
  description = "List of service orchestrations with rules and actions"
}

