print("Fantasy (Midgard) using Lua events")
print("For techs to work properly, you may need to paste the midgard rules.txt into the Fantasy folder,")
print("then start a Fantasy game before starting a Midgard game")
print("(No idea why this is, maybe a TOTPP 0.17 bug?)")

local VERSION = "original"

local eventsPath = string.gsub(debug.getinfo(1).source, "@", "")
local scenarioFolderPath = string.gsub(eventsPath, "events.lua", "?.lua")
if string.find(package.path, scenarioFolderPath, 1, true) == nil then
	 package.path = package.path .. ";" .. scenarioFolderPath
end

local civlua = require("civlua")
local func = require("functions")
-- debug mode is indicated by the presence of a debug.lua file
-- local isDebug, debugFuncs = pcall(require, "debug_" .. VERSION)

local INFOKEY = 211 -- tab
local DEBUGKEY = 214 -- backspace

local MAPS = {
	surface = civ.getMap(0),
	underwater = civ.getMap(1),
	underworld = civ.getMap(2),
	cloudworld = civ.getMap(3)
}

local BASETERRAIN = {
	surface = {
		oldForest = civ.getBaseTerrain(0, 3),
		iceBarrens = civ.getBaseTerrain(0, 7),
		wastelands = civ.getBaseTerrain(0, 9)
	},
	underwater = {
		goldenShipwreck = civ.getBaseTerrain(1, 2),
		iceCap = civ.getBaseTerrain(1, 7)
	},
	underworld = {
		caveOfWonders = civ.getBaseTerrain(2, 2),
		tunnel = civ.getBaseTerrain(2, 4)
	},
	cloudworld = {
		sky = civ.getBaseTerrain(3, 10)
	}
}

local TECH = {
	runes = civ.getTech(44),
	niebelungenlied = civ.getTech(38),
	dragonLore = civ.getTech(77),
	volsangsRelease = civ.getTech(63),
	griffinCulture = civ.getTech(79),
	ragnarok = civ.getTech(90),
	aCallToArms = civ.getTech(92),
	metalworking = civ.getTech(51),
	huginnAndMuninn = civ.getTech(76),
	theSongOfDreya = civ.getTech(24),
	eldritchLore = civ.getTech(61),
	bifrost = civ.getTech(99)
}

local UNITTYPE = {
	sSkeleton = civ.getUnitType(51),
	sNightRider = civ.getUnitType(17),
	sBarrowWight = civ.getUnitType(52),
	sFellWraith = civ.getUnitType(42),
	sWitch = civ.getUnitType(28),
	warlock = civ.getUnitType(10),
	greatBats = civ.getUnitType(27),
	gCragWolf = civ.getUnitType(21),
	jrmngndSpit = civ.getUnitType(60),
	unspHorror = civ.getUnitType(36),
	worm = civ.getUnitType(79),
	dragon = civ.getUnitType(59),
	elderDragon = civ.getUnitType(77),
	mKraken = civ.getUnitType(58),
	giantFlytrap = civ.getUnitType(75),
	eTreefolk = civ.getUnitType(23),
	bGriffin = civ.getUnitType(78), -- blake griffin
	frostGiant = civ.getUnitType(56),
	shieldBoat = civ.getUnitType(35),
	settler = civ.getUnitType(0),
	jackOLantern = civ.getUnitType(50),
	fairy = civ.getUnitType(47),
	dwarf = civ.getUnitType(1),
	hHero = civ.getUnitType(62),
	eHero = civ.getUnitType(67),
	iHero = civ.getUnitType(65),
	mHero = civ.getUnitType(64),
	bHero = civ.getUnitType(66),
	gGreatGoblin = civ.getUnitType(63),
	sLord = civ.getUnitType(68), -- shitlord
	flagUnit = civ.getUnitType(76)
}

local WONDER = {
	briansExpedition = civ.getWonder(12)
}

local TRIBE = {
	barbarians = civ.getTribe(0),
	infidels = civ.getTribe(1),
	humans = civ.getTribe(2),
	goblins = civ.getTribe(3),
	stygians = civ.getTribe(4),
	merfolk = civ.getTribe(5),
	elves = civ.getTribe(6),
	buteos = civ.getTribe(7)
}

local tribeData = {
	{originalCapital="Krakatorum", hero=UNITTYPE.iHero},
	{originalCapital="Oldgrange", hero=UNITTYPE.hHero},
	{originalCapital="Grympen Mire", hero=UNITTYPE.gGreatGoblin},
	{originalCapital="Doomsday", hero=UNITTYPE.sLord},
	{originalCapital="Atlantis", hero=UNITTYPE.mHero},
	{originalCapital="Goldleaf", hero=UNITTYPE.eHero},
	{originalCapital="Eagle's Aerie", hero=UNITTYPE.bHero}
}

-- global var
state = {}

function setInitialState()
	state.spawn = { -- barbarian spawning
		minions = true, -- flag 26
		griffins = true, -- flag 11
		frostGiants = true, -- flag 31
		undead = true -- flag 25 (flipped)
	}

	state.questsDone = {
		flytrapIsland = false, -- flag 0
		treePrinceDragon = false, -- flag 1
		unspHorror = false, -- flag 2
		worm = false, -- flag 3
		frostGiant = false, -- flag 4
		niebelungenliedTreasure = false, -- flag 5
		dwarvenHoard = false, -- flag 6
		jackOLantern = false, -- flag 7
		briansExpedition = false, -- flag 8
		rot = false -- flag 9
	}

	state.keyAssembled = false

	state.tribeState = {}
	for i = 1,7 do
		state.tribeState[i] = {
			gemsFound={
				goblet = false, -- flag 27
				ruby = false, -- flag 28
				sapphire = false, -- flag 29
				emerald = false -- flag 30
			},
			capitalsTaken={
				false, -- infidels = false, -- flag 13
				false, -- humans = false, -- flag 12
				false, -- goblins = false, -- flag 17
				false, -- stygians = false, -- flag 18
				false, -- merfolk = false, -- flag 16
				false, -- elves = false, -- flag 14
				false -- buteos = false -- flag 15
			}
		}
	end

	state.volsang = 0 -- corruption level, flags 19-23
	state.volsangCountdown = -1
	state.expeditionTribe = -1
	state.expeditionCountdown = -1
	state.ragnarokTribe = -1

	state.spawnQueue = {}
end

local doTweaks = function()
	return false
end

-- Our local 'justOnce' function, so it uses our state.
local justOnce = function (key, f) civlua.justOnce(civlua.property(state, key), f) end

-- fix bug with civlua createUnit function when using inCapital
civlua.createUnit = function(unittype, tribe, locations, options)
	options = options or {}
	local function getFirstValidLocation(locations)
		for _, v in ipairs(locations) do
			local tile = civ.getTile(table.unpack(v))
			if civlua.isValidUnitLocation(unittype, tribe, tile) then
				return tile
			end
		end
	end
	local function getLocation()
		if options.inCapital then
			local capital = civlua.findCapital(tribe)
			if civlua.isValidUnitLocation(unittype, tribe, capital.location) then
				return capital.location
			end
		else
			if options.randomize then
				locations = func.shuffle(locations)
			end
			return getFirstValidLocation(locations)
		end
	end
	local units = {}
	for i = 1, options.count or 1 do
		local location = getLocation()
		if location then
			local unit = civ.createUnit(unittype, tribe, location)
			unit.veteran = options.veteran
			unit.homeCity = options.homeCity
			table.insert(units, unit)
		end
	end
	return units
end

local formatMessage = function(msg)
	return func.splitlines(string.gsub(msg, "\t+", ""))
end

local targetedMessage = function(receiver, msgPlayer, msgAi)
	if civ.getPlayerTribe() == receiver then
		if msgPlayer.sound then
			civ.playSound(msgPlayer.sound)
		end
		civ.ui.text(formatMessage(msgPlayer.msg))
	elseif msgAi then
		if msgAi.sound then
			civ.playSound(msgAi.sound)
		end
		civ.ui.text(formatMessage(string.gsub(msgAi.msg, "{TRIBE}", receiver.name)))
	end
end

local findResearcher = function(tech)
	for i = 1, 7 do
		local tribe = civ.getTribe(i)
		if tribe:hasTech(tech) then
			return tribe
		end
	end
end

local isFlagInStack = function(killed)
	-- Check if there's a flag in the tile the killed unit was on
	-- This doesn't work exactly how the original scenario worked, because it doesn't detect whether the flag unit was
	-- actually killed with the stack, but it's probably good enough
	local unitsInStack = {}
	for unit in killed.location.units do
		if unit.type == UNITTYPE.flagUnit then
			return true
		end
	end
	return false
