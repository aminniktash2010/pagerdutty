
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


data "pagerduty_service" "services" {
  for_each = toset([for route in var.service_route : route.label])
  name     = each.key
}
resource "pagerduty_event_orchestration_router" "router" {
  for_each = local.orchestration_ids

  event_orchestration = each.value

  set {
    id = "start"
    dynamic "rule" {
      for_each = {
        for route in var.service_route :
        route.label => route if route.event_orchestration == each.key
      }
      content {
        label = rule.value.label
        dynamic "condition" {
          for_each = rule.value.conditions
          content {
            expression = condition.value.expression
          }
        }
        actions {
          route_to = data.pagerduty_service.services[rule.value.label].id
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
resource "pagerduty_event_orchestration_service" "service_orchestration" {

  for_each = {
    for orch in var.service_orchestrations :
    "${orch.event_orchestration}-${orch.service_name}" => orch
  }


  service = data.pagerduty_service.services[each.value.service_name].id
  enable_event_orchestration_for_service = true

  set {
    id = "start"
    dynamic "rule" {
      for_each = each.value.rules
      content {
        label = rule.value.label
        condition {
          expression = rule.value.condition
        }
        actions {
          dynamic "automation_action" {
            for_each = rule.value.automation_actions
            content {
              name = automation_action.value.name
              url = automation_action.value.url
              auto_send = automation_action.value.auto_send
              dynamic "parameter" {
                for_each = automation_action.value.parameters
                content {
                  key = parameter.key
                  value = tostring(parameter.value.value)
                }
              }
              dynamic "header" {
                for_each = automation_action.value.headers
                content {
                  key = header.key
                  value = tostring(header.value.value)
                }
              }
            }
          }
          severity = rule.value.severity
          annotate = rule.value.annotate
          suppress = rule.value.suppress 
          suspend  = rule.value.suspend
          priority = data.pagerduty_priority.priority[rule.value.priority].id
        }
      }
    }
  }

  catch_all {
    actions { }
  }
}
