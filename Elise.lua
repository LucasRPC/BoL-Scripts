--[[ Script AutoUpdater ]]
local version = "1"
local Author = "Da Vinci & RK1K"
local ScriptName = "Black Widow"
local AUTOUPDATE = true
local ran = math.random
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/LucasRPC/BoL-Scripts/Elise.lua".."?rand="..ran(3500,5500)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local FileName = _ENV.FILE_NAME
local mh = myHero
local champ = mh.charName

if champ ~= "Elise" then return end
function OnLoad() Updater() end
function OnUnload()
    print("<b><font color=\"#000000\"> | </font><font color=\"#FFFFFF\">DVRK Elise</font><font color=\"#000000\"> | </font></b><font color=\"#00FFFF\"> Re/Un Loaded succesfully")
end
local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local Spiderform = false
local RefreshTime = 0.4
local CastableItems = {
    Tiamat      = { Range = 300 , Slot   = function() return FindItemSlot("TiamatCleave") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("TiamatCleave") ~= nil and mh:CanUseSpell(FindItemSlot("TiamatCleave")) == READY) end, Damage = function(target) return getDmg("TIAMAT", target, mh) end},
    Bork        = { Range = 650 , Slot   = function() return FindItemSlot("SwordOfFeastAndFamine") end,  reqTarget = true,  IsReady                     = function() return (FindItemSlot("SwordOfFeastAndFamine") ~= nil and mh:CanUseSpell(FindItemSlot("SwordOfFeastAndFamine")) == READY) end, Damage = function(target) return getDmg("RUINEDKING", target, mh) end},
    Bwc         = { Range = 650 , Slot   = function() return FindItemSlot("BilgewaterCutlass") end,  reqTarget = true,  IsReady                         = function() return (FindItemSlot("BilgewaterCutlass") ~= nil and mh:CanUseSpell(FindItemSlot("BilgewaterCutlass")) == READY) end, Damage = function(target) return getDmg("BWC", target, mh) end},
    Hextech     = { Range = 750 , Slot   = function() return FindItemSlot("HextechGunblade") end,  reqTarget = true,    IsReady                         = function() return (FindItemSlot("HextechGunblade") ~= nil and mh:CanUseSpell(FindItemSlot("HextechGunblade")) == READY) end, Damage = function(target) return getDmg("HXG", target, mh) end},
    Blackfire   = { Range = 750 , Slot   = function() return FindItemSlot("BlackfireTorch") end,  reqTarget = true,   IsReady                           = function() return (FindItemSlot("BlackfireTorch") ~= nil and mh:CanUseSpell(FindItemSlot("BlackfireTorch")) == READY) end, Damage = function(target) return getDmg("BLACKFIRE", target, mh) end},
    Youmuu      = { Range = mh.range + mh.boundingRadius + 350 , Slot   = function() return FindItemSlot("YoumusBlade") end,  reqTarget = false,  IsReady                              = function() return (FindItemSlot("YoumusBlade") ~= nil and mh:CanUseSpell(FindItemSlot("YoumusBlade")) == READY) end, Damage = function(target) return 0 end},
    Randuin     = { Range = 500 , Slot   = function() return FindItemSlot("RanduinsOmen") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("RanduinsOmen") ~= nil and mh:CanUseSpell(FindItemSlot("RanduinsOmen")) == READY) end, Damage = function(target) return 0 end},
    TwinShadows = { Range = 1000, Slot   = function() return FindItemSlot("ItemWraithCollar") end,  reqTarget = false,  IsReady                         = function() return (FindItemSlot("ItemWraithCollar") ~= nil and mh:CanUseSpell(FindItemSlot("ItemWraithCollar")) == READY) end, Damage = function(target) return 0 end},
}

