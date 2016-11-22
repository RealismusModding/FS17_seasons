

## g_currentMission

time // Current time since start of the game (so after you quit and re-open the save, this resets to 0)
missionStats.difficulty
   Utils.lerp(0.6, 1, (g_currentMission.missionStats.difficulty-1)/2))

### g_currentMission.environment (table 13)

currentHour  // Hour in day (0-23)
currentMinute // Minute in day (0-59)
currentDay // Current gameday (1+)

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


### missionInfo (in-game settings) (table 80)

timeScale // Timescale, 1 = realtime, 500 = fast


### MISSIONS

g_currentMission.fieldJobManager

### Night temperatures (table 227)
14 values

```lua
{
   9,
   3,
   2,
   7,
   14,
   9,
   11,
   12,
   15,
   1,
   15,
   0,
   9,
   14,
}
```

### Day temperatures (table 232)

14 values
``` lua
{
   21,
   23,
   25,
   13,
   27,
   19,
   18,
   19,
   24,
   24,
   17,
   23,
   15,
   27,
}
```

# Others (denv 0)

g_savegamePath
g_screenHeight
g_colorBg
g_gameSettings
g_i18n
g_screenWidth
g_aspectScaleX
g_gameVersion
g_referenceScreenWidth
g_uiDebugEnabled
g_savegameXML
g_gui

# Other stuff

ShopScreen.onVehicleBought(self, ...) -- Called when a vehicle is bought.
Vehicle:getSpeedLimit(onlyIfWorking)

Vehicle.attachedImplements
   get its speed limit
   get min of currently found min and speed limit
