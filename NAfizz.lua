if Player.CharName ~= "Fizz" then return end
--[[ require ]]
require("common.log")
module("NA Fizz", package.seeall, log.setup)
clean.module("NA Fizz", clean.seeall, log.setup)
--[[ SDK ]]
local SDK         = _G.CoreEx
local Obj         = SDK.ObjectManager
local Event       = SDK.EventManager
local Game        = SDK.Game
local Enums       = SDK.Enums
local Geo         = SDK.Geometry
local Renderer    = SDK.Renderer
local Input       = SDK.Input
--[[Libraries]] 
local TS          = _G.Libs.TargetSelector()
local Menu        = _G.Libs.NewMenu
local Orb         = _G.Libs.Orbwalker
local Collision   = _G.Libs.CollisionLib
local Pred        = _G.Libs.Prediction
local HealthPred  = _G.Libs.HealthPred
local DmgLib      = _G.Libs.DamageLib
local ImmobileLib = _G.Libs.ImmobileLib
local Spell       = _G.Libs.Spell
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Fizz = {}
local FizzHP = {}
local FizzNP = {}
local LastSheen = os.clock()
local LastLichBane = os.clock()
local ItemSlots = require("lol/Modules/Common/ItemID")
local targetedSpells = {
    Akali = {
        Slot = 3,
        Danger = 3
    },
    Alistar = {
        Slot = 1,
        Danger = 2
    },
    Anivia = {
        Slot = 2,
        Danger = 1
    },
    Annie = {
        Slot = 0,
        Danger = 2
    },  
    Brand = {
        Slot = 3,
        Danger = 3
    },
    Caitlyn = {
        Slot = 3,
        Danger = 3
    },
    Camille = {
        Slot = 3,
        Danger = 3
    },
    Cassiopeia = {
        Slot = 2 ,
        Danger = 1
    },
    Chogath = {
        Slot = 3,
        Danger = 3
    },
    Darius = {
        Slot = 3,
        Danger = 3
    },
    Diana = {
        Slot = 2,
        Danger = 2
    },
    Evelynn = {
        Slot = 1,
        Danger = 2
    },
    Fiddlesticks = {
        Slot = 0,
        Danger = 2
    },
    Fizz = {
        Slot = 0,
        Danger = 2
    },
    Fiora = {
        Slot = 3,
        Danger = 3
    },
    Gangplank = {
        Slot = 0,
        Danger = 1
    },
    Garen = {
        Slot = 3,
        Danger =3
    },
    Irelia = {
        Slot = 0,
        Danger = 2
    },
    Janna = {
        Slot = 1,
        Danger = 2
    },
    JarvanIV = {
        Slot =  3,
        Danger = 3
    },
    Jax = {
        Slot = 0,
        Danger = 2
    },
    Jayce = {
        Slot = 0 ,
        Danger = 1
    },
    Jhin ={
        Slot = 0,
        Danger = 1
    },
    Karma = {
        Slot = 1,
        Danger = 2
    },
    Kassadin = {
        Slot = 0,
        Danger = 1
    },
    Katarina = {
        Slot = 0,
        Danger = 1
    },
    Kayn = {
        Slot = 3,
        Danger = 3
    },
    Khazix = {
        Slot = 0,
        Danger = 2
    },
    Kindred = {
        Slot = 2,
        Danger = 2
    },
    Leblanc = {
        Slot = 0,
        Danger = 1
    },
    LeeSin = {
        Slot = 3,
        Danger =3
    },
    Lissandra = {
        Slot = 3,
        Danger = 3
    },
    Lucian = {
        Slot = 0,
        Danger = 1
    },
    Lulu = {
        Slot = 1,
        Danger = 2
    },
    Malphite = {
        Slot=0,
        Danger = 0
    },
    Malzahar = {
        Slot = 3,
        Danger = 3
    },
    Maokai = {
        Slot = 1,
        Danger = 2
    },
    MasterYi = {
        Slot = 0,
        Danger = 2 
    },
    MissFortune = {
        Slot = 0,
        Danger = 1,
    },
    Mordekaiser = {
        Slot = 3,
        Danger = 3
    },
    Nasus = {
        Slot = 1,
        Danger = 2
    },
    Nautilus = {
        Slot = 3,
        Danger = 3
    },
    Nidalee = {
        Slot = 0,
        Danger = 2
    },
    Nocturne = {
        Slot = 2,
        Danger = 3
    },
    Nunu = {
        Slot = 0,
        Danger = 1
    },
    Olaf = {
        Slot  = 2,
        Danger = 2
    },
    Pantheon = {
        Slot = 1,
        Danger = 3
    },
    Poppy = {
        Slot = 2,
        Danger = 3
    },
    Qiyana = {
        Slot = 2,
        Danger = 1
    },
    Quinn = {
        Slot = 2,
        Danger = 2
    },
    Rammus = {
        Slot = 2,
        Danger = 3
    },
    Reksai = {
        Slot = 3,
        Danger = 3
    },
    Ryze = {
        Slot = 1,
        Danger = 2
    },
    Samira = {
        Slot = 3,
        Danger = 2
    },
    Sejuani = {
        Slot = 2,
        Danger = 2
    },
    Senna = {
        Slot = 0,
        Danger = 1,
    },
    Sett = {
        Slot = 3,
        Danger = 3,
    },
    Shaco = {
        Slot = 2,
        Danger = 2
    },
    Singed = {
        Slot = 2,
        Danger = 3
    },
    Skarner = {
        Slot = 3,
        Danger = 3
    },
    Sylas = {
        Slot = 3,
        Danger = 3
    },
    Syndra = {
        Slot = 3,
        Danger = 3
    },
    Tahmkench= {
        Slot = 1,
        Danger = 3
    },
    Talon = {
        Slot = 0,
        Danger = 1
    },
    Teemo = {
        Slot = 0,
        Danger = 1
    },
    Tristana = {
        Slot = 3,
        Danger = 3
    },
    TwistedFate = {
        Slot = 1,
        Danger = 2
    },
    Trundle = {
        Slot = 3,
        Danger = 3
    },
    Vayne = {
        Slot = 2,
        Danger = 2
    },
    Veigar = {
        Slot = 3,
        Danger = 3
    },
    Vi = {
        Slot = 3,
        Danger = 3
    },
    Vladimir = {
        Slot = 0,
        Danger = 1
    },
    Volibear = {
        Slot = 1,
        Danger = 1
    },
    Viktor = {
        Slot = 0,
        Danger = 2
    },
    Warwick = {
        Slot = 0,
        Danger = 1
    },
    Wukong = {
        Slot = 2,
        Danger = 1
    },
    XinZhao = {
        Slot = 2,
        Danger = 2
    },
    Yasuo = {
        Slot = 2,
        Danger = 1 
    },
    Zed = {
        Slot = 3,
        Danger = 3 
    }
}
--[[Spells]] 
local Q = Spell.Targeted({
    Slot = Enums.SpellSlots.Q,
    Range = 550,
    Key = "Q",
})
local W = Spell.Active({
    Slot = Enums.SpellSlots.W,
    Delay = 0,
    Range = 175,
    LastW = os.clock(),
    LastWC = os.clock(),
    Key = "W",
})
local E = Spell.Skillshot({
    Slot = Enums.SpellSlots.E,
    Range =  330,
    Delay = 0,
    Radius = 400,
    Key = "E",
    Type = "Circular"
})
local E2 = Spell.Skillshot({
    Slot = Enums.SpellSlots.E,
    Range =  270,
    Delay = 0,
    Radius = 200,
    Key = "E",
    Type = "Circular"
})
local R = Spell.Skillshot({
    Slot = Enums.SpellSlots.R,
    Delay = 0.25,
    Range = 1300,
    Speed = 1300,
    Radius = 80,
    Type = "Linear",
    Collisions = {WindWall = true},
    UseHitbox = true,
    GuppyMaxrange = 455,
    ChomperMaxRange = 910,
    GIGALODONMaxRange = 1300,
    Key = "R",

})
local Summoner2 = Spell.Targeted({
    Slot = Enums.SpellSlots.Summoner2,
    Range = 600,
    Key = "I"
})
local Summoner1 = Spell.Targeted({
    Slot = Enums.SpellSlots.Summoner1,
    Range = 600,
    Key = "I"
})

