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
	valorAnc = Save + 0x32F4
	wisdomAnc = Save + 0x332C
	limitAnc = Save + 0x3364
	masterAnc = Save + 0x339C
	finalAnc = Save + 0x33D4
	valorLvlAdr = valorAnc + 0x02
	wisdomLvlAdr = wisdomAnc + 0x02
	limitLvlAdr = limitAnc + 0x02
	masterLvlAdr = masterAnc + 0x02
	finalLvlAdr = finalAnc + 0x02
	valorLast = 1
	wisdomLast = 1
	limitLast = 1
	masterLast = 1
	finalLast = 1
	valor = valorAnc + 0x0016 + 0x0004 + 0x0A-- First Unused Slot, accounting for my form movement mod
	wisdom = wisdomAnc + 0x000E + 0x000A + 0x0A
	limit = limitAnc + 0x0008 + 0x0A
	master = masterAnc + 0x0014 + 0x000A + 0x0A
	final = finalAnc + 0x0010 + 0x000A + 0x0A
	anti = Save + 0x340C + 0x000C + 0x000A + 0x0A
	isBoosted = {"Reload"}
	FireTierAdr = Save + 0x3594
	BlizzTierAdr = Save + 0x3595
	ThunTierAdr = Save + 0x3596
	CureTierAdr = Save + 0x3597
	MagTierAdr = Save + 0x35CF
	RefTierAdr = Save +	0x35D0
	startMP = 50
	lastSpells = 0
	titleScreenAdr = Now - 0x0654
	loadFlag = 0x453B82
	dontSpam = false
	extraAP = 0
end

function Events(M,B,E) --Check for Map, Btl, and Evt
return ((Map == M or not M) and (Btl == B or not B) and (Evt == E or not E))
end

function giveAbility(character, abilityCode)
	if character == "party" then
		for partyMem = 2,12 do
			abilityGiven = false
			for Slot = 0,80 do
				local Current = partyList[partyMem] + abilOff + 2*Slot
				local Ability = ReadShort(Current) & 0x0FFF
				if Ability == 0x0000 and abilityGiven == false then
					WriteShort(Current, abilityCode + 0x8000)
					abilityGiven = true
				end
			end
		end
	else
		abilityGiven = false
		for Slot = 0,80 do
			local Current = character + abilOff + 2*Slot
			local Ability = ReadShort(Current) & 0x0FFF
			if Ability == 0x0000 and abilityGiven == false then
				WriteShort(Current, abilityCode + 0x8000)
				abilityGiven = true
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
	onTitle = ReadInt(titleScreenAdr)
	if ReadByte(curLvlAdr) == 1 then
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
	if onPC == true then
		loading = ReadByte(loadFlag)
		curHP = ReadByte(curHPAdr)
		if loading == 0 and dontSpam == true then
			dontSpam = false
		end
		if (loading == 1 or curHP < 1) and dontSpam == false and (Place ~= 0x2002 and Events(0x01,Null,0x01)) then
			ConsolePrint("Reloading Boost Table")
			isBoosted = {"Reload"}
			dontSpam = true
		end
	end
	
	--Execute functions
	newGame()
	sysEdits()
	giveBoost()
end

