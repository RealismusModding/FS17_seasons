----------------------------------------------------------------------------------------------------
-- GRAPH
----------------------------------------------------------------------------------------------------
-- Purpose:  Making and drawing graphs
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGraph = {}
local ssGraph_mt = Class(ssGraph)

ssGraph.BG_COLOR = {0, 0, 0, 0}
ssGraph.LINE_COLOR = {0.9, 0.9, 0.9, 1} --{0.0742, 0.4341, 0.6939, 1}
ssGraph.AXIS_COLOR = {0.2122, 0.5271, 0.0307, 1}
ssGraph.TEXT_COLOR = {0.2122, 0.5271, 0.0307, 1}
ssGraph.GRID_COLOR = {0.2122, 0.5271, 0.0307, 0.2}
ssGraph.TODAY_COLOR = InGameMenu.FRUIT_COLORS[false][5]
ssGraph.MAX_ROUNDOFF = 50

ssGraph.LINE_COLOR = InGameMenu.FRUIT_COLORS[false][1]

function ssGraph:new(parentElement)
    local self = {}
    setmetatable(self, ssGraph_mt)

    self.parent = parentElement
    self.yUnit = ""
    self.data = {}

    log("NEW!")

    self.rect = ssRectOverlay:new(parentElement)

    local width, height = getNormalizedScreenValues(1, 1)
    self.pixel = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)

    self.maxValue = 0

    _, self.axisTextSize = getNormalizedScreenValues(0, 12)
    _, self.titleTextSize = getNormalizedScreenValues(0, 18)

    return self
end

function ssGraph:delete()
    self.pixel:delete()
end

function ssGraph:draw()
    -- Background
    self.pixel:setPosition(unpack(self.parent.absPosition))
    self.pixel:setDimension(unpack(self.parent.size))
    self.pixel:setColor(unpack(self.BG_COLOR))
    self.pixel:render()

    local marginX, marginY = getNormalizedScreenValues(20, 20)
    local lineWidth, lineHeight = getNormalizedScreenValues(1, 1)
    local axisWidth, axisHeight = getNormalizedScreenValues(2, 2)
    local valueWidth = (self.parent.size[1] - marginX) / table.getn(self.data)
    local nudgeWidth, nudgeHeight = getNormalizedScreenValues(8, 8)

    -- Left axis
    self.pixel:setPosition(self.parent.absPosition[1] + marginX - axisWidth, self.parent.absPosition[2] + marginY)
    self.pixel:setDimension(axisWidth, self.parent.size[2] - marginY)
    self.pixel:setColor(unpack(self.AXIS_COLOR))
    self.pixel:render()

    -- Bottom axis
    self.pixel:setPosition(self.parent.absPosition[1] + marginX, self.parent.absPosition[2] + marginY)
    self.pixel:setDimension(self.parent.size[1] - marginX, axisHeight)
    self.pixel:render()

    -- Segments
    self.pixel:setColor(unpack(self.GRID_COLOR))
    self.pixel:setDimension(nudgeWidth, lineHeight)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    local segmentHeight = (self.parent.size[2] - marginY) / 5
    local segmentValue = self.maxValue / 5

    for i = 0, 5 do
        self.pixel:setPosition(
            self.parent.absPosition[1] + marginX - nudgeWidth,
            self.parent.absPosition[2] + marginY + i * segmentHeight)
        self.pixel:render()

        renderText(
            self.parent.absPosition[1] + marginX - nudgeWidth * 1.5,
            self.parent.absPosition[2] + marginY + i * segmentHeight - getTextHeight(self.axisTextSize, tostring(self.maxValue)) / 2,
            self.axisTextSize, tostring(math.ceil(i * segmentValue)))
    end

    -- Values
    local valueFactor = (self.parent.size[2] - marginY - lineHeight) / self.maxValue

    for day, price in ipairs(self.data) do
        self.pixel:setDimension(valueWidth - lineWidth, price * valueFactor)
        self.pixel:setPosition(self.parent.absPosition[1] + marginX + valueWidth * (day - 1),
                               self.parent.absPosition[2] + marginY + lineHeight)

        if day == self.currentDay then
            self.pixel:setColor(unpack(self.TODAY_COLOR))
        else
            self.pixel:setColor(unpack(self.LINE_COLOR))
        end

        self.pixel:render()
    end

    -- Reset
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function ssGraph:setData(data)
    self.data = data

    self.maxValue = 1
    self.minValue = 5000
    for _, value in ipairs(data) do
        self.maxValue = math.max(self.maxValue, value)
        self.minValue = math.min(self.minValue, value)
    end

    -- Don't round off too much
    local roundoff = math.floor(math.min(self.maxValue / 4, ssGraph.MAX_ROUNDOFF))

    self.maxValue = (math.ceil(self.maxValue / roundoff) + 1) * roundoff
    self.minValue = (math.floor(self.minValue / roundoff) - 1) * roundoff
end

function ssGraph:setYUnit(unit)
    self.yUnit = unit
end

function ssGraph:setCurrentDay(day)
    self.currentDay = day
end
