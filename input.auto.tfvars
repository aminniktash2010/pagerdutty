business_services = [
  {
    name = "TBS1"
  },
  {
    name = "TBS2"
  }
]

services = [
  {
    customer_name         = "CustomerA"
    product_name          = "ProductA"
    service_id            = "ServiceA"
    match_summary         = ".*ServiceA.*"
    match_source          = "sourceA.*"
    business_service_name = "TBS1"
    additional_conditions = [
      { expression = "event.summary matches part  'high'" },
      { expression = "event.summary matches part  'critical'" }
    ]
    action = {
      name               = "CustomerA Script Action"
      description        = "Script Action for CustomerA Service"
      action_type        = "script"
      script             = "print(\"Hello from CustomerA Service!\")"
      invocation_command = "/usr/local/bin/python3"
    }
  },
  {
    customer_name         = "CustomerB"
    product_name          = "ProductB"
    service_id            = "ServiceB"
    match_summary         = ".*ServiceB.*"
    match_source          = "sourceB.*"
    business_service_name = "TBS2"
    additional_conditions = []
  }
]


#####################################################
team  = "TechOps"
#####################################################
escalation_policy = {
  name     = "Primary Escalation Policy"
  schedule = "Primary On-Call Schedule"
}

first_escalation_user     = "oncall-email@pg-dev.com"
second_escalation_user    = "oncall-email@pg-dev.com"

##################################################################
schedule = {
  name        = "Primary On-Call Schedule"
  time_zone   = "America/New_York"
  description = "Primary on-call schedule for the team"
  usa_users       = ["oncall-email@pg-dev.com", "amin.niktash@varian.com"]
  india_users       = ["oncall-email@pg-dev.com", "amin.niktash@varian.com"]
}


#######################################################

event_orchestration = {
  name = "Primary Event Orchestration"
}
