
ssLang = {}

function ssLang.getText(key, default)
    if g_i18n:hasText(key) then
        return g_i18n:getText(key)
    elseif default ~= nil then
        return default
    else
        return key
    end
end
