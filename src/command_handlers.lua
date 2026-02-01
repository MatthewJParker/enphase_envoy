local log = require "log"
local capabilities = require "st.capabilities"
local st_utils = require "st.utils"

local command_handlers = {}

local envoy = capabilities["wanderdream36822.envoyEnphaseV7"]
local battery = capabilities["wanderdream36822.batteryCharge"]
local envoymode = capabilities["wanderdream36822.envoyModeV10"]
local lastupdate = capabilities["wanderdream36822.lastUpdate"]

local cosock = require "cosock"
local http = cosock.asyncify "socket.http"
local https = cosock.asyncify "ssl.https"
local json = require "dkjson"
local ltn12 = require "ltn12"
local refreshrate
local refreshcnt
local sc_stream = "disabled"
local key = ""

function fixenergy(energy)
    if energy < 0 then
        energy = 0
    end
    return(math.floor(energy/1000))
end

function calculateMode(importedenergy, exportedenergy, consumedenergy, producedenergy, dischargedenergy, chargedenergy)

    if (importedenergy < 100) then
        importedenergy = 0
    end
    if (exportedenergy < 100) then
        exportedenergy = 0
    end
    if (consumedenergy < 100) then
        consumedenergy = 0
    end
    if (producedenergy < 100) then
        producedenergy = 0
    end
    if (dischargedenergy < 100) then
        dischargedenergy = 0
    end
    if (chargedenergy < 100) then
        chargedenergy = 0
    end

    if producedenergy > 0 and exportedenergy > 0 and dischargedenergy == 0 then
        return 10, "Producing/Exporting"
    elseif producedenergy > 0 and chargedenergy > 0 then
        return 9, "Producing/Charging"
    elseif producedenergy > 0 and chargedenergy == 0 and importedenergy == 0 and dischargedenergy == 0 then
        return 8, "Producing"
    elseif producedenergy > 0 and dischargedenergy > 0 and importedenergy == 0 then
        return 7, "Producing/Discharging"
    elseif producedenergy == 0 and dischargedenergy > 0 and importedenergy == 0 then
        return 6, "Discharging"
    elseif producedenergy > 0 and dischargedenergy > 0 and importedenergy > 0 then
        return 5, "Producing/Discharging/Importing"
    elseif producedenergy > 0 and dischargedenergy == 0 and importedenergy > 0 then
        return 4, "Importing/Producing"
    elseif producedenergy == 0 and dischargedenergy > 0 and importedenergy > 0 then
        return 3, "Discharging/Importing"
    elseif producedenergy == 0 and dischargedenergy == 0 and importedenergy > 0 then
       return 2, "Importing"
    elseif dischargedenergy > 0 and exportedenergy > 0 then
        return 1, "Discharging/Exporting"
    else
       return 0, "Unknown"
    end
end

