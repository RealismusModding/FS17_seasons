----------------------------------------------------------------------------------------------------
-- SEASONS HEADER GUI
----------------------------------------------------------------------------------------------------
-- Purpose:  Header (or footer) of seasons gui stuff
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssGuiSeasonsHeader = {}
local ssGuiSeasonsHeader_mt = Class(ssGuiSeasonsHeader)

function ssGuiSeasonsHeader:new(parentElement)
    local self = {}
    setmetatable(self, ssGuiSeasonsHeader_mt)

    self.parent = parentElement
    self.isFooter = false

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

    self.margin = {0, 0}

    return self
end

function ssGuiSeasonsHeader:delete()
    self.pixel:delete()

    for _, overlay in pairs(self.seasons) do
        overlay:delete()
    end
end

function ssGuiSeasonsHeader:settingsChanged()
    self.transitionHeaders = ssUtil.getTransitionHeaders()
end

function ssGuiSeasonsHeader:draw()
    if self.transitionHeaders == nil then
        -- Move here. :new is called when game starts, and in an MP game, data is not readily availabl
        self.transitionHeaders = ssUtil.getTransitionHeaders()
    end

    local pixel = self.pixel

    local _, footerHeight = getNormalizedScreenValues(0, 50)
    local footerWidth = self.parent.size[1] - self.margin[1]
    local _, textSize = getNormalizedScreenValues(0, 9)

    local footerX = self.parent.absPosition[1] + self.margin[1]
    local footerY = self.parent.absPosition[2] + self.margin[2] - footerHeight
    local transitionWidth = footerWidth / 12

    local separatorWidth = getNormalizedScreenValues(1, 0)
    local offsetY = 0

    pixel:setPosition(footerX, footerY)
    pixel:setDimension(footerWidth, footerHeight)
    pixel:setColor(0.017, 0.017, 0.017, 1)
    pixel:render()

    if self.isFooter then
        offsetY = self.seasonIconHeight
    end

    -- Draw separator blocks in the header
    pixel:setColor(0.0284, 0.0284, 0.0284, 1)
    for i = 2, g_seasons.environment.TRANSITIONS_IN_YEAR do
        if i == 4 or i == 7 or i == 10 then -- full height
            pixel:setPosition(footerX + (i - 1) * transitionWidth,
                              footerY)
            pixel:setDimension(separatorWidth, footerHeight)
        else
            pixel:setPosition(footerX + (i - 1) * transitionWidth,
                              footerY + offsetY)
            pixel:setDimension(separatorWidth, footerHeight - self.seasonIconHeight)
        end

        pixel:render()
    end

    if self.isFooter then
        offsetY = 0
    else
        offsetY = footerHeight - self.seasonIconHeight
    end

    -- Season icons
    for s = 0, 3 do
        local season = self.seasons[s]

        season:setPosition(footerX + s * (footerWidth / 4) + footerWidth / 8 - self.seasonIconWidth / 2,
                           footerY + offsetY)
        season:render()
    end

    if self.isFooter then
        offsetY = self.seasonIconHeight
    else
        offsetY = 0
    end

    -- Write numbers in headers
    setTextColor(0.5, 0.5, 0.5, 1)
    setTextAlignment(RenderText.ALIGN_CENTER)
    for i = 1, g_seasons.environment.TRANSITIONS_IN_YEAR do
        renderText(
            footerX + (i - 0) * transitionWidth - transitionWidth / 2,
            footerY + offsetY + textSize / 2, -- footer
            textSize,
            self.transitionHeaders[(i - 1) % 3 + 1]
        )
    end

    -- Reset
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function ssGuiSeasonsHeader:setIsFooter(isFooter)
    self.isFooter = isFooter
end

function ssGuiSeasonsHeader:setMargin(marginX, marginY)
    self.margin = {marginX, marginY}
end
