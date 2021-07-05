if Player.CharName ~= "Gangplank" then return false end

module("NAGangplank", package.seeall, log.setup)
clean.module("NAGangplank", clean.seeall, log.setup)

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

function NAGangplankMenu()
	Menu.NewTree("NAGangplankCombo", "Combo", function ()
		Menu.Checkbox("Combo.CastQ","Cast Q",true)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastQBarrel","Cast Q on Barrel in Target Range",true)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastEMB", "E Min Barrels", 1, 1, 3, 1)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Slider("Combo.CastRHC", "R Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 0, 1, 100, 1)
		Menu.Slider("Combo.CastRMinHit", "R Min. Hit Enemies", 2, 1, 5, 1)
		Menu.Checkbox("Combo.CastIgnite", "Cast Ignite if Available", true)
	end)
	Menu.NewTree("NAGangplankHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastQ","Cast Q",true)
		Menu.Checkbox("Harass.CastQBarrel","Cast Q on Barrel in Target Range",true)
		Menu.Slider("Harass.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastE","Cast E",true)
		Menu.Slider("Harass.CastEHC", "E Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastEMB", "E Min Barrels", 1, 1, 3, 1)
	end)
	Menu.NewTree("NAGangplankWave", "Waveclear", function ()
		Menu.ColoredText("Wave", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQ","Cast Q",true)
		Menu.Slider("Waveclear.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Waveclear.CastE","Cast E",true)
		Menu.Slider("Waveclear.CastEHC", "E Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastEMB", "E Min Barrels", 1, 1, 3, 1)
		Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastQJg","Cast Q",true)
		Menu.Slider("Waveclear.CastQMinManaJg", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Waveclear.CastEJg","Cast E",true)
		Menu.Slider("Waveclear.CastEHCJg", "E Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastEMBJg", "E Min Barrels", 1, 1, 3, 1)
	end)
	Menu.NewTree("NAGangplankLasthit", "Lasthit", function ()
		Menu.Checkbox("Lasthit.CastQ","Cast Q",true)
		Menu.Slider("Lasthit.CastQHC", "Q Hit Chance", 0.60, 0.05, 1, 0.05)
	end)
	Menu.NewTree("NAGangplankMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastQKS","Auto-Cast Q Killable",true)
		Menu.Checkbox("Misc.CastWCC","Auto-Cast W on CC",true)
		Menu.Checkbox("Misc.CastRKS","Auto-Cast R Killable",true)
		Menu.Slider("Misc.CastRKSHC", "Killable R Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Misc.CastRKSMW", "R Min Waves Damage for KS", 3, 1, 18, 1)
		Menu.Checkbox("Misc.AABarrel","AutoAttack Barrel in Range in all Modes",true)
	end)
	Menu.NewTree("NAGangplankDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawE","Draw E Range",true)
		Menu.ColorPicker("Drawing.DrawEColor", "Draw E Color", 0x118AB2FF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
	end)
end

Menu.RegisterMenu("NAGangplank","NAGangplank",NAGangplankMenu)

local function GetIgniteSlot()
	for i=SpellSlots.Summoner1, SpellSlots.Summoner2 do
		if Player:GetSpell(i).Name:lower():find("summonerdot") then
			return i
		end
	end
	return SpellSlots.Unknown
end

-- Global vars
local spells = {
	Q = Spell.Targeted({
		Slot = Enums.SpellSlots.Q,
		Range = 625,
		Speed = 2600,
		Delay = 0.25,
	}),
	W = Spell.Active({
		Slot = Enums.SpellSlots.W,
		Delay = 0.25,
	}),
	E = Spell.Skillshot({
		Slot = Enums.SpellSlots.E,
		Range = 1000,
		Speed = math.huge,
		Delay = 0.25,
		Radius = 360,
		BarrelRadius = 345,
		Type = "Circular",
	}),
	R = Spell.Skillshot({
		Slot = Enums.SpellSlots.R,
		Range = math.huge,
		Speed = math.huge,
		Delay = 0.25,
		Radius = 580,
		Type = "Circular",
	}),
	Ign = Spell.Targeted({
		Slot = GetIgniteSlot(),
		Delay = 0,
		Range = 600,
	}),}

local lastTick = 0
local barrels = {}

local function ValidMinion(minion)
	return minion and minion.IsTargetable and minion.MaxHealth > 6 -- check if not plant or shroom
end

local function GameIsAvailable()
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function IsTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
		or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function GetBarrelsAmmo()
	return Player:GetSpell(SpellSlots.E).Ammo
end

local function CountBarrelsNearMe()

	local myPos = Player.Position
	local numBarrels = 0

	for handle, barrel in pairs(barrels) do
		local dist = myPos:Distance(barrel.Position)

		if dist <= spells.E.Range then
			numBarrels = numBarrels + 1
		end
	end

	return numBarrels
end

local function CountBarrelsNearTarget(target)

	local numBarrels = 0

	for handle, barrel in pairs(barrels) do

		local enemyPos = target:FastPrediction(spells.E.Delay)
		local dist = enemyPos:Distance(barrel.Position)

		if dist <= spells.E.Radius then
			numBarrels = numBarrels + 1
		end
	end

	return numBarrels
end

local function IsTargetNearBarrel(target)

	for handle, barrel in pairs(barrels) do

		local enemyPos = target:FastPrediction(spells.E.Delay)
		local dist = enemyPos:Distance(barrel.Position)

		if dist <= spells.E.Radius then
			return true
		end
	end

	return false
end

local function IsBarrelChained(barrel)
	if barrel:GetBuff("gangplankebarrellink") then return true end

	return false
end

local function BarrelsIntersect(posE1, posE2)
	if Geometry.CircleCircleIntersection(posE1, spells.E.BarrelRadius,
			posE2, spells.E.BarrelRadius) then
		return true
	end

	return false
end


local function CanKillBarrel(barrel)

	if barrel.Health == 1 then
		return true
	end

	return false
end

local function GetBarrelNearTarget(target)

	for handle, barrel in pairs(barrels) do

		local enemyPos = target:FastPrediction(spells.E.Delay)
		local dist = enemyPos:Distance(barrel.Position)

		if dist <= spells.E.Radius then
			return barrel
		end
	end

	return nil

end

local function GetNearestBarrel()

	local myPos = Player.Position
	local nearBarrel = nil

	for handle, barrel in pairs(barrels) do

		if nearBarrel then

			local distBarrel = myPos:Distance(barrel.Position)
			local distNearBarrel = myPos:Distance(nearBarrel.Position)

			if distBarrel < distNearBarrel then
				nearBarrel = barrel
			end

		else
			nearBarrel = barrel
		end
	end

	return nearBarrel
end

local function GetQDmg(target)
	local playerAI = Player.AsAI
	local dmgQ = -5 + 25 * Player:GetSpell(SpellSlots.Q).Level
	local bonusDmg = playerAI.TotalAD
	local totalDmg = dmgQ + bonusDmg

	return DamageLib.CalculatePhysicalDamage(Player, target, totalDmg)
end

local function GetEDmg(target)
	local playerAI = Player.AsAI
	local dmgE = Player.TotalAD
	local bonusDmg = 55 + 25 * Player:GetSpell(SpellSlots.E).Level
	local totalDmg = dmgE + bonusDmg
	return DamageLib.CalculatePhysicalDamage(Player, target, totalDmg)
end

local function GetRDmg(target, numWaves)
	local playerAI = Player.AsAI
	local dmgR = 30 + 90 * Player:GetSpell(SpellSlots.R).Level
	local bonusDmg = playerAI.TotalAP * 0.30
	local totalDmg = dmgR + bonusDmg * numWaves
	return DamageLib.CalculateMagicalDamage(Player, target, totalDmg)
end

local function GetIgniteDmg(target)
	return 50 + 20 * Player.Level - target.HealthRegen * 2.5
end

local function GetDamage(target)
	local totalDmg = 0
	if spells.Q:IsReady() then
		totalDmg = totalDmg + GetQDmg(target)
	end
	if spells.E:IsReady() then
		totalDmg = totalDmg + GetEDmg(target)
	end
	if spells.Ign.Slot ~= SpellSlots.Unknown and  spells.Ign:IsReady() then
		totalDmg = totalDmg + GetIgniteDmg(target)
	end

	return totalDmg
end

local function CastQ(target, checkBarrel)
	if spells.Q:IsReady() then
		if checkBarrel then
			local nearBarrel = GetNearestBarrel()
			local barrel = GetBarrelNearTarget(target)

			if nearBarrel and IsBarrelChained(nearBarrel) and barrel and IsBarrelChained(nearBarrel) then
				if CanKillBarrel(nearBarrel) then
					if spells.Q:Cast(nearBarrel) then
						return
					end
				end
			else
				if barrel and CanKillBarrel(barrel) then
					if spells.Q:Cast(barrel) then
						return
					end
				else
					if Player:Distance(target) <= spells.Q.Range and
							spells.Q:Cast(target) then
						return
					end
				end
			end

			return
		end

		if Player:Distance(target) <= spells.Q.Range and spells.Q:Cast(target) then
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

local function CastE(target, hitChance, minBarrels)
	if spells.E:IsReady() then
		--if CountBarrelsNearMe() <= minBarrels then
		if spells.E:CastOnHitChance(target, hitChance) then
			return
		end
		--end
	end
end

local function CastELogic(target, hitChance, minBarrels)

	if spells.E:IsReady() and CountBarrelsNearMe() <= minBarrels then

		local dist = Player:Distance(target.Position)

		if CountBarrelsNearMe() == 0 then
			local firstBarrelDist = Player.Position:Extended(target,
					Player.AttackRange+Player.BoundingRadius)
			if spells.E:Cast(firstBarrelDist) then
				return
			end
		else
			-- triple barrel
			if GetBarrelsAmmo() == 2 or CountBarrelsNearMe() >= 1 then
				if dist > spells.Q.Range and CountBarrelsNearMe() == 1 then
					local barrelTarget = GetNearestBarrel()
					if barrelTarget and CanKillBarrel(barrelTarget) then
						for i=1,3 do
							local barrelDist = Player.Position:Extended(target,(spells.E.BarrelRadius*2)*i)
							if BarrelsIntersect(barrelDist, barrelTarget.Position) then
								if spells.E:Cast(barrelDist) then
									return
								end
							end
						end
					end
				elseif (dist <= spells.Q.Range or CountBarrelsNearMe() >= 2) and not GetBarrelNearTarget(target) and
					CanKillBarrel(GetNearestBarrel()) then
						CastE(target, hitChance, minBarrels)
						return
				end
			end
		end
	end
end

local function CastR(target, hitChance)
	if spells.R:IsReady() then
		if spells.R:CastOnHitChance(target, hitChance) then
			return
		end
	end
end

local function CastR(targetPos)
	if spells.R:IsReady() then
		if spells.R:Cast(targetPos)  then
			return
		end
	end
end

local function CastRAll()

	if spells.R:IsReady() then
		local targets = {}
		local enemies = ObjManager.Get("enemy", "heroes")

		for handle, obj in pairs(enemies) do
			local hero = obj.AsHero
			if hero and hero.IsTargetable then
				local posHero = hero:FastPrediction(spells.R.Delay)
				table.insert(targets, posHero)
			end
		end

		local bestPosR, hitCountR = spells.R:GetBestCircularCastPos(targets)

		if hitCountR >= Menu.Get("Combo.CastRMinHit") then
			CastR(bestPosR)
		end
	end


end

local function CastIgnite(target)
	if spells.Ign:IsReady() then
		if spells.Ign:Cast(target) then
			return
		end
	end
end

local function AutoWCC()
	if not spells.W:IsReady() then return end

	if IsTargetCC(Player) then
		CastW()
	end

end

local function AutoQKS()
	if not spells.Q:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, qRange = Player.Position, (spells.Q.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = myPos:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.Q.Delay)
			if dist <= qRange and GetQDmg(hero) > healthPred then
				CastQ(hero, false) -- Q KS
			end
		end
	end
end

local function AutoRKS(numWaves)
	if not spells.R:IsReady() then return end

	local enemies = ObjManager.Get("enemy", "heroes")

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.R.Delay)
			if GetRDmg(hero,numWaves) > healthPred then
				CastR(hero, Menu.Get("Misc.CastRKSHC")) -- R KS
			end
		end
	end
