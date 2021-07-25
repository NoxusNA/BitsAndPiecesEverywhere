if Player.CharName ~= "Katarina" then return end
require("common.log")
module("NA Katarina", package.seeall, log.setup)
clean.module("NA Katarina", clean.seeall, log.setup)
local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()


-- recaller
local Katarina = {}
local KatarinaHP = {}

-- ign slot
local function GetIgniteSlot()
	for i=Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2 do
		if Player:GetSpell(i).Name:lower():find("summonerdot") then
			return i
		end
	end
	return Enums.SpellSlots.Unknown
end

-- spells
local Q = Spell.Targeted({
    Slot = Enums.SpellSlots.Q,
    Range = 625,
    Key = "Q"
})
local W = Spell.Active({
    Slot = Enums.SpellSlots.W,
    Range = 400,
    Key = "W"
})
local E = Spell.Skillshot({
    Slot = Enums.SpellSlots.E,
    Range = 725,
    Key = "E"
})
local R = Spell.Active({
    Slot = Enums.SpellSlots.R,
    Range = 550,
    Key = "R",
})
local Ign = Spell.Targeted({
	Slot = GetIgniteSlot(),
	Delay = 0,
	Range = 600,
	Key = "Ign",
})

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

function Katarina.OnHighPriority() 
    if not GameIsAvailable() then
        return
    end
    if Katarina.Auto() then return end
    local ModeToExecute = KatarinaHP[Orbwalker.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

function Katarina.OnNormalPriority()
    if not GameIsAvailable() then
        return
    end
    local ModeToExecute = Katarina[Orbwalker.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

-- DRAW
function Katarina.OnDraw()
    local Pos = Player.Position
    local spells = {Q,W,E,R}
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..v.Key..".Enabled", true) and v:IsReady() then
            Renderer.DrawCircle3D(Pos, v.Range, 30, 3, Menu.Get("Drawing."..v.Key..".Color"))
        end
    end
end


-- SPELLDMG
local function dmg(spell,a,target)
    local dmg = 0
    if spell.Key == "Q" or a then
        dmg = dmg + (75 + (spell:GetLevel() - 1) * 30) + (0.3 * Player.TotalAP)
    end
    if spell.Key == "E" or a then
        dmg = dmg + (15 + (spell:GetLevel() - 1) * 15) + (0.5 * Player.TotalAD) + (0.25 * Player.TotalAP)
    end
    if spell.Key == "R" or a then
        dmg = dmg + (375 + (spell:GetLevel() - 1) * 188) + (2.85 * Player.TotalAP)
    end
	if spell.Key == "Ign" or a then
		dmg = dmg + 50 + 20 * Player.Level - target.HealthRegen * 2.5
	end
    return dmg
end


-- SPELL HELPERS
local function CanCast(spell,mode)
    return spell:IsReady() and Menu.Get(mode .. ".Cast"..spell.Key)
end

local function HitChance(spell)
    return Menu.Get("Chance."..spell.Key)
end

local function GetTargets(Spell)
    return {TS:GetTarget(Spell.Range,true)}
end

local function Count(spell,team,type)
    local num = 0
    for k, v in pairs(ObjManager.Get(team, type)) do
        local minion = v.AsAI
        local Tar    = spell:IsInRange(minion) and minion.MaxHealth > 6 and minion.IsTargetable
        if minion and Tar then
            num = num + 1
        end
    end
    return num
end

local function Countminions(Range,pos)
    local num = 0
    for k, v in pairs(ObjManager.Get("enemy", "minions")) do
        local hero = v.AsAI
        if hero and hero.IsTargetable and hero.MaxHealth > 6 and hero:Distance(pos) < Range then
            num = num + 1
        end
    end
    return num
end

local function CountHeroes(Range,type)
    local num = 0
    for k, v in pairs(ObjManager.Get(type, "heroes")) do
        local hero = v.AsHero
        if hero and hero.IsTargetable and hero:Distance(Player.Position) < Range then
            num = num + 1
        end
    end
    return num
end

local function Lane(spell)
    return Menu.Get("Lane."..spell.Key)
end

local function Jungle(spell)
    return Menu.Get("Jungle."..spell.Key)
end

local function KS(spell)
    return Menu.Get("KS."..spell.Key)
end

-- MODES FUNCTIONS
function Katarina.ComboLogic(mode)
    if CanCast(R,mode) then 
        Katarina.CastR(Menu.Get("rmode"))
    end
end

function Katarina.HarassLogic(mode)
    if Menu.Get("Harassmode") == 0 then 
        if CanCast(Q,mode) then 
            Katarina.CastQ()
        end
        if CanCast(W,mode) then 
            Katarina.CastW()
        end
        if CanCast(E,mode) and not Q:IsReady() then 
            Katarina.CastE(Menu.Get("emodeH"),Menu.Get("Harass.SaveE"))
        end
    end
    if Menu.Get("Harassmode") == 1 then
        if CanCast(E,mode) then 
            Katarina.CastE(Menu.Get("emodeH"),Menu.Get("Harass.SaveE"))
        end 
        if CanCast(W,mode) then 
            Katarina.CastW()
        end
        if CanCast(Q,mode) and not E:IsReady() then 
            Katarina.CastQ()
        end
    end
end

function Katarina.ClearLogic()
    if Lane(Q) and Q:IsReady() then 
        for k,v in pairs (ObjManager.Get("enemy","minions")) do 
            local Minion = v.AsAI 
            local Valid =  Q:IsInRange(Minion) and Minion.MaxHealth > 6
            if Valid then 
                if Q:Cast(Minion) then return end
            end
       end
    end
    if Lane(W) and W:IsReady() then 
        if Countminions(W.Range,Player.Position) >= Menu.Get("Lane.WH") then 
            W:Cast()
        end
    end
    if Lane(E) and E:IsReady() then 
        for k,dagger in pairs(ObjManager.GetNearby("ally","minions")) do 
            if dagger.Name == "HiddenMinion" and not dagger.IsDead then
                if Countminions(350,dagger.Position) >= Menu.Get("Lane.EH") then
                    E:Cast(dagger.Position)
                end
            end
        end
    end
    if Jungle(Q) and Q:IsReady() then 
        for k,v in pairs (ObjManager.Get("neutral","minions")) do 
            local Minion = v.AsAI 
            local Valid  =  Q:IsInRange(Minion) and Minion.MaxHealth > 6
            if Valid then 
                if Q:Cast(Minion) then return end
            end
       end
    end
    if Jungle(W) and W:IsReady() then 
        for k,v in pairs (ObjManager.Get("neutral","minions")) do 
            local Minion = v.AsAI 
            local Valid =  W:IsInRange(Minion) and Minion.MaxHealth > 6
            if Valid then 
                if W:Cast() then return end
            end
       end
    end
    if Jungle(E) and E:IsReady() then 
        for k,v in pairs (ObjManager.Get("neutral","minions")) do 
            local Minion = v.AsAI 
            local Valid =  E:IsInRange(Minion) and Minion.MaxHealth > 6
            if Valid then 
                for k,dagger in pairs(ObjManager.GetNearby("ally","minions")) do 
                    if dagger.Name == "HiddenMinion" and not dagger.IsDead  and dagger:Distance(Minion) < 450 and dagger:Distance(Minion) <= E.Range + 50 then
                        local castpos = dagger.Position:Extended(Minion.Position,200)
                        if E:Cast(castpos) then return end
                    else
                        local castpos = Minion.Position:Extended(Player.Position, 50)
                        if E:Cast(castpos) then return end
                    end
                end
            end
       end
    end
end

function Katarina.LastHitQ()
if not (Menu.Get("LastHit.Q") or Q:IsReady()) then return end
   for k,v in pairs (ObjManager.Get("enemy","minions")) do 
        local Minion = v.AsAI 
        local Valid =  Q:IsInRange(Minion) and Minion.MaxHealth > 6
        if Valid then 
            local dmg = DmgLib.CalculateMagicalDamage(Player,Minion,dmg(Q,false,Minion))
            local pre = Q:GetHealthPred(Minion)
            if pre > 0 and dmg > pre then 
                if Q:Cast(Minion) then return end
            end
        end
   end
end


-- SPELLCASTERS
function Katarina.CastIgnite()
    for k,igntarget in pairs(GetTargets(Ign)) do
        if igntarget and Ign:Cast(igntarget) then
            return
        end
    end
end

function Katarina.CastQ()
    for k,qtarget in pairs(GetTargets(Q)) do
        if qtarget and Q:Cast(qtarget) then
            return
        end
    end
end

function Katarina.CastW()
      for k,wtarget in pairs(GetTargets(W)) do
        if wtarget and W:Cast() then
            return
        end
    end
end

function Katarina.CastE(mode,safe)
    for k,etarget in pairs({TS:GetTarget(E.Range + 250 ,true)}) do
        if etarget then
            for k,dagger in pairs(ObjManager.GetNearby("ally","minions")) do 
                if dagger.Name == "HiddenMinion" and not dagger.IsDead and dagger:Distance(etarget) < 450 and dagger:Distance(Player) <= E.Range + 250 then
                    local CastPos = dagger.Position:Extended(etarget.Position,200)
                    if E:Cast(CastPos) then return end    
                end
            end
            for k,dagger in pairs(ObjManager.GetNearby("all","particles")) do 
                if not dagger.Name ~= "Katarina_Base_W_Indicator_Ally" or dagger:Distance(etarget) > 450 or dagger:Distance(Player) >= E.Range + 250 then
                    Katarina.CastEMode(mode,safe)
                end
            end
        end
    end
end

function Katarina.CastEMode(mode,safe)
    if safe then return end
    if mode == 0 then
        for k,etarget in pairs({TS:GetTarget(E.Range + 250 ,true)}) do
            if etarget then 
            local CastPos = etarget.Position:Extended(Player.Position, -50)
            if E:Cast(CastPos) then return end
            end
        end
    end
    if mode == 1 then
        for k,etarget in pairs({TS:GetTarget(E.Range + 250 ,true)}) do
            if etarget then 
            local CastPos = etarget.Position:Extended(Player.Position, 50)
            if E:Cast(CastPos) then return end
            end
        end
    end
    if mode == 2 then
        if not R:IsReady() then 
            for k,etarget in pairs({TS:GetTarget(E.Range + 250 ,true)}) do
                if etarget then 
                local CastPos = etarget.Position:Extended(Player.Position, 50)
                if E:Cast(CastPos) then return end
                end
            end
        end
        if R:IsReady() then 
            for k,etarget in pairs({TS:GetTarget(E.Range + 250 ,true)}) do
                if etarget then 
                local CastPos = etarget.Position:Extended(Player.Position, -50)
                if E:Cast(CastPos) then return end
                end
            end
        end
    end
end

function Katarina.CastR(mode)
    if mode == 0 then 
        for k,rtarget in pairs(GetTargets(R)) do
            if rtarget.HealthPercent * 100 < Menu.Get("RHP") then
                R:Cast()
            end
        end
    end
    if mode == 1 then 
        for k,rtarget in pairs(GetTargets(R)) do
            local rdmg = DmgLib.CalculateMagicalDamage(Player,rtarget,dmg(Q,true,rtarget))
            local ks   = R:GetKillstealHealth(rtarget)
            if rdmg > ks then
                R:Cast()
            end
        end
    end
end

function Katarina.followup()
    if not Menu.Get("followUp") or not E:IsReady() then return end
    for k,etarget in pairs(GetTargets(E)) do
        if not etarget then return end
        if etarget:Distance(Player) >= R.Range - 100 then
            for k,dagger in pairs(ObjManager.GetNearby("all","particles")) do 
                if dagger and dagger.Name == "Katarina_Base_W_Indicator_Ally" and dagger:Distance(etarget) < 450 and dagger:Distance(Player) <= E.Range + 50 then
                    Input.MoveTo(Renderer.GetMousePos())
                    local castpos = dagger.Position:Extended(etarget.Position,200)
                    if E:Cast(castpos) then return end
                else
                    Input.MoveTo(Renderer.GetMousePos())
                    local castpos = etarget.Position:Extended(Player.Position,-50)
                    if E:Cast(castpos) then return end
                end
            end
        end
    end 
end

function Katarina.CanncelR()
    local count = CountHeroes(R.Range,"enemy")
    if count < 1 then
       Input.MoveTo(Renderer.GetMousePos()) 
    end 
end


-- CALLBACKS
function Katarina.Auto()
    if Player:GetBuff("katarinarsound") and Orbwalker.GetMode() == "Combo" then 
        Katarina.followup()
    end
    if Player:GetBuff("katarinarsound") and Menu.Get("CanncelR") then 
        Katarina.CanncelR()
    end
    if Player:GetBuff("katarinarsound") and not Menu.Get("KS.CanncelR") then return end
    if KS(Q) and Q:IsReady() then
        for k,qtarget in pairs(GetTargets(Q)) do
            local dmg = DmgLib.CalculateMagicalDamage(Player,qtarget,dmg(Q,false,qtarget))
            local ks  = Q:GetKillstealHealth(qtarget)
            if dmg > ks then
                if Player:GetBuff("katarinarsound") then 
                    Input.MoveTo(Renderer.GetMousePos())
                end
                if Q:Cast(qtarget) then return end
            end
        end
    end
    if KS(E) and E:IsReady() then
        for k,etarget in pairs(GetTargets(E)) do
            local dmg = DmgLib.CalculateMagicalDamage(Player,etarget,dmg(E,false,etarget))
            local ks  = E:GetKillstealHealth(etarget)
            if dmg > ks then
                if Player:GetBuff("katarinarsound") then 
                    Input.MoveTo(Renderer.GetMousePos())
                end
                if E:Cast(etarget) then return end
            end
        end
    end
end


-- RECALLERS
function Katarina.Combo()  Katarina.ComboLogic("Combo")  end
function KatarinaHP.Combo() 
      if Menu.Get("Combomode") == 0 then 
		if CanCast(Ign,"Combo") then 
            Katarina.CastIgnite()
        end
		if CanCast(Q,"Combo") then 
            Katarina.CastQ()
        end
        if CanCast(W,"Combo") then 
            Katarina.CastW()
        end
        if CanCast(E,"Combo") and not Q:IsReady() then 
            Katarina.CastE(Menu.Get("emode"),Menu.Get("Combo.SaveE"))
        end
    end
    if Menu.Get("Combomode") == 1 then
        if CanCast(E,"Combo") then 
            Katarina.CastE(Menu.Get("emode"),Menu.Get("Combo.SaveE"))
        end 
		if CanCast(Ign,"Combo") then 
            Katarina.CastIgnite()
        end
        if CanCast(W,"Combo") then 
            Katarina.CastW()
        end
        if CanCast(Q,"Combo") and not E:IsReady() then 
            Katarina.CastQ()
        end
    end
end
function Katarina.Harass() Katarina.HarassLogic("Harass") end
function Katarina.Waveclear() Katarina.ClearLogic() end
function Katarina.Lasthit() Katarina.LastHitQ()end


-- MENU
function Katarina.LoadMenu()
    Menu.RegisterMenu("NAKatarina", "NA Katarina", function()
        Menu.NewTree("Combo", "Combo Options", function()
            Menu.Dropdown("Combomode","Combo mode",0,{"Q > E ", "E > Q"})
            Menu.Checkbox("Combo.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Combo.CastW",   "Use [W]", true)
            Menu.Checkbox("Combo.CastE",   "Use [E]", true)
            Menu.Checkbox("Combo.SaveE",   "E Only for Daggers", false)
            Menu.Dropdown("emode","e mode",0 ,{"Infront", "Behind", "Logic"})
            Menu.Checkbox("Combo.CastR",   "Use [R]", true)
            Menu.Dropdown("rmode","r mode",0 ,{"If X Health", "If Killable"})
            Menu.Slider("RHP"," If Enemy <= X Health",50,1,100)
            Menu.Checkbox("CanncelR",   "Cancel R if no Enemies", true)
            Menu.Checkbox("followUp",   "Follow up Enemy if running out of R Range", true)
			Menu.Checkbox("Combo.CastIgn", "Cast Ignite if Available", true)
        end)
        Menu.NewTree("Harass", "Harass Options", function()
            Menu.Dropdown("Harassmode","Harass mode",0,{"Q > E ", "E > Q"})
            Menu.Checkbox("Harass.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Harass.CastW",   "Use [W]", true)
            Menu.Checkbox("Harass.CastE",   "Use [E]", true)
            Menu.Checkbox("Harass.SaveE",   "E Only for Daggers", false)
            Menu.Dropdown("emodeH","e mode",0 ,{"Infront", "Behind", "Logic"})
        end)
        Menu.NewTree("Wave", "Farming Options", function()
            Menu.NewTree("Lane", "Laneclear Options", function()
                Menu.Checkbox("Lane.Q",   "Use Q", true)
                Menu.Checkbox("Lane.W",   "Use W", true)
                Menu.Slider("Lane.WH",   "W Hitcount", 3,1,5)
                Menu.Checkbox("Lane.E",   "Use E", true)
                Menu.Slider("Lane.EH",   "E Hitcount", 3,1,5)
            end)
            Menu.NewTree("Jungle", "Jungleclear Options", function()
                Menu.Checkbox("Jungle.Q",   "Use Q", true)
                Menu.Checkbox("Jungle.W",   "Use W", true)
                Menu.Checkbox("Jungle.E",   "Use E", true)
            end)
            Menu.NewTree("LastHit", "LastHit Options", function()
                Menu.Checkbox("LastHit.Q",   "Use Q", false)
            end)
        end)
        Menu.NewTree("KillSteal", "KillSteal Options", function()
            Menu.Checkbox("KS.Q",   "Use Q", true)
            Menu.Checkbox("KS.E",   "Use E", true)
            Menu.Checkbox("KS.CanncelR",   "Cancel R for Killsteal", false)
        end)
        Menu.NewTree("Draw", "Drawing Options", function()
            Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range",true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xf03030ff)
            Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range",true)
            Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x30e6f0ff)
            Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range",false)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x3060f0ff)
            Menu.Checkbox("Drawing.R.Enabled",   "Draw [R] Range",true)
            Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0xf03086ff)
        end)
    end)     
end


-- LOAD
function OnLoad()
    Katarina.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Katarina[eventName] then
            EventManager.RegisterCallback(eventId, Katarina[eventName])
        end
    end    
    return true
end