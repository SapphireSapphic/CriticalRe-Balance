LUAGUI_NAME = "Critical Re:Balance"
LUAGUI_AUTH = "SapphireSapphic"
LUAGUI_DESC = "Rebalances a variety of things in the game, with the goal of improving the Critical and/or Level 1 experience."

function _OnInit()
	if (GAME_ID == 0xF266B00B or GAME_ID == 0xFAF99301) and ENGINE_TYPE == "ENGINE" then --PCSX2
		ConsolePrint("Critical Re:Balance PCSX2")
		onPC=false
		Save = 0x032BB30 --Save File
		Sys3 = 0x1CCB300 --03system.bin
		Btl0 = 0x1CE5D80 --00battle.bin	
		Now = 0x032BAE0 --Current Location
		Slot1    = 0x1C6C750 --Unit Slot 1
		NextSlot = 0x268
	elseif GAME_ID == 0x431219CC and ENGINE_TYPE == "BACKEND" then
		onPC=true
		ConsolePrint("Critical Re:Balance")
		Save = 0x09A7070 - 0x56450E
		Sys3 = 0x2A59DB0 - 0x56450E
		Btl0 = 0x2A74840 - 0x56450E	
		offset = 0x56454E
		Now = 0x0714DB8 - offset
		Slot1    = 0x2A20C58 - 0x56450E
		NextSlot = 0x278
		--need to find PCSX2 Equivelant to these values
			Hurricane = 0x2A98006 -offset
			DrawRange = 0x2A20EA0 -offset
			DistanceDash = 0x2A94BD4 -offset
			DistanceDash2 = 0x2A94CBC -offset
			DistanceDash3 = 0x2A94DCC -offset
	end
	curLvlAdr = Save + 0x24F0 + 0x000F
	curDiffAdr = Save + 0x2498
	abilOff = 0x0054
	sora = Save + 0x24F0
	curHPAdr = sora + 0x04
	maxHPAdr = sora + 0x05
	maxMPAdr = sora + 0x07
	donald = Save + 0x2604
	goofy = Save + 0x2718
	mickey = Save + 0x282C
	auron = Save + 0x2940
	mulan = Save + 0x2A54
	aladdin = Save + 0x2B68
	capJack = Save + 0x2C7C
	beast = Save + 0x2D90
	skelJack = Save + 0x2EA4
	simba = Save + 0x2FB8
	tron = Save + 0x30CC
	riku = Save + 0x31E0
	partyList = {sora, donald, goofy, auron, mulan, aladdin, capJack, beast, skelJack, simba, tron, riku}
	valor = Save + 0x32FE + 0x0016 + 0x0004-- First Unused Slot, accounting for my form movement mod
	wisdom = Save + 0x3336 + 0x000E + 0x000A
	limit = Save + 0x336E + 0x0008
	master = Save + 0x33A6 + 0x0014 + 0x000A
	final = Save + 0x33DE + 0x0010 + 0x000A
	anti = Save + 0x340C + 0x000C + 0x000A
	isBoosted = {"Init"}
	FireTierAdr = Save + 0x3594
	BlizzTierAdr = Save + 0x3595
	ThunTierAdr = Save + 0x3596
	CureTierAdr = Save + 0x3597
	MagTierAdr = Save + 0x35CF
	RefTierAdr = Save +	0x35D0
	soraMPRewrite = 60
	startMP = 60
	vanillaMPbonus = 10
	Slot2  = Slot1 - NextSlot
	Slot3  = Slot2 - NextSlot
	Slot4  = Slot3 - NextSlot
	Slot5  = Slot4 - NextSlot
	Slot6  = Slot5 - NextSlot
	Slot7  = Slot6 - NextSlot
	Slot8  = Slot7 - NextSlot
	Slot9  = Slot8 - NextSlot
	Slot10 = Slot9 - NextSlot
	Slot11 = Slot10 - NextSlot
	Slot12 = Slot11 - NextSlot
end

function Events(M,B,E) --Check for Map, Btl, and Evt
return ((Map == M or not M) and (Btl == B or not B) and (Evt == E or not E))
end

