local ScriptName = "Two-Face Kayn"
local Author = "Da Vinci"
local version = 1.1
local AUTOUPDATE = true
local ran = math.random
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/LucasRPC/BoL-Scripts/TFKayn.lua".."?rand="..ran(3500,5500)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local FileName = _ENV.FILE_NAME

if myHero.charName ~= "Kayn" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local lastDash  
local RefreshTime = 0.4
local RP, KaynP, Darkin, AS, Kayn = nil, nil, nil, nil, nil
local CastableItems = {
    Tiamat      = { Range = 300 , Slot   = function() return FindItemSlot("TiamatCleave") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("TiamatCleave") ~= nil and myHero:CanUseSpell(FindItemSlot("TiamatCleave")) == READY) end, Damage = function(target) return getDmg("TIAMAT", target, myHero) end},
    Titanic     = { Range = myHero.range + myHero.boundingRadius + 350 , Slot   = function() return FindItemSlot("TitanicHydraCleave") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("TitanicHydraCleave") ~= nil and myHero:CanUseSpell(FindItemSlot("TitanicHydraCleave")) == READY) end, Damage = function(target) return getDmg("TITANIC", target, myHero) end},
    Bork        = { Range = 450 , Slot   = function() return FindItemSlot("SwordOfFeastAndFamine") end,  reqTarget = true,  IsReady                     = function() return (FindItemSlot("SwordOfFeastAndFamine") ~= nil and myHero:CanUseSpell(FindItemSlot("SwordOfFeastAndFamine")) == READY) end, Damage = function(target) return getDmg("RUINEDKING", target, myHero) end},
    Bwc         = { Range = 400 , Slot   = function() return FindItemSlot("BilgewaterCutlass") end,  reqTarget = true,  IsReady                         = function() return (FindItemSlot("BilgewaterCutlass") ~= nil and myHero:CanUseSpell(FindItemSlot("BilgewaterCutlass")) == READY) end, Damage = function(target) return getDmg("BWC", target, myHero) end},
    Hextech     = { Range = 400 , Slot   = function() return FindItemSlot("HextechGunblade") end,  reqTarget = true,    IsReady                         = function() return (FindItemSlot("HextechGunblade") ~= nil and myHero:CanUseSpell(FindItemSlot("HextechGunblade")) == READY) end, Damage = function(target) return getDmg("HXG", target, myHero) end},
    Blackfire   = { Range = 750 , Slot   = function() return FindItemSlot("BlackfireTorch") end,  reqTarget = true,   IsReady                           = function() return (FindItemSlot("BlackfireTorch") ~= nil and myHero:CanUseSpell(FindItemSlot("BlackfireTorch")) == READY) end, Damage = function(target) return getDmg("BLACKFIRE", target, myHero) end},
    Youmuu      = { Range = myHero.range + myHero.boundingRadius + 350 , Slot   = function() return FindItemSlot("YoumusBlade") end,  reqTarget = false,  IsReady                              = function() return (FindItemSlot("YoumusBlade") ~= nil and myHero:CanUseSpell(FindItemSlot("YoumusBlade")) == READY) end, Damage = function(target) return 0 end},
    Randuin     = { Range = 500 , Slot   = function() return FindItemSlot("RanduinsOmen") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("RanduinsOmen") ~= nil and myHero:CanUseSpell(FindItemSlot("RanduinsOmen")) == READY) end, Damage = function(target) return 0 end},
    TwinShadows = { Range = 1000, Slot   = function() return FindItemSlot("ItemWraithCollar") end,  reqTarget = false,  IsReady                         = function() return (FindItemSlot("ItemWraithCollar") ~= nil and myHero:CanUseSpell(FindItemSlot("ItemWraithCollar")) == READY) end, Damage = function(target) return 0 end},
} 

