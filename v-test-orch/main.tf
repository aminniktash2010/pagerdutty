locals {
  orchestration_ids = { for k, v in pagerduty_event_orchestration.orchestration : k => v.id }
  prioritiy_ids = { for k, v  in data.pagerduty_priority.priority : k => v.id }
}

data "pagerduty_priority" "priority" {
  for_each = var.priorities

  name =  each.value
}

resource "pagerduty_event_orchestration" "orchestration" {
  for_each = { for orch in var.orchestrations : orch.name => orch }

  name        = each.value.name
  team        = each.value.team
  description = each.value.description
}

resource "pagerduty_event_orchestration_integration" "integration" {
  for_each = { for integ in var.integrations : integ.label => integ }

  label               = each.value.label
  event_orchestration = lookup(local.orchestration_ids, each.value.event_orchestration, null)
}


resource "pagerduty_event_orchestration_router" "router" {
  event_orchestration = lookup(local.orchestration_ids, each.value.event_orchestration, null)

  set {
    id = "start"

    dynamic "rule" {
      for_each = { for integ in var.service_route : integ.label => integ }

      content {
        label = each.value.label

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
