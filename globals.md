

## g_currentMission

time // Current time since start of the game (so after you quit and re-open the save, this resets to 0)


### g_currentMission.environment (table 13)

currentHour  // Hour in day (0-23)
currentMinute // Minute in day (0-59)
currentDay

// Rain
allowRain
autoRain // To turn of rain in summer?
minRainDuration // Short rains in summer?

// Sun
sunHeightAngle // For lower sun in winter?
nightStart // Longer nights in winter
nightEnd
sunColorCurve

dayTime // Current time within a day (0 - dayLength)
dayLength // Length of a day

weatherTemperaturesNight (table 227)
weatherTemperaturesDay (table 232)
