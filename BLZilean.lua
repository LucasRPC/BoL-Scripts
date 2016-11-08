local ScriptName = "BioLogic Zilean"
local Author = "Da Vinci"
local Version = 1
local FileName = _ENV.FILE_NAME

if myHero.charName ~= "Zilean" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local RefreshTime = 0.4
local DefensiveItems = nil

function UpdateScript()
local Script = {}
  Script.Host = "raw.githubusercontent.com"
  Script.VersionPath = "/LucasRPC/BoL-Scripts/master/version/Zilean.version"
  Script.Path = "/LucasRPC/BoL-Scripts/master/BLZilean.lua"
  Script.SavePath = SCRIPT_PATH .. FileName
  Script.CallbackUpdate = function(NewVersion, OldVersion) PrintMessage("Updated to (" .. NewVersion .. "). Please reload script.") end
  Script.CallbackNoUpdate = function(OldVersion) PrintMessage("No Updates Found.") end
  Script.CallbackNewVersion = function(NewVersion) PrintMessage("New Version found (" .. NewVersion .. "). Please wait until its downloaded.") end
  Script.CallbackError = function(NewVersion) PrintMessage("Error while Downloading. Please try again.") end
  ScriptUpdate(Version, true, Script.Host, Script.VersionPath, Script.Path, Script.SavePath, Script.CallbackUpdate,Script.CallbackNoUpdate, Script.CallbackNewVersion,Script.CallbackError)
end 

