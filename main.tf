terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "3.14.3"
    }
  }
}

provider "pagerduty" {
  token =  "u+-gy4yC2-MiWVUgmNTQ"
}

locals {
  unique_services = {
    for key, service in var.services :
    "${service.customer_name}-${service.product_name}-${service.service_id}" => service
  }

  unique_business_services = {
    for key, bs in var.business_services :
    bs.name => bs
  }
}

data "pagerduty_team" "team" {
  name = var.team
}

data "pagerduty_user" "usa_users" {
  for_each = toset(var.schedule.usa_users)
  email    = each.value
}

data "pagerduty_user" "india_users" {
  for_each = toset(var.schedule.india_users)
  email    = each.value
}

data "pagerduty_user" "first_escalation_user" {
  email = var.first_escalation_user
}

data "pagerduty_user" "second_escalation_user" {
  email = var.second_escalation_user
}

data "pagerduty_priority" "p1" {
  name = "P1"
}

resource "pagerduty_schedule" "schedule" {
  name        = var.schedule.name
  time_zone   = var.schedule.time_zone
  description = lookup(var.schedule, "description", null)

  layer {
    name         = "USA"
    start        = "2022-01-01T08:00:00Z"
    rotation_virtual_start = "2022-01-01T08:00:00Z"
    rotation_turn_length_seconds = 43200  # 12 hours

    users = [
      for user in data.pagerduty_user.usa_users : user.id
    ]
  }

  layer {
    name         = "India"
    start        = "2022-01-01T20:00:00Z"
    rotation_virtual_start = "2022-01-01T20:00:00Z"
    rotation_turn_length_seconds = 43200  # 12 hours

    users = [
      for user in data.pagerduty_user.india_users : user.id
    ]
  }
}



resource "pagerduty_escalation_policy" "policy" {
  name = var.escalation_policy.name
  teams = [data.pagerduty_team.team.id]
  rule {
    escalation_delay_in_minutes = 30

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.schedule.id
    }
  }
  rule {
    escalation_delay_in_minutes = 120

    target {
      type = "user_reference"
      id   = data.pagerduty_user.first_escalation_user.id
    }
  }
  rule {
    escalation_delay_in_minutes = 240

    target {
      type = "user_reference"
      id   = data.pagerduty_user.second_escalation_user.id
    }
  }
}






resource "pagerduty_event_orchestration" "orchestration" {
  name    = var.event_orchestration.name
  team    = data.pagerduty_team.team.id
}

resource "pagerduty_event_orchestration_router" "router" {
  event_orchestration = pagerduty_event_orchestration.orchestration.id

  set {
    id = "start"

    dynamic "rule" {
      for_each = local.unique_services

      content {
        label = "Route for ${rule.value.customer_name}-${rule.value.product_name}-${rule.value.service_id}"

        dynamic "condition" {
          for_each = concat([
            {
              expression = "event.summary matches part '${rule.value.match_summary}'"
            },
            {
              expression = "event.source matches regex '${rule.value.match_source}'"
            }
          ], rule.value.additional_conditions)

          content {
            expression = condition.value.expression
          }
        }

        actions {
          route_to = pagerduty_service.services[rule.key].id
        }
      }
    }
  }

  catch_all {
    actions {
      route_to = "unrouted"
    }
  }
}

resource "pagerduty_service" "services" {
  for_each = local.unique_services

  name                    = "svb-${each.value.customer_name}-${each.value.product_name}-${each.value.service_id}"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = pagerduty_escalation_policy.policy.id
}

resource "pagerduty_business_service" "bs" {
  for_each = {
    for bs in var.business_services : bs.name => bs
  }

  name = each.value.name
}

# Define secondary business services with the exact same name as the service
resource "pagerduty_business_service" "secondary_bs" {
  for_each = local.unique_services

  name = "${each.value.customer_name}-${each.value.product_name}-${each.value.service_id}"
}









resource "pagerduty_event_orchestration_global" "global" {
  event_orchestration = pagerduty_event_orchestration.orchestration.id

  set {
    id = "start"
    rule {
      label = "Always annotate a note to all events"
      actions {
        annotate = "This incident was created by the Database Team via a Global Orchestration"
        # Id of the next set
        route_to = "step-two"
      }
    }
  }

  set {
    id = "step-two"
    rule {
      label = "Drop events that are marked as no-op"
      condition {
        expression = "event.summary matches 'no-op'"
      }
      actions {
        drop_event = true
      }
    }
    rule {
      label = "If there's something wrong on the replica, then mark the alert as a warning"
      condition {
        expression = "event.custom_details.hostname matches part 'replica'"
      }
      actions {
        severity = "warning"
      }
    }
    rule {
      label = "Otherwise, set the incident to P1 and run a diagnostic"
      actions {
        priority = data.pagerduty_priority.p1.id
        automation_action {
          name = "db-diagnostic"
          url = "https://example.com/run-diagnostic"
          auto_send = true
        }
      }
    }
  }

  catch_all {
    actions { }
  }
}

