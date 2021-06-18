if Player.CharName ~= "Heimerdinger" then return false end

module("NAHeimer", package.seeall, log.setup)
clean.module("NAHeimer", clean.seeall, log.setup)

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

function NAHeimerMenu()
	Menu.NewTree("NAHeimerCombo", "Combo", function ()
		Menu.Checkbox("Combo.CastQ","Cast Q",false)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 1, 0, 100, 1)
		Menu.Slider("Combo.CastQMinRange", "Q Min. Range", 450, 10, 525, 5)
		Menu.Checkbox("Combo.CastW","Cast W",true)
		Menu.Checkbox("Combo.CastWCC","Cast W on CC Only",false)
		Menu.Slider("Combo.CastWHC", "W Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastWMinMana", "W % Min. Mana", 1, 0, 100, 1)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastEHC", "E Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastEMinMana", "E % Min. Mana", 1, 0, 100, 1)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 1, 0, 100, 1)
		Menu.Checkbox("Combo.CastIgnite", "Cast Ignite if Available", true)
	end)
	Menu.NewTree("NAHeimerHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastQ","Cast Q",false)
		Menu.Slider("Harass.CastQMinMana", "Q % Min. Mana", 1, 0, 100, 1)
		Menu.Slider("Harass.CastQMinRange", "Q Min. Range", 450, 10, 525, 5)
		Menu.Checkbox("Harass.CastW","Cast W",true)
		Menu.Checkbox("Harass.CastWCC","Cast W on CC Only",false)
		Menu.Slider("Harass.CastWHC", "W Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastWMinMana", "W % Min. Mana", 1, 0, 100, 1)
		Menu.Checkbox("Harass.CastE","Cast E",true)
		Menu.Slider("Harass.CastEHC", "E Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastEMinMana", "E % Min. Mana", 1, 0, 100, 1)
	end)
	Menu.NewTree("NAHeimerWave", "Waveclear", function ()
		Menu.ColoredText("Wave", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastW","Cast W",true)
		Menu.Slider("Waveclear.CastWHC", "W Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastWMinMana", "W % Min. Mana", 50, 0, 100, 1)
		Menu.Checkbox("Waveclear.CastE","Cast E",true)
		Menu.Slider("Waveclear.CastEHC", "E Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastEMinMana", "E % Min. Mana", 50, 0, 100, 1)
		Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastWJg","Cast W",true)
		Menu.Slider("Waveclear.CastWHCJg", "W Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastWMinManaJg", "W % Min. Mana", 10, 0, 100, 1)
		Menu.Checkbox("Waveclear.CastEJg","Cast E",true)
		Menu.Slider("Waveclear.CastEHCJg", "E Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastEMinManaJg", "E % Min. Mana", 10, 0, 100, 1)
	end)
	Menu.NewTree("NAHeimerMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastRQ","Auto-Cast R-Q Hero in Range",true)
		Menu.Slider("Misc.CastRHC", "Q Min. Range Heros", 2, 1, 5, 1)
		Menu.Slider("Misc.CastQMinRange", "Q Min. Range", 450, 10, 525, 5)
		Menu.Checkbox("Misc.CastRWKS","Auto-Cast R-W Killable",true)
		Menu.Slider("Misc.CastRWKSHC", "W Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Checkbox("Misc.CastREKS","Auto-Cast R-E Killable",true)
		Menu.Slider("Misc.CastREKSHC", "E Hit Chance", 0.75, 0.05, 1, 0.05)
		Menu.Checkbox("Misc.CastEGap","Auto-Cast E GapCloser",false)
	end)
	Menu.NewTree("NAHeimerDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawW","Draw W Range",true)
		Menu.ColorPicker("Drawing.DrawWColor", "Draw W Color", 0x06D6A0FF)
		Menu.Checkbox("Drawing.DrawE","Draw E Range",true)
		Menu.ColorPicker("Drawing.DrawEColor", "Draw E Color", 0x118AB2FF)
		Menu.Checkbox("Drawing.DrawTurrets","Draw Turret Activation Range",true)
		Menu.ColorPicker("Drawing.DrawTurretsColor", "Draw Turret Range Color", 0xFFFFFFFF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
	end)
end
Menu.RegisterMenu("NAHeimer","NAHeimer",NAHeimerMenu)

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
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 350,
		Speed = math.huge,
		Delay = 0.25,
		Radius = 525,
		Type = "Circular",
		TurretRange = 525,
	}),
	W = Spell.Skillshot({
		Slot = Enums.SpellSlots.W,
		Range = 1325,
		Speed = 3000,
		--ConeAngleRad = 45,
		Delay = 0.25,
		Radius = 300,
		Type = "Linear",
		Collisions = {Heroes=true, Minions=true, WindWall=true},
	}),
	E = Spell.Skillshot({
		Slot = Enums.SpellSlots.E,
		Range = 970,
		Speed = 1200,
		Delay = 0.25,
		Radius = 250,
		Type = "Circular",
	}),
	R = Spell.Active({
		Slot = Enums.SpellSlots.R,
		Range = Player.AttackRange + 50,
		Delay = 0,
	}),
	Ign = Spell.Targeted({
		Slot = GetIgniteSlot(),
		Delay = 0,
		Range = 600,
	}),
}

