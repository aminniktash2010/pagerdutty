terraform {
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "3.14.3"
    }
  }
}

provider "pagerduty" {
  token =  #var.pagerduty_api_token
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

data "pagerduty_event_orchestrations" "ev-orch" {
  name_filter = "TechOps-event_orchestration"
}
data "pagerduty_escalation_policy" "es" {
  name = "TechOps"
}



resource "pagerduty_business_service" "bs" {
  for_each = local.unique_business_services

  name = each.value.name
}



resource "pagerduty_service" "services" {
  for_each = local.unique_services

  name                    = "${each.value.customer_name}-${each.value.product_name}-${each.value.service_id}"
  auto_resolve_timeout    = 14400
  acknowledgement_timeout = 600
  escalation_policy       = data.pagerduty_escalation_policy.es.id
  #business_service        = pagerduty_business_service.bs[each.value.business_service_name].id
}



resource "pagerduty_event_orchestration_router" "router" {
  event_orchestration = data.pagerduty_event_orchestrations.ev-orch.event_orchestrations[0].id

  set {
    id = "start"

    dynamic "rule" {
      for_each = local.unique_services

      content {
        label = "Route for ${rule.value.customer_name}-${rule.value.product_name}-${rule.value.service_id}"

        dynamic "condition" {
          for_each = [
            {
              expression = "event.summary matches part '${rule.value.match_summary}'"
            },
            {
              expression = "event.source matches regex '${rule.value.match_source}'"
            }
          ]

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

resource "pagerduty_service_dependency" "dependencies" {
  for_each = local.unique_services

  dependency {
    dependent_service {
      id   = pagerduty_business_service.bs[each.value.business_service_name].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.services[each.key].id
      type = "service"
    }
  }
}
