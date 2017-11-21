----------------------------------------------------------------------------------------------------
-- DIALOG FOR THE MEASURE TOOL
----------------------------------------------------------------------------------------------------
-- Purpose:  Shows measurement data
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssMeasureToolDialog = {}

local ssMeasureToolDialog_mt = Class(ssMeasureToolDialog, DialogElement)

function ssMeasureToolDialog:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssMeasureToolDialog_mt
    end
    local self = DialogElement:new(target, custom_mt)

    self.isBackAllowed = false
    self.inputDelay = 250

    return self
end

function ssMeasureToolDialog:onCreate()
    self.defaultDialogHeight = self.dialogElement.size[2]
    self.defaultDialogBgHeight = self.dialogBgElement.size[2]

    if self.dialogTextElement ~= nil then
        local defaultTextHeight, _ = self.dialogTextElement:getTextHeight()
        self.defaultDialogHeight = self.defaultDialogHeight - defaultTextHeight
        self.defaultDialogBgHeight = self.defaultDialogBgHeight - defaultTextHeight
        self.defaultText = self.dialogTextElement.text
    end

    self:setDialogType(DialogElement.TYPE_INFO)
    self.defaultBackText = self.backButton.text
end

function ssMeasureToolDialog:onOpen()
    ssMeasureToolDialog:superClass().onOpen(self)

    self.inputDelay = self.time + 250

    if GS_IS_CONSOLE_VERSION then
        FocusManager:setFocus(self.contentList)
    else
        FocusManager:setFocus(self.backButton)
    end

    if self.backButtonConsole ~= nil then
        FocusManager:setFocus(self.backButtonConsole)
    end
end

function ssMeasureToolDialog:onClose()
    ssMeasureToolDialog:superClass().onClose(self)

    self.contentList:deleteListItems()
    self:setTitle("")
end

function ssMeasureToolDialog:onClickBack(forceBack, usedMenuButton)
    if self.inputDelay < self.time then
        self:close()

        if self.onOk ~= nil then
            if self.target ~= nil then
                self.onOk(self.target, self.args)
            else
                self.onOk(self.args)
            end
        end
    end
end

function ssMeasureToolDialog:setCallback(onOk, target, args)
    self.onOk = onOk
    self.target = target
    self.args = args
end

function ssMeasureToolDialog:setTitle(text)
    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
    end
end

function ssMeasureToolDialog:setData(data)
    self.data = data
    self:updateContent()
end

function ssMeasureToolDialog:updateContent()
    self.contentList:deleteListItems()

    for i, item in ipairs(self.data) do
        self.currentItem = item
        self.currentItemIsOdd = i % 2 == 0

        local row = self.contentItemTemplate:clone(self.contentList)
        row:updateAbsolutePosition()
    end

    self.currentItem = nil
end

function ssMeasureToolDialog:onCreateItemBg(element)
    if self.currentItem ~= nil then
        if self.currentItemIsOdd == true then
            element:applyProfile(element.profile .. "Odd")
        end
    end
end

function ssMeasureToolDialog:onCreateItemIcon(element)
    if self.currentItem ~= nil then
        element:setImageFilename(g_seasons.modDir .. "resources/gui/measureTool.dds")
        element:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(getNormalizedUVs(self.currentItem.iconUVs)))
    end
end

function ssMeasureToolDialog:onCreateItemText(element)
    if self.currentItem ~= nil then
        element:setText(self.currentItem.text)

        if self.currentItem.hasIssue == true then
            element:applyProfile(element.profile .. "Issue")
        end
    end
end
