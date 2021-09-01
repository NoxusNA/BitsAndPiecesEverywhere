if _G.CoreEx.ObjectManager.Player.CharName ~= "Riven" then
    return
end
local ScriptName, Version = "RivenMechanics", "0.1"
module(ScriptName, package.seeall, log.setup)
clean.module(ScriptName, clean.seeall, log.setup)

local SDK = _G.CoreEx
local Lib = _G.Libs
local Obj = SDK.ObjectManager
local Player = Obj.Player
local Event = SDK.EventManager
local Enums = SDK.Enums
local Renderer = SDK.Renderer
local Input = SDK.Input

local TS = Lib.TargetSelector()
local HitChanceEnum = SDK.Enums.HitChance
local Menu = Lib.NewMenu
local Orb = Lib.Orbwalker
local Pred = Lib.Prediction
local DmgLib = Lib.DamageLib
local Spell = Lib.Spell
local Geometry = SDK.Geometry
local Vector = Geometry.Vector

local basePosition = Player.TeamId == 100 and Vector(14302, 172, 14387) or Vector(415, 182, 415)

local UsableItems = {
    Prowler = {
        ProwlerItemIds = {7000, 6693},
        Range = 500
    },
    Youmuus = {
        YoumuusItemIds = {3388, 3142},
        Range = 0
    },
    GaleForce = {
        GaleForceItemIds = {6671},
        Range = 425
    },
    Goredrinker = {
        GoredrinkerItemIds = {6630},
        Range = 450
    },
    Stridebreaker = {
        StridebreakerItemIds = {6631},
        Range = 450
    }
}

local UsableSS = {
    Ignite = {
        Slot = nil,
        Range = 600
    },
    Smite = {
        Slot = nil,
        Range = 500
    },
    Flash = {
        Slot = nil,
        Range = 400
    }
}

local spells = {
    Q = Spell.Targeted({
        Slot = Enums.SpellSlots.Q,
        Range = 275,
        Delay = 0,
        Type = "Circular",
        Key = "Q"
    }),
    W = Spell.Active({
        Slot = Enums.SpellSlots.W,
        Delay = 0.25,
        Range = 300,
        Key = "W"
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 300,
        Type = "Linear",
        Key = "E"
    }),
    R = Spell.Active({
        Slot = Enums.SpellSlots.R,
        Delay = 0.25,
        Key = "R"
    }),
    R2 = Spell.Skillshot({
        Slot = Enums.SpellSlots.R,
        Type = "Cone",
        Range = 1100,
        Delay = 0.25,
        ConeAngleRad = 18 * math.pi / 180,
        Speed = 1600,
        Radius = 200,
        Collisions = {
            Minions = false,
            WindWall = true,
            Heroes = false,
            Wall = false
        },
        Key = "R"
    })
}

local isFastCombo = false

local DelayCastQ = function(Target)
    if Player:IsFacing(Target, 30) and spells.Q:IsReady() then
        spells.Q:Cast(Target)
    else
        Orb.BlockMove(false)
        Orb.BlockAttack(false)
    end
end

local DelayCastE = function(Target)
    if spells.E:IsReady() then
        spells.E:Cast(Target.Position)
    end
end

local DelayCastW = function()
    if spells.W:IsReady() then
        spells.W:Cast()
    end
end

local DelayCastR1 = function()
    if spells.R:IsReady() then
        spells.R:Cast()
    end
end

local DelayCastR2 = function(Target)
    if spells.R2:IsReady() then
        spells.R2:Cast(Target.Position)
    end
end

function IsAutoAttack(spellCast)
    return spellCast.Name == "RivenBasicAttack" or spellCast.Name == "RivenBasicAttack2" or spellCast.Name ==
               "RivenBasicAttack3" or spellCast.Name == "RivenCritAttack"
end

function IsInFountain()
    return Player:Distance(basePosition) < 300
end