end

local function Waveclear()

	if spells.Q:IsReady() or spells.E:IsReady() then

		local pPos, pointsE, minionQ, minionCannon = Player.Position, {}, nil, nil
		local isJgCS = false

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				local posE = minion:FastPrediction(spells.E.Delay)
				if posE:Distance(pPos) < spells.E.Range and minion.IsTargetable then
					table.insert(pointsE, posE)
				end

				if minion:Distance(pPos) <= spells.Q.Range then
					if minionQ then
						local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
						if minionQ.Health >= healthPred then
							minionQ = minion
						end
					else
						minionQ = minion
					end
				end

			end
		end

		-- Jungle Minions
		if #pointsE == 0 or not minionQ then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					local posE = minion:FastPrediction(spells.E.Delay)
					if posE:Distance(pPos) < spells.E.Range and minion.IsTargetable then
						isJgCS = true
						table.insert(pointsE, posE)
					end

					if minion:Distance(pPos) <= spells.Q.Range then
						isJgCS = true
						if minionQ then
							local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
							if minionQ.Health >= healthPred then
								minionQ = minion
							end
						else
							minionQ = minion
						end
					end

				end
			end
		end

		local castQMenu = nil
		local castQHCMenu = nil
		local castEMenu = nil
		local castEHCMenu = nil

		if not isJgCS then
			castQMenu = Menu.Get("Waveclear.CastQ")
			castEMenu = Menu.Get("Waveclear.CastE")
			castEHCMenu = Menu.Get("Waveclear.CastEHC")
		else
			castQMenu = Menu.Get("Waveclear.CastQJg")
			castEMenu = Menu.Get("Waveclear.CastEJg")
			castEHCMenu = Menu.Get("Waveclear.CastEHCJg")
		end

		local bestPosE, hitCountE = spells.E:GetBestCircularCastPos(pointsE)

		if bestPosE and hitCountE >= castEHCMenu
				and spells.E:IsReady() and castEMenu and CountBarrelsNearMe() == 0 then
			spells.E:Cast(bestPosE)
			return
		end
		if minionQ and spells.Q:IsReady() and castQMenu then
			if minionQ.Health <= GetQDmg(minionQ) then
				CastQ(minionQ, false)
				return
			else
				if CountBarrelsNearMe() > 0 then
					local barrel = GetNearestBarrel()
					if CanKillBarrel(barrel) then
						CastQ(barrel, false)
					end
				end
			end
		end
	end
