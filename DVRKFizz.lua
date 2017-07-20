local ScriptName = "Fizz Khalifa"
local Author = "Da Vinci & RK1K"
local version = 1
local mh = myHero
local cha = mh.charName

if cha ~= "Fizz" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local WP, WCheck = nil, nil

if FileExist(LIB_PATH .. "/CastItems.lua") then
	require "CastItems"
else
    print("Downloading Librarys...")
    DelayAction(function() DownloadFile("https://raw.githubusercontent.com/Icesythe7/GOS/master/CastItems.lua".."?rand="..math.random(1500,2500), LIB_PATH.."CastItems.lua", function () print("Successfully downloaded, SHIFT + double-press F9.") end) end, 3)
    return
end

function OnLoad()
    local r = _Required()
    local sb = string.byte
    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()
    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1400, DAMAGE_MAGIC)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 550, Type = SPELL_TYPE.TARGETTED}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 200, Type = SPELL_TYPE.SELF}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 400, Width = 330, Delay = 0.25, Speed = 1200, Aoe = true, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 1275, Width = 150, Delay = 0.25, Speed = 1300, Aoe = false, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()

    Menu:addSubMenu(cha.." - Target Selector Settings", "TS")
        Menu.TS:addTS(TS)
        _Circle({Menu = Menu.TS, Name = "Draw", Text = "Draw circle on Target", Source = function() return TS.target end, Range = 120, Condition = function() return ValidTarget(TS.target, TS.range) end, Color = {255, 255, 0, 0}, Width = 4})
        _Circle({Menu = Menu.TS, Name = "Range", Text = "Draw circle for Range", Range = function() return TS.range end, Color = {255, 255, 0, 0}, Enable = false})

    Menu:addSubMenu(cha.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addSubMenu("Q Settings", "Q")
            Menu.Combo.Q:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addSubMenu("W Settings", "W")
            Menu.Combo.W:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)    
        Menu.Combo:addSubMenu("E Settings", "E")
            Menu.Combo.E:addParam("useE", "Use Safe E", SCRIPT_PARAM_ONKEYTOGGLE, true, sb("H"))
            Menu.Combo.E:addParam("useE2", "Use Gapclose E", SCRIPT_PARAM_ONKEYTOGGLE, false, sb("H"))
        Menu.Combo:addSubMenu("R Settings", "R")
            Menu.Combo.R:addParam("useR", "Use R", SCRIPT_PARAM_ONKEYTOGGLE, true, sb("L"))
            Menu.Combo.R:addParam("useQR", "Use QR", SCRIPT_PARAM_ONKEYTOGGLE, false, sb("L"))

    Menu:addSubMenu(cha.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(cha.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("E", "Use E If Hit >= ", SCRIPT_PARAM_SLICE, 4, 0, 10)

    Menu:addSubMenu(cha.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(cha.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu(cha.." - Item Settings","items")
		Menu.items:addParam("panic", "Use them when life under %", SCRIPT_PARAM_SLICE, 10,0,100)
		Menu.items:addParam("11","",SCRIPT_PARAM_INFO,"")
		Menu.items:addParam("22","<< Combo Items >>",SCRIPT_PARAM_INFO,"")
		Menu.items:addParam("ccut","Bilgewater Cutlass",SCRIPT_PARAM_ONOFF,true)
		Menu.items:addParam("cbok","Blade of the Ruined King",SCRIPT_PARAM_ONOFF,true)
		Menu.items:addParam("cgun","Hextech Gunblade",SCRIPT_PARAM_ONOFF,true)
		Menu.items:addParam("ctia","Tiamats",SCRIPT_PARAM_ONOFF,true)
		Menu.items:addParam("33","",SCRIPT_PARAM_INFO,"")
		Menu.items:addParam("44","<< Harass Items >>",SCRIPT_PARAM_INFO,"")
		Menu.items:addParam("hcut","Bilgewater Cutlass",SCRIPT_PARAM_ONOFF,false)
		Menu.items:addParam("hbok","Blade of the Ruined King",SCRIPT_PARAM_ONOFF,false)
		Menu.items:addParam("hgun","Hextech Gunblade",SCRIPT_PARAM_ONOFF,false)
		Menu.items:addParam("htia","Tiamats",SCRIPT_PARAM_ONOFF,false)

    Menu:addSubMenu(cha.." - Misc Settings", "Misc")
        Menu.Misc:addParam("SetSkin", "Select Skin", SCRIPT_PARAM_LIST, 10, {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})

    Menu:addSubMenu(cha.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use E To Evade", "UseE")
        _Evader(Menu.Auto.UseE):CheckCC():AddCallback(
            function(target)
                if E:IsReady() and IsValidTarget(target) then
                    local Position = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular() * E.Range
                    local Position2 = Vector(mh) + Vector(Vector(target) - Vector(mh)):normalized():perpendicular2() * E.Range
                    if not Collides(Position) then
                        E:CastToVector(Position)
                    elseif not Collides(Position2) then
                        E:CastToVector(Position2)
                    else
                        E:CastToVector(Position)
                    end
                end
            end)


    Menu:addSubMenu(cha.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, sb("K"))
        Menu.Keys:addParam("Marathon", "Marathon Mode", SCRIPT_PARAM_ONKEYDOWN, false, sb("T"))
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys.HarassToggle = false
        Menu.Keys.Marathon = false
end

function OnTick()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    SetSkin(mh, Menu.Misc.SetSkin)
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    end
    if Menu.Keys.HarassToggle then
		Harass()
	end
    if Menu.Keys.Marathon then
       mh:MoveTo(mousePos.x, mousePos.z)
       CastSpell(_E, mousePos.x, mousePos.z)
    end
	local panic = mh.health / mh.maxHealth < Menu.items.panic / 100
	if panic then
		local d175 = CountEnemyHeroInRange(175, mh) > 0
		local d650 = CountEnemyHeroInRange(650, mh) > 0
		local d750 = CountEnemyHeroInRange(750, mh) > 0
		if d750 then CastItem(3144, target) end
		if dist then CastItem(3153, target) end
		if dist then CastItem(3146, target) end
		CastItem(3077) CastItem(3074) CastItem(3748)
	end

end

function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
	local easy = enemy.health/enemy.maxHealth <= 0.3 and enemy.health > 0
        if ValidTarget(enemy, TS.range) and easy then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health and not enemy.dead then
            	local dmq = Q:Damage(enemy) >= enemy.health
            	local dme = E:Damage(enemy) >= enemy.health
                if Menu.KillSteal.useQ and dmq then Q:Cast(enemy) end
                if Menu.KillSteal.useE and dme then E:Cast(enemy) end
            end
            local dmi = Ignite:Damage(enemy) >= enemy.health
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and dmi then Ignite:Cast(enemy) end
        end
    end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if Menu.Combo.E.useE then
            E.Range = 400
            E.Width = 330
            E:Cast(target)
        elseif Menu.Combo.E.useE2 then
            E.Range = 600
            E.Width = 270
            E:Cast(target)
        end
		local d300 = GetDistance(target) < 300
        if Menu.Combo.W.useW and WP and d300 then
            W:Cast()
        end
        if Menu.Combo.Q.useQ then
            Q:Cast(target)
        end
        if Menu.Combo.R.useR then
            R.Range = 1250
            R:Cast(target)
        elseif Menu.Combo.R.useQR then
            R.Range = 300
            R:Cast(target)
        end
    end
    local d175 = CountEnemyHeroInRange(175, mh) > 0
	local d650 = CountEnemyHeroInRange(650, mh) > 0
	local d750 = CountEnemyHeroInRange(750, mh) > 0
	if Menu.items.ccut and d750 then
	CastItem(3144, target)
	end
	if Menu.items.cbok and d650 then
	CastItem(3153, target)
	end
	if Menu.items.cgun and d650 then
	CastItem(3146, target)
	end
	if Menu.items.ctia and d175 then
	CastItem(3077) CastItem(3074) CastItem(3748)
	end
end

function WBuff(unit)
    return TargetHaveBuff("fizzwdot", unit)
end

function Harass()
    local target = TS.target
	local manaok = mh.mana / mh.maxMana * 100 >= Menu.Harass.Mana
    if manaok then
        if ValidTarget(target) then
            if Menu.Harass.useE then
                E:Cast(target)
            end
            if Menu.Harass.useQ then
                Q:Cast(target)
            end
			local d300 = GetDistance(target) < 300
            if Menu.Harass.useW and d300 then
                W:Cast(target)
            end
        end
    end
    local d175 = CountEnemyHeroInRange(175, mh) > 0
	local d650 = CountEnemyHeroInRange(650, mh) > 0
	local d750 = CountEnemyHeroInRange(750, mh) > 0
	if Menu.items.hcut and d750 then
	CastItem(3144, target)
	end
	if Menu.items.hbok and d650 then
	CastItem(3153, target)
	end
	if Menu.items.hgun and d650 then
	CastItem(3146, target)
	end
	if Menu.items.htia and d175 then
	CastItem(3077) CastItem(3074) CastItem(3748)
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
    	local how = Menu.LaneClear.E
        E:LaneClear({NumberOfHits = how})
    end
                
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW then
        W:JungleClear()
    end
    if Menu.JungleClear.useE then
        E:JungleClear()
    end
end

AddProcessSpellCallback(function(unit, spell)
    if mh.dead then return end
    if unit and spell and spell.name and unit.isMe then
        if spell.name:lower() == "fizze" then 
            E1 = true
            print("true E1")
        end        
        if spell.name:lower() == "fizzetwo" then 
            E2 = true
            print("true E2")	
        end
        if spell.name:lower() == "fizzebuffer" then 
            EB = true
            print("true EB")	
        end
    end
end)

AddCreateObjCallback(
        function(obj)
    if obj == nil then return end
    if obj and obj.name and obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = true
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = true
        end
    end
end)

AddDeleteObjCallback(
        function(obj)
    if obj == nil then return end
    if obj and obj.name and obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = false
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = false
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
		local osc = os.clock()
        if osc - time <= RefreshTime then 
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