function giveAbility(character, abilityCode)
	if character == "party" then
		for partyMem = 2,12 do
			for Slot = 0,80 do
				local Current = partyList[partyMem] + abilOff + 2*Slot
				local Ability = ReadShort(Current)
				if Ability == 0x0000 then
					WriteShort(Current, abilityCode + 0x8000)
					return
				end
			end
		end
	else
		for Slot = 0,80 do
			local Current = character + abilOff + 2*Slot
			local Ability = ReadShort(Current)
			if Ability == 0x0000 then
				WriteShort(Current, abilityCode + 0x8000)
				return
			end
		end
	end
end

function _OnFrame()
	-- define crucial variables
	World  = ReadByte(Now+0x00)
	Room   = ReadByte(Now+0x01)
	Place  = ReadShort(Now+0x00)
	Door   = ReadShort(Now+0x02)
	Map    = ReadShort(Now+0x04)
	Btl    = ReadShort(Now+0x06)
	Evt    = ReadShort(Now+0x08)
	PrevPlace = ReadShort(Now+0x30)
	if ReadByte(curLvlAdr) == 0x01 then
		for Slot = 0,80 do
			local Current = sora +abilOff+ 2*Slot
			local Ability = ReadShort(Current)
			if Ability == 0x8194 then
				lvl1 = true
			end
		end
	else
		lvl1 = false
	end
	curDiff = ReadByte(curDiffAdr)
	if curDiff == 0x03 then
		crit = true
	else
		crit = false
	end
	
	--Execute functions
	sysEdits()
	giveBoost()
	newGame()
	gameplay()
	if lvl1 == true then
		betterLvl1()
	end
end

function newGame()
	if Place == 0x2002 and Events(0x01,Null,0x01) then --Station of Serenity Weapons
		
		--Start all characters with all abilities equipped, except auto limit
		for partyMem = 1,13 do
			for Slot = 0,80 do
				local Current = partyList[partyMem] + abilOff + 2*Slot
				local Ability = ReadShort(Current)
				if Ability < 0x8000 and Ability > 0x0000 and Ability ~= 0x01A1 then
					WriteShort(Current,Ability + 0x8000)
				end
			end
			--Start All party members on sora attack	
			if partyMem ~= 1 then
				WriteByte(partyList[partyMem] + 0x00F4, 0x04)
			end
		end
		
		--Starting Inventory Edits
		startMegas = curDiff
		if lvl1 == true then
			startMegas = startMegas*2
		end
		WriteByte(Save+0x3586, startMegas*10) --Start with Megalixirs based on difficulty
	end
end

