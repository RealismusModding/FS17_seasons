# calculating sunrise and sunset from latitude and Julian day
# reallogger
# 2016 11 09

import math

def day(p,L_rad,eta,J):
    gamma = (math.sin(p)+math.sin(L_rad)*math.sin(eta))/(math.cos(L_rad)*math.cos(eta))

    #to account for polar day and polar night
    if gamma < -1:
        D = 0
    elif gamma > 1:
        D = 24
    else:
        D = 24-24/math.pi*math.acos(gamma)

    #daylight saving between 1 April and 31 October as an approximation
    if J < 91 or J > 304:
        time_start = 12-D/2
        time_end = 12+D/2
    elif (J >= 91 and J <= 304) and (gamma < -1 or gamma > 1):
        time_start = 12-D/2
        time_end = 12+D/2
    else:
        time_start = 12-D/2+1
        time_end = 12+D/2+1

    return (time_start,time_end)

##### IN LOAD
L = 51.9   #Latitude
L_rad = L*math.pi/180
p_night = 6*math.pi/180 #suns inclination below the horizon for 'civil twilight'
p_day = -1*math.pi/180 #suns inclination above the horizon for "daylight" assumed to be one degree above horizon
#####

J = 1       #Julian day

#### IN CALCULATE
theta = 0.216+2*math.atan(0.967*math.tan(0.0086*(J-186)))
eta = math.asin(0.4*math.cos(theta))

#setting time for daylight
[time_startday,time_endday] = day(p_day, L_rad, eta, J)

#setting time for full darkness
[time_endnight,time_startnight] = day(p_night, L_rad, eta, J)


print "EndNight %.02f, StartDay %.02f, EndDay %.02f, StartNight %.02f" % (time_endnight, time_startday, time_endday, time_startnight)
