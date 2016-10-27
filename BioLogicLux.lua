local ScriptName = "BioLogic Lux"
local AUTOUPDATES = true
local Author = "Da Vinci"
local version = 1.3

if myHero.charName ~= "Lux" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local DefensiveItems = nil

function CheckUpdate()
    if AUTOUPDATES then
        local ToUpdate = {}
        ToUpdate.LocalVersion = version
        ToUpdate.VersionPath = "raw.githubusercontent.com/LucasRPC/BoL-Scripts/master/version/Lux.version"
        ToUpdate.ScriptPath = "raw.githubusercontent.com/LucasRPC/BoL-Scripts/master/BioLogicLux.lua"
        ToUpdate.SavePath = SCRIPT_PATH.._ENV.FILE_NAME
        ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) PrintMessage(ScriptName, "Updated to "..NewVersion..". Please reload with 2x F9.") end
        ToUpdate.CallbackNoUpdate = function(OldVersion) PrintMessage(ScriptName, "No Updates Found.") end
        ToUpdate.CallbackNewVersion = function(NewVersion) PrintMessage(ScriptName, "New Version found ("..NewVersion.."). Please wait...") end
        ToUpdate.CallbackError = function(NewVersion) PrintMessage(ScriptName, "Error while downloading.") end
        _ScriptUpdate(ToUpdate)
    end
end

function OnLoad()

    local r = _Required()
    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()
    if OrbwalkManager.GotReset then return end
    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 3500, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")
    DefensiveItems = {
            Zhonyas     = _Spell({Range = 1000, Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("ZhonyasHourglass") end),
        }
    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 1200, Width = 70, Delay = 0.25, Speed = 1200, Aoe = false, Collision = true, Type = SPELL_TYPE.LINEAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 0, Type = SPELL_TYPE.SELF}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 1100, Width = 330, Delay = 0.25, Speed = 1300, Aoe = false, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 3300, Width = 140, Delay = 1, Speed = math.huge, Collision = false, Aoe = true, Type = SPELL_TYPE.LINEAR}):AddDraw()

    Menu:addSubMenu(myHero.charName.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useR", "Use Smart R", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useR2", "Use R If Enemies >=", SCRIPT_PARAM_SLICE, math.min(#GetEnemyHeroes(), 3), 0, 5, 0)
        Menu.Combo:addParam("Zhonyas", "Use Zhonyas if HP % <=", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("E", "Use E If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useR", "Use R (Not Recomended)", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

        Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use Q To Interrupt GapClosers", "W3")
            _Interrupter(Menu.Auto.W3):CheckGapcloserSpells():AddCallback(
                function(target)
                    if Menu.Auto.W3 then
                        if Q:IsReady() then
                            Q:Cast(target)
                        end
                    end
                end
            )
        Menu.Auto:addSubMenu("Use E To Shield", "UseE")
            _Evader(Menu.Auto.UseE):CheckCC():AddCallback(
                function(target)
                    if E:IsReady() and IsValidTarget(target) then
                        E:Cast()
                    end
                end) 

    Menu:addSubMenu(myHero.charName.." - Misc Settings", "Misc")
        Menu.Misc:addParam("SetSkin", "Select Skin", SCRIPT_PARAM_LIST, 10, {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})

    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("ManualR", "Manual R (T)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
        Menu.Keys:addParam("Flee", "Flee Like a Girl", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys:permaShow("Flee")
        Menu.Keys:permaShow("ManualR")
        Menu.Keys.HarassToggle = false
        Menu.Keys.ManualR = false
        Menu.Keys.Flee = false
end

function OnTick()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    SetSkin(myHero, Menu.Misc.SetSkin)
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    end
    if Menu.Keys.HarassToggle then Harass() end
    if Menu.Keys.ManualR then Ult() end
    if Menu.Keys.Flee then TryToRun() end
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
                if Menu.KillSteal.useE and E:Damage(enemy) >= enemy.health and not enemy.dead then E:Cast(enemy) end
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
        if Menu.Combo.Zhonyas > 0 and PercentageHealth() <= Menu.Combo.Zhonyas and DefensiveItems.Zhonyas:IsReady() and Zhonyas:IsReady() then
            DefensiveItems.Zhonyas:Cast()
            Zhonyas:Cast()
        end
        if Menu.Combo.useE then
            E:Cast(target)
            E:Cast(target)
        end
        if Menu.Combo.useQ then
            Q:Cast(target)
        end
        if Menu.Combo.useR and target.health < R:Damage(target) + Q:Damage(target) + E:Damage(target) then
            R:Cast(target)
        end
        if Menu.Combo.useR2 > 0 then
            if R:IsReady() then
                for i, enemy in ipairs(GetEnemyHeroes()) do
                    local CastPosition, WillHit, NumberOfHits = R:GetPrediction(enemy, {TypeOfPrediction = "VPrediction"})
                    if NumberOfHits and type(NumberOfHits) == "number" and NumberOfHits >= Menu.Combo.useR2 and WillHit then
                        CastSpell(R.Slot, CastPosition.x, CastPosition.z)
                    end
                end
            end
        end    
    end
end

function Ult()
    local target = TS.target
    if ValidTarget(target) then
        R:Cast(target)
    end
end

function TryToRun()
    local target = TS.target
    if Menu.Keys.Flee then
        myHero:MoveTo(mousePos.x, mousePos.z)
    end
    if ValidTarget(target) and Q:IsReady() then
        Q:Cast(target)
    end
end

function Harass()
    local target = TS.target
    if myHero.mana / myHero.maxMana * 100 >= Menu.Harass.Mana then
        if ValidTarget(target) then
            if Menu.Harass.useQ then
                Q:Cast(target)
            end
            if Menu.Harass.useE then
                E:Cast(target)
                E:Cast(target)
            end
        end
    end
end

function Clear()
    if myHero.mana / myHero.maxMana * 100 >= Menu.Harass.Mana then
        if Menu.LaneClear.useQ then
            Q:LaneClear()
        end
        if Menu.LaneClear.useE then
            E:LaneClear({NumberOfHits = Menu.LaneClear.E})
        end
    end
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useE then
        E:JungleClear()
    end
end

function PercentageMana(u)
    local unit = u ~= nil and u or myHero
    return unit and unit.mana/unit.maxMana * 100 or 0
end

function PercentageHealth(u)
    local unit = u ~= nil and u or myHero
    return unit and unit.health/unit.maxHealth * 100 or 0
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