function giveBoost()
	pCon = ReadByte(Save+0x36B2)
	pNon = ReadByte(Save+0x36B3)
	pPea = ReadByte(Save+0x36B4)
	pCharm = ReadByte(Save+0x3964)
	numProof = pCon + pNon + pPea + pCharm
	FireTier = ReadByte(FireTierAdr)
	BlizzTier = ReadByte(BlizzTierAdr)
	ThunTier = ReadByte(ThunTierAdr)
	MagTier = ReadByte(MagTierAdr)
	RefTier = ReadByte(RefTierAdr)
	CureTier = ReadByte(CureTierAdr)
	totalSpells = FireTier + BlizzTier + ThunTier + MagTier + RefTier + CureTier
	auronWpn = ReadByte(Save+0x35AE)
	mulanWpn = ReadByte(Save+0x35AF)
	beastWpn = ReadByte(Save+0x35B3)
	boneWpn = ReadByte(Save+0x35B4)
	simbaWpn = ReadByte(Save+0x35B5)
	capWpn = ReadByte(Save+0x35B6)
	aladdinWpn = ReadByte(Save+0x35C0)
	rikuWpn = ReadByte(Save+0x35C1)
	tronWpn = ReadByte(Save+0x35C2)
	memCard = ReadByte(Save+0x3643)
	ocStone = ReadByte(Save+0x3644)
	iceCream = ReadByte(Save+0x3649)
	picture = ReadByte(Save+0x364A)
	if ReadByte(Save+0x36C0) & 0x01 == 0x01 then
		stitch = 0x01
	else
		stitch = 0
	end
	if ReadByte(Save+0x36C0) & 0x02 == 0x02 then
		valorObt = 0x01
	else
		valorObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x04 == 0x04 then
		wisdomObt = 0x01
	else
		wisdomObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x08 == 0x08 then
		chicken = 0x01
	else
		chicken = 0
	end
	if ReadByte(Save+0x36C0) & 0x10 == 0x10 then
		finalObt = 0x01
	else
		finalObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x40 == 0x40 then
		masterObt = 0x01
	else
		masterObt = 0
	end
	if ReadByte(Save+0x36CA) & 0x08 == 0x08 then
		limitObt = 0x01
	else
		limitObt = 0
	end
	if ReadByte(Save+0x36C4) & 0x10 == 0x10 then
		genie = 0x01
	else
		genie = 0
	end
	if ReadByte(Save+0x36C4) & 0x20 == 0x20 then
		peter = 0x01
	else
		peter = 0
	end
	if ReadByte(Save+0x36C4) & 0x40 == 0x40 then
		report1 = 0x01
	else
		report1 = 0
	end
	if ReadByte(Save+0x36C4) & 0x80 == 0x80 then
		report2 = 0x01
	else
		report2 = 0
	end
	if ReadByte(Save+0x36C5) & 0x01 == 0x01 then
		report3 = 0x01
	else
		report3 = 0
	end
	if ReadByte(Save+0x36C5) & 0x02 == 0x02 then
		report4 = 0x01
	else
		report4 = 0
	end
	if ReadByte(Save+0x36C5) & 0x04 == 0x04 then
		report5 = 0x01
	else
		report5 = 0
	end
	if ReadByte(Save+0x36C5) & 0x08 == 0x08 then
		report6 = 0x01
	else
		report6 = 0
	end
	if ReadByte(Save+0x36C5) & 0x10 == 0x10 then
		report7 = 0x01
	else
		report7 = 0
	end
	if ReadByte(Save+0x36C5) & 0x20 == 0x20 then
		report8 = 0x01
	else
		report8 = 0
	end
	if ReadByte(Save+0x36C5) & 0x40 == 0x40 then
		report9 = 0x01
	else
		report9 = 0
	end
	if ReadByte(Save+0x36C5) & 0x80 == 0x80 then
		report10 = 0x01
	else
		report10 = 0
	end
	if ReadByte(Save+0x36C6) & 0x01 == 0x01 then
		report11 = 0x01
	else
		report11 = 0
	end
	if ReadByte(Save+0x36C6) & 0x02 == 0x02 then
		report12 = 0x01
	else
		report12 = 0
	end
	if ReadByte(Save+0x36C6) & 0x04 == 0x04 then
		report13 = 0x01
	else
		report13 = 0
	end
	--Combination Boosts
	if (pPea + pNon + pCon + pCharm) == 4 then
		pAll = 0x01
	else
		pAll = 0x00
	end
	if (FireTier >= 1) and (totalSpells >= 6) and (finalObt >= 1) then
		fireAndFinal = 0x01
	else
		fireAndFinal = 0x00
	end
	if (BlizzTier >=1) and (totalSpells >= 6) and (wisdomObt >=1) then
		blizAndWiz = 1
	else
		blizAndWiz = 0
	end
	if (ThunTier >=1) and (totalSpells >= 6) and (masterObt >=1) then
		thunAndMaster = 1
	else
		thunAndMaster = 0
	end
	if (CureTier >=1) and (totalSpells >= 9) and (limitObt >=1) then
		cureAndLimit = 1
	else
		cureAndLimit = 0
	end
	if (RefTier >= 1) and (totalSpells >= 9) and (masterObt>=1) then
		refAndMaster = 1
	else
		refAndMaster = 0
	end	
	if (MagTier >= 1) and (totalSpells >= 9) and (valorObt>=1) then
		magAndValor = 1
	else
		magAndValor = 0
	end
	if genie + peter + stitch + chicken >= 1 then
		summon = 1
	else
		summon = 0
	end
	if genie + peter + stitch + chicken >= 3 then
		summons3 = 1
	else
		summons3 = 0
	end
	if (FireTier>=3) and (BlizzTier>=3) and (ThunTier>=3) and (CureTier>=3) and (RefTier>=3) and (MagTier>=3) then
		allSpells3 = 1
	else
		allSpells3 = 0
	end
	if (FireTier>=2) and (BlizzTier>=2) and (ThunTier>=2) and (CureTier>=2) and (RefTier>=2) and (MagTier>=2) then
		allSpells2 = 1
	else
		allSpells2 = 0
	end
	if (FireTier>=1) and (BlizzTier>=1) and (ThunTier>=1) and (CureTier>=1) and (RefTier>=1) and (MagTier>=1) then
		allSpells = 1
	else
		allSpells = 0
	end
	if report1 + report2 + report3 + report4 + report5 + report6 + report7 + report8 + report9 + report10 + report11 + report12 + report13 >= 13 then
		reportALL = 1
	else
		reportALL = 0
	end
	if auronWpn + mulanWpn + aladdinWpn + capWpn + beastWpn + boneWpn + simbaWpn + tronWpn + rikuWpn + iceCream + picture >= 11 then
		allVisit = 1
	else
		allVisit = 0
	end
	
	boostTable = {
		{pPea, giveBoost = function() 
			giveAbility(sora, 0x0190) --Combination Boost
			giveAbility(sora, 0x018E) --Form Boost
			WriteByte(Save+0x3674, ReadByte(Save+0x3674)+1)-- Armor slot
		end}, 
		{pNon, giveBoost = function() 
			if lvl1 == true then
				giveAbility(sora, 0x0187)--Air Combo Boost
			else
				giveAbility(sora, 0x0188)--Reaction Boost
			end
			WriteByte(Save+0x3675, ReadByte(Save+0x3675)+1)-- Acc slot
		end}, 
		{pCon, giveBoost = function() 
			if lvl1 == true then
				giveAbility(sora, 0x0186)--Combo Boost
			else
				giveAbility(sora, 0x018D)--Drive Boost
			end
			WriteByte(Save+0x3674, ReadByte(Save+0x3674)+1)-- Armor slot
		end}, 
		{pCharm, giveBoost = function() 
			giveAbility(sora, 0x018E)--Form Boost
			giveAbility(sora, 0x018D)--Drive Boost
			WriteByte(Save+0x3675, ReadByte(Save+0x3675)+1)-- Acc slot
		end}, 
		{auronWpn, giveBoost = function() 
			WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
			WriteByte(Save+0x3580, ReadByte(Save+0x3580)+((curDiff+1)*3))-- Potions
		end}, 
		{mulanWpn, giveBoost = function() 
			WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
			WriteByte(Save+0x3581, ReadByte(Save+0x3581)+((curDiff+1)*3))-- Hi-Potions
		end}, 
		{aladdinWpn, giveBoost = function() 
			WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
			WriteByte(Save+0x3582, ReadByte(Save+0x3582)+((curDiff+1)*3))-- Ethers
		end}, 
		{capWpn, giveBoost = function() 
			WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
			WriteByte(Save+0x3583, ReadByte(Save+0x3583)+((curDiff+1)*3))-- Elixirs
		end}, 
		{beastWpn, giveBoost = function() 
			WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
			WriteByte(Save+0x3584, ReadByte(Save+0x3584)+((curDiff+1)*3))-- Mega-Potions
		end}, 
		{boneWpn, giveBoost = function() 
			WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
			WriteByte(Save+0x3585, ReadByte(Save+0x3585)+((curDiff+1)*3))-- Mega-Ethers
		end}, 
		{simbaWpn, giveBoost = function() 
			WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
			WriteByte(Save+0x3586, ReadByte(Save+0x3586)+((curDiff+1)*3))-- Megalixirs
		end}, 
		{tronWpn, giveBoost = function() 
			WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
			WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff+1)*1))-- Drive Recoveries
		end}, 
		{rikuWpn, giveBoost = function() 
			WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
			WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff+1)*1))-- High Drive Recoveries
		end}, 
		{ocStone, giveBoost = function() 
			WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
			WriteByte(Save+0x35E1, ReadByte(Save+0x35E1)+((curDiff+1)*3))-- Tents
		end}, 
		{iceCream, giveBoost = function() 
			WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
			WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff+1)*1))-- Drive Recoveries
		end}, 
		{picture, giveBoost = function() 
			WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
			WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff+1)*1))-- High Drive Recoveries
		end}, 
		{report1, giveBoost = function() 
			WriteByte(Save+0x3580, ReadByte(Save+0x3580)+((curDiff+1)*3))-- Potions
		end}, 
		{report2, giveBoost = function() 
			WriteByte(Save+0x3581, ReadByte(Save+0x3581)+((curDiff+1)*3))-- Hi-Potions
		end}, 
		{report3, giveBoost = function() 
			WriteByte(Save+0x3582, ReadByte(Save+0x3582)+((curDiff+1)*3))-- Ethers
		end}, 
		{report4, giveBoost = function() 
			WriteByte(Save+0x3583, ReadByte(Save+0x3583)+((curDiff+1)*3))-- Elixirs
		end}, 
		{report5, giveBoost = function() 
			WriteByte(Save+0x3584, ReadByte(Save+0x3584)+((curDiff+1)*3))-- Mega-Potions
		end}, 
		{report6, giveBoost = function() 
			WriteByte(Save+0x3585, ReadByte(Save+0x3585)+((curDiff+1)*3))-- Mega-Ethers
		end}, 
		{report7, giveBoost = function() 
			WriteByte(Save+0x3586, ReadByte(Save+0x3586)+((curDiff+1)*3))-- Megalixirs
		end}, 
		{report8, giveBoost = function() 
			WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff+1)*1))-- Drive Recoveries
		end}, 
		{report9, giveBoost = function() 
			WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff+1)*1))-- High Drive Recoveries
		end}, 
		{report10, giveBoost = function() 
			WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff+1)*1))-- High Drive Recoveries
		end}, 
		{report11, giveBoost = function() 
			WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff+1)*1))-- Drive Recoveries
		end}, 
		{report12, giveBoost = function() 
			WriteByte(Save+0x35B1, ReadByte(Save+0x35B1)+3)-- Cosmic Arts
		end}, 
		{report13, giveBoost = function() 
			WriteByte(Save+0x35B1, ReadByte(Save+0x35B1)+3)-- Cosmic Arts
		end}, 
		{pAll, giveBoost = function() 
			--Nothing apparently
		end}, 
		{allVisit, giveBoost = function() 
			giveAbility(sora, 0x0256)--Protectga
			giveAbility(sora, 0x0186)--Combo Boost
		end}, 
		{reportALL, giveBoost = function() 
			giveAbility(sora, 0x0256)--Protectga
			giveAbility(sora, 0x0187)--Air Combo Boost
		end},		
		{fireAndFinal, giveBoost = function() 
			giveAbility(sora, 0x0198)--Fire Boost
		end}, 
		{blizAndWiz, giveBoost = function() 
			giveAbility(sora, 0x0199)--Blizzard Boost
		end}, 
		{thunAndMaster, giveBoost = function() 
			giveAbility(sora, 0x019A)--Thunder Boost
		end}, 
		{cureAndLimit, giveBoost = function() 
			giveAbility(sora, 0x0190)--Combination Boost
			giveAbility(sora, 0x0192)--Leaf Bracer
		end}, 
		{refAndMaster, giveBoost = function() 
			giveAbility(sora, 0x018E)--Form Boost
		end}, 
		{magAndValor, giveBoost = function() 
			giveAbility(sora, 0x018D)--Drive Boost
		end}, 
		{allSpells, giveBoost = function() 
			giveAbility(sora, 0x01A6)--MP Hastega
		end}, 
		{allSpells2, giveBoost = function() 
			giveAbility(sora, 0x01A6)--MP Hastega
		end}, 
		{allSpells3, giveBoost = function() 
			giveAbility(sora, 0x01A6)--MP Hastega
		end}, 
		{summon, giveBoost = function() 
			giveAbility(sora, 0x018F)--Summon Boost
		end}, 
		{summons3, giveBoost = function() 
			giveAbility(sora, 0x018F)--Summon Boost
		end}, 
		{totalSpells, giveBoost = function()
			
		end}
	}
	
	if isBoosted[1] == "Init" then
		for boostCheck = 1, #(boostTable) do
			if boostTable[boostCheck][1] >= 0x01 then
				isBoosted[boostCheck] = true
			else
				isBoosted[boostCheck] = false
			end
		end
	else
		for boostCheck = 1, #(boostTable) do
			if boostTable[boostCheck][1] >= 0x01 and isBoosted[boostCheck] == false then
				--Has item, does not have boost
				if lvl1 == true or boostCheck <= 29 then
					ConsolePrint("Giving Boost for - "..boostCheck)
					boostTable[boostCheck].giveBoost()
				end
				isBoosted[boostCheck] = true
			end
		end
	end
	
	if ReadByte(Save+0x3672) > 0 then
		local Bonus
		if curDiff < 3 then --Non-Critical
			Bonus = 10
		else --Critical
			Bonus = 5
		end
		vanillaMPbonus = vanillaMPbonus + Bonus
	end
