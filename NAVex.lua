if Player.CharName ~= "Vex" then return false end

module("NAVex", package.seeall, log.setup)
clean.module("NAVex", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Geometry, Renderer = _SDK.ObjectManager, _SDK.EventManager, _SDK.Input, _SDK.Enums, _SDK.Game, _SDK.Geometry, _SDK.Renderer
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player
local Prediction = _G.Libs.Prediction
local Orbwalker = _G.Libs.Orbwalker
local Spell, HealthPred = _G.Libs.Spell, _G.Libs.HealthPred
local DamageLib = _G.Libs.DamageLib

TS = _G.Libs.TargetSelector(Orbwalker.Menu)

-- NewMenu
local Menu = _G.Libs.NewMenu

function NAVexMenu()
	Menu.NewTree("NAVexCombo", "Combo", function ()
		Menu.Checkbox("Combo.CastQ","Cast Q",true)
		Menu.Slider("Combo.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastW","Cast W",true)
		Menu.Slider("Combo.CastWMR", "W Min. Range", 400, 200, 550, 10)
		Menu.Slider("Combo.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Slider("Combo.CastRHC", "R Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastRUnderTurret","Cast R only if target not Under Turret",true)
		Menu.Checkbox("Combo.CastRLowHP","Cast R only if target % HP",true)
		Menu.Slider("Combo.CastRPercHP", "Cast R Missing Target % HP", 38, 0, 100, 1)
		Menu.Checkbox("Combo.CastR2","Cast R2 for GapClose",true)
	end)
	Menu.NewTree("NAVexHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastQ","Cast Q",true)
		Menu.Slider("Harass.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastW","Cast W",true)
		Menu.Slider("Harass.CastWMR", "W Min. Range", 475, 200, 550, 10)
		Menu.Slider("Harass.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastE","Cast E",true)
		Menu.Slider("Harass.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAVexWave", "Waveclear", function ()
		Menu.ColoredText("Wave", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQ","Cast Q for Killable CS",true)
		Menu.Slider("Waveclear.CastQHC", "Q Min. Killable Count",  1, 0, 10, 1)
		Menu.Slider("Waveclear.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQJg","Cast Q",true)
		Menu.Slider("Waveclear.CastQHCJg", "Q Min. Hit Count",  1, 0, 10, 1)
		Menu.Slider("Waveclear.CastQMinManaJg", "Q % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAVexMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastWGap","Auto-Cast W on GapClose",true)
	end)
	Menu.NewTree("NAVexDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawW","Draw W Range",true)
		Menu.ColorPicker("Drawing.DrawWColor", "Draw W Color", 0x06D6A0FF)
		Menu.Checkbox("Drawing.DrawE","Draw E Range",true)
		Menu.ColorPicker("Drawing.DrawEColor", "Draw E Color", 0x118AB2FF)
		Menu.Checkbox("Drawing.DrawR","Draw R Range",true)
		Menu.ColorPicker("Drawing.DrawRColor", "Draw R Color", 0xFFD166FF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
	end)
end

Menu.RegisterMenu("NAVex","NAVex",NAVexMenu)

-- Global vars
local spells = {
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 600,
		Speed = 600,
		Radius = 180,
		Delay = 0.15,
		Collisions = { WindWall = true },
		Type = "Linear",
	}),
	Q2 = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 1200,
		Speed = 3200,
		Radius = 80,
		Delay = 0.55,
		Collisions = { WindWall = true },
		Type = "Linear",
	}),
	W = Spell.Active({
		Slot = Enums.SpellSlots.W,
		Delay = 0.25,
		Speed = math.huge,
		Radius = 475,
		EffectRadius = 550,
		Type = "Circular",
	}),
	E = Spell.Skillshot({
		Slot = Enums.SpellSlots.E,
		Delay = 0.25,
		Speed = 1300,
		Range = 800,
		Radius = 200,
		EffectRadius = 300,
		Type = "Circular",
	}),
	R = Spell.Skillshot({
		Slot = Enums.SpellSlots.R,
		Delay = 0.25,
		Speed = 1600,
		Range = 2000, -- 2000 / 2500 / 3000
		Radius = 130,
		EffectRadius = 650,
		Type = "Linear",
	}),
	R2 = Spell.Active({
		Slot = Enums.SpellSlots.R,
		Delay = 0,
		Speed = math.huge,
		Range = math.huge,
	}),
}

