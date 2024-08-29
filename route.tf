resource "pagerduty_event_orchestration_router" "router" {
  event_orchestration = pagerduty_event_orchestration.orchestration.id

  set {
    id = "start"

    dynamic "rule" {
      for_each = local.unique_services

      content {
        label = "Route for ${rule.value.customer_name}-${rule.value.product_name}-${rule.value.service_id}"

        dynamic "condition" {
          for_each = rule.value.conditions

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