end

function gameplay()
	if lvl1 == true then
		MPbonus2 = 2
	else
		MPbonus2 = 1
	end
	startMP = (curDiff+3)*10
	soraMPRewrite = startMP + vanillaMPbonus + (totalSpells * (2+curDiff) * MPbonus2)
	--WriteInt(Slot1+0x180,soraMPRewrite)
	WriteInt(Slot1+0x184,soraMPRewrite)

	statsBoost = (numProof+1) * 20
	for partyMem = 2,12 do
		WriteByte(partyList[partyMem]+0x08,statsBoost)--AP
		WriteByte(partyList[partyMem]+0x09,statsBoost)--Power
		WriteByte(partyList[partyMem]+0x0A,statsBoost)--Magic
		WriteByte(partyList[partyMem]+0x0B,statsBoost)--Def
	end
	
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 and onPC == true then
		WriteShort(limit, 0x8107) --Distance Step / Dodge Slash
	end
end

function betterLvl1()
	--Boost stats based on how much dmg sora has
	numProof = pCon + pNon + pPea + pCharm
	maxHP = ReadByte(maxHPAdr)
	curHP = ReadByte(curHPAdr)
	curDiff = ReadByte(curDiffAdr)
	boostBy = math.floor((numProof+curDiff+1)/2)
	statsBoost = boostBy * (maxHP - curHP)
	WriteByte(sora+0x09,statsBoost)--Power
	WriteByte(sora+0x0A,statsBoost)--Magic
	WriteByte(sora+0x0B,statsBoost+((boostBy+1)*5))--Def
	
