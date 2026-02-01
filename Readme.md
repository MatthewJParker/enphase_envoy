# Enphase Envoy

This is a smartthings edge driver for the Enphase Envoy. For my setup I have a battery so I have assumed it is a setup with Battery. The driver could be customised to exclude the battery as a future version.

It is using local commands available and as referenced by this online guide:

https://github.com/Matthew1471/Enphase-API

This driver uses the EdgeBridge driver that I have installed on my raspberryPI made by Todd Austin:

https://github.com/toddaustin07/edgebridge

This is so it it can get a token from the server, after that it operates locally.

Therefore, you need to know your device serial number and have a username and password, as you would have setup with the enphase app.

You can set all this up in the settings once you install the driver.

To access your local Enphase you can try:

https://envoy/home#auth

Once you login the web page at the top shows the serial number: "Envoy Serial Number".
