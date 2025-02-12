--[[
Holdout Example

	Underscore prefix such as "_function()" denotes a local function and is used to improve readability
	
	Variable Prefix Examples
		"fl"	Float
		"n"		Int
		"v"		Table
		"b"		Boolean
]]
DAMAGE_TYPES = {
	    [0] = "DAMAGE_TYPE_NONE",
	    [1] = "DAMAGE_TYPE_PHYSICAL",
	    [2] = "DAMAGE_TYPE_MAGICAL",
	    [4] = "DAMAGE_TYPE_PURE",
	    [7] = "DAMAGE_TYPE_ALL",
	    [8] = "DAMAGE_TYPE_HP_REMOVAL",
	}
require("internal/util")
require("lua_item/simple_item")
require("lua_boss/boss_32_meteor")
require( "epic_boss_fight_game_round" )
require( "epic_boss_fight_game_spawner" )
require('lib.optionsmodule')
require('stats')
require( "libraries/Timers" )
require( "statcollection/init" )

if CHoldoutGameMode == nil then
	CHoldoutGameMode = class({})
end

-- Precache resources
function Precache( context )
	--PrecacheResource( "particle", "particles/generic_gameplay/winter_effects_hero.vpcf", context )
	PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )	
	PrecacheResource( "particle_folder", "particles/frostivus_gameplay", context )

	PrecacheResource( "soundfile", "soundevents/game_sounds_custom.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/music.vsndevts", context)

	PrecacheItemByNameSync( "item_tombstone", context )
	PrecacheItemByNameSync( "item_bag_of_gold", context )
	PrecacheItemByNameSync( "item_slippers_of_halcyon", context )

    PrecacheUnitByNameSync("npc_dota_boss32_trueform", context)
    PrecacheUnitByNameSync("npc_dota_boss32_trueform_h", context)
    PrecacheUnitByNameSync("npc_dota_boss32_trueform_vh", context)

    PrecacheUnitByNameSync("npc_dota_boss12_b", context)
    PrecacheUnitByNameSync("npc_dota_boss12_b_h", context)
    PrecacheUnitByNameSync("npc_dota_boss12_b_vh", context)
    PrecacheUnitByNameSync("npc_dota_boss12_c", context)
    PrecacheUnitByNameSync("npc_dota_boss12_c_vh", context)
    PrecacheUnitByNameSync("npc_dota_boss12_d", context)

end

-- Actually make the game mode when we activate
function Activate()
	GameRules.holdOut = CHoldoutGameMode()
	GameRules.holdOut:InitGameMode()	
	
end

function DeleteAbility( unit)
    for i=0,15,1 do
					local ability = unit:GetAbilityByIndex(i)
					if ability ~= nil then
						ability:Destroy()
					end
				end
end
function TeachAbility( unit, ability_name, level )
    if not level then level = 1 end
        unit:AddAbility(ability_name)
        local ability = unit:FindAbilityByName(ability_name)
        if ability then
            ability:SetLevel(tonumber(level))
            return ability
        end
end
function levelAbility( unit, ability_name, level )
    if not level then level = 1 end
        local ability = unit:FindAbilityByName(ability_name)
        if ability then
            ability:SetLevel(tonumber(level))
            return ability
        end
end

function CHoldoutGameMode:Chalenger()
	local hero = self.chalenger

	if hero:GetHealth() >= 2  then hero:SetHealth (1) end
	return 0.1
end


