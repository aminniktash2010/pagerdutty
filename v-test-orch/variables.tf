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
