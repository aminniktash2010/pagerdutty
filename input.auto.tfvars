business_services = [
  {
    name = "TBS1"
    used_by    = ["TBS2", "TBS3"]
    using_on = []
  },
  {
    name = "TBS2"
    used_by    = []
    using_on = []
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
    match_summary         = ".*ServiceA.*"
    match_source          = "sourceA.*"   
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
    additional_conditions = []
    used_by               = ["TBS2"]
    using_on            = ["TBS1"]
  },
  {
    customer_name         = "Customerc"
    product_name          = "Productc"
    service_id            = "Servicec"
    match_summary         = ".*ServiceB.*"
    match_source          = "sourceB.*"
    additional_conditions = []
    used_by               = ["TBS2"]
    using_on            = ["TBS1"]
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
