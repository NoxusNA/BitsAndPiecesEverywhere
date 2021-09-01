if Player.CharName ~= "Caitlyn" then return false end

module("NACait", package.seeall, log.setup)
clean.module("NACait", clean.seeall, log.setup)

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

function NACaitMenu()
	Menu.NewTree("NACaitCombo", "Combo", function ()
		Menu.Checkbox("Combo.UseSmart","Use Smart Combo (W -> Q -> AA -> E -> AA",true)
		Menu.Separator()
		Menu.Checkbox("Combo.CastQ","Cast Q",true)
		Menu.Slider("Combo.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastW","Cast W",true)
		Menu.Slider("Combo.CastWMinTraps", "W Keep Min Traps", 2, 0, 4, 1)
		Menu.Slider("Combo.CastWHC", "W Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
		Menu.Separator()
		Menu.Checkbox("Combo.UseGaleforce","Use Galeforce on Missing Target % HP",true)
		Menu.Slider("Combo.UseGaleforcePerc", "Galeforce Missing Target %", 38, 0, 50, 1)
	end)
	Menu.NewTree("NACaitHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastQ","Cast Q",true)
		Menu.Slider("Harass.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastW","Cast W",true)
		Menu.Slider("Harass.CastWMinTraps", "W Keep Min Traps", 2, 0, 2, 1)
		Menu.Slider("Harass.CastWHC", "W Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastE","Cast E",true)
		Menu.Slider("Harass.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NACaitWave", "Waveclear", function ()
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
	Menu.NewTree("NACaitMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastQtrap","Auto-Cast Q on trap",true)
		Menu.Checkbox("Misc.CastWCC","Auto-Cast W on full CC",true)
		Menu.Checkbox("Misc.CastEGap","Auto-Cast E on GapClose",true)
		Menu.Checkbox("Misc.CastQKS","Auto-Cast Q Killable",true)
		Menu.Checkbox("Misc.CastRKS","Auto-Cast R Killable",true)
		Menu.Slider("Misc.CastRKSRange","R Killable No Enemies Close Range",1200, 100, 3500, 10)
		Menu.Checkbox("Misc.DuskNoAA","Disable AA on Dusk Stealth",true)
		Menu.Checkbox("Misc.AutoBlueWard","Auto-BlueWard for R",true)
		Menu.Separator()
		Menu.Keybind("Misc.AutoCS", "Auto LastHit CS Toggle", string.byte('O'), true, true)
		Menu.Keybind("Misc.AutoHarass", "Auto Harass Toggle", string.byte('T'), true, true)
	end)
	Menu.NewTree("NACaitDrawing", "Drawing", function ()
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

Menu.RegisterMenu("NACait","NACait",NACaitMenu)

-- Global vars
local spells = {
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 1300,
		Speed = 2200,
		Radius = 90,
		Delay = 0.625,
		Collisions = { WindWall = true },
		Type = "Linear",
	}),
	W = Spell.Skillshot({
		Slot = Enums.SpellSlots.W,
		Delay = 1.25,
		Speed = math.huge,
		Range = 800,
		Radius = 75,
		IsTrap = true,
		Type = "Circular",
	}),
	E = Spell.Skillshot({
		Slot = Enums.SpellSlots.E,
		Delay = 0.15,
		Speed = 1600,
		Range = 800,
		Radius = 70,
		Type = "Linear",
		Collisions = { Heroes = true, Minions = true, WindWall = true },
	}),
	R = Spell.Targeted({
		Slot = Enums.SpellSlots.R,
		Delay = 0.375,
		Speed = 3200,
		Range = 3500,
	}),
}

local lastTick = 0

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

local function IsTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
			or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function GetNumberTraps()
	return Player:GetSpell(SpellSlots.W).Ammo
end

local function IsTargetTrapped(target)

	if target:GetBuff("caitlynyordletrapdebuff") then
		return true
	end

	return false
end

local function HasHeadshot(target)

	if target:GetBuff("caitlynheadshotrangecheck") then
		return true
	end

	return false
end

local function IsCaitDuskStealth()

	if Player:GetBuff("6691stealth") then
		return true
	end

	return false
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

local function UseGaleforce(target)
	for i=SpellSlots.Item1, SpellSlots.Item6 do
		local _item = Player:GetSpell(i)
		if _item ~= nil and _item then
			local itemInfo = _item.Name

			if itemInfo == "6671Cast" then
				if Player:GetSpellState(i) == SpellStates.Ready then
					Input.Cast(i, target.Position)
				end
				return
			end
		end
	end
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
		if spells.Q:CastOnHitChance(target, hitChance) then
			return
		end
	end
end

local function CastW(target, hitChance)
	if spells.W:IsReady() then
		if spells.W:CastOnHitChance(target, hitChance) then
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

local function CastR(target)
	if spells.R:IsReady() then
		if spells.R:Cast(target)  then
			return
		end
	end
end

