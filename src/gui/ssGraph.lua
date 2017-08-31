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
ssGraph.AXIS_COLOR = {0.5, 0.5, 0.5, 1}
ssGraph.TEXT_COLOR = {1, 1, 1, 1}
ssGraph.TODAY_COLOR = InGameMenu.FRUIT_COLORS[false][5]
ssGraph.MAX_ROUNDOFF = 50

ssGraph.LINE_COLOR = InGameMenu.FRUIT_COLORS[false][1]

function ssGraph:new(parentElement)
    local self = {}
    setmetatable(self, ssGraph_mt)

    self.parent = parentElement
    self.yUnit = ""
    self.data = {}

    self.rect = ssRectOverlay:new(parentElement)

    local width, height = getNormalizedScreenValues(1, 1)
    self.pixel = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)

    self.seasonIconWidth, self.seasonIconHeight = getNormalizedScreenValues(30, 30)

    self.seasons = {}
    self.seasons[ssEnvironment.SEASON_SPRING] = Overlay:new("hud_spring", g_seasons.baseUIFilename, 0, 0, self.seasonIconWidth, self.seasonIconHeight)
    self.seasons[ssEnvironment.SEASON_SPRING]:setUVs(getNormalizedUVs({8, 216, 128, 128}))
    self.seasons[ssEnvironment.SEASON_SUMMER] = Overlay:new("hud_summer", g_seasons.baseUIFilename, 0, 0, self.seasonIconWidth, self.seasonIconHeight)
    self.seasons[ssEnvironment.SEASON_SUMMER]:setUVs(getNormalizedUVs({144, 216, 128, 128}))
    self.seasons[ssEnvironment.SEASON_AUTUMN] = Overlay:new("hud_autumn", g_seasons.baseUIFilename, 0, 0, self.seasonIconWidth, self.seasonIconHeight)
    self.seasons[ssEnvironment.SEASON_AUTUMN]:setUVs(getNormalizedUVs({280, 216, 128, 128}))
    self.seasons[ssEnvironment.SEASON_WINTER] = Overlay:new("hud_winter", g_seasons.baseUIFilename, 0, 0, self.seasonIconWidth, self.seasonIconHeight)
    self.seasons[ssEnvironment.SEASON_WINTER]:setUVs(getNormalizedUVs({416, 216, 128, 128}))

    self.maxValue = 0
    self.minValue = 0
    self.title = 0
    self.currentDay = 1

    self.transitionHeaders = ssUtil.getTransitionHeaders()

    _, self.axisTextSize = getNormalizedScreenValues(0, 12)
    _, self.titleTextSize = getNormalizedScreenValues(0, 18)

    return self
end

function ssGraph:delete()
    self.pixel:delete()
end

