terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "3.14.3"
    }
  }
}

provider "pagerduty" {
  token = "var.pd-pagerduty_token"
}

resource "pagerduty_maintenance_window" "example" {
  count      = var.weeks
  start_time = timeadd(var.start_date, "${count.index * 7 * 24 * 60 * 60}s")
  end_time   = timeadd(timeadd(var.start_date, "${count.index * 7 * 24 * 60 * 60}s"), "2h")

  services    = [data.pagerduty_service.t-services.id]
}




data "pagerduty_service" "t-services" {
  name = var.service_name
}

variable "service_name" {
  description = "List of PagerDuty service IDs"
  type        = string
}

variable "weeks" {
  description = "Number of weeks for the maintenance window recurrence"
  type        = number
  default     = 5
}
variable "start_date" {
  description = "Fixed start date for the maintenance window (format: YYYY-MM-DDTHH:MM:SSZ)"
  type        = string
  default     = "2024-07-23T20:00:00Z"
}
