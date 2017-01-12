# calculating daily upkeep
# reallogger
# 2016 11 17
# Data used from 'Cost of Owning and Operating Farm Machinery in Pacific Northwest: 2011" by Kathleen Painter

def repairCost(operatingTime, price):
    lifeTimeFactor = 5. #Just a constant needed for determining when the repair cost levels out
    RF1 = 0.007 #repair factors - unique for each equipment - to be read from seperate file maintenanceFactors.xml
    RF2 = 2. #repair factors - unique for each equipment - to be read from seperate file maintenanceFactors.xml

    lifeTime = 600. #read from maintenanceFactors.xml

    power = 110 #read from vehicle.self
    dailyUpKeep = 160 # read from vehicle.self only used for scale

    if operatingTime < lifeTime / lifeTimeFactor:
        return 0.025 * price * (RF1*(operatingTime/5)**RF2) * dailyUpKeep / power

    else:
        return 0.025 * price * (RF1*(operatingTime/(5*lifeTimeFactor))**RF2) * (1 + (operatingTime - lifeTime / lifeTimeFactor) / (lifeTime/5) * 2) * dailyUpKeep / power


price = 95000.  # read from vehicle.self
daysInSeason = 10

prevOperatingTime = 20. #operatingTime is in seconds so divide by 3600 as algorithm uses hours
operatingTime = 30. #operatingTime is in seconds so divide by 3600 as algorithm uses hours




#timeSinceRepair
#Should perhaps be enough to repair the requipment once a season
#
daysSinceLastRepair = 10 #dummy
currentDay = 18 #dummy read current day

cumDirtAmount = 1*(operatingTime - prevOperatingTime) #dummy cumDirtAmount to be read from vehicle.self and stored in savegame. Reset when repaired.
if operatingTime == prevOperatingTime:
    avgDirtAmount = 0
else:
    avgDirtAmount = cumDirtAmount / (operatingTime - prevOperatingTime)

prevRepairCost = repairCost(prevOperatingTime, price)
newRepairCost = repairCost(operatingTime, price)

taxInterestCost = 0.03 * price/(4 * daysInSeason) # to be deducted every day

if daysSinceLastRepair < daysInSeason:
    #repairFac = 0.5
    #maintenanceCost = (newRepairCost - prevRepairCost)*repairFac*(0.8 + 0.2* avgDirtAmount**2) # to be deducted when doing repair
    maintenanceCost = 0
else:
    repairFac = 1
    maintenanceCost = (newRepairCost - prevRepairCost)*repairFac*(0.8 + 0.2* avgDirtAmount**2) # to be deducted daily

print maintenanceCost
print taxInterestCost