local lastTick = 0
local rActive = false
local turrets = {}

local function ValidMinion(minion)
	return minion and minion.IsTargetable and minion.MaxHealth > 6 -- check if not plant or shroom
end

local function GameIsAvailable()
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function IsRActive()
	return rActive
end

local function isTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
		or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function GetWDmg(target, onUlt)
	local playerAI = Player.AsAI
	local dmgW = not onUlt and
			(25 + 25 * Player:GetSpell(SpellSlots.W).Level) or (90 + 45 * Player:GetSpell(SpellSlots.R).Level)
	local dmgWExtra = 5 + 5 * Player:GetSpell(SpellSlots.W).Level

	local totalDmg = (dmgW + 0.45 * playerAI.TotalAP) + (dmgWExtra + 0.12 * playerAI.TotalAP)

	if IsRActive() then
		totalDmg = totalDmg * 4
	end

	--print("target: eDmg: ", target.Name, DamageLib.CalculateMagicalDamage(Player, target, totalDmg))
	return DamageLib.CalculateMagicalDamage(Player, target, totalDmg)
end

local function GetEDmg(target, onUlt)
	local playerAI = Player.AsAI
	local dmgE = not onUlt and
			(20 + 40 * Player:GetSpell(SpellSlots.E).Level) or (100 * Player:GetSpell(SpellSlots.R).Level)

	local totalDmg = dmgE + 0.60 * playerAI.TotalAP
	
	--print("target: eDmg: ", target.Name, DamageLib.CalculateMagicalDamage(Player, target, totalDmg))
	return DamageLib.CalculateMagicalDamage(Player, target, totalDmg)
end

local function GetIgniteDmg(target)
	return 50 + 20 * Player.Level - target.HealthRegen * 2.5
end

local function GetDamage(target)
	local totalDmg = 0
	if spells.W:IsReady() then
		totalDmg = totalDmg + GetWDmg(target, IsRActive())
	end
	if spells.E:IsReady() then
		totalDmg = totalDmg + GetEDmg(target, IsRActive())
	end
	if spells.Ign.Slot ~= SpellSlots.Unknown and  spells.Ign:IsReady() then
		totalDmg = totalDmg + GetIgniteDmg(target)
	end
	
	return totalDmg
end

local function CastQ(pos)
	if spells.Q:IsReady() then
		if spells.Q:Cast(pos) then
			return
		end
	end
end

local function CastQ(target, minTurretRange)
	if spells.Q:IsReady() then
		local targetPos = target:FastPrediction(spells.Q.Delay)
		local predPos = Player.Position:Extended(targetPos,spells.Q.Range)
		local dist = predPos:Distance(targetPos)
		if dist <= minTurretRange and spells.Q:Cast(predPos) then
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

local function CastR()
	if spells.R:IsReady() then
		if spells.R:Cast() then
			return
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

