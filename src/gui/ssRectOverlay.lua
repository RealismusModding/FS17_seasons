----------------------------------------------------------------------------------------------------
-- RECT OVERLAY
----------------------------------------------------------------------------------------------------
-- Purpose:  Drawing rectangles and lines, and texts in boxes
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssRectOverlay = {}
local ssRectOverlay_mt = Class(ssRectOverlay)

function ssRectOverlay:new(parentElement)
    local self = {}
    setmetatable(self, ssRectOverlay_mt)

    self.parent = parentElement

    -- Cache for performance. If always the same image is used, drawing is much faster
    self.overlay = Overlay:new("pixel", Utils.getFilename("resources/gui/pixel.png", g_seasons.modDir), 0, 0, width, height)

    return self
end

function ssRectOverlay:delete()
    self.overlay:delete()
end

function ssRectOverlay:render(x, y, width, height, color, boxHeight)
    if color ~= nil then
        self.overlay:setColor(unpack(color))
    else
        self.overlay:setColor(1, 1, 1, 1)
    end

    if boxHeight ~= nil then
        y = y + (boxHeight - height) / 2
    end

    -- Change the origin from bottom-left to top-left because we draw from left to right, top to bottom
    x = x + self.parent.absPosition[1]
    y = self.parent.absPosition[2] + self.parent.size[2] - height - y

    renderOverlay(self.overlay.overlayId, x, y, width, height)
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