local function ValidMinion(minion)
	return minion and minion.IsTargetable and minion.MaxHealth > 6 -- check if not plant or shroom
end

local function ValidTarget(target)
	return target and target.IsTargetable and target.MaxHealth > 6 -- check if not plant or shroom
end

local function GameIsAvailable()
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function IsTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
			or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function IsUltimateActive()
	return Player:GetSpell(SpellSlots.R).Name == "VexR2"
end

local function HasPerkDarkHarvest()
	return Player:HasPerk(Enums.PerkIDs.DarkHarvest)
end

local function HasPerkCoupdeGrace()
	return Player:HasPerk(Enums.PerkIDs.CoupdeGrace)
end

local function CountHarvestSouls()
	local harvestBuff = Player:GetBuff("ASSETS/Perks/Styles/Domination/DarkHarvest/DarkHarvest.lua")
	if harvestBuff then
		return harvestBuff.Count
	end
	return 0
end

local function CountEnemiesInRange(range)

	local count = 0

	local enemies = ObjManager.Get("enemy", "heroes")
	local myPos = Player.Position

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero then
			local dist = myPos:Distance(hero.Position)
			if dist <= range then
				count = count + 1
			end
		end
	end

	return count
end

local function IsTargetUnderTurret(target)
	local turrets = ObjManager.GetNearby("enemy", "turrets")

	local turretRange = 900
	local targetPos = target.Position

	for _, obj in ipairs(turrets) do
		local turret = obj.AsTurret
		local dist = targetPos:Distance(turret)

		if turret and turret.IsValid and not turret.IsDead
				and dist <= turretRange + target.BoundingRadius then
			return true
		end
	end

	return false
end

local function UpdateRRange()
	spells.R.Range = 1500 + 500 * Player:GetSpell(SpellSlots.R).Level
end

local function GetQDmg(target)
	local playerAI = Player.AsAI
	local dmgQ = 10 + 40 * Player:GetSpell(SpellSlots.Q).Level
	local bonusDmg = (115 + (15 * Player:GetSpell(SpellSlots.Q).Level)) / 100 * playerAI.TotalAD
	local totalDmg = dmgQ + bonusDmg

	if HasPerkDarkHarvest() and target.HealthPercent < 0.5 then
		-- 50% of their maximum health deal 20 − 60 (based on level) (+ 5 per Soul) (+ 25% bonus AD) (+ 15% AP)
		local playerLvl = Player.Level - 1
		local bonusHarvestDmg = 0.25 * playerAI.BonusAD + 0.15 * playerAI.TotalAP
		local bonusSoulDmg = 5 * CountHarvestSouls()

		if playerLvl > 0 then
			totalDmg = totalDmg + (20 + 40 / (17 * playerLvl)) + bonusSoulDmg + bonusHarvestDmg
		else
			totalDmg = totalDmg + 20 + bonusSoulDmg + bonusHarvestDmg
		end
	end

	if HasPerkCoupdeGrace() and target.HealthPercent < 0.4 then
		totalDmg = totalDmg + (totalDmg * 0.08)
	end

	return DamageLib.CalculatePhysicalDamage(Player, target, totalDmg)
end

local function GetEDmg(target)
	local playerAI = Player.AsAI
	local dmgE = 30 + 40 * Player:GetSpell(SpellSlots.E).Level
	local bonusDmg = 0.8 * playerAI.TotalAP
	local totalDmg = dmgE + bonusDmg
	return DamageLib.CalculateMagicalDamage(Player, target, totalDmg)
end

