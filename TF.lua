--[[

ForbiddenTF
By LucasRP a.k.a DaVinci
Version: 1

Don't forget to name the file TF.lua. Otherwise the updater won't work.

If you don't want to load an specific champion just delete the line that contains the champion name (from the list below).

]]

local Champions = {

    ["TwistedFate"]         = true,

}
if not Champions[myHero.charName] then return end

--END LINE