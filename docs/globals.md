

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

# Animals

AnimalScreen.TRANSPORTATION_FEE
setAnimalDaytime(...)
g_currentMission.husbandries

g_currentMission.husbandries.sheep
dailyUpkeep
totalNumAnimals
productivity
animalDesc 3601
   price                   sheep:4000, chicken:0, pig:3000, cow:5000
   milkPerDay              sheep:0, chicken:0, pig:0, cow:714
   liquidManurePerDay      sheep:0, chicken:0, pig:65, cow:250
   dirtFillLevelPerDay     sheep:6, chicken:0, pig:16, cow:30
   palletFillLevelPerDay   sheep:24, chicken:0, pig:0, cow:0
   strawPerDay             sheep:0, chicken:0, pig:20, cow:70
   birthRatePerDay         sheep:0.025, chicken:0, pig:0.16666666666667, cow:0.02
   waterPerDay             sheep:15, chicken:0, pig:10, cow:35
   foodPerDay              sheep:30, chicken:0, pig:90, cow:350
   manurePerDay            sheep:0, chicken:0, pig:50, cow:200
   pickUpObjectsPerDay     sheep:0, chicken:1, pig:0, cow:0
   dailyUpkeep             sheep:20, chicken:0, pig:30, cow:40


# GUI

g_gui:closeDialogByName("YesNoDialog")

## DialogElement -> ScreenElement

To set the icon
```lua
dialog.target:setDialogType(type)
DialogElement.TYPE_BENCHMARK
DialogElement.TYPE_INFO
DialogElement.TYPE_KEY
DialogElement.TYPE_LOADING
DialogElement.TYPE_QUESTION
DialogElement.TYPE_WARNING
```

To make closeable with ESCape
```lua
dialog.target:setIsCloseAllowed(true)
```

## MessageDialog -> DialogElement
```lua
local dialog = g_gui:showDialog("MessageDialog")
dialog.target:setText("Hello World A text!")
-- resizeDialog()
```

Will show a non-closable dialog with waiting icon

## InfoDialog -> MessageDialog

A dialog with a button to close it.
`dialog.target:setIsCloseAllowed(false)` has no effect. An icon is shown.

`dialog.target:setButtonTexts("text")` to set the button text.

Has a `setCallback(f)` as well.

## YesNoDialog -> MessageDialog
```lua
local dialog = g_gui:showDialog("YesNoDialog")
dialog.target:setText("Hello World A text!")
dialog.target:setCallback(func(yesNo))
dialog.target:setButtonTexts("Yes", "No")
```

## Gui

new()
showGui() -- with class name

## GuiElement
addCallback
addElement
applyProfile
applyScreenAlignment()
draw()
getBorders
getIsActive
getIsSelected
getIsVisible
raiseCallback
setAlpha
setDisabled
setId
setOverlayState
setPosition
setSize
setVisible
unlinkElement
update

GuiElement.ORIGIN_BOTTOM
GuiElement.ORIGIN_CENTER
GuiElement.ORIGIN_LEFT
GuiElement.ORIGIN_MIDDLE
GuiElement.ORIGIN_RIGHT
GuiElement.ORIGIN_TOP

GuiElement.SCREEN_ALIGN_BOTTOM
GuiElement.SCREEN_ALIGN_CENTER
GuiElement.SCREEN_ALIGN_LEFT
GuiElement.SCREEN_ALIGN_MIDDLE
GuiElement.SCREEN_ALIGN_RIGHT
GuiElement.SCREEN_ALIGN_TOP
GuiElement.SCREEN_ALIGN_XNONE
GuiElement.SCREEN_ALIGN_YNONE

## MultiTextOptionElement -> GuiElement
Probably scroll things like in the settings menu

setTexts
getState
setState
addText
addElement

## SliderElement -> GuiElement
callOnChanged
addElement
SliderElement.DIRECTION_X
SliderElement.DIRECTION_Y
setAlpha
setController
setMaxValue
setMinValue
setSize
setSliderSize
setTexts
setValue

## TextElement -> GuiElement
setText
.. 2Color, 2SelectedColor, Color, SelectedColor, Size
get ..

## ButtonElement -> TextElement
setDisabled
setIconSize
setImageFilename
setSelected
reset

## TextInputElement -> ButtonElement

## ToggleButtonElement -> GuiElement
addElement
setIsChecked

## ToggleButtonElement2 -> MultiTextOptionElement
addElement
getIsChecked
setIsChecked

## BitmapElement -> GuiElement
setAlpha
setImageColor
setImageFilename
setImageUVs

## BoxLayoutElement -> BitmapElement
addElement

BoxLayoutElement.ALIGN_BOTTOM
BoxLayoutElement.ALIGN_CENTER
BoxLayoutElement.ALIGN_LEFT
BoxLayoutElement.ALIGN_MIDDLE
BoxLayoutElement.ALIGN_RIGHT
BoxLayoutElement.ALIGN_TOP

getIsElementIncluded
invalidateLayout
removeElement

## ListElement -> GuiElement
addElement
addElements
getSelectedElement
onSliderValueChanged
removeElement
scrollList
scrollTo
setSelectedRow
setPreSelectedRow

## ListItemElement -> BitmapElement

getIsSelected
getIsPreSelected
setSelected
setPreSelected
reset

## PagingElement -> GuiElement

addElement
addPage
getCurrentPageId
getIsPageDisabled
getPageMappingIndex
getPageTitles
setPage
setPageDisabled
setPageIdDisabled
updatePageMapping

## TableElement -> GuiElement
addElement
deleteListItems
TableElement.getItemNumberByRealRowColumn(...)
TableElement.getItemNumberByRowColumn(...)
TableElement.getNumRows(...)
TableElement.getRealRowColumnByItemNumber(...)
TableElement.getRowColumnByItemNumber(...)
TableElement.getSelectedElement(...)
TableElement.removeElement(...)
TableElement.scrollList(...)
TableElement.scrollTo(...)
TableElement.scrollToItemNumber(...)
TableElement.selectItemByNumber(...)
TableElement.setPreSelectedRow(...)
TableElement.setScrollToFirstVisibleItem(...)
TableElement.setSelectedRow(...)
TableElement.setSelection(...)

## FlowLayoutElement -> BoxLayoutElement


## ScreenElement -> GuiElement

## SettingsScreen -> ScreenElement

g_inGameMenu

## Small in game message at botton
```lua
g_currentMission.inGameMessage:showMessage("TITle", "Some text", -1); --TourIcons
-- g_currentMission.inGameMessage:showDialog("TITle", self); ??

--if not g_currentMission.inGameMessage:getIsVisible() and not g_gui:getIsGuiVisible() then
```
