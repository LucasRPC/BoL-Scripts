local ScriptName = "Rengar The Mighty"
local Author = "Da Vinci"
local version = 2.7

if myHero.charName ~= "Rengar" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local Ferocity = false
local Invisible = false
local isInBush = false
local isJumping = false
local LastJump = 0
local OffensiveItems = nil

function OnLoad()
    if not RequireSimpleLib() then return end

    OffensiveItems = {
        Tiamat      = _Spell({Range = 300, DamageName = "TIAMAT", Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("Cleave") end),
        Bork        = _Spell({Range = 450, DamageName = "RUINEDKING", Type = SPELL_TYPE.TARGETTED}):AddSlotFunction(function() return FindItemSlot("SwordOfFeastAndFamine") end),
        Bwc         = _Spell({Range = 400, DamageName = "BWC", Type = SPELL_TYPE.TARGETTED}):AddSlotFunction(function() return FindItemSlot("BilgewaterCutlass") end),
        Hextech     = _Spell({Range = 400, DamageName = "HXG", Type = SPELL_TYPE.TARGETTED}):AddSlotFunction(function() return FindItemSlot("HextechGunblade") end),
        Youmuu      = _Spell({Range = myHero.range + myHero.boundingRadius + 250, Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("YoumusBlade") end),
        Randuin     = _Spell({Range = 500, Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("RanduinsOmen") end),
    }

    DelayAction(function() _arrangePriorities() end, 10)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 850, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 125, Width = nil, Delay = 0.25, Speed = math.huge, Collision = false, Aoe = false}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 390, Width = 55, Delay = 0.5, Speed = math.huge, Aoe = true}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 950, Width = 50, Delay = 0.25, Speed = math.huge, Collision = true, Aoe = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
        R = _Spell({Slot = _R, DamageName = "R", Range = 700, Width = nil, Delay = nil, Speed = math.huge, Collision = false, Aoe = false}):AddDraw()

    Menu:addSubMenu(myHero.charName.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

        Menu.Combo:addSubMenu("R Cast Settings", "R")
            Menu.Combo.R:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.R:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
            Menu.Combo.R:addParam("useWhp", "(W) - Min. % HP to Cast", SCRIPT_PARAM_SLICE, 65, 0, 100, 0)
            Menu.Combo.R:addParam("useE", "Use E", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte('Z'))
            Menu.Combo.R:permaShow("useE")

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys.HarassToggle = false
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
end


function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health then
              if Menu.KillSteal.useQ and Q:Damage(enemy) >= enemy.health and not enemy.dead then Q:Cast(enemy) end
              if Menu.KillSteal.useW and W:Damage(enemy) >= enemy.health and not enemy.dead then W:Cast(enemy) end
              if Menu.KillSteal.useE and E:Damage(enemy) >= enemy.health and not enemy.dead then E:Cast(enemy) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    if ValidTarget(target) then
        if OrbwalkManager.GotReset and OrbwalkManager:InRange(target) then return end
        if not Ferocity then
        if Menu.Combo.useQ then
                Q:Cast(target)
                myHero:Attack(target)
        end
        if Menu.Combo.useW and not Invisible then W:Cast(target) end
        if Menu.Combo.useE and not Invisible and isJumping then 
                E:Cast(target)
                UseItems(target)
            elseif Menu.Combo.useE and not Invisible and not isInBush then 
                E:Cast(target)
            end
        end
        if Ferocity then
            if Menu.Combo.R.useQ then
            	Q:Cast()
            	myHero:Attack(target)
            end
            if Menu.Combo.R.useW then CastWR(target) end
            if Menu.Combo.R.useE and isJumping and Invisible then
              E:Cast(target)
              UseItems(target)
            elseif Menu.Combo.R.useE and not Invisible and not isJumping then
                E:Cast(target)
            end   
        end
        if isJumping then
		      if OrbwalkManager.GotReset then return end
        	if myHero.mana >= 5 then
                if Menu.Combo.R.useQ then Q:Cast()myHero:Attack(target) end
            	end
        	W:Cast(target)
        	E:Cast(target)
        	UseItems(target)
        	Q:Cast(target)
        	myHero:Attack(target)
        end
    end
end

function CastWR()
    if (myHero.health / myHero.maxHealth) * 100 <= Menu.Combo.R.useWhp and ValidTarget(target, TS.range) then
        W:Cast(target)
    end
end

function Harass()
    local target = TS.target
    if ValidTarget(target) then
        if Menu.Harass.useQ then
            Q:Cast(target)
        end
        if Menu.Harass.useW then
            W:Cast(target)
        end
        if Menu.Harass.useE then
            E:Cast(target)
        end
    end
end

function Clear()

        if Menu.LaneClear.useQ then
            Q:LaneClear()
        end
        if Menu.LaneClear.useW then
            W:LaneClear()
        end
        if Menu.LaneClear.useE then
            E:LaneClear()
        end
                
    if Menu.JungleClear.useE then
        E:JungleClear()
    end
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW then
        W:JungleClear()
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

function UseItems(unit)
    for _, item in pairs(OffensiveItems) do
        item:Cast(unit)
    end
end

function OnCreateObj(object)
    if object and object.valid and object.name then
        if object and GetDistanceSqr(myHero, object) < 1000 * 1000 and object.name:lower():find("rengar") then 
              if object.name:lower():find("ring") then
                  isInBush = true
              elseif object.name:lower():find("leap") then
                  isJumping = true
                  LastJump = os.clock()
              end
          end
              
              
        if object.name:find("Rengar_Base_P_Buf_Max.troy") then
            Ferocity = true
        end
        if object.name:find("Rengar_Base_R_Cas.troy") then
            Invisible = true
        end
    end
end

function OnDeleteObj(object)
    if object and object.valid and object.name then
        if object and GetDistanceSqr(myHero, object) < 1000 * 100 and object.name:lower():find("rengar") then 
              if object.name:lower():find("ring") then
                  isInBush = false
              elseif object.name:lower():find("leap") then
                  isJumping = false
              end
          end
        if object.name:find("Rengar_Base_P_Buf_Max.troy") then
          Ferocity = false
        end
        if object.name:find("Rengar_Base_R_Buf.troy") then
            Invisible = false
        end
    end
end

function RequireSimpleLib()
    if FileExist(LIB_PATH.."SimpleLib.lua") and not FileExist(SCRIPT_PATH.."SimpleLib.lua") then
        require "SimpleLib"
        if _G.SimpleLibVersion == nil then 
            print("Your SimpleLib file is wrong.")
            return false
        end
        if _G.SimpleLibVersion < 1.41 then
            print("You need the lastest version of SimpleLib. The library should autoupdate.")
            return false
        end
        return true
    elseif FileExist(LIB_PATH.."SimpleLib.lua") and FileExist(SCRIPT_PATH.."SimpleLib.lua") then
        print("SimpleLib.lua should not be in Custom Script (Only on Common folder), delete it from there...")
        return false
    else
        local function Base64Encode2(data)
            local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            return ((data:gsub('.', function(x)
                local r,b='',x:byte()
                for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
                return r;
            end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
                if (#x < 6) then return '' end
                local c=0
                for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
                return b:sub(c+1,c+1)
            end)..({ '', '==', '=' })[#data%3+1])
        end
        local SavePath = LIB_PATH.."SimpleLib.lua"
        local ScriptPath = '/BoL/TCPUpdater/GetScript5.php?script='..Base64Encode2("raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua")..'&rand='..math.random(99999999)
        local GotScript = false
        local LuaSocket = nil
        local Socket = nil
        local Size = nil
        local RecvStarted = false
        local Receive, Status, Snipped = nil, nil, nil
        local Started = false
        local File = ""
        local NewFile = ""
        if not LuaSocket then
            LuaSocket = require("socket")
        else
            Socket:close()
            Socket = nil
            Size = nil
            RecvStarted = false
        end
        Socket = LuaSocket.tcp()
        if not Socket then
            print('Socket Error')
        else
            Socket:settimeout(0, 'b')
            Socket:settimeout(99999999, 't')
            Socket:connect('sx-bol.eu', 80)
            Started = false
            File = ""
        end
        AddTickCallback(function()
            if GotScript then return end
            Receive, Status, Snipped = Socket:receive(1024)
            if Status == 'timeout' and not Started then
                Started = true
                print("Downloading a library called SimpleLib. Please wait...")
                Socket:send("GET "..ScriptPath.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
            end
            if (Receive or (#Snipped > 0)) and not RecvStarted then
                RecvStarted = true
            end

            File = File .. (Receive or Snipped)
            if File:find('</si'..'ze>') then
                if not Size then
                    Size = tonumber(File:sub(File:find('<si'..'ze>') + 6, File:find('</si'..'ze>') - 1))
                end
                if File:find('<scr'..'ipt>') then
                    local _, ScriptFind = File:find('<scr'..'ipt>')
                    local ScriptEnd = File:find('</scr'..'ipt>')
                    if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
                    local DownloadedSize = File:sub(ScriptFind + 1,ScriptEnd or -1):len()
                end
            end
            if File:find('</scr'..'ipt>') then
                local a,b = File:find('\r\n\r\n')
                File = File:sub(a,-1)
                NewFile = ''
                for line,content in ipairs(File:split('\n')) do
                    if content:len() > 5 then
                        NewFile = NewFile .. content
                    end
                end
                local HeaderEnd, ContentStart = NewFile:find('<sc'..'ript>')
                local ContentEnd, _ = NewFile:find('</scr'..'ipt>')
                if not ContentStart or not ContentEnd then
                else
                    local newf = NewFile:sub(ContentStart + 1,ContentEnd - 1)
                    local newf = newf:gsub('\r','')
                    if newf:len() ~= Size then
                        return
                    end
                    local newf = Base64Decode(newf)
                    if type(load(newf)) ~= 'function' then
                    else
                        local f = io.open(SavePath, "w+b")
                        f:write(newf)
                        f:close()
                        print("Required library downloaded. Please reload with 2x F9.")
                    end
                end
                GotScript = true
            end
        end)
        return false
    end
end
