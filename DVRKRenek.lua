--[[ Script AutoUpdater ]]
local version = "1"
local Author = "Da Vinci & RK1K"
local ScriptName = "The Reptilian"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/LucasRPC/BoL-Scripts/DVRKRenek.lua".."?rand="..ran(3500,5500)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local mh = myHero
local champ = mh.charName

if champ ~= "Renekton" then return end

local Q, W, E, R, Ignite = nil, nil, nil, nil, nil
local TS, Menu = nil, nil
local PredictedDamage = {}
local lastDash
local RefreshTime = 0.4
local CastableItems = {
    Tiamat      = { Range = 175 , Slot   = function() return FindItemSlot("TiamatCleave") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("TiamatCleave") ~= nil and mh:CanUseSpell(FindItemSlot("TiamatCleave")) == READY) end, Damage = function(target) return getDmg("TIAMAT", target, mh) end},
    Titanic     = { Range = 175 , Slot   = function() return FindItemSlot("TitanicHydraCleave") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("TitanicHydraCleave") ~= nil and mh:CanUseSpell(FindItemSlot("TitanicHydraCleave")) == READY) end, Damage = function(target) return getDmg("TITANIC", target, mh) end},
    Bork        = { Range = 650 , Slot   = function() return FindItemSlot("SwordOfFeastAndFamine") end,  reqTarget = true,  IsReady                     = function() return (FindItemSlot("SwordOfFeastAndFamine") ~= nil and mh:CanUseSpell(FindItemSlot("SwordOfFeastAndFamine")) == READY) end, Damage = function(target) return getDmg("RUINEDKING", target, mh) end},
    Bwc         = { Range = 650 , Slot   = function() return FindItemSlot("BilgewaterCutlass") end,  reqTarget = true,  IsReady                         = function() return (FindItemSlot("BilgewaterCutlass") ~= nil and mh:CanUseSpell(FindItemSlot("BilgewaterCutlass")) == READY) end, Damage = function(target) return getDmg("BWC", target, mh) end},
    Hextech     = { Range = 750 , Slot   = function() return FindItemSlot("HextechGunblade") end,  reqTarget = true,    IsReady                         = function() return (FindItemSlot("HextechGunblade") ~= nil and mh:CanUseSpell(FindItemSlot("HextechGunblade")) == READY) end, Damage = function(target) return getDmg("HXG", target, mh) end},
    Blackfire   = { Range = 750 , Slot   = function() return FindItemSlot("BlackfireTorch") end,  reqTarget = true,   IsReady                           = function() return (FindItemSlot("BlackfireTorch") ~= nil and mh:CanUseSpell(FindItemSlot("BlackfireTorch")) == READY) end, Damage = function(target) return getDmg("BLACKFIRE", target, mh) end},
    Youmuu      = { Range = mh.range + mh.boundingRadius + 350 , Slot   = function() return FindItemSlot("YoumusBlade") end,  reqTarget = false,  IsReady                              = function() return (FindItemSlot("YoumusBlade") ~= nil and mh:CanUseSpell(FindItemSlot("YoumusBlade")) == READY) end, Damage = function(target) return 0 end},
    Randuin     = { Range = 500 , Slot   = function() return FindItemSlot("RanduinsOmen") end,  reqTarget = false,  IsReady                             = function() return (FindItemSlot("RanduinsOmen") ~= nil and mh:CanUseSpell(FindItemSlot("RanduinsOmen")) == READY) end, Damage = function(target) return 0 end},
    TwinShadows = { Range = 1000, Slot   = function() return FindItemSlot("ItemWraithCollar") end,  reqTarget = false,  IsReady                         = function() return (FindItemSlot("ItemWraithCollar") ~= nil and mh:CanUseSpell(FindItemSlot("ItemWraithCollar")) == READY) end, Damage = function(target) return 0 end},
}

