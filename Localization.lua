local currentLocale = GetLocale()
local LOCALIZED = ({
    enUS={},
    esMX={
        ["Meeting Stone"]="Roca de encuentro",
    },
    ptBR={
        ["Meeting Stone"]="Pedra de Encontro",
    },
    deDE={
        ["Meeting Stone"]="Versammlungsstein",
    },
    esES={
        ["Meeting Stone"]="Roca de encuentro",
    },
    frFR={
        ["Meeting Stone"]="Pierre de rencontre",
    },
    ruRU={
        ["Meeting Stone"]="Камень встреч",
    },
    koKR={
        ["Meeting Stone"]="만남의 돌",
    },
    zhTW={
        ["Meeting Stone"]="集合石",
    },
    zhCN={
        ["Meeting Stone"]="集合石",
    },
})[currentLocale]

if not LOCALIZED then
    _G.StaticPopupDialogs.SSH_NOT_LOCALIZED = {
        text = ("|cffffd300SummonStoneHelper|r does not currently support the |cffffd300%s|r locale - Sorry!"):format(currentLocale),
        button1 = OKAY,
        timeout = 0,
        whileDead = true,
    }
    StaticPopup_Show("SSH_NOT_LOCALIZED")
    return
    -- @todo figure out what meeting stones are called in other locales
end

(select(2,...)).LocalizedString = setmetatable(LOCALIZED,{__index=function(t,k) return k end})
