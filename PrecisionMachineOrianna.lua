local ScriptName = "Precision Machine"
local Author = "Da Vinci"
local version = 1
local ran = math.random
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/LucasRPC/BoL-Scripts/PrecisionMachineOrianna.lua".."?rand="..ran(3500,5500)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local FileName = _ENV.FILE_NAME

if myHero.charName ~= "Orianna" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local Colors = { 
    Green   =  ARGB(255, 0, 180, 0), 
    Yellow  =  ARGB(255, 255, 215, 00),
    Red     =  ARGB(255, 255, 0, 0),
    White   =  ARGB(255, 255, 255, 255),
    Blue    =  ARGB(255, 0, 0, 255),
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
    for i = 1, objManager.maxObjects do
        local object = objManager:getObject(i)
        if object and object.name and object.valid and object.name:lower():find("doomball") then
            PosBall = object
        end
    end
    PosBall = myHero
    TimeLimit = 0.1
    LastFarmRequest = 0
    ValidDistance = 2000
    UpdateSimpleLib()
    DelayAction(function() SexyPrint("Orianna by Da Vinci Loaded Succesfully.") end, 5)
    if OrbwalkManager.GotReset then return end
    if VIP_USER then HookPackets() end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 945, DAMAGE_MAGIC)
    EnemyMinions = minionManager(MINION_ENEMY, 945, myHero, MINION_SORT_MAXHEALTH_DEC)
    JungleMinions = minionManager(MINION_JUNGLE, 600, myHero, MINION_SORT_MAXHEALTH_DEC)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052017")

    Passive = { Damage = function(target) return getDmg("P", target, myHero) end, IsReady = false}
    AA = {Range = function(target) return 620 end, Damage = function(target) return getDmg("AD", target, myHero) end }
    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 815, Width = 130, Delay = 0, Speed = 1200, Type = SPELL_TYPE.CIRCULAR, LastCastTime = 0, Collision = false, Aoe = true}):AddDraw():AddSourceFunction(function() return PosBall end):AddDrawSourceFunction(function() return myHero end)
    W = _Spell({Slot = _W, DamageName = "W", Range = 225, Width = 225, Delay = 0.25, Speed = math.huge, Type = SPELL_TYPE.SELF, LastCastTime = 0, Collision = false, Aoe = true}):AddDraw():AddSourceFunction(function() return PosBall end)
    E = _Spell({Slot = _E, DamageName = "E", Range = 1095, Width = 85, Delay = 0, Speed = 1800, Type = SPELL_TYPE.TARGETTED_ALLY, LastCastTime = 0, Collision = false, Aoe = true, Missile = nil}):AddDraw():AddSourceFunction(function() return PosBall end):AddDrawSourceFunction(function() return myHero end)
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 330, Width = 330, Delay = 0.5, Speed = math.huge, Type = SPELL_TYPE.SELF, LastCastTime = 0, Collision = false, Aoe = true, ControlPressed = false, Sent = 0}):AddDraw():AddSourceFunction(function() return PosBall end)

    TS:AddToMenu(Menu)

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("useQ","Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W If Enemies >= ", SCRIPT_PARAM_SLICE, 1, 0, 5)
        Menu.Combo:addParam("useE","Use E If Hit >=", SCRIPT_PARAM_SLICE, 1, 0, 5)
        Menu.Combo:addParam("useE2","Use E If % Health <=", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
        Menu.Combo:addParam("useR","Use R If Killable", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useR2","Use R If Enemies >=", SCRIPT_PARAM_SLICE, 3, 0, 5)
        Menu.Combo:addParam("useIgnite","Use Ignite If Killable", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ","Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW","Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE","Use E For Damage", SCRIPT_PARAM_ONOFF, false)
        Menu.Harass:addParam("useE2","Use E If % Health <=", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q If Hit >= ", SCRIPT_PARAM_SLICE, 3, 0, 10)
        Menu.LaneClear:addParam("useW", "Use W If Hit >=", SCRIPT_PARAM_SLICE, 3, 0, 10)
        Menu.LaneClear:addParam("useE", "Use E If Hit >=", SCRIPT_PARAM_SLICE, 6, 0, 10)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use R To Interrupt", "useR")
            _Interrupter(Menu.Auto.useR):CheckChannelingSpells():AddCallback(function(target) ForceR(target) end)

        Menu.Auto:addSubMenu("Use E To Initiate", "useE")
            _Initiator(Menu.Auto.useE):CheckGapcloserSpells():AddCallback(function(unit) if ValidTarget(TS.target) then CastE(unit) end end)

        Menu.Auto:addParam("useW", "Use W If Enemies >= ", SCRIPT_PARAM_SLICE, 3, 0, 5)
        Menu.Auto:addParam("useR", "Use R If Enemies >= ", SCRIPT_PARAM_SLICE, 4, 0, 5)

    Menu:addSubMenu(myHero.charName.." - Misc Settings", "Misc")
        Menu.Misc:addParam("overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Misc:addParam("BlockR", "Block R If Will Not Hit", SCRIPT_PARAM_ONOFF, true)
        Menu.Misc:addParam("developer", "Developer Mode", SCRIPT_PARAM_ONOFF, false)

    Menu:addSubMenu(myHero.charName.." - Drawing Settings", "Draw")
        _Circle({Menu = Menu.Draw, Name = "BallPosition", Text = "Ball Position", Source = function() return PosBall end, Range = 130, Color = { 255, 0, 0, 255 }, Width = 4})

        Menu.Draw:addParam("dmgCalc", "Damage Prediction Bar", SCRIPT_PARAM_ONOFF, true)


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
     SexyPrint("Script Re/Un Loaded succesfully")
 end

AddTickCallback(
    function()
        if myHero.dead or Menu == nil then return end
        TS.range = 945
        TS.target = _GetTarget()
        TS:update()
        if OrbwalkManager:IsCombo() then Combo()
        elseif OrbwalkManager:IsHarass() then Harass()
        elseif OrbwalkManager:IsClear() then Clear() 
        end
        if Menu.KillSteal.useQ or Menu.KillSteal.useW or Menu.KillSteal.useE or Menu.KillSteal.useR or Menu.KillSteal.useIgnite then KillSteal() end

        if ValidTarget(TS.target) and (Menu.Auto.useW > 0 or Menu.Auto.useR > 0) then Auto() end

        if Menu.Keys.HarassToggle then Harass() end
        if Menu.Keys.Marathon then Run() end
        if not PosBall.valid or GetDistanceSqr(myHero, PosBall) > ValidDistance * ValidDistance then 
            PosBall = myHero 
        end 
    end)

AddProcessSpellCallback(
    function(unit, spell)
        if myHero.dead or unit == nil then return end
        if not unit.isMe then return end
        if spell.name:lower():find("oriana") and spell.name:lower():find("izuna") and spell.name:lower():find("command") then Q.LastCastTime = os.clock()
        elseif spell.name:lower():find("oriana") and spell.name:lower():find("dissonance") and spell.name:lower():find("command") then W.LastCastTime = os.clock()
        elseif spell.name:lower():find("oriana") and spell.name:lower():find("redact") and spell.name:lower():find("command") then 
            E.LastCastTime = os.clock()
            DelayAction(function(pos) PosBall = pos end, E.Delay + GetDistance(spell.endPos, PosBall) / E.Speed, {spell.target})
        elseif spell.name:lower():find("oriana") and spell.name:lower():find("detonate") and spell.name:lower():find("command") then R.LastCastTime = os.clock()
        end
    end)
    
AddAnimationCallback(
    function(unit, animation)
        if unit.isMe and animation == 'Prop' then
            PosBall = myHero
        end
    end)
    
AddCreateObjCallback(
    function(obj)
        if not obj or not obj.name then return end
        if obj.name:lower():find("orianna") and obj.name:lower():find("yomu") and obj.name:lower():find("ring") and obj.name:lower():find("green") then
            PosBall = obj
        elseif obj.name:lower():find("orianna") and obj.name:lower():find("ball") and obj.name:lower():find("flash") then
            PosBall = myHero
        elseif obj.name:lower() == "missile" and (obj.spellOwner and obj.spellOwner.isMe or GetDistanceSqr(PosBall, obj) < 50 * 50) and (os.clock() - Q.LastCastTime < 0.1 or os.clock() - E.LastCastTime < 0.1) then
            PosBall = obj
        end
    end)

AddDeleteObjCallback(
    function(obj)
        if not obj or not obj.name then return end
        if obj and obj.name and obj.name:lower():find("orianna") and obj.name:lower():find("yomu") and obj.name:lower():find("ring") and obj.name:lower():find("green") and GetDistanceSqr(myHero, obj) < 150 * 150 then
            PosBall = myHero
        end
    end
    )
AddDrawCallback(
    function()
        if myHero.dead or Menu == nil then return end
        if Menu.Draw.dmgCalc then DrawPredictedDamage() end
    end
    )
AddCastSpellCallback(
        function(iSpell, startPos, endPos, targetUnit) 
            if Menu.Misc.BlockR and iSpell == 3 and CountEnemyHeroInRange(330, PosBall) == 0 then
                BlockSpell()
                SexyPrint("R Blocked!")
            end
        end)


function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if enemy.health/enemy.maxHealth <= 0.4 and ValidTarget(enemy, TS.range) and enemy.visible and enemy.health > 0  then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health and enemy.health > 0 then
                if Q:IsReady() and Menu.KillSteal.useQ and (q or Q:Damage(enemy) > enemy.health) and not enemy.dead then CastQ(enemy) end
                if W:IsReady() and Menu.KillSteal.useW and (w or W:Damage(enemy) > enemy.health) and not enemy.dead then CastW(enemy) end
                if E:IsReady() and Menu.KillSteal.useE and (e or E:Damage(enemy) > enemy.health) and not enemy.dead then CastE(enemy) end
                if R:IsReady() and Menu.KillSteal.useR and (r or R:Damage(enemy) > enemy.health) and not enemy.dead then CastR(enemy) end
                if (((w or W:Damage(enemy) > enemy.health) and Menu.KillSteal.useW) or ((r or R:Damage(enemy) > enemy.health) and Menu.KillSteal.useR)) and (Menu.KillSteal.useQ or Menu.KillSteal.useE) and not enemy.dead then ThrowBallTo(enemy, R.Width) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) > enemy.health and enemy.health > 0 then Ignite:Cast(enemy) end
        end
    end
end

function CastQ(target)
    if ValidTarget(target, Q.Range) and Q:IsReady() then
        if GetDistanceSqr(PosBall, target) > math.pow(Q.Range * 1.8, 2) then CastE(myHero) end
        Q:Cast(target)
    end
end

function CastW(target)
    if W:IsReady() and ValidTarget(target, Q.Range + W.Width/2) then
        if PosBall and PosBall.name and PosBall.name:lower():find("missile") then return end
        W:Cast(target)
    end
end

function CastE(unit)
    if unit ~= nil then
        if E:IsReady() and unit.valid and unit.team == myHero.team and GetDistanceSqr(myHero, unit) < E.Range * E.Range then
            CastSpell(E.Slot, unit)
        elseif E:IsReady() and unit.valid and unit.team ~= myHero.team then
            local table = nil
            if unit.type:lower():find("hero") then 
                table = GetEnemyHeroes()
            else 
                EnemyMinions:update()
                if #EnemyMinions.objects > 0 then
                    table = EnemyMinions.objects 
                else
                    JungleMinions:update()
                    if #JungleMinions.objects > 0 then
                        table = JungleMinions.objects
                    end
                end
            end
            if table~= nil then
                local BestPos, BestHit = BestHitE(table)
                if BestHit~=nil and BestHit > 0 and BestPos~=nil and BestPos.team == myHero.team then
                    CastE(BestPos)
                end
            end
        end
    end
end

function CastR(target)
    if R:IsReady() and ValidTarget(target, Q.Range + R.Range) then
        if PosBall and PosBall.name and PosBall.name:lower():find("missile") then return end
        R:Cast(target)
    end
end

function Combo()
    local target = TS.target
    if ValidTarget(target) then
        if Menu.Combo.useIgnite and Ignite:IsReady() and ValidTarget(target, Ignite.Range) then 
            local q, w, e, r, dmg = GetBestCombo(target)
            if dmg >= target.health and target.health > 0 then
                Ignite:Cast(target)
            end
        end
        if Menu.Combo.useQ then 
            CastQ(target) 
        end
        if W:IsReady() and Menu.Combo.useW > 0 and #W:ObjectsInArea(GetEnemyHeroes()) >= Menu.Combo.useW then
            CastSpell(W.Slot)
        end
        if Menu.Combo.useR and R:IsReady() and #ObjectsInArea(Q.Range * 1.5, R.Delay, GetEnemyHeroes()) <= 3 then
            local q, w, e, r, dmg = GetBestCombo(target)
            if dmg >= target.health and r then
                CastR(target)
            end
        end
        if R:IsReady() and Menu.Combo.useR2 > 0 and Menu.Combo.useR2 <= #R:ObjectsInArea(GetEnemyHeroes()) then
            CastSpell(R.Slot)
        end

        if Menu.Combo.useE > 0 then
            local BestPos, Count = BestHitE(GetEnemyHeroes())
            if BestHit~=nil and BestHit >= Menu.Combo.useE and BestPos~=nil and BestPos.team == myHero.team then
                SexyPrint("UsingEX")
                CastE(BestPos)
            end
        end

        if Menu.Combo.useE2 > 0 and myHero.health/myHero.maxHealth * 100 <= Menu.Combo.useE2 and CountEnemyHeroInRange(400, myHero) >= 1 then
            CastSpell(_E, myHero)
        end
    end
end

function Harass()
    local target = TS.target
    if ValidTarget(target) and myHero.mana/myHero.maxMana * 100 >= Menu.Harass.Mana then
        if Menu.Harass.useE then CastE(target) end
        if Menu.Harass.useE2 > 0 and myHero.health/myHero.maxHealth * 100 <= Menu.Harass.useE2 and ValidTarget(target, GetAARange(target)) then CastE(myHero) end
        if Menu.Harass.useW then CastW(target) end
        if Menu.Harass.useQ then CastQ(target) end
    end
end

function Clear()
    if myHero.mana/myHero.maxMana * 100 >= Menu.LaneClear.Mana then
        EnemyMinions:update()
        for i, minion in pairs(EnemyMinions.objects) do
            if ValidTarget(minion, 945) and os.clock() - LastFarmRequest > 0.2 then
                if Menu.LaneClear.useQ > 0 and Q:IsReady() then
                    local BestPos, Count = BestHitQ(EnemyMinions.objects)
                    if BestPos ~=nil and Menu.LaneClear.useQ <= Count then
                        CastQ(BestPos)
                    end
                end

                if Menu.LaneClear.useW > 0 and W:IsReady() then
                    local Count = #W:ObjectsInArea(EnemyMinions.objects)
                    if Menu.LaneClear.useW <= Count then 
                        CastSpell(W.Slot)
                    end
                end
                if Menu.LaneClear.useE > 0 and E:IsReady() then
                    local BestPos, Count = BestHitE(EnemyMinions.objects)
                    if BestPos~=nil and Menu.LaneClear.useE <= Count then
                        CastE(BestPos)
                    end
                end
                LastFarmRequest = os.clock()
            end
        end
    end

    JungleMinions:update()
    for i, minion in pairs(JungleMinions.objects) do
        if ValidTarget(minion, 945) then 
            if Menu.JungleClear.useQ and Q:IsReady() then
                CastSpell(Q.Slot, minion.x, minion.z)
            end

            if Menu.JungleClear.useW and W:IsReady() then
                CastW(minion)
            end
            if Menu.JungleClear.useE and E:IsReady() then
                CastE(minion)
            end
        end
    end
end

function ThrowBallTo(target, width)
    local EAlly = nil
    if E:IsReady() and GetDistanceSqr(PosBall, target) > width * width then
        
        local Position = Prediction:GetPredictedPos(target, {Delay = E.Delay + GetDistance(PosBall, target)/E.Speed})
        for i = 1, heroManager.iCount do
            local ally = heroManager:GetHero(i)
            if ally.team == player.team and GetDistanceSqr(myHero, ally) < E.Range * E.Range and GetDistanceSqr(PosBall, ally) > 50 * 50  then
                local Position3 = Prediction:GetPredictedPos(ally, {Delay = E.Delay + GetDistance(PosBall, ally)/E.Speed})
                if GetDistanceSqr(Position3, Position) <= width * width then
                    if EAlly == nil then 
                        EAlly = ally
                    else
                        local Position2 = Prediction:GetPredictedPos(EAlly, {Delay = E.Delay + GetDistance(PosBall, EAlly)/E.Speed})
                        if GetDistanceSqr(Position, Position2) > GetDistanceSqr(Position, Position3) then 
                            EAlly = ally
                        end
                    end
                end
            end
        end
    end

    if EAlly~=nil and GetDistanceSqr(EAlly, target) <= width * width then
        CastE(EAlly)
    elseif Q:IsReady() then
        CastQ(target)
    end
end

function BestHitQ(objects)
    local BestPos 
    local BestHit = 0

    local function CountObjectsOnLineSegment(StartPos, EndPos, width, objects2)
        local n = 0
        for i, object in ipairs(objects2) do
            local Position = Prediction:GetPredictedPos(object, {Delay = Q.Delay + GetDistance(StartPos, object)/Q.Speed})
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, Position)
            local w = width --+ Prediction.VP:GetHitBox(object) / 3
            if isOnSegment and GetDistanceSqr(pointSegment, Position) < w * w and GetDistanceSqr(StartPos, EndPos) > GetDistanceSqr(StartPos, Position) then
                n = n + 1
            end
        end
        return n
    end
    for i, object in ipairs(objects) do
        if ValidTarget(object, Q.Range) then
            local Position = Prediction:GetPredictedPos(object, {Delay = Q.Delay + GetDistance(PosBall, object)/Q.Speed})
            local hit = CountObjectsOnLineSegment(PosBall, Position, Q.Width, objects) + 1
            if hit > BestHit then
                BestHit = hit
                BestPos = object--Vector(object)
                if BestHit == #objects then
                   break
                end
            end
        end
    end
    return BestPos, BestHit
end

function BestHitE(objects)

    local function HitE(StartPos, EndPos, width, objects)
        local n = 0
        for i, object in ipairs(objects) do
            local Position = Prediction:GetPredictedPos(object, {Delay = E.Delay + GetDistance(StartPos, object)/E.Speed})
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, Position)
            local w = width --+ Prediction.VP:GetHitBox(object) / 3
            if isOnSegment and GetDistanceSqr(pointSegment, object) < w * w and GetDistanceSqr(StartPos, EndPos) > GetDistanceSqr(StartPos, object) then
                n = n + 1
            end
        end
        return n
    end

    local tab = {}
    local BestAlly = nil 
    local BestHit = 0
    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team == player.team and hero.health > 0 then
            if GetDistanceSqr(myHero, hero) < E.Range * E.Range and GetDistanceSqr(PosBall, hero) > 50 * 50 then
                local Position = Prediction:GetPredictedPos(hero, {Delay = E.Delay + GetDistance(PosBall, hero)/E.Speed})
                local hit = HitE(PosBall, Position, E.Width, objects)
                if hit > BestHit then
                    BestHit = hit
                    BestAlly = hero--Vector(hero)
                    if BestHit == #objects then
                       break
                    end
                end
            end
        end
    end
    return BestAlly, BestHit
    -- body
end

function Auto()
    if W:IsReady() and Menu.Auto.useW > 0 and #W:ObjectsInArea(GetEnemyHeroes()) >= Menu.Auto.useW then
        CastSpell(W.Slot)
    end
    if R:IsReady() and Menu.Auto.useR > 0 and #R:ObjectsInArea(GetEnemyHeroes()) >= Menu.Auto.useR then
        CastSpell(R.Slot)
    end
end

function Run()
    myHero:MoveTo(mousePos.x, mousePos.z)
    if E:IsReady() and GetDistanceSqr(PosBall, myHero) > W.Width * W.Width then
        CastE(myHero)
    elseif Q:IsReady() and GetDistanceSqr(PosBall, myHero) > W.Width * W.Width then
        CastSpell(Q.Slot, myHero.x, myHero.z)
    end

    if W:IsReady() and GetDistanceSqr(PosBall, myHero) < W.Width * W.Width then
        CastSpell(W.Slot)
    end
end


function ForceR(target)
    if R:IsReady() and GetDistanceSqr(target, PosBall) < R.Range * R.Range then
        CastR(target)
    elseif Q:IsReady() and GetDistanceSqr(target, PosBall) < (Q.Range + R.Width) * (Q.Range + R.Width) then
        ThrowBallTo(target, R.Width)
    end
end

function ObjectsInArea(range, delay, array)
    local objects2 = {}
    local delay = delay or 0
    if array ~= nil then
        for i, object in ipairs(array) do
            if ValidTarget(object, 815 * 2.5) then
                local Position, WillHit = Prediction:GetPredictedPos(object, {Delay = delay})
                if GetDistanceSqr(PosBall, Position) <= range * range and WillHit then
                    table.insert(objects2, object)
                end
            end
        end
    end
    return objects2
end

function ObjectsInArea(objects, range, PosBall)
    local objects2 = {}
    for i, object in ipairs(objects) do
        if ValidTarget(object) then
            if GetDistanceSqr(PosBall, object) <= range * range then
                table.insert(objects2, object)
            end
        end
    end
    return objects2
end

function CountEnemies(point, range)
    local ChampCount = 0
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) then
            if GetDistanceSqr(enemy, point) <= range*range then
                ChampCount = ChampCount + 1
            end
        end
    end
    return ChampCount
end

function SexyPrint(message)
   local sexyName = "<font color=\"#E41B17\">[<b>Precision Machine</b>]:</font>"
   local fontColor = "FFFFFF"
   print(sexyName .. " <font color=\"#" .. fontColor .. "\">" .. message .. "</font>")
end

function GetOverkill()
    local over = (100 + Menu.Misc.overkill)/100
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

function _GetTarget()
    local bestTarget = nil
    local range = TS.range
    if ValidTarget(GetTarget(), range) then
        if GetTarget().type:lower():find("hero") or GetTarget().type:lower():find("minion") then
            return GetTarget() 
        end
    end
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, range) then
            if bestTarget == nil then 
                bestTarget = enemy
            else
                local q, w, e, r, dmgEnemy = GetBestCombo(enemy)
                local q, w, e, r, dmgBest = GetBestCombo(bestTarget)
                local percentageEnemy = (enemy.health - dmgEnemy) / enemy.maxHealth
                local percentageBest = (bestTarget.health - dmgBest) / bestTarget.maxHealth

                if percentageEnemy * GetPriority(enemy) < percentageBest * GetPriority(bestTarget) then
                    bestTarget = enemy
                end
            end
        end
    end
    return bestTarget
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