end

local getNumCapitalsTaken = function(tribeId)
	if tribeId < 1 then return false end
	local capitalsTaken = 0
	for tribeId, isTaken in ipairs(state.tribeState[tribeId].capitalsTaken) do
		if isTaken then
			capitalsTaken = capitalsTaken + 1
		end
	end
	return capitalsTaken
end

local isGobletCompleted = function(tribeId)
	if tribeId < 1 then return false end
	local gems = 0
	for gem, hasGem in pairs(state.tribeState[tribeId].gemsFound) do
		if hasGem then gems = gems + 1 end
	end
	return gems == 4
end

local isUnitAHero = function(unitId)
	for i, tribeInfo in ipairs(tribeData) do
		if unitId == tribeInfo.hero.id then return true end
	end
	return false
end

local getNumQuestsDone = function()
	local questsDone = 0
	-- Taking all the capitals counts as all quests but taking Rot
	if state.keyAssembled then
		questsDone = 9
		if state.questsDone.rot then
			questsDone = 10
		end
	else
		for quest, isDone in pairs(state.questsDone) do
			if isDone then
				questsDone = questsDone + 1
			end
		end
	end
	return questsDone
end

-- map, terrainType, exceptionMask, mapRect
-- Unlike the original, this doesn't destroy things...I think that's fine
local changeTerrain = function(args)
	args.map = args.map or 0
	args.exceptionMask = args.exceptionMask or 0x0
	-- exceptionMask: 0x0624 (11000100100)
	-- mapRect: {56,110,74,110,74,134,56,134}
	-- why are there 4 points used to defined a rectangle?? Just use two
	local xMin = args.mapRect[1]
	local xMax = args.mapRect[5]
	local yMin = args.mapRect[2]
	local yMax = args.mapRect[6]
	for x = xMin, xMax do
		for y = yMin, yMax do
			if math.fmod(x + y, 2) == 0 then
				local tile = civ.getTile(x, y, args.map.id)
				-- Ocean resource tiles away from land have terrain type +64
				local baseTerrainType = math.fmod(tile.terrainType, 64)
				if args.exceptionMask >> baseTerrainType & 1 ~= 1 then
					tile.terrainType = args.terrainType.type
				end
			end
		end
	end
end

-- Because the civ.scen triggers seem to overwrite the trigger function rather than adding more,
-- I am adding this event so I can register multiple functions and keep the code
-- sorted by in-game function rather than code function
local eventRegister = {
	onTurn={},
	onBribeUnit={},
	onUnitKilled={},
	onCityDestroyed={},
	onCityTaken={},
	onCityProduction={},
	onKeyPress={}
}

function registerEvent(trigger, fn)
	if eventRegister[trigger] then
		table.insert(eventRegister[trigger], fn)
	else
		print("Cannot register function to '" .. trigger .. "' event")
	end
end

