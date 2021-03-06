-- QuickApp WATERVAPOR

-- This QuickApp gives access to real-time water vapor level of any location in Asia, Europe, North America, Australia and New Zealand by latitude and longitude. 


-- IMPORTANT
-- You need an API key form https://www.getambee.com
-- The API is free up to 100 API calls/day, with zero limitations on country, access to air quality, pollen, weather and fire data and dedicated support 


-- Version 0.3 (24th May 2021)
-- Changed handling in case exhausted daily usage limit 

-- Version 0.2 (21th May 2021)
-- Tested

-- Version 0.1 (17th May 2021)
-- Initial version


-- Variables (mandatory): 
-- apiKey = Get your free API key from https://www.getambee.com
-- interval = [number] in seconds time to get the data from the API
-- timeout = [number] in seconds for http timeout
-- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
-- icon = [numbber] User defined icon number (add the icon via an other device and lookup the number)

-- Example response:
-- {"message":"success","data":[{"createdAt":"2021-05-17 11:25:00Z","water_vapor":1.837}]}


-- No editing of this code is needed 


function QuickApp:logging(level,text) -- Logging function for debug
  if tonumber(debugLevel) >= tonumber(level) then 
      self:debug(text)
  end
end


function QuickApp:updateProperties() --Update properties
  self:logging(3,"updateProperties")
  self:updateProperty("value",tonumber(data.WaterVapor))
  self:updateProperty("unit", "m")
  self:updateProperty("log", data.timestamp)
end


function QuickApp:updateLabels() -- Update labels
  self:logging(3,"updateLabels")
  local labelText = ""
  if debugLevel == 4 then
    labelText = labelText .."SIMULATION MODE" .."\n\n"
  end
  labelText = labelText .."Water Vapor:  " ..data.WaterVapor .." " .."\n"
  labelText = labelText .."Message: " ..data.message .."\n\n"
  labelText = labelText .."LAT: " ..latitude .." / " .."LON: " ..longitude .."\n"
  labelText = labelText .."Measured: " ..data.timestamp .."\n"
  
  self:logging(2,"labelText: " ..labelText)
  self:updateView("label1", "text", labelText) 
end


function QuickApp:getValues() -- Get the values
  self:logging(3,"getValues")
  data.message = jsonTable.message
  data.WaterVapor = string.format("%.1f",jsonTable.data[1].water_vapor)
  local createdAt = jsonTable.data[1].createdAt

    -- Check timezone and daylight saving time
  local timezone = os.difftime(os.time(), os.time(os.date("!*t",os.time())))/3600
  if os.date("*t").isdst then -- Check daylight saving time 
    timezone = timezone + 1
  end
  self:logging(3,"Timezone + dst: " ..timezone)

  -- Convert time of measurement to local timezone
  local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
  local runyear, runmonth, runday, runhour, runminute, runseconds = createdAt:match(pattern)
  local convertedTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
  data.timestamp = os.date("%d-%m-%Y %X", convertedTimestamp + (timezone*3600))
end


function QuickApp:simData() -- Simulate Ambee API
  self:logging(3,"Simulation mode")
  local apiResult = '{"message":"success","data":[{"createdAt":"2021-05-17 11:25:00Z","water_vapor":1.837}]}'
  
  self:logging(3,"apiResult: " ..apiResult)

  jsonTable = json.decode(apiResult) -- Decode the json string from api to lua-table 
  
  self:getValues()
  self:updateLabels()
  self:updateProperties()

  for id,child in pairs(self.childDevices) do 
    child:updateValue(data) 
  end
  
  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function() 
     self:simData()
  end)
end