function HasItem(itemId)
    for itemSlot, item in pairs(Player.Items) do
        if item and item.ItemId == itemId then
            return itemSlot, item
        end
    end

    return nil, nil
end

function NumberOrMax(number, max)
    if not number or number == nil or number > max then
        return max
    else
        return number
    end
end

function IsQUp()
    local hasPassive = false
    local timeLeft = 0
    for k, v in pairs(Player.Buffs) do
        if v.Name == "RivenTriCleave" then
            timeLeft = v.DurationLeft
            return true, timeLeft
        end
    end
    return hasPassive, timeLeft
end

function IsR1()
    return spells.R:GetName() == "RivenFengShuiEngine"
end

function IsR2()
    return spells.R:GetName() == "RivenIzunaBlade"
end

function IsQ1()
    for k, v in pairs(Player.Buffs) do
        if v.Name == "riventricleavesoundone" then
            return false
        end
        if v.Name == "riventricleavesoundtwo" then
            return false
        end
    end
    return spells.Q:IsReady()
end

function IsQ2()
    for k, v in pairs(Player.Buffs) do
        if v.Name == "riventricleavesoundone" then
            return true and spells.Q:IsReady()
        end
    end
    return false
end

function IsQ3()
    for k, v in pairs(Player.Buffs) do
        if v.Name == "riventricleavesoundtwo" then
            return true and spells.Q:IsReady()
        end
    end
    return false
end

function IsInAARange(Target)
    return Player:Distance(Target) <= Player.AttackRange + 100
end

function GetItemSlot(Arr)
    for _, itemId in ipairs(Arr) do
        local slot, item = HasItem(itemId)

        if slot then
            slot = slot + 6

            if Player:GetSpellState(slot) == Enums.SpellStates.Ready then
                return slot
            end
        end
    end

    return nil
end

function GetActiveItem()
    local hasProwler, hasGaleForce, hasGoredrinker, hasStridebreaker = GetItemSlot(UsableItems.Prowler.ProwlerItemIds),
        GetItemSlot(UsableItems.GaleForce.GaleForceItemIds), GetItemSlot(UsableItems.Goredrinker.GoredrinkerItemIds),
        GetItemSlot(UsableItems.Stridebreaker.StridebreakerItemIds)
    return hasProwler or hasGaleForce or hasGoredrinker or hasStridebreaker
end

function CheckIgniteSlot()
    local slots = {Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2}

    local function IsIgnite(slot)
        return Player:GetSpell(slot).Name == "SummonerDot"
    end

    for _, slot in ipairs(slots) do
        if IsIgnite(slot) then
            if UsableSS.Ignite.Slot ~= slot then
                UsableSS.Ignite.Slot = slot
            end

            return
        end
    end

    if UsableSS.Ignite.Slot ~= nil then
        UsableSS.Ignite.Slot = nil
    end
end

function CheckFlashSlot()
    local slots = {Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2}

    local function IsFlash(slot)
        return Player:GetSpell(slot).Name == "SummonerFlash"
    end

    for _, slot in ipairs(slots) do
        if IsFlash(slot) then
            if UsableSS.Flash.Slot ~= slot then
                UsableSS.Flash.Slot = slot
            end

            return
        end
    end

    if UsableSS.Flash.Slot ~= nil then
        UsableSS.Flash.Slot = nil
    end
end

function CheckSmiteSlot()
    local slots = {Enums.SpellSlots.Summoner1, Enums.SpellSlots.Summoner2}

    local function IsSmite(slot)
        return Player:GetSpell(slot).Name == "S5_SummonerSmiteDuel" or Player:GetSpell(slot).Name ==
                   "S5_SummonerSmitePlayerGanker" or Player:GetSpell(slot).Name == "SummonerSmite"
    end

    for _, slot in ipairs(slots) do
        if IsSmite(slot) then
            if UsableSS.Smite.Slot ~= slot then
                UsableSS.Smite.Slot = slot
            end

            return
        end
    end

    if UsableSS.Ignite.Slot ~= nil then
        UsableSS.Ignite.Slot = nil
    end