function OnLoad() Update()
    local r = _Required()
    r:Add({Name = "SimpleLib", Url = "raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua"})
    r:Check()
    if OrbwalkManager.GotReset then return end
    if r:IsDownloading() then return end
    if OrbwalkManager == nil then print("Check your SimpleLib file, isn't working... The script can't load without SimpleLib. Try to copy-paste the entire SimpleLib.lua on your common folder.") return end
    DelayAction(function() CheckUpdate() end, 5)
    DelayAction(function() _arrangePriorities() end, 10)
    TS = _SimpleTargetSelector(TARGET_LESS_CAST_PRIORITY, 700, DAMAGE_PHYSICAL)
    Menu = scriptConfig(ScriptName.." by "..Author, ScriptName.."24052015")

    Q = _Spell({Slot = _Q, DamageName = "Q", Range = 315}):AddDraw()
    W = _Spell({Slot = _W, DamageName = "W", Range = 175}):AddDraw()
    E = _Spell({Slot = _E, DamageName = "E", Range = 470, Width = 60, Delay = 0.25, Speed = 1400, Aoe = false, Collision = false, Type = SPELL_TYPE.LINEAR}):AddDraw()
    Ignite = _Spell({Slot = FindSummonerSlot("summonerdot"), DamageName = "IGNITE", Range = 600, Type = SPELL_TYPE.TARGETTED})
    R = _Spell({Slot = _R, DamageName = "R", Range = 175}):AddDraw()

    TS:AddToMenu(Menu)

    Menu:addSubMenu(champ.." - Combo Settings", "Combo")
        Menu.Combo:addParam("Overkill", "Overkill % for Dmg Predict..", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
        Menu.Combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("useE1", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("useE2", "Use E 2", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("Wreset", "Cancel Animation", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("CancelAnim", "Delay for AnimationCancel", SCRIPT_PARAM_SLICE, 0, 0, 1.5, 1)

    Menu:addSubMenu(champ.." - Harass Settings", "Harass")
		Menu.Harass:addParam("Mode", "Mode: 1|Q+W 2|E+Q+W+E 3|All In", SCRIPT_PARAM_SLICE, 1, 1, 3, 0)
        Menu.Harass:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("useE1", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("useE2", "Use E 2", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - LaneClear Settings", "LaneClear")
        Menu.LaneClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.LaneClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - JungleClear Settings", "JungleClear")
        Menu.JungleClear:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
        Menu.JungleClear:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - KillSteal Settings", "KillSteal")
        Menu.KillSteal:addParam("KillSteal", "Use Smart Kill Steal", SCRIPT_PARAM_ONOFF, false)
        Menu.KillSteal:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)

    Menu:addSubMenu(champ.." - Keys Settings", "Keys")
        OrbwalkManager:LoadCommonKeys(Menu.Keys)
        Menu.Keys:addParam("HarassToggle", "Harass (Toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
        Menu.Keys:addParam("Panicr", "Use R when life under %", SCRIPT_PARAM_SLICE, 10,0,100)
        Menu.Keys:permaShow("HarassToggle")
        Menu.Combo:permaShow("aniCancelW")
        Menu.Keys:permaShow("Panicr")
        Menu.Keys.HarassToggle = false
end

function OnTick()
    if Menu == nil then return end
    TS:update()
    KillSteal()
    Checks()
    KillSteal2()
    if OrbwalkManager:IsCombo() then
        Combo()
    elseif OrbwalkManager:IsHarass() then
        Harass()
    elseif OrbwalkManager:IsClear() then
        Clear()
    end
    if Menu.Keys.HarassToggle then Harass() end
    local panicr = (CountEnemyHeroInRange(600, mh) > 0) and mh.health / mh.maxHealth < Menu.Keys.Panicr / 100
    if panicr then CastSpell(_R, mh) end
end

function Collides(vec)
    return IsWall(D3DXVECTOR3(vec.x, vec.y, vec.z))
end


function KillSteal2()
    for idx, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, TS.range) and enemy.health > 0 and enemy.health/enemy.maxHealth <= 0.3 then
            if Menu.KillSteal.useIgnite and Ignite:IsReady() and Ignite:Damage(enemy) >= enemy.health and not enemy.dead then Ignite:Cast(enemy) end
        end
    end
end

function Combo()
    local target = TS.target
    local q, w, e, r, dmg = GetBestCombo(target)
    if ValidTarget(target) then
      if Menu.Combo.useE1 then
          Slice(target)
      end
      if Menu.Combo.useW then
          W:Cast(target)
      end
      if Menu.Combo.useQ then
          Q:Cast(target)
      end
      if Menu.Combo.useE2 then
          Dice(target)
      end
    UseItems(target)
    end
end

function Harass()
    local target = TS.target
    if ValidTarget(target) then
      local mod = Menu.Harass.Mode
      local qq = Menu.Harass.useQ
      local ww = Menu.Harass.useW
      local e1 = Menu.Harass.useE1
      local e2 = Menu.Harass.useE2
        if mod == 1 then
            if qq then Q:Cast(target) end
            if ww then W:Cast(target) end
        end
        if mod == 2 then
            if qq then Q:Cast(target) end
            if ww then W:Cast(target) end
            if e1 then Slice(target) end
            if e2 then Dice(target) end
        end
        if mod == 3 then
            if e1 then Slice(target) end
            if not E1READY and qq then Q:Cast(target) end
            if not E1READY and not Q:IsReady() and ww then W:Cast(target) end
            if not E1READY and not Q:IsReady() and not W:IsReady() and e2 then LastDash() end
        end
    end
end

function Slice()
    local target = TS.target
    if ValidTarget(target) and E1READY then
        E:Cast(target)
    end
end

function Dice()
    local target = TS.target
    if ValidTarget(target) and E2READY then
        E:Cast(target)
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

function OnDash(unit, dash)
    if Menu.Harass.Mode == 3 then
        if unit and unit.valid and unit.isMe then
            lastDash = { dash.startPos, dash.startT, dash.endT }
        end
    end
end

function LastDash()
	if E2READY and lastDash and GetTickCount() > lastDash[3] and type(lastDash) == 'table' then
        local time = GetTickCount() - lastDash[2]
        if lastDash[2] + 4000 <= GetTickCount()
            then
                CastSpell(_E, lastDash[1].x, lastDash[1].z)
        end
    end
end

function OnProcessSpell(object, spell)
    if ValidTarget(Target) then
        local exe = spell.name == 'RenektonExecute'
        if exe and Menu.Combo.Wreset then
            DelayAction(function()
            if item.IsReady() then UseItems(target) end
            	local delay = 0
            end, 0)
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
        local osk = os.clock()
        if osk - time <= RefreshTime then
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

function UnitAtTower(unit)
    for i, turret in pairs(GetTurrets()) do
        if turret ~= nil then
            if turret.team ~= mh.team then
                if GetDistance(unit, turret) <= turret.range then
                    return true
                end
            end
        end
    end
    return false
end

function KillSteal()
    local enemyHeroes = GetEnemyHeroes()
    for _, enemy in pairs(enemyHeroes) do
        if enemy ~= nil and ValidTarget(enemy) then
        local distance = GetDistance(enemy)
        local Health = enemy.health
            if Health <= Q:Damage(enemy) and Q:IsReady() then
                Q:Cast(enemy)
            elseif Health <= E:Damage(enemy) then
                E:Cast(enemy)
            elseif Health <= (Q:Damage(enemy) + W:Damage(enemy)) and Q:IsReady() and W:IsReady() then
                W:Cast(enemy)
            elseif Health <= (Q:Damage(enemy) + E:Damage(enemy)) and Q:IsReady() then
                E:Cast(enemy)
            elseif Health <= (W:Damage(enemy) + E:Damage(enemy)) and W:IsReady() then
                E:Cast(enemy)
            elseif Health <= (Q:Damage(enemy) + W:Damage(enemy) + E:Damage(enemy)) and Q:IsReady() and W:IsReady() then
                E:Cast(enemy)
            end
        end
    end
end

function Checks()
    E1READY = (mh:CanUseSpell(_E) == READY) and mh:GetSpellData(_E).name == "RenektonSliceAndDice"
    E2READY = (mh:CanUseSpell(_E) == READY) and mh:GetSpellData(_E).name == "RenektonDice"
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

function Update()
	if AUTOUPDATE then
		local ServerData = GetWebResult(UPDATE_HOST, "/LucasRPC/BoL-Scripts/version/Renek.version")
			if ServerData then
				ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
					if ServerVersion then
						if tonumber(version) < ServerVersion then
							DelayAction(function() print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">New version found for DVRK Reptilian... <font color=\"#000000\"> | </font><font color=\"#FF0000\"></font><font color=\"#FF0000\"><b> Version "..ServerVersion.."</b></font>") end, 3)
							DelayAction(function() print("<font color=\"#FFFFFF\"><b> >> Updating, please don't press F9 << </b></font>") end, 4)
							DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () print("<font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">DVRK Reptilian</font> <font color=\"#000000\"> | </font><font color=\"#FF0000\">UPDATED <font color=\"#FF0000\"><b>("..version.." => "..ServerVersion..")</b></font> Press F9 twice to load the updated version.") end) end, 5)
						else
							DelayAction(function() print("<b><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FFFFFF\">DVRK Reptilian</font><font color=\"#000000\"> | </font><font color=\"#FF0000\"><font color=\"#FF0000\"> Version "..ServerVersion.."</b></font>") end, 1)
						end
					end
				else
			DelayAction(function() print("<font color=\"#FFFFFF\">DVRK Reptilian - Error while downloading version info, RE-DOWNLOAD MANUALLY.</font>")end, 1)
		end
	end
end
