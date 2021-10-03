if Player.CharName ~= "Alistar" then return end

module("NAAlistar", package.seeall, log.setup)
clean.module("NAAlistar", clean.seeall, log.setup)

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
local Alistar = {}
local AlistarNP = {}

local function GetIgniteSlot()
	for i=Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2 do
		if Player:GetSpell(i).Name:lower():find("summonerdot") then
			return i
		end
	end
	return Enums.SpellSlots.Unknown
end

-- MENU
function Alistar.LoadMenu()
    Menu.RegisterMenu("NAAlistar", "NA Alistar", function()
        Menu.NewTree("Combo", "Combo Options", function()
            Menu.Checkbox("Combo.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Combo.CastW",   "Use [W]", true)
            Menu.Checkbox("Combo.CastE",   "Use [E]", true)
            Menu.Checkbox("Combo.CastR",   "Use [R]", false)
            Menu.Slider("RSlider","Use [R] when Enmies > ",2,1,5)
			Menu.Checkbox("Combo.CastIgn",   "Use [Ign] if Available", false)
        end)
        Menu.NewTree("Harass", "Harass Options", function()
            Menu.ColoredText("Mana Percent limit", 0xFFD700FF, true)
            Menu.Slider("ManaSlider","",50,0,100)
            Menu.Checkbox("Harass.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Harass.CastW",   "Use [W]", true)
            Menu.Checkbox("Harass.CastE",    "Use [E]", true)
        end)
        Menu.NewTree("Misc", "Misc Options", function()
            Menu.Checkbox("Misc.WI",   "Use [W] on Interrupter", true)
            Menu.Checkbox("Misc.W",   "Use W on gapclose", true)
            Menu.ColoredText("Gapclose W Whitelist", 0xFFD700FF, true)
            for _, Object in pairs(ObjManager.Get("enemy", "heroes")) do
                local name = Object.AsHero.CharName
				local nameSub = "Misc." .. name
                Menu.Checkbox(nameSub, name, false)
            end
        end)
        Menu.NewTree("Draw", "Drawing Options", function()
            Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range",true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xf03030ff)
            Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range",true)
            Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x30e6f0ff)
            Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range",false)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x3060f0ff)
        end)
    end)     
end

-- spells
local Q = Spell.Active({
    Slot = Enums.SpellSlots.Q,
    Range = 375,
    Delay = 0.25,
    Key = "Q"
})
local W = Spell.Targeted({
    Slot = Enums.SpellSlots.W,
    Range = 650,
    Delay = 0,
    Key = "W"
})
local E = Spell.Active({
    Slot = Enums.SpellSlots.E,
    Range = 350,
    Key = "E"
})
local R = Spell.Active({
    Slot = Enums.SpellSlots.R,
    Range = 600,
    Delay = 0.25,
    Key = "R",
})
local Ign = Spell.Targeted({
	Slot = GetIgniteSlot(),
	Delay = math.huge,
	Range = 600,
	Key = "Ign",
})

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end


function Alistar.OnHighPriority() 
    if not GameIsAvailable() then
        return
    end
    if Alistar.Auto() then return end
    local ModeToExecute = Alistar[Orbwalker.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

function Alistar.OnNormalPriority()
    if not GameIsAvailable() then
        return
    end
    local ModeToExecute = AlistarNP[Orbwalker.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

-- DRAW
function Alistar.OnDraw()
    local Pos = Player.Position
    local spells = {Q,W,E}
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..v.Key..".Enabled", true) and v:IsReady() then
            Renderer.DrawCircle3D(Pos, v.Range, 30, 3, Menu.Get("Drawing."..v.Key..".Color"))
        end
    end
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


-- MODES FUNCTIONS
function Alistar.ComboLogic(mode)
    if CanCast(Q,mode) then
        for k,v in pairs(GetTargets(Q)) do
            if Q:Cast() then return end
        end
    end
    if CanCast(W,mode) and Q:IsReady() and Q:GetManaCost() + W:GetManaCost() <= Player.Mana then
        if #TS:GetTargets(Q.Range, true) == 0 then 
            for k,wtarget in pairs(GetTargets(W)) do
                if W:Cast(wtarget) then
                    return
                end
            end
        end
    end
    if CanCast(E,mode) then
        for k,etarget in pairs(GetTargets(E)) do
            if E:Cast() then
                return
            end
        end
    end
    if CanCast(R,mode) then
        if CountHeroes(R.Range,"enemy") >= Menu.Get("RSlider") and CountHeroes(1000,"ally") >= 2 then 
            R:Cast() 
        end
    end
	if CanCast(Ign,mode) then
        for k,igntarget in pairs(GetTargets(Ign)) do
            if Ign:Cast(igntarget) then
                return
            end
        end
    end
end

function Alistar.HarassLogic(mode)
    if Menu.Get("ManaSlider") > (Player.ManaPercent * 100) then return end
    if CanCast(Q,mode) then
        for k,v in pairs(GetTargets(Q)) do
            if Q:Cast() then return end
        end
    end
    if CanCast(W,mode) and Q:IsReady() and Q:GetManaCost() + W:GetManaCost() <= Player.Mana then
        if #TS:GetTargets(Q.Range, true) == 0 then 
            for k,wtarget in pairs(GetTargets(W)) do
                if W:Cast(wtarget) then
                    return
                end
            end
        end
    end
    if CanCast(E,mode) then
        for k,etarget in pairs(GetTargets(E)) do
            if E:Cast() then
                return
            end
        end
    end
end


-- CALLBACKS
function Alistar.Auto()

end

function Alistar.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.WI") and W:IsReady() and danger > 2) then return end
    if W:IsInRange(source) then
        W:Cast(source)
    return
    end
end

function Alistar.OnGapclose(Source, Dash)
    if not (Source.IsMe or Q:IsReady()) then return end
    local mode = Orbwalker.GetMode()
    local CastQ  = function()
        return Q:Cast()
    end
    if mode == "Combo" then 
        local paths = Dash:GetPaths()
        local time = Game.GetTime()
        if CanCast(Q,mode)  then delay((paths[#paths].EndTime - time) * 150,CastQ) end
    end
    if mode == "Harass" then 
        local paths = Dash:GetPaths()
        local time = Game.GetTime()
        if CanCast(Q,mode)  then delay((paths[#paths].EndTime - time) * 150,CastQ) end
    end
end

function Alistar.OnGapclose(Source, DashInstance)
    if not (Source.IsEnemy or Menu.Get("Misc.W") or W:IsReady()) then return end
    local mypos = Player.Position
    local Dist  = mypos:Distance(Source)
    if Source.AsHero.CharName == "Alistar" then return end
	local charNameSub = "Misc." .. Source.AsHero.CharName
    if Dist < W.Range then
    --if Dist < W.Range and Menu.Get(charNameSub) then
        if W:Cast(Source) then return end
    end
end

-- RECALLERS
function Alistar.Combo()  Alistar.ComboLogic("Combo")  end
function AlistarNP.Harass() Alistar.HarassLogic("Harass") end





-- LOAD
function OnLoad()
    Alistar.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Alistar[eventName] then
            EventManager.RegisterCallback(eventId, Alistar[eventName])
        end
    end    
    return true
end