end

BaseStrucutre = {}

function BaseStrucutre:new(dat)
    dat = dat or {}
    setmetatable(dat, self)
    self.__index = self
    return dat
end

function BaseStrucutre:Menu()
    Menu.RegisterMenu(ScriptName, ScriptName .. " V" .. Version, function()
        Menu.NewTree("Combo", "Combo Options", function()
            Menu.Checkbox("Combo.CastQ", "Use Q", true)
            Menu.Checkbox("Combo.KeepQUp", "Keep Q Up", true)
            Menu.Checkbox("Combo.CastW", "Use W", true)
            Menu.Checkbox("Combo.CastE", "Use E", true)
            Menu.Checkbox("Combo.CastR", "Use R", true)
            Menu.Checkbox("Combo.CastR2", "Use R2", true)
            Menu.Checkbox("Combo.UseItem", "Use Offensive Items (If Available)", true)
            Menu.Checkbox("Combo.CastIgnite", "Use Ignite", true)
            Menu.Checkbox("Combo.CastSmite", "Use Smite", true)
            Menu.Checkbox("Combo.Flash", "Use Flash if Killable", false)
        end)
        Menu.NewTree("Harass", "Harass Options", function()
            Menu.ColoredText("Mana Percent limit", 0xFFD700FF, true)
            Menu.Slider("Harass.ManaSlider", "", 70, 0, 100)
            Menu.Checkbox("Harass.CastQ", "Use Q", true)
            Menu.Checkbox("Harass.CastW", "Use W", true)
            Menu.Checkbox("Harass.CastE", "Use E", true)
        end)
        Menu.NewTree("Lasthit", "LastHit Options", function()
            Menu.ColoredText("Mana Percent limit", 0xFFD700FF, true)
            Menu.Slider("Lasthit.ManaSlider", "", 50, 0, 100)
            Menu.Checkbox("Lasthit.CastQ", "Use Q", true)
            Menu.Checkbox("Lasthit.CastW", "Use W", true)
        end)
        Menu.NewTree("Waveclear", "Waveclear Options", function()
            Menu.Slider("Lane.ManaSlider", "Lane Mana Slider", 70, 0, 100)
            Menu.NewTree("Lane", "Lane Options", function()
                Menu.Checkbox("Lane.Q", "Use Q", true)
                Menu.Checkbox("Lane.W", "Use W", true)
                Menu.Checkbox("Lane.E", "Use E", false)
            end)
            Menu.NewTree("Jungle", "Jungle Options", function()
                Menu.Checkbox("Jungle.Q", "Use Q", true)
                Menu.Checkbox("Jungle.W", "Use W", true)
                Menu.Checkbox("Jungle.E", "Use E", true)
            end)
        end)
        Menu.NewTree("Misc", "Misc Options", function()
        end)
        Menu.NewTree("Draw", "Drawing Options", function()
            Menu.Checkbox("Drawing.Damage", "Draw Possible DMG", false)
            Menu.Checkbox("Drawing.Q.Enabled", "Draw Q Range", false)
            Menu.Checkbox("Drawing.W.Enabled", "Draw W Range", false)
            Menu.Checkbox("Drawing.E.Enabled", "Draw E Range", false)
            Menu.Checkbox("Drawing.R.Enabled", "Draw R Range", false)
        end)
    end)
end

function BaseStrucutre:GetQDmg()
    return 20 + spells.Q:GetLevel() * 15 + ((40 + spells.Q:GetLevel() * 5) / 100 * Player.TotalAD)
end

function BaseStrucutre:GetWDmg()
    return 25 + spells.W:GetLevel() * 30 + (1 * Player.TotalAD)
end

function BaseStrucutre:GetEDmg()
    return 0
end

function BaseStrucutre:GetRDmg(Target)
    local dmgCalc = 100 + spells.R:GetLevel() * 50 + (0.6 * Player.TotalAD)
    return dmgCalc +
               (dmgCalc * NumberOrMax(math.ceil(100 - (Target.Health * 100) / Target.MaxHealth) * 2.667, 200) / 100)
