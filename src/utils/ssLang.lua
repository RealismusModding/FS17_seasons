----------------------------------------------------------------------------------------------------
-- TRANSLATION UTILITY SCRIPT
----------------------------------------------------------------------------------------------------
-- Authors:  Rahkiin
--
-- Copyright (c) Realismus Modding, 2017
----------------------------------------------------------------------------------------------------

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

--- function to convert from Celsius to Fahrenheit
function ssLang.formatTemperature(tempCelcius)
    if ssWeatherForecast.degreeFahrenheit then
        return string.format("%iºF", ssLang.convertTempToFahrenheit(tempCelcius))
    else
        return string.format("%iºC", tempCelcius)
    end
end

function ssLang.convertTempToFahrenheit(tempCelcius)
    return mathRound(tempCelcius * 1.8 + 32, 0)
end

function ssLang.formatLength(meters)
    if g_i18n.useMiles then
        return string.format("%.1f %s", meters * 3.2808, ssLang.getText("unit_feetShort"))
    else
        return string.format("%.1f %s", meters, ssLang.getText("unit_meterShort"))
    end
end
