# water_vapor

This QuickApp (for the Fibaro Homecenter 3) gives access to real-time water vapor level of any location in Asia, Europe, North America, Australia and New Zealand by latitude and longitude. 


IMPORTANT
- You need an API key form https://www.getambee.com
- The API is free up to 100 API calls/day, with zero limitations on country, access to air quality, pollen, weather and fire data and dedicated support 


Version 0.3 (24th May 2021)
- Changed handling in case exhausted daily usage limit 

Version 0.2 (21th May 2021)
- Tested

Version 0.1 (17th May 2021)
- Initial version


Variables (mandatory): 
- apiKey = Get your free API key from https://www.getambee.com
- interval = [number] in seconds time to get the data from the API
- timeout = [number] in seconds for http timeout
- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
- icon = [numbber] User defined icon number (add the icon via an other device and lookup the number)