end

function BaseStrucutre:GetIgniteDmg(target)
    return 50 + 20 * Player.Level - target.HealthRegen * 2.5
end

function BaseStrucutre:GetLastHitMinion(pos, range, possibleDmg, collision, onlyKillable)
    local lastHitMinion = nil
    for k, v in pairs(Obj.GetNearby("enemy", "minions")) do
        local minion = v.AsAttackableUnit
        if minion.IsValid and not minion.IsDead and minion.IsTargetable and minion:Distance(pos) < range then
            if minion.Health < possibleDmg or not onlyKillable then
                if collision then
                    local qPred = Pred.GetPredictedPosition(minion, spells.Q, Player.Position)
                    if qPred and qPred.HitChanceEnum >= HitChanceEnum.VeryLow then
                        return minion
                    end
                elseif lastHitMinion == nil or minion.Health < lastHitMinion.Health then
                    lastHitMinion = minion
                end
            end
        end
    end
    return lastHitMinion
end

function BaseStrucutre:GetLastHitMonster(pos, range, possibleDmg, collision, onlyKillable)
    local lastHitMinion = nil
    for k, v in pairs(Obj.GetNearby("neutral", "minions")) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable and
            minion:Distance(pos) < range then
            if minion.Health < possibleDmg or not onlyKillable then
                if collision then
                    local qPred = Pred.GetPredictedPosition(minion, spells.Q, Player.Position)
                    if qPred and qPred.HitChanceEnum >= HitChanceEnum.VeryLow then
                        return minion
                    end
                elseif lastHitMinion == nil or minion.Health < lastHitMinion.Health then
                    lastHitMinion = minion
                end
            end
        end
    end
    return lastHitMinion
end

function BaseStrucutre:CountMinionsInRange(range, type)
    local amount = 0
    for k, v in pairs(Obj.GetNearby(type, "minions")) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable and
            Player:Distance(minion) < range then
            amount = amount + 1
        end
    end
    return amount
end

function BaseStrucutre:GetPriorityMinion(pos, type, maxRange)
    local minionFocus = nil
    for k, v in pairs(self:GetNerbyMinions(pos, type, maxRange)) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable then
            if minionFocus == nil then
                minionFocus = minion
            elseif minionFocus.IsEpicMinion then
                minionFocus = minion
            elseif not minionFocus.IsEpicMinion and minionFocus.IsEliteMinion then
                minionFocus = minion
            elseif not minionFocus.IsEpicMinion and not minionFocus.IsEliteMinion then
                if minion.Health < minionFocus.Health or minionFocus:Distance(pos) > minion:Distance(pos) then
                    minionFocus = minion
                end
            end
        end
    end
    return minionFocus
end

function BaseStrucutre:GetNerbyMinions(pos, type, maxRange)
    local minionTable = {}
    for k, v in pairs(Obj.Get(type, "minions")) do
        local minion = v.AsMinion
        if not minion.IsJunglePlant and minion.IsValid and not minion.IsDead and minion.IsTargetable and
            minion:Distance(pos) < maxRange then
            table.insert(minionTable, minion)
        end
    end
    return minionTable
end

function BaseStrucutre:GetNerbyTargets(target, range)
    local objTable = {}
    for k, v in pairs(Obj.GetNearby("all", "minions")) do
        local obj = v.AsAttackableUnit
        if obj.IsValid and obj.IsDead and target:Distance(obj) < range then
            table.insert(objTable, obj)
        end
    end
    for k, v in pairs(Obj.GetNearby("all", "heroes")) do
        local obj = v.AsAttackableUnit
        if obj.IsValid and obj.IsDead and not obj.IsMe and target:Distance(obj) < range then
            table.insert(objTable, obj)
        end
    end
    return objTable
end

