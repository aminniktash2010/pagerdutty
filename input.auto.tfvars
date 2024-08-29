business_services = [
  {
    name = "TBS1"
    used_by    = []
    using_on = []
  },
  {
    name = "TBS2"
    used_by    = []
    using_on = ["TBS3", "TBS1"]
  },
  {
    name = "TBS3"
    used_by    = []
    using_on = []
  }
]

services = [
  {
    customer_name         = "CustomerA"
    product_name          = "ProductA"
    service_id            = "ServiceA"
    used_by               = ["TBS2", "TBS3"]
    using_on              = ["TBS1"]
    conditions = [
  {
    expression = "event.summary matches part '.*critical.*' and event.summary matches part 'region'"
  },
  ]
  },
  {
    customer_name         = "CustomerB"
    product_name          = "ProductB"
    service_id            = "ServiceB"
    used_by               = ["TBS2"]
    using_on            = ["TBS1"]
    conditions = [
  {
    expression = "event.summary matches part  '.*critical.*'"
  },
  {
    expression = "event.source matches part  'production.*'"
  }
  
]
  
  },
  {
    customer_name         = "Customerc"
    product_name          = "Productc"
    service_id            = "Servicec"
    match_summary         = ".*ServiceB.*"
    match_source          = "sourceB.*"
    used_by               = []
    using_on              = []
    conditions = [
  {
    expression = "event.summary matches part  '.*critical.*'"
  },
  {
    expression = "event.source matches part  'production.*'"
  }
]
  }
]


#####################################################
team  = "TechOps"
#####################################################
escalation_policy = {
  name     = "My Lab E Policy"
  schedule = "My Lab On-Call Schedule"
}

first_escalation_user     = "oncall-email@pg-dev.com"
second_escalation_user    = "oncall-email@pg-dev.com"

##################################################################
schedule = {
  name        = "My Lab On-Call Schedule"
  time_zone   = "America/New_York"
  description = "Primary on-call schedule for the team"
  usa_users       = ["oncall-email@pg-dev.com", "amin.niktash@varian.com"]
  india_users       = ["oncall-email@pg-dev.com", "amin.niktash@varian.com"]
}


#######################################################

event_orchestration = {
  name = "My Lab Event Orchestration"
}