function DrawPredictedDamage() 
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        local p = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
        if ValidTarget(enemy) and enemy.visible and OnScreen(p.x, p.y) then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health then
                DrawLineHPBar(dmg, "KILLABLE", enemy, true)
            else
                local spells = ""
                if q then spells = "Q" end
                if w then spells = spells .. "W" end
                if e then spells = spells .. "E" end
                if r then spells = spells .. "R" end
                DrawLineHPBar(dmg, spells, enemy, true)
            end
        end
    end
end

function GetAARange(unit)
    return ValidTarget(unit) and unit.range + unit.boundingRadius + myHero.boundingRadius / 2 or 0
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
    local ServerData = GetWebResult(UPDATE_HOST, "/LucasRPC/BoL-Scripts/version/Orianna.version")
        if ServerData then
            ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
                if ServerVersion then
                    if tonumber(version) < ServerVersion then
                        DelayAction(function() SexyPrint("New version found for Precision Machine Orianna... Version "..ServerVersion.." ") end, 3)
                        DelayAction(function() SexyPrint("Updating, please don't press F9") end, 4)
                        DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () SexyPrint("("..version.." => "..ServerVersion..") Press F9 twice to load the updated version.") end) end, 5)
                    else
                        DelayAction(function() SexyPrint("Version "..ServerVersion.."") end, 1)
                    end
                end
            else
        DelayAction(function() SexyPrint("Error while downloading version info, RE-DOWNLOAD MANUALLY.")end, 1)
    end
end