----------------------------------------------------------------
----------------------------------------------------------------
-- MINION SPAWNING
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	-- Many of these events had a delay - instead of dealing with that,
	-- We'll just wait some turns before checking - I believe it's equivalent
	-- I tested to make sure: a delayed random turn trigger CAN be triggered while one is already delayed
	local minionsSpawned = {}
	local commonMinionSpawns = {{65,123,0}, {65,117,0}, {71,63,0}, {52,46,0}, {51,73,0}}
	if turn >= 70 and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "Underwater S Night Rider")
		local spawns = {{24,78,1}, {14,34,1}, {100,52,1}, {43,139,1}, {20,138,1}, {87,19,1}, {95,109,1}, {50,28,1}}
		civlua.createUnit(UNITTYPE.sNightRider, TRIBE.barbarians, spawns, {randomize=true})
	end
	if turn >= 25 and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "Jormungand Spit")
		-- Around jormungand's maw in the north
		local spawns = {{82,4,0}, {82,6,0}, {81,5,0}, {81,3,0}, {83,5,0}, {83,3,0}, {82,2,0}}
		civlua.createUnit(UNITTYPE.jrmngndSpit, TRIBE.barbarians, spawns, {randomize=true})
	end
	if turn >= 25 and math.random(1, 100) == 1 then
		table.insert(minionsSpawned, "Dragon")
		-- Various northerly locations
		local spawns = {{62,18,0}, {78,22,0}, {61,29,0}, {112,14,0}, {103,21,0}}
		civlua.createUnit(UNITTYPE.dragon, TRIBE.barbarians, spawns, {randomize=true})
	end
	if turn >= 25 and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "E Treefolk")
		local spawns = {}
		civlua.createUnit(UNITTYPE.eTreefolk, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.spawn.minions and turn >= 25 and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "S Skeleton")
		civlua.createUnit(UNITTYPE.sSkeleton, TRIBE.barbarians, commonMinionSpawns, {randomize=true})
	end
	if state.spawn.minions and turn >= 25 and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "G Crag Wolf")
		civlua.createUnit(UNITTYPE.gCragWolf, TRIBE.barbarians, commonMinionSpawns, {randomize=true})
	end
	if state.spawn.minions and turn >= 25 and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "Great Bats")
		civlua.createUnit(UNITTYPE.greatBats, TRIBE.barbarians, commonMinionSpawns, {randomize=true})
	end
	if state.volsang >= 1 and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "Dwarf")
		-- Near dwarven tunnels in north
		local spawns = {{73,25,0}, {73,25,0}, {65,25,0}, {56,20,0}, {107,19,0}}
		civlua.createUnit(UNITTYPE.dwarf, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 1 and state.spawn.minions and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "S Fell Wraith")
		civlua.createUnit(UNITTYPE.sFellWraith, TRIBE.barbarians, commonMinionSpawns, {randomize=true})
	end
	if state.volsang >= 1 and state.spawn.minions and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "S Witch")
		local spawns = {{65,123,3}, {65,117,3}, {6,100,3}, {88,124,3}, {66,52,3}}
		civlua.createUnit(UNITTYPE.sWitch, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 2 and state.spawn.minions and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "M Kraken")
		local spawns = {{60,38,2}, {60,62,2}, {64,96,2}, {115,69,2}, {116,102,2}, {108,76,2}}
		civlua.createUnit(UNITTYPE.mKraken, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 2 and state.spawn.minions and state.spawn.griffins and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "B Griffin")
		local spawns = {{5,103,3}, {70,68,3}, {65,119,3}, {66,112,3}, {118,62,3}}
		civlua.createUnit(UNITTYPE.bGriffin, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 3 and state.spawn.minions and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "Worm")
		local spawns = {{63,79,2}, {65,31,2}, {88,104,2}, {48,40,2}, {109,109,2}}
		civlua.createUnit(UNITTYPE.worm, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 4 and state.spawn.minions and math.random(1, 33) == 1 then
		table.insert(minionsSpawned, "Warlock")
		local spawns = {{2,106,3}, {72,80,3}, {66,42,3}, {71,87,3}, {67,125,3}, {8,106,3}}
		civlua.createUnit(UNITTYPE.warlock, TRIBE.barbarians, spawns, {randomize=true})
	end
	if state.volsang >= 4 and state.spawn.minions and state.spawn.frostGiants and math.random(1, 50) == 1 then
		table.insert(minionsSpawned, "Frost Giant")
		-- in mtns
		local spawns = {{60,34,0}, {57,65,0}, {61,65,0}, {60,46,0}, {60,86,0}, {61,65,0}, {62,92,0}, {54,58,0}, {64,46,0}, {65,103,0}}
		civlua.createUnit(UNITTYPE.frostGiant, TRIBE.barbarians, spawns, {randomize=true})
	end

	if #minionsSpawned > 0 then
		print("Spawning minions: " .. table.concat(minionsSpawned, ", "))
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- GRIFFIN ALLIES
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if state.volsang >= 4 then
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			if tribe:hasTech(TECH.griffinCulture) then
				justOnce("J1Griffins", function()
					civ.playSound("Fanfare7.wav")
					civ.ui.text(formatMessage([[
						Volsang's corruption has reached the Griffins' mountain stronghold and forced them into the open. If
						you can understand their ways, you think you may convince many to join your side. If you haven't 
						studied Griffin Culture yet, perhaps the allure of Griffin allies might convince you to do so.
					]]))
					state.spawn.griffins = false
				end)
				if math.random(1, 25) == 1 then
					if civ.getTribe(i) == civ.getPlayerTribe() then
						civ.ui.text(formatMessage([[
							A griffin decides to join your fight against Volsang.
						]]))
					end
					civlua.createUnit(UNITTYPE.bGriffin, civ.getTribe(i), {}, {inCapital=true})
				end
			end
		end
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- VOLSANG CORRUPTION SPREAD
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if state.volsangCountdown > 0 then 
		state.volsangCountdown = state.volsangCountdown - 1
	end

	if state.volsangCountdown == 0 then
		state.volsangCountdown = -1
		state.volsang = state.volsang + 1
		if state.volsang == 1 then
			civ.ui.text(formatMessage([[
				After centuries of imprisonment, Volsang suddenly detects a slight loosening
				of his magical bonds. He decides to test his returning powers. His vile 
				corruption begins to creep over the world.
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0624, mapRect={56,110,74,110,74,134,56,134}})
			civ.playVideo("Scene9a.avi")

		elseif state.volsang == 2 then
			civ.ui.text(formatMessage([[
				Volsang's magical bonds suddenly loosen further; 
				with greater confidence, he tests his powers. No 
				person and no city, even those allied to him, can 
				survive his spreading all-pervasive corruption.
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={56,110,74,110,74,134,56,134}})
			civ.playVideo("Scene9b.avi")
		elseif state.volsang == 3 then
			civ.ui.text(formatMessage([[
				Yet another weakening of Volsang's magical bonds occurs; all of the races 
				begin to exhibit real fear now. Can anyone stop Volsang before he breaks 
				completely free?
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={44,98,86,98,86,152,44,152}})
			civ.playVideo("Scene9b.avi")
		elseif state.volsang == 4 then
			civ.ui.text(formatMessage([[
				Volsang's confidence grows as he detects a further weakening of his 
				magical bonds and no champion in sight to challenge his reemergence.
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={33,85,99,85,99,161,33,161}})
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={15,60,32,60,32,100,15,100}})
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={15,100,22,100,22,160,15,160}})
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={22,114, 32,114, 32,160, 22,160}})
			civ.playVideo("Scene9b.avi")
		elseif state.volsang == 5 then
			civ.ui.text(formatMessage([[
				Suddenly there's another rumbling in the magical vortex 
				and Volsang is now more free than enslaved.
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={33,59, 121,59, 121,161, 33, 161}})
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={22,42, 120,42, 120,100, 22,100}})
			civ.playVideo("Scene9b.avi")
		elseif state.volsang == 6 then
			civ.ui.text(formatMessage([[
				A great clap of thunder announces the imminent release of Volsang. 
				The next magical rumbling will, likely, be sufficient to free Volsang 
				to corrupt Midgard completely. Time has almost run out.
			]]))
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.wastelands, exceptionMask=0x0620, mapRect={1,1,121,1,121,43,1,43}})
			civ.giveTech(TRIBE.humans, TECH.volsangsRelease)
			civ.playVideo("Scene9b.avi")
		elseif civ.hasTech(TRIBE.humans, TECH.volsangsRelease) then
			civ.ui.text(formatMessage([[
				You are too late! Volsang finally breaks free and enslaves Midgard with his powerful magic. Not even the
				Gods can help you now. YOU HAVE LOST THE GAME!
			]]))
			civ.playVideo("Scene9.avi")
			civ.endGame(true)
		end
	end

	if turn >= 150 and state.volsangCountdown == -1 then
		local maxDelay = 70
		if state.volsang <= 6 then
			maxDelay = 50 + 20 * getNumQuestsDone()
		end

		state.volsangCountdown = math.random(1, maxDelay)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- SPAWN QUEUE
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	local numSpawned = 0
	local newI = 1
	local undeadSpawns = {{65,117,0}, {65,123,0}, {68,124,0}, {74,114,0}}
	for i, spawnInfo in ipairs(state.spawnQueue) do
		spawnInfo.turnsLeft = spawnInfo.turnsLeft - 1
		if spawnInfo.turnsLeft <= 0 then
			if spawnInfo.undead then
				-- NEW: Cancel queued undead immediately when worm is defeated instead of 3 turn delay
				-- TODO? Would be fun if undead spawned where they died
				if state.spawn.undead then
					civlua.createUnit(UNITTYPE.sBarrowWight, TRIBE.barbarians, undeadSpawns, {randomize=true})
					numSpawned = numSpawned + 1
				end
			else
				civlua.createUnit(civ.getUnitType(spawnInfo.unitId), civ.getTribe(spawnInfo.tribeId), spawnInfo.locations, spawnInfo.options)
				numSpawned = numSpawned + 1
			end
			state.spawnQueue[i] = nil
		else
			if i > newI then
				state.spawnQueue[newI] = state.spawnQueue[i]
				state.spawnQueue[i] = nil
			end
			newI = newI + 1
		end
	end
	if numSpawned > 0 then
		print("Attempted to spawn " .. tostring(numSpawned) .. " units. Left in queue: " .. tostring(newI - 1))
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- TALES AND RUMORS
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	-- This used to be one big long message on a random turn at the beginning...
	-- I've split it up so as not to overload the player

	-- Used to be 1/25 chance
	if turn >= 5 and math.random(1, 10) == 1 then
		justOnce("J1JackOLanterns", function() 
			civ.playSound("Fanfare7.wav")
			civ.ui.text(formatMessage([[
				An old, dust-covered hermit wanders into your capital telling many strange tales he has heard in his travels.
				You pay particular attention to three of them.
				He mentions a frost giant who is looking for adventure for a price. 
				He states with total conviction that whoever tastes Jormungand's spittle gains knowledge of war magic.
				He also speaks of animated Jack O'Lanterns roaming the roads and byways who are often willing to reveal
				valuable secrets for a price.  
			]]))
			local spawns = {{64,104,0}, {57,55,0}, {71,53,0}, {59,125,0}, {61,35,0}}
			civlua.createUnit(UNITTYPE.jackOLantern, TRIBE.barbarians, spawns, {count=5, randomize=true})
		end)
	end
	if turn >= 100 and math.random(1, 20) == 1 then
		justOnce("J1AdvancedRumors", function() 
			civ.playSound("Fanfare7.wav")
			civ.ui.text(formatMessage([[
				The old, dust-covered hermit is back, with more wild tales from his adventures.
				He describes a utopian island guarded by gigantic man-eating plants. He claims that a great treasure awaits 
				whoever can pacify the island.
				He whispers of huge worms who can bore through solid rock. A very ancient worm lives on a lonely 
				island in a huge underground sea and is famous for having swallowed many treasures in its long life. 
			]]))
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- RUNES
----------------------------------------------------------------
----------------------------------------------------------------
local runesRegister = {}
local registerRunes = function(id, checkFn, msg)
	table.insert(runesRegister, {id=id, checkFn=checkFn, msg=msg})
end

registerEvent("onTurn", function(turn)
	-- Inform the player about Runes research
	if TECH.runes.researched then
		justOnce("J1Runes", function()
			local researcher = findResearcher(TECH.runes)
			targetedMessage(researcher, {sound="Fanfare7.wav", msg=[[
				You have finally managed to decipher the long forgotten runic language.
				Many important messages are written in that script.
			]]}, {sound="Fanfare7.wav", msg=[[
				The {TRIBE} have finally managed to decipher the long forgotten runic language.
				You might consider learning Runes as many important messages 
				are written in that script.
			]]})
		end)
	end

	if civ.getPlayerTribe():hasTech(TECH.runes) then
		for i, runeInfo in pairs(runesRegister) do
			if runeInfo.checkFn() then
				justOnce("J1" .. runeInfo.id, function()
					--civ.playSound("Fanfare7.wav")
					civ.ui.text(formatMessage(runeInfo.msg))
				end)
			end
		end	
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- CAPITALS
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onCityTaken", function(city, defender)
	if defender.id > 0 and city.name == tribeData[defender.id].originalCapital then
		state.tribeState[city.owner.id].capitalsTaken[defender.id] = true
		if civ.getPlayerTribe() == city.owner then
			civ.playSound("Shortking.wav")
			civ.ui.text(formatMessage([[
				You discover a piece of a key in a reliquary buried in the city ruins. You instantly recognize it as part of 
				the great key of Volsang, shattered in the climactic battle that enslaved him many centuries ago and 
				presumed lost since then. It seems a secret cult of Volsang had kept it in safekeeping. If all six pieces can 
				be found, Volsang's escape can be stopped. Perhaps they are hidden in other capitals.
			]]))
		end
	end
end)

registerEvent("onTurn", function(turn)
	for i = 1,7 do
		if getNumCapitalsTaken(i) >= 6 then
			justOnce("J1CapitalsConquered", function()
				local conqueringTribe = civ.getTribe(i)
				targetedMessage(conqueringTribe, {sound="Shortking.wav", msg=[[
					All six pieces of the key have been found. In the face of a greater foe, the tribes momentarily put aside 
					their wars and help build one key. The key magically restores Volsang's imprisonment spell to almost full
					strength. One crack is too deep to repair, however. Even so, the chances of Volsang overcoming the spell
					again have been dramatically reduced although not eliminated entirely. You still need to find another way
					to defeat him forever.
				]]}, {sound="Shortking.wav", msg=[[
					The {TRIBE} have found six pieces of a key. In the face of a greater foe, the tribes momentarily put aside 
					their wars and help build one key. The key magically restores Volsang's imprisonment spell to almost full
					strength. One crack is too deep to repair, however. Even so, the chances of Volsang overcoming the spell
					again have been dramatically reduced although not eliminated entirely. You still need to find another way
					to defeat him forever.
				]]})
				state.spawn.minions = false
				state.keyAssembled = true
			end)
		end
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- FLYTRAP ISLAND
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.giantFlytrap and isFlagInStack(killed) then
		justOnce("J1Flytrap", function()
			targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
				You discover a magic sack out of which flows mounds of coins, a beautiful ruby, a pellucid cube which
				evaporates within seconds of touching it, a fragment of parchment with runes written on it and, to your
				astonishment, enough settlers to build a village. Even though human, they seem to consider you their natural master. 
				You also hear a disembodied voice intoning, "The Gods have safeguarded this island from Volsang's Scourge."
			]]})
			killer.owner.money = killer.owner.money + 2000
			table.insert(state.spawnQueue, {turnsLeft=1, unitId=UNITTYPE.settler.id, tribeId=killer.owner.id, locations={{27,107,0}}, options={}})
			state.tribeState[killer.owner.id].gemsFound.ruby = true
			state.questsDone.flytrapIsland = true
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- TREE PRINCE'S DRAGON
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onBribeUnit", function(unit, prevOwner)
	if unit.type == UNITTYPE.jackOLantern and prevOwner == TRIBE.barbarians and state.volsang == 0 then
		targetedMessage(unit.owner, {msg=[[
			In gratitude for your gift, the Jack O'Lantern reveals a secret he learned while accidently overhearing a
			conversation between two wicked wizards. At the risk of his life, he relates to you a story of a prince
			transformed into a tree creature by one of the wizards. If anyone can break the spell by putting enough gold
			into a hollow bole on the creature, the prince will bestow a great reward. He last heard of the poor treeman
			roaming the haunted forest east of the Misty Mountains. He also warns you to hurry before he wanders
			away.
		]]})
		local spawns = {{66,54,0}, {67,71,0}, {71,67,0}, {66,44,0}, {67,55,0}, {66,70,0}, {70,68,0}, {65,41,0}, {71,79,0}, {73,69,0}}
		civlua.createUnit(UNITTYPE.eTreefolk, TRIBE.barbarians, spawns, {randomize=true, count=2})
	end

	if unit.type == UNITTYPE.eTreefolk and prevOwner == TRIBE.barbarians then
		targetedMessage(unit.owner, {sound="Fanfare7.wav", msg=[[
			The tree suddenly transforms into an ugly prince. With effusive thanks, he hands over a wooden tablet
			covered in runes. He tells you it is far more valuable than money; but can you believe a prince who is not
			charming? Seemingly as an afterthought, he tosses you a brilliant blue sapphire.
		]]})
		civlua.createUnit(UNITTYPE.flagUnit, TRIBE.barbarians, {{62,16,0}}, {})
		state.tribeState[unit.owner.id].gemsFound.sapphire = true
	end