function newGame()
	if Place == 0x2002 and Events(0x01,Null,0x01) then --Station of Serenity Weapons
		valorLast = 1
		wisdomLast = 1
		limitLast = 1
		masterLast = 1
		finalLast = 1	
		--Start all characters with all abilities equipped, except auto limit
		for partyMem = 1,12 do
			for Slot = 0,80 do
				local Current = partyList[partyMem] + abilOff + 2*Slot
				local Ability = ReadShort(Current)
				if Ability < 0x8000 and Ability > 0x0000 and Ability ~= 0x01A1 then
					WriteShort(Current,Ability + 0x8000)
				end
			end
			
			--Starting MP
			startMP = 100-((curDiff+2)*10)
			WriteInt(Slot1+0x180,startMP)
			WriteInt(Slot1+0x184,startMP)
			lastSpells = 0
			
			--Start All party members on sora attack	
			if partyMem ~= 1 then
				WriteByte(partyList[partyMem] + 0x00F4, 0x04)
			end
		end
		
		isBoosted = {"Init"}
		
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
	pCharm = ReadByte(Save+0x3694)
	numProof = pCon + pNon + pPea + pCharm
	statsBoost = (numProof+1) * 10
	for partyMem = 2,12 do
		WriteByte(partyList[partyMem]+0x08,(statsBoost*(curDiff+1)))--AP
		WriteByte(partyList[partyMem]+0x09,statsBoost)--Power
		WriteByte(partyList[partyMem]+0x0A,statsBoost)--Magic
		WriteByte(partyList[partyMem]+0x0B,statsBoost)--Def
	end
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
	valorLvl = ReadByte(valorLvlAdr)
	wisdomLvl = ReadByte(wisdomLvlAdr)
	limitLvl = ReadByte(limitLvlAdr)
	masterLvl = ReadByte(masterLvlAdr)
	finalLvl = ReadByte(finalLvlAdr)
	if ReadByte(Save+0x36C0) & 0x01 == 0x01 then
		stitch = 1
	else
		stitch = 0
	end
	if ReadByte(Save+0x36C0) & 0x02 == 0x02 then
		valorObt = 1
	else
		valorObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x04 == 0x04 then
		wisdomObt = 1
	else
		wisdomObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x08 == 0x08 then
		chicken = 1
	else
		chicken = 0
	end
	if ReadByte(Save+0x36C0) & 0x10 == 0x10 then
		finalObt = 1
	else
		finalObt = 0
	end
	if ReadByte(Save+0x36C0) & 0x40 == 0x40 then
		masterObt = 1
	else
		masterObt = 0
	end
	if ReadByte(Save+0x36CA) & 0x08 == 0x08 then
		limitObt = 1
	else
		limitObt = 0
	end
	if ReadByte(Save+0x36C4) & 0x10 == 0x10 then
		genie = 1
	else
		genie = 0
	end
	if ReadByte(Save+0x36C4) & 0x20 == 0x20 then
		peter = 1
	else
		peter = 0
	end
	if ReadByte(Save+0x36C4) & 0x40 == 0x40 then
		report1 = 1
	else
		report1 = 0
	end
	if ReadByte(Save+0x36C4) & 0x80 == 0x80 then
		report2 = 1
	else
		report2 = 0
	end
	if ReadByte(Save+0x36C5) & 0x01 == 0x01 then
		report3 = 1
	else
		report3 = 0
	end
	if ReadByte(Save+0x36C5) & 0x02 == 0x02 then
		report4 = 1
	else
		report4 = 0
	end
	if ReadByte(Save+0x36C5) & 0x04 == 0x04 then
		report5 = 1
	else
		report5 = 0
	end
	if ReadByte(Save+0x36C5) & 0x08 == 0x08 then
		report6 = 1
	else
		report6 = 0
	end
	if ReadByte(Save+0x36C5) & 0x10 == 0x10 then
		report7 = 1
	else
		report7 = 0
	end
	if ReadByte(Save+0x36C5) & 0x20 == 0x20 then
		report8 = 1
	else
		report8 = 0
	end
	if ReadByte(Save+0x36C5) & 0x40 == 0x40 then
		report9 = 1
	else
		report9 = 0
	end
	if ReadByte(Save+0x36C5) & 0x80 == 0x80 then
		report10 = 1
	else
		report10 = 0
	end
	if ReadByte(Save+0x36C6) & 0x01 == 0x01 then
		report11 = 1
	else
		report11 = 0
	end
	if ReadByte(Save+0x36C6) & 0x02 == 0x02 then
		report12 = 1
	else
		report12 = 0
	end
	if ReadByte(Save+0x36C6) & 0x04 == 0x04 then
		report13 = 1
	else
		report13 = 0
	end
	--Combination Boosts
	if numProof >= 4 then
		pAll = 1
	else
		pAll = 0
	end
	if (FireTier >= 1) and (totalSpells >= 6) and (finalObt >= 1) then
		fireAndFinal = 1
	else
		fireAndFinal = 0
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
	if auronWpn + mulanWpn + aladdinWpn + capWpn + beastWpn + boneWpn + simbaWpn + tronWpn + rikuWpn + iceCream + picture + memCard >= 10 then
		allVisit = 1
	else
		allVisit = 0
	end
	
	statsBoost = 0
	if lvl1 == true then
		statsBoost = math.floor((auronWpn + mulanWpn + aladdinWpn + capWpn + beastWpn + boneWpn + simbaWpn + tronWpn + rikuWpn + iceCream + picture + memCard + ocStone + allVisit + report1 + report2 + report3 + report4 + report5 + report6 + report7 + report8 + report9 + report10 + report11 + report12 + report13 + reportALL + genie + peter + stitch + chicken + totalSpells + numProof + valorLvl + wisdomLvl + limitLvl + masterLvl + finalLvl + fireAndFinal + blizAndWiz + thunAndMaster + cureAndLimit + refAndMaster + magAndValor + allSpells + allSpells2 + allSpells3 + summon + summons3 + pAll)/(curDiff+2))
	end
	extraAP = (curDiff+2) * 11
	WriteByte(sora+0x08,(statsBoost*(curDiff+2)*2)+extraAP)--AP
	WriteByte(sora+0x09,statsBoost)--Power
	WriteByte(sora+0x0A,statsBoost)--Magic
	WriteByte(sora+0x0B,math.floor(statsBoost/((curDiff+1)/2)))--Def
	
	boostVars = {pPea, pNon, pCon, pCharm, auronWpn, mulanWpn, aladdinWpn, capWpn, beastWpn, boneWpn, simbaWpn, tronWpn, rikuWpn, memCard, ocStone, iceCream, picture, report1, report2, report3, report4, report5, report6, report7, report8, report9, report10, report11, report12, report13, pAll, allVisit, reportALL, fireAndFinal, blizAndWiz, thunAndMaster, cureAndLimit, refAndMaster, magAndValor, allSpells, allSpells2, allSpells3, summon, summons3, totalSpells, valorLvl, wisdomLvl, limitLvl, masterLvl, finalLvl}
	boostNames = {"Proof of Peace", "Proof of Nonexistence", "Proof of Connection", "Promise Charm", "Auron Weapon", "Mulan Weapon", "Aladdin Weapon", "Cap Jack Weapon", "Beast Weapon", "Skel Jack Weapon", "Simba Weapon", "Tron Weapon", "Riku Weapon", "Membership Card", "Olympus Stone", "Ice Cream", "Picture", "Ansem Report 1", "Ansem Report 2", "Ansem Report 3", "Ansem Report 4", "Ansem Report 5", "Ansem Report 6", "Ansem Report 7", "Ansem Report 8", "Ansem Report 9", "Ansem Report 10", "Ansem Report 11", "Ansem Report 12", "Ansem Report 13", "All Proofs + Promise Charm", "All Party Weapons", "All Ansem Reports", "Fire and Final", "Blizzard and Wisdom", "Thunder and Master", "Cure and Limit", "Reflect and Master", "Magnet and Valor", "All Teir 1 Spells", "All Teir 2 Spells", "All Teir 3 Spells", "Any One Summon", "Any Three Summons", "Total Spells", "Valor Lvl Up", "Wisdom Lvl Up", "Limit Lvl Up", "Master Lvl Up", "Final Lvl Up"}
	
	if isBoosted[1] == "Init" and Place ~= 0xFFFF and onTitle ~= 1 then
		lastSpells = 0
		for boostCheck = 1, #(boostVars) do
			isBoosted[boostCheck] = false
		end
	elseif isBoosted[1] == "Reload" and Place ~= 0xFFFF and onTitle ~= 1 then
		lastSpells = totalSpells
		valorLast = valorLvl
		wisdomLast = wisdomLvl
		limitLast = limitLvl
		masterLast = masterLvl
		finalLast = finalLvl
		for boostCheck = 1, #(boostVars) do
			if boostVars[boostCheck] >= 1 then
				isBoosted[boostCheck] = true
			else
				isBoosted[boostCheck] = false
			end
		end
	elseif Place ~= 0xFFFF and onTitle ~= 1 then
		for boostCheck = 1, #(boostVars) do
			if boostVars[boostCheck] > 0 and (isBoosted[boostCheck] == false or (lastSpells < totalSpells and boostNames[boostCheck] == "Total Spells") or (valorLast < valorLvl and boostNames[boostCheck] == "Valor Lvl Up") or (wisdomLast < wisdomLvl and boostNames[boostCheck] == "Wisdom Lvl Up") or (limitLast < limitLvl and boostNames[boostCheck] == "Limit Lvl Up") or (masterLast < masterLvl and boostNames[boostCheck] == "Master Lvl Up") or (finalLast < finalLvl and boostNames[boostCheck] == "Final Lvl Up")) then
				--Has item, does not have boost
				ConsolePrint("Giving Boost for - "..boostNames[boostCheck].." x"..boostVars[boostCheck])
				isBoosted[boostCheck] = true
				boostTable(boostCheck, boostNames, boostVars)
			end
		end
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
end

