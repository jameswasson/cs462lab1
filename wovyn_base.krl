ruleset wovyn_base {
  meta {
    // use module use_twilio_module alias twilio
    shares __testing
  }
  global {
    temperature_threshold = 80
    __testing = { "queries":
      [ { "name": "__testing" }
      ] , "events":
      [
        { "domain": "woven", "type":"process_heartbeat"},
        { "domain": "woven", "type":"new_temperature_reading", "attrs": [ "temperature", "timestamp" ]}
      ]
    }
  }
  rule process_heartbeat {
      select when woven process_heartbeat
      pre{
        all_things = event:attrs
        generic_thing = event:attr("genericThing")
        data = generic_thing["data"]
        temperature = data["temperature"]
        temperatureF = temperature[0]["temperatureF"].klog()
        status = generic_thing => "good" | "bad"
      }
      /*
      if status == "good" then
         send_directive("my_directive", {"message_info":{"temperatureF":temperatureF, "status":status}});
        /*/
        fired{
          raise woven event "new_temperature_reading" attributes {
            "temperature" : temperatureF,
            "timestamp" : time:now()
          } if status == "good"
        }
        //*/
    }
    
    rule find_high_temps {
      select when woven new_temperature_reading
      pre{
        temperature = event:attr("temperature").klog()
        timestamp = event:attr("timestamp")
        exceeds_threshold = (temperature.as("Number") > temperature_threshold).klog()
        message = exceeds_threshold => "It is too hot" | "It is just right"
      }
        send_directive("my_directive", {"message":message})
      always {
          raise woven event "threshold_violation" attributes {
            "message":message
          }
            if exceeds_threshold
      }
    }
    
    rule threshold_notification {
      select when woven threshold_violation
      always {
          raise test event "new_message_easy" attributes {
            "message" : event:attr("message"),
          }
      }
    }
}