function BaseStrucutre:GetNearstTarget(target, range)
    local obj = nil
    for k, v in pairs(self:GetNerbyTargets(target, range)) do
        if obj ~= nil and target:Distance(v) < target:Distance(obj) then
            obj = v
        else
            obj = v
        end
    end
    return obj
end

function BaseStrucutre:GetSmiteDmg()
    local smiteData = Player:GetSpell(UsableSS.Smite.Slot)
    if smiteData.Name == "S5_SummonerSmiteDuel" then
        return 41 + Player.Level * 7
    elseif smiteData.Name == "S5_SummonerSmitePlayerGanker" then
        return 11.3 + Player.Level * 8.6
    elseif smiteData.Name == "SummonerSmite" then
        return 0
    end
    return 0
end

function BaseStrucutre:TotalDmg(Target, countSS)
    local Damage = DmgLib.CalculatePhysicalDamage(Player, Target, Player.TotalAD)
    if spells.Q:IsReady() and spells.Q:IsInRange(Target) then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetQDmg() * 3)
    elseif spells.Q:IsReady() and Player:Distance(Target) < spells.Q.Range * 2 then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetQDmg() * 2)
    elseif spells.Q:IsReady() and Player:Distance(Target) < spells.Q.Range * 3 then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetQDmg())
    end
    if spells.W:IsReady() and spells.W:IsInRange(Target) then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetWDmg())
    end
    if UsableSS.Ignite.Slot ~= nil and Player:GetSpellState(UsableSS.Ignite.Slot) == Enums.SpellStates.Ready and countSS and
        Player:Distance(Target) < UsableSS.Ignite.Range then
        Damage = Damage + DmgLib.CalculateMagicalDamage(Player, Target, self:GetIgniteDmg(Target))
    end
    if spells.E:IsReady() and spells.E:IsInRange(Target) then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetEDmg())
    end
    if spells.R:IsReady() and IsInAARange(Target) then
        Damage = Damage + DmgLib.CalculatePhysicalDamage(Player, Target, self:GetRDmg(Target))
    end
    return Damage
end

function BaseStrucutre:CountHeroes(pos, range, team)
    local num = 0
    for k, v in pairs(Obj.Get(team, "heroes")) do
        local hero = v.AsHero
        if hero.IsValid and not hero.IsDead and hero.IsTargetable and hero:Distance(pos) < range then
            num = num + 1
        end
    end
    return num
end

function BaseStrucutre:IsInDanger(Target)
    if Target.IsEnemy or Target.IsDead then
        return false
    end
    local amountThreats = self:CountHeroes(Target.Position, spells.W.Range, "ally")
    if amountThreats >= 1 and Target.HealthPercent <= 0.2 then
        return true
    end

    return false
end

function BaseStrucutre:OnDraw()
    if Menu.Get("Drawing.Q.Enabled") then
        Renderer.DrawCircle3D(Player.Position, spells.Q.Range, 30, 4, 0x118AB2FF)
    end
    if Menu.Get("Drawing.W.Enabled") then
        Renderer.DrawCircle3D(Player.Position, spells.W.Range, 30, 4, 0x118AB2FF)
    end
    if Menu.Get("Drawing.E.Enabled") then
        Renderer.DrawCircle3D(Player.Position, spells.E.Range, 30, 4, 0x118AB2FF)
    end
    if Menu.Get("Drawing.R.Enabled") then
        Renderer.DrawCircle3D(Player.Position, spells.R.Range, 30, 4, 0x118AB2FF)
    end
end

function BaseStrucutre:AutoCast()
    local keepQUp = Menu.Get("Combo.KeepQUp")
    if Orb.GetMode() == "Combo" and keepQUp and spells.Q:IsReady() then
        local isQUp, timeLeft = IsQUp()
        if isQUp and timeLeft < 0.3 then
            Input.Cast(spells.Q.Slot)
        end
    end
end