local function GetRDmg(target)
	local playerAI = Player.AsAI
	local dmgR = 75 + 225 * Player:GetSpell(SpellSlots.R).Level
	local bonusDmg = 2 * playerAI.BonusAD
	local totalDmg = dmgR + bonusDmg

	if HasPerkDarkHarvest() and target.HealthPercent < 0.5 then
		-- 50% of their maximum health deal 20 − 60 (based on level) (+ 5 per Soul) (+ 25% bonus AD) (+ 15% AP)
		local playerLvl = Player.Level - 1
		local bonusHarvestDmg = 0.25 * playerAI.BonusAD + 0.15 * playerAI.TotalAP
		local bonusSoulDmg = 5 * CountHarvestSouls()

		if playerLvl > 0 then
			totalDmg = totalDmg + (20 + 40 / (17 * playerLvl)) + bonusSoulDmg + bonusHarvestDmg
		else
			totalDmg = totalDmg + 20 + bonusSoulDmg + bonusHarvestDmg
		end
	end

	if HasPerkCoupdeGrace() and target.HealthPercent < 0.4 then
		totalDmg = totalDmg + (totalDmg * 0.08)
	end

	return DamageLib.CalculatePhysicalDamage(Player, target, totalDmg)
end

local function GetDamage(target)
	local totalDmg = 0
	if spells.Q:IsReady() then
		totalDmg = totalDmg + GetQDmg(target)
	end
	if spells.E:IsReady() then
		totalDmg = totalDmg + GetEDmg(target)
	end
	if spells.R:IsReady() then
		totalDmg = totalDmg + GetRDmg(target)
	end

	return totalDmg
end

local function CastQ(target, hitChance)
	if spells.Q:IsReady() then
		if spells.Q:CastOnHitChance(target, hitChance) or
				spells.Q2:CastOnHitChance(target, hitChance) then
			return
		end
	end
end

local function CastW()
	if spells.W:IsReady() then
		if spells.W:Cast() then
			return
		end
	end
end

local function CastE(target, hitChance)
	if spells.E:IsReady() then
		if spells.E:CastOnHitChance(target, hitChance) then
			return
		end
	end
end

local function CastR(target, hitChance, useR2)
	if spells.R:IsReady() then
		if IsUltimateActive() and useR2 then
			if spells.R2:Cast()  then
				return
			end
		elseif not IsUltimateActive() then
			if spells.R:CastOnHitChance(target, hitChance)  then
				return
			end
		end
	end
end

local function Waveclear()

	if spells.Q:IsReady() then

		local pPos, pointsQ = Player.Position, {}
		local isJgCS = false

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			local minionDmgQ = GetQDmg(minion)
			local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
			if ValidMinion(minion) and minionDmgQ >= healthPred then
				local posQ = minion:FastPrediction(spells.Q.Delay)
				if posQ:Distance(pPos) < spells.Q.Range and minion.IsTargetable then
					table.insert(pointsQ, posQ)
				end
			end
		end

		-- Jungle Minions
		if #pointsQ == 0 then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					local posQ = minion:FastPrediction(spells.Q.Delay)
					if posQ:Distance(pPos) < spells.Q.Range and minion.IsTargetable then
						isJgCS = true
						table.insert(pointsQ, posQ)
					end
				end
			end
		end

		local castQMenu = nil
		local castQHCMenu = nil

		if not isJgCS then
			castQMenu = Menu.Get("Waveclear.CastQ")
			castQHCMenu = Menu.Get("Waveclear.CastQHC")
		else
			castQMenu = Menu.Get("Waveclear.CastQJg")
			castQHCMenu = Menu.Get("Waveclear.CastQHCJg")
		end

		local bestPosQ, hitCountQ = spells.Q:GetBestCircularCastPos(pointsQ)

		if bestPosQ and hitCountQ >= castQHCMenu
				and spells.Q:IsReady() and castQMenu then
			spells.Q:Cast(bestPosQ)
			return
		end

	end
end

local function OnHighPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

end

