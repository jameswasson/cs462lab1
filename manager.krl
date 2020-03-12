ruleset manage_sensors {
    meta {
      use module io.picolabs.wrangler alias wrangler
      use module io.picolabs.subscription alias subscription
      shares __testing, sensors, get_temperatures, subs
    }
    global {
      sensors = function(){
        ent:my_sensors.defaultsTo({}) 
      }
      subs = function(){
        ent:subs.defaultsTo({})
      }
      flt = function(a,v){a.append(v)};
      get_temperatures = function(){
        ent:subs.defaultsTo({}).map(
          function(x){
            wrangler:skyQuery(x["Tx"],"temperature_store","temperatures")
        }).values().reduce(flt,[])
      }
      __testing = { "queries":
        [ { "name": "__testing" }
         ,{ "name": "sensors" }
         ,{ "name": "subs" }
         ,{ "name": "get_temperatures" }
        ] , "events":
        [ { "domain": "sensor", "type": "new_sensor", "attrs": ["name"]}
        , { "domain": "sensor", "type": "new_sensor"}
        , { "domain": "sensor", "type": "unneeded_sensor", "attrs": ["name"]}
        ]
      }
      threshold = 90
    }
    
    rule newSubAdded {
      select when wrangler subscription_added
      pre {
        subID = event:attr("Id")                // The ID of the subscription is given as an attribute
        subInfo = event:attr("bus")             // The relevant subscription info is given in the "bus" attribute
        subName = event:attr("name")
      }
      always {
        ent:subs := ent:subs.defaultsTo({}).put(subName, subInfo)
      }
    }
    
    rule add_child_info{
      select when wrangler child_initialized
      pre {
        parent = event:attr("parent")
        name = event:attr("name").klog("The name is: ")
        id = event:attr("id")
        eci = event:attr("eci")
        new_sensor = {"id": id, "eci": eci, "parent": parent}
        wellKnown_Rx = subscription:wellKnown_Rx()["id"]
        wellKnown_Tx = wrangler:skyQuery(eci, "io.picolabs.subscription", "wellKnown_Rx")["id"].klog("I got the wellknown and it is: ")
      }
      event:send(
                 { "eci": eci, "eid": "",
                   "domain": "sensor", "type": "profile_updated",
                   "attrs": { "location":"unknown","name":name, "number":"13608449021","threshold":threshold } } )
      fired {
        ent:my_sensors := ent:my_sensors.defaultsTo({}).put(name, new_sensor)
        raise wrangler event "subscription" attributes {
          "name":name,
          "wellKnown_Tx":wellKnown_Tx
        }
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
        clear ent:subs{[name]}
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
  