function BaseStrucutre:Combo(postAttack)
    if Orb.IsWindingUp() then
        return
    end
    local CastQ, CastW, CastE, CastR, CastR2, CastIgnite, CastSmite, UseItem, Flash = Menu.Get("Combo.CastQ"),
        Menu.Get("Combo.CastW"), Menu.Get("Combo.CastE"), Menu.Get("Combo.CastR"), Menu.Get("Combo.CastR2"),
        Menu.Get("Combo.CastIgnite"), Menu.Get("Combo.CastSmite"), Menu.Get("Combo.UseItem"), Menu.Get("Combo.Flash")
    local Target = TS:GetTarget(1200, true)
    local hasActiveItem = GetActiveItem()

    if not Target then
        return
    end

    local rDmg = self:GetRDmg(Target)

    if hasActiveItem and Player:GetSpellState(hasActiveItem) == Enums.SpellStates.Ready and
        (Player.HealthPercent < 0.5 or (not spells.Q:IsReady() and IsInAARange(Target))) then
            Input.Cast(hasActiveItem, Target.Position)
        return
    end

    if CastIgnite and UsableSS.Ignite.Slot ~= nil and Player:GetSpellState(UsableSS.Ignite.Slot) ==
        Enums.SpellStates.Ready and self:GetIgniteDmg(Target) > Target.Health + 10 and Player:Distance(Target) <
        UsableSS.Ignite.Range then
        Input.Cast(UsableSS.Ignite.Slot, Target)
        return
    end

    if CastQ and CastE and CastR2 and IsR2() and spells.E:IsReady() and Player:Distance(Target) < spells.Q.Range + spells.E.Range and rDmg > Target.Health then
        delay(50, DelayCastE, Target)
        delay(150, DelayCastR2, Target)
        return
    end

    if CastW and spells.W:IsReady() and spells.W:IsInRange(Target) then
        if spells.R2:IsReady() and IsR2() and CastR2 and rDmg >
            Target.Health then
            spells.W:Cast()
            delay(150, DelayCastR2, Orb.GetTarget())
            return
        elseif (not spells.R2:IsReady() or not IsR2()) and
            spells.W:IsInRange(Target) then
            spells.W:Cast()
            return
        end
    end

    if (not isFastCombo or not IsInAARange(Target)) and CastE and spells.E:IsReady() and Player:Distance(Target) < spells.E.Range + Player.AttackRange - 50 then
        if spells.R:IsReady() and IsR1() and CastR then
            spells.E:Cast(Target.Position)
            delay(125, DelayCastR1, nil)
            return
        elseif spells.R:IsReady() and IsR2() and CastR2 then
            spells.E:Cast(Target.Position)
            delay(125, DelayCastR2, Target)
            return
        elseif spells.W:IsReady() and CastW then
            spells.E:Cast(Target.Position)
            delay(150, DelayCastW, nil)
            return
        end
    end

    if CastQ and spells.Q:IsReady() and not spells.W:IsReady() and not spells.E:IsReady() and not spells.R:IsReady() then
        if IsInAARange(Target) then
            isFastCombo = true
            return
        elseif Player:IsFacing(Target, 30) and not IsInAARange(Target) and Player:Distance(Target) < spells.Q.Range +
            Player.AttackRange then
            isFastCombo = true
            spells.Q:Cast(Target)
            return
        elseif Player:IsFacing(Target, 30) and not IsInAARange(Target) and Player:Distance(Target) > spells.Q.Range +
            Player.AttackRange and Player:Distance(Target) < spells.Q.Range * 2 + Player.AttackRange then
            spells.Q:Cast(Target)
            return
        elseif not IsInAARange(Target) and isFastCombo then
            isFastCombo = false
            return
        end
    end
end

