if Player.CharName ~= "Aphelios" then return false end

module("NAAphelios", package.seeall, log.setup)
clean.module("NAAphelios", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Geometry, Renderer = _SDK.ObjectManager, _SDK.EventManager, _SDK.Input, _SDK.Enums, _SDK.Game, _SDK.Geometry, _SDK.Renderer
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player
local Prediction = _G.Libs.Prediction
local Orbwalker = _G.Libs.Orbwalker
local Spell, HealthPred = _G.Libs.Spell, _G.Libs.HealthPred
local DamageLib = _G.Libs.DamageLib

TS = _G.Libs.TargetSelector(Orbwalker.Menu)

--apheliospreload
--apheliospswapwarning

-- NewMenu
local Menu = _G.Libs.NewMenu

function NAApheliosMenu()
	Menu.NewTree("NAApheliosCombo", "Combo", function ()
		Menu.NewTree("NAApheliosComboQ", "Cast Q", function ()
			Menu.Checkbox("Combo.CastQCalibrum","Calibrum, The Sniper Rifle",true)
			Menu.Slider("Combo.CastQCalibrumHC", "Calibrum Hit Chance", 0.60, 0.05, 1, 0.05)
			Menu.Slider("Combo.CastQCalibrumMinMana", "Calibrum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Combo.CastQSeverum","Severum, The Scythe Pistol",true)
			Menu.Slider("Combo.CastQSeverumMinRange", "Severum Min. Range", 500, 200, 550, 10)
			Menu.Slider("Combo.CastQSeverumMinMana", "Severum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Combo.CastQGravitum","Gravitum, The Gravity Cannon",true)
			Menu.Slider("Combo.CastQGravitumMinMana", "Gravitum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Combo.CastQInfernum","Infernum, The Flamethrower",true)
			Menu.Slider("Combo.CastQInfernumHC", "Infernum Hit Chance", 0.60, 0.05, 1, 0.05)
			Menu.Slider("Combo.CastQInfernumMinMana", "Infernum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Combo.CastQCrescendum","Crescendum, The Chakram",true)
			Menu.Slider("Combo.CastQCrescendumMR", "Crescendum Min. Range", 450, 200, 475, 5)
			Menu.Slider("Combo.CastQCrescendumMinMana", "Crescendum % Min. Mana", 0, 1, 100, 1)
		end)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Slider("Combo.CastREnemies", "R Min. Enemies Hit", 2, 1, 5, 1)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 0, 1, 100, 1)
		Menu.Separator()
		Menu.Checkbox("Combo.CastRSeverum","Cast R Severum on X enemies when % HP (lifesteal)",true)
		Menu.Slider("Combo.CastRSeverumEnemies", "R Severum X Hit Enemies", 1, 1, 5, 1)
		Menu.Slider("Combo.CastRSeverumHP", "R Severum % HP ", 35, 1, 100, 1)
		Menu.Separator()
		Menu.Checkbox("Combo.UseGaleforce","Use Galeforce on Missing Target % HP",true)
		Menu.Slider("Combo.UseGaleforcePerc", "Galeforce Missing Target %", 38, 0, 50, 1)
	end)
	Menu.NewTree("NAApheliosHarass", "Harass", function ()
		Menu.NewTree("NAApheliosHarassQ", "Cast Q", function ()
			Menu.Checkbox("Harass.CastQCalibrum","Calibrum, The Sniper Rifle",true)
			Menu.Slider("Harass.CastQCalibrumHC", "Calibrum Hit Chance", 0.60, 0.05, 1, 0.05)
			Menu.Slider("Harass.CastQCalibrumMinMana", "Calibrum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Harass.CastQSeverum","Severum, The Scythe Pistol",true)
			Menu.Slider("Harass.CastQSeverumMinRange", "Severum Min. Range", 500, 200, 550, 10)
			Menu.Slider("Harass.CastQSeverumMinMana", "Severum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Harass.CastQGravitum","Gravitum, The Gravity Cannon",true)
			Menu.Slider("Harass.CastQGravitumMinMana", "Gravitum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Harass.CastQInfernum","Infernum, The Flamethrower",true)
			Menu.Slider("Harass.CastQInfernumHC", "Infernum Hit Chance", 0.60, 0.05, 1, 0.05)
			Menu.Slider("Harass.CastQInfernumMinMana", "Infernum % Min. Mana", 0, 1, 100, 1)
			Menu.Checkbox("Harass.CastQCrescendum","Crescendum, The Chakram",true)
			Menu.Slider("Harass.CastQCrescendumMR", "Crescendum Hit Chance", 0.60, 0.05, 1, 0.05)
			Menu.Slider("Harass.CastQCrescendumMinMana", "Crescendum % Min. Mana", 0, 1, 100, 1)
		end)
	end)
	Menu.NewTree("NAApheliosWave", "Waveclear", function ()
		Menu.ColoredText("Wave", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQ","Cast Q Infernum for Killable CS",true)
		Menu.Slider("Waveclear.CastQHC", "Q Infernum Min. Killable Count",  1, 0, 10, 1)
		Menu.Slider("Waveclear.CastQMinMana", "Q Infernum % Min. Mana", 0, 1, 100, 1)
		Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQJg","Cast Q Infernum",true)
		Menu.Slider("Waveclear.CastQHCJg", "Q Infernum Min. Hit Count",  1, 0, 10, 1)
		Menu.Slider("Waveclear.CastQMinManaJg", "Q Infernum % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAApheliosMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastQGravitumGap","Auto-Cast Q Gravitum on GapClose",true)
		Menu.Checkbox("Misc.CastQGravitumAARange","Auto-Cast Q Gravitum on Target out of AA",true)
		Menu.Checkbox("Misc.CastQCrescendumGap","Auto-Cast Q Crescendum on GapClose",true)
		Menu.Checkbox("Misc.ForceAACalibrum","Force AA on Calibrum Enemy",true)
		Menu.Checkbox("Misc.SwitchSeverum","Auto-Switch Severum on % HP",true)
		Menu.Slider("Misc.SwitchSeverumHP", "Switch Severum % HP ", 35, 1, 100, 1)
		Menu.Checkbox("Misc.CastRKS","Auto-Cast R for KillSteal",true)
		Menu.Slider("Misc.CastRKSHC", "R KillSteal Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Separator()
		Menu.Checkbox("Misc.AutoSwitchWeapon","Auto-Switch Weapon on Q CD",true)
		Menu.Checkbox("Misc.AutoSwitchCrescendum","Auto-Switch Weapon to Crescendum on close range",true)
		Menu.Slider("Misc.AutoSwitchCrescendumRange", "Crescendum Close Range", 300, 100, 550, 10)
	end)
	Menu.NewTree("NAApheliosDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawR","Draw R Range",true)
		Menu.ColorPicker("Drawing.DrawRColor", "Draw R Color", 0xFFD166FF)
		Menu.Checkbox("Drawing.DrawWeapons","Draw Weapons",true)
		Menu.ColorPicker("Drawing.DrawWeaponsColor", "Draw Weapons Color", 0xFFD166FF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
	end)
end

Menu.RegisterMenu("NAAphelios","NAAphelios",NAApheliosMenu)

-- Aphelios Weapons
local Weapons = {
	NONE = 0,
	CALIBRUM = 1,
	SEVERUM = 2,
	GRAVITUM = 3,
	INFERNUM = 4,
	CRESCENDUM = 5,
}

-- Global vars
local spells = {
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
	}),
	QCalibrum = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 1450,
		Speed = 1850,
		Radius = 70,
		Delay = 0.4,
		Collisions = { WindWall = true, Minions = true },
		Type = "Linear",
		LastUse = 0,
		CoolDown = 0,
	}),
	QSeverum = Spell.Active({
		Slot = Enums.SpellSlots.Q,
		Range = 550,
		EffectRadius = 550,
		Delay = 0.1,
		LastUse = 0,
		CoolDown = 0,
	}),
	QGravitum = Spell.Active({
		Slot = Enums.SpellSlots.Q,
		Range = math.huge,
		Delay = 0.3,
		LastUse = 0,
		CoolDown = 0,
	}),
	QInfernum = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 650,
		Speed = 3000,
		Radius = 100,
		ConeAngleRad = 70,
		Delay = 0.4,
		--Collisions = { WindWall = true, Minions = true },
		Type = "Cone",
		LastUse = 0,
		CoolDown = 0,
	}),
	QCrescendum = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 475,
		Delay = 0.25,
		EffectRadius = 500,
		Collisions = { WindWall = true},
		Type = "Linear",
		LastUse = 0,
		CoolDown = 0,
	}),
	W = Spell.Active({
		Slot = Enums.SpellSlots.W,
		Delay = 0.25,
	}),
	R = Spell.Skillshot({
		Slot = Enums.SpellSlots.R,
		Delay = 0.6,
		Speed = 2000,
		Range = 1300,
		Radius = 200,
		EffectRadius = 350,
		Type = "Linear",
	}),
}

