----------------------------------------------------------------------------------------------------
-- DIALOG FOR SHOWING TO OPTIONS WITH BACK BUTTON
----------------------------------------------------------------------------------------------------
-- Purpose:  Shows an A/B option to the player with cancel
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

ssTwoOptionDialog = {}

local ssTwoOptionDialog_mt = Class(ssTwoOptionDialog, DialogElement)

function ssTwoOptionDialog:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = ssTwoOptionDialog_mt
    end
    local self = DialogElement:new(target, custom_mt)

    self.isBackAllowed = false
    self.inputDelay = 250

    return self
end

function ssTwoOptionDialog:onCreate()
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
    self.defaultFirstText = self.firstButton.text
    self.defaultSecondText = self.secondButton.text
end

function ssTwoOptionDialog:onOpen()
    ssTwoOptionDialog:superClass().onOpen(self)

    self.inputDelay = self.time + 250

    FocusManager:setFocus(self.backButton)

    if self.backButtonConsole ~= nil then
        FocusManager:setFocus(self.backButtonConsole)
    end
end

function ssTwoOptionDialog:onClose()
    ssTwoOptionDialog:superClass().onClose(self)

    self:setTitle(nil)
    self:setText(nil)
    self:setButtonTexts(nil, nil)
end

function ssTwoOptionDialog:onClickOk()
    self:sendCallback(true, 1)
end

function ssTwoOptionDialog:onClickBack(forceBack, usedMenuButton)
    self:sendCallback(false)
end

function ssTwoOptionDialog:onClickCancel()
    self:sendCallback(true, 2)
end

function ssTwoOptionDialog:sendCallback(confirm, option)
    if self.inputDelay < self.time then
        self:close()

        if self.callbackFunc ~= nil then
            if self.target ~= nil then
                self.callbackFunc(self.target, confirm, option, self.args)
            else
                self.callbackFunc(confirm, option, self.args)
            end
        end
    end
end

function ssTwoOptionDialog:setCallback(callbackFunc, target, args)
    self.callbackFunc = callbackFunc
    self.target = target
    self.args = args
end

function ssTwoOptionDialog:setTitle(text)
    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
    end
end

function ssTwoOptionDialog:setButtonTexts(firstText, secondText)
    self.firstButton:setText(Utils.getNoNil(firstText, self.defaultFirstText))
    if self.firstButtonConsole ~= nil then
        self.firstButtonConsole:setText(Utils.getNoNil(firstText, self.defaultFirstText))
    end

    self.secondButton:setText(Utils.getNoNil(secondText, self.defaultSecondText))
    if self.secondButtonConsole ~= nil then
        self.secondButtonConsole:setText(Utils.getNoNil(secondText, self.defaultSecondText))
    end
end

function ssTwoOptionDialog:setText(text)
    if self.dialogTextElement ~= nil then
        self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))

        local textHeight, _ = self.dialogTextElement:getTextHeight()
        self:resizeDialog(textHeight)
    end
end

function ssTwoOptionDialog:resizeDialog(heightOffset)
    self.dialogElement:setSize(nil, self.defaultDialogHeight + heightOffset)
    self.dialogBgElement:setSize(nil, self.defaultDialogBgHeight + heightOffset)
end