function BaseStrucutre:Harass(postAttack)
    local CastQ, CastW, CastE = Menu.Get("Harass.CastQ"), Menu.Get("Harass.CastW"), Menu.Get("Harass.CastE")
    local Target = TS:GetTarget(spells.Q.Range, true)
    if not Target then
        return
    end

    if CastW and spells.W:IsReady() and postAttack and IsInAARange(Target) then
        spells.W:Cast()
        return
    end

    if CastQ and spells.Q:IsReady() and (postAttack or not IsInAARange(Target)) then
        if spells.Q:IsInRange(Target) then
            spells.Q:Cast()
            return
        end
    end

    if CastE and spells.E:IsReady() then
        spells.E:Cast()
        return
    end

end

function BaseStrucutre:Lasthit(postAttack)
    local ManaSlider, CastQ, CastW = Menu.Get("Lasthit.ManaSlider"), Menu.Get("Lasthit.CastQ"),
        Menu.Get("Lasthit.CastW")
    local minions = Obj.GetNearby("enemy", "minions")
    if #minions == 0 or Player.ManaPercent <= ManaSlider / 100 then
        return
    end
    if CastW and spells.W:IsReady() and postAttack then
        local lastHitMinion = self:GetLastHitMinion(Player.Position, Player.AttackRange, self:GetWDmg(), false, true)
        if lastHitMinion == nil then
            return
        else
            spells.W:Cast()
            return
        end
    end
    if CastQ and spells.Q:IsReady() and postAttack then
        local lastHitMinion = self:GetLastHitMinion(Player.Position, spells.Q.Range, self:GetQDmg(), false, true)
        if lastHitMinion == nil then
            return
        else
            spells.Q:Cast(lastHitMinion)
            return
        end
    end
end

function BaseStrucutre:Waveclear(postAttack)
    local ManaSlider, CastQLane, CastWLane, CastQJungle, CastWJungle, CastEJungle = Menu.Get("Lane.ManaSlider"),
        Menu.Get("Lane.Q"), Menu.Get("Lane.W"), Menu.Get("Jungle.Q"), Menu.Get("Jungle.W"), Menu.Get("Jungle.E")
    local minions = self:CountMinionsInRange(500, "enemy")
    local monsters = self:CountMinionsInRange(500, "neutral")
    if (minions == 0 and monsters == 0) or Player.ManaPercent <= ManaSlider / 100 then
        return
    end

    if minions > monsters then
        local minionFocus = self:GetPriorityMinion(Player.Position, "enemy", spells.Q.Range)
        if minionFocus == nil then
            return
        end
        if CastWLane and postAttack then
            spells.W:Cast()
            return
        end
        if CastQLane and spells.Q:IsReady() then
            spells.Q:Cast(minionFocus)
            return
        end
    else
        local minionFocus = self:GetPriorityMinion(Player.Position, "neutral", spells.Q.Range)
        if minionFocus == nil then
            return
        end
        if minionFocus.IsEpicMinion then
            if (minionFocus.Health < 1300 and UsableSS.Smite.Slot ~= nil) and self:TotalDmg(minionFocus, false) <
                minionFocus.Health then
                return
            end
            if CastQJungle and spells.Q:IsReady() and spells.Q:IsInRange(minionFocus) then
                spells.Q:Cast(minionFocus)
                return
            end
            if CastWJungle and spells.W:IsReady() and postAttack and IsInAARange(minionFocus) then
                spells.W:Cast()
                return
            end
            if CastEJungle and spells.E:IsReady() and spells.E:IsInRange(minionFocus) then
                spells.E:Cast()
                return
            end
        else
            if CastQJungle and spells.Q:IsReady() and spells.Q:IsInRange(minionFocus) then
                spells.Q:Cast(minionFocus)
                return
            end
            if CastWJungle and spells.W:IsReady() and postAttack and IsInAARange(minionFocus) then
                spells.W:Cast()
                return
            end
            if CastEJungle and spells.E:IsReady() and spells.E:IsInRange(minionFocus) then
                spells.E:Cast()
                return
            end
        end
    end

end

function BaseStrucutre:OnLowPriority()
    CheckSmiteSlot()
    CheckIgniteSlot()
    CheckFlashSlot()
end

