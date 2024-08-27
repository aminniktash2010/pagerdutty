resource "pagerduty_service_dependency" "bs_using_bs" {
  for_each = {
    for pair in flatten([
      for bs_key, bs_value in local.unique_business_services :
      [for using_on in try(tolist(bs_value.using_on), []) : {
        bs_key   = bs_key
        using_on = using_on
      }]
    ]) : "${pair.bs_key}-${pair.using_on}" => pair
  }

  dependency {
    dependent_service {
      id   = pagerduty_business_service.bs[each.value.bs_key].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_business_service.bs[each.value.using_on].id
      type = "business_service"
    }
  }
}


resource "pagerduty_service_dependency" "bs_used_by_bs" {
  for_each = {
    for pair in flatten([
      for bs_key, bs_value in local.unique_business_services :
      [for used_by in try(tolist(bs_value.used_by), []) : {
        bs_key  = bs_key
        used_by = used_by
      }]
    ]) : "${pair.bs_key}-${pair.used_by}" => pair
  }

  dependency {
    dependent_service {
      id   = lookup(pagerduty_business_service.bs, each.value.used_by, null) != null ? pagerduty_business_service.bs[each.value.used_by].id : pagerduty_business_service.secondary_bs[each.value.used_by].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_business_service.bs[each.value.bs_key].id
      type = "business_service"
    }
  }
}


# Creating dependency  business_service for each technical service
resource "pagerduty_service_dependency" "secondary_bs_using_service" {
  for_each = local.unique_services

  dependency {
    dependent_service {
      id   = pagerduty_business_service.secondary_bs[each.key].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.services[each.key].id
      type = "service"
    }
  }
}

resource "pagerduty_service_dependency" "service_using_bs" {
  for_each = {
    for pair in flatten([
      for service_key, service_value in local.unique_services :
      [for using_on in try(tolist(service_value.using_on), []) : {
        service_key = service_key
        using_on    = using_on
      }]
    ]) : "${pair.service_key}-${pair.using_on}" => pair
  }

  dependency {
    dependent_service {
      id   = pagerduty_business_service.secondary_bs[each.value.service_key].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_business_service.bs[each.value.using_on].id
      type = "business_service"
    }
  }
}


resource "pagerduty_service_dependency" "service_used_by_bs" {
  for_each = {
    for pair in flatten([
      for service_key, service_value in local.unique_services :
      [for used_by in try(tolist(service_value.used_by), []) : {
        service_key = service_key
        used_by     = used_by
      }]
    ]) : "${pair.service_key}-${pair.used_by}" => pair
  }

  dependency {
    dependent_service {
      id   = pagerduty_business_service.bs[each.value.used_by].id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_business_service.secondary_bs[each.value.service_key].id
      type = "business_service"
    }
  }
}