AddLoadCallback(function()

    local function UpdateSimpleLib()
        if FileExist(LIB_PATH .. "SimpleLib.lua") then
          require("SimpleLib")    
        else
          DownloadFile("https://raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua", LIB_PATH .. "SimpleLib.lua", function() UpdateSimpleLib() end)
        end
    end
    UpdateSimpleLib()
    UpdateScript()
    if OrbwalkManager.GotReset then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 900, DAMAGE_MAGIC)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")
    DefensiveItems = { Zhonyas = _Spell({Range = 1000, Type = SPELL_TYPE.SELF}):AddSlotFunction(function() return FindItemSlot("ZhonyasHourglass") end),}
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 895, Width = 205, Delay = 0.3, Speed = 2000, Aoe = true, Collision = false, Type = SPELL_TYPE.CIRCULAR}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 0, Type = SPELL_TYPE.SELF}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 700, Type = SPELL_TYPE.TARGETTED}):AddDraw()
    R = _Spell({Slot = _R, DamageName = "R", Range = 900, Type = SPELL_TYPE.TARGETTED, IsForEnemies = false}):AddDraw()

    TS:AddToMenu(Menu)

    Menu:addSubMenu(myHero.charName.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE", "Use E on enemy", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("selfE", "Use E on self", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("RPANIC", "Smart Ultimate", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("RHP", "What % to ult", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
        Menu.Combo:addParam("HelpR", "Auto Revive Allies", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("AHP", "% To Revive", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
        Menu.Combo:addParam("Zhonyas", "Use Zhonyas if HP % <=", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - Harass Settings", "Harass")
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("Mana", "Min. Mana Percent: ", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    Menu:addSubMenu(myHero.charName.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(myHero.charName.." - Misc Settings", "Misc")
        Menu.Misc:addParam("SetSkin", "Select Skin", SCRIPT_PARAM_LIST, 10, {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"})

    Menu:addSubMenu(myHero.charName.." - Auto Settings", "Auto")
        Menu.Auto:addSubMenu("Use E To Slow Gapclosers", "E")
        _Interrupter(Menu.Auto.E):CheckGapcloserSpells():AddCallback(function(target) E:Cast(target) end)
        
    Menu:addSubMenu(myHero.charName.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("Flee", "Marathon Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
        Menu.Keys:addParam("AssistedUltimate", "Use R on My Hero Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
        Menu.Keys:permaShow("Flee")
        Menu.Keys:permaShow("HarassToggle")
        Menu.Keys.HarassToggle = false
        Menu.Keys.Flee = false
end)

AddTickCallback(function()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    Ultimate()
    SetSkin(myHero, Menu.Misc.SetSkin)
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    end
    if Menu.Keys.Flee then TryToRun() end
    if Menu.Keys.HarassToggle then Harass() end
    if Menu.Combo.RPANIC then Ultimate() end
    if Menu.Keys.AssistedUltimate then R:Cast(myHero) end
end)

function TryToRun()
    if Menu.Keys.Flee then
        myHero:MoveTo(mousePos.x, mousePos.z)
        CastSpell(_E, myHero)
    end
end

function KillSteal()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.3 then
            local q, w, e, r, dmg = GetBestCombo(enemy)
            if dmg >= enemy.health then
                if Menu.KillSteal.useQ and Q:Damage(enemy) >= enemy.health and not enemy.dead then Q:Cast(enemy) end
            end
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
        if Menu.Combo.Zhonyas > 0 and PercentageHealth() <= Menu.Combo.Zhonyas and DefensiveItems.Zhonyas:IsReady() and CountEnemyHeroInRange(800) >= 1 then
            DefensiveItems.Zhonyas:Cast()
        end
        if Menu.Combo.useE and not Q:IsReady() and not W:IsReady() then
            E:Cast(target)
        end
        if Menu.Combo.useW and not Q:IsReady() then
            W:Cast()
        end
        if Menu.Combo.selfE then
            if E:IsReady() and GetDistance(target) < 1150 and GetDistance(target) > 500 then
                CastSpell(_E, myHero)
            end
        end
        if Menu.Combo.useQ then
            Q:Cast(target)
        end   
    end
end

function Ultimate()
    if Menu.Combo.RPANIC then
        if PercentageHealth() <= Menu.Combo.RHP then
            if R:IsReady() and CountEnemyHeroInRange(1100) >= 1 then
                R:Cast(myHero)
            end
        end
    end
    if Menu.Combo.HelpR then
        for i, ally in ipairs(GetAllyHeroes()) do
            if ally ~= nil and GetDistance(ally) < R.Range and not ally.dead and R:IsReady() and ally.health / ally.maxHealth * 100 <= Menu.Combo.AHP then
                CastSpell(_R, ally)
            end
        end
    end
end

function Harass()
    local target = TS.target
    if PercentageMana() >= Menu.Harass.Mana then
        if ValidTarget(target) then
            if Menu.Harass.useE then
                E:Cast(target)
            end
            if Menu.Harass.useQ then
                Q:Cast(target)
            end
            if Menu.Harass.useW and not Q:IsReady() and not E:IsReady() then
                W:Cast()
            end
        end
    end
end

function Clear()
    if PercentageMana() >= Menu.LaneClear.Mana then
        if Menu.LaneClear.useQ then
            Q:LaneClear()
        end
        if Menu.LaneClear.useW and not Q:IsReady() then
            W:Cast()
        end
    end
    if Menu.JungleClear.useQ then
        Q:JungleClear()
    end
    if Menu.JungleClear.useW and not Q:IsReady() then
        W:Cast()
    end
end

function GetOverkill()
    return (100 + Menu.Combo.Overkill)/100
end

function PercentageHealth(u)
    local unit = u ~= nil and u or myHero
    return unit and unit.health/unit.maxHealth * 100 or 0
end

function PercentageMana(u)
    local unit = u ~= nil and u or myHero
    return unit and unit.mana/unit.maxMana * 100 or 0
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

class("ScriptUpdate")

function ScriptUpdate:__init(LocalVersion, UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
  self.LocalVersion = LocalVersion
  self.Host = Host
  self.VersionPath = '/BoL/TCPUpdater/GetScript' .. (UseHttps and '5' or '6') .. '.php?script=' .. self:Base64Encode(self.Host .. VersionPath) .. '&rand=' .. math.random(99999999)
  self.ScriptPath = '/BoL/TCPUpdater/GetScript' .. (UseHttps and '5' or '6') .. '.php?script=' .. self:Base64Encode(self.Host .. ScriptPath) .. '&rand=' .. math.random(99999999)
  self.SavePath = SavePath
  self.CallbackUpdate = CallbackUpdate
  self.CallbackNoUpdate = CallbackNoUpdate
  self.CallbackNewVersion = CallbackNewVersion
  self.CallbackError = CallbackError
  AddDrawCallback(function() self:OnDraw() end)
  self:CreateSocket(self.VersionPath)
  self.DownloadStatus = 'Connect to Server for VersionInfo'
  AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
  print('<font color="#FFFFFF">' .. os.clock() .. ': ' .. str)
end

function ScriptUpdate:OnDraw()
  if self.DownloadStatus ~= 'Downloading script... (100%)' and self.DownloadStatus ~= 'Checking for version... (100%)' then
    DrawText('Downloading: ' .. (self.DownloadStatus or 'Unknown'), 42, 550, 550, ARGB(138, 43, 226, 255))
  end
end

function ScriptUpdate:CreateSocket(url)
  if not self.LuaSocket then
    self.LuaSocket = require("socket")
  else
    self.Socket:close()
    self.Socket = nil
    self.Size = nil
    self.RecvStarted = false
  end
  self.LuaSocket = require("socket")
  self.Socket = self.LuaSocket.tcp()
  self.Socket:settimeout(0, 'b')
  self.Socket:settimeout(99999999, 't')
  self.Socket:connect('sx-bol.eu', 80)
  self.Url = url
  self.Started = false
  self.LastPrint = ""
  self.File = ""
end

function ScriptUpdate:Base64Encode(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r,b='',x:byte()
    for i=8, 1, -1 do
      r=r .. (b%2^i-b%2^(i-1)>0 and '1' or '0')
    end
    return r;
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then
      return ''
    end
    local c=0
    for i = 1, 6 do
      c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0)
    end
    return b:sub(c+1,c+1)
  end) .. ({ '', '==', '=' })[#data%3+1])
end

function ScriptUpdate:GetOnlineVersion()
  if self.GotScriptVersion then
    return
  end
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET " .. self.Url .. " HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Checking for version... (0%)'
  end
  self.File = self.File .. (self.Receive or self.Snipped)
  if self.File:find('</s' .. 'ize>') then
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si' .. 'ze>')+6, self.File:find('</si' .. 'ze>')-1))
    end
    if self.File:find('<scr' .. 'ipt>') then
      local _, ScriptFind = self.File:find('<scr' .. 'ipt>')
      local ScriptEnd = self.File:find('</scr' .. 'ipt>')
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      local DownloadedSize = self.File:sub(ScriptFind+1, ScriptEnd or -1):len()
      self.DownloadStatus = 'Checking for version... (' .. math.round(100/self.Size*DownloadedSize, 2) .. '%)'
    end
  end
  if self.File:find('</scr' .. 'ipt>') then
    self.DownloadStatus = 'Checking for version... (100%)'
    local a,b = self.File:find('\r\n\r\n')
    self.File = self.File:sub(a, -1)
    self.NewFile = ''
    for line,content in pairs(self.File:split('\n')) do
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
    end
    local HeaderEnd, ContentStart = self.File:find('<scr' .. 'ipt>')
    local ContentEnd, _ = self.File:find('</sc' .. 'ript>')
    if not (ContentStart and ContentEnd) then
      if self.CallbackError and type(self.CallbackError) == 'function' then
        self.CallbackError()
      end
    else
      self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart+1,ContentEnd-1)))
      self.OnlineVersion = tonumber(self.OnlineVersion)
      if self.OnlineVersion > self.LocalVersion then
        if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
          self.CallbackNewVersion(self.OnlineVersion, self.LocalVersion)
        end
        self:CreateSocket(self.ScriptPath)
        self.DownloadStatus = 'Waiting for server...'
        AddTickCallback(function() self:DownloadUpdate() end)
      else
        if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
          self.CallbackNoUpdate(self.LocalVersion)
        end
      end
    end
    self.GotScriptVersion = true
  end
end

function ScriptUpdate:DownloadUpdate()
  if self.GotScriptUpdate then
    return
  end
  self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  if self.Status == 'timeout' and not self.Started then
    self.Started = true
    self.Socket:send("GET " .. self.Url .. " HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
  end
  if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
    self.RecvStarted = true
    self.DownloadStatus = 'Downloading script... (0%)'
  end
  self.File = self.File .. (self.Receive or self.Snipped)
  if self.File:find('</si' .. 'ze>') then
    if not self.Size then
      self.Size = tonumber(self.File:sub(self.File:find('<si' .. 'ze>')+6, self.File:find('</si' .. 'ze>')-1))
    end
    if self.File:find('<scr' .. 'ipt>') then
      local _, ScriptFind = self.File:find('<scr' .. 'ipt>')
      local ScriptEnd = self.File:find('</scr' .. 'ipt>')
      if ScriptEnd then
        ScriptEnd = ScriptEnd-1
      end
      local DownloadedSize = self.File:sub(ScriptFind+1, ScriptEnd or -1):len()
      self.DownloadStatus = 'Downloading script... (' .. math.round(100/self.Size*DownloadedSize, 2) .. '%)'
    end
  end
  if self.File:find('</scr' .. 'ipt>') then
    self.DownloadStatus = 'Downloading script... (100%)'
    local a,b = self.File:find('\r\n\r\n')
    self.File = self.File:sub(a, -1)
    self.NewFile = ''
    for line,content in pairs(self.File:split('\n')) do
      if content:len() > 5 then
        self.NewFile = self.NewFile .. content
      end
    end
    local HeaderEnd, ContentStart = self.NewFile:find('<sc' .. 'ript>')
    local ContentEnd, _ = self.NewFile:find('</scr' .. 'ipt>')
    if not (ContentStart and ContentEnd) then
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
          self.CallbackUpdate(self.OnlineVersion, self.LocalVersion)
        end
      end
    end
    self.GotScriptUpdate = true
  end
end

assert(load(Base64Decode("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"), nil, "bt", _ENV))()
TrackerLoad("LL8yQBEICG6UGdxf")