local lastTick = 0;
local weapon = 0;
local offHandWeapon = 0;

local function ValidMinion(minion)
	return minion and minion.IsTargetable and minion.MaxHealth > 6 and minion.IsMinion
end

local function ValidTarget(target)
	return target and target.IsTargetable and target.MaxHealth > 6  and target.IsHero
end

local function GameIsAvailable()
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function IsTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
		or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function SetWeapons()
	-- Main Weapon
	if Player:GetBuff("ApheliosCalibrumManager") then
		weapon = Weapons.CALIBRUM
	elseif Player:GetBuff("ApheliosSeverumManager") then
		weapon = Weapons.SEVERUM
	elseif Player:GetBuff("ApheliosGravitumManager") then
		weapon = Weapons.GRAVITUM
	elseif Player:GetBuff("ApheliosInfernumManager") then
		weapon = Weapons.INFERNUM
	elseif Player:GetBuff("ApheliosCrescendumManager") then
		weapon = Weapons.CRESCENDUM
	end
	-- OffHand Weapon
	if Player:GetBuff("ApheliosOffHandBuffCalibrum") then
		offHandWeapon = Weapons.CALIBRUM
	elseif Player:GetBuff("ApheliosOffHandBuffSeverum") then
		offHandWeapon = Weapons.SEVERUM
	elseif Player:GetBuff("ApheliosOffHandBuffGravitum") then
		offHandWeapon = Weapons.GRAVITUM
	elseif Player:GetBuff("ApheliosOffHandBuffInfernum") then
		offHandWeapon = Weapons.INFERNUM
	elseif Player:GetBuff("ApheliosOffHandBuffCrescendum") then
		offHandWeapon = Weapons.CRESCENDUM
	end
