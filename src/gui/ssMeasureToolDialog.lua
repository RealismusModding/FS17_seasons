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

    FocusManager:setFocus(self.backButton)

    if self.backButtonConsole ~= nil then
        FocusManager:setFocus(self.backButtonConsole)
    end
end

function ssMeasureToolDialog:onClose()
    ssMeasureToolDialog:superClass().onClose(self)

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
    log("Set data")
    print_r(data)

    -- local textHeight, _ = self.dialogTitleElement:getTextHeight()
    self:resizeDialog(60 * table.getn(data))
end

-- Resize to exactly fit the content
function ssMeasureToolDialog:resizeDialog(heightOffset)
    self.dialogElement:setSize(nil, self.defaultDialogHeight + heightOffset)
    self.dialogBgElement:setSize(nil, self.defaultDialogBgHeight + heightOffset)
end
