----------------------------------------------------------------------------------------------------
-- RECT OVERLAY
----------------------------------------------------------------------------------------------------
-- Purpose:  Drawing a rect and in rects
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssRectOverlay = {}
local ssRectOverlay_mt = Class(ssRectOverlay)

function ssRectOverlay:new(parentElement)
    local overlay = {}
    setmetatable(overlay, ssRectOverlay_mt)

    overlay.parent = parentElement

    if ssRectOverlay.g_overlay == nil then
        local width, height = getNormalizedScreenValues(1, 1)
        ssRectOverlay.g_overlay = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)
    end

    return overlay
end

function ssRectOverlay:render(x, y, width, height, color, boxHeight)
    if color ~= nil then
        ssRectOverlay.g_overlay:setColor(unpack(color))
    else
        ssRectOverlay.g_overlay:setColor(1, 1, 1, 1)
    end

    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderOverlay(ssRectOverlay.g_overlay.overlayId, x, y, width, height)
end

function ssRectOverlay:renderText(x, y, fontSize, text, boxHeight, boxWidth)
    local height = getTextHeight(fontSize, text)

    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    if boxWidth ~= nil then
        local width = getTextWidth(fontSize, text)
        x = x + (boxWidth - width) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderText(x, y, fontSize, text)
end

function ssRectOverlay:renderOverlay(overlay, x, y, width, height, boxHeight, boxWidth)
    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    if boxWidth ~= nil then
        x = x + (boxWidth - width) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderOverlay(overlay.overlayId, x, y, width, height)
end