function command_handlers.poll(device, override)
    local obj = {}
    local streamobj= {}
    log.debug("Poll working")
    log.debug(refreshcnt)
    log.debug(refreshrate)
    if (refreshcnt < refreshrate and override == false) then
        log.debug("Not running routine")
        refreshcnt = refreshcnt + 1
        if (refreshcnt == 2 and refreshrate > 3) then
            log.debug("Turnoff stream")
            streamobj = envoyStream(device, false)
            sc_stream = streamobj.sc_stream
        end
        log.debug(sc_stream)
        return
    end

    refreshcnt = 1

    -- Poll Envoy for metering data
    log.debug("Just prior: " .. sc_stream)
    if (sc_stream == "enabled") then
        log.debug("Poll as it is enabled")
        obj = envoyPoll(device)
        sc_stream = obj.connection.sc_stream
    end

    -- great looking at fixing no streaming, maybe could add logic to repoll
    if (sc_stream == "disabled") then
        log.debug("Turnon stream")
        streamobj = envoyStream(device, true)
        sc_stream = streamobj.sc_stream
        log.debug(sc_stream)
        obj = envoyPoll(device)
    end
    log.debug("Time: " .. obj.meters.last_update)
    local lastupdatestr = converttimestamp(obj.meters.last_update)
    device:emit_event(lastupdate.lastupdate({value=lastupdatestr}))

    --    device:emit_event(lastupdated.signalMetrics({value = lastupdatestr}, {visibility = {displayed = visible_satate }}))
    local importedenergy = fixenergy(obj.meters.grid.agg_p_mw)
    --    local exportedenergy = fixenergy(obj.meters.load.agg_p_mw-obj.meters.pv.agg_p_mw-obj.meters.storage.agg_p_mw)
    local exportedenergy = fixenergy(-obj.meters.grid.agg_p_mw)
    local consumedenergy = fixenergy(obj.meters.load.agg_p_mw)
    local producedenergy = fixenergy(obj.meters.pv.agg_p_mw)
    local dischargedenergy = fixenergy(obj.meters.storage.agg_p_mw)
    local chargedenergy = fixenergy(-obj.meters.storage.agg_p_mw)

    local modeval, mode = calculateMode(importedenergy, exportedenergy, consumedenergy, producedenergy, dischargedenergy, chargedenergy)
    print(modeval)
    print(mode)
    device:emit_event(envoymode.envoymode({value=mode}))
    device:emit_event(envoymode.envoymodeno({value=modeval}))

    print("Stream", obj.connection.sc_stream)
    device:emit_event(battery.charge({value=math.floor(obj.meters.soc), unit="%"}))

    device:emit_event(envoy.importedenergy({value=importedenergy, unit="W"}))
    device:emit_event(envoy.exportedenergy({value=exportedenergy, unit="W"}))
    device:emit_event(envoy.consumedenergy({value=consumedenergy, unit="W"}))
    device:emit_event(envoy.producedenergy({value=producedenergy, unit="W"}))
    device:emit_event(envoy.dischargedenergy({value=dischargedenergy, unit="W"}))
    device:emit_event(envoy.chargedenergy({value=chargedenergy, unit="W"}))

    --    device:emit_event(envoy.importedenergy({value=math.random(1,10), unit="kW"}))
end

-- callback to handle an `on` capability command
function command_handlers.switch_on(driver, device, command)
    log.debug(string.format("[%s] calling set_power(on)", device.device_network_id))
    device:emit_event(capabilities.switch.switch.on())
    device:emit_component_event(device.profile.components.s2, capabilities.switch.switch.on())
    local es = envoyStream(device, true)
end

-- callback to handle an `off` capability command
function command_handlers.switch_off(driver, device, command)
    log.debug(string.format("[%s] calling set_power(off)", device.device_network_id))
    device:emit_event(capabilities.switch.switch.off())
    device:emit_component_event(device.profile.components.s2, capabilities.switch.switch.off())
    local es = envoyStream(device, false)
end

-- Simple table print routine
function printTable(tbl)
    for key, value in pairs(tbl) do
        log.debug(string.format("[%s]: [%s]", key, value))
    end
end

-- Converts ENVOY timestamp to EST
function converttimestamp(timestamp)
    log.debug(timestamp)
    log.debug(tonumber(timestamp)+60*60*11)
    local formattedDate = os.date("%Y-%m-%dT%H:%M:%S", tonumber(timestamp)+60*60*11)  -- Adjust the format as needed
    return formattedDate
end

-- Get latest data
function envoyStream(device, flag)
    if (key == "") then
        log.debug("No key set")
        return
    end
    local authorizationHeader = "Bearer " .. key
    local contentTypeHeader = "Content-Type: application/json"
    local respbody = {}
    local flagstr = flag and "1" or "0"
    local data = "{\"enable\": " .. flagstr .. "}"

    log.debug(data .. "flag:" .. flagstr)
    --    ["content-length"] = string.len(data)
    local url = "https://" .. device.preferences.ipaddress .. "/ivp/livedata/stream"
    log.debug("start")
    https.TIMEOUT = 5
    local response, code, headers1, status = https.request{
        url = url,
        method = "POST",
        headers = {
            ["Authorization"] = authorizationHeader,
            ["Content-Type"] = contentTypeHeader,
            ["content-length"] = string.len(data)
        },
        source = ltn12.source.string(data),
        sink = ltn12.sink.table(respbody)
    }
    log.debug("end")
    if code == 200 then
        -- Assuming the response is a JSON string, parse it
        local jsonstr = table.concat(respbody,"")
        local obj, pos, err = json.decode (jsonstr, 1, nil)
        if err then
            log.debug ("Error:" .. err)
            return err
        else
            log.debug("sc_stream:" .. obj.sc_stream)
            return obj
        end
    else
        print("Error:", status)
        return status
    end
end

