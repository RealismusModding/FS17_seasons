# calculating temperatures based on season
# based on historic weather data from UK
# Inverse normal CDF algorithm based on A&S formula 26.2.23 - thanks to John D. Coook
# reallogger
# 2016 11 15

from math import sqrt,log
from random import random
from numpy import zeros

def ssTmax(ss): #sets the minimum, mode and maximum of the seasonal average maximum temperature. Simplification due to unphysical bounds. 
	if ss == "winter":
		return [5.0,8.6,10.7] #min, mode, max
		
	elif ss == "spring":
		return [12.1, 14.2, 17.9] #min, mode, max
		
	elif ss == "summer":
		return [19.4, 21.7, 26.0] #min, mode, max
	
	elif ss == "autumn":
		return [14.0, 15.6, 17.3] #min, mode, max
	
def ssTriDist(m): #Outputs a random sample from a triangular distribution
	pmode = (m[1]-m[0])/(m[2]-m[0])
	p = random()
	if p < pmode:
		return sqrt(p*(m[2]-m[0])*(m[1]-m[0]))+m[0]
	else:
		return m[2]-sqrt((1-p)*(m[2]-m[0])*(m[2]-m[1]))

def RationalApproximation(t): 
	c = [2.515517, 0.802853, 0.010328]	
	d = [1.432788, 0.189269, 0.001308]
	return t - ((c[2]*t + c[1])*t + c[0]) / (((d[2]*t + d[1])*t + d[0])*t + 1.0)
	
def ssNormDist(mu,sigma): #Outputs a random sample from a normal distribution
	p = random()
	if p < 0.5:
		return RationalApproximation( sqrt(-2.0*log(p)))*-sigma + mu
	else:
		return RationalApproximation( sqrt(-2.0*log(1-p)))*sigma + mu

Tmax = ssTmax("winter")
Tmaxmean = ssTriDist(Tmax) #This is the seasonal average and should be stored for each season. Not to be resampled each day.

day = [1,2,3,4,5,6,7,8,9,10] #dummy array with day numbers. To be replaced. 

weatherTemperaturesDay = zeros(len(day))
weatherTemperaturesNight = zeros(len(day))

for i in day:
	weatherTemperaturesDay[i-1] = ssNormDist(Tmaxmean,2.5) #At midnight and a new day is to be generated, just use this call to get a new daily high temperature
	weatherTemperaturesNight[i-1] = ssNormDist(0,2) + 0.75*weatherTemperaturesDay[i-1]-5 #At midnight and a new day is to be generated, just use this call to get a new daily low temperature
	
print weatherTemperaturesDay
print weatherTemperaturesNight