--[[Startup]] 
local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

function Fizz.OnHighPriority() 
    if not GameIsAvailable() then
        return
    end
    if Fizz.Auto() then return end
    local ModeToExecute = FizzHP[Orb.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

function Fizz.OnNormalPriority()
    if not GameIsAvailable() then
        return
    end
    local ModeToExecute = FizzNP[Orb.GetMode()]
    if ModeToExecute then
		ModeToExecute()
	end
end

--[[Draw]] 
function Fizz.OnDraw()
    local Pos = Player.Position
    local spells = {Q,W,E}
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..v.Key..".Enabled", true) and v:IsReady() then
            Renderer.DrawCircle3D(Pos, v.Range, 30, 3, Menu.Get("Drawing."..v.Key..".Color"))
        end
    end
    if Menu.Get("Drawing."..R.Key..".Enabled", true) and R:IsReady() then
        Renderer.DrawCircle3D(Pos, R.GuppyMaxrange, 30, 3, Menu.Get("Drawing."..R.Key..".Color"))
        Renderer.DrawCircle3D(Pos, R.ChomperMaxRange, 30, 3, Menu.Get("Drawing."..R.Key..".Color"))
        Renderer.DrawCircle3D(Pos, R.GIGALODONMaxRange, 30, 3, Menu.Get("Drawing."..R.Key..".Color"))
    end