-- Main poll function
function envoyPoll(device)
    if (key == "") then
        log.debug("No key set")
        return
    end
    local authorizationHeader = "Bearer " .. key
    log.debug(authorizationHeader)
    local contentTypeHeader = "Content-Type: application/json"
    local respbody = {}

    local url = "https://" .. device.preferences.ipaddress .. "/ivp/livedata/status"
    log.debug("start")
    https.TIMEOUT = 5
    local response, code, headers1, status = https.request{
    url = url,
    method = "GET",
    headers = {
    ["Authorization"] = authorizationHeader,
    ["Content-Type"] = contentTypeHeader
    },
    --            source = ltn12.source.string(data),
    sink = ltn12.sink.table(respbody)
    }
    log.debug("end")
    if code == 200 then
        -- Assuming the response is a JSON string, parse it
        local jsonstr = table.concat(respbody,"")
        local obj, pos, err = json.decode (jsonstr, 1, nil)
        if err then
            log.debug ("Error:" .. err)
            return err
        else
            return obj
        end
    else
        print("Error:", status)
        return status
    end
end

-- Routine to get the token if not provided
function getToken(device)
    local respbody = {}
    local respbody2 = {}
    local session_id

    local url = "http://" .. device.preferences.edgebridgeipaddress .. ":" .. device.preferences.edgebridgeport .. "/api/forward?url=https://enlighten.enphaseenergy.com/login/login.json?"
    log.debug(url)
    local data = [[user[email]=]] .. device.preferences.username .. [[&user[password]=]] .. device.preferences.password
    log.debug("start")
    log.debug(data)
--multipart/form-data
    http.TIMEOUT = 5
    local response, code, headers1, status = http.request{
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["content-length"] = string.len(data)
        },
        source = ltn12.source.string(data),
        sink = ltn12.sink.table(respbody)
    }
    log.debug("end")
    if code == 200 then
        -- Assuming the response is a JSON string, parse it
        --traverseObject(respbody)
        local jsonstr = table.concat(respbody,"")
        local obj, pos, err = json.decode (jsonstr, 1, nil)
        if err then
            print ("Error:", err)
            return
        else
            log.debug(obj.session_id)
            session_id = obj.session_id
        end
    else
        print("Code: ", code)
        return
    end

    url = "http://" .. device.preferences.edgebridgeipaddress .. ":" .. device.preferences.edgebridgeport .. "/api/forward?url=https://entrez.enphaseenergy.com/tokens"
    log.debug(url)
    data = [[{
            "session_id": "]] .. session_id .. [[",
            "serial_num": "]] .. device.preferences.serial ..[[",
            "username": "]] .. device.preferences.username .. [["
}]]
    log.debug("start")
    log.debug(data)

    local response, code, headers1, status = http.request{
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["content-length"] = string.len(data)
        },
        source = ltn12.source.string(data),
        sink = ltn12.sink.table(respbody2)
    }
    log.debug("end")
    if code == 200 then
        key = table.concat(respbody2,"")
        log.debug(string.len(key))
        log.debug(key)
        return key
    else
        print("Error:", status)
        return
    end
end

-- Triggered by the refresh action
function command_handlers.do_refresh(driver,device, cmd)
    log.debug("Refresh")
    local result = getToken(device)
    command_handlers.poll(device, true)
end


function command_handlers.do_Preferences(driver, device)
        log.debug("Preference Changes")
      --  printTable(device.preferences.refresh)
        log.debug(device.preferences.refresh)
        refreshrate = tonumber(device.preferences.refresh)
        refreshcnt = tonumber(device.preferences.refresh)
        log.debug(refreshrate)
        log.debug("Token:" .. device.preferences.tokenp1)
    if (device.preferences.tokenp1 == "") then
        print ("No token is set so we depend on the edgebridge driver to get the token")
        local result = getToken(device)
    end
end

function traverseObject(obj, depth)
    depth = depth or 0

    for key, value in pairs(obj) do
        if type(value) == 'table' then
            print(string.rep(' ', depth * 2) .. key .. ":")
            traverseObject(value, depth + 1)
        else
            if key == 'last_update' then
                print(convert_timestamp(value))
            elseif key == 'soc' then
                print(string.rep(' ', depth * 2) .. key .. ": " .. value .. "%")
            elseif key == 'agg_p_mw' then
                local num = string.format("%.1f", value / 1000000)
                print(string.rep(' ', depth * 2) .. key .. ": " .. num .. " w")
            else
                print(string.rep(' ', depth * 2) .. key .. ": " .. value)
            end
        end
    end
end

return command_handlers