local function AutoRQ()
	if not spells.Q:IsReady() and not spells.R:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, qRange = Player.Position, (not IsRActive() and (spells.Q.Range + Player.BoundingRadius + 100)
		or (spells.Q.Range + Player.BoundingRadius))
	local pointsQ = {}
	
	local enemiesInRange = 0

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			
			local targetPos = hero:FastPrediction(spells.Q.Delay)
			local predPos = Player.Position:Extended(targetPos,spells.Q.Range)
			local dist = predPos:Distance(targetPos)
			
			if dist <= Menu.Get("Misc.CastQMinRange") then
				enemiesInRange = enemiesInRange + 1
				table.insert(pointsQ,predPos)
			end

		end
	end
	
	if enemiesInRange >= Menu.Get("Misc.CastRHC") then
	
		CastR()
		if IsRActive() then
		
			local bestPosQ, hitCountQ = spells.Q:GetBestCircularCastPos(pointsQ)
			
			if hitCountQ >= enemiesInRange then 
				CastQ(bestPosQ)
			end
			
		end
	
	end
	
end

local function AutoRWKS()
	if not spells.W:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, wRange = Player.Position, (spells.W.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = myPos:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.W.Delay)
			local wDmg = GetWDmg(hero, false)
			local wDmgR = GetWDmg(hero, true)

			if dist <= wRange and wDmgR > healthPred then
				CastR()
				if IsRActive() then
					CastW(hero, Menu.Get("Misc.CastRWKSHC")) -- RW KS
				end
			end
			if dist <= wRange and wDmg > healthPred then
				CastE(hero, Menu.Get("Misc.CastRWKSHC")) -- W KS
			end
		end
	end
end

local function AutoREKS()
	if not spells.E:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, eRange = Player.Position, (spells.E.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = myPos:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.E.Delay)
			local eDmg = GetEDmg(hero, false)
			local eDmgR = GetEDmg(hero, true)

			if dist <= eRange and eDmgR > healthPred then
				CastR()
				if IsRActive() then
					CastE(hero, Menu.Get("Misc.CastREKSHC")) -- RE KS
				end
			end
			if dist <= eRange and eDmg > healthPred then
				CastE(hero, Menu.Get("Misc.CastREKSHC")) -- E KS
			end
		end
	end
end

local function Waveclear()

	if spells.W:IsReady() or spells.E:IsReady() then

		local pPos, pointsW, pointsE = Player.Position, {}, {}
		local isJgCS = false

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				local posW = minion:FastPrediction(spells.W.Delay)
				if posW:Distance(pPos) < spells.W.Range and minion.IsTargetable then
					table.insert(pointsW, posW)
				end

				local posE = minion:FastPrediction(spells.E.Delay)
				if posE:Distance(pPos) < spells.E.Range and minion.IsTargetable then
					table.insert(pointsE, posE)
				end
			end
		end

		-- Jungle Minions
		if #pointsW == 0 or #pointsE == 0 then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					local posW = minion:FastPrediction(spells.W.Delay)
					if posW:Distance(pPos) < spells.W.Range and minion.IsTargetable then
						isJgCS = true
						table.insert(pointsW, posW)
					end

					local posE = minion:FastPrediction(spells.E.Delay)
					if posE:Distance(pPos) < spells.E.Range and minion.IsTargetable then
						isJgCS = true
						table.insert(pointsE, posE)
					end
				end
			end
		end

		local castWMenu = nil
		local castWHCMenu = nil
		local castWMinManaMenu = nil
		local castEMenu = nil

		if not isJgCS then
			castWMenu = Menu.Get("Waveclear.CastW")
			castWHCMenu = Menu.Get("Waveclear.CastWHC")
			castWMinManaMenu = Menu.Get("Waveclear.CastWMinMana")
			castEMenu = Menu.Get("Waveclear.CastE")
			castEHCMenu = Menu.Get("Waveclear.CastEHC")
			castEMinManaMenu = Menu.Get("Waveclear.CastEMinMana")
		else
			castWMenu = Menu.Get("Waveclear.CastWJg")
			castWHCMenu = Menu.Get("Waveclear.CastWHCJg")
			castWMinManaMenu = Menu.Get("Waveclear.CastWMinManaJg")
			castEMenu = Menu.Get("Waveclear.CastEJg")
			castEHCMenu = Menu.Get("Waveclear.CastEHCJg")
			castEMinManaMenu = Menu.Get("Waveclear.CastEMinManaJg")
		end

		local bestPosW, hitCountW = spells.W:GetBestLinearCastPos(pointsW)

		if bestPosW and hitCountW >= castWHCMenu
				and spells.W:IsReady() and castWMenu
				and Player.Mana >= (castWMinManaMenu / 100) * Player.MaxMana then
			spells.W:Cast(bestPosW)
			return
		end

		local bestPosE, hitCountE = spells.E:GetBestCircularCastPos(pointsW)

		if bestPosE and hitCountE >= castEHCMenu
				and spells.E:IsReady() and castEMenu
				and Player.Mana >= (castEMinManaMenu / 100) * Player.MaxMana then
			spells.E:Cast(bestPosE)
			return
		end

	end
