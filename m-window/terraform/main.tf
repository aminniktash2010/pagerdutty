terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "3.14.3"
    }
  }
}

provider "pagerduty" {
  token = var.pd-pagerduty_token
}




data "pagerduty_service" "t-services" {
  name = var.service_name
}

variable "pd-pagerduty_token" {
  description = "please provide your tocken"
  type  = string
}
variable "service_name" {
  description = "List of PagerDuty service IDs"
  type        = string
}
##########################################

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

variable "duration" {
  description = "Duration of each maintenance window (format: 2h, 30m, etc.)"
  type        = string
  default     = "2h"
}

resource "pagerduty_maintenance_window" "example" {
  count      = var.weeks
  start_time = timeadd(var.start_date, "${count.index * 7 * 24 * 60 * 60}s")
  end_time   = timeadd(timeadd(var.start_date, "${count.index * 7 * 24 * 60 * 60}s"), var.duration)
  services   = [data.pagerduty_service.t-services.id]
}
