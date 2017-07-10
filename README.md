# FS17 Seasons

***WARNING***: You are looking at the DEVELOPMENT VERSION of the Seasons mod. To play Seasons, download at the Giants ModHub: [https://farming-simulator.com/mod.php?mod_id=79288](https://farming-simulator.com/mod.php?mod_id=79288). The code here might break your savegame, and computer, and give a lot of pain.

***WARNING***: We do not officially support activating the Seasons mod on an existing savegame. Do this at your own risk. Read more about this in the [F.A.Q.](https://github.com/RealismusModding/FS17_seasons/wiki/Frequently-Asked-Questions#q-why-do-you-not-support-adding-the-seasons-mod-to-an-existing-savegame)

Please do give feedback on [Slack](http://slack.realismusmodding.com) and post any issues you find!

## Publishing
Only the Realismus Modding team is allowed to publish any of this code as a mod to any mod site, or file sharing site.
The code is open for your own use, but give credit where due.
Thus, when building your own version of Seasons, give a credit notice to Realismus Modding when publishing screenshots or images.
This is not required when using the only official published mod by Realismis Modding, on Giants ModHub. It would be a nice gesture however.

## Making videos of development version
We have a couple of rules regarding videos to keep both our and our players experience the best. You are allowed to make videos with Seasons, under a couple of simple conditions:
- Do not share the GitHub link, if you are using a development version of the mod.
- Do not explain how to install this mod. (The mod might also change at any moment, making your video outdated)
- Give credit to 'Realismus Modding' as creators of the mod.
- Link to our [YouTube channel](https://www.youtube.com/c/realismusmodding).
- You do _not_ need to put the mod name in the video title, but you can if you want.

- Join us on [Slack](http://slack.realismusmodding.com) and tell us all about your awesome video.

Videos that are not holding to the rules will get a request for removal.
If you have any questions about this policy you can ask them on Slack.

## Forking the code
You are allowed to fork this repository, apply changes and use those for private use.
You are not allowed to distribute these changes yourself.
Please open a pull request to allow for merging back your adjustments. (See also 'Publishing')

## Pull Requests
Please join us on [Slack](http://slack.realismusmodding.com) to discuss any changes you wish to make via pull requests, otherwise they are likely to be rejected, except for translations.

## For map makers
For a better game experience, custom maps should add one new density layer: Seasons mask. See [here](https://www.realismusmodding.com/mods/seasons/manual/modding/info-for-map-makers) for more information, or join our [Slack](http://slack.realismusmodding.com).

## Features

### Seasons
- Changeable season lengths. (For best results, restart the game / server after changing season length)
- Plowable snow in the winter! Reduced tire friction when driving in snow.
- Soil temperature is properly modelled using thermodynamic equations and historical data, which introduces interesting aspects like soil is frozen in the winter and sometimes in the first few days of spring, so you can't work on it
- Changed the weather system to fit the seasons
  - Rainy in autumn
  - Sunny in summer
  - Snow and rain in winter.
- Winters have longer nights than summers. In the winter it might be light only 8 hours while in summer it is near 17 hours.
- Pedestrians do not spawn in the Winter.
- When snow falls, tippers and shovels fill up. Put them in a shed (when the map has a snow mask) or activate the cover.
- Snow will melt from tippers and shovels when it is not freezing outside.
- Bunker Silo contents now take one third of a season to ferment.
- Tree and bush textures will change with season and weather (trees drop their leaves when temperature becomes low etc.)

### Weather forecast
- 7 day weather forecast
- Hail may occur unexpectedly

### Crops
- At the beginning of a new game, the mod will reset all fields to the harvested state. This is to simulate the fact that you just bought the farm and the fields haven't been worked since the last harvest.
- Using the mod on an existing save game is not recommended. The mod will prompt if you wish to reset all fields in this situation.
- Vanilla growth is completely disabled. The mod controls all growth of fruits.
- Winter kills certain crops
- Grass is knocked back to state 2 in the winter
- Crop growth duration is much, much longer: for some crops more than half a year
- Growth is adjusted to match real life life as much as possible - for example, crops will not grow if planted at the wrong time of the year
- Winter and spring crops are possible now. Some crops can be planted in autumn (barley, wheat and canola) and in spring and will reach harvestable state by the summer. Some crops can only be planted at certain times of the year.
- Growth is configurable and can be changed by map makers to suit their map
- Germination of planted crops will only occur if the soil temperatures rise above the germination temperature.
- Swaths will reduce over time.
- Grass bales will rot and disappear after two days.
- Hay and straw bales exposed to rain will start to rot so keep them inside (only when the map has a snow mask)
- Wrapped bales needs time (one third of a season) to ferment before they are turned into silage
- Wrapped hay will not ferment. Wrapped hay bales can be stored outside.
- Treshing can only be done when moisture content of the crop is sufficiently low. After rain the crop needs time and sunny weather to dry. Moist summer nights can also occur.
- Custom fruits are handled gracefully by using barley's growth patterns. Map makers can choose to modify the growth patterns of vanilla fruits and also make the mod aware of custom fruits by supplying custom growth patterns for them
- Crops are only harvestable in the final growth state, except for poplar, oilseedradish, sugarbeet and potato. Min forage growth state has not been modified.
- Once a non-root crop reaches the first harvestable stage according to the growth overview in the esc menu, it is ready to harvest. This is the final harvestable stage.
- Using a tedder when crops are wet or when it is raining, leaves wet grass, not dry grass.
- Growth and withering settings are disabled as this mod overwrites this functionality
- The mod also controls the growth of planted trees. It takes 5 years for trees to be fully grown, harvestable after 2 years.
- Trees inhibit the growth of other trees if they have been planted too close together. To restart the growth of the tree you will need to thin out the trees.

### Vehicles and maintenance
- Age in maintenance GUI is now days since last repair
- New maintenance algorithm with repair, maintenance and taxes
- Keep your machine clean to lower daily maintenance costs
- Machine not used? Pay less
- You can repair your vehicles at the vehicle workshop (placeable or on the map). It is more expensive at the dealer
- If you don't maintain your vehicle, starting of the vehicle takes longer, and after a while it may be very hard to start it.
- Motor start setting is disabled as this mod overwrites the functionality
- You can borrow vehicles for a free demo as long as it is returned within the same day with less than 0.5 engine hours

### Economy
- Loan cap is set to 30% of your total owned land + placeable buildings value  with a minimum of 300,000
- The interest has been adjusted to the new year length.
- Prices of almost everything changes during a year, realistically.
- You can't sell grass/hay/straw in an unbaled form. (Price is 0)
- You can't sell wet grass bales (price is 0)
- Income from missions is reduced to ~5x what a worker would earn if 100% of the time for a mission is used.
- Field prices can be adjusted via the economy xml file using fieldPriceFactor. 1 = default prices. < 1 for cheaper fields and > 1 for more expensive fields. For example, setting this value to 0.5 will result in a price half of what it would be in the standard game

### Helpers
- Wages have been changed to fit the new economy.
- Overtime, before 6AM and after 6PM or on the weekends, pays 150%

### Animals
- Animals have been adjusted to the seasons
  - They drink more water in summer than in winter
  - They need more straw in winter than in summer
  - They only give birth to offspring in spring (pigs and sheep) or summer (cows)
  - Milk and wool production depend on season (Wool only in spring and summer, milk spread, mostly in winter and spring)
- Animals die when they have no food. (Disabled on 'Easy')
- Max feeding capacity is lowered to 3 days

### Warnings for gameplay
- Do not fast forward faster than 6000x on singleplayer (preferable even slower)
- Do not fast forward faster than 1200x on multiplayer (120x is even better)
- The game will get out of sync with the extra load of Seasons
- The released version of this mod does not work with save games created using any previous versions. Delete the old version and start a new save game.


## Mod conflicts
Do not load multiple map mods. Only load the map you are using!

- Any mod that manipulates the weather, e.g. Multi overlay hud
- Any mod that manipulates growth
- Any mod that changes animals
- Any 'season manager' type mods
- Some animal cleaning mods may not work correctly, especially during the winter

Known:

## Contributing
You are free to contribute any code. But by doing this you transfer your copyright to the Realismus
Modding team so that we can publish this mod and change the code. Only we are allowed to publish Seasons.

Please follow the following code formatting rules:
- End your lines with \n (LF), not CRLF
- Use spaces, not tabs

## Copyright
Copyright (c) 2016-2017 Realismus Modding
All rights reserved.

This copyright does not impugn any trademarks or copyrights owned by Giants

*Warranty disclaimer*. You agree that you are using the software solely at your own risk.
Realismus Modding provides the software “as is” and without warranty of any kind, and Realismus
Modding for itself and its publishers and licensors hereby disclaims all express or implied
warranties, including without limitation warranties of merchantability, fitness for a particular
purpose, performance, accuracy, reliability, and non-infringement.

The [Terms and Conditions of GIANTS Software GmbH](https://www.farming-simulator.com/termsModHub.php) also apply.

### Informal explanation
An informal explanation of what this all means (this part is not legalese and can't be treated as such)

Realismus Modding (we) wrote the Mod and we have the copyright on this Mod. That means the code is ours and we can do
with it what we want. It also means you can't just copy our code and use it for your own projects.
Only we can distribute the Mod to others.
We allow you to make small changes for your own gameplay or with your friends. But you are not allowed to
publish these changes openly.
When you make a contribution (translations, code changes) you give that code to us. Otherwise we would
not be able to publish this Mod anymore.
If you lose your savegame or if your computer crashes due to our Mod, you can tell us and we will
attempt to fix the mod but we will not be paying for a new computer nor getting your savegame back.
(Make backups!)
