--local cosock = require "cosock"
--local http = cosock.asyncify "socket.http"
local http = require("http")

local user = "chewbarker1@hotmail.com"
local password = "Tester111!"
local envoy_serial = "122325055085"
local session_id = ""
local web_token = ""

-- Login
http.post("https://enlighten.enphaseenergy.com/login/login.json?", {
    query = {
        ["user[email]"] = user,
        ["user[password]"] = password
    }
}, function(response)
    session_id = response.body.session_id

    -- Get web token
    http.post("https://entrez.enphaseenergy.com/tokens", {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = {
            session_id = session_id,
            serial_num = envoy_serial,
            username = user
        }
    }, function(response)
        web_token = response.body
        print(session_id)
        print(web_token)
    end)
end)