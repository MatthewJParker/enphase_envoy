-- require st provided libraries
local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local log = require "log"

-- require custom handlers from driver package
local command_handlers = require "command_handlers"
local envoy = require "envoy"
local discovery = require "discovery"
local envoymode = capabilities["wanderdream36822.envoyModeV10"]
local lastupdate = capabilities["wanderdream36822.lastUpdate"]
--local lastupdate = capabilities["legendabsolute60149.signalMetrics"]

-----------------------------------------------------------------
-- local functions
-----------------------------------------------------------------
-- this is called once a device is added by the cloud and synchronized down to the hub
local function device_added(driver, device)
  log.info("[" .. device.id .. "] Adding new Envoy device")

  -- set a default or queried state for each capability attribute
  device:emit_event(capabilities.switch.switch.off())
end

-- this is called both when a device is added (but after `added`) and after a hub reboots.
local function device_init(driver, device)
  log.info("[" .. device.id .. "] Initializing Envoy device")
  command_handlers.do_Preferences(driver, device)
  driver:call_on_schedule(20, function() command_handlers.poll(device, false) end, "envoy_refresh")

  -- mark device as online so it can be controlled from the app
  device:online()
end

local function do_refresh(driver, device)
  log.debug("Refresh")
 -- device:emit_event(envoymode.envoymode({value="Producing"}))
  device:emit_event(lastupdate.lastupdate({value="Yes"}))
--  device:emit_event(sm.signalMetrics({value = "wow"}, {visibility = {displayed = visible_satate }}))
end

-- this is called when a device is removed by the cloud and synchronized down to the hub
local function device_removed(driver, device, cmd)
  log.info("[" .. device.id .. "] Removing Envoy device")
end

-- create the driver object
local envoy_driver = Driver("envoy", {
  discovery = discovery.handle_discovery,
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
    removed = device_removed,
    infoChanged = command_handlers.do_Preferences
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = command_handlers.switch_on,
      [capabilities.switch.commands.off.NAME] = command_handlers.switch_off,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = command_handlers.do_refresh,
    }
  }
})

-- Call on schedule
--envoy_driver:call_on_schedule(20, function() log.info("This is an example timer that runs every five seconds") end, "test_timer")

-- run the driver
envoy_driver:run()
