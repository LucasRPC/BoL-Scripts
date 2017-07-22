local ScriptName = "Spray and Pray"
local Author = "Da Vinci"
local version = 1
local AUTOUPDATE = true
local ran = math.random
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/LucasRPC/BoL-Scripts/Twitch.lua".."?rand="..ran(3500,5500)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local FileName = _ENV.FILE_NAME

if myHero.charName ~= "Twitch" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local DrawBars = {}
local DeadlyVenom = {}
local DeadlyVenomJungle = {}
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

    for _, target in pairs(GetEnemyHeroes()) do
            DeadlyVenom[target.networkID] = {
                stacks = 0,
                time = 0
            }
        end

    UpdateSimpleLib()
    DelayAction(function()
        print("<b><font color=\"#000000\"> | </font><font color=\"#FFFFFF\">Twitch: </font> <font color=\"#4AA02C\">Spray and Pray</font><font color=\"#000000\"> | </font></b><font color=\"#00FFFF\"> Loaded succesfully")
    end, 10)
    if OrbwalkManager.GotReset then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."21072017")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = myHero.boundingRadius, Type = SPELL_TYPE.SELF}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 950, Width = 275, Delay = 0.25, Speed = 1750, Aoe = true, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 1200, Type = SPELL_TYPE.SELF}):AddDraw()
    R = _Spell({Slot = _R, DamageName = "R", Range = 850, Type = SPELL_TYPE.SELF}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})

    TS:AddToMenu(Menu)

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addSubMenu("                    | Q Settings |", "Q")
            Menu.Combo.Q:addParam("UseQLowHp", "Use Q On Low Health", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.Q:addParam("QLowHp", "    Set Low Health %", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
        Menu.Combo:addSubMenu("                    | W Settings |", "W")    
            Menu.Combo.W:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addSubMenu("                    | E Settings |", "E")
            Menu.Combo.E:addParam("useE", "Use E", SCRIPT_PARAM_LIST, 2, {"Never", "ToFinish", "ForDmg"})
            Menu.Combo.E:addParam("OutOfRange", "Use E if target is Leaving E Range", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.E:addParam("EStacksLeave", "    Min Passive Stacks if Leaving:", SCRIPT_PARAM_SLICE, 4, 1, 6, 0)
        Menu.Combo:addSubMenu("                    | R Settings |", "R")
            Menu.Combo.R:addParam("useR", "Use R (Beta)", SCRIPT_PARAM_ONOFF, false)
            Menu.Combo.R:addParam("REnemies", "    Set number of grouped enemies:", SCRIPT_PARAM_SLICE, 3, 1, 5, 0)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E On number of stacks", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("EStacks", "     Set number of E stacks:", SCRIPT_PARAM_SLICE, 4, 1, 6, 0)
        Menu.Harass:addParam("Mana", "Harass Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("W", "Use W If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)
        Menu.LaneClear:addParam("Mana", "Clear Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        --Menu.JungleClear:addParam("useE", "Jungle KS E Settings", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useE", "Killsteal with E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Drawing Settings", "D")
        Menu.D:addParam("PassiveStacks", "Draw Passive Stack Number", SCRIPT_PARAM_ONOFF, true)
        Menu.D:addParam("PassiveStacksOutline", "Draw Outline to Text", SCRIPT_PARAM_ONOFF, true)
        Menu.D:addParam("PassiveStackscolor", "Passive Stack Number Colour", SCRIPT_PARAM_COLOR, {255,180,255,0})
        Menu.D:addParam("poisonTimer", "Draw Poison Stack Time", SCRIPT_PARAM_ONOFF, true)
        Menu.D:addParam("PassiveStacksCountdowncolor", "Poison Time Colour", SCRIPT_PARAM_COLOR, {255,0,255,255})
        Menu.D:addParam("DrawEnemySpellCooldowns", "Draw Enemy Spell Cooldowns", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("Marathon", "Run Run Run", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
        Menu.Keys:addParam("Recall", "Invi Recall", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("B"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys:permaShow("Marathon")
        Menu.Keys.HarassToggle = false
        Menu.Keys.Marathon = false
        Menu.Keys.Recall = false
end

function OnUnload()
     print("<b><font color=\"#000000\"> | </font><font color=\"#FFFFFF\">Twitch: </font> <font color=\"#4AA02C\">Spray and Pray</font><font color=\"#000000\"> | </font></b><font color=\"#00FFFF\"> Re/Un Loaded succesfully")
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
    if Menu.Keys.Marathon then
       myHero:MoveTo(mousePos.x, mousePos.z)
       CastSpell(_Q)
    end
    if Q:IsReady() and Menu.Combo.Q.UseQLowHp and myHero.health / myHero.maxHealth <= Menu.Combo.Q.QLowHp / 100 and CountEnemyHeroInRange(600, myHero) > 1 then
        CastSpell(_Q)
    end
    if Menu.Keys.Recall then
       CastSpell(_Q)
    end
    for _, target in pairs(GetEnemyHeroes()) do
        if DeadlyVenom[target.networkID] ~= nil then
            if DeadlyVenom[target.networkID].stacks > 6 then
                DeadlyVenom[target.networkID].stacks = 6
            end
            if DeadlyVenom[target.networkID].stacks > 0 then
                if os.clock() >= DeadlyVenom[target.networkID].time then
                    DeadlyVenom[target.networkID] = {
                        stacks = 0,
                        time = 0
                    }
                end
            end
        end
    end
    for _, target in pairs(minionManager(MINION_JUNGLE, 99999).objects) do
        if DeadlyVenomJungle[target.networkID] ~= nil then
            if DeadlyVenomJungle[target.networkID].stacks > 6 then
                DeadlyVenomJungle[target.networkID].stacks = 6
            end
            if DeadlyVenomJungle[target.networkID].stacks > 0 then
                if os.clock() >= DeadlyVenomJungle[target.networkID].time then
                    DeadlyVenomJungle[target.networkID] = {
                        stacks = 0,
                        time = 0,
                        name = nil
                    }
                end
            end
        end
    end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end

function CountEntitiesInRange(entity, range)
    count = 0
    for i = 1, heroManager.iCount do
        currentEnemy = heroManager:GetHero(i)
        if currentEnemy.team ~= myHero.team and range >= GetDistance(currentEnemy, entity) and not currentEnemy.dead and currentEnemy.visible then
            count = count + 1
        end
    end
    return count
end


function KillSteal()
    for idx, target in ipairs(GetEnemyHeroes()) do
        if ValidTarget(target, TS.range) and target.health > 0 and target.health/target.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(target)
            if dmg >= target.health then
                if Menu.KillSteal.useE  and not target.dead then
                    if DeadlyVenom[target.networkID] ~= nil then
                        if GetEDmg_Twitch(target) > target.health then
                            CastSpell(_E)
                        end
                    end 
                end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(target) >= target.health and not target.dead then Ignite:Cast(target) end
        end
    end
end


function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if Menu.Combo.W.useW then
            W:Cast(target)
        end
        if Menu.Combo.E.useE > 1 then

            if Menu.Combo.E.useE == 2 then 
                if DeadlyVenom[target.networkID] ~= nil and E:IsReady() then
                    if GetEDmg_Twitch(target) > target.health then
                        CastSpell(_E)
                    end
                end
            elseif Menu.Combo.E.useE == 3 then
                if DeadlyVenom[target.networkID] ~= nil then
                    if DeadlyVenom[target.networkID].stacks >= 5 and E:IsReady() then
                        CastSpell(_E)
                    end
                end
            end
        end
        if Menu.Combo.E.OutOfRange then
            if DeadlyVenom[target.networkID] ~= nil then
                if DeadlyVenom[target.networkID].stacks >= Menu.Combo.E.EStacksLeave and GetDistanceSqr(target) > (E.Range-150)*(E.Range-150) then
                    CastSpell(_E)
                end
            end
        end
        if Menu.Combo.R.useR and R:IsReady() and GetDistance(myHero, target) <= R.Range and CountEntitiesInRange(target, 350) >= Menu.Combo.R.REnemies then
            CastSpell(_R)
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
            if Menu.Harass.useE then
                if DeadlyVenom[target.networkID] ~= nil then
                    if DeadlyVenom[target.networkID].stacks >= Menu.Harass.EStacks then
                        CastSpell(_E)
                    end
                end                
            end
        end
    end
end


function Clear()
    local mana = myHero.mana / myHero.maxMana * 100
    if mana >= Menu.LaneClear.Mana then
        if Menu.LaneClear.useW then
            W:LaneClear({NumberOfHits = Menu.LaneClear.W})
        end
    end
                
    if Menu.JungleClear.useW then
        W:JungleClear()
    end
    if Menu.JungleClear.useE then
        JungleMinions:update()
        for i, minion in pairs(JungleMinions.objects) do
            if minion.health > 0 and E:Damage(minion) > minion.health then
                print("CastingE")
                CastSpell(_E)
            end
        end
    end
end

function GetJungleMinion(off)
    local offset = off ~= nil and off or 0
    for i, minion in pairs(JungleMinions.objects) do
        if IsValidTarget(minion) then
            if OrbwalkManager:InRange(minion) then
                return minion
            end
        end
    end
    return nil
end

function GetEDmg_Twitch(target)
    if myHero:GetSpellData(_E).level < 1 then
        return 0
    end
    if E:IsReady() then
        if DeadlyVenom[target.networkID] ~= nil then
            local BaseDamage = { 20, 35, 50, 65, 80}
            local StackDamage = { 15, 20, 25, 30, 35}
            local trueDmg = BaseDamage[myHero:GetSpellData(_E).level] + (((StackDamage[myHero:GetSpellData(_E).level]) + ((myHero.ap * (1 + myHero.apPercent)) * 0.2) + (myHero.addDamage * 0.25)) * DeadlyVenom[target.networkID].stacks)
                FinalDmg = trueDmg * (100 / (100 + target.armor))
            return FinalDmg
        elseif DeadlyVenomJungle[target.networkID] ~= nil then
            local BaseDamage = { 20, 35, 50, 65, 80}
            local StackDamage = { 15, 20, 25, 30, 35}
            local trueDmg = BaseDamage[myHero:GetSpellData(_E).level] + (((StackDamage[myHero:GetSpellData(_E).level]) + ((myHero.ap * (1 + myHero.apPercent)) * 0.2) + (myHero.addDamage * 0.25)) * DeadlyVenomJungle[target.networkID].stacks)
                FinalDmg = trueDmg * (100 / (100 + target.armor))
            return FinalDmg
        else
            return 0
        end
    else
        return 0
    end
end


function OnUpdateBuff(target, buff, stacks)
    if target and buff and buff.name then
        if target.type == myHero.type then
            if buff.name == "TwitchDeadlyVenom" then
                DeadlyVenom[target.networkID] = {
                    stacks = DeadlyVenom[target.networkID].stacks + 1,
                    time = os.clock() + 6
                }
            end
            if buff.name == "TwitchVenomCaskDebuff" then
                DeadlyVenom[target.networkID] = {
                    stacks = DeadlyVenom[target.networkID].stacks + 1,
                    time = os.clock() + 6
                }
            end
        end
        if target.type ~= myHero.type then
            if buff.name == "TwitchDeadlyVenom" then
                if DeadlyVenomJungle[target.networkID] ~= nil then
                    if DeadlyVenomJungle[target.networkID].stacks == 6 then
                        DeadlyVenomJungle[target.networkID].time = os.clock() + 6
                    end
                end
            end
        end
    end
end

function OnRemoveBuff(target, buff)
    if target and buff and buff.name then
        if buff.name == "TwitchDeadlyVenom" then
            if target.type == myHero.type then
                DeadlyVenom[target.networkID] = {
                    stacks = 0,
                    time = 0
                }
            end
        end
    end
    if target and buff then
        if target.isMe and buff.name == "TwitchFullAutomatic" then
            ValidR = false
        end
    end
end


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

function OnDraw()
    if myHero.dead then return end

    if Menu.D.DrawEnemySpellCooldowns then
        DrawEntityCooldown(GetEnemyHeroes())
    end

    for _, target in pairs(GetEnemyHeroes()) do 
        if target.visible and not target.dead and DeadlyVenom[target.networkID] ~= nil and DeadlyVenom[target.networkID].stacks >= 1 then
            local feetdraw = WorldToScreen(D3DXVECTOR3(target.x, target.y, target.z))
            if Menu.D.PassiveStacks then
                if  Menu.D.PassiveStacksOutline then
                    DrawTextFilter("Stacks:", 25, feetdraw.x + 2, feetdraw.y + 2, ARGB(255, 0, 0, 0))
                    DrawTextFilter("" .. tostring(DeadlyVenom[target.networkID].stacks), 25, feetdraw.x + 82, feetdraw.y + 2, ARGB(255, 0, 0, 0))
                end
                DrawTextFilter("Stacks:", 25, feetdraw.x, feetdraw.y, ARGB(255, 255, 255, 255))
                DrawTextFilter("" .. tostring(DeadlyVenom[target.networkID].stacks), 25, feetdraw.x + 80, feetdraw.y, ARGB(table.unpack( Menu.D.PassiveStackscolor)))
            end
            if   Menu.D.poisonTimer then
                local function roundToFirstDecimal(seconds)
                    return math.ceil(seconds * 10) * 0.1
                end
                if  Menu.D.PassiveStacksOutline then
                    DrawTextFilter("Time:", 25, feetdraw.x + 2, feetdraw.y + 22, ARGB(255, 0, 0, 0))
                    DrawTextFilter("" .. roundToFirstDecimal(DeadlyVenom[target.networkID].time - os.clock()), 25, feetdraw.x + 62, feetdraw.y + 22, ARGB(255, 0, 0, 0))
                end
                DrawTextFilter("Time:", 25, feetdraw.x, feetdraw.y + 20, ARGB(255, 255, 255, 255))
                DrawTextFilter("" .. roundToFirstDecimal(DeadlyVenom[target.networkID].time - os.clock()), 25, feetdraw.x + 60, feetdraw.y + 20, ARGB(table.unpack( Menu.D.PassiveStacksCountdowncolor)))
            end
        end
    end

    for _, bar in pairs(DrawBars) do
        local starttime = 0
        local endtime = 0
        local target = nil
        local inc = false
        local alpha, red, green, blue, alphafade, redfade, greenfade, bluefade = 255
        for v,k in pairs(bar) do
            if v == 1 then 
                target = objManager:GetObjectByNetworkId(k)
            elseif v == 2 then
                starttime = k
            elseif v == 3 then
                endtime = k
            elseif v == 4 then
                alpha = k
            elseif v == 5 then
                red = k
            elseif v == 6 then
                green = k
            elseif v == 7 then
                blue = k
            elseif v == 8 then
                alphafade = k
            elseif v == 9 then
                redfade = k
            elseif v == 10 then
                greenfade = k
            elseif v == 11 then
                bluefade = k
            elseif v == 12 then
                inc = k
            end
        end
        if starttime < endtime and starttime < os.clock() and endtime > os.clock() then
            local lenght = 130
            local deltat = endtime - starttime
            local mult = endtime - os.clock()
            local multiplier = mult/deltat
            multiplier = multiplier
            if not inc then
                lenght = lenght * multiplier
            else
                lenght = 130 - lenght * multiplier
            end
            alphaN = (alpha * multiplier) + (alphafade - (alphafade * multiplier))
            redN = (red * multiplier) + (redfade - (redfade * multiplier))
            greenN = (green * multiplier) + (greenfade - (greenfade * multiplier))
            blueN = (blue * multiplier) + (bluefade - (bluefade * multiplier))
            if multiplier >= 0 then
                local barPos = GetUnitHPBarPos(target)
                local barOffset = GetUnitHPBarOffset(target)
                local baseX = barPos.x - 69 + barOffset.x * 150
                local baseY = barPos.y + barOffset.y * 50 + 12.5
                local yoffset = 0
                if settings.draws.otherTwitch.lineoffset == 1 then
                    yoffset = 10
                elseif settings.draws.otherTwitch.lineoffset == 2 then
                    yoffset = 30
                elseif settings.draws.otherTwitch.lineoffset == 3 then
                    yoffset = - 30
                elseif settings.draws.otherTwitch.lineoffset == 4 then
                    yoffset = - 60
                end
                local px = baseX
                local py = baseY + yoffset
                local cx = baseX + lenght
                local cy = baseY + yoffset
                DrawLineFilter(px, py, cx, cy, 10, ARGB(alphaN, redN, greenN, blueN))
            end
        end
    end
end

function DrawTextFilter(text, size, x, y, colour)
    DrawText(text, size, x, y, colour)
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

function DrawCooldownLine(target, starttime, endtime, alpha, red, green, blue, alphafade, redfade, greenfade, bluefade, inc)
    if not target then
        target = myHero
    end
    if not starttime then
        error("starttime required")
    end
    if not endtime then
        error("endtime required")
    end
    if not alpha then
        alpha = 255
    end
    if not red then
        red = 255 end
    if not green then
        green = 255
    end
    if not blue then
        blue = 255
    end
    if not inc then
        inc = false
    end
    if not alphafade then
        alphafade = alpha
    end
    if not redfade then
        redfade = red
    end
    if not greenfade then
        greenfade = green
    end
    if not bluefade then
        bluefade = blue
    end
    local nb = {}
    table.insert(nb,target.networkID)
    table.insert(nb,starttime)
    table.insert(nb,endtime)
    table.insert(nb,alpha)
    table.insert(nb,red)
    table.insert(nb,green)
    table.insert(nb,blue)
    table.insert(nb,alphafade)
    table.insert(nb,redfade)
    table.insert(nb,greenfade)
    table.insert(nb,bluefade)
    table.insert(nb,inc)
    table.insert(DrawBars, nb)
end

function DrawEntityCooldown(entity)
    local QSpellNotReady = true
    local WSpellNotReady = true
    local ESpellNotReady = true
    local RSpellNotReady = true
    local CoolDownQ = false
    local CoolDownW = false
    local CoolDownE = false
    local CoolDownR = false
    for _, target in pairs(entity) do
        if target ~= nil and target.visible and not target.dead then
            local barPos = GetHPBarPosCooldown(target)
            if OnScreen(barPos.x, barPos.y) then
                CoolDownTrackerQ = math.ceil(target:GetSpellData(SPELL_1).currentCd)
                CoolDownTrackerW = math.ceil(target:GetSpellData(SPELL_2).currentCd)
                CoolDownTrackerE = math.ceil(target:GetSpellData(SPELL_3).currentCd)
                CoolDownTrackerR = math.ceil(target:GetSpellData(SPELL_4).currentCd)
                spellColorQ = ARGB(255, 255, 0, 0)
                spellColorW = ARGB(255, 255, 0, 0)
                spellColorE = ARGB(255, 255, 0, 0)
                spellColorR = ARGB(255, 255, 0, 0)
                if CoolDownTrackerQ == nil or CoolDownTrackerQ == 0 then
                    CoolDownTrackerQ = "Q"
                    CoolDownQ = true
                else
                    CoolDownQ = false
                end
                if CoolDownTrackerW == nil or CoolDownTrackerW == 0 then
                    CoolDownTrackerW = "W"
                    CoolDownW = true
                else
                    CoolDownW = false
                end
                if CoolDownTrackerE == nil or CoolDownTrackerE == 0 then
                    CoolDownTrackerE = "E"
                    CoolDownE = true
                else
                    CoolDownE = false
                end
                if CoolDownTrackerR == nil or CoolDownTrackerR == 0 then
                    CoolDownTrackerR = "R"
                    CoolDownR = true
                else
                    CoolDownR = false
                end
                if target:GetSpellData(SPELL_1).level > 0 then
                    spellColorQ = ARGB(255, 255, 255, 255)
                    QSpellNotReady = false
                end
                if target:GetSpellData(SPELL_2).level > 0 then
                    spellColorW = ARGB(255, 255, 255, 255)
                    WSpellNotReady = false
                end
                if target:GetSpellData(SPELL_3).level > 0 then
                    spellColorE = ARGB(255, 255, 255, 255)
                    ESpellNotReady = false
                end
                if target:GetSpellData(SPELL_4).level > 0 then
                    spellColorR = ARGB(255, 255, 255, 255)
                    RSpellNotReady = false
                end
                DrawRectangleFilter(barPos.x - 6, barPos.y, 85, 20, 0xFF000000)
                if CoolDownQ and not QSpellNotReady then
                    DrawRectangleFilter(barPos.x - 4, barPos.y + 2, 17, 16, 0x8033CC00)
                elseif not CoolDownQ then
                    DrawRectangleFilter(barPos.x - 4, barPos.y + 2, 17, 16, 0x80FF0000)
                end
                if CoolDownW and not WSpellNotReady then
                    DrawRectangleFilter(barPos.x + 17, barPos.y + 2, 17, 16, 0x8033CC00)
                elseif not CoolDownW then
                    DrawRectangleFilter(barPos.x + 17, barPos.y + 2, 17, 16, 0x80FF0000)
                end
                if CoolDownE and not ESpellNotReady then
                    DrawRectangleFilter(barPos.x + 38, barPos.y + 2, 17, 16, 0x8033CC00)
                elseif not CoolDownE then
                    DrawRectangleFilter(barPos.x + 38, barPos.y + 2, 17, 16, 0x80FF0000)
                end
                if CoolDownR and not RSpellNotReady then
                    DrawRectangleFilter(barPos.x + 59, barPos.y + 2, 17, 16, 0x8033CC00)
                elseif not CoolDownR then
                    DrawRectangleFilter(barPos.x + 59, barPos.y + 2, 17, 16, 0x80FF0000)
                end
                DrawTextFilter(" " .. CoolDownTrackerQ, 15, barPos.x-5+2, barPos.y + 2, spellColorQ)
                DrawTextFilter(" " .. CoolDownTrackerW, 15, barPos.x+15+2, barPos.y + 2, spellColorW)
                DrawTextFilter("  " .. CoolDownTrackerE, 15, barPos.x+35+2, barPos.y + 2, spellColorE)
                DrawTextFilter("  " .. CoolDownTrackerR, 15, barPos.x+54+2, barPos.y + 2, spellColorR)
            end
        end
    end
end

function GetHPBarPosCooldown(enemy)
    enemy.barData = {PercentageOffset = {x = -0.05, y = 0}}
    local barPos = GetUnitHPBarPos(enemy)
    local barPosOffset = GetUnitHPBarOffset(enemy)
    local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
    local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
    local BarPosOffsetX = 171
    local BarPosOffsetY = 46
    local CorrectionY = 39
    local StartHpPos = 31
    barPos.x = math.floor(barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos)
    barPos.y = math.floor(barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY)
    local StartPos = Vector(barPos.x , barPos.y, 0)
    local EndPos = Vector(barPos.x + 108 , barPos.y , 0)
    return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function DrawRectangleFilter(x, y, size, width, colour)
    DrawRectangle(x, y, size, width, colour)
end

function RemoveCooldownLine(target)
    for _, bar in pairs(DrawBars) do
        local delete = false
        for k, v in pairs(bar) do
            if k == 1 then
                if v == target.networkID then
                    delete = true
                end
            end
        end
        if delete == true then
            table.clear(bar)
        end
    end
end


function Updater()
    if AUTOUPDATE then
        local ServerData = GetWebResult(UPDATE_HOST, "/LucasRPC/BoL-Scripts/version/Kayn.version")
            if ServerData then
                ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
                    if ServerVersion then
                        if tonumber(version) < ServerVersion then
                            DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for Spray and Pray... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
                            DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
                            DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">Twitch: </font> <font color=\"#4AA02C\">Spray and Pray</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
                        else
                            DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">Twitch: </font> <font color=\"#4AA02C\">Spray and Pray</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
                        end
                    end
                else
            DelayAction(function() print("<font color=\"#FFFFFF\">Twitch: Spray and Pray - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
        end
    end
end
