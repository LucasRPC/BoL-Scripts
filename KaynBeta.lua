local ScriptName = "Kayn"
local Author = "Da Vinci"
local version = 1

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

    local r = _Required()
    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()
    if OrbwalkManager.GotReset then return end
    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 550, Width = 100, Delay = 0.15, Speed = 500, Aoe = true, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 700, Width = 175, Delay = 0.55, Speed = 500, Aoe = true, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 400, Type = SPELL_TYPE.SELF}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 550, Type = SPELL_TYPE.TARGETTED}):AddDraw()

    Menu:addSubMenu(myHero.charName.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        --Menu.Combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useR", "Use R (Beta)", SCRIPT_PARAM_ONOFF, false)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
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
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("KillSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, false)

        Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
            Menu.Auto:addSubMenu("Use Q To Evade", "UseQ")
        _Evader(Menu.Auto.UseQ):CheckCC():AddCallback(
            function(target)
                if Q:IsReady() and IsValidTarget(target) then
                    local Position = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular() * 350
                    local Position2 = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular2() * 350
                    if not Collides(Position) then
                        Q:CastToVector(Position)
                    elseif not Collides(Position2) then
                        Q:CastToVector(Position2)
                    else
                        Q:CastToVector(Position)
                    end
                end
            end)
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
      local eh = enemy.health
      local ed = enemy.dead
        if ValidTarget(enemy, TS.range) and eh > 0 and eh/enemy.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= eh then
                if Menu.KillSteal.useQ and Q:Damage(enemy) >= eh and not ed then Q:Cast(enemy) end
                if Menu.KillSteal.useW and W:Damage(enemy) >= eh and not ed then W:Cast(enemy) end
                if Menu.KillSteal.useR and R:Damage(enemy) >= eh and not ed then R:Cast(enemy) end
                --if Menu.KillSteal.KillSteal then
                    --if eh <= Q:Damage(enemy) and Q:IsReady() then
                        --Q:Cast(enemy)
                    --elseif eh <= R:Damage(enemy) then
                        --R:Cast(enemy)
                    --elseif eh <= W:Damage(enemy) then
                        ---W:Cast(enemy)
                    --elseif eh <= (Q:Damage(enemy) + W:Damage(enemy)) and Q:IsReady() and W:IsReady() then
                        --Q:Cast(enemy)
                    --elseif eh <= (Q:Damage(enemy) + W:Damage(enemy) + R:Damage(enemy)) and Q:IsReady() and W:IsReady() then
                        --Q:Cast(enemy)
                    --end
                --end

            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= eh and not ed then Ignite:Cast(enemy) end
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
        if Menu.Combo.useQ then
            Q:Cast(target)
        end
        if Menu.Combo.useR and RP then
            R:Cast(target)
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
            if Menu.Harass.useQ then
                Q:Cast(target)
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


class "_Required"
function _Required:__init()
    self.requirements = {}
    self.downloading = {}
    return self
end

function _Required:Add(t)
    assert(t and type(t) == "table", "_Required: table is invalid!")
    local name = t.Name
    assert(name and type(name) == "string", "_Required: name is invalid!")
    local url = t.Url
    assert(url and type(url) == "string", "_Required: url is invalid!")
    local extension = t.Extension ~= nil and t.Extension or "lua"
    local usehttps = t.UseHttps ~= nil and t.UseHttps or true
    table.insert(self.requirements, {Name = name, Url = url, Extension = extension, UseHttps = usehttps})
end

function _Required:Check()
    for i, tab in pairs(self.requirements) do
        local name = tab.Name
        local url = tab.Url
        local extension = tab.Extension
        local usehttps = tab.UseHttps
        if not FileExist(LIB_PATH..name.."."..extension) then
            print("Downloading a required library called "..name.. ". Please wait...")
            local d = _Downloader(tab)
            table.insert(self.downloading, d)
        end
    end
    
    if #self.downloading > 0 then
        for i = 1, #self.downloading, 1 do 
            local d = self.downloading[i]
            AddTickCallback(function() d:Download() end)
        end
        self:CheckDownloads()
    else
        for i, tab in pairs(self.requirements) do
            local name = tab.Name
            local url = tab.Url
            local extension = tab.Extension
            local usehttps = tab.UseHttps
            if FileExist(LIB_PATH..name.."."..extension) and extension == "lua" then
                require(name)
            end
        end
    end
end

function _Required:CheckDownloads()
    if #self.downloading == 0 then 
        print("Required libraries downloaded. Please reload with 2x F9.")
    else
        for i = 1, #self.downloading, 1 do
            local d = self.downloading[i]
            if d.GotScript then
                table.remove(self.downloading, i)
                break
            end
        end
        DelayAction(function() self:CheckDownloads() end, 2) 
    end 
end

function _Required:IsDownloading()
    return self.downloading ~= nil and #self.downloading > 0 or false
end

class "_Downloader"
function _Downloader:__init(t)
    local name = t.Name
    local url = t.Url
    local extension = t.Extension ~= nil and t.Extension or "lua"
    local usehttps = t.UseHttps ~= nil and t.UseHttps or true
    self.SavePath = LIB_PATH..name.."."..extension
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(usehttps and '5' or '6')..'.php?script='..self:Base64Encode(url)..'&rand='..math.random(99999999)
    self:CreateSocket(self.ScriptPath)
    self.DownloadStatus = 'Connect to Server'
    self.GotScript = false
end

function _Downloader:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.Socket = self.LuaSocket.tcp()
    if not self.Socket then
        print('Socket Error')
    else
        self.Socket:settimeout(0, 'b')
        self.Socket:settimeout(99999999, 't')
        self.Socket:connect('sx-bol.eu', 80)
        self.Url = url
        self.Started = false
        self.LastPrint = ""
        self.File = ""
    end
end

function _Downloader:Download()
    if self.GotScript then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotScript = true
    end
end

function _Downloader:Base64Encode(data)
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