local function AutoQTrap()
	if not spells.Q:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, qRange = Player.Position, (spells.Q.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero then
			local dist = myPos:Distance(hero.Position)
			if dist <= qRange and IsTargetTrapped(hero) then
				CastQ(hero, Enums.HitChance.High) -- Q trap
			end
		end
	end

end

local function AutoWCC()
	if not spells.W:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, wRange = Player.Position, (spells.W.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero then
			local dist = myPos:Distance(hero.Position)
			if dist <= wRange and IsTargetCC(hero) then
				CastW(hero, Enums.HitChance.High) -- W trap
			end
		end
	end

end

local function AutoQKS()
	if not spells.Q:IsReady() then return end

	local enemies, qRange = ObjManager.GetNearby("enemy", "heroes"), (spells.Q.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = Player.Position:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.Q.Delay)
			if GetQDmg(hero) >= healthPred and dist <= qRange then
				CastQ(hero, Enums.HitChance.High) -- Q KS
			end
		end
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
			if GetRDmg(hero) >= healthPred and CountEnemiesInRange(range) == 0 and dist <= rRange then
				CastR(hero) -- R KS
			end
		end
	end
end

local function AutoCS()
	for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
		local minion = v.AsAI
		local healthPred = HealthPred.GetHealthPrediction(minion, 0.1)
		local dist = Player.Position:Distance(minion.Position)
		local trueRange = Player.AttackRange + Player.BoundingRadius

		if ValidMinion(minion) and Orbwalker.GetAutoAttackDamage(minion) >= healthPred
				and dist <= trueRange then
			Orbwalker.Attack(minion)
		end
	end
end

local function AutoHarass()
	Orbwalker.Orbwalk(nil,nil,"Harass")
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

	if Menu.Get("Misc.CastQtrap") then
		AutoQTrap()
	end
	if Menu.Get("Misc.CastWCC") then
		AutoWCC()
	end
	if Menu.Get("Misc.CastQKS") then
		AutoQKS()
	end
	if Menu.Get("Misc.CastRKS") then
		AutoRKS(Menu.Get("Misc.CastRKSRange"))
	end

end

local function OnTick()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	local gameTime = Game.GetTime()
	if gameTime < (lastTick + 0.25) then return end
	lastTick = gameTime

	-- Auto CS
	if Menu.Get("Misc.AutoCS") then
	--	if Menu.Get("Misc.AutoHarass") then
	--		Menu.Set("Misc.AutoHarass", false)
	--	end
		AutoCS()
	end

	-- Auto Harass
	if Menu.Get("Misc.AutoHarass") then
	--	if Menu.Get("Misc.AutoCS") then
	--		Menu.Set("Misc.AutoCS", false)
	--	end
		AutoHarass()
	end

	-- Combo
	if Orbwalker.GetMode() == "Combo" then

		if Menu.Get("Combo.UseSmart") then
			local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)

			if target and ValidTarget(target) then
				if spells.W:IsReady() and not IsTargetTrapped(target) then
					if target.Position:Distance(Player.Position) <= (spells.W.Range + Player.BoundingRadius) and
							GetNumberTraps() > Menu.Get("Combo.CastWMinTraps") then
						CastW(target, Menu.Get("Combo.CastWHC"))
					end
				end

				if spells.Q:IsReady() and IsTargetTrapped(target) and not Menu.Get("Misc.CastQtrap") then
					CastQ(target, Menu.Get("Combo.CastQHC"))
				end

				if spells.E:IsReady() and not HasHeadshot(target) and not spells.Q:IsReady() then
					if target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
						CastE(target,Menu.Get("Combo.CastEHC"))
					end
				end

				if Menu.Get("Combo.UseGaleforce") then
					if target.Position:Distance(Player.Position) <= (425 + 750) and
							target.HealthPercent <= (Menu.Get("Combo.UseGaleforcePerc") / 100)  then
						UseGaleforce(target)
					end
				end
			end

		else
			if Menu.Get("Combo.CastQ") then
				if spells.Q:IsReady() then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Q.Range + Player.BoundingRadius, true)
					if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.Q.Range + Player.BoundingRadius) then
						CastQ(target, Menu.Get("Combo.CastQHC"))
					end
				end
			end
			if Menu.Get("Combo.CastW") then
				if spells.W:IsReady() then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
					if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.W.Range + Player.BoundingRadius) and
							GetNumberTraps() > Menu.Get("Combo.CastWMinTraps") then
						CastW(target, Menu.Get("Combo.CastWHC"))
					end
				end
			end
			if Menu.Get("Combo.CastE") then
				if spells.E:IsReady() then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
					if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
						CastE(target,Menu.Get("Combo.CastEHC"))
						return
					end
				end
			end
			if Menu.Get("Combo.UseGaleforce") then
				local target = Orbwalker.GetTarget() or TS:GetTarget(425 + 750, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (425 + 750) and
						target.HealthPercent <= Menu.Get("Combo.UseGaleforcePerc")  then
					UseGaleforce(target)
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
				if target and target.Position:Distance(Player.Position) <= (spells.Q.Range + Player.BoundingRadius) then
					CastQ(target, Menu.Get("Harass.CastQHC"))
				end
			end
		end
		if Menu.Get("Harass.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.W.Range + Player.BoundingRadius) and
						GetNumberTraps() > Menu.Get("Harass.CastWMinTraps") then
					CastW(target, Menu.Get("Harass.CastWHC"))
				end
			end
		end
		if Menu.Get("Harass.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
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
		Renderer.DrawCircle3D(Player.Position, spells.Q.Range, 30, 1.0, Menu.Get("Drawing.DrawQColor"))
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

	if Menu.Get("Misc.CastEGap") and spells.E:IsReady() then
		Input.Cast(SpellSlots.E, endPos)
	end
end

local function OnPreAttack(args)
	if Menu.Get("Misc.DuskNoAA") then
		if IsCaitDuskStealth() then
			args.Process = nil
		end
	end
end

local function OnVisionLost(obj)
	if obj.IsEnemy and obj.IsHero then
		if Menu.Get("Misc.AutoBlueWard") then
			-- todo
		end
	end
end

function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)
	EventManager.RegisterCallback(Enums.Events.OnPreAttack, OnPreAttack)
	EventManager.RegisterCallback(Enums.Events.OnVisionLost, OnVisionLost)

	return true
end
