ruleset manage_sensors {
    meta {
      use module io.picolabs.wrangler alias wrangler
      shares __testing, sensors
    }
    global {
      sensors = function(){
        ent:my_sensors.defaultsTo({})
      }
      __testing = { "queries":
        [ { "name": "__testing" }
         ,{ "name": "sensors" }
        ] , "events":
        [ { "domain": "sensor", "type": "new_sensor", "attrs": ["name"]}
        , { "domain": "sensor", "type": "new_sensor"}
        , { "domain": "sensor", "type": "unneeded_sensor", "attrs": ["name"]}
        ]
      }
      threshold = 90
    }
    
    rule add_child_info{
      select when wrangler child_initialized
      pre {
        parent = event:attr("parent")
        name = event:attr("name").klog("The name is: ")
        id = event:attr("id")
        eci = event:attr("eci")
        new_sensor = {"id": id, "eci": eci, "parent": parent}
      }
      event:send(
                 { "eci": eci, "eid": "",
                   "domain": "sensor", "type": "profile_updated",
                   "attrs": { "location":"unknown","name":name, "number":"13608449021","threshold":threshold } } )
      fired {
        ent:my_sensors := ent:my_sensors.defaultsTo({}).put(name, new_sensor)
      }
    }
    
    rule child_deletion{
      select when sensor unneeded_sensor
      pre {
        name = event:attr("name")
        exists = ent:my_sensors >< name
      }
      if exists then
        send_directive("deleting_section", {"name":name})
      fired{
        raise wrangler event "child_deletion"
          attributes {"name": name};
        clear ent:my_sensors{[name]}
      }
    }
    
    rule new_sensor {
      select when sensor new_sensor
      pre{
        name = event:attr("name").defaultsTo("")
        exists = ent:my_sensors >< name
      }
      fired {
        raise wrangler event "child_creation"
          attributes { "name": name
            , "color": "#ffff00"
            , "rids": ["temperature_store", "wovyn_base", "sensor_profile"]
          }
          if not exists
      }
    }
    
  }
  