# calculating daily upkeep
# reallogger
# 2016 11 17
# Data used from 'Cost of Owning and Operating Farm Machinery in Pacific Northwest: 2011" by Kathleen Painter

def repairCost(operatingTime,lifeTime,lifeTimeFactor,price):
    RF1 = 0.007 #repair factors - unique for each equipment - to be read from seperate file
    RF2 = 2. #repair factors - unique for each equipment - to be read from seperate file

    if operatingTime < lifeTime / lifeTimeFactor:
        return 0.025 * price * (RF1*(operatingTime/5)**RF2)

    else:
        return 0.025 * price * (RF1*(operatingTime/(5*lifeTimeFactor))**RF2) * (1 + (operatingTime - lifeTime / lifeTimeFactor) / (lifeTime/5) * 2)


price = 95000.
daysInSeason = 10

prevOperatingTime = 34. #operatingTime is in seconds so divide by 3600 as algorithm uses hours
newOperatingTime = 40. #operatingTime is in seconds so divide by 3600 as algorithm uses hours
lifeTime = 600. #read from vehicle.self

lifeTimeFactor = 5. #Just a constant needed for scaling the repairCost

#timeSinceRepair
#
#Should perhaps be enough to repair the requipment once a season
#
daysSinceLastRepair = 11 #dummy
currentDay = 29 #dummy read current day

cumDirtAmount = 1*(newOperatingTime - prevOperatingTime) #dummy cumDirtAmount to be read from vehicle.self and stored in savegame. Reset when repaired.

if newOperatingTime == prevOperatingTime:
    avgDirtAmount = 0
else:
    avgDirtAmount = cumDirtAmount / (newOperatingTime - prevOperatingTime)

prevRepairCost = repairCost(prevOperatingTime, lifeTime, lifeTimeFactor, price)
newRepairCost = repairCost(newOperatingTime, lifeTime, lifeTimeFactor, price)

if daysSinceLastRepair > currentDay - daysInSeason:
    repairFac = 0.5
    maintenanceCost = (newRepairCost - prevRepairCost)*repairFac*(0.8 + 0.2* avgDirtAmount**2) # to be deducted when doing repair
else:
    repairFac = 1
    maintenanceCost = (newRepairCost - prevRepairCost)*repairFac*(0.8 + 0.2* avgDirtAmount**2) # to be deducted daily

print maintenanceCost
print prevRepairCost
print newRepairCost


taxInterestCost = 0.03 * price/(4 * daysInSeason) # to be deducted every day

print taxInterestCost