function BaseStrucutre:OnVisionLost(obj)
end

function BaseStrucutre:OnPostAttack()
    local orbMode = Orb.GetMode()
    if orbMode == "Combo" then
        self:Combo(true)
    elseif orbMode == "Harass" then
        self:Harass(true)
    elseif orbMode == "Waveclear" then
        self:Waveclear(true)
    elseif orbMode == "Lasthit" then
        self:Lasthit(true)
    end
end

function BaseStrucutre:OnLoop()
    self:AutoCast()
    local orbMode = Orb.GetMode()
    if orbMode == "Combo" then
        self:Combo(false)
    elseif orbMode == "Harass" then
        self:Harass(false)
    elseif orbMode == "Waveclear" then
        self:Waveclear(false)
    elseif orbMode == "Lasthit" then
        self:Lasthit(false)
    else
        isFastCombo = false
        Orb.BlockMove(false)
        Orb.BlockAttack(false)
    end
end

function BaseStrucutre:OnCreateObject(obj)
end

function BaseStrucutre:OnGapClose(source, dash)
end

function BaseStrucutre:OnDrawDamage(target, dmgList)
    if Menu.Get("Drawing.Damage") then
        table.insert(dmgList, self:TotalDmg(target, true))
    end
end

RivenMechanics = BaseStrucutre:new()

RivenMechanics:Menu()

-- Loading Components --

-- Events --
local OnNormalPriority = function()
    RivenMechanics:OnLoop()
end

local OnGapClose = function(source, dash)
    RivenMechanics:OnGapClose(source, dash)
end

local OnLowPriority = function()
    RivenMechanics:OnLowPriority()
end

local OnPostAttack = function()
    RivenMechanics:OnPostAttack()
end

local OnDraw = function()
    RivenMechanics:OnDraw()
end

local OnVisionLost = function(obj)
    RivenMechanics:OnVisionLost(obj)
end

local OnDrawDamage = function(target, dmgList)
    RivenMechanics:OnDrawDamage(target, dmgList)
end

local OnCreateObject = function(obj)
    RivenMechanics:OnCreateObject(obj)
end

local OnProcessSpell = function(obj, spellCast)
    if obj.IsMe then
        print(spellCast.Name)
    end
    local target = Orb.GetTarget()
    if target == nil or not target.IsValid then
        Orb.BlockMove(false)
        Orb.BlockAttack(false)
        return
    end
    if obj.IsMe and spellCast.Name == "RivenMartyr" then
        delay(700, Input.Attack, Orb.GetTarget())
        return
    end
    if not isFastCombo then
        return
    end
    if obj.IsMe and spellCast.Name == "RivenTriCleave" and IsInAARange(Orb.GetTarget()) then
        Orb.BlockMove(true)
        Orb.BlockAttack(true)
        Input.MoveTo(Orb.GetTarget().Position:Extended(Player.Position, 35))
        delay(75, Input.Attack, Orb.GetTarget())
    elseif obj.IsMe and (IsAutoAttack(spellCast)) then
        delay(225, DelayCastQ, Orb.GetTarget())
    end
end

function OnLoad()
    Event.RegisterCallback(Enums.Events.OnLowPriority, OnLowPriority)
    Event.RegisterCallback(Enums.Events.OnNormalPriority, OnNormalPriority)
    Event.RegisterCallback(Enums.Events.OnGapclose, OnGapClose)
    Event.RegisterCallback(Enums.Events.OnPostAttack, OnPostAttack)
    Event.RegisterCallback(Enums.Events.OnVisionLost, OnVisionLost)
    Event.RegisterCallback(Enums.Events.OnDraw, OnDraw)
    Event.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
    Event.RegisterCallback(Enums.Events.OnCreateObject, OnCreateObject)
    Event.RegisterCallback(Enums.Events.OnProcessSpell, OnProcessSpell)
    CheckIgniteSlot()
    CheckFlashSlot()
    CheckSmiteSlot()

    return true
end