end

--[[Helper Functions]]
local function CanCast(spell,mode)
    return spell:IsReady() and Menu.Get(mode .. ".Cast"..spell.Key)
end

local function HitChance(spell)
    return Menu.Get("Chance."..spell.Key)
end

local function Lane(spell)
    return spell:IsReady() and Menu.Get("Lane."..spell.Key)
end

local function LastHit(spell)
    return Menu.Get("LastHit."..spell.Key) and spell:IsReady()
end

local function Structure(spell)
    return Menu.Get("Structure."..spell.Key) and spell:IsReady()
end

local function Jungle(spell)
    return spell:IsReady() and Menu.Get("Jungle."..spell.Key)
end

local function Flee(spell)
    return Menu.Get("Flee."..spell.Key) and spell:IsReady()
end

local function KS(spell)
    return Menu.Get("KS."..spell.Key) and spell:IsReady()
end

local function GetTargetsRange(Range)
    return {TS:GetTarget(Range,true)}
end

local function GetTargets(Spell)
    return {TS:GetTarget(Spell.Range,true)}
end

local function CountHeroes(pos,Range,type)
    local num = 0
    for k, v in pairs(Obj.Get(type, "heroes")) do
        local hero = v.AsHero
        if hero and hero.IsTargetable and not hero.IsMe and hero:Distance(pos.Position) < Range then
            num = num + 1
        end
    end
    return num
end

local function ValidAI(minion,Range)
    local AI = minion.AsAI
    return AI.IsTargetable and AI.MaxHealth > 6 and AI:Distance(Player) < Range
end

local function SortMinion(list)
    table.sort(list, function(a, b) return a.MaxHealth > b.MaxHealth end)
    return list
end

local function IsUnderTurrent(pos)
    local sortme = {}
    for k, v in pairs(Obj.Get("enemy", "turrets")) do
        if not v.IsDead and v.IsTurret then 
            table.insert(sortme,v)
        end
    end
    table.sort(sortme,function(a, b) return b:Distance(Player) > a:Distance(Player) end)
    for  k,v  in ipairs(sortme) do 
        return v:Distance(pos) <= 870
    end
end

local function dmg(spell)
    local dmg = 0
    local Extra = 0
    local time = os.clock()
    for v, k in pairs(Player.Items) do
        local id = k.ItemId
        if id == ItemSlots.LichBane then
            if (time >= LastLichBane or Player:GetBuff("lichbane")) then 
                Extra = Player.BaseAD * 1.5 + Player.TotalAP * 0.4
            end
        end
    end
    if spell.Key == "Q" then
        dmg = (10 + (Q:GetLevel() - 1) * 15) + (0.55 * Player.TotalAP)
    end
    if spell.Key == "W" then
        dmg = (50 + (W:GetLevel() - 1) * 20) + (0.5 * Player.TotalAP)
    end
    return dmg + Extra
end

local function edmg()
    return (70 + (E:GetLevel() - 1) * 50) + (0.75 * Player.TotalAP)
end

local function sdmg(spell)
    local dmg = 0
    if spell.Key == "I" then
        dmg = (70 + (Player.Level) * 20) 
    end
    return dmg