end

local function OnHighPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	if Menu.Get("Misc.CastRQ") then
		AutoRQ()
	end
	if Menu.Get("Misc.CastRWKS") then
		AutoRWKS()
	end
	if Menu.Get("Misc.CastREKS") then
		AutoREKS()
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
				local target = Orbwalker.GetTarget() or
						TS:GetTarget(spells.Q.Range + spells.Q.TurretRange + Player.BoundingRadius, false)
				if target then
					CastQ(target, Menu.Get("Combo.CastQMinRange"))
					return
				end
			end
		end
		if Menu.Get("Combo.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastEMinMana") / 100) * Player.MaxMana then
					CastE(target,Menu.Get("Combo.CastEHC"))
					return
				end
			end
		end
		if Menu.Get("Combo.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.W.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastWMinMana") / 100) * Player.MaxMana then
					if Menu.Get("Combo.CastWCC") then
						if isTargetCC(target) then
							CastW(target,Menu.Get("Combo.CastWHC"))
							return
						end
					else
						CastW(target,Menu.Get("Combo.CastWHC"))
						return
					end

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
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.R.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.R.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastRMinMana") / 100) * Player.MaxMana then
					CastR()
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
				local target = Orbwalker.GetTarget() or
						TS:GetTarget(spells.Q.Range + spells.Q.TurretRange + Player.BoundingRadius, false)
				if target then
					CastQ(target, Menu.Get("Harass.CastQMinRange"))
					return
				end
			end
		end
		if Menu.Get("Harass.CastE") then
			if spells.E:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastEMinMana") / 100) * Player.MaxMana then
					CastE(target,Menu.Get("Harass.CastEHC"))
					return
				end
			end
		end
		if Menu.Get("Harass.CastW") then
			if spells.W:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.W.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.W.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Harass.CastWMinMana") / 100) * Player.MaxMana then
					if Menu.Get("Harass.CastWCC") then
						if isTargetCC(target) then
							CastW(target,Menu.Get("Harass.CastWHC"))
							return
						end
					else
						CastW(target,Menu.Get("Harass.CastWHC"))
						return
					end

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

	-- Draw Turret Activation Range
	for handle, turretPos in pairs(turrets) do
		if Menu.Get("Drawing.DrawTurrets") then
			Renderer.DrawCircle3D(turretPos, 1000, 30, 1.0, Menu.Get("Drawing.DrawTurretsColor"))
		end
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

local function OnBuffGain(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name
		--if buff then
		--	print("buffG: ", buff)
		--end

		if buff == "HeimerdingerR" then
			rActive = true
			spells.Q.Range = 450
		end
	end
end

local function OnBuffLost(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name
		--if buff then
		--	print("buffL: ", buff)
		--end

		if buff == "HeimerdingerR" then
			rActive = false
			spells.Q.Range = 350
		end
	end
end

local function OnCreateObject(obj)
	if obj.IsAlly and obj.IsMinion then
		local objName = obj.Name
		if objName == "H-28G Evolution Turret" then
			turrets[obj.Handle] = obj.Position
		end
	end
end

local function OnDeleteObject(obj)
	if obj.IsAlly and obj.IsMinion then
		local objName = obj.Name
		if objName == "H-28G Evolution Turret" then
			turrets[obj.Handle] = nil
		end
	end
end

function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnNormalPriority, OnNormalPriority)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)
	EventManager.RegisterCallback(Enums.Events.OnBuffGain, OnBuffGain)
	EventManager.RegisterCallback(Enums.Events.OnBuffLost, OnBuffLost)
	EventManager.RegisterCallback(Enums.Events.OnCreateObject, OnCreateObject)
	EventManager.RegisterCallback(Enums.Events.OnDeleteObject, OnDeleteObject)

	return true
end