end

local function HasCalibrumBuff(target)

	if target:GetBuff("aphelioscalibrumbonusrangedebuff") then
		return true
	end

	return false
end

local function HasGravitumBuff(target)

	if target:GetBuff("ApheliosGravitumDebuff") then
		return true
	end

	return false
end

local function WeaponToText(weapon)
	if weapon == Weapons.CALIBRUM then
		return "Calibrum"
	elseif weapon == Weapons.SEVERUM then
		return "Severum"
	elseif weapon == Weapons.GRAVITUM then
		return "Gravitum"
	elseif weapon == Weapons.INFERNUM then
		return "Infernum"
	elseif weapon == Weapons.CRESCENDUM then
		return "Crescendum"
	end
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

--todo
local function GetQDmg(target)
	local playerAI = Player.AsAI
	--local dmgQ = 10 + 40 * Player:GetSpell(SpellSlots.Q).Level
	--local bonusDmg = (115 + (15 * Player:GetSpell(SpellSlots.Q).Level)) / 100 * playerAI.TotalAD
	--local totalDmg = dmgQ + bonusDmg
	local totalDmg = 0

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

local function GetRDmg(target)
	local playerAI = Player.AsAI
	local dmgR = 75 + 50 * Player:GetSpell(SpellSlots.R).Level
	local bonusDmg = 0.2 * playerAI.BonusAD + playerAI.TotalAP
	local totalDmg = dmgR + bonusDmg

	if weapon == Weapons.CALIBRUM and HasCalibrumBuff(target) then
		totalDmg = totalDmg + (20 + 30 * Player:GetSpell(SpellSlots.R).Level)
	elseif weapon == Weapons.INFERNUM then
		totalDmg = totalDmg + (50 * Player:GetSpell(SpellSlots.R).Level + 0.25 * playerAI.BonusAD)
	end

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
	if spells.R:IsReady() then
		totalDmg = totalDmg + GetRDmg(target)
	end

	return totalDmg