end

local function dmgsheen()
    local dmg = 0
    local time = os.clock()
    for v, k in pairs(Player.Items) do
        local id = k.ItemId
        if id == ItemSlots.Sheen then
            if (time >= LastSheen or Player:GetBuff("sheen")) then 
                dmg = Player.BaseAD 
            end
        end
    end
    return dmg 
end
--[[Events]]
function Fizz.Auto()
    if KS(Q) then
        for k,v in pairs(GetTargetsRange(Q.Range)) do 
            local dmg = DmgLib.CalculateMagicalDamage(Player,v,dmg(Q))
            local dmgAA = DmgLib.CalculatePhysicalDamage(Player,v,Player.TotalAD)
            local Sheendmg = DmgLib.CalculatePhysicalDamage(Player, v, dmgsheen())
            local Ks  = Q:GetKillstealHealth(v)
            if dmg + Sheendmg + dmgAA > Ks and Q:Cast(v) then return end
        end
    end
    if KS(Summoner1) and not Q:IsReady() then 
        for k, obj in pairs(GetTargets(Summoner1)) do 
            if obj.Health >= sdmg(Summoner1) then return end
            if CountHeroes(obj,600,"ally") >= 1 then return end
            if Summoner1:IsReady() and Summoner1:GetName() == "SummonerDot" then 
                if Summoner1:IsInRange(obj) and Summoner1:Cast(obj) then return end
            end
            if Summoner2:IsReady() and Summoner2:GetName() == "SummonerDot" then 
                if Summoner2:IsInRange(obj) and Summoner2:Cast(obj) then return end
            end
        end
    end
end

function Fizz.OnBuffLost(sender,Buff)
    if not sender.IsMe then return end
    if Buff.Name == "sheen" then 
        LastSheen = os.clock() + 2
    end
    if Buff.Name == "lichbane" then 
        LastLichBane = os.clock() + 3
    end
end

function Fizz.OnBuffGain(sender,Buff)
    if not sender.IsMe then return end
    if Buff.Name == "FizzW" then 
        W.LastW = os.clock() + 2
        W.LastWC = os.clock() + 0.5
    end
end

function Fizz.OnPostAttack(targets)
    local Target = targets.AsAI
    local mode = Orb.GetMode()
    if not Target or not W:IsReady() then return end
    if Target.IsHero and mode == "Combo" then 
        if CanCast(W,mode) then 
            if W:Cast() then return end
        end
    end
    if Target.IsHero and mode == "Harass" then 
        if CanCast(W,mode) then 
            if W:Cast() then return end
        end
    end
    if Target.IsStructure and Structure(W) then 
        if W:Cast() then return end
    end
end

local function OnProcessSpell(sender,spell)
    if E:IsReady() and E:GetName() == "FizzE" then 
        if sender.IsTurret and Menu.Get("Misc.ET") and spell.Target and spell.Target.IsMe then 
            E:Cast(Renderer.GetMousePos())
        end
    end
    if spell.Slot > 3  then return end
    if E:IsReady() and E:GetName() == "FizzE" then 
        if not (sender.IsHero and sender.IsEnemy) then return end
        if Menu.Get("Misc.EST") and targetedSpells[sender.CharName] and targetedSpells[sender.CharName].Slot == spell.Slot
        and targetedSpells[sender.CharName].Danger >= Menu.Get("Targeted") and Menu.Get(spell.Slot .. sender.CharName) and spell.Target and spell.Target.IsMe then 
           E:Cast(Renderer.GetMousePos())
        end
    end
    if not E:IsReady() then
        if not (sender.IsHero and sender.IsEnemy) then return end
        if Menu.Get("Misc.Zhonyas") and targetedSpells[sender.CharName] and
         targetedSpells[sender.CharName].Slot == spell.Slot and targetedSpells[sender.CharName].Danger >= Menu.Get("Zhonyas") 
         and Menu.Get(spell.Slot .. sender.CharName) and spell.Target and spell.Target.IsMe then 
            for k, v in pairs(Player.Items) do
                local id = v.ItemId
                local itemslot = k + 6
                if id == ItemSlots.ZhonyasHourglass or id == ItemSlots.Stopwatch then
                    if Player:GetSpellState(itemslot) ==  Enums.SpellStates.Ready then 
                        Input.Cast(itemslot)
                    end
                end
            end
        end
    end