function CHoldoutGameMode:InitGameMode()
	print ("Epic Boss Fight loaded Version 0.09.01-03")
	print ("Made By FrenchDeath , a noob in coding ")
	print ("Thank to DrTeaSpoon and Noya from Moddota.com for all the help they give :D")
	GameRules._finish = false
	self._nRoundNumber = 1
	self.Last_Target_HB = nil
	self.Shield = false
	self.Last_HP_Display = -1
	self._currentRound = nil
	self._regenround25 = false
	self._regenround13 = false
	self._check_check_dead = false
	self._flLastThinkGameTime = nil
	self._check_dead = false
	self._timetocheck = 0
	self._freshstart = true
	self.boss_master_id = -1
	Life = SpawnEntityFromTableSynchronous( "quest", { 
		name = "Life", 
		title = "#LIFETITLE" } )
	Life._life = 10
	if GetMapName() == "epic_boss_fight_normal" then Life._life = 12 
		GameRules:SetHeroSelectionTime( 90.0 )
		Life._MaxLife = 12
	end
	if GetMapName() == "epic_boss_fight_hard" then Life._life = 9 
		GameRules:SetHeroSelectionTime( 45.0 )
		Life._MaxLife = 9
	end
	if GetMapName() == "epic_boss_fight_impossible" then Life._life = 6 
		GameRules:SetHeroSelectionTime( 30.0 )
		Life._MaxLife = 6
	end
	if GetMapName() == "epic_boss_fight_challenger" then Life._life = 1 
		GameRules:SetHeroSelectionTime( 30.0 )
		Life._MaxLife = 1
	end
	LifeBar = SpawnEntityFromTableSynchronous( "subquest_base", { 
           show_progress_bar = true, 
           progress_bar_hue_shift = -119 
         } )
	Life:AddSubquest( LifeBar )
	GameRules._live = Life._life
	GameRules._used_live = 0
	-- text on the quest timer at start
	Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
	Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._life )

	-- value on the bar
	LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
	LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._life )



	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 7)
	if GetMapName() == "epic_boss_fight_boss_master" then Life._life = 9 
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
		GameRules:SetHeroSelectionTime( 45.0 )
		Life._MaxLife = 9
	else 
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	end


	self:_ReadGameConfiguration()
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( true )


	GameRules:SetTreeRegrowTime( 60.0 )
	GameRules:SetCreepMinimapIconScale( 4 )
	GameRules:SetRuneMinimapIconScale( 1.5 )
	GameRules:SetGoldTickTime( 60.0 )
	GameRules:SetGoldPerTick( 0 )
	GameRules:GetGameModeEntity():SetRemoveIllusionsOnDeath( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	xpTable = {
		0,-- 1
		200,-- 2
		500,-- 3
		900,-- 4
		1400,-- 5
		2000,-- 6
		2600,-- 7
		3200,-- 8
		4400,-- 9
		5400,-- 10
		6000,-- 11
		8200,-- 12
		9000,-- 13
		10400,-- 14
		11900,-- 15
		13500,-- 16
		15200,-- 17
		17000,-- 18
		18900,-- 19
		20900,-- 20
		23000,-- 21
		25200,-- 22
		27500,-- 23
		29900,-- 24
		32400, -- 25
		40000, -- 26
		50000, -- 27
		65000, -- 28
		80000, -- 29
		100000, -- 30
		125000, -- 31
		150000, -- 32
		175000, -- 33
		200000, -- 34
		250000, -- 35
		300000, -- 36
		350000, --37
		400000, --38
		500000, --39
		600000, --40
		700000, --41
		800000, --42
		1000000, --43
		1500000, --44
		2000000, --45
		3000000, --46
		4000000, --47
		5000000, --48
		6000000, --49
		7000000, --50
		8000000, --51
		9000000, --52
		10000000, --53
		11000000, --54
		12000000, --55
		13000000, --56
		14000000, --57
		15000000, --58
		16000000, --59
		17000000, --60
		18000000, --61
		19000000, --62
		20000000, --63
		22500000, --64
		25000000, --65
		30000000, --66
		35000000, --67
		40000000, --68
		45000000, --69
		50000000, --70
		55000000, --71
		60000000, --72
		70000000, --73
		80000000, --74
		100000000 --75
	}

	GameRules:GetGameModeEntity():SetUseCustomHeroLevels( true )
    GameRules:GetGameModeEntity():SetCustomHeroMaxLevel( 75 )
    GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel( xpTable )
	-- Custom console commands
	Convars:RegisterCommand( "holdout_test_round", function(...) return self:_TestRoundConsoleCommand( ... ) end, "Test a round of holdout.", FCVAR_CHEAT )
	Convars:RegisterCommand( "holdout_spawn_gold", function(...) return self._GoldDropConsoleCommand( ... ) end, "Spawn a gold bag.", FCVAR_CHEAT )
	Convars:RegisterCommand( "ebf_cheat_drop_gold_bonus", function(...) return self._GoldDropCheatCommand( ... ) end, "Cheat gold had being detected !",0)
	Convars:RegisterCommand( "ebf_gold", function(...) return self._Goldgive( ... ) end, "hello !",0)
	Convars:RegisterCommand( "ebf_max_level", function(...) return self._LevelGive( ... ) end, "hello !",0)
	Convars:RegisterCommand( "ebf_drop", function(...) return self._ItemDrop( ... ) end, "hello",0)
	Convars:RegisterCommand( "steal_game", function(...) return self._fixgame( ... ) end, "look like someone try to steal my map :D",0)
	Convars:RegisterCommand( "holdout_status_report", function(...) return self:_StatusReportConsoleCommand( ... ) end, "Report the status of the current holdout game.", FCVAR_CHEAT )

	-- Hook into game events allowing reload of functions at run time
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CHoldoutGameMode, "OnGameRulesStateChange" ), self )
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap( CHoldoutGameMode, "OnHeroPick"), self )
	ListenToGameEvent('player_connect_full', Dynamic_Wrap( CHoldoutGameMode, 'OnConnectFull'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(CHoldoutGameMode, 'OnAbilityUsed'), self)

	CustomGameEventManager:RegisterListener('Boss_Master', Dynamic_Wrap( CHoldoutGameMode, 'Boss_Master'))
	CustomGameEventManager:RegisterListener('mute_sound', Dynamic_Wrap( CHoldoutGameMode, 'mute_sound'))
	CustomGameEventManager:RegisterListener('unmute_sound', Dynamic_Wrap( CHoldoutGameMode, 'unmute_sound'))
	CustomGameEventManager:RegisterListener('Health_Bar_Command', Dynamic_Wrap( CHoldoutGameMode, 'Health_Bar_Command'))




	-- Register OnThink with the game engine so it is called every 0.25 seconds
	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( CHoldoutGameMode, "FilterDamage" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 ) 
	GameRules:GetGameModeEntity():SetThink( "Update_Health_Bar", self, 0.09 ) 
end

function CHoldoutGameMode:Health_Bar_Command (event)
 	local ID = event.pID
 	local player = PlayerResource:GetPlayer(ID)
 	print (event.Enabled)
 	if event.Enabled == 0 then
 		player.HB = false
 		player.Health_Bar_Open = false
 	else
 		player.HB = true
 	end
end

function CHoldoutGameMode:Update_Health_Bar()
		local higgest_ennemy_hp = 0
		local biggest_ennemy = nil
		for _,unit in pairs ( Entities:FindAllByName( "npc_dota_creature")) do
			if unit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
				if unit:GetMaxHealth() > higgest_ennemy_hp and unit:IsAlive() then
					biggest_ennemy = unit
					higgest_ennemy_hp = unit:GetMaxHealth()
				end
			end
		end
		if self.Last_Target_HB ~= biggest_ennemy and biggest_ennemy ~= nil then
			if self.Last_Target_HB ~= nil then
				ParticleManager:DestroyParticle(self.Last_Target_HB.HB_particle, false)
			end
			self.Last_Target_HB = biggest_ennemy
			self.Last_Target_HB.HB_particle = ParticleManager:CreateParticle("particles/health_bar_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW   , self.Last_Target_HB)
            ParticleManager:SetParticleControl(self.Last_Target_HB.HB_particle, 0, self.Last_Target_HB:GetAbsOrigin())
            ParticleManager:SetParticleControl(self.Last_Target_HB.HB_particle, 1, self.Last_Target_HB:GetAbsOrigin())
		end
		Timers:CreateTimer(0.1,function()
			if biggest_ennemy ~= nil and biggest_ennemy:IsAlive() then
				local table_arg = {}
				table_arg.total_life = biggest_ennemy:GetMaxHealth()
				table_arg.current_life = biggest_ennemy:GetHealth()
				table_arg.total_mana = biggest_ennemy:GetMaxMana()
				table_arg.current_mana = biggest_ennemy:GetMana()
				table_arg.name = biggest_ennemy:GetUnitName()
				if self.Last_HP_Display ~= table_arg.current_life then
					self.Last_HP_Display = table_arg.current_life
					CustomGameEventManager:Send_ServerToAllClients("Update_Health_Bar", table_arg)
				end
				if table_arg.total_mana ~= 0 then
					CustomGameEventManager:Send_ServerToAllClients("Update_mana_Bar", table_arg)
				end
				if self.Shield == false and biggest_ennemy.have_shield == true then
					self.Shield = true
					CustomGameEventManager:Send_ServerToAllClients("activate_shield", {})
				elseif	self.Shield == true and biggest_ennemy.have_shield ~= true then 
					self.Shield = false
					CustomGameEventManager:Send_ServerToAllClients("disactivate_shield", {})
				end
				for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
					if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
						if PlayerResource:HasSelectedHero( nPlayerID ) then
							local player = PlayerResource:GetPlayer(nPlayerID)
							if player.HB == true and player.Health_Bar_Open == false then
								player.Health_Bar_Open = true
								CustomGameEventManager:Send_ServerToPlayer(player,"Open_Health_Bar", {})
							end
						end
					end
				end
			else
				for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
					if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
						if PlayerResource:HasSelectedHero( nPlayerID ) then
							local player = PlayerResource:GetPlayer(nPlayerID)
							if player.HB == true and player.Health_Bar_Open == true then
								player.Health_Bar_Open = false
								CustomGameEventManager:Send_ServerToPlayer(player,"Close_Health_Bar", {})
							end
						end
					end
				end
			end
		end)

	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
		return nil
	end
	return 0.09
end


function increase_damage_player(ID,Damage)
	
end

function CHoldoutGameMode:FilterDamage( filterTable )
    --[[for k, v in pairs( filterTable ) do
      print("Damage: " .. k .. " " .. tostring(v) )
    end]]
    local total_damage_team = 0
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end

    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local damagetype = filterTable["damagetype_const"]

   
    local damage = filterTable["damage"] --Post reduction
    local attackerID = attacker:GetPlayerOwnerID()
    if attackerID and PlayerResource:HasSelectedHero( attackerID ) then
	    local hero = PlayerResource:GetSelectedHeroEntity(attackerID)
	    local player = PlayerResource:GetPlayer(attackerID)
	    hero.damageDone = math.floor(hero.damageDone + damage)
	    local dps = math.ceil(hero.damageDone/GameRules:GetGameTime())
	   	CustomGameEventManager:Send_ServerToPlayer(player,"Update_Damage", {damage = hero.damageDone , dps = dps})
    end
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
				total_damage_team = hero.damageDone + total_damage_team
			end
		end
	end
    CustomGameEventManager:Send_ServerToAllClients("Update_Damage_Team", {team = total_damage_team})


    return true
end
function GetHeroDamageDone(hero)
    return hero.damageDone
end

function CHoldoutGameMode:OnAbilityUsed(keys)
	--will be used in future :p
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityname = keys.abilityname
	print (abilityname)
end

function CHoldoutGameMode:OnHeroPick (event)
 	local hero = EntIndexToHScript(event.heroindex)
 	if hero:GetName() == "npc_dota_hero_invoker" then levelAbility( hero, "invoker_reset", 1) end
	hero:RemoveAbility('attribute_bonus')
	hero:AddItemByName("npc_dota_courier")
	hero.damageDone = 0
	hero.Ressurect = 0
	stats:ModifyStatBonuses(hero)
	hero:AddAbility('lua_attribute_bonus')
	local ID = hero:GetPlayerID()
	hero:SetGold(0 , false)
	hero:SetGold(0 , true)
	local player = PlayerResource:GetPlayer(ID)
 	player.HB = true
 	player.Health_Bar_Open = false
	if PlayerResource:GetSteamAccountID( ID ) == 42452574 then
		print ("look like maker of map is here :D")
		message_creator = true
	end 
	--[[if PlayerResource:GetSteamAccountID( ID ) == 86736807 then
		print ("look like a chalenger is here :D")
		message_chalenger = true
		self.chalenger = hero
		GameRules:GetGameModeEntity():SetThink( "Chalenger", self, 0.25 ) 
	end]]
	if PlayerResource:GetSteamAccountID( ID ) == 25195578 then
		print ("look like a naughty guy is here :D")
		message_chalenger = true
		self.chalenger = hero
		GameRules:GetGameModeEntity():SetThink( "Chalenger", self, 0.1 ) 
	end
	if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
		DeleteAbility(hero)
		TeachAbility (hero , "hide_hero")
		hero:AddNoDraw()
		self.boss_master_id = ID
    end
end

function CHoldoutGameMode:mute_sound (event)
 	local ID = event.pID
 	local player = PlayerResource:GetPlayer(ID)
 	StopSoundOn("music.music",player)
 	player.NoMusic = true
end
function CHoldoutGameMode:unmute_sound (event)
 	local ID = event.pID
 	local player = PlayerResource:GetPlayer(ID)
 	player:SetMusicStatus(DOTA_MUSIC_STATUS_NONE, 0)
 	EmitSoundOnClient("music.music",player)
 	player.NoMusic = false
end

function CHoldoutGameMode:Boss_Master (event)
 	local ID = event.pID
 	local commandname = event.Command
 	local player = PlayerResource:GetPlayer(ID)
 	if commandname == "magic_immunity_1" then

 	elseif commandname == "magic_immunity_2" then

 	elseif commandname == "damage_immunity" then

 	elseif commandname == "double_damage" then

 	elseif commandname == "quad_damage" then

 	end
 	
end


-- Read and assign configurable keyvalues if applicable
function CHoldoutGameMode:_ReadGameConfiguration()
	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	kv = kv or {} -- Handle the case where there is not keyvalues file

	self._bAlwaysShowPlayerGold = kv.AlwaysShowPlayerGold or false
	self._bRestoreHPAfterRound = kv.RestoreHPAfterRound or false
	self._bRestoreMPAfterRound = kv.RestoreMPAfterRound or false
	self._bRewardForTowersStanding = kv.RewardForTowersStanding or false
	self._bUseReactiveDifficulty = kv.UseReactiveDifficulty or false

	self._flPrepTimeBetweenRounds = tonumber( kv.PrepTimeBetweenRounds or 0 )
	self._flItemExpireTime = tonumber( kv.ItemExpireTime or 10.0 )

	self:_ReadRandomSpawnsConfiguration( kv["RandomSpawns"] )
	self:_ReadLootItemDropsConfiguration( kv["ItemDrops"] )
	self:_ReadRoundConfigurations( kv )
end

-- Verify spawners if random is set
function CHoldoutGameMode:OnConnectFull()
	SendToServerConsole("dota_combine_models 0")
    SendToConsole("dota_combine_models 0") 
    SendToServerConsole("dota_health_per_vertical_marker 1000")
end

function CHoldoutGameMode:ChooseRandomSpawnInfo()
	if #self._vRandomSpawnsList == 0 then
		error( "Attempt to choose a random spawn, but no random spawns are specified in the data." )
		return nil
	end
	return self._vRandomSpawnsList[ RandomInt( 1, #self._vRandomSpawnsList ) ]
end

-- Verify valid spawns are defined and build a table with them from the keyvalues file
function CHoldoutGameMode:_ReadRandomSpawnsConfiguration( kvSpawns )
	self._vRandomSpawnsList = {}
	if type( kvSpawns ) ~= "table" then
		return
	end
	for _,sp in pairs( kvSpawns ) do			-- Note "_" used as a shortcut to create a temporary throwaway variable
		table.insert( self._vRandomSpawnsList, {
			szSpawnerName = sp.SpawnerName or "",
			szFirstWaypoint = sp.Waypoint or ""
		} )
	end
end


-- If random drops are defined read in that data
function CHoldoutGameMode:_ReadLootItemDropsConfiguration( kvLootDrops )
	self._vLootItemDropsList = {}
	if type( kvLootDrops ) ~= "table" then
		return
	end
	for _,lootItem in pairs( kvLootDrops ) do
		table.insert( self._vLootItemDropsList, {
			szItemName = lootItem.Item or "",
			nChance = tonumber( lootItem.Chance or 0 )
		})
	end
end


-- Set number of rounds without requiring index in text file
function CHoldoutGameMode:_ReadRoundConfigurations( kv )
	self._vRounds = {}
	while true do
		local szRoundName = string.format("Round%d", #self._vRounds + 1 )
		local kvRoundData = kv[ szRoundName ]
		if kvRoundData == nil then
			return
		end
		local roundObj = CHoldoutGameRound()
		roundObj:ReadConfiguration( kvRoundData, self, #self._vRounds + 1 )
		table.insert( self._vRounds, roundObj )
	end
end


-- When game state changes set state in script
function CHoldoutGameMode:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get()
	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		if GetMapName() ~= "epic_boss_fight_challenger" then
			ShowGenericPopup( "#holdout_instructions_title", "#holdout_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
		else
			ShowGenericPopup( "#holdout_instructions_title_challenger", "#holdout_instructions_body_challenger", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
		end
	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			local player = PlayerResource:GetPlayer(nPlayerID)
			if player ~= nil then
				print ("play music")
				Timers:CreateTimer(0.1,function()
								if player.NoMusic ~= true then
									print ("replay music")
									EmitSoundOnClient("music.music",player)
									return 480
								end
							end)
				self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
			end
		end
	end
end

function CHoldoutGameMode:_regenlifecheck()
	if self._regenround25 == false and self._nRoundNumber >= 26 then
		self._regenround25 = true
		local messageinfo = {
		message = "One life has been gained , you just hit a checkpoint !",
		duration = 5
		}
		SendToServerConsole("dota_health_per_vertical_marker 100000")
		FireGameEvent("show_center_message",messageinfo)   
		self._checkpoint = 26
		Life._MaxLife = Life._MaxLife + 1
		Life._life = Life._life + 1
		GameRules._live = Life._life
		Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
   		Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
		-- value on the bar
		LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
		LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
	end
	if self._regenround13 == false and self._nRoundNumber >= 14 then
		self._regenround13 = true
		local messageinfo = {
		message = "One life has been gained , you just hit a checkpoint !",
		duration = 5
		}
		SendToConsole("dota_combine_models 0")
		SendToServerConsole("dota_health_per_vertical_marker 10000")
		FireGameEvent("show_center_message",messageinfo)   
		self._checkpoint = 14
		Life._MaxLife = Life._MaxLife + 1
		Life._life = Life._life + 1
		GameRules._live = Life._life
		Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
   		Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
		-- value on the bar
		LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
		LifeBar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, Life._MaxLife )
	end
end

function CHoldoutGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:_CheckForDefeat()
		self:_ThinkLootExpiry()
		self:_regenlifecheck()
		if self._flPrepTimeEnd ~= nil then
			self:_ThinkPrepTime()
		elseif self._currentRound ~= nil then
			self._currentRound:Think()
			if self._currentRound:IsFinished() then 
				self._currentRound:End()
				self._currentRound = nil
				-- Heal all players
				self:_RefreshPlayers()
				self._nRoundNumber = self._nRoundNumber + 1
				simple_item:SetRoundNumer(self._nRoundNumber)
				boss_meteor:SetRoundNumer(self._nRoundNumber)
				GameRules._roundnumber = self._nRoundNumber
				if self._nRoundNumber > #self._vRounds then
					self._nRoundNumber = 1
					SendToConsole("dota_health_per_vertical_marker 250")
					GameRules:SetCustomVictoryMessage ("Congratulation!")
					GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
					GameRules._finish = true
				else
					self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
				end
			end
		end
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
		return nil
	end
	return 0.25
end

function CHoldoutGameMode:_RefreshPlayers()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if hero ~=nil then
					if not hero:IsAlive() then
						hero:RespawnUnit()
					end
					hero:SetHealth( hero:GetMaxHealth() )
					hero:SetMana( hero:GetMaxMana() )
				end
			end
		end
	end
end


function CHoldoutGameMode:_CheckForDefeat()
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return
	end
	local AllRPlayersDead = true
	local PlayerNumberRadiant = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			PlayerNumberRadiant = PlayerNumberRadiant + 1
			if not PlayerResource:HasSelectedHero( nPlayerID ) and self._nRoundNumber == 1 and self._currentRound == nil then
				AllRPlayersDead = false
			elseif PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if hero and hero:IsAlive() then
					AllRPlayersDead = false
				end
			end
		end
	end


	if AllRPlayersDead and PlayerNumberRadiant>0 then 
		if self._entPrepTimeQuest then
			self:_RefreshPlayers()
			return
		end
		print (self._check_dead)
		print (self._check_check_dead)
		if self._check_dead == false then
			self._check_check_dead = false
			Timers:CreateTimer(2.0,function()
				if self._check_check_dead == false then
					self._check_dead = true
				else
					self._check_check_dead = false
				end
			end)
		end
		if self._check_dead == true and Life._life > 0 then
			if self._currentRound ~= nil then
				self._currentRound:End()
				self._currentRound = nil
			end
			self._flPrepTimeEnd = GameRules:GetGameTime() + 20
			Life._life = Life._life - 1
			GameRules._live = Life._life
			GameRules._used_live = GameRules._used_live + 1 
			Life:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
   			LifeBar:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Life._life )
			self._check_dead = false
			for _,unit in pairs ( Entities:FindAllByName( "npc_dota_creature")) do
				if unit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
					unit:ForceKill(true)
				end
			end
			for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
				if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
					local totalgold = unit:GetGold() + ((((self._nRoundNumber/1.5)+5)/((Life._life/2) +0.5))*500)
		            unit:SetGold(0 , false)
		            unit:SetGold(totalgold, true)
	        	end
			end
			if delay ~= nil then
				self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
			end
			self:_RefreshPlayers()
		else
			self._check_dead = false
		end
	end
	if PlayerNumberRadiant == 0 or Life._life == 0 then
		self:_OnLose()
	end
end


function CHoldoutGameMode:_OnLose()
	--[[Say(nil,"You just lose all your life , a vote start to chose if you want to continue or not", false)
	if self._checkpoint == 14 then
		Say(nil,"if you continue you will come back to round 13 , you keep all the current item and gold gained", false)
	elif self._checkpoint == 26 then
		Say(nil,"if you continue you will come back to round 25 , you keep all the current item and gold gained", false)
	elseif self._checkpoint == 46 then
		Say(nil,"if you continue you will come back to round 45 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 61 then
		Say(nil,"if you continue you will come back to round 60 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 76 then
		Say(nil,"if you continue you will come back to round 75 , you keep with all the current item and gold gained", false)
	elseif self._checkpoint == 91 then
		Say(nil,"if you continue you will come back to round 90 , you keep with all the current item and gold gained", false)
	else
		Say(nil,"if you continue you will come back to round begin and have all your money and item erased", false)
	end
	Say(nil,"If you want to retry , type YES in thes chat if you don't want type no , no vote will be taken as a yes", false)
	Say(nil,"At least Half of the player have to vote yes for game to restart on last check points", false)]]
	SendToConsole("dota_health_per_vertical_marker 250")
	GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
end


function CHoldoutGameMode:_ThinkPrepTime()
	if GameRules:GetGameTime() >= self._flPrepTimeEnd then
		self._flPrepTimeEnd = nil
		if self._entPrepTimeQuest then
			UTIL_RemoveImmediate( self._entPrepTimeQuest )
			self._entPrepTimeQuest = nil
		end

		if self._nRoundNumber > #self._vRounds then
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			Say(nil,"If you wish you can support me on patron (link in description of the gamemode), anyways, thank for playing <3", false)
			return false
		end
		self._currentRound = self._vRounds[ self._nRoundNumber ]
		self._currentRound:Begin()
		return
	end

	if not self._entPrepTimeQuest then
		self._entPrepTimeQuest = SpawnEntityFromTableSynchronous( "quest", { name = "PrepTime", title = "#DOTA_Quest_Holdout_PrepTime" } )
		self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
		self._entPrepTimeQuest:SetTextReplaceString( self:GetDifficultyString() )
		self:_RefreshPlayers()
		self._vRounds[ self._nRoundNumber ]:Precache()
	end
	self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._flPrepTimeEnd - GameRules:GetGameTime() )
end

function CHoldoutGameMode:_ThinkLootExpiry()
	if self._flItemExpireTime <= 0.0 then
		return
	end

	local flCutoffTime = GameRules:GetGameTime() - self._flItemExpireTime

	for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop")) do
		local containedItem = item:GetContainedItem()
		if containedItem:GetAbilityName() == "item_bag_of_gold" or item.Holdout_IsLootDrop then
			self:_ProcessItemForLootExpiry( item, flCutoffTime )
		end
	end
end


function CHoldoutGameMode:_ProcessItemForLootExpiry( item, flCutoffTime )
	if item:IsNull() then
		return false
	end
	if item:GetCreationTime() >= flCutoffTime then
		return true
	end

	local containedItem = item:GetContainedItem()
	if containedItem and containedItem:GetAbilityName() == "item_bag_of_gold" then
		if self._currentRound and self._currentRound.OnGoldBagExpired then
			self._currentRound:OnGoldBagExpired()
		end
	end

	local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, item )
	ParticleManager:SetParticleControl( nFXIndex, 0, item:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )
	local inventoryItem = item:GetContainedItem()
	if inventoryItem then
		UTIL_RemoveImmediate( inventoryItem )
	end
	UTIL_RemoveImmediate( item )
	return false
end


function CHoldoutGameMode:GetDifficultyString()
	local nDifficulty = PlayerResource:GetTeamPlayerCount()
	if nDifficulty > 10 then
		return string.format( "(+%d)", nDifficulty )
	elseif nDifficulty > 0 then
		return string.rep( "+", nDifficulty )
	else
		return ""
	end
end


function CHoldoutGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end

	-- Attach client side hero effects on spawning players

	if spawnedUnit:IsCreature() then
		spawnedUnit:SetHPGain( spawnedUnit:GetMaxHealth() * 0.3 ) -- LEVEL SCALING VALUE FOR HP
		spawnedUnit:SetManaGain( 0 )
		spawnedUnit:SetHPRegenGain( 0 )
		spawnedUnit:SetManaRegenGain( 0 )
		if spawnedUnit:IsRangedAttacker() then
			spawnedUnit:SetDamageGain( ( ( spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin() ) / 2 ) * 0.1 ) -- LEVEL SCALING VALUE FOR DPS
		else
			spawnedUnit:SetDamageGain( ( ( spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin() ) / 2 ) * 0.2 ) -- LEVEL SCALING VALUE FOR DPS
		end
		spawnedUnit:SetArmorGain( 0 )
		spawnedUnit:SetMagicResistanceGain( 0 )
		spawnedUnit:SetDisableResistanceGain( 0 )
		spawnedUnit:SetAttackTimeGain( 0 )
		spawnedUnit:SetMoveSpeedGain( 0 )
		spawnedUnit:SetBountyGain( 0 )
		spawnedUnit:SetXPGain( 0 )
		spawnedUnit:CreatureLevelUp( PlayerResource:GetTeamPlayerCount()  )
		if spawnedUnit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
			Timers:CreateTimer(0.1,function()
				spawnedUnit:SetOwner(PlayerResource:GetSelectedHeroEntity(self.boss_master_id))
				spawnedUnit:SetControllableByPlayer(self.boss_master_id,true)
			end)
		end
	end
end


-- Attach client-side hero effects for a reconnecting player
function CHoldoutGameMode:OnPlayerReconnected( event )
	local nReconnectedPlayerID = event.PlayerID
	for _,hero in pairs( Entities:FindAllByClassname( "npc_dota_hero" ) ) do
		if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			if hero:IsRealHero() then
				self:_SpawnHeroClientEffects( hero, nReconnectedPlayerID )
			end
			self._DisconnectedPlayer = self._DisconnectedPlayer - 1
		end
	end
end


function CHoldoutGameMode:OnEntityKilled( event )
	local check_tombstone = true
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	if killedUnit and killedUnit:IsRealHero() then
		for itemSlot = 0, 5, 1 do
	        local Item = killedUnit:GetItemInSlot( itemSlot )
	        if Item ~= nil and Item:GetName() == "item_ressurection_stone" and Item:IsCooldownReady() then
	            	self._check_check_dead = true
	            	check_tombstone = false
	            	self._check_dead = false
	            	if Life._life == 1 then
	            		AllRPlayersDead = false
	            	end
	        end
	    end
	    if killedUnit:GetName() == ( "npc_dota_hero_skeleton_king") then
			local ability = killedUnit:FindAbilityByName("skeleton_king_reincarnation")
			local reincarnation_CD = 0
			local reincarnation_CD_total = 0
			local reincarnation_level = 0
			reincarnation_CD = ability:GetCooldownTimeRemaining()
			reincarnation_level = ability:GetLevel()
			reincarnation_CD_total = ability:GetCooldown(reincarnation_level-1)
			for itemSlot = 0, 5, 1 do
	            local Item = killedUnit:GetItemInSlot( itemSlot )
	            if Item ~= nil and Item:GetName() == "item_octarine_core" then
	            	reincarnation_CD_total = reincarnation_CD_total*0.75
	            end
	            if Item ~= nil and Item:GetName() == "item_octarine_core2" then
	            	reincarnation_CD_total = reincarnation_CD_total*0.67
	            end
	            if Item ~= nil and Item:GetName() == "item_octarine_core3" then
	            	reincarnation_CD_total = reincarnation_CD_total*0.5
	             end
	            if Item ~= nil and Item:GetName() == "item_octarine_core4" then
	            	reincarnation_CD_total = reincarnation_CD_total*0.33
	            end
	        end
			print (reincarnation_CD)
			print (reincarnation_CD_total)
			if reincarnation_level >= 1 and reincarnation_CD >= reincarnation_CD_total - 5 then
				AllRPlayersDead = false
				check_tombstone = false
				self._check_dead = false
				self._check_check_dead = true
				if reincarnation_level < 6 then
					Timers:CreateTimer(2,function()
						killedUnit:RespawnUnit()
						killedUnit:SetHealth( killedUnit:GetMaxHealth() )
						killedUnit:SetMana( killedUnit:GetMaxMana() )
					end)
				end
				if reincarnation_level >= 6 then
					for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
						if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
							Timers:CreateTimer(2,function()
								if not unit:IsAlive() then 
									unit:RespawnUnit()
								end
								unit:SetHealth( unit:GetMaxHealth() )
								unit:SetMana( unit:GetMaxMana() )
							end)
						end
					end
				end
			end
		end	
		if GetMapName() ~= "epic_boss_fight_challenger" then
			if check_tombstone == true and killedUnit.NoTombStone ~= true then
				local newItem = CreateItem( "item_tombstone", killedUnit, killedUnit )
				newItem:SetPurchaseTime( 0 )
				newItem:SetPurchaser( killedUnit )
				local tombstone = SpawnEntityFromTableSynchronous( "dota_item_tombstone_drop", {} )
				tombstone:SetContainedItem( newItem )
				tombstone:SetAngles( 0, RandomFloat( 0, 360 ), 0 )
				FindClearSpaceForUnit( tombstone, killedUnit:GetAbsOrigin(), true )	
			end
		end
	end
end

function CHoldoutGameMode:CheckForLootItemDrop( killedUnit )
	for _,itemDropInfo in pairs( self._vLootItemDropsList ) do
		if RollPercentage( itemDropInfo.nChance ) then
			local newItem = CreateItem( itemDropInfo.szItemName, nil, nil )
			newItem:SetPurchaseTime( 0 )
			local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
			drop.Holdout_IsLootDrop = true
		end
	end
end

-- Leveling/gold data for console command "holdout_test_round"
XP_PER_LEVEL_TABLE = {
		0,-- 1
		200,-- 2
		500,-- 3
		900,-- 4
		1400,-- 5
		2000,-- 6
		2600,-- 7
		3200,-- 8
		4400,-- 9
		5400,-- 10
		6000,-- 11
		8200,-- 12
		9000,-- 13
		10400,-- 14
		11900,-- 15
		13500,-- 16
		15200,-- 17
		17000,-- 18
		18900,-- 19
		20900,-- 20
		23000,-- 21
		25200,-- 22
		27500,-- 23
		29900,-- 24
		32400, -- 25
		40000, -- 26
		50000, -- 27
		65000, -- 28
		80000, -- 29
		100000, -- 30
		125000, -- 31
		150000, -- 32
		175000, -- 33
		200000, -- 34
		250000, -- 35
		300000, -- 36
		350000, --37
		400000, --38
		500000, --39
		600000, --40
		700000, --41
		800000, --42
		1000000, --43
		1500000, --44
		2000000, --45
		2500000, --46
		3000000, --47
		3500000, --48
		4000000, --49
		4500000, --50
		5000000, --51
		6000000, --52
		7000000, --53
		8000000, --54
		9000000, --55
		1000000, --56
		1100000, --57
		1200000, --58
		1300000, --59
		1400000, --60
		1500000, --61
		1750000, --62
		2000000, --63
		2250000, --64
		2500000, --65
		3000000, --66
		3500000, --67
		4000000, --68
		4500000, --69
		5000000, --70
		5500000, --71
		6000000, --72
		7000000, --73
		8000000, --74
		10000000 --75
	}





-- Custom game specific console command "holdout_test_round"
function CHoldoutGameMode:_TestRoundConsoleCommand( cmdName, roundNumber, delay )
	local nRoundToTest = tonumber( roundNumber )
	print (string.format( "Testing round %d", nRoundToTest ) )
	if nRoundToTest <= 0 or nRoundToTest > #self._vRounds then
		Msg( string.format( "Cannot test invalid round %d", nRoundToTest ) )
		return
	end


	local nExpectedGold = 0
	local nExpectedXP = 0
	for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
		if PlayerResource:IsValidPlayer( nPlayerID ) then
			PlayerResource:SetBuybackCooldownTime( nPlayerID, 0 )
			PlayerResource:SetBuybackGoldLimitTime( nPlayerID, 0 )
			PlayerResource:ResetBuybackCostTime( nPlayerID )
		end
	end

	if self._entPrepTimeQuest then
		UTIL_RemoveImmediate( self._entPrepTimeQuest )
		self._entPrepTimeQuest = nil
	end

	if self._currentRound ~= nil then
		self._currentRound:End()
		self._currentRound = nil
	end

	for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop")) do
		local containedItem = item:GetContainedItem()
		if containedItem then
			UTIL_RemoveImmediate( containedItem )
		end
		UTIL_RemoveImmediate( item )
	end

	self._flPrepTimeEnd = GameRules:GetGameTime() + 15
	self._nRoundNumber = nRoundToTest
	print(self._nRoundNumber)
	if delay ~= nil then
		self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
	end
end

function CHoldoutGameMode:_GoldDropConsoleCommand( cmdName, goldToDrop )
	local newItem = CreateItem( "item_bag_of_gold", nil, nil )
	newItem:SetPurchaseTime( 0 )
	if goldToDrop == nil then goldToDrop = 99999 end
	newItem:SetCurrentCharges( goldToDrop )
	local spawnPoint = Vector( 0, 0, 0 )
	local heroEnt = PlayerResource:GetSelectedHeroEntity( 0 )
	if heroEnt ~= nil then
		spawnPoint = heroEnt:GetAbsOrigin()
	end
	local drop = CreateItemOnPositionSync( spawnPoint, newItem )
	newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
end

function CHoldoutGameMode:_GoldDropCheatCommand( cmdName, goldToDrop)
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:GetSteamAccountID( nPlayerID ) == 42452574 then
				print ("Cheat gold activate")
				local newItem = CreateItem( "item_bag_of_gold", nil, nil )
				newItem:SetPurchaseTime( 0 )
				if goldToDrop == nil then goldToDrop = 99999 end
				newItem:SetCurrentCharges( goldToDrop )
				local spawnPoint = Vector( 0, 0, 0 )
				local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if heroEnt ~= nil then
					spawnPoint = heroEnt:GetAbsOrigin()
				end
				local drop = CreateItemOnPositionSync( spawnPoint, newItem )
				newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
			else 
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_Goldgive( cmdName, golddrop , ID)
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:GetSteamAccountID( nPlayerID ) == 42452574 then
				if ID == nil then ID = nPlayerID end
				if golddrop == nil then golddrop = 99999 end
				PlayerResource:GetSelectedHeroEntity(ID):SetGold(golddrop, true)
			else 
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_LevelGive( cmdName, golddrop , ID)
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:GetSteamAccountID( nPlayerID ) == 42452574 then
				if ID == nil then ID = nPlayerID end
				if golddrop == nil then golddrop = 99999 end
				local hero = PlayerResource:GetSelectedHeroEntity(ID)
				for i=0,74,1 do
					hero:HeroLevelUp(false)
				end
				hero:SetAbilityPoints(0) 
				for i=0,15,1 do
					local ability = hero:GetAbilityByIndex(i)
					if ability ~= nil then
						ability:SetLevel(ability:GetMaxLevel() )
					end
				end
			else 
				print ("look like someone try to cheat without know what he's doing hehe")
			end
		end
	end
end
function CHoldoutGameMode:_ItemDrop(item_name)
	if item_name ~= nil then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
				if PlayerResource:GetSteamAccountID( nPlayerID ) == 42452574 then
					print ("master had dropped an item")
					local newItem = CreateItem( item_name, nil, nil )
					if newItem == nil then newItem = "item_heart_divine" end
					local spawnPoint = Vector( 0, 0, 0 )
					local heroEnt = PlayerResource:GetSelectedHeroEntity( nPlayerID )
					if heroEnt ~= nil then
						heroEnt:AddItemByName(item_name)
					else
						local drop = CreateItemOnPositionSync( spawnPoint, newItem )
						newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
					end
				else 
					print ("look like someone try to cheat without know what he's doing hehe")
				end
			end
		end
	end
end
function CHoldoutGameMode:_fixgame(item_name)
	if item_name ~= nil then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
				if PlayerResource:GetSteamAccountID( nPlayerID ) == 42452574 then
					print ("master is not happy , someone is a stealer :D")
					for _,unit in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
						for itemSlot = 0, 5, 1 do
		            		local Item = unit:GetItemInSlot( itemSlot )
		            		unit:RemoveItem(Item)
		            	end
		            end
					print ("Master frenchDeath has ruined the game , now he gonna leave :D, FUCK YOU MOD STEALER !")
				else 
					print ("you don't have acces to this kid")
				end
			end
		end
	end
end


function CHoldoutGameMode:_StatusReportConsoleCommand( cmdName )
	print( "*** Holdout Status Report ***" )
	print( string.format( "Current Round: %d", self._nRoundNumber ) )
	if self._currentRound then
		self._currentRound:StatusReport()
	end
	print( "*** Holdout Status Report End *** ")
end