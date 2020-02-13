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
}