function ssGraph:draw()
    local pixel = self.pixel

    setTextColor(unpack(ssGraph.TEXT_COLOR))

    local marginX, marginY = getNormalizedScreenValues(20, 20)
    local lineWidth, lineHeight = getNormalizedScreenValues(1, 1)
    local axisWidth, axisHeight = getNormalizedScreenValues(2, 2)
    local valueWidth = (self.parent.size[1] - marginX) / table.getn(self.data)
    local nudgeWidth, nudgeHeight = getNormalizedScreenValues(8, 8)

    -- Title
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(
        self.parent.absPosition[1] + marginX + (self.parent.size[1] - marginX) / 2,
        self.parent.absPosition[2] + self.parent.size[2] + 2 * getTextHeight(self.titleTextSize, "A"),
        self.titleTextSize,
        string.format("%s, %s / %s", self.title, g_i18n:getCurrencySymbol(true), self.yUnit)
        )

    -- Left axis
    pixel:setPosition(self.parent.absPosition[1] + marginX - axisWidth, self.parent.absPosition[2] + marginY)
    pixel:setDimension(axisWidth, self.parent.size[2] - marginY)
    pixel:setColor(unpack(self.AXIS_COLOR))
    pixel:render()

    -- Bottom axis
    pixel:setPosition(self.parent.absPosition[1] + marginX, self.parent.absPosition[2] + marginY)
    pixel:setDimension(self.parent.size[1] - marginX, axisHeight)
    pixel:render()

    -- Segments
    pixel:setDimension(nudgeWidth, lineHeight)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    local segmentHeight = (self.parent.size[2] - marginY) / 5
    local segmentValue = self.maxValue / 5

    if self.maxValue > 0 then
        for i = 0, 5 do
            pixel:setPosition(
                self.parent.absPosition[1] + marginX - nudgeWidth,
                self.parent.absPosition[2] + marginY + i * segmentHeight)
            pixel:render()

            renderText(
                self.parent.absPosition[1] + marginX - nudgeWidth * 1.5,
                self.parent.absPosition[2] + marginY + i * segmentHeight - getTextHeight(self.axisTextSize, tostring(self.maxValue)) / 2.3,
                self.axisTextSize,
                tostring(math.ceil(g_i18n:getCurrencyFactor() * i * segmentValue)))
        end

        -- Values
        local valueFactor = (self.parent.size[2] - marginY - lineHeight) / self.maxValue

        for day, price in ipairs(self.data) do
            pixel:setDimension(valueWidth - lineWidth, price * valueFactor)
            pixel:setPosition(self.parent.absPosition[1] + marginX + valueWidth * (day - 1),
                                   self.parent.absPosition[2] + marginY + lineHeight)

            if day == self.currentDay then
                pixel:setColor(unpack(self.TODAY_COLOR))
            else
                pixel:setColor(unpack(self.LINE_COLOR))
            end

            pixel:render()
        end
    end

    ------ Draw footer

    local _, footerHeight = getNormalizedScreenValues(0, 50)
    local footerWidth = self.parent.size[1] - marginX
    local _, footerTextSize = getNormalizedScreenValues(0, 9)

    local footerX = self.parent.absPosition[1] + marginX
    local footerY = self.parent.absPosition[2] + marginY - footerHeight
    local transitionWidth = footerWidth / 12

    local separatorWidth = getNormalizedScreenValues(1, 0)

    pixel:setPosition(footerX, footerY)
    pixel:setDimension(footerWidth, footerHeight)
    pixel:setColor(0.017, 0.017, 0.017, 1)
    pixel:render()

    -- Draw separator blocks in the header
    pixel:setColor(0.0284, 0.0284, 0.0284, 1)
    for i = 2, g_seasons.environment.TRANSITIONS_IN_YEAR do
        if i == 4 or i == 7 or i == 10 then
            pixel:setPosition(footerX + (i - 1) * transitionWidth,
                              footerY)
            pixel:setDimension(separatorWidth, footerHeight)
        else
            pixel:setPosition(footerX + (i - 1) * transitionWidth,
                              footerY + self.seasonIconHeight)
            pixel:setDimension(separatorWidth, footerHeight - self.seasonIconHeight)
        end

        pixel:render()
    end

    -- Season icons
    for s = 0, 3 do
        local season = self.seasons[s]

        season:setPosition(footerX + s * (footerWidth / 4) + footerWidth / 8 - self.seasonIconWidth / 2,
                           footerY)
        season:render()
    end

    -- Write numbers in headers
    setTextColor(0.5, 0.5, 0.5, 1)
    setTextAlignment(RenderText.ALIGN_CENTER)
    for i = 1, g_seasons.environment.TRANSITIONS_IN_YEAR do
        renderText(
            footerX + (i - 0) * transitionWidth - transitionWidth / 2,
            footerY + self.seasonIconHeight + footerTextSize / 2,
            footerTextSize,
            self.transitionHeaders[(i - 1) % 3 + 1]
            )
    end

    setTextColor(1, 1, 1, 1)

    -- Reset
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function ssGraph:setData(data)
    self.data = data

    self.maxValue = 0
    self.minValue = 5000
    for _, value in ipairs(data) do
        self.maxValue = math.max(self.maxValue, value)
        self.minValue = math.min(self.minValue, value)
    end

    -- Don't round off too much
    local roundoff = math.floor(math.min(self.maxValue / 4, ssGraph.MAX_ROUNDOFF))

    self.maxValue = (math.ceil(self.maxValue / roundoff) + 1) * roundoff
    self.minValue = (math.floor(self.minValue / roundoff) - 1) * roundoff

    self.transitionHeaders = ssUtil.getTransitionHeaders()
end

function ssGraph:setYUnit(unit)
    self.yUnit = unit
end

function ssGraph:setCurrentDay(day)
    self.currentDay = day
end

function ssGraph:setTitle(title)
    self.title = title
end