end)

registerRunes("TreemanTablet", function() return state.tribeState[civ.getPlayerTribe().id].gemsFound.sapphire end, [[
	You use your knowledge of runes to decipher the tablet the treeman gave you.
	The Treeman's tablet reads, "HEARKEN TO OUR PLEA!" A fearsome dragon holds our beautiful princess for
	ransom in the cold north. Defeat him and you will be amply rewarded. His evil brother, the giant
	Jormungand whose coils girdle the poles, has stolen our treasury and swallowed it whole. Recover our
	savings and receive another reward and our undying gratitude. - The People of the North.
]])

registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.elderDragon and killed.z == 0 then
		justOnce("J1SurfaceElderDragon", function()
			targetedMessage(killer.owner, {sound="Shortking.wav", msg=[[
				You have defeated the great elder dragon. In his lair, you find a fair maiden, actually a beautiful princess
				betrothed to the tree prince and being held for ransom by the dragon. She bequeathes to you a dragon tooth
				amulet, 2000 gold pieces, a fragment of parchment, and a pellucid cube which evaporates into smoke upon
				your touching it. She places the amulet around your neck and you suddenly realize great insights into 
				dragon lore.
			]]})
			killer.owner.money = killer.owner.money + 2000
			civ.giveTech(killer.owner, TECH.dragonLore)
			state.questsDone.treePrinceDragon = true
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- JORMUNGAND UNSPEAKABLE HORROR
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onUnitKilled", function(killed, killer)
	-- It didn't originally have map=2, I added that
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.unspHorror and killed.z == 2 then
		justOnce("J1UnspHorror", function()
			targetedMessage(killer.owner, {sound="Shortking.wav", msg=[[
				In amazement, you watch the defeated Unspeakable Horror transform into a Griffin who swears eternal
				allegience to you for breaking the spell that had enchanted him. He then rushes out of the snake into 
				the open air. Among the bones and animal remains that have accumulated in Jormungand's tail over the 
				centuries, you discover an exquisite emerald gem, a runic rosetta stone, a piece of parchment, mountains 
				of coins, and a pellucid cube that evaporates at a touch. You return the treasury to the people of the north 
				who give you a reward of 2000 gold coins in return.
			]]})
			killer.owner.money = killer.owner.money + 2000
			state.questsDone.unspHorror = true
			state.tribeState[killer.owner.id].gemsFound.emerald = true
			civ.giveTech(killer.owner, TECH.runes)
			-- Same as jormungand spit
			local spawns = {{82,4,0}, {82,6,0}, {81,5,0}, {81,3,0}, {83,5,0}, {83,3,0}, {82,2,0}}
			civlua.createUnit(UNITTYPE.bGriffin, killer.owner, spawns, {})
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- FROST GIANT
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onBribeUnit", function(unit, prevOwner)
	if unit.type == UNITTYPE.frostGiant and prevOwner == TRIBE.barbarians then
		justOnce("J1FrostGiant", function()
			targetedMessage(unit.owner, {msg=[[
				The giant decides to join your side. He gives you a piece of parchment and a pellucid cube which
				evaporates upon touch. He vows that, henceforth, none of his fellow frost giants will fight for Volsang.
			]]}, {msg=[[
				You hear rumors that the frost giants have decided to follow the {TRIBE} and have vowed never to fight for Volsang.
			]]})
			state.spawn.frostGiants = false
			state.questsDone.frostGiant = true
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- UNDEAD AND WORM
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onUnitKilled", function(killed, killer)
	-- I've modified this to not trigger when killing a flag
	-- Also only show message when the player is involved in the combat
	-- The original undead spawn list had 6 dud locations,
	-- Instead we explicitly define a 40% chance
	-- TODO: Killing barrow wight doesn't trigger?
	local undeadChance = 40
	local playerInvolved = civ.getPlayerTribe() == killer.owner or civ.getPlayerTribe() == killed.owner
	if state.spawn.undead and not isFlagInStack(killed) then
		if playerInvolved then
			justOnce("J1Undead", function()
				targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
					The shade of a defeated unit has been carried away by a huge worm to
					rise up as a Barrow Wight, now a minion of Volsang. You recall that all
					dead creatures eventually arise under the dominion of Volsang and that
					this insidious practice will persist until you defeat a worm.
				]]})
			end)
		end
		if math.random(1, 100) <= undeadChance then
			table.insert(state.spawnQueue, {turnsLeft=3, undead=true, locations={{killed.location.x, killed.location.y, killed.location.z}}})
		end
	end

	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.worm then
		justOnce("J1Worm", function()
			targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
				You carve open the dead worm and find inside, a piece of parchment, and 1000 gold coins. A runic
				message mysteriously appears as raised welts on the skin of the creature.
			]]}, {sound="Fanfare7.wav", msg=[[
				You hear rumors that the {TRIBE} have slain a worm, and that a runic message appeared on its dead skin.
			]]})
			killer.owner.money = killer.owner.money + 1000
			state.questsDone.worm = true
			state.spawn.undead = false
		end)
	end
