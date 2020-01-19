ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley" // being used by James Wasson
    logging on
    shares hello
  }
   
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
  }
   
  rule hello_world {
    select when echo hello
    send_directive("say", {"something": "Hello World"})
  }
  
  rule hello_monkey {
    select when echo monkey
  pre {
    name = event:attr("name").klog("our passed in name: ").defaultsTo("Monkey")
  }
  send_directive("say", {"something":"Hello " + name})
  }
  
  rule hello_mmonkey {
    select when echo mmonkey
  pre {
    name = event:attr("name").klog("our passed in name: ") || "Monkey"
  }
  send_directive("say", {"something":"Hello " + name})
  }
}