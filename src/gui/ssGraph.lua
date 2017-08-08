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
ssGraph.LINE_COLOR = {0.0742, 0.4341, 0.6939, 1}
ssGraph.AXIS_COLOR = {0.2122, 0.5271, 0.0307, 1}
ssGraph.TEXT_COLOR = {0.2122, 0.5271, 0.0307, 1}
ssGraph.GRID_COLOR = {0.2122, 0.5271, 0.0307, 0.2}

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

    return self
end

function ssGraph:delete()
    self.pixel:delete()
end

function ssGraph:draw()

    -- self.rect:render(10, 10, 400, 400, {1,1,1,1})

    self.pixel:setPosition(unpack(self.parent.absPosition))
    self.pixel:setDimension(unpack(self.parent.size))
    -- self.pixel:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_RIGHT)
    self.pixel:setColor(unpack(self.BG_COLOR))

    self.pixel:render()

    local marginX, marginY = getNormalizedScreenValues(20, 20)
    local lineWidth, lineHeight = getNormalizedScreenValues(1.5, 1.5)
    local valueWidth = (self.parent.size[1] - marginX) / table.getn(self.data)
    local nudgeWidth, nudgeHeight = getNormalizedScreenValues(8, 8)

    -- Left axis
    self.pixel:setPosition(self.parent.absPosition[1] + marginX, self.parent.absPosition[2] + marginY)
    self.pixel:setDimension(lineWidth, self.parent.size[2] - marginY)
    self.pixel:setColor(unpack(self.AXIS_COLOR))
    self.pixel:render()

    -- Bottom axis
    self.pixel:setPosition(self.parent.absPosition[1] + marginX, self.parent.absPosition[2] + marginY)
    self.pixel:setDimension(self.parent.size[1] - marginX, lineHeight)
    self.pixel:render()

    -- Zero


    -- Top value


    -- Segments
    self.pixel:setDimension(lineWidth, nudgeHeight)
    self.pixel:setColor(unpack(self.GRID_COLOR))

    for i = 1, table.getn(self.data) do
        self.pixel:setPosition(self.parent.absPosition[1] + marginX + i * valueWidth, self.parent.absPosition[2] + marginY - nudgeHeight)

        self.pixel:render()
    end

    self.pixel:setDimension(nudgeWidth, lineHeight)
    local segmentHeight = (self.parent.size[2] - marginY) / 5

    for i = 1, 5 do
        self.pixel:setPosition(self.parent.absPosition[1] + marginX - nudgeWidth, self.parent.absPosition[2] + marginY + i * segmentHeight)

        self.pixel:render()
    end

    -- Values
    self.pixel:setDimension(valueWidth, lineHeight)
    self.pixel:setColor(unpack(self.LINE_COLOR))

    local valueFactor = (self.parent.size[2] - marginY - lineHeight) / self.maxValue

    for i, value in ipairs(self.data) do
        self.pixel:setPosition(self.parent.absPosition[1] + marginX + valueWidth * (i - 1), self.parent.absPosition[2] + marginY + lineHeight + value.price * valueFactor)

        self.pixel:render()
    end

end

function ssGraph:setData(data)
    self.data = data

    self.maxValue = 1
    for _, value in ipairs(data) do
        self.maxValue = math.max(self.maxValue, value.price)
    end

    log("Data")
    print_r(self.data)
    log("max", self.maxValue)
end

function ssGraph:setYUnit(unit)
    self.yUnit = unit
end

--[[

margins around
rest: divide by numX
for each X, draw line at Y
draw axises
write axis texts

]]