end)

registerRunes("WormRunes", function() return not state.spawn.undead end, [[
	You use your knowledge of runes to decipher the message on the slain worm's skin.
	The runic message says, "Killing a great worm ends their insidious
	practice of swallowing dead warriors and then excreting them as barrow wights."
]])

----------------------------------------------------------------
----------------------------------------------------------------
-- NIEBELUNGENLIED TREASURE
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if civ.getPlayerTribe():hasTech(TECH.niebelungenlied) then
		targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
			Stuck among the leaves of a long-thought lost tome of the Niebelungenlied is discovered 
			an ancient map showing a tunnel maze. In the margin, some runic script is scrawled.
		]]})
	end
end)

registerRunes("NiebelungenliedRunes", function() return civ.getPlayerTribe():hasTech(TECH.niebelungenlied) end, [[
	You use your knowledge of runes to decipher the text in the margins of the Niebelungenlied map.
	It says "Underground coordinates 118,140 and then the single word, "Dig".
]])

registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.elderDragon and killed.z == 2 then
		justOnce("J1NTreasure", function()
			targetedMessage(killer.owner, {sound="Shortking.wav", msg=[[
				You discover a dragon's hoard of dwarven gold. Alas there is another piece of parchment. 
				The pieces you have accumulated so far seem to fit together but you can make nothing 
				of the writing. At the bottom of the pile of gold, you stumble upon a strange mirror which 
				reflects nothing.
			]]}, {sound="Fanfare7.wav", msg=[[
				The {TRIBE} discover a dragon's hoard of dwarven gold. Alas there is another piece of parchment. 
				The pieces accumulated so far seem to fit together but you can make nothing 
				of the writing. At the bottom of the pile of gold, they stumble upon a strange mirror which 
				reflects nothing.
			]]})
			killer.owner.money = killer.owner.money + 3000
			state.questsDone.niebelungenliedTreasure = true
			changeTerrain({map=MAPS.underworld, terrainType=BASETERRAIN.underworld.caveOfWonders, mapRect={116,138,120,138,120,142,116,142}})
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- DWARVEN HOARD
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if state.volsang >= 1 then
		justOnce("J1Dwarves", function()
			local spawns = {{73,25,0}, {72,24,0}, {78,24,0}, {70,24,0}, {68,22,0}, {62,18,0}}
			civlua.createUnit(UNITTYPE.dwarf, TRIBE.barbarians, spawns, {})
		end)
	end
end)

registerEvent("onBribeUnit", function(unit, prevOwner)
	if unit.type == UNITTYPE.dwarf and prevOwner == TRIBE.barbarians then
		justOnce("J1DwarfKing", function()
			targetedMessage(unit.owner, {sound="Fanfare7.wav", msg=[[
				The Dwarven King shares your concern and offers his army for your use. He also hints at a ring of power
				lost somewhere in his mine that may be of service in your war against Volsang. He teaches you the
				dwarven art of metalworking.
			]]}, {sound="Fanfare7.wav", msg=[[
				The {TRIBE} have found the Dwarven King, who offers his army for their use,
				as well as the Dwarven secret of metalworking. You hear rumors that the {TRIBE} are
				now searching for something in the Dwarven mines.
			]]})
			civlua.createUnit(UNITTYPE.flagUnit, TRIBE.barbarians, {{97,31,2}}, {})
			civlua.createUnit(UNITTYPE.sBarrowWight, TRIBE.barbarians, {{97,31,2}}, {})
			civlua.createUnit(UNITTYPE.dwarf, unit.owner, {{73,25,2}, {74,24,2}, {75,23,2}}, {count=6})
			civ.giveTech(unit.owner, TECH.metalworking)
		end)
	end
end)

registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.sBarrowWight and isFlagInStack(killed) then
		justOnce("J1DwarvenHoard", function()
			targetedMessage(killer.owner, {sound="Shortking.wav", msg=[[
				In a hidden chamber covered in carved runes, you find the lost dwarven hoard. Included is a piece of
				parchment, 2000 gold pieces and a dwarven-forged ring of power that helps delay Volsang's breakout.
			]]}, {sound="Fanfare7.wav", msg=[[
				You hear rumors that the {TRIBE} have found a lost dwarven hoard.
			]]})
			killer.owner.money = killer.owner.money + 2000
			state.questsDone.dwarvenHoard = true
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- JACK O'LANTERN
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onCityProduction", function(city, prod)
	if civ.isUnit(prod) and prod.type == UNITTYPE.jackOLantern and city.owner.id > 0 then
		justOnce("J1Jacko", function()
			targetedMessage(city.owner, {sound="Fanfare7.wav", msg=[[
				The ability to build a Jack O'Lantern is steeped in ancient magic. As you place the pumpkin head on the
				branch-fashioned body, you feel a shudder in the mystical fabric emanating far to the south. A piece of
				parchment magically extrudes from the pumpkin's carved mouth.
			]]}, {sound="Fanfare7.wav", msg=[[
				You hear rumor that the {TRIBE} have successfully built a Jack O'Lantern, and a piece of parchment
				magically appeared from the pumpkin's mouth, which may slow Volsang's release.
			]]})
			state.questsDone.jackOLantern = true
		end)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- BRIAN'S EXPEDITION
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onCityProduction", function(city, prod)
	if civ.isWonder(prod) and prod == WONDER.briansExpedition then
		justOnce("J1BrianStart", function()
			-- NEW - start of expedition message
			targetedMessage(city.owner, {sound="Fanfare7.wav", msg=[[
				The entrepid explorer, Brian, has left on a voyage to the furthest corners of the world.
			]]})
			state.expeditionTribe = city.owner.id
			-- CHANGED: random turns from 1-30 to 10-20
			state.expeditionCountdown = math.random(10, 20)
		end)
	end
end)

registerEvent("onTurn", function(turn)
	if state.expeditionCountdown > 0 then
		state.expeditionCountdown = state.expeditionCountdown - 1
	end
	if state.expeditionCountdown == 0 then
		state.expeditionCountdown = -1
		local builder = civ.getTribe(state.expeditionTribe)
		targetedMessage(builder, {sound="Shortking.wav", msg=[[
			The entrepid explorer, Brian, returns home from an extraordinary voyage to the far corners of the world. 
			His tales of monsters and magic appear so fantastic that everyone who listens scoffs until he pulls out
			Huginn and Muninn, Odin's famous crows, who hear and see everything. He also claims to have found a
			submersible boat and a bit of parchment he believes is the oldest object he has ever beheld.
		]]}, {sound="Fanfare7.wav", msg=[[
			The entrepid explorer, Brian, returns home from an extraordinary voyage. He shows the {TRIBE}
			Huginn and Muninn, Odin's famous crows, who hear and see everything. He also claims to have found 
			a bit of parchment he believes is the oldest object he has ever beheld.
		]]})
		civ.giveTech(builder, TECH.huginnAndMuninn)
		civlua.createUnit(UNITTYPE.shieldBoat, builder, {{45,81,0}, {86,76,0}, {39,131,0}, {48,10,0}, {83,7,0}}, {})
		state.questsDone.briansExpedition = true
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- ROT
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onUnitKilled", function(killed, killer)
	-- Rot hint
	if killed.owner == TRIBE.barbarians and civ.getPlayerTribe() == killer.owner and civ.getPlayerTribe():hasTech(TECH.runes) then
		justOnce("J1RotHint", function()
			civ.ui.text(formatMessage([[
				You are astonished to discover a map on the carcass of a barbarian creature lying on the side of a road. You notice some smudged
				runes in the margin. The message reads, Search the city of Rot in the Valley of the Wastelands to find
				the Goblet of Everlasting Life. Rot appears on the map near the intersection of coordinates of 68 and 124.
			]]))
		end)
	end
end)

registerEvent("onCityDestroyed", function(city)
	if city.owner == TRIBE.barbarians and city.name == "Rot" then
		destroyer = civ.getCurrentTribe()	
		justOnce("J1RotDestroy", function()
			if destroyer.id > 0 then
				-- If Rot starves or something (from corruption), then this never happens...
				targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
					The destroyer of the heathen city of Rot has discovered a votive gold
					goblet covered in runes buried in the debris of a temple.
					Surrounding the cup are three empty clasps evidently placed there to
					hold gems. The barbarians were able to make away with most of
					their treasure but some gold was still overlooked.
				]]})
				destroyer.money = destroyer.money + 400
				state.tribeState[destroyer.id].gemsFound.goblet = true
			else
				targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
					One positive aspect of Volsang's spreading corruption is that the city of Rot has been
					destroyed. This will slow Volsang's release, but any treasure that might have been found there
					is now lost.
				]]})
			end
			state.questsDone.rot = true
		end)
	end