--Extra form abilities
	--valor
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 then
		WriteShort(valor, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x03 then
		WriteShort(valor+2, 0x81A6) --MP Hastega
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(valor+4, 0x81A0) --Once More
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x05 then
		WriteShort(valor+6, 0x8186) --Combo Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(valor+8, 0x8189) --Finishing Plus
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(valor+10, 0x8187) --Air Combo Boost
	end
	
	--wisdom
	if ReadByte(Save + 0x332C + 0x02) >= 0x02 then
		WriteShort(wisdom, 0x8193) --Magic Lock-On
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x03 then
		WriteShort(wisdom+2, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x04 then
		WriteShort(wisdom+4, 0x8198) --Fire Boost
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x05 then
		WriteShort(wisdom+6, 0x81A0) --Once More
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x06 then
		WriteShort(wisdom+8, 0x8199) --Blizzard Boost
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x07 then
		WriteShort(wisdom+10, 0x819A) --Thunder Boost
	end
	
	--limit
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 and onPC == true then
		WriteShort(limit, 0x8107) --Distance Step / Dodge Slash
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x03 then
		WriteShort(limit+2, 0x8187) --Air Combo Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(limit+4, 0x810F) --Horizontal Slash
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x05 then
		WriteShort(limit+6, 0x8186) --Combo Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(limit+8, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(limit+20, 0x81A0) --Once More
	end
	
	--master
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 then
		WriteShort(master, 0x821C) --Drive Converter
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x03 then
		WriteShort(master+2, 0x8186) --MP Hastega
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(master+4, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x05 then
		WriteShort(master-22, 0x8187) --Air Combo Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(master-24, 0x81A0) --Once More
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(master-26, 0x8187) --Air Combo Boost
	end
	
	--final
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 then
		WriteShort(final, 0x819A) --Thunder Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x03 then
		WriteShort(final+2, 0x8198) --Fire Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(final+4, 0x819A) --Thunder Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x05 then
		WriteShort(final+6, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(final+8, 0x8198) --Fire Boost
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(final-14, 0x81A0) --Once More
	end
end

function sysEdits()
	--Running Speed boost
	base = 10
	faster = 16
	fastest = 20
	WriteFloat(Sys3+0x17CE4, base)--Base Sora
	WriteFloat(Sys3+0x17D18, faster)--Valor
	WriteFloat(Sys3+0x17D4C, faster)--Wis
	WriteFloat(Sys3+0x17D80, faster)--Master
	WriteFloat(Sys3+0x17DB4, fastest)--Final
	WriteFloat(Sys3+0x17E84, base)--Donald
	WriteFloat(Sys3+0x17EEC, base)--Goofy
	WriteFloat(Sys3+0x17F54, base)--Aladdin
	WriteFloat(Sys3+0x17F88, base)--Auron
	WriteFloat(Sys3+0x17FBC, base)--Mulan
	WriteFloat(Sys3+0x17FF0, base)--Ping
	WriteFloat(Sys3+0x18024, base)--Tron
	WriteFloat(Sys3+0x18058, base)--Mickey
	WriteFloat(Sys3+0x1808C, base)--Beast
	WriteFloat(Sys3+0x180C0, base)--Jack Skel
	WriteFloat(Sys3+0x18128, base)--Jack Sparrow
	WriteFloat(Sys3+0x1815C, base)--Riku
	WriteFloat(Sys3+0x18364, base)--Limit Form
	
	--make party members Lvl to 99 super fast
	for partyLevel = 0,98 do
		WriteInt(Btl0+0x25F5C+(0x10 * partyLevel), 1)--Donald
		WriteInt(Btl0+0x26590+(0x10 * partyLevel), 1)--Goofy
		WriteInt(Btl0+0x271F8+(0x10 * partyLevel), 1)--Auron
		WriteInt(Btl0+0x2782C+(0x10 * partyLevel), 1)--Mulan
		WriteInt(Btl0+0x27E60+(0x10 * partyLevel), 1)--Aladdin
		WriteInt(Btl0+0x28494+(0x10 * partyLevel), 1)--Jack Sparrow
		WriteInt(Btl0+0x28AC8+(0x10 * partyLevel), 1)--Beast
		WriteInt(Btl0+0x290FC+(0x10 * partyLevel), 1)--Jack Skellington
		WriteInt(Btl0+0x29730+(0x10 * partyLevel), 1)--Simba
		WriteInt(Btl0+0x29D64+(0x10 * partyLevel), 1)--Tron
		WriteInt(Btl0+0x2A398+(0x10 * partyLevel), 1)--Riku
	end
	
	WriteByte(Sys3+0x0500,1) -- Anti
	WriteByte(Sys3+0x1070,5) -- Stitch
	WriteByte(Sys3+0x10A0,2) -- Genie
	WriteByte(Sys3+0xA40,0x0E)   -- Blizzard Cost: 14
	WriteByte(Sys3+0x1640,0x0E)  -- Blizzara Cost: 14
	WriteByte(Sys3+0x1670,0x0E)  -- Blizzaga Cost: 14
	WriteByte(Sys3+0xA10,0x10)   -- Thunder Cost: 16
	WriteByte(Sys3+0x16A0,0x10)  -- Thundara Cost: 16
	WriteByte(Sys3+0x16D0,0x10)  -- Thundaga Cost: 16
	WriteByte(Sys3+0x1FD0,0x0C)  -- Reflect Cost: 12
	WriteByte(Sys3+0x2000,0x0C)  -- Reflera Cost: 12
	WriteByte(Sys3+0x2030,0x0C)  -- Reflega Cost: 12
	WriteByte(Sys3+0x7E50,0x28)  -- Strike Raid Cost: 40
	if onPC == true then
		WriteFloat(DrawRange, 375)   -- DrawRange3x
		WriteByte(Hurricane, 0x20)   --RemoveHurricaneWinderFloat
		WriteByte(Hurricane+1, 0x42) --RemoveHurricaneWinderFloat
		WriteByte(Hurricane+4, 0x16) --RemoveHurricaneWinderFloat
		WriteByte(Hurricane+5, 0x43) --RemoveHurricaneWinderFloat
		WriteByte(Hurricane+8, 0x20) --RemoveHurricaneWinderFloat
		WriteByte(Hurricane+9, 0x42) --RemoveHurricaneWinderFloat
		WriteFloat(DistanceDash, 2000) --DistanceDash MAXRANGE
		WriteByte(DistanceDash2, 0x36) --Disable DodgeSlash Entry2
		WriteByte(DistanceDash3, 0x36) --Disable DodgeSlash Entry3
	end
end