end

local function LasthitQ()
	if spells.Q:IsReady() then
		local pPos, minionQ = Player.Position, nil

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				if minion:Distance(pPos) <= spells.Q.Range then
					if minionQ then
						local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
						if minionQ.Health >= healthPred then
							minionQ = minion
						end
					else
						minionQ = minion
					end
				end
			end
		end

		-- Jungle Minions
		if not minionQ then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					if minion:Distance(pPos) <= spells.Q.Range then
						if minionQ then
							local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
							if minionQ.Health >= healthPred then
								minionQ = minion
							end
						else
							minionQ = minion
						end
					end
				end
			end
		end

		if minionQ then
			if minionQ.Health <= GetQDmg(minionQ) then
				CastQ(minionQ, false)
				return
			end
		end

	end

end

local function OnHighPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	if Menu.Get("Misc.CastQKS") then
		AutoQKS()
	end
	if Menu.Get("Misc.CastWCC") then
		AutoWCC()
	end
	if Menu.Get("Misc.CastRKS") then
		AutoRKS(Menu.Get("Misc.CastRKSMW"))
	end

end

local function OnNormalPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	local gameTime = Game.GetTime()
	if gameTime < (lastTick + 0.25) then return end
	lastTick = gameTime

	-- Combo
	if Orbwalker.GetMode() == "Combo" then
		if Menu.Get("Combo.CastQ") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
					CastQ(target, Menu.Get("Combo.CastQBarrel"))
				end
			end
		end
		if Menu.Get("Combo.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
					CastELogic(target,Menu.Get("Combo.CastEHC"), Menu.Get("Combo.CastEMB"))
					return
				end
			end
		end
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.R.Range + Player.BoundingRadius, true)
				if target then
					CastRAll()
					return
				end
			end
		end
		if Menu.Get("Combo.CastIgnite") then
			if spells.Ign.Slot ~= SpellSlots.Unknown then
				if spells.Ign:IsReady() then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Ign.Range + Player.BoundingRadius, true)
					if target and target.Position:Distance(Player.Position) <= (spells.Ign.Range + Player.BoundingRadius) then
						CastIgnite(target)
						return
					end
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
					CastQ(target,Menu.Get("Harass.CastQBarrel"))
					return
				end
			end
		end
		if Menu.Get("Harass.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius) then
					CastELogic(target,Menu.Get("Harass.CastEHC"), Menu.Get("Harass.CastEMB"))
					return
				end
			end
		end

		-- Lasthit
	elseif Orbwalker.GetMode() == "Lasthit" then
		if Menu.Get("Lasthit.CastQ") then
			LasthitQ()
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

	if GetNearestBarrel() then
		Renderer.DrawCircle3D(GetNearestBarrel().Position, spells.E.Radius, 30, 1.0, Menu.Get("Drawing.DrawEColor"))
	end

end

local function OnDrawDamage(target, dmgList)
	if Menu.Get("Drawing.DrawDamage") then
		table.insert(dmgList, GetDamage(target))
	end
end

local function OnCreateObject(obj)
	if obj.IsMinion then
		local objName = obj.Name
		local objAA = obj.AsAttackableUnit

		if objName and objAA and obj.IsBarrel then
			if objName == "Barrel" then
				barrels[obj.Handle] = objAA
			end
		end
	end
end

local function OnDeleteObject(obj)
	if obj.IsMinion then
		local objName = obj.Name
		local objAA = obj.AsAttackableUnit

		if objName and objAA and obj.IsBarrel then
			if objName == "Barrel" then
				barrels[obj.Handle] = nil
			end
		end
	end
end

local function OnPreAttack(args)

	local myRange = Player.AttackRange + Player.BoundingRadius
	local target = args.Target

	if Menu.Get("Misc.AABarrel") and target.IsHero then
		local barrel = GetBarrelNearTarget(target)

		if barrel and CanKillBarrel(barrel) then
			local dist = Player:Distance(barrel)

			if dist <= myRange then
				args.Target = barrel
			end
		end
	end

end


function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnNormalPriority, OnNormalPriority)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreateObject)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDeleteObject)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnPreAttack, OnPreAttack)

	return true
end