AddLoadCallback(function()

    local function UpdateSimpleLib()
        if FileExist(LIB_PATH .. "SimpleLib.lua") then
          require("SimpleLib")
        else
          DownloadFile("https://raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua", LIB_PATH .. "SimpleLib.lua", function() UpdateSimpleLib() end)
        end
    end

    UpdateSimpleLib()

    if OrbwalkManager.GotReset then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() _arrangePriorities() end, 10)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100, DAMAGE_MAGIC)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 625, Type = SPELL_TYPE.TARGETTED}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 950, Width = 80, Delay = 0.25, Speed = 1600, Aoe = false, Collision = true, Type = SPELL_TYPE.LINEAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 1075, Width = 80, Delay = 0.25, Speed = 1600, Aoe = false, Collision = true, Type = SPELL_TYPE.LINEAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 0, Type = SPELL_TYPE_SELF}):AddDraw()

    Menu:addSubMenu(champ.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(champ.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addSubMenu("HumanForm Combo", "hcombo")
    		    Menu.Combo.hcombo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.hcombo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.hcombo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
						Menu.Combo.hcombo:addParam("eaim","E Aimed", SCRIPT_PARAM_ONKEYDOWN,false, GetKey("T"))
        Menu.Combo:addSubMenu("SpiderForm Combo", "scombo")
            Menu.Combo.scombo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.scombo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.scombo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("autos", "Switch Spider if target is Cocooned", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("autoh", "Switch Human if QWE on Cooldown", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("rdist", "Minimum distance to R 300*", SCRIPT_PARAM_SLICE, 300,100,500)

    Menu:addSubMenu(champ.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Harass Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(champ.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
				Menu.LaneClear:addParam("Q", "Use Q If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("Mana", "Clear Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(champ.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Combo:permaShow("autos")
        Menu.Combo:permaShow("autoh")
        Menu.Combo:permaShow("rdist")
        Menu.Harass:permaShow("Mana")
        Menu.LaneClear:permaShow("Mana")
        Menu.Keys.HarassToggle = false
end)

AddTickCallback(function()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    end
    if Menu.Keys.HarassToggle then Harass() end
end)

function OnTick()
	for i, enemy in ipairs(GetEnemyHeroes()) do
    if Menu.Combo.hcombo.eaim and Spiderform == false then
			E:Cast(enemy)
    end
	end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end

function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
      local eh = enemy.health
      local ed = enemy.dead
        if ValidTarget(enemy, TS.range) and eh > 0 and eh/enemy.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= eh and not Spiderform then
                if Menu.KillSteal.useQ and Q:Damage(enemy) >= eh and not ed then Q:Cast(enemy) end
                if Menu.KillSteal.useW and W:Damage(enemy) >= eh and not ed then W:Cast(enemy) end
                if Menu.KillSteal.useE and E:Damage(enemy) >= eh and not ed then E:Cast(enemy) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= eh and not ed then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if not E:IsReady() and not Q:IsReady() and not W:IsReady() and not usingW and R:IsReady() and GetDistance(target) > Menu.Combo.rdist and Menu.Combo.autoh then
            CastSpell(_R)
        end
        if Menu.Combo.hcombo.useW and not Spiderform then
            W:Cast(target)
        end
		if Menu.Combo.hcombo.useQ and not Spiderform then
            Q:Cast(target)
        end
        if Menu.Combo.hcombo.useE and not Spiderform then
            E:Cast(target)
        end
        if Menu.Combo.scombo.useW then
            CastWs(target)
        end
        if Menu.Combo.scombo.useQ then
            CastQs(target)
        end
        if Menu.Combo.scombo.useE then
            CastEs(target)
        end
        UseItems(target)
    end
end

function CastQs(target)
    if Q:IsReady() and Spiderform then
        Q.Range = 475
        Q:Cast(target)
    elseif not Spiderform then
        Q.Range = 625
    end
end

function CastWs(target)
    if W:IsReady() and Spiderform and ValidTarget(target, 200) then
        CastSpell(_W)
    end
end

function CastEs(target)
  local valid = ValidTarget(target, 965)
    if E:IsReady() and Spiderform and not usingE and valid and GetDistanceSqr(target) > 475*475 then
        CastSpell(_E)
    end
    if E:IsReady() and Spiderform and usingE and valid then
        CastSpell(_E, target)
    end
end

function Harass()
    local target = TS.target
    local mana = mh.mana / mh.maxMana * 100
    if mana >= Menu.Harass.Mana then
        if ValidTarget(target) then
            if Menu.Harass.useQ and not Spiderform then
                Q:Cast(target)
            end
            if Menu.Harass.useW and not Spiderform then
                W:Cast(target)
            end
            if Menu.Harass.useE and not Spiderform then
                E:Cast(target)
            end
        end
    end
end

function Clear()
    local mana = mh.mana / mh.maxMana * 100
    if mana >= Menu.LaneClear.Mana then
        if Menu.LaneClear.useQ then
            Q:LaneClear()
        end
        if Menu.LaneClear.useW then
            W:LaneClear()
        end
    end

    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW then
        W:JungleClear()
    end
end

function OnApplyBuff(source, unit, buff)
    if source and buff and source.isMe and buff.name then
        if buff.name:lower():find("eliser") then
            Spiderform = true
        elseif buff.name:lower():find("elisespidere") then
            usingE = true
        elseif buff.name:lower():find("elisespiderw") then
            usingW = true
        end
    end
end

function OnRemoveBuff(unit, buff)
    if unit and buff and unit.isMe and buff.name then
        if buff.name:lower():find("eliser") then
            Spiderform = false
        elseif buff.name:lower():find("elisespidere") then
            usingE = false
        elseif buff.name:lower():find("elisespiderw") then
            usingW = false
        end
    end
end

function coconbuff(unit)
    return TargetHaveBuff("EliseHumanE", unit)
end

function Cocoonedcheck()
    if Spiderform then return end
    if not Spiderform then
        if Config.Combo.autos and ValidTarget(target, 800) and coconbuff(target) and R:IsReady() then
            CastSpell(_R)
        end
    end
end

    function GetOverkill()
        return (100 + Menu.Combo.Overkill)/100
    end

function GetBestCombo(target)
    if not IsValidTarget(target) then return false, false, false, false, 0 end
    local q = {false}
    local w = {false}
    local e = {false}
    local r = {false}
    local damagetable = PredictedDamage[target.networkID]
    if damagetable ~= nil then
        local time = damagetable[6]
				local t1 = os.clock()
        if os.clock() - time <= RefreshTime then
            return damagetable[1], damagetable[2], damagetable[3], damagetable[4], damagetable[5]
        else
            if Q:IsReady() then q = {false, true} end
            if W:IsReady() then w = {false, true} end
            if E:IsReady() then e = {false, true} end
            if R:IsReady() then r = {false, true} end
            local bestdmg = 0
            local best = {Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady()}
            local dmg, mana = GetComboDamage(target, Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady() )
            bestdmg = dmg
            if dmg > target.health then
                for qCount = 1, #q do
                    for wCount = 1, #w do
                        for eCount = 1, #e do
                            for rCount = 1, #r do
                                local d, m = GetComboDamage(target, q[qCount], w[wCount], e[eCount], r[rCount])
                                if d >= target.health and mh.mana >= m then
                                    if d < bestdmg then
                                        bestdmg = d
                                        best = {q[qCount], w[wCount], e[eCount], r[rCount]}
                                    end
                                end
                            end
                        end
                    end
                end
                --return best[1], best[2], best[3], best[4], bestdmg
                damagetable[1] = best[1]
                damagetable[2] = best[2]
                damagetable[3] = best[3]
                damagetable[4] = best[4]
                damagetable[5] = bestdmg
                damagetable[6] = os.clock()
            else
                local table2 = {false,false,false,false}
                local bestdmg, mana = 0, 0
                for qCount = 1, #q do
                    for wCount = 1, #w do
                        for eCount = 1, #e do
                            for rCount = 1, #r do
                                local d, m = GetComboDamage(target, q[qCount], w[wCount], e[eCount], r[rCount])
                                if d > bestdmg and mh.mana > m then
                                    table2 = {q[qCount],w[wCount],e[eCount],r[rCount]}
                                    bestdmg = d
                                end
                            end
                        end
                    end
                end
                --return table2[1],table2[2],table2[3],table2[4], bestdmg
                damagetable[1] = table2[1]
                damagetable[2] = table2[2]
                damagetable[3] = table2[3]
                damagetable[4] = table2[4]
                damagetable[5] = bestdmg
                damagetable[6] = os.clock()
            end
            return damagetable[1], damagetable[2], damagetable[3], damagetable[4], damagetable[5]
        end
    else
        local dmg, mana = GetComboDamage(target, Q:IsReady(), W:IsReady(), E:IsReady(), R:IsReady())
        PredictedDamage[target.networkID] = {false, false, false, false, dmg, os.clock() - RefreshTime * 2}
        return GetBestCombo(target)
    end
end

function GetComboDamage(target, q, w, e, r)
    local comboDamage = 0
    local currentManaWasted = 0
    if IsValidTarget(target) then
        if q then
            comboDamage = comboDamage + Q:Damage(target)
            currentManaWasted = currentManaWasted + Q:Mana()
        end
        if w then
            comboDamage = comboDamage + W:Damage(target)
            currentManaWasted = currentManaWasted + W:Mana()
        end
        if e then
            comboDamage = comboDamage + E:Damage(target)
            currentManaWasted = currentManaWasted + E:Mana()
        end
        if r then
            comboDamage = comboDamage + R:Damage(target)
            currentManaWasted = currentManaWasted + R:Mana()
        end
        if Ignite:IsReady() then comboDamage = comboDamage + Ignite:Damage(target) end
        comboDamage = comboDamage + getDmg("AD", target, mh) * 2
    end
    comboDamage = comboDamage * GetOverkill()
    return comboDamage, currentManaWasted
end

function Cast_Item(item, target)
    if item.IsReady() and ValidTarget(target, item.Range) then
        if item.reqTarget then
            CastSpell(item.Slot(), target)
        else
            CastSpell(item.Slot())
        end
    end
end

function UseItems(unit)
    if ValidTarget(unit) then
        for _, item in pairs(CastableItems) do
            Cast_Item(item, unit)
        end
    end
end

function PrintMessage(arg1, arg2)
    local a, b = "", ""
    if arg2 ~= nil then
        a = arg1
        b = arg2
    else
        a = ScriptName
        b = arg1
    end
    print("<font color=\"#6699ff\"><b>" .. a .. ":</b></font> <font color=\"#FFFFFF\">" .. b .. "</font>")
end

--[[ AutoUpdater by Jaikor ]]
function Updater()
	if AUTOUPDATE then
		local ServerData = GetWebResult(UPDATE_HOST, "/LucasRPC/BoL-Scripts/version/Elise.version")
			if ServerData then
				ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
					if ServerVersion then
						if tonumber(version) < ServerVersion then
							DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for DVRK Elise... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
							DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
							DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">DVRK Elise</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
						else
							DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">DVRK Elise</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
						end
					end
				else
			DelayAction(function() print("<font color=\"#FFFFFF\">DVRK Elise - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
		end
	end
end