local function OnTick()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	-- Combo
	if Orbwalker.GetMode() == "Combo" then
		if Menu.Get("Combo.CastQ") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Q2.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.Q2.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Combo.CastQHC"))
				end
			end
		end
		if Menu.Get("Combo.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and target.Position:Distance(Player.Position) <= (Menu.Get("Combo.CastWMR") + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastWMinMana") / 100) * Player.MaxMana then
					CastW()
				end
			end
		end
		if Menu.Get("Combo.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastEMinMana") / 100) * Player.MaxMana then
					CastE(target,Menu.Get("Combo.CastEHC"))
					return
				end
			end
		end
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then
				-- Update R Range update
				UpdateRRange()

				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.R.Range + Player.BoundingRadius, true)

				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.R.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastEMinMana") / 100) * Player.MaxMana then

					-- Check if Target is UnderTurret Option
					if target and Menu.Get("Combo.CastRUnderTurret") and IsTargetUnderTurret(target) then
						return
					end

					-- Check if Target is % HP
					if target and Menu.Get("Combo.CastRLowHP") and target.HealthPercent > Menu.Get("Combo.CastRPercHP")/100 then
						return
					end

					CastR(target,Menu.Get("Combo.CastRHC"),Menu.Get("Combo.CastR2"))
					return
				end
			end
		end

	-- Waveclear
	elseif Orbwalker.GetMode() == "Waveclear" then

		Waveclear()

	-- Harass
	elseif Orbwalker.GetMode() == "Harass" then

		if Menu.Get("Harass.CastQ") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Q2.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.Q2.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQHC"))
				end
			end
		end
		if Menu.Get("Harass.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and target.Position:Distance(Player.Position) <= (Menu.Get("Harass.CastWMR") + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastWMinMana") / 100) * Player.MaxMana then
					CastW()
				end
			end
		end
		if Menu.Get("Harass.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastEMinMana") / 100) * Player.MaxMana then
					CastE(target,Menu.Get("Harass.CastEHC"))
					return
				end
			end
		end

	end

end

local function OnDraw()

	-- Draw Q Range
	if Player:GetSpell(SpellSlots.Q).IsLearned and Menu.Get("Drawing.DrawQ") then
		Renderer.DrawCircle3D(Player.Position, spells.Q2.Range, 30, 1.0, Menu.Get("Drawing.DrawQColor"))
	end
	-- Draw W Range
	if Player:GetSpell(SpellSlots.W).IsLearned and Menu.Get("Drawing.DrawW") then
		Renderer.DrawCircle3D(Player.Position, spells.W.Range, 30, 1.0, Menu.Get("Drawing.DrawWColor"))
	end
	-- Draw E Range
	if Player:GetSpell(SpellSlots.E).IsLearned and Menu.Get("Drawing.DrawE") then
		Renderer.DrawCircle3D(Player.Position, spells.E.Range, 30, 1.0, Menu.Get("Drawing.DrawEColor"))
	end
	-- Draw R Range
	if Player:GetSpell(SpellSlots.R).IsLearned and Menu.Get("Drawing.DrawR") then
		-- Update R Range update
		UpdateRRange()
		Renderer.DrawCircle3D(Player.Position, spells.R.Range, 30, 1.0, Menu.Get("Drawing.DrawRColor"))
	end

end

local function OnDrawDamage(target, dmgList)
	if Menu.Get("Drawing.DrawDamage") then
		table.insert(dmgList, GetDamage(target))
	end
end

local function OnGapclose(source, dash)
	if not source.IsEnemy then return end

	local paths = dash:GetPaths()
	local endPos = paths[#paths].EndPos
	local pPos = Player.Position
	local pDist = pPos:Distance(endPos)
	if pDist > 400 or pDist > pPos:Distance(dash.StartPos) or not source:IsFacing(pPos) then return end

	if Menu.Get("Misc.CastWGap") and spells.W:IsReady() then
		Input.Cast(SpellSlots.W)
	end
end

function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)

	return true
end