function OnLoad()
    Updater()
    local function UpdateSimpleLib()
        if FileExist(LIB_PATH .. "SimpleLib.lua") then
          require("SimpleLib")
        else
          DownloadFile("https://raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua", LIB_PATH .. "SimpleLib.lua", function() UpdateSimpleLib() end)
        end
    end

    UpdateSimpleLib()
    print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\">Two Face Kayn</font><font color=\"#000000\"> | </font></b><font color=\"#00FFFF\"> Loaded succesfully")
    if OrbwalkManager.GotReset then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052017")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 560, Width = 0, Delay = 0.15, Speed = 500, Aoe = true, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 700, Width = 100, Delay = 0.55, Speed = 500, Aoe = true, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 400, Type = SPELL_TYPE.SELF}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 550, Type = SPELL_TYPE.TARGETTED}):AddDraw()

    TS:AddToMenu(Menu)

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_LIST, 2, {"Never", "WithPred", "MousePos"})
        Menu.Combo:addParam("useQGP", "Gapclose with Q", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useR", "Use R (Beta)", SCRIPT_PARAM_ONOFF, false)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_LIST, 2, {"Never", "WithPred", "MousePos"})
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Harass Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("Q", "Use Q If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("W", "Use W If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)
        Menu.LaneClear:addParam("Mana", "Clear Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("KillSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

        Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
            Menu.Auto:addSubMenu("Use Q To Evade", "UseQ")
            _Evader(Menu.Auto.UseQ):CheckCC():AddCallback(
                function(target)
                    if Q:IsReady() and IsValidTarget(target) and Menu.Auto.Q2 then
                        local Position = Vector(myHero) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular() * 350
                        local Position2 = Vector(myHero) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular2() * 350
                        if not Collides(Position) then
                            Q:CastToVector(Position)
                        elseif not Collides(Position2) then
                            Q:CastToVector(Position2)
                        else
                            Q:CastToVector(Position)
                        end
                    end
                end)
            Menu.Auto:addParam("Q2", "Use Q To Evade", SCRIPT_PARAM_ONOFF, false)
            --[RVADE-START]--
            Menu.Auto:addSubMenu("Use R To Evade", "UseR")
            _Evader(Menu.Auto.UseR):CheckCC():AddCallback(
                function(target)
                    if Menu.Auto.R2 and R:IsReady() and IsValidTarget(target) then
                        R:Cast(target)
                    end
                end)
            Menu.Auto:addParam("R2", "Use R To Evade", SCRIPT_PARAM_ONOFF, false)
            --[RVADE-END]-- 
            Menu.Auto:addSubMenu("Use Darkin W To Interrupt", "UseW")
                _Interrupter(Menu.Auto.UseW):CheckChannelingSpells():CheckGapcloserSpells():AddCallback(function(target) if Darkin == true then W:Cast(target)end end)


    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("Marathon", "Run Run Run", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys:permaShow("Marathon")
        Menu.Keys.HarassToggle = false
        Menu.Keys.Marathon = false
end

function OnUnload()
     print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\">Two Face Kayn</font><font color=\"#000000\"> | </font></b><font color=\"#00FFFF\"> Re/Un Loaded succesfully")
 end

function OnTick()
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
    if AS then
        W.Delay = 0.6
        W.Range = 900
        R.Range = 750
    end
    if Menu.Keys.Marathon then
       myHero:MoveTo(mousePos.x, mousePos.z)
       CastSpell(_Q, mousePos.x, mousePos.z)
    end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end


function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health then
                if Menu.KillSteal.useQ and Q:Damage(enemy) >= enemy.health and not enemy.dead then Q:Cast(enemy) end
                if Menu.KillSteal.useW and W:Damage(enemy) >= enemy.health and not enemy.dead then W:Cast(enemy) end
                if Menu.KillSteal.useR and R:Damage(enemy) >= enemy.health and not enemy.dead then R:Cast(enemy) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if Menu.Combo.useW then
            W:Cast(target)
        end
        if Menu.Combo.useQ > 1 then
            if Menu.Combo.useQ == 2 then
                Q:Cast(target)
            elseif Menu.Combo.useQ == 3 then
                CastSpell(_Q, mousePos.x, mousePos.z)
            end
        end
        if Menu.Combo.useR and RP and (W:Damage(target)+Q:Damage(target)+R:Damage(target)> target.health) then
            R:Cast(target)
        end
        if Menu.Combo.useQGP and GetDistanceSqr(target) > 500*500 then
            CastSpell(_Q, mousePos.x, mousePos.z)
        end
        UseItems(target)  
    end
end


function Harass()
    local target = TS.target
    local mana = myHero.mana / myHero.maxMana * 100
    if mana >= Menu.Harass.Mana then
        if ValidTarget(target) then
             if Menu.Harass.useW then
                W:Cast(target)
            end
            if Menu.Harass.useQ > 1 then
                if Menu.Harass.useQ == 2 then
                    Q:Cast(target)
                elseif Menu.Harass.useQ == 3 then
                    CastSpell(_Q, mousePos.x, mousePos.z)
                end
            end
        end
    end
end


function Clear()
    local mana = myHero.mana / myHero.maxMana * 100
    if mana >= Menu.LaneClear.Mana then
        if Menu.LaneClear.useQ then
            Q:LaneClear({NumberOfHits = Menu.LaneClear.Q})
        end
        if Menu.LaneClear.useW then
            W:LaneClear({NumberOfHits = Menu.LaneClear.W})
        end
    end
                
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW then
        W:JungleClear()
    end
end

AddCreateObjCallback(
        function(obj)
    if obj == nil then return end
    if obj and obj.name and obj.type then
        if obj.name:find("Kayn_Base_R_marker_beam") then
            RP = true
        end
        if obj.name:find("Kayn_Base_Primary_R_Mark") then
            KaynP = true
        end
        if obj.name:find("Kayn_Base_Slayer") then
            Darkin = true
        end
        if obj.name:find("Kayn_Base_Assassin") then
            AS = true
        end
        if obj.name:find("Kayn_Base_Primary") then
            Kayn = true
        end
    end
end)

AddDeleteObjCallback(
        function(obj)
    if obj == nil then return end
    if obj and obj.name and obj.type then
        if obj.name:find("Kayn_Base_R_marker_beam") then
            RP = false
        end
        if obj.name:find("Kayn_Base_Primary_R_Mark") then
            RP1 = false
        end
        if obj.name:find("Kayn_Base_Slayer") then
            Darkin = false
        end
        if obj.name:find("Kayn_Base_Assassin") then
            AS = false
        end
        if obj.name:find("Kayn_Base_Primary") then
            Kayn = false
        end
    end
end)


function GetOverkill()
    local over = (100 + Menu.Combo.Overkill)/100
    return over
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
                                if d >= target.health and myHero.mana >= m then
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
                                if d > bestdmg and myHero.mana > m then 
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
        comboDamage = comboDamage + getDmg("AD", target, myHero) * 2
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

function UnitAtTower(unit)
    for i, turret in pairs(GetTurrets()) do
        if turret ~= nil then
            if turret.team ~= myHero.team then
                if GetDistance(unit, turret) <= turret.range then
                    return true
                end
            end
        end
    end
    return false
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


function Updater()
    if AUTOUPDATE then
        local ServerData = GetWebResult(UPDATE_HOST, "/LucasRPC/BoL-Scripts/version/Kayn.version")
            if ServerData then
                ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
                    if ServerVersion then
                        if tonumber(version) < ServerVersion then
                            DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for Two-Face Kayn... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
                            DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
                            DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">Two-Face Kayn</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
                        else
                            DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">Two-Face Kayn</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
                        end
                    end
                else
            DelayAction(function() print("<font color=\"#FFFFFF\">Two-Face Kayn - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
        end
    end
end