end

local function CastQ(target, hitChance)
	if spells.Q:IsReady() then
		if weapon == Weapons.CALIBRUM then
			if spells.QCalibrum:CastOnHitChance(target, hitChance) then
				return
			end
		elseif weapon == Weapons.SEVERUM then
			if spells.QSeverum:Cast() then
				return
			end
		elseif weapon == Weapons.GRAVITUM then
			if spells.QGravitum:Cast() then
				return
			end
		elseif weapon == Weapons.INFERNUM then
			if spells.QInfernum:CastOnHitChance(target, hitChance) then
				return
			end
		elseif weapon == Weapons.CRESCENDUM and target and ValidTarget(target) then
			local targetAI = target.AsAI
			if targetAI then
				local targetPos = targetAI:FastPrediction(spells.QCrescendum.Delay)
				local predPos = Player.Position:Extended(targetPos,spells.QCrescendum.Range)
				local dist = predPos:Distance(targetPos)
				if dist <= hitChance and spells.QCrescendum:Cast(predPos) then
					return
				end
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

local function CastR(target, hitChance)
	if spells.R:IsReady() then
		if spells.R:CastOnHitChance(target,hitChance)  then
			return
		end
	end
end

local function CastRCombo()
	if not spells.R:IsReady() then return end

	local pointsEnemies = {}
	local myPos = Player.Position
	local enemies, rRange = ObjManager.GetNearby("enemy", "heroes"), (spells.R.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local posEnemy = hero:FastPrediction(spells.R.Delay)
			local dist = myPos:Distance(hero.Position)
			if dist <= rRange then
				table.insert(pointsEnemies, posEnemy)
			end
		end
	end

	local bestPosCombo, hitCountCombo = Geometry.BestCoveringRectangle(pointsEnemies, myPos, spells.R.EffectRadius)

	if bestPosCombo and hitCountCombo >= Menu.Get("Combo.CastREnemies") then
		spells.R:Cast(bestPosCombo)
	end

end

local function SwitchWeapon(weapon)
	if weapon == offHandWeapon then
		CastW()
		return true
	end

	return false
end

local function AutoSwitchWeapon ()
	local timeLeftQ = 0
	local cooldown = 0
	local lastUse = 0

	if offHandWeapon == Weapons.CALIBRUM then
		lastUse = spells.QCalibrum.LastUse
		cooldown = spells.QCalibrum.CoolDown
	elseif offHandWeapon == Weapons.SEVERUM then
		lastUse = spells.QSeverum.LastUse
		cooldown = spells.QSeverum.CoolDown
	elseif offHandWeapon == Weapons.GRAVITUM then
		lastUse = spells.QGravitum.LastUse
		cooldown = spells.QGravitum.CoolDown
	elseif offHandWeapon == Weapons.INFERNUM then
		lastUse = spells.QInfernum.LastUse
		cooldown = spells.QInfernum.CoolDown
	elseif offHandWeapon == Weapons.CRESCENDUM then
		lastUse = spells.QCrescendum.LastUse
		cooldown = spells.QCrescendum.CoolDown
	end


	timeLeftQ = Game.GetTime() - (lastUse + cooldown)

	if timeLeftQ >= 0 then
		if SwitchWeapon(offHandWeapon) then
			return
		end
	end
end

local function CastRSeverum()
	if not spells.R:IsReady() then return end

	local pointsEnemies = {}
	local myPos = Player.Position
	local enemies, rRange = ObjManager.GetNearby("enemy", "heroes"), (spells.R.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local posEnemy = hero:FastPrediction(spells.R.Delay)
			local dist = myPos:Distance(hero.Position)
			if dist <= rRange then
				table.insert(pointsEnemies, posEnemy)
			end
		end
	end
	
	local bestPosSev, hitCountSev = Geometry.BestCoveringRectangle(pointsEnemies, myPos, spells.R.EffectRadius)
	
	if bestPosSev and hitCountSev >= Menu.Get("Combo.CastRSeverumEnemies") then
		if weapon ~= Weapons.SEVERUM and offHandWeapon == Weapons.SEVERUM then
			if SwitchWeapon(Weapons.SEVERUM) then
				spells.R:Cast(bestPosSev)
				return
			end
		else
			if weapon == Weapons.SEVERUM then
				spells.R:Cast(bestPosSev)
				return
			end
		end
	end
	
end

local function AutoRKS(hitChance)
	if not spells.R:IsReady() then return end

	local enemies, rRange = ObjManager.Get("enemy", "heroes"), (spells.R.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = Player.Position:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.R.Delay)

			local aaRange = Orbwalker.GetTrueAutoAttackRange(Player,hero)
			local aaDmg = DamageLib.GetAutoAttackDamage(Player,hero,true)

			if dist > aaRange and aaDmg < healthPred and GetRDmg(hero) >= healthPred and dist <= rRange then
				CastR(hero, hitChance) -- R KS
			end
		end
	end
end

local function ForceAACalibrum()

	local enemies = ObjManager.Get("enemy", "heroes")
	local myPos = Player.Position

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero then
			local dist = myPos:Distance(hero.Position)
			if dist <= spells.QCalibrum.Range and HasCalibrumBuff(hero) then
				Orbwalker.Attack(hero.Position)
			end
		end
	end

end

local function AutoQGravitumAARange()

	if not spells.Q:IsReady() and (offHandWeapon ~= Weapons.GRAVITUM and weapon ~= Weapons.GRAVITUM) then return end

	local enemies, aaRange = ObjManager.GetNearby("enemy", "heroes"), (Player.AttackRange + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = Player.Position:Distance(hero.Position)

			if dist > aaRange and HasGravitumBuff(hero) then
				if weapon == Weapons.GRAVITUM then
					CastQ()
				elseif offHandWeapon == Weapons.GRAVITUM then
					if SwitchWeapon(Weapons.GRAVITUM) then
						CastQ()
					end
				end
			end
		end
	end
end

local function AutoSwitchCrescendum()

	local enemies, menuRange = ObjManager.GetNearby("enemy", "heroes"), Menu.Get("Misc.AutoSwitchCrescendumRange")

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = Player.Position:Distance(hero.Position)

			if dist <= menuRange then
				if offHandWeapon == Weapons.CRESCENDUM then
					SwitchWeapon(Weapons.CRESCENDUM)
				end
			end
		end
	end

end

local function Waveclear()

	if spells.Q:IsReady() and weapon == Weapons.INFERNUM then

		local pPos, pointsQ = Player.Position, {}
		local isJgCS = false

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				local posQ = minion:FastPrediction(spells.QInfernum.Delay)
				if posQ:Distance(pPos) < spells.QInfernum.Range and minion.IsTargetable then
					table.insert(pointsQ, posQ)
				end
			end
		end

		-- Jungle Minions
		if #pointsQ == 0 then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					local posQ = minion:FastPrediction(spells.QInfernum.Delay)
					if posQ:Distance(pPos) < spells.QInfernum.Range and minion.IsTargetable then
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

		local bestPosQ, hitCountQ = Geometry.BestCoveringCone(pointsQ, pPos, spells.QInfernum.ConeAngleRad)

		if bestPosQ and hitCountQ >= castQHCMenu
				and spells.QInfernum:IsReady() and castQMenu then
			spells.QInfernum:Cast(bestPosQ)
			return
		end

	end
end

local function OnHighPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	if Menu.Get("Misc.CastRKS") then
		AutoRKS(Menu.Get("Misc.CastRKSHC"))
	end
	if Menu.Get("Misc.ForceAACalibrum") then
		ForceAACalibrum()
	end
	if Menu.Get("Misc.CastQGravitumAARange") then
		AutoQGravitumAARange()
	end
	if Menu.Get("Misc.SwitchSeverum") and weapon ~= Weapons.SEVERUM 
		and Player.HealthPercent <= Menu.Get("Misc.SwitchSeverumHP") / 100 then
		if SwitchWeapon(Weapons.SEVERUM) then
			return
		end
	end

	-- Auto-Switch Weapon
	if Menu.Get("Misc.AutoSwitchWeapon") then
		-- IsLearned not working apparently, using level then
		--spells.Q:GetState() == SpellStates.Disabled -- to be fixed, wrong val

		if Player.Level > 1 and (not (spells.Q:GetState() == 520) and not (spells.Q:GetState() == SpellStates.Ready))
				and spells.Q:GetManaCost() <= Player.Mana then
			AutoSwitchWeapon()
		end
	end
	-- Auto-Switch Crescendum Close Range
	if Menu.Get("Misc.AutoSwitchCrescendum") then
		if offHandWeapon == Weapons.CRESCENDUM then
			AutoSwitchCrescendum()
		end
	end

end

local function OnTick()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	-- Combo
	if Orbwalker.GetMode() == "Combo" then

		if Menu.Get("Combo.CastRSeverum") and (weapon == Weapons.SEVERUM or offHandWeapon == Weapons.SEVERUM) then
			if spells.R:IsReady() then
				if Player.Health <= (Menu.Get("Combo.CastRSeverumHP") / 100) * Player.MaxHealth then
					CastRSeverum()
				end
			end
		end

		if Menu.Get("Combo.CastQCalibrum") and weapon == Weapons.CALIBRUM then
			if spells.QCalibrum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QCalibrum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and not HasCalibrumBuff(target)
						and target.Position:Distance(Player.Position) <= (spells.QCalibrum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQCalibrumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Combo.CastQCalibrumHC"))
				end
			end
		end
		if Menu.Get("Combo.CastQSeverum") and weapon == Weapons.SEVERUM then
			if spells.QSeverum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QSeverum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and target.Position:Distance(Player.Position) <= (Menu.Get("Combo.CastQSeverumMinRange") + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQSeverumMinMana") / 100) * Player.MaxMana then
					CastQ()
				end
			end
		end
		if Menu.Get("Combo.CastQGravitum") and weapon == Weapons.GRAVITUM then
			if spells.QGravitum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QGravitum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and HasGravitumBuff(target)
						and target.Position:Distance(Player.Position) <= (spells.QGravitum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQGravitumMinMana") / 100) * Player.MaxMana then
					CastQ()
				end
			end
		end
		if Menu.Get("Combo.CastQInfernum") and weapon == Weapons.INFERNUM then
			if spells.QInfernum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QInfernum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.QInfernum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQInfernumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Combo.CastQInfernumHC"))
				end
			end
		end
		if Menu.Get("Combo.CastQCrescendum") and weapon == Weapons.CRESCENDUM then
			if spells.QCrescendum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QCrescendum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.QCrescendum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastQCrescendumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Combo.CastQCrescendumMR"))
				end
			end
		end
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then
				if Player.Mana >= (Menu.Get("Combo.CastRMinMana") / 100) * Player.MaxMana then
					CastRCombo()
				end
			end
		end
		if Menu.Get("Combo.UseGaleforce") then
			local target = Orbwalker.GetTarget() or TS:GetTarget(425 + 750, true)
			if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (425 + 750) and
					target.HealthPercent <= Menu.Get("Combo.UseGaleforcePerc")/100  then
				UseGaleforce(target)
			end
		end
		-- Waveclear
	elseif Orbwalker.GetMode() == "Waveclear" then

		Waveclear()

		-- Harass
	elseif Orbwalker.GetMode() == "Harass" then

		if Menu.Get("Harass.CastQCalibrum") and weapon == Weapons.CALIBRUM then
			if spells.QCalibrum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QCalibrum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.QCalibrum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQCalibrumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQCalibrumHC"))
				end
			end
		end
		if Menu.Get("Harass.CastQSeverum") and weapon == Weapons.SEVERUM then
			if spells.QSeverum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QSeverum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and target.Position:Distance(Player.Position) <= (Menu.Get("Harass.CastQSeverumMinRange") + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQSeverumMinMana") / 100) * Player.MaxMana then
					CastQ()
				end
			end
		end
		if Menu.Get("Harass.CastQGravitum") and weapon == Weapons.GRAVITUM then
			if spells.QGravitum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QGravitum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target)
						and target.Position:Distance(Player.Position) <= (spells.QGravitum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQGravitumMinMana") / 100) * Player.MaxMana then
					CastQ()
				end
			end
		end
		if Menu.Get("Harass.CastQInfernum") and weapon == Weapons.INFERNUM then
			if spells.QInfernum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QInfernum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.QInfernum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQInfernumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQInfernumHC"))
				end
			end
		end
		if Menu.Get("Harass.CastQCrescendum") and weapon == Weapons.CRESCENDUM then
			if spells.QCrescendum:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.QCrescendum.Range + Player.BoundingRadius, true)
				if target and ValidTarget(target) and target.Position:Distance(Player.Position) <= (spells.QCrescendum.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastQCrescendumMinMana") / 100) * Player.MaxMana then
					CastQ(target, Menu.Get("Harass.CastQCrescendumMR"))
				end
			end
		end

	end

end

local function OnDraw()

	local qRange = 0

	if weapon == Weapons.CALIBRUM then
		qRange = spells.QCalibrum.Range
	elseif weapon == Weapons.SEVERUM then
		qRange = spells.QSeverum.Range
	elseif weapon == Weapons.GRAVITUM then
		qRange = spells.QGravitum.Range
	elseif weapon == Weapons.INFERNUM then
		qRange = spells.QInfernum.Range
	elseif weapon == Weapons.CRESCENDUM then
		qRange = spells.QCrescendum.Range
	end

	-- Draw Q Range
	if Player:GetSpell(SpellSlots.Q).IsLearned and Menu.Get("Drawing.DrawQ") then
		Renderer.DrawCircle3D(Player.Position, qRange, 30, 1.0, Menu.Get("Drawing.DrawQColor"))
	end
	-- Draw R Range
	if Player:GetSpell(SpellSlots.R).IsLearned and Menu.Get("Drawing.DrawR") then
		Renderer.DrawCircle3D(Player.Position, spells.R.Range, 30, 1.0, Menu.Get("Drawing.DrawRColor"))
	end
	-- Draw Weapons
	if Menu.Get("Drawing.DrawWeapons") and weapon ~= Weapons.NONE and offHandWeapon ~= Weapons.NONE then
		local textWeapon = "Weapon: " .. WeaponToText(weapon) .. " | OffHandWeapon: " .. WeaponToText(offHandWeapon)
		Renderer.DrawTextOnPlayer(textWeapon, Menu.Get("Drawing.DrawWeaponsColor"))
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

	if Menu.Get("Misc.CastQGravitumGap") and HasGravitumBuff(source) and spells.QGravitum:IsReady() then
		if weapon == Weapons.GRAVITUM then
			CastQ()
		elseif offHandWeapon == Weapons.GRAVITUM then
			if SwitchWeapon(Weapons.GRAVITUM) then
				CastQ()
			end
		end
	end
	if Menu.Get("Misc.CastQCrescendumGap") and spells.QCrescendum:IsReady() then
		if weapon == Weapons.CRESCENDUM then
			CastQ(endPos, Enums.HitChance.LOW)
		elseif offHandWeapon == Weapons.CRESCENDUM then
			if SwitchWeapon(Weapons.CRESCENDUM) then
				CastQ(endPos, Enums.HitChance.LOW)
			end
		end
	end
end

local function OnBuffGain(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name
		if buff then

			-- Main Weapon
			if buff == "ApheliosCalibrumManager" then
				weapon = Weapons.CALIBRUM
			elseif buff == "ApheliosSeverumManager" then
				weapon = Weapons.SEVERUM
			elseif buff == "ApheliosGravitumManager" then
				weapon = Weapons.GRAVITUM
			elseif buff == "ApheliosInfernumManager" then
				weapon = Weapons.INFERNUM
			elseif buff == "ApheliosCrescendumManager" then
				weapon = Weapons.CRESCENDUM
			end
			-- OffHand Weapon
			if buff == "ApheliosOffHandBuffCalibrum" then
				offHandWeapon = Weapons.CALIBRUM
			elseif buff == "ApheliosOffHandBuffSeverum" then
				offHandWeapon = Weapons.SEVERUM
			elseif buff == "ApheliosOffHandBuffGravitum" then
				offHandWeapon = Weapons.GRAVITUM
			elseif buff == "ApheliosOffHandBuffInfernum" then
				offHandWeapon = Weapons.INFERNUM
			elseif buff == "ApheliosOffHandBuffCrescendum" then
				offHandWeapon = Weapons.CRESCENDUM
			end

		end
	end
end

local function OnProcessSpell(sender, spell)
	if sender.IsMe then
		if not spell.IsBasicAttack then
			local spellName = spell.Name

			if spellName == "ApheliosCalibrumQ" then
				spells.QCalibrum.LastUse = Game.GetTime()
				spells.QCalibrum.CoolDown = Player:GetSpell(SpellSlots.Q).TotalCooldown
			elseif spellName == "ApheliosSeverumQ" then
				spells.QSeverum.LastUse = Game.GetTime()
				spells.QSeverum.CoolDown = Player:GetSpell(SpellSlots.Q).TotalCooldown
			elseif spellName == "ApheliosGravitumQ" then
				spells.QGravitum.LastUse = Game.GetTime()
				spells.QGravitum.CoolDown = Player:GetSpell(SpellSlots.Q).TotalCooldown
			elseif spellName == "ApheliosInfernumQ" then
				spells.QInfernum.LastUse = Game.GetTime()
				spells.QInfernum.CoolDown = Player:GetSpell(SpellSlots.Q).TotalCooldown
			elseif spellName == "ApheliosCrescendumQ" then
				spells.QCrescendum.LastUse = Game.GetTime()
				spells.QCrescendum.CoolDown = Player:GetSpell(SpellSlots.Q).TotalCooldown
				-- Weapon Switch Reset
			elseif spellName == "ApheliosW" then
					-- to be fixed by Thorn
					Orbwalker.ResetAttack()

			end
		end
	end
end

function OnLoad()

	if weapon == Weapons.NONE or offHandWeapon == Weapons.NONE then
		SetWeapons()
	end

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)
	EventManager.RegisterCallback(Enums.Events.OnBuffGain, OnBuffGain)
	EventManager.RegisterCallback(Enums.Events.OnProcessSpell, OnProcessSpell)

	return true
end