function boostTable(boostCheck, boostNames, boostVars)
	if lvl1 == true then
		itemBoost = 2
	else
		itemBoost = 1
	end
	if boostNames[boostCheck] == "Proof of Peace" then
		giveAbility(sora, 0x0190) --Combination Boost
		if lvl1 == true and curDiff ~= 3 then
			giveAbility(sora, 0x018E) --Form Boost
		end
		WriteByte(Save+0x3674, ReadByte(Save+0x3674)+1)-- Armor slot
		giveAbility("party", 0x256) --Protectga
	elseif boostNames[boostCheck] == "Proof of Nonexistence" then
		if lvl1 == true and curDiff ~= 3 then
			giveAbility(sora, 0x0187)--Air Combo Boost
		else
			giveAbility(sora, 0x0188)--Reaction Boost
		end
		WriteByte(Save+0x3675, ReadByte(Save+0x3675)+1)-- Acc slot
		giveAbility("party", 0x01A4)--Auto Healing
	elseif boostNames[boostCheck] == "Proof of Connection" then
		if lvl1 == true and curDiff ~= 3 then
			giveAbility(sora, 0x0186)--Combo Boost
		else
			giveAbility(sora, 0x018D)--Drive Boost
		end
		WriteByte(Save+0x3674, ReadByte(Save+0x3674)+1)-- Armor slot
		giveAbility("party", 0x01A3)--Hyper Healing
	elseif boostNames[boostCheck] == "Promise Charm" then
		giveAbility(sora, 0x0195)--Draw
		if lvl1 == true and curDiff ~= 3 then
			giveAbility(sora, 0x018D)--Drive Boost
		end
		WriteByte(Save+0x3675, ReadByte(Save+0x3675)+1)-- Acc slot
		giveAbility("party", 0x01A2)--Auto Change
	elseif boostNames[boostCheck] == "Auron Weapon" then
		WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
		WriteByte(Save+0x3580, ReadByte(Save+0x3580)+((curDiff+1)*itemBoost))-- Potions
		giveAbility("party", 0x019B)--Item Boost
	elseif boostNames[boostCheck] == "Mulan Weapon" then
		WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
		WriteByte(Save+0x3581, ReadByte(Save+0x3581)+((curDiff+1)*itemBoost))-- Hi-Potions
		giveAbility("party", 0x019B)--Item Boost
	elseif boostNames[boostCheck] == "Aladdin Weapon" then
		WriteByte(Save+0x35BB, ReadByte(Save+0x35BB)+1)-- Full Bloom +
		WriteByte(Save+0x3582, ReadByte(Save+0x3582)+((curDiff+1)*itemBoost))-- Ethers
		giveAbility("party", 0x019B)--Item Boost
	elseif boostNames[boostCheck] == "Cap Jack Weapon" then
		WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
		WriteByte(Save+0x3583, ReadByte(Save+0x3583)+((curDiff+1)*itemBoost))-- Elixirs
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "Beast Weapon" then
		WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
		WriteByte(Save+0x3584, ReadByte(Save+0x3584)+((curDiff)*itemBoost))-- Mega-Potions
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "Skel Jack Weapon" then
		WriteByte(Save+0x35B7, ReadByte(Save+0x35B7)+1)-- Shadow Archive +
		WriteByte(Save+0x3585, ReadByte(Save+0x3585)+((curDiff)*itemBoost))-- Mega-Ethers
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "Simba Weapon" then
		WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
		WriteByte(Save+0x3586, ReadByte(Save+0x3586)+((curDiff)*itemBoost))-- Megalixirs
		giveAbility("party", 0x019E)--Defender
	elseif boostNames[boostCheck] == "Tron Weapon" then
		WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
		WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff)*itemBoost))-- Drive Recoveries
		giveAbility("party", 0x019E)--Defender
	elseif boostNames[boostCheck] == "Riku Weapon" then
		WriteByte(Save+0x35D3, ReadByte(Save+0x35D3)+1)-- Shock Charm +
		WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff)*itemBoost))-- High Drive Recoveries
		giveAbility("party", 0x019E)--Defender
	elseif boostNames[boostCheck] == "Membership Card" then
		giveAbility(sora, 0x018E)--Form Boost
	elseif boostNames[boostCheck] == "Olympus Stone" then
		WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
		WriteByte(Save+0x35E1, ReadByte(Save+0x35E1)+((curDiff)*itemBoost))-- Tents
		giveAbility("party", 0x021E)--Damage Control
	elseif boostNames[boostCheck] == "Ice Cream" then
		WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
		WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff)*itemBoost))-- Drive Recoveries
		giveAbility("party", 0x021E)--Damage Control
	elseif boostNames[boostCheck] == "Picture" then
		WriteByte(Save+0x35D4, ReadByte(Save+0x35D4)+1)-- Grand Ribbon
		WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff)*itemBoost))-- High Drive Recoveries
		giveAbility("party", 0x021E)--Damage Control
	elseif boostNames[boostCheck] == "Ansem Report 1" then
		WriteByte(Save+0x3580, ReadByte(Save+0x3580)+((curDiff+1)*itemBoost))-- Potions
		giveAbility("party", 0x0196)--Jackpot
	elseif boostNames[boostCheck] == "Ansem Report 2" then
		WriteByte(Save+0x3581, ReadByte(Save+0x3581)+((curDiff+1)*itemBoost))-- Hi-Potions
		giveAbility("party", 0x0196)--Jackpot
	elseif boostNames[boostCheck] == "Ansem Report 3" then
		WriteByte(Save+0x3582, ReadByte(Save+0x3582)+((curDiff+1)*itemBoost))-- Ethers
		giveAbility("party", 0x0196)--Jackpot
	elseif boostNames[boostCheck] == "Ansem Report 4" then
		WriteByte(Save+0x3583, ReadByte(Save+0x3583)+((curDiff+1)*itemBoost))-- Elixirs
		giveAbility("party", 0x019C)--MP Rage
	elseif boostNames[boostCheck] == "Ansem Report 5" then
		WriteByte(Save+0x3584, ReadByte(Save+0x3584)+((curDiff)*itemBoost))-- Mega-Potions
		giveAbility("party", 0x019C)--MP Rage
	elseif boostNames[boostCheck] == "Ansem Report 6" then
		WriteByte(Save+0x3585, ReadByte(Save+0x3585)+((curDiff)*itemBoost))-- Mega-Ethers
		giveAbility("party", 0x019C)--MP Rage
	elseif boostNames[boostCheck] == "Ansem Report 7" then
		WriteByte(Save+0x3586, ReadByte(Save+0x3586)+((curDiff)*itemBoost))-- Megalixirs
		giveAbility("party", 0x01A3)--Hyper Healing
	elseif boostNames[boostCheck] == "Ansem Report 8" then
		WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff)*itemBoost))-- Drive Recoveries
		giveAbility("party", 0x01A3)--Hyper Healing
	elseif boostNames[boostCheck] == "Ansem Report 9" then
		WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff)*itemBoost))-- High Drive Recoveries
		giveAbility("party", 0x01A4)--Auto Healing
	elseif boostNames[boostCheck] == "Ansem Report 10" then
		WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff)*itemBoost))-- High Drive Recoveries
		giveAbility("party", 0x01A4)--Auto Healing
	elseif boostNames[boostCheck] == "Ansem Report 11" then
		WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff)*itemBoost))-- Drive Recoveries
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "Ansem Report 12" then
		WriteByte(Save+0x35B1, ReadByte(Save+0x35B1)+1)-- Cosmic Arts
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "Ansem Report 13" then
		WriteByte(Save+0x35B1, ReadByte(Save+0x35B1)+1)-- Cosmic Arts
		giveAbility("party", 0x0197)--Lucky Lucky
	elseif boostNames[boostCheck] == "All Proofs + Promise Charm" then
		WriteByte(Save+0x3584, ReadByte(Save+0x3584)+((curDiff)*itemBoost))-- Mega-Potions
		WriteByte(Save+0x3585, ReadByte(Save+0x3585)+((curDiff)*itemBoost))-- Mega-Ethers
		WriteByte(Save+0x3586, ReadByte(Save+0x3586)+((curDiff)*itemBoost))-- Megalixirs
		WriteByte(Save+0x3664, ReadByte(Save+0x3664)+((curDiff)*itemBoost))-- Drive Recoveries
		WriteByte(Save+0x3665, ReadByte(Save+0x3665)+((curDiff)*itemBoost))-- High Drive Recoveries
	elseif boostNames[boostCheck] == "All Party Weapons" then
		if lvl1 == true then
			giveAbility(sora, 0x0186)--Combo Boost
		end
		giveAbility("party", 0x01A0)--Once More
	elseif boostNames[boostCheck] == "All Ansem Reports" then
		if lvl1 == true then
			giveAbility(sora, 0x0187)--Air Combo Boost
		end
		giveAbility("party", 0x019F)--Second Chance
	elseif boostNames[boostCheck] == "Fire and Final" then
		if lvl1 == true then
			giveAbility(sora, 0x0198)--Fire Boost
		end
		giveAbility("party", 0x0198)--Fire Boost
	elseif boostNames[boostCheck] == "Blizzard and Wisdom" then
		if lvl1 == true then
			giveAbility(sora, 0x0199)--Blizzard Boost
		end
		giveAbility("party", 0x0199)--Blizzard Boost
	elseif boostNames[boostCheck] == "Thunder and Master" then
		if lvl1 == true then
			giveAbility(sora, 0x019A)--Thunder Boost
		end
		giveAbility("party", 0x019A)--Thunder Boost
	elseif boostNames[boostCheck] == "Cure and Limit" then
		giveAbility(sora, 0x0190)--Combination Boost
		if lvl1== true then
			giveAbility(sora, 0x0192)--Leaf Bracer
		end
		giveAbility("party", 0x0256)--Protectga
	elseif boostNames[boostCheck] == "Reflect and Master" and lvl1==true then
		giveAbility(sora, 0x018E)--Form Boost
	elseif boostNames[boostCheck] == "Magnet and Valor" and lvl1==true then
		giveAbility(sora, 0x018D)--Drive Boost
	elseif boostNames[boostCheck] == "All Tier 1 Spells" and lvl1==true then
		if curDiff == 0 then
			giveAbility(sora, 0x01A6)--MP Hastega
		end
		giveAbility("party", 0x01A6)--MP Hastega
	elseif boostNames[boostCheck] == "All Tier 2 Spells" and lvl1==true then
		if curDiff <= 1 then
			giveAbility(sora, 0x01A6)--MP Hastega
		end
		giveAbility("party", 0x01A6)--MP Hastega
	elseif boostNames[boostCheck] == "All Tier 3 Spells" and lvl1==true then
		if curDiff <= 2 then
			giveAbility(sora, 0x01A6)--MP Hastega
		end
		giveAbility("party", 0x01A6)--MP Hastega
	elseif boostNames[boostCheck] == "Any One Summon" and lvl1==true then
		if curDiff <=1 then
			giveAbility(sora, 0x018F)--Summon Boost
		end
		giveAbility("party", 0x0256)--Protectga
	elseif boostNames[boostCheck] == "Any Three Summons" and lvl1==true then
		giveAbility(sora, 0x018F)--Summon Boost
		giveAbility("party", 0x0256)--Protectga
	elseif lastSpells < totalSpells then
		if lvl1 == true then
			MPbonus2 = 2
		else
			MPbonus2 = 1
		end
		spellMPBoost = (2+curDiff) *MPbonus2
		WriteInt(Slot1+0x180,ReadInt(Slot1+0x180)+spellMPBoost)
		WriteInt(Slot1+0x184,ReadInt(Slot1+0x184)+spellMPBoost)
		--ConsolePrint("lastSpells = "..lastSpells)
		lastSpells = lastSpells + 1
		--ConsolePrint("totalSpells = "..totalSpells)
	elseif valorLast < valorLvl then
		if valorLvl >= 2 then
			WriteShort(valor, 0x819F) --Second Chance
		end
		if valorLvl >= 3 then
			WriteShort(valor+2, 0x81A6) --MP Hastega
		end
		if valorLvl >= 4 then
			WriteShort(valor+4, 0x81A0) --Once More
		end
		if valorLvl >= 5 then
			WriteShort(valor+6, 0x8186) --Combo Boost
		end
		if valorLvl >= 6 then
			WriteShort(valor+8, 0x8189) --Finishing Plus
		end
		if valorLvl >= 7 then
			WriteShort(valor+10, 0x8187) --Air Combo Boost
		end
		valorLast = valorLast + 1
	elseif wisdomLast < wisdomLvl then
		if wisdomLvl >= 2 then
			WriteShort(wisdom, 0x8193) --Magic Lock-On
		end
		if wisdomLvl >= 3 then
			WriteShort(wisdom+2, 0x819F) --Second Chance
		end
		if wisdomLvl >= 4 then
			WriteShort(wisdom+4, 0x8198) --Fire Boost
		end
		if wisdomLvl >= 5 then
			WriteShort(wisdom+6, 0x81A0) --Once More
		end
		if wisdomLvl >= 6 then
			WriteShort(wisdom+8, 0x8199) --Blizzard Boost
		end
		if wisdomLvl >= 7 then
			WriteShort(wisdom+10, 0x819A) --Thunder Boost
		end
		wisdomLast = wisdomLast + 1
	elseif limitLast < limitLvl then
		if limitLvl >= 2 and onPC == true then
			WriteShort(limit, 0x8107) --Distance Step / Dodge Slash
		end
		if limitLvl >= 3 then
			WriteShort(limit+2, 0x8187) --Air Combo Boost
		end
		if limitLvl >= 4 then
			WriteShort(limit+4, 0x81A6) --MP Hastega
		end
		if limitLvl >= 5 then
			WriteShort(limit+6, 0x8186) --Combo Boost
		end
		if limitLvl >= 6 then
			WriteShort(limit+8, 0x819F) --Second Chance
		end
		if limitLvl >= 7 then
			WriteShort(limit+24, 0x81A0) --Once More
		end
		limitLast = limitLast + 1
	elseif masterLast < masterLvl then
		if masterLvl >= 2 then
			WriteShort(master, 0x821C) --Drive Converter
		end
		if masterLvl >= 3 then
			WriteShort(master+2, 0x8186) --MP Hastega
		end
		if masterLvl >= 4 then
			WriteShort(master+4, 0x819F) --Second Chance
		end
		if masterLvl >= 5 then
			WriteShort(master-22, 0x8187) --Air Combo Boost
		end
		if masterLvl >= 6 then
			WriteShort(master-24, 0x81A0) --Once More
		end
		if masterLvl >= 7 then
			WriteShort(master-26, 0x8187) --Air Combo Boost
		end
		masterLast = masterLast + 1
	elseif finalLast < finalLvl then
		if finalLvl >= 2 then
			WriteShort(final, 0x80A3) --Air Combo Plus
		end
		if finalLvl >= 3 then
			WriteShort(final+2, 0x8198) --Fire Boost
		end
		if finalLvl >= 4 then
			WriteShort(final+4, 0x80A2) --Combo Plus
		end
		if finalLvl >= 5 then
			WriteShort(final+6, 0x819F) --Second Chance
		end
		if finalLvl >= 6 then
			WriteShort(final+8, 0x8198) --Fire Boost
		end
		if finalLvl >= 7 then
			WriteShort(final-14, 0x81A0) --Once More
		end
		finalLast = finalLast + 1
	else
		--ConsolePrint("Unrecognized Boost. How'd you do that?")
	end
end	