end

function Fizz.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.RI") and Q:IsReady() and danger > 2) then return end
    if not Menu.Get("2" .. source.AsHero.CharName) then return end
    if R:CastOnHitChance(source,Enums.HitChance.VeryHigh) then
        return 
    end
end

function Fizz.OnGapclose(Source, DashInstance)
    if not (Source.IsEnemy) or not Menu.Get("Misc.EGap")  then return end
    if not Menu.Get("3" .. Source.AsHero.CharName) then return end
    local path = DashInstance:GetPaths()
    local endPos = path[#path].EndPos
    if Player.Position:Distance(endPos) < 300 then
        local castPos = Renderer.GetMousePos()
        Fizz.CastE(castPos)      
    end
end
    
--[[Orbwalker Recallers]]
function FizzHP.Combo()
    local mode = "Combo"
    if CanCast(R,mode) then 
        if Menu.Get("R2") then
            for k,v in pairs(GetTargetsRange(Menu.Get("R.Max"))) do 
                if v:Distance(Player) > 910 then
                    local pred = Pred.GetPredictedPosition(v, R, Player.Position)
                    if pred and pred.HitChance > HitChance(R) then
                        local CastPos = Player.Position:Extended(pred.CastPosition,R.GIGALODONMaxRange)
                        R:Cast(CastPos)
                    end
                end
            end
        end
        if Menu.Get("R1") then
            for k,v in pairs(GetTargetsRange(R.ChomperMaxRange)) do 
                if v:Distance(Player) > 455 then
                    local pred = Pred.GetPredictedPosition(v, R, Player.Position)
                    if pred and pred.HitChance > HitChance(R) then
                        local CastPos = Player.Position:Extended(pred.CastPosition,R.GIGALODONMaxRange)
                        R:Cast(CastPos)
                    end
                end
            end
        end
        if Menu.Get("R0") then
            for k,v in pairs(GetTargetsRange(R.GuppyMaxrange)) do 
                local pred = Pred.GetPredictedPosition(v, R, Player.Position)
                if pred and pred.HitChance > HitChance(R) then
                    local CastPos = Player.Position:Extended(pred.CastPosition,R.GIGALODONMaxRange)
                    R:Cast(CastPos)
                end
            end
        end
    end
end

function  FizzNP.Combo()
    local mode = "Combo"
    local time = os.clock()
    if W:IsReady() then W.LastWC = os.clock() + 0.5 end
    if CanCast(Q,mode) then
        for k,v in pairs(GetTargets(Q)) do 
            if Q:Cast(v) then return end
        end
    end
    if CanCast(E,mode) and time > W.LastWC and not Q:IsReady() then
        for k,v in pairs(GetTargetsRange(E.Radius + E2.Radius)) do 
            if E:IsInRange(v) then Fizz.CastE(v.Position) end
            if E:GetName() == "FizzETwo" and Player:Distance(v) > 400 then 
                Fizz.CastE2(v.Position)
            end
        end
    end
end

function FizzNP.Harass()
    local mode = "Harass"
    if Menu.Get("ManaSlider") > Player.ManaPercent * 100 then return end
    local time = os.clock()
    if W:IsReady() then W.LastWC = os.clock() + 0.5 end
    if CanCast(Q,mode) then
        for k,v in pairs(GetTargets(Q)) do 
            if Q:Cast(v) then return end
        end
    end
    if CanCast(E,mode) and time > W.LastWC and not Q:IsReady() then
        for k,v in pairs(GetTargetsRange(E.Radius + E2.Radius)) do 
            if E:IsInRange(v) then Fizz.CastE(v.Position) end
            if E:GetName() == "FizzETwo" and Player:Distance(v) > 400 then 
                Fizz.CastE2(v.Position)
            end
        end
    end
end

function FizzHP.Waveclear()
    if Menu.Get("ManaSliderLane") > Player.ManaPercent * 100 then return end
    if Lane(E) then
        local EPoint = {}
        for k, v in pairs(Obj.Get("enemy", "minions")) do
            local minion = v.AsAI
            if ValidAI(minion,E.Range) then
                local pos = minion:FastPrediction(Game.GetLatency()+ E.Delay)
                local isKillable = DmgLib.CalculateMagicalDamage(Player, minion, edmg()) > minion.Health
                if pos:Distance(Player.Position) < E.Range and isKillable then
                    table.insert(EPoint, pos)
                end
            end                       
        end
        local bestPos, hitCount = E:GetBestCircularCastPos(EPoint, E.Radius)
        if bestPos and hitCount >= Menu.Get("Lane.EH") then
            Fizz.CastE(bestPos)
        end
    end
end

function FizzNP.Waveclear()
    local time = os.clock()
    local list = {}
    local QList = {}
    local WList = {}
    if W:IsReady() then W.LastW = os.clock() + 2 end
    for k,v in pairs(Obj.Get("enemy","minions")) do
        local trueRange = W.Range + Player.BoundingRadius + v.AsAI.BoundingRadius
        if ValidAI(v, trueRange) then 
            table.insert(list,v.AsAI)
        end
    end
    SortMinion(list)
    if Menu.Get("ManaSliderLane") < Player.ManaPercent * 100 then 
        if not list then return end
        if Lane(W) then 
            for k,minion in pairs(list) do 
                local healthPred = W:GetHealthPred(minion)
                local WDmg = DmgLib.CalculateMagicalDamage(Player, minion, dmg(W))
                local AADmg = Orb.GetAutoAttackDamage(minion)
                local Sheendmg = DmgLib.CalculatePhysicalDamage(Player, minion, dmgsheen())
                if healthPred > 0 and healthPred < math.floor(WDmg + AADmg + Sheendmg) then 
                    Orb.StopIgnoringMinion(minion)
                    if W:Cast() then return end
                end        
            end  
        end 
        if Lane(Q) and time > W.LastW  and not W:IsReady() then 
            for k,v in pairs(Obj.Get("enemy","minions")) do
                if ValidAI(v,Q.Range) then 
                    local minion = v.AsAI
                    local healthPred = Q:GetHealthPred(minion)
                    local QDmg = DmgLib.CalculateMagicalDamage(Player, minion, dmg(Q))
                    local AADmg = Orb.GetAutoAttackDamage(minion)
                    local Sheendmg = DmgLib.CalculatePhysicalDamage(Player, minion, dmgsheen())
                    if healthPred > 0 and healthPred < math.floor(QDmg + AADmg + Sheendmg) then 
                        if Q:Cast(minion) then return end
                    end       
                end
            end
        end 
    end
    if Jungle(Q) then 
        for k,v in pairs(Obj.GetNearby("neutral","minions")) do
            if ValidAI(v, Q.Range) then 
                table.insert(QList,v.AsAI)
            end
        end
        SortMinion(QList)
        if not QList then return end
        for k,minion in pairs(QList) do 
            if minion then 
                if Q:Cast(minion) then return end
            end    
        end  
    end 
    if Jungle(W) then 
        for k,v in pairs(Obj.GetNearby("neutral","minions")) do
            local trueRange = W.Range + Player.BoundingRadius + v.AsAI.BoundingRadius
            if ValidAI(v, trueRange) then 
                table.insert(WList,v.AsAI)
            end
        end
        SortMinion(WList)
        if not WList then return end
        for k,minion in pairs(WList) do 
            if minion then 
                Orb.StopIgnoringMinion(minion)
                if W:Cast() then return end
            end    
        end  
    end 
    if Jungle(E) and time > W.LastW and not (Q:IsReady() and W:IsReady()) then 
        for k,v in pairs(Obj.GetNearby("neutral","minions")) do
            local trueRange = E.Radius
            if ValidAI(v, trueRange) then 
                Fizz.CastE(v.Position)
            end
        end
    end 
end

function FizzNP.Lasthit()
    local time = os.clock()
    local list = {}
    if W:IsReady() then W.LastW = os.clock() + 2 end
    for k,v in pairs(Obj.Get("enemy","minions")) do
        local trueRange = W.Range + Player.BoundingRadius + v.AsAI.BoundingRadius
        if ValidAI(v,trueRange) then 
            table.insert(list,v.AsAI)
        end
    end
    if not list then return end
    SortMinion(list)
    if LastHit(W) then 
        for k,minion in pairs(list) do 
            local healthPred = W:GetHealthPred(minion)
            local WDmg = DmgLib.CalculateMagicalDamage(Player, minion, dmg(W))
            local AADmg = Orb.GetAutoAttackDamage(minion)
            local Sheendmg = DmgLib.CalculatePhysicalDamage(Player, minion, dmgsheen())
            if healthPred > 0 and healthPred < math.floor(WDmg + AADmg + Sheendmg) then 
                Orb.StopIgnoringMinion(minion)
                if W:Cast() then return end
            end       
        end  
    end 
    if LastHit(Q) and time > W.LastW  and not W:IsReady()  then 
        for k,v in pairs(Obj.Get("enemy","minions")) do
            if ValidAI(v,Q.Range) then 
                local minion = v.AsAI
                if not minion.IsEpicMinion then return end
                local healthPred = Q:GetHealthPred(minion)
                local QDmg = DmgLib.CalculateMagicalDamage(Player, minion, dmg(Q))
                local AADmg = Orb.GetAutoAttackDamage(minion)
                local Sheendmg = DmgLib.CalculatePhysicalDamage(Player, minion, dmgsheen())
                if healthPred > 0 and healthPred < math.floor(QDmg + AADmg + Sheendmg) then 
                    if Q:Cast(minion) then return end
                end       
            end
        end
    end
end

function FizzNP.Flee()
    if Flee(E) then 
        local pos = Renderer.GetMousePos()
        if E:Cast(pos) then return end
    end
    if Flee(Q) then 
        local pos = Renderer.GetMousePos()
        for k, Object in pairs(Obj.Get("enemy", "heroes")) do
            local Hero = Object.AsHero
            if Hero:Distance(pos) < 200 then 
                Q:Cast(Hero)
            end
        end
        for k, Object in pairs(Obj.Get("enemy", "minions")) do
            local minion = Object.AsAI
            local valid = minion.MaxHealth > 6 and minion.IsTargetable
            if valid and minion:Distance(pos) < 200 then 
                Q:Cast(minion)
            end
        end
        for k, Object in pairs(Obj.Get("neutral", "minions")) do
            local minion = Object.AsAI
            local valid = minion.MaxHealth > 6 and minion.IsTargetable
            if valid and minion:Distance(pos) < 200 then 
                Q:Cast(minion)
            end
        end
    end
end

--[[Spell Functions]]
function Fizz.CastE(pos)
    if E:GetName() == "FizzE" then
        E:Cast(pos)
    end
end

function Fizz.CastE2(pos)
    if E2:Cast(pos) then return end
end

function Fizz.CastR(target,HitChance)
    if R:CastOnHitChance(target,HitChance) then return end
end

--[[Menu]]
function Fizz.LoadMenu()
    Menu.RegisterMenu("NAFizz", "NA Fizz", function()
        Menu.NewTree("Combo", "Combo Options", function()
            Menu.Checkbox("Combo.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Combo.CastW",   "Use [W]", true)
            Menu.Checkbox("Combo.CastE",   "Use [E]", true)
            Menu.Checkbox("Combo.CastR",   "Use [R]", true)
            Menu.Checkbox("R0",   "^ Use Guppy  ", false)
            Menu.Checkbox("R1",   "^ Use Chomper  ", true)
            Menu.Checkbox("R2",   "^ Use GIGALODON  ", true)
            Menu.NewTree("RRange", "[R] Range Options", function()
                Menu.Slider("R.Max", "[R] Max Range",1250,0,1300)   
            end)
        end)
        Menu.NewTree("Harass", "Harass Options", function()
            Menu.ColoredText("Mana Percent limit", 0xFFD700FF, true)
            Menu.Slider("ManaSlider","",50,0,100)
            Menu.Checkbox("Harass.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Harass.CastW",   "Use [W]", true)
            Menu.Checkbox("Harass.CastE",   "Use [E]", false)
        end)
        Menu.NewTree("Waveclear", "Waveclear Options", function()
            Menu.NewTree("Lane", "Lane Options", function() 
                Menu.ColoredText("Mana Percent limit", 0xFFD700FF, true)
                Menu.Slider("ManaSliderLane","",30,0,100)
                Menu.Checkbox("Lane.Q",   "Use [Q] | Logic", true)
                Menu.Checkbox("Lane.W",   "Use [W]", true)
                Menu.Checkbox("Lane.E",   "Use [E] Only When Killable", true)
                Menu.Slider("Lane.EH","E HitCount",3,1,5)
            end)
            Menu.NewTree("Lasthit", "Lasthit Options", function() 
                Menu.Checkbox("LastHit.Q",   "Use [Q] | Logic", true)
                Menu.Checkbox("LastHit.W",   "Use [W]", true)
            end)
            Menu.NewTree("Structure", "Structure Options", function() 
                Menu.Checkbox("Structure.W",   "Use [W]", true)
            end)
            Menu.NewTree("Jungle", "Jungle Options", function() 
                Menu.Checkbox("Jungle.Q",   "Use [Q] | Logic", true)
                Menu.Checkbox("Jungle.W",   "Use [W]", true)
                Menu.Checkbox("Jungle.E",   "Use [E]", true)
            end)
        end)
        Menu.NewTree("KS", "KillSteal Options", function()
            Menu.Checkbox("KS.Q"," Use Q to Ks", true)
            Menu.Checkbox("KS.I"," Use Ignite to Ks", true)
        end)
        Menu.NewTree("Flee", "Flee Options", function()
            Menu.Checkbox("Flee.Q"," Use Q ", true)
            Menu.Checkbox("Flee.E"," Use E ", true)
        end)
        Menu.NewTree("MiscTargeterd", "Misc Targeterd Spells Options", function()
            Menu.Checkbox("Misc.ET","Auto Dodge Tower Shots",true)
            for k, Object in pairs(Obj.Get("enemy", "heroes")) do
                local Hero = Object.AsHero.CharName
                if targetedSpells[Hero] then 
                    Menu.NewTree(Hero,Hero, function()
                    if targetedSpells[Hero].Slot == 0 then Menu.Checkbox(0 .. Hero, "Use on " .. "Q", true) end
                    if targetedSpells[Hero].Slot == 1 then Menu.Checkbox(1 .. Hero, "Use on " .. "W", true) end
                    if targetedSpells[Hero].Slot == 2 then Menu.Checkbox(2 .. Hero, "Use on " .. "E", true) end
                    if targetedSpells[Hero].Slot == 3 then Menu.Checkbox(3 .. Hero, "Use on " .. "R", true) end
                    Menu.ColoredText("Danger Level" .. targetedSpells[Hero].Danger, 0xFFFFFFFF, true)
                    end)
                end  
            end
            Menu.Checkbox("Misc.EST","Auto Dodge Targeted spells",true)
            Menu.Slider("Targeted","^ when Danger level",2,1,3)
            Menu.Checkbox("Misc.Zhonyas","Auto ZhonyasHourglass | When E not Ready",true)
            Menu.Slider("Zhonyas","^ when Danger level",3,1,3)
        end)
        Menu.NewTree("Misc", "Misc Options", function()
            Menu.Checkbox("Misc.RI",   "Use [R] on Interrupter", true)
            Menu.NewTree("Interrupter", "Interrupter Whitelist", function()
                for _, Object in pairs(Obj.Get("enemy", "heroes")) do
                    local Name = Object.AsHero.CharName
                    Menu.Checkbox("2" .. Name, "Use on " .. Name, false)
                end
            end)
            Menu.Checkbox("Misc.EGap",   "Use [E] on gapclose", true)
            Menu.NewTree("gapclose", "gapclose Whitelist", function()
                for _, Object in pairs(Obj.Get("enemy", "heroes")) do
                    local Name = Object.AsHero.CharName
                    Menu.Checkbox("3" .. Name, "Use on " .. Name, false)
                end
            end)
        end)
        Menu.NewTree("Prediction", "Prediction Options", function()
            Menu.Slider("Chance.R","R HitChance", 0.75, 0, 1, 0.05)
        end)
        Menu.NewTree("Draw", "Drawing Options", function()
            Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range",true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0x118AB2FF)
            Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range",false)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)
            Menu.Checkbox("Drawing.R.Enabled",   "Draw [R] Range",false)
            Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0x118AB2FF)
        end)
    end)     
end

-- LOAD
function OnLoad()
    Fizz.LoadMenu()
    Event.RegisterCallback(Enums.Events.OnProcessSpell, OnProcessSpell) -- for Faster function recall 
    for eventName, eventId in pairs(Enums.Events) do
        if Fizz[eventName] then
            Event.RegisterCallback(eventId, Fizz[eventName])
        end
    end    
    return true
end