end)

registerEvent("onCityTaken", function(city, defender)
	if defender == TRIBE.barbarians and city.name == "Rot" then
		justOnce("J1RotDestroy", function()
			targetedMessage(city.owner, {sound="Fanfare7.wav", msg=[[
				You are dumbfounded to discover a votive gold goblet covered in runes buried in the debris of heathen
				Rot. Surrounding the cup are three empty clasps evidently placed there to hold gems. The barbarians were able to make away with most of
				their treasure but some gold was still overlooked.
			]]}, {sound="Fanfare7.wav", msg=[[
				The {TRIBE} have captured the barbarian city of Rot. They found an intriguing goblet in the debris.
			]]})
			city.owner.money = city.owner.money + 400
			state.tribeState[city.owner.id].gemsFound.goblet = true
			state.questsDone.rot = true
		end)
	end
end)

registerRunes("GobletRunes", function() return state.tribeState[civ.getPlayerTribe().id].gemsFound.goblet end, [[
	You use your knowledge of runes to decipher the message on the goblet found in Rot.
	The runic inscription on the goblet reads, "I give perpetual life to all of heroic stature who drink from me."
	The goblet does not seem to work unless gems are placed in its three empty clasps.
]])

----------------------------------------------------------------
----------------------------------------------------------------
-- FAIRIES
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	-- Don't let this happen on turn 1
	if math.random(1, 33) == 1 and turn > 1 then
		targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
			Stories are circulating everywhere that fairies have been spotted flittering about the neighborhood. If only
			you can convince one of these magical beings to become a friend, you know you will greatly benefit from
			its knowledge and magical abilities.
		]]})
		local spawns = {{120,82,0}, {93,65,0}, {41,133,0}, {92,124,0}, {30,66,0}, {65,41,0}, {51,69,0}, {65,99,0}, {75,51,0}, {60,66,0}}
		civlua.createUnit(UNITTYPE.fairy, TRIBE.barbarians, spawns, {randomize=true, count=4})
	end
end)

