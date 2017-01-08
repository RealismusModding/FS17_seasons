# FS17 Seasons

This mod is not complete and is actively being worked on. Nothing is guaranteed to work and the mod is in a state of constant flux. 

## Publishing
Only the Realismus Modding team is allowed to publish any of this code as a mod to any mod site. 
The code is open for your own use, but give credit where due.
Thus, when building your own version of Seasons, give a credit notice to Realismus Modding when publishing screenshots or images.
This is not required when using the only official published mod by Realismis Modding, on ModHub. It would be a nice gesture however.

## Forking the code
You are allowed to fork this repository, apply changes and use those for private use. 
You are not allowed to distribute these changes yourself. 
Please open a pull request to allow for merging back your adjustments. (See also 'Publishing')

## Pull Requests
Please join us on [Slack](http://realismus.joskuijpers.nl) to discuss any changes you wish to make via pull requests, otherwise they are likely to be rejected, except for translations. 

## Features

### Seasons
- Plowable snow in the winter!
- Soil temperature is properly modelled using thermnodynamic equations and historical data which introduces interesting aspects like soil is frozen in the winter and sometimes in the first few days of spring, so you can't work on it
- Changed the weather system to fit the seasons
  - Rainy in autumn
  - Sunny in summer
  - Snow and hail in winter
- Winters have longer nights than summers. In the winter it might be light only 8 hours while in summer it is near 17 hours.

### Weather forecast
- 7 day weather forecast

### Crops
- Vanilla growth is completely disabled. The mod controls all growth of fruits, except for normal trees at this point in time
- Winter kills certain crops
- Grass is knocked back to stage 2 in the winter
- Crop growth duration is much, much longer: for some crops more than half a year
- Growth is adjust to match real life life as much as possible - for example, crops will not grow if planted at the wrong time of the year
- Winter and spring crops are possible now. Some crops can be planted in autumn and in spring and will reach harvestable stage by the summer. Some crops can only be planted at certain times of the year. 
- Growth is configurable and can be changed by map makers to suit their map

### Maintenance
- Age in maintenance GUI is now days since last repair
- New maintenance algorithm with repair, maintenance and taxes
- Keep your machine clean to lower daily maintenance costs
- Machine not used? Pay less
- You can repair your vehicles at the vehicle workshop (placeable or on the map). It is more expensive at the dealer
- If you don't maintain your vehicle it may break down

### Finance
- Loan cap is set to 70% of your total owned land value
- New maximum loan is set to 5 million
- The interest has been adjusted to the new year length.

### Helpers
- Wages have been changed to fit the new economy.
- Overtime, before 6AM and after 18AM or in the weekends, pays 150%

### Animals
- Animals have been adjusted to the seasons
  - They drink more water in summer than in winter
  - They need more straw in winter than in summer
  - They only birth babies in spring (pigs and sheep) or summer (cows)
  - Milk and wool production depend on season (Wool only in spring, milk spread, mostly in winter and spring)

## Coding style
- End your lines with \n (LF), not CRLF
- Use spaces, not tabs
