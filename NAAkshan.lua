if Player.CharName ~= "Akshan" then return false end

module("NAAkshan", package.seeall, log.setup)
clean.module("NAAkshan", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Geometry, Renderer = _SDK.ObjectManager, _SDK.EventManager, _SDK.Input, _SDK.Enums, _SDK.Game, _SDK.Geometry, _SDK.Renderer
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local CollisionLib = _G.Libs.CollisionLib
local Player = ObjManager.Player
local Prediction = _G.Libs.Prediction
local Orbwalker = _G.Libs.Orbwalker
local Spell, HealthPred = _G.Libs.Spell, _G.Libs.HealthPred
local DamageLib = _G.Libs.DamageLib

TS = _G.Libs.TargetSelector(Orbwalker.Menu)

--buffs
--akshanpassivemovementspeed
--AkshanPassiveDebuff

-- NewMenu
local Menu = _G.Libs.NewMenu

function NAAkshanMenu()
	Menu.NewTree("NAAkshanCombo", "Combo", function ()
		Menu.Checkbox("Combo.CastQ","Cast Q",true)
		Menu.Slider("Combo.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastW","Cast W",false)
		Menu.Slider("Combo.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastERange","Cast E If no Max Wall Range found", 600, 200, 750, 50)
		Menu.Slider("Combo.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAAkshanHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastQ","Cast Q",true)
		Menu.Checkbox("Harass.CastQMinion","Cast Q Check for Minions",true)
		Menu.Slider("Harass.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAAkshanWave", "Waveclear", function ()
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
	Menu.NewTree("NAAkshanMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastWRiver","Auto-Cast W in River",true)
		Menu.Checkbox("Misc.CastRKS","Auto-Cast R if Killable",true)
		Menu.Slider("Misc.CastRKSRange", "R Min. Distance from Enemies", 1000, 200, 1500, 50)
		Menu.Checkbox("Misc.CastEBuff","Cast E Only if Enemy Has Akshan Mark",true)
		Menu.Checkbox("Misc.UseMovSpeedPassive","Prioritize Movement Speed for Passive AA",true)
	end)
	Menu.NewTree("NAAkshanDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawE","Draw E Range",true)
		Menu.ColorPicker("Drawing.DrawEColor", "Draw E Color", 0x118AB2FF)
		Menu.Checkbox("Drawing.DrawR","Draw R Range",true)
		Menu.ColorPicker("Drawing.DrawRColor", "Draw R Color", 0xFFD166FF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
	end)
end

Menu.RegisterMenu("NAAkshan","NAAkshan",NAAkshanMenu)

-- Global vars
local spells = {
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 850,
		Speed = 1500,
		Radius = 120,
		Delay = 0.25,
		EffectRadius = 400,
		Collisions = { WindWall = true },
		Type = "Linear",
	}),
	QMinion = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 850,
		Speed = 1500,
		Radius = 120,
		Delay = 0.25,
		EffectRadius = 400,
		Collisions = { WindWall = true },
		MinionRange = 500,
		MinHitChance = 0.5,
		Type = "Linear",
	}),
	W = Spell.Active({
		Slot = Enums.SpellSlots.W,
		Delay = 0.5,
		Speed = math.huge,
	}),
	E = Spell.Skillshot({
		Slot = Enums.SpellSlots.E,
		Delay = 0.1,
		Speed = 2500,
		Range = 800,
		Type = "Circular",
	}),
	R = Spell.Targeted({
		Slot = Enums.SpellSlots.R,
		Delay = 0.25,
		Speed = 3200,
		Range = 2500,
		Radius = 120,
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
	return Player:GetSpell(SpellSlots.R).Name == "AkshanRCancel"
end

local function IsCamouflaged()
	return Player:GetBuff("AkshanW")
end

local function IsHooked()
	return Player:GetSpell(SpellSlots.E).Name == "AkshanE2"
end

local function IsSwinging()
	return Player:GetSpell(SpellSlots.E).Name == "AkshanE3"
end

local function HasAkshanPassiveMovementSpeed()
	return Player:GetBuff("akshanpassivemovementspeed")
end

local function HasAkshanPassiveDebuff(target)
	return target:GetBuff("AkshanPassiveDebuff")
end

local function BestWallForRange(eRange, targetPos)

	local eCircle = Geometry.Circle(Player.Position, eRange)
	local eCirclePoints = eCircle:GetPoints(20)
	local ePoints = {}

	for i,point in ipairs(eCirclePoints) do
		local dist = point:Distance(targetPos)
		if point:IsWall() and dist <= eRange then
			table.insert(ePoints, point)
		end
	end

	local ePos = nil
	for i,ePoint in ipairs(ePoints) do
		if ePos then
			local distEPos = ePos:Distance(targetPos)
			local dist = ePoint:Distance(targetPos)

			if dist < distEPos then
				ePos = ePoint
			end
		else
			ePos = ePoint
		end
	end

	if ePos then
		return ePos
	end

	return nil
end

local function BestWallForSwing(target)

	local targetPos = target.Position

	-- try first Max E Range
	local ePos = BestWallForRange(spells.E.Range, targetPos)

	if not ePos then
		-- try Custom Combo E Range
		ePos = BestWallForRange(Menu.Get("Combo.CastERange"), targetPos)
	end

	if ePos and ePos:Distance(targetPos) <= (Player.AttackRange + Player.BoundingRadius) then
		return ePos
	end
	return nil

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

local function IsTargetNearMinions(target, range)
	local minions = ObjManager.GetNearby("enemy", "minions")

	local targetPos = target.Position

	for _, obj in ipairs(minions) do
		local minion = obj.AsAI
		local dist = targetPos:Distance(minion)

		if minion and ValidMinion(minion)
				and dist <= range then
			return true
		end
	end

	return false
end

local function GetQDmg(target)
	local playerAI = Player.AsAI
	local dmgQ = -15 + 20 * Player:GetSpell(SpellSlots.Q).Level
	local bonusDmg = 0.8 * playerAI.TotalAD
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
	return 0 --todo
end

local function GetRDmg(target)
	local playerAI = Player.AsAI
	local dmgR = 15 + 5 * Player:GetSpell(SpellSlots.R).Level
	local bonusDmg = 0.10 * playerAI.TotalAD
	local totalDmg = (dmgR + bonusDmg) * (4 + 1 * Player:GetSpell(SpellSlots.R).Level)

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

local function CastQ(target, hitChance, minionCheck)
	if spells.Q:IsReady() then
		if minionCheck then
			spells.QMinion.Range = spells.Q.Range + spells.QMinion.MinionRange
			spells.QMinion.MinHitChance = hitChance
			local pred = Prediction.GetPredictedPosition(target,spells.QMinion,Player.Position)
			if pred then
				-- Thorn needs to fix
				--local countCol = pred.CollisionCount
				--local colObj = pred.CollisionObjects
				local predPos = pred.CastPosition
				--print("collisioncount: ",countCol )
				--print("colObjSize: ",table.getn(colObj) )
				local col = CollisionLib.SearchMinions(Player.Position, target.Position,
						spells.Q.Radius*2, spells.Q.Speed, spells.Q.Delay,10,"enemy",nil)
				if col then
					local colObj = col.Objects
					if colObj and table.getn(colObj) > 1 then
						for _, obj in pairs(colObj) do
							if obj.IsMinion and obj.IsEnemy then
								if spells.Q:Cast(predPos) then
									return
								end
							end
						end
					end
				end
			end
		else
			if spells.Q:CastOnHitChance(target, hitChance) then
				return
			end
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

local function CastE(target)
	if spells.E:IsReady() then
		if not IsHooked() and not IsSwinging() then
			local bestWall = BestWallForSwing(target)
			if bestWall and spells.E:Cast(bestWall) then
				return
			end
		elseif IsHooked() and not IsSwinging() then
			if Orbwalker.Move(target.Position) then
				return
			end
		end
	end
end

local function CastR(target)
	if spells.R:IsReady() and not IsUltimateActive() then
		if spells.R:Cast(target)  then
				return
		end
	end
end

local function AutoWRiver()
	if not spells.W:IsReady() then return end
	if Player.IsInRiver and not IsCamouflaged() then
		CastW()
	end
end

local function AutoRKS(range)
	if not spells.R:IsReady() then return end

	local enemies, rRange = ObjManager.Get("enemy", "heroes"), (spells.R.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = Player.Position:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.R.Delay)
			if GetRDmg(hero) >= healthPred and CountEnemiesInRange(range) == 0
					and not IsTargetUnderTurret(Player)
					and not IsTargetUnderTurret(hero)
					and dist <= rRange then
				CastR(hero) -- R KS
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
			local minionDmgQ = GetQDmg(minion) * 2
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

		local bestPosQ, hitCountQ = spells.Q:GetBestLinearCastPos(pointsQ)

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

	if Menu.Get("Misc.CastWRiver") then
		AutoWRiver()
	end
	if Menu.Get("Misc.CastRKS") then
		AutoRKS(Menu.Get("Misc.CastRKSRange"))
	end

end

local function OnTick()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	-- Check Akshan E status for Orbwalker
	if IsHooked() or IsSwinging() then
		Orbwalker.BlockMove(true)
		Orbwalker.BlockAttack(true)
	else
		Orbwalker.BlockMove(false)
		Orbwalker.BlockAttack(false)
	end

	-- Combo
	if Orbwalker.GetMode() == "Combo" then
		if Menu.Get("Combo.CastQ") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Q.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.Q.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Combo.CastQHC"))
				end
			end
		end
		if Menu.Get("Combo.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and Player.Mana >= (Menu.Get("Combo.CastWMinMana") / 100) * Player.MaxMana then
					CastW()
				end
			end
		end
		if Menu.Get("Combo.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.AttackRange + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and Player.Mana >= (Menu.Get("Combo.CastEMinMana") / 100) * Player.MaxMana then
					if Menu.Get("Misc.CastEBuff") then
						if HasAkshanPassiveDebuff(target) then
							CastE(target)
						end
					else
						CastE(target)
					end
				end
			end
		end
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then

				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.R.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.R.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastRMinMana") / 100) * Player.MaxMana then
					CastR(target)
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
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Q.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.Q.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQHC"), false)
				end
			end
		end

		if Menu.Get("Harass.CastQMinion") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or
						TS:GetTarget(spells.Q.Range + spells.QMinion.MinionRange + Player.BoundingRadius, true)
				if target and ValidTarget(target) and IsTargetNearMinions(target, spells.QMinion.MinionRange)
						and target.Position:Distance(Player.Position) <= (spells.Q.Range + spells.QMinion.MinionRange + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQHC"), true)
				end
			end
		end

	end

end

local function OnDraw()

	-- Draw Q Range
	if Player:GetSpell(SpellSlots.Q).IsLearned and Menu.Get("Drawing.DrawQ") then
		Renderer.DrawCircle3D(Player.Position, spells.Q.Range, 30, 1.0, Menu.Get("Drawing.DrawQColor"))
	end
	-- Draw E Range
	if Player:GetSpell(SpellSlots.E).IsLearned and Menu.Get("Drawing.DrawE") then
		Renderer.DrawCircle3D(Player.Position, spells.E.Range, 30, 1.0, Menu.Get("Drawing.DrawEColor"))
	end
	-- Draw R Range
	if Player:GetSpell(SpellSlots.R).IsLearned and Menu.Get("Drawing.DrawR") then
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

	--if Menu.Get("Misc.CastWGap") and spells.W:IsReady() then
	--	Input.Cast(SpellSlots.W)
	--end
end

local function OnBuffGain(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name
		if buff then
			--print("buffG: ", buff)
		end
	end
end

local function OnBuffLost(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name
		if buff then
			--print("buffL: ", buff)
		end
	end
end

local function OnPreAttack(args)
	if Menu.Get("Misc.UseMovSpeedPassive") and HasAkshanPassiveMovementSpeed() then
		args.Target = nil
	end
end

function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)
	EventManager.RegisterCallback(Enums.Events.OnBuffGain, OnBuffGain)
	EventManager.RegisterCallback(Enums.Events.OnBuffLost, OnBuffLost)
	EventManager.RegisterCallback(Enums.Events.OnPreAttack, OnPreAttack)

	return true
end
