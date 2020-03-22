ruleset temperature_store {
    meta {
      shares __testing, temperatures, threshold_violations, inrange_temperatures
      provides          temperatures, threshold_violations, inrange_temperatures
    }
    global {
      __testing = { "queries":
        [ { "name": "__testing" }
        , { "name": "temperatures", "args": [] }
        , { "name": "threshold_violations", "args": [] }
        , { "name": "inrange_temperatures", "args": [] }
        ] , "events":
        [ { "domain": "woven", "type":"new_temperature_reading", "attrs": [ "temperature", "timestamp" ]}
        , { "domain": "woven", "type": "threshold_violation", "attrs": [ "message", "temperature", "timestamp" ] }
        , { "domain": "sensor", "type": "reading_reset"}
        ]
      }
      temperatures  = function() {
       ent:temperatures.defaultsTo([])
      }
      threshold_violations  = function() {
       ent:violations.defaultsTo([])
      }
      inrange_temperatures   = function() {
        ent:temperatures.defaultsTo([]).difference(ent:violations.defaultsTo([]))
      }
    }
    rule request_temperatures{
      select when temperature_store requestTemperature
      pre{
        rcn = event:attr("rcn")
        eci = event:attr("eci")
        return_domain = event:attr("return_domain")
        return_type = event:attr("return_type")
        subscription_map =
         {
          "eci":eci,
          "domain":return_domain,
          "type":return_type,
          "attrs":
            {
              "rcn":rcn,
              "temperatures":ent:temperatures.defaultsTo([])
            }
         }
      }
      event:send(subscription_map)
    }
    rule collect_temperatures {
      select when woven new_temperature_reading
      pre{
        temperature = event:attr("temperature").klog("collect_temperatures got: ")
        timestamp = event:attr("timestamp")
      }
      always{
        ent:temperatures:= ent:temperatures.defaultsTo([]).append({"temperature":temperature,"timestamp":timestamp})
      }
    }
    rule collect_threshold_violations  {
      select when woven threshold_violation
      pre{
        temperature = event:attr("temperature").klog("threshold_violation got: ")
        timestamp = event:attr("timestamp")
      }
      always{
        ent:violations:= ent:violations.defaultsTo([]).append({"temperature":temperature,"timestamp":timestamp})
      }
    }
    rule clear_temeratures {
      select when sensor reading_reset
      always{
        ent:temperatures:= []
        ent:violations:= []
      }
    }
    //Accep all subscription requests
    rule autoAcceptSubscriptions {
      select when wrangler inbound_pending_subscription_added
      pre{
        rand_temp = random:integer(50)
        rand_time = random:integer(50)
      }
      always {
        raise wrangler event "pending_subscription_approval" attributes event:attrs;
        raise woven event "new_temperature_reading" attributes {
          "temperature":rand_temp,
          "timestamp":rand_time
        }
      }
    }
  }
  