registerEvent("onBribeUnit", function(unit, prevOwner)
	if unit.type == UNITTYPE.fairy and prevOwner == TRIBE.barbarians then
		targetedMessage(unit.owner, {msg=[[
			The fairy teaches you the magical Song of Dreya. Chanting the last syllable, your mind is suddenly filled
			with magical notions you never knew before.
		]]})
		civ.giveTech(unit.owner, TECH.theSongOfDreya)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- JORMUNGAND SPIT
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.type == UNITTYPE.jrmngndSpit then
		targetedMessage(killer.owner, {msg=[[
			The evil stench of the dead spit fills your head with arcane knowledge.
		]]})
		civ.giveTech(killer.owner, TECH.eldritchLore)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- HEROES
----------------------------------------------------------------
----------------------------------------------------------------
-- Change from set coords to inCapital for safety
registerEvent("onTurn", function(turn)
	-- Hero call
	if state.volsang >= 1 then
		justOnce("J1Heroes", function()
			civ.playSound("Fanfare7.wav")
			civ.ui.text(formatMessage([[
				Rumors have begun circulating that your champion has been seen near your capital. After years of solitary
				wandering, is he finally returning to lead the battle against Volsang? Your heart rises to your throat with
				the sudden hope this thought brings. 
			]]))
			for i = 1,7 do
				table.insert(state.spawnQueue, {turnsLeft=math.random(1,5), unitId=tribeData[i].hero.id, tribeId=i, locations={}, options={veteran=true, inCapital=true}})
			end
		end)
	end

	-- Display message when everlasting life goblet completed (NEW)
	if isGobletCompleted(civ.getPlayerTribe().id) then
		justOnce("J1GobletFinished", function()
			targetedMessage(civ.getPlayerTribe(), {sound="Shortking.wav", msg=[[
				You place into the goblet of everlasting life you found in Rot the three gems you have acquired in your travels: 
				The sapphire from the ugly prince,
				the ruby from the island of giant flytraps,
				and the emerald extracted from Jormungand's tail.
				Suddenly the goblet fills itself with a pale gold liquid.
				You hand the goblet to your hero. Your hero is now immortal!
			]]})
		end)
	end
end)

registerEvent("onUnitKilled", function(killed, killer)
	-- Respawn heroes
	if isGobletCompleted(killed.owner.id) and isUnitAHero(killed.type.id) then
		targetedMessage(killed.owner, {sound="Fanfare7.wav", msg=[[
			Your hero drinks from the goblet and reappears in your capital, completely restored to life.
		]]})
		civlua.createUnit(tribeData[killed.owner.id].hero, killed.owner, {}, {veteran=true, inCapital=true})
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- CALL TO ARMS
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if state.volsang >= 1 then
		justOnce("J1CTAStart", function()
			civ.ui.text(formatMessage([[
				A sudden influx of Jack O'Lanterns in the region generally means they have important information to
				impart for a price. 
			]]))
			local spawnsSurface = {{38,60,0}, {44,60,0}, {46,114,0}, {39,133,0}, {87,57,0}, {93,51,0}, {30,66,0}, {93,131,0}, {60,36,0}, {61,33,0}}
			local spawnsUnderground = {{73,67,2}, {49,77,2}, {47,63,2}}
			civlua.createUnit(UNITTYPE.jackOLantern, TRIBE.barbarians, spawnsSurface, {count=6, randomize=true})
			civlua.createUnit(UNITTYPE.jackOLantern, TRIBE.barbarians, spawnsUnderground, {})
		end)
	end

	-- End call to arms
	if state.volsang >= 2 and civ.getPlayerTribe():hasTech(TECH.aCallToArms) then
		justOnce("J1EndCallToArms", function()
			civ.playSound("Fanfare7.wav")
			civ.ui.text(formatMessage([[
				Volsang has now grown so powerful that the other races have become too frightened to respond to the 'call
				to arms'.
			]]))
			-- TODO: Delete flag units
		end)
	end
end)

registerEvent("onBribeUnit", function(unit, prevOwner)
	if unit.type == UNITTYPE.jackOLantern and prevOwner == TRIBE.barbarians and state.volsang == 1 then
		-- Used to be when volsang >= 1, but it doesn't work when volsang > 1 so don't show message when > 1
		if civ.getPlayerTribe() == unit.owner then
			civ.playSound("Fanfare7.wav")
			civ.ui.text(formatMessage([[
				Overcome by such excitement that he barely can take a breath, Jack exclaims that you must send an envoy
				to visit the foreign embassy of every capital with a call to arms before Volsang can 
				further loosen his magical bonds. In the face of a common danger, the other races will likely provide 
				you with units and money but don't delay before they change their minds. He says the embassies are 
				usually  not found in the capital but directly to the north of it.  Jack also mentions that the Dwarven King 
				might come to your assistance for a price. You should look for him in the far north.
			]]))
			civ.giveTech(unit.owner, TECH.aCallToArms)
			justOnce("J1CallToArms", function()
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.humans, {{39,71,0}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.infidels, {{48,124,0}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.elves, {{92,54,0}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.merfolk, {{28,56,1}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.buteos, {{60,34,3}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.goblins, {{60,62,2}}, {})
				civlua.createUnit(UNITTYPE.flagUnit, TRIBE.stygians, {{87,135,2}}, {})
			end)
		end
	end
end)

registerEvent("onUnitKilled", function(killed, killer)
	if state.volsang == 1 and killed.type == UNITTYPE.flagUnit then
		if killed.owner == TRIBE.humans then
			justOnce("J1HumanCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Humans hear the call to arms and contribute 500 gold and a captured Frost Giant they were saving for
					the final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{39,71,0}, {39,69,0}, {39,67,0}, {38,68,0}, {40,68,0}, {40,66,0}}
				civlua.createUnit(UNITTYPE.frostGiant, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.infidels then
			justOnce("J1InfidelCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Infidels hear the call to arms and contribute 500 gold and a captured Frost Giant they were saving for
					the final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{48,124,0}, {48,122,0}, {48,120,0}, {47,121,0}, {49,123,0}, {46,122,0}, {49,123,0}}
				civlua.createUnit(UNITTYPE.frostGiant, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.elves then
			justOnce("J1ElvesCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Elves hear the call to arms and contribute 500 gold and a captured Frost Giant they were saving for the
					final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{92,54,0}, {92,52,0}, {93,51,0}, {91,51,0}, {93,65,0}, {96,64,0}}
				civlua.createUnit(UNITTYPE.frostGiant, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.merfolk then
			justOnce("J1MerfolkCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Merfolk hear the call to arms and contribute 500 gold and a captured Kraken they were saving for the
					final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{27,59,1}, {30,58,1}, {25,59,1}, {24,58,1}, {24,56,1}, {24,54,1}}
				civlua.createUnit(UNITTYPE.mKraken, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.buteos then
			justOnce("J1ButeoCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Buteos hear the call to arms and contribute 500 gold and a captured Griffin they were saving for the
					final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{60,34,3}, {60,32,3}, {62,32,3}, {58,32,3}, {59,31,3}, {61,31,3}, {62,34,3}, {58,34,3}}
				civlua.createUnit(UNITTYPE.bGriffin, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.goblins then
			justOnce("J1GoblinCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Goblins hear the call to arms and contribute 500 gold and a captured Worm they were saving for the
					final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{60,62,2}, {60,60,2}, {59,61,2}, {58,62,2}, {59,59,2}, {62,60,2}, {58,60,2}, {57,61,2}}
				civlua.createUnit(UNITTYPE.worm, killer.owner, spawns, {})
			end)
		elseif killed.owner == TRIBE.stygians then
			justOnce("J1StygianCTA", function()
				targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
					The Stygians hear the call to arms and contribute 500 gold and a captured Worm they were saving for the
					final defense of their capital.
				]]})
				killer.owner.money = killer.owner.money + 500
				local spawns = {{87,135,2}, {88,134,2}, {86,136,2}, {89,133,2}, {84,138,2}, {85,131,2}, {91,135,2}}
				civlua.createUnit(UNITTYPE.worm, killer.owner, spawns, {})
			end)
		end
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- RAGNAROK
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if state.volsang >= 4 then
		justOnce("J1OneRing", function()
			targetedMessage(civ.getPlayerTribe(), {sound="Fanfare7.wav", msg=[[
				All of the races hold an emergency council to consider and recommend what 
				measures, if any, can be undertaken to stave off Volsang. After hours of 
				useless debate that usually occurs when no one has any ideas, a small 
				voice from the back squeaks, "We might try to find the legendary one 
				true ring." Everyone shouts in unison, "Why didn't I think of that? What 
				is the one true ring?" You recall the legend of the one ring which can 
				bring untold wealth and the power it can buy. You seem to be the only 
				one who also remembers that a curse was attached to it although you 
				never heard what it was about. It was lost at sea with the wreck of a 
				treasure ship. The council now disperses very pleased with itself. 
			]]})
			changeTerrain({map=MAPS.underwater, terrainType=BASETERRAIN.underwater.goldenShipwreck, mapRect={113,159,113,159,113,159,113,159}})
			civlua.createUnit(UNITTYPE.flagUnit, TRIBE.barbarians, {{113,159,1}}, {})
			civlua.createUnit(UNITTYPE.sSkeleton, TRIBE.barbarians, {{113,159,1}}, {})
		end)
	end
end)

registerEvent("onUnitKilled", function(killed, killer)
	if killed.owner == TRIBE.barbarians and killed.location.z == 1 and killed.type == UNITTYPE.flagUnit then
		civ.playMusic(3)
		targetedMessage(killer.owner, {msg=[[
			You've found the one, true Ring in the hold of the wrecked
			treasure ship. Obeying an irresistable urge, you put it on your
			forefinger. Suddenly the heavens burst open with a celestial 
			fireworks display that penetrates everywhere even to the bottom 
			of the sea. Whether this otherworldly phenomena presages good 
			or evil, only time will tell.
		]]})
		killer.owner.money = killer.owner.money + 10000
		killer.owner.betrayals = 0
		state.ragnarokTribe = killer.owner.id
		civ.giveTech(TRIBE.stygians, TECH.ragnarok)
	end
end)

registerEvent("onTurn", function(turn)
	if civ.hasTech(TRIBE.stygians, TECH.ragnarok) then
		if math.random(1, 16) == 1 then
			TRIBE.stygians:takeTech(TECH.ragnarok)
		elseif math.random(1, 20) == 1 then
			justOnce("J1Ragnarok", function()
				targetedMessage(civ.getPlayerTribe(), {sound="Rangarok.wav", msg=[[
					Putting on the true ring has unleashed the cataclysmic battle,
					Ragnarok, between the gods and the titans of the frozen north. 
					The outcome is inevitable and the titans win. Midgard is turned 
					into a frozen wasteland.
				]]})
				local ragnarokTribe = civ.getTribe(state.ragnarokTribe)
				ragnarokTribe.money = math.max(0, ragnarokTribe.money - 10000)
				ragnarokTribe.betrayals = 7
				civ.giveTech(TRIBE.goblins, TECH.ragnarok)
				--Except: 10011110001
				changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.iceBarrens, exceptionMask=0x04E1, mapRect={0,0,121,0,121,162,0,162}})
				--Except: 10011110010
				-- Bug fix? maps 1-3 go out of bounds because x and y are flipped (was {0,0,149,0,149,119,0,119}, should be {0,0,119,0,119,149,0,149})
				-- in fact why not just use the full damn map
				changeTerrain({map=MAPS.underwater, terrainType=BASETERRAIN.underwater.iceCap, exceptionMask=0x04E2, mapRect={0,0,121,0,121,162,0,162}})
				--Except: 10001001001
				changeTerrain({map=MAPS.underworld, terrainType=BASETERRAIN.underworld.tunnel, exceptionMask=0x0449, mapRect={0,0,121,0,121,162,0,162}})
				--Except: 01100100011
				changeTerrain({map=MAPS.cloudworld, terrainType=BASETERRAIN.cloudworld.sky, exceptionMask=0x0323, mapRect={0,0,121,0,121,162,0,162}})
			end)
		end
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- BIFROST
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onTurn", function(turn)
	if getNumQuestsDone() >= 10 and TECH.griffinCulture.researched then
		justOnce("J1BifrostStart", function()
			targetedMessage(civ.getPlayerTribe(), {sound="Shortking.wav", msg=[[
				For reasons you still don't fully understand, you hold an emergency meeting with the other races, collect all 
				of the fragments found, and look at the pieced together parchment by its reflection in Glorianda's Mirror. 
				You can read a comprehensible message! It says, "To the reader of this document, We, the gods of Asgard, 
				foresaw the returning power of Volsang many centuries ago so devised a test to determine the worthiness 
				of the inhabitants to procure our aid. You have met the challenge and are a true hero of Midgard. You must 
				undergo one final test, however. Find Bifrost, the rainbow bridge that leads to our home and we will help 
				you defeat Volsang forever."
			]]})
			changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.iceBarrens, mapRect={51,87,51,87,51,89,51,89}})
			civlua.createUnit(UNITTYPE.flagUnit, TRIBE.barbarians, {{51,89,0}}, {})
		end)
	end

	-- Random chance to just give bifrost to anyone with deep future tech research
	if math.random(1, 20) == 1 then
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			if tribe.futureTechs >= 20 then
				civ.playMusic(3)
				targetedMessage(tribe, {msg=[[
					While hanging from Yggdrasil, the tree of life, you involuntarily begin to recite a magical incantation. At
					its conclusion, you see in your mind's eye the precise location of Bifrost. 
				]]}, {msg=[[
					While hanging from Yggdrasil, the {TRIBE} discover the precise location of Bifrost. 
				]]})
				civ.giveTech(tribe, TECH.bifrost)
			end
		end
	end

	if TECH.bifrost.researched then
		local winner = findResearcher(TECH.bifrost)
		targetedMessage(winner, {msg=[[
			You have found Bifrost, the rainbow bridge that leads to Asgard, the home of the gods. He convinces 
			Odin, the chief god, to join your cause and, with his support, the races easily overcome the evil wizard, 
			Volsang, and expel him from Midgard forever. YOU ARE DECLARED THE SAVIOR OF MIDGARD AND HAVE WON THE GAME!
		]]}, {msg=[[
			The {TRIBE} have found Bifrost, the rainbow bridge that leads to Asgard, the home of the gods. He convinces 
			Odin, the chief god, to join your cause and, with his support, the races easily overcome the evil wizard, 
			Volsang, and expel him from Midgard forever. THE HERO OF BIFROST IS DECLARED THE
			SAVIOR OF MIDGARD AND HAS WON THE GAME!
		]]})
		changeTerrain({map=MAPS.surface, terrainType=BASETERRAIN.surface.oldForest, exceptionMask=0x0624, mapRect={0,0,121,0,121,161,0,161}})
		civ.playAviFile("Scene8.avi")
		civ.endGame(true)
	end
end)

registerEvent("onUnitKilled", function(killed, killer)
	if getNumQuestsDone() >= 10 and killed.type == UNITTYPE.flagUnit and killed.owner == TRIBE.barbarians then
		targetedMessage(killer.owner, {sound="Fanfare7.wav", msg=[[
			In one last desperate attempt to prevent you speaking with the gods, Volsang teleports his chief lieutenant
			to block your passage across Bifrost.
		]]}, {sound="Fanfare7.wav", msg=[[
			The {TRIBE} have located Bifrost. In one last desperate attempt to prevent them from speaking with the gods, Volsang teleports his chief lieutenant
			to block their passage across Bifrost.
		]]})
		civlua.createUnit(UNITTYPE.unspHorror, TRIBE.barbarians, {{51,89,0}}, {veteran=true})
	end

	if getNumQuestsDone() >= 10 and killed.type == UNITTYPE.unspHorror and killed.owner == TRIBE.barbarians then
		civ.giveTech(killer.owner, TECH.bifrost)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- SIEGE ENGINE
----------------------------------------------------------------
----------------------------------------------------------------
civ.scen.onCentauriArrival(function (tribe)
	local shipSize = math.min(tribe.spaceship.habitation, tribe.spaceship.lifesupport, tribe.spaceship.solar)
	if shipSize == 1 then
		targetedMessage(civ.getPlayerTribe(), {msg=[[
			After a long journey filled with many delays and perils, the siege engine launches the infernal sphere at
			Volsang's fortress. Volsang is hurled through the atmosphere beyond all the planes of existence. There is
			great celebration everywhere as Volsang's evil fortress is torn asunder. The magicians wag their heads
			however and are heard to mutter, "He was not sent far enough. He could return in less than a lifetime."
			EVERYONE CONGRATULATES THE HERO WHO BUILT THE GREAT SIEGE ENGINE. HE HAS SAVED MIDGARD THOUGH HIS VICTORY MIGHT HAVE BEEN MORE COMPLETE IF HE
			HAD FASHIONED A LARGER WEAPON!
		]]})
	elseif shipSize == 2 then
		targetedMessage(civ.getPlayerTribe(), {msg=[[
			After a long journey filled with many delays and perils, the siege engine launches the infernal sphere at
			Volsang's fortress. Volsang is hurled through the atmosphere beyond all the planes of existence. There is
			great celebration everywhere as Volsang's evil fortress is torn asunder. The magicians wag their heads
			however and are heard to mutter, "He was not sent far enough. He could return in less than two lifetimes."
			EVERYONE CONGRATULATES THE HERO WHO BUILT THE GREAT SIEGE ENGINE. HE HAS SAVED MIDGARD THOUGH HIS VICTORY MIGHT HAVE BEEN MORE COMPLETE IF HE
			HAD FASHIONED A LARGER WEAPON!
		]]})
	elseif shipSize == 3 then
		targetedMessage(civ.getPlayerTribe(), {msg=[[
			After a long journey filled with many delays and perils, the siege engine launches the infernal sphere at
			Volsang's fortress. Volsang is hurled through the atmosphere beyond all the planes of existence. There is
			great celebration everywhere as Volsang's evil fortress is torn asunder. The magicians wag their heads
			however and are heard to mutter, "He was not sent far enough. He could return in less than three lifetimes."
			EVERYONE CONGRATULATES THE HERO WHO BUILT THE GREAT SIEGE ENGINE. HE HAS SAVED MIDGARD THOUGH HIS VICTORY MIGHT HAVE BEEN MORE COMPLETE IF HE
			HAD FASHIONED A LARGER WEAPON!
		]]})
	elseif shipSize >= 4 then
		targetedMessage(civ.getPlayerTribe(), {msg=[[
			After a long journey filled with many delays and perils, the siege engine launches the infernal sphere at
			Volsang's fortress. Volsang is hurled through the atmosphere beyond all the planes of existence. There is
			great celebration everywhere as Volsang's evil fortress is torn asunder. The magicians nod their heads in
			approval.. "You have rid us of Volsang forever.", they cry.
			EVERYONE CONGRATULATES THE HERO WHO BUILT THE GREAT SIEGE ENGINE. HE HAS SAVED MIDGARD FOREVER AND WON A COMPLETE VICTORY!!
		]]})
	end
	civ.endGame(true)
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- QUEST STATUS
----------------------------------------------------------------
----------------------------------------------------------------
registerEvent("onKeyPress", function(key)
	if key == INFOKEY then
		local playerState = state.tribeState[civ.getPlayerTribe().id]

		local infoStrings = {"MIDGARD STATUS"}
		table.insert(infoStrings, "Volsang threat level: " .. state.volsang)
		table.insert(infoStrings, "Next Volsang threat increase: " .. state.volsangCountdown .. " turns")
		table.insert(infoStrings, "-------------")
		table.insert(infoStrings, "BIFROST QUESTS")
		for quest, isDone in pairs(state.questsDone) do
			table.insert(infoStrings, quest .. ": " .. tostring(isDone))
		end
		table.insert(infoStrings, "-------------")
		table.insert(infoStrings, "EVERLASTING LIFE")
		for gem, isFound in pairs(playerState.gemsFound) do
			table.insert(infoStrings, gem .. ": " .. tostring(isFound))
		end
		table.insert(infoStrings, "-------------")
		table.insert(infoStrings, "Capitals taken: " .. getNumCapitalsTaken(civ.getPlayerTribe().id))

		civ.ui.text(formatMessage(table.concat(infoStrings, "\r\n^")))
	elseif key == DEBUGKEY then
		-- print(state)
	end
end)

----------------------------------------------------------------
----------------------------------------------------------------
-- EVENTS
----------------------------------------------------------------
----------------------------------------------------------------
-- if isDebug and debugFuncs.debugEventRegister then
-- 	for eventName, events in pairs(debugFuncs.debugEventRegister) do
-- 		for i, fn in pairs(events) do
-- 			registerEvent(eventName, fn)
-- 		end
-- 	end
-- end

civ.scen.onLoad(function (buffer)
	print("Loading saved state")
	state = civlua.unserialize(buffer)
end)

civ.scen.onSave(function () 
	return civlua.serialize(state) 
end)

civ.scen.onScenarioLoaded(function ()
	civ.playMusic(10)
	-- DONTPLAYWONDERS
	doTweaks()
end)

civ.scen.onSchism(function () return false end)

civ.scen.onKeyPress(function(key)
	for i, fn in pairs(eventRegister.onKeyPress) do
		fn(key)
	end
end)

civ.scen.onTurn(function (turn)
	for i, fn in pairs(eventRegister.onTurn) do
		fn(turn)
	end
end)

civ.scen.onUnitKilled(function (killed, killer)
	for i, fn in pairs(eventRegister.onUnitKilled) do
		fn(killed, killer)
	end
end)

civ.scen.onBribeUnit(function (unit, prevOwner)
	for i, fn in pairs(eventRegister.onBribeUnit) do
		fn(unit, prevOwner)
	end
end)

civ.scen.onCityDestroyed(function (city)
	for i, fn in pairs(eventRegister.onCityDestroyed) do
		fn(city)
	end
end)

civ.scen.onCityTaken(function (city, defender)
	for i, fn in pairs(eventRegister.onCityTaken) do
		fn(city, defender)
	end
end)

civ.scen.onCityProduction(function (city, prod)
	for i, fn in pairs(eventRegister.onCityProduction) do
		fn(city, prod)
	end
end)

setInitialState()

----------------------------------------------------------------
----------------------------------------------------------------
-- DEBUG FUNCTIONS
----------------------------------------------------------------
----------------------------------------------------------------

resetState = function()
	setInitialState()
	print("State reset")
end

printState = function()
	print(civlua.serialize(state))
end

giveAllGems = function()
	local playerTribeId = civ.getPlayerTribe().id
	state.tribeState[playerTribeId].gemsFound.ruby = true
	state.tribeState[playerTribeId].gemsFound.sapphire = true
	state.tribeState[playerTribeId].gemsFound.emerald = true
	state.tribeState[playerTribeId].gemsFound.goblet = true
	print("All everlasting life gems granted to player")
end

completeAllQuests = function()
	for questId, questDone in pairs(state.questsDone) do
		state.questsDone[questId] = true
	end
	print("All quests completed")
end

triggerVolsang = function()
	state.volsangCountdown = 0
	print("Volsang will be triggered next turn")
end
