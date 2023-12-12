local log = require "log"
local capabilities = require "st.capabilities"
local cosock = require "cosock"
local http = cosock.asyncify "socket.http"
local https = cosock.asyncify "ssl.https"
local json = require "dkjson"
local ltn12 = require "ltn12"
local envoy = {}

local session_id = '5118286df55126efa7545279b6e9ea81'
local access_token = 'eyJraWQiOiI3ZDEwMDA1ZC03ODk5LTRkMGQtYmNiNC0yNDRmOThlZTE1NmIiLCJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NiJ9.eyJhdWQiOiIxMjIzMjUwNTUwODUiLCJpc3MiOiJFbnRyZXoiLCJlbnBoYXNlVXNlciI6Im93bmVyIiwiZXhwIjoxNzMwMDg2NjcwLCJpYXQiOjE2OTg1NTA2NzAsImp0aSI6IjQ5ZDVjZGVjLTU3MDUtNDYxNi04YjE1LTg3ZWUyNGUxYzVmYiIsInVzZXJuYW1lIjoiY2hld2JhcmtlcjFAaG90bWFpbC5jb20ifQ.u8M6jHUxY06xuZcSUd3cvvwIKFhwFZ7Y244SRQNSgvCaNHV8v7DNPlKm8HndQdn4AXhOcP4ZmSXEEOhHUCJEJg'

local headers = {
    ["Accept"] = "application/json",
    ["Authorization"] = "Bearer " .. access_token
}


local agent = {
    verify = "none"
}

function printTable(tbl)
    for key, value in pairs(tbl) do
        log.debug(string.format("[%s]: [%s]", key, value))
    end
end

-- Converts ENVOY timestamp to EST
function convert_timestamp(timestamp)
    local date = os.date("*t", timestamp)  -- Assuming timestamp is in seconds

    local options = {
        year = "numeric",
        month = "long",
        day = "numeric",
        hour = "numeric",
        minute = "numeric",
        second = "numeric",
        timeZoneName = "short"
    }

    local formattedDate = os.date("%Y-%m-%dT%H:%M:%S", timestamp + 10 * 60 * 60)  -- Adjust the format as needed
    return formattedDate 
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



return envoy