function QuickApp:getData()
  self:logging(3,"Start getData")
  self:logging(2,"URL: " ..address)
    
  http:request(address, {
    options = {data = Method, method = "GET", headers = {["x-api-key"] = apiKey,["Content-Type"] = "application/json",["Accept"] = "application/json",}},
    
      success = function(response)
        self:logging(3,"response status: " ..response.status)
        self:logging(3,"headers: " ..response.headers["Content-Type"])
        self:logging(2,"Response data: " ..response.data)

        if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
          self:warning("Temporarily no data from Ambee")
          return
          --self:logging(3,"No data SetTimeout " ..interval .." seconds")
          --fibaro.setTimeout(interval*1000, function() 
          --  self:getdata()
          --end)
        end

        --response.data = response.data:gsub("% / ", "") -- Clean up the response.data by removing /
        --self:logging(2,"Response data editted: " ..response.data)

        jsonTable = json.decode(response.data) -- JSON decode from api to lua-table

        self:getValues()
        self:updateLabels()
        self:updateProperties()
      
      end,
      error = function(error)
        self:error('error: ' ..json.encode(error))
        self:updateProperty("log", "error: " ..json.encode(error))
      end
    }) 

  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout((interval)*1000, function() 
     self:getData()
  end)
end


function QuickApp:createVariables() -- Get all Quickapp Variables or create them
  data = {}
  data.message = ""
  data.WaterVapor = "0"
  data.timestamp = ""
end


function QuickApp:getQuickAppVariables() -- Get all variables 
  apiKey = self:getVariable("apiKey")
  latitude = tonumber(self:getVariable("latitude"))
  longitude = tonumber(self:getVariable("longitude"))
  interval = tonumber(self:getVariable("interval")) 
  httpTimeout = tonumber(self:getVariable("httpTimeout")) 
  debugLevel = tonumber(self:getVariable("debugLevel"))
  local icon = tonumber(self:getVariable("icon")) 

  if apiKey =="" or apiKey == nil then
    apiKey = "" 
    self:setVariable("apiKey",apiKey)
    self:trace("Added QuickApp variable apiKey")
  end
  if latitude == 0 or latitude == nil then 
    latitude = string.format("%.2f",api.get("/settings/location")["latitude"]) -- Default latitude of your HC3
    self:setVariable("latitude", latitude)
    self:trace("Added QuickApp variable latitude with default value " ..latitude)
  end  
  if longitude == 0 or longitude == nil then
    longitude = string.format("%.2f",api.get("/settings/location")["longitude"]) -- Default longitude of your HC3
    self:setVariable("longitude", longitude)
    self:trace("Added QuickApp variable longitude with default value " ..longitude)
  end
  if interval == "" or interval == nil then
    interval = "7200" -- Free account includes up to 100 calls a day, so default value is 7200 (every two hours)
    self:setVariable("interval",interval)
    self:trace("Added QuickApp variable interval")
    interval = tonumber(interval)
  end  
  if httpTimeout == "" or httpTimeout == nil then
    httpTimeout = "5" -- timeoout in seconds
    self:setVariable("httpTimeout",httpTimeout)
    self:trace("Added QuickApp variable httpTimeout")
    httpTimeout = tonumber(httpTimeout)
  end
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" -- Default value for debugLevel response in seconds
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  if icon == "" or icon == nil then 
    icon = "0" -- Default icon
    self:setVariable("icon",icon)
    self:trace("Added QuickApp variable icon")
    icon = tonumber(icon)
  end
  if icon ~= 0 then 
    self:updateProperty("deviceIcon", icon) -- set user defined icon 
  end
  latitude = string.format("%.2f",latitude) -- double check, to prevent 404 response
  longitude = string.format("%.2f",longitude) -- double check, to prevent 404 response

  address = "https://api.ambeedata.com/waterVapor/latest/by-lat-lng" .."?lat=" ..latitude .."&lng=" ..longitude -- Combine webaddress and location info

  if apiKey == nil or apiKey == ""  then -- Check mandatory API key 
    self:error("API key is empty! Get your free API key from https://www.getambee.com")
    self:warning("No API Key: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty API key
  end

end


function QuickApp:onInit()
  __TAG = fibaro.getName(plugin.mainDeviceId) .." ID:" ..plugin.mainDeviceId
  self:debug("onInit") 
  
  self:getQuickAppVariables() -- Get Quickapp Variables or create them
  self:createVariables() -- Create Variables

  http = net.HTTPClient({timeout=httpTimeout*1000})

  if tonumber(debugLevel) >= 4 then 
    self:simData() -- Go in simulation
  else
    self:getData() -- Get data from API
  end
end

--EOF
