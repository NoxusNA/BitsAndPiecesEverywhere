if Player.CharName ~= "Shaco" then return false end

module("NAShaco", package.seeall, log.setup)
clean.module("NAShaco", clean.seeall, log.setup)

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

function NAShacoMenu()
	Menu.NewTree("NAShacoCombo", "Combo", function ()
		Menu.Checkbox("Combo.CastQ","Cast Q",false)
		Menu.Slider("Combo.CastQMinMana", "Q % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastW","Cast W",true)
		Menu.Checkbox("Combo.CastWCC","Cast W on CC Only",true)
		Menu.Slider("Combo.CastWHC", "W Hit Chance", 0.50, 0.05, 1, 0.05)
		Menu.Slider("Combo.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastE","Cast E",true)
		Menu.Slider("Combo.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastR","Cast R",true)
		Menu.Checkbox("Combo.CastRHail","Cast R Only After HailOfBlades Buff",true)
		Menu.Slider("Combo.CastRMinMana", "R % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Combo.CastIgnite", "Cast Ignite if Available", true)
		Menu.Checkbox("Combo.CastSmite", "Cast Smite if Available", true)
		Menu.Checkbox("Combo.CastProwler", "Cast Prowler's Claw if Available", true)
	end)
	Menu.NewTree("NAShacoHarass", "Harass", function ()
		Menu.Checkbox("Harass.CastW","Cast W",true)
		Menu.Checkbox("Harass.CastWCC","Cast W on CC Only",true)
		Menu.Slider("Harass.CastWHC", "W Hit Chance", 0.60, 0.05, 1, 0.05)
		Menu.Slider("Harass.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Harass.CastE","Cast E",true)
		Menu.Slider("Harass.CastEMinMana", "E % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAShacoWave", "Waveclear", function ()
		Menu.ColoredText("Wave", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastW","Cast W",true)
		Menu.Slider("Waveclear.CastWHC", "W Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastWMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Waveclear.CastE","Cast E",true)
		Menu.Slider("Waveclear.CastEMinMana", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
		Menu.Checkbox("Waveclear.CastWJg","Cast W",true)
		Menu.Slider("Waveclear.CastWHCJg", "W Min. Hit Count", 1, 0, 10, 1)
		Menu.Slider("Waveclear.CastWMinManaJg", "W % Min. Mana", 0, 1, 100, 1)
		Menu.Checkbox("Waveclear.CastEJg","Cast W",true)
		Menu.Slider("Waveclear.CastEMinManaJg", "W % Min. Mana", 0, 1, 100, 1)
	end)
	Menu.NewTree("NAShacoLasthit", "Lasthit", function ()
		Menu.Checkbox("Lasthit.CastE","Cast E",true)
	end)
	Menu.NewTree("NAShacoMisc", "Misc.", function ()
		Menu.Checkbox("Misc.CastAAQOnlyBackstab","AA Only if Backstab while Stealth on Q",true)
		Menu.Checkbox("Misc.CastEKS","Auto-Cast E Killable",true)
		Menu.Checkbox("Misc.CastWGap","Auto-Cast W GapCloser",true)
		Menu.Checkbox("Misc.CastRLowHP","Auto-Cast R LowHP",true)
		Menu.Slider("Misc.CastRMinLowHP", "R % LowHP", 30, 1, 100, 1)
		Menu.Checkbox("Misc.AutoRFollow","Auto-Clone Follow",true)
		Menu.Checkbox("Misc.CoupRune","Coup De Grace Rune",true)
		Menu.Checkbox("Misc.CastWInitialJg","Cast W for Initial Jungle Spots",true)
		Menu.Keybind("Misc.JgBackStab", "Jungle BackStab Only", string.byte("J"), true, false)
	end)
	Menu.NewTree("NAShacoDrawing", "Drawing", function ()
		Menu.Checkbox("Drawing.DrawQ","Draw Q Range",true)
		Menu.ColorPicker("Drawing.DrawQColor", "Draw Q Color", 0xEF476FFF)
		Menu.Checkbox("Drawing.DrawW","Draw W Range",true)
		Menu.ColorPicker("Drawing.DrawWColor", "Draw W Color", 0x06D6A0FF)
		Menu.Checkbox("Drawing.DrawE","Draw E Range",true)
		Menu.ColorPicker("Drawing.DrawEColor", "Draw E Color", 0x118AB2FF)
		Menu.Checkbox("Drawing.DrawR","Draw R Range",true)
		Menu.ColorPicker("Drawing.DrawRColor", "Draw R Color", 0xFFD166FF)
		Menu.Checkbox("Drawing.DrawQPredPos","Draw Q Predicted Position",true)
		Menu.ColorPicker("Drawing.DrawQPredColor", "Draw Q Predicted Color", 0xFFFFFFFF)
		Menu.Checkbox("Drawing.DrawDamage","Draw Damage",true)
		Menu.Checkbox("Drawing.DrawJgSpots","Draw Initial Jungle W Spots",true)
		Menu.ColorPicker("Drawing.DrawJgSpotsColor", "Draw Jungle W Color", 0x00FF00FF)
	end)
end
Menu.RegisterMenu("NAShaco","NAShaco",NAShacoMenu)

local function GetIgniteSlot()
	for i=SpellSlots.Summoner1, SpellSlots.Summoner2 do
		if Player:GetSpell(i).Name:lower():find("summonerdot") then
			return i
		end
	end
	return SpellSlots.Unknown
end

local function GetSmiteSlot()
	for i=SpellSlots.Summoner1, SpellSlots.Summoner2 do
		if Player:GetSpell(i).Name:lower():find("smite") then
			return i
		end
	end
	return SpellSlots.Unknown
end

local function GetProwlerSlot()	
	for i=SpellSlots.Item1, SpellSlots.Item6 do
		local item = Player:GetSpell(i)
		if item and item.Name == "6693Active" then
			return i
		end
	end
	
	return SpellSlots.Unknown
end

-- Global vars
local spells = {
	Q = Spell.Skillshot({
		Slot = Enums.SpellSlots.Q,
		Range = 400,
		Speed = 1550,
		Delay = 0.75,
		Radius = Player.BoundingRadius,
		Type = "Circular",
	}),
	W = Spell.Skillshot({
		Slot = Enums.SpellSlots.W,
		Range = 500,
		Speed = math.huge,
		Delay = 2.00,
		Radius = 300,
		Type = "Circular",
	}),
	E = Spell.Targeted({
		Slot = Enums.SpellSlots.E,
		Delay = 0.25,
		Range = 625,
	}),
	R = Spell.Skillshot({
		Slot = Enums.SpellSlots.R,
		Range = 250,
		Speed = math.huge,
		Delay = 0.25,
		Radius = 250,
		Type = "Circular",
	}),
	Ign = Spell.Targeted({
		Slot = GetIgniteSlot(),
		Delay = math.huge,
		Range = 600,
	}),
	Smite = Spell.Targeted({
		Slot = GetSmiteSlot(),
		Delay = math.huge,
		Range = 600,
	}),
	Prowler = Spell.Targeted({
		Slot = GetProwlerSlot(),
		Delay = math.huge,
		Range = 500,
	}),
}

local jgWSpots = {
	W1Blue = {
		Position = Geometry.Vector(6861.04,50.17,5374.14),
		Time = 50,
	},
	W2Blue = {
		Position = Geometry.Vector(6970.46,53.94,5456.48),
		Time = 68,
	},
	W3Blue = {
		Position = Geometry.Vector(6905.83,48.53,4559.07),
		Time = 84,
	},
	W1Red = {
		Position = Geometry.Vector(7955.41,52.12,9651.28),
		Time = 50,
	},
	W2Red = {
		Position = Geometry.Vector(7854.32,52.29,9578.22),
		Time = 68,
	},
	W3Red = {
		Position = Geometry.Vector(7898.00,50.21,10385.15),
		Time = 84,
	},
}

local lastTick = 0
local qActive = false
local hailBuffActive = false
local killableEnemies = {}
local smiteDmg = 0

local function ValidMinion(minion)
	return minion and minion.IsTargetable and minion.MaxHealth > 6 -- check if not plant or shroom
end

local function GameIsAvailable()
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function IsQActive()
	return qActive
end

local function IsCloneActive()
	return Player:GetSpell(SpellSlots.R).Name == "HallucinateGuide"
end

local function isTargetCC(target)
	return target.IsImmovable or target.IsTaunted or target.IsFeared or target.IsSurpressed or target.IsAsleep
		or target.IsCharmed or target.IsSlowed or target.IsGrounded
end

local function GetEDmg(target)
	local playerAI = Player.AsAI
	local pPos = Player.Position
	local extraDmg = 0
	local dmgQ = 45 + 25 * Player:GetSpell(SpellSlots.E).Level
	local bonusDmg = playerAI.BonusAD * 0.7 + playerAI.TotalAP * 0.50

	if not target:IsFacing(pPos,90) then
		if target.HealthPercent < 0.3 then
			extraDmg = 12.94 + (2.06 * Player.Level) + playerAI.TotalAP * 0.15
		else
			extraDmg = 19.41 + (3.09 * Player.Level) + playerAI.TotalAP * 0.1
		end
	end
	local totalDmg = dmgQ + bonusDmg + extraDmg
	
	if Menu.Get("Misc.CoupRune") and target.HealthPercent < 0.4 then
		totalDmg = totalDmg + (totalDmg * 0.08)
	end
	
	return DamageLib.CalculateMagicalDamage(Player, target, totalDmg)
end

local function GetIgniteDmg(target)
	return 50 + 20 * Player.Level - target.HealthRegen * 2.5
end

local function GetSmiteDmg(target)
	if spells.Smite.Slot ~= SpellSlots.Unknown and  spells.Smite:IsReady() then
		if Player:GetSpell(spells.Smite.Slot).Name == "S5_SummonerSmitePlayerGanker" then
			return 12 + 8 * Player.Level
		end
	end

	return 0
end

local function GetProwlerDmg(target)
	local playerAI = Player.AsAI
	local dmg = 65 + 0.25 * playerAI.BonusAD
	return DamageLib.CalculatePhysicalDamage(Player, target, dmg)
end

local function GetDamage(target)
	local totalDmg = 0
	if spells.E:IsReady() then
		totalDmg = totalDmg + GetEDmg(target)
	end
	if spells.Ign.Slot ~= SpellSlots.Unknown and  spells.Ign:IsReady() then
		totalDmg = totalDmg + GetIgniteDmg(target)
	end
	if spells.Smite.Slot ~= SpellSlots.Unknown and spells.Smite:IsReady() then
		totalDmg = totalDmg + GetSmiteDmg(target)
	end
	if spells.Prowler.Slot ~= SpellSlots.Unknown and spells.Prowler:IsReady() then
		totalDmg = totalDmg + GetProwlerDmg(target)
	end
	
	return totalDmg
end

local function CastQ(target)
	if spells.Q:IsReady() then
		if target then
			if spells.Q:Cast(target) then
				return
			end
		else
			local mousePos = Renderer.GetMousePos()
			if spells.Q:Cast(mousePos)  then
				return
			end
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

local function CastW(pos)
	if spells.W:IsReady() then
		if spells.W:Cast(pos) then
			return
		end
	end
end

local function CastE(target)
	if spells.E:IsReady() then
		if spells.E:Cast(target) then
			return
		end
	end
end

local function CastR(target)
	if spells.R:IsReady() then

		if target then
			if spells.R:Cast(target) then
				return
			end
		else
			local mousePos = Renderer.GetMousePos()
			if spells.R:Cast(mousePos)  then
				return
			end
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

local function CastSmite(target)
	if spells.Smite:IsReady() then
		if Player:GetSpell(spells.Smite.Slot).Name == "S5_SummonerSmiteDuel" or 
			Player:GetSpell(spells.Smite.Slot).Name == "S5_SummonerSmitePlayerGanker" then
			if spells.Smite:Cast(target) then
				return
			end
		end
	end
end

local function CastProwler(target)
	if spells.Prowler:IsReady() then
		if spells.Prowler:Cast(target) then
			return
		end
	end
end

local function AutoEKS()
	if not spells.E:IsReady() then return end

	local enemies = ObjManager.GetNearby("enemy", "heroes")
	local myPos, eRange = Player.Position, (spells.E.Range + Player.BoundingRadius)

	for handle, obj in pairs(enemies) do
		local hero = obj.AsHero
		if hero and hero.IsTargetable then
			local dist = myPos:Distance(hero.Position)
			local healthPred = HealthPred.GetHealthPrediction(hero, spells.E.Delay)
			--if GetEDmg(hero) > healthPred then
			--	killableEnemies[hero.Name] = hero
			--else
			--	killableEnemies[hero.Name] = nil
			--end
			if dist <= eRange and GetEDmg(hero) > healthPred then
				CastE(hero) -- E KS
			end
		end
	end
end

local function AutoRLowHP()
	if not spells.R:IsReady() then return end

	if Player.HealthPercent <= Menu.Get("Misc.CastRMinLowHP")/100 then
		CastR()
	end

end

local function AutoInitialJg()
	local gameTime = Game.GetTime()
	for handle, spot in pairs(jgWSpots) do
		if Player:Distance(spot.Position) <= spells.W.Range and 
			gameTime > spot.Time-0.5 and gameTime <= spot.Time+0.5 then
			CastW(spot.Position)
		end
	end
end

local function Waveclear()

	if spells.W:IsReady() or spells.E:IsReady() then

		local pPos, pointsW, minionE = Player.Position, {}, nil
		local isJgCS = false

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				local posW = minion:FastPrediction(spells.W.Delay)
				if posW:Distance(pPos) < spells.W.Range and minion.IsTargetable then
					table.insert(pointsW, posW)
				end

				if minion:Distance(pPos) <= spells.E.Range then
					if minionE then
						local healthPred = HealthPred.GetHealthPrediction(minion, spells.E.Delay)
						if minionE.Health >= healthPred then
							minionE = minion
						end
					else
						minionE = minion
					end
				end
			end
		end

		-- Jungle Minions
		if #pointsW == 0 or not minionE then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					local posW = minion:FastPrediction(spells.W.Delay)
					if posW:Distance(pPos) < spells.W.Range and minion.IsTargetable then
						isJgCS = true
						table.insert(pointsW, posW)
					end

					if minion:Distance(pPos) <= spells.E.Range then
						isJgCS = true
						if minionE then
							local healthPred = HealthPred.GetHealthPrediction(minion, spells.E.Delay)
							if minionE.Health >= healthPred then
								minionE = minion
							end
						else
							minionE = minion
						end
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
			castEMinManaMenu = Menu.Get("Waveclear.CastEMinMana")
		else
			castWMenu = Menu.Get("Waveclear.CastWJg")
			castWHCMenu = Menu.Get("Waveclear.CastWHCJg")
			castWMinManaMenu = Menu.Get("Waveclear.CastWMinManaJg")
			castEMenu = Menu.Get("Waveclear.CastEJg")
			castEMinManaMenu = Menu.Get("Waveclear.CastEMinManaJg")
		end

		local bestPosW, hitCountW = spells.W:GetBestCircularCastPos(pointsW)

		if bestPosW and hitCountW >= castWHCMenu
				and spells.W:IsReady() and castWMenu
				and Player.Mana >= (castWMinManaMenu / 100) * Player.MaxMana then
			spells.W:Cast(bestPosW)
			return
		end
		if minionE and spells.E:IsReady() and castEMenu
				and Player.Mana >= (castEMinManaMenu / 100) * Player.MaxMana then
			if minionE.Health <= GetEDmg(minionE) then
				CastE(minionE)
				return
			end
		end
	end
end

local function LasthitE()
	if spells.E:IsReady() then
		local pPos, minionE = Player.Position, nil

		-- Enemy Minions
		for k, v in pairs(ObjManager.GetNearby("enemy", "minions")) do
			local minion = v.AsAI
			if ValidMinion(minion) then
				if minion:Distance(pPos) <= spells.E.Range then
					if minionE then
						local healthPred = HealthPred.GetHealthPrediction(minion, spells.E.Delay)
						if minionE.Health >= healthPred then
							minionE = minion
						end
					else
						minionE = minion
					end
				end
			end
		end

		-- Jungle Minions
		if not minionE then
			for k, v in pairs(ObjManager.GetNearby("neutral", "minions")) do
				local minion = v.AsAI
				if ValidMinion(minion) then
					if minion:Distance(pPos) <= spells.Q.Range then
						if minionE then
							local healthPred = HealthPred.GetHealthPrediction(minion, spells.Q.Delay)
							if minionE.Health >= healthPred then
								minionE = minion
							end
						else
							minionE = minion
						end
					end
				end
			end
		end

		if minionE then
			if minionE.Health <= GetEDmg(minionE) then
				CastE(minionE)
				return
			end
		end

	end

end

local function OnHighPriority()

	if not GameIsAvailable() then return end
	if not Orbwalker.CanCast() then return end

	if Menu.Get("Misc.CastEKS") then
		AutoEKS()
	end
	if Menu.Get("Misc.CastRLowHP") then
		AutoRLowHP()
	end

end

local function OnNormalPriority()

	if not GameIsAvailable() then return end
	--if not Orbwalker.CanCast() then return end

	local gameTime = Game.GetTime()
	if gameTime < (lastTick + 0.25) then return end
	lastTick = gameTime

	if IsCloneActive() and Menu.Get("Misc.AutoRFollow") then
		local target = Orbwalker.GetTarget() or TS:GetTarget(1300, false)
		CastR(target)
	end
	
	if Menu.Get("Misc.CastWInitialJg") and spells.W:IsReady() 
		and gameTime >= 50 and gameTime < 90 then
		AutoInitialJg()
	end
	
	-- Combo
	if Orbwalker.GetMode() == "Combo" then
		if Menu.Get("Combo.CastQ") then
			if spells.Q:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(1300 + Player.BoundingRadius, false)
				if target then
					CastQ()
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
				if spells.Ign:IsReady() and not qActive then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Ign.Range + Player.BoundingRadius, true)
					if target and target.Position:Distance(Player.Position) <= (spells.Ign.Range + Player.BoundingRadius) then
						CastIgnite(target)
						return
					end
				end
			end
		end
		if Menu.Get("Combo.CastSmite") then
			if spells.Smite.Slot ~= SpellSlots.Unknown then
				if spells.Smite:IsReady() and not qActive then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Smite.Range + Player.BoundingRadius, true)
					if target and target.Position:Distance(Player.Position) <= (spells.Smite.Range + Player.BoundingRadius) then
						CastSmite(target)
					end
				end
			end
		end
		if Menu.Get("Combo.CastProwler") then
			spells.Prowler.Slot = GetProwlerSlot()
			if spells.Prowler.Slot ~= SpellSlots.Unknown then
				if spells.Prowler:IsReady() then
					local target = Orbwalker.GetTarget() or TS:GetTarget(spells.Prowler.Range + Player.BoundingRadius, true)
					if target and target.Position:Distance(Player.Position) <= (spells.Prowler.Range + Player.BoundingRadius) then
						CastProwler(target)
						return
					end
				end
			end
		end
		if Menu.Get("Combo.CastE") then
			if spells.E:IsReady() and not qActive then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.E.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.E.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastEMinMana") / 100) * Player.MaxMana then
					CastE(target)
					return
				end
			end
		end
		if Menu.Get("Combo.CastR") then
			if spells.R:IsReady() then
				local target = Orbwalker.GetTarget() or TS:GetTarget(spells.R.Range + Player.BoundingRadius, true)
				if target and target.Position:Distance(Player.Position) <= (spells.R.Range + Player.BoundingRadius)
						and Player.Mana >= (Menu.Get("Combo.CastRMinMana") / 100) * Player.MaxMana then
					if Menu.Get("Combo.CastRHail") then
						if hailBuffActive then
							CastR()
						end
					else
						CastR()
					end
					return
				end
			end
		end

		-- Waveclear
	elseif Orbwalker.GetMode() == "Waveclear" then

		Waveclear()

		-- Harass
	elseif Orbwalker.GetMode() == "Harass" then

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

		-- Lasthit
	elseif Orbwalker.GetMode() == "Lasthit" then
		if Menu.Get("Lasthit.CastE") then
			LasthitE()
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

	-- Draw Q Predicted Pos
	if Player:GetSpell(SpellSlots.Q).IsLearned and spells.Q:IsReady() and Menu.Get("Drawing.DrawQPredPos") then

		local mousePos = Renderer.GetMousePos()
		local pPos = Player.Position
		local dist = mousePos:Distance(pPos)

		if dist >= spells.Q.Range then
			Renderer.DrawCircle3D(pPos:Extended(mousePos,400), Player.BoundingRadius, 30, 1.0,
					Menu.Get("Drawing.DrawQPredColor"))
		else
			Renderer.DrawCircle3D(mousePos, Player.BoundingRadius, 30, 1.0,
					Menu.Get("Drawing.DrawQPredColor"))
		end

	end
	
	-- Draw Jungle W Spots
	local gameTime = Game.GetTime()
	if Player:GetSpell(SpellSlots.W).IsLearned and Menu.Get("Drawing.DrawJgSpots") and
		gameTime < 90 then
		for handle, spot in pairs(jgWSpots) do
			Renderer.DrawCircle3D(spot.Position, Player.BoundingRadius, 30, 1.0,
						Menu.Get("Drawing.DrawJgSpotsColor"))
			Renderer.DrawText(spot.Position:ToScreen(), {x=500,y=500}, "Time: " .. spot.Time , Menu.Get("Drawing.DrawJgSpotsColor"))
		end
	end

	-- Draw Killable E
	--if killableEnemies then
	--	for name, heroObj in pairs(killableEnemies) do
	--		local ePos = heroObj.Position:ToScreen()
	--		local msg, color = "E Killable", 0x000000FF
	--		Renderer.DrawFilledRect(ePos, Geometry.Vector(74, 15, 0), 1, 0xFFFFFFFF)
	--		Renderer.DrawText(ePos, {x=500,y=500}, msg, color)
	--	end
	--end

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
		Input.Cast(SpellSlots.W, endPos)
	end
end

local function OnPreAttack(args)

	if qActive and Menu.Get("Misc.CastAAQOnlyBackstab")then
		local pPos = Player.Position
		if args.Target:IsFacing(pPos,90) then
			args.Target = nil
		end
	end
	
	local target = args.Target
	
	if target and target.IsMonster and Menu.Get("Misc.JgBackStab") then
		local pPos = Player.Position
		if args.Target:IsFacing(pPos,90) then
			args.Target = nil
		end
	end
end

local function OnBuffGain(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name

		if buff == "Deceive" then
			qActive = true
		end
		if buff == "ASSETS/Perks/Styles/Domination/HailOfBlades/HailOfBladesBuff.lua" then
			hailBuffActive = true
		end
	end
end

local function OnBuffLost(obj, buffInst)
	if obj.IsMe then
		local buff = buffInst.Name

		if buff == "Deceive" then
			qActive = false
		end
		if buff == "ASSETS/Perks/Styles/Domination/HailOfBlades/HailOfBladesBuff.lua" then
			hailBuffActive = false
		end
	end
end

function OnLoad()

	EventManager.RegisterCallback(Enums.Events.OnHighPriority, OnHighPriority)
	EventManager.RegisterCallback(Enums.Events.OnNormalPriority, OnNormalPriority)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnDrawDamage, OnDrawDamage)
	EventManager.RegisterCallback(Enums.Events.OnGapclose, OnGapclose)
	EventManager.RegisterCallback(Enums.Events.OnPreAttack, OnPreAttack)
	EventManager.RegisterCallback(Enums.Events.OnBuffGain, OnBuffGain)
	EventManager.RegisterCallback(Enums.Events.OnBuffLost, OnBuffLost)

	return true
end
