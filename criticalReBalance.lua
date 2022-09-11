LUAGUI_NAME = "Critical Re:Balance"
LUAGUI_AUTH = "SapphireSapphic"
LUAGUI_DESC = "Rebalances a variety of things in the game, with the goal of improving the Critical and/or Level 1 experience."

function _OnInit()
	if GAME_ID == 0x431219CC and ENGINE_TYPE == "BACKEND" then
		canExecute=true
		ConsolePrint("Critical Re:Balance")
		Save = 0x09A7070 - 0x56450E
		Sys3 = 0x2A59DB0 - 0x56450E
		curLvl = Save + 0x24F0 + 0x000F
		curDiff = Save + 0x2498
		abilOff = 0x0054
		sora = Save + 0x24F0
		curHP = sora + 0x04
		maxHp = sora + 0x05
		donald = Save + 0x2604
		goofy = Save + 0x2718
		valor = Save + 0x32FE + 0x0016 + 0x0004-- First Unused Slot, accounting for my form movement mod
		wisdom = Save + 0x3336 + 0x000E + 0x000A
		limit = Save + 0x336E + 0x0008
		master = Save + 0x33A6 + 0x0014 + 0x000A
		final = Save + 0x33DE + 0x0010 + 0x000A
		anti = Save + 0x340C + 0x000C + 0x000A
		local offset = 0x56454E
		local Hurricane = 0x2A98006 -offset
		local DrawRange = 0x2A20EA0 -offset
		local DistanceDash = 0x2A94BD4 -offset
		local DistanceDash2 = 0x2A94CBC -offset
		local DistanceDash3 = 0x2A94DCC -offset
	end
end

function Events(M,B,E) --Check for Map, Btl, and Evt
return ((Map == M or not M) and (Btl == B or not B) and (Evt == E or not E))
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
	if ReadByte(curLvl) == 0x01 then
		lvl1 = true
	else
		lvl1 = false
	end
	if ReadByte(curDiff) == 0x03 then
		crit = true
	else
		crit = false
	end
	
	--Execute functions
	newGame()
	if lvl1 == true then
		betterLvl1()
	end
	doubleStuff()
	finnyFun()
end

function newGame()
	if Place == 0x2002 and Events(0x01,Null,0x01) then --Station of Serenity Weapons
		--Starting Inventory Edits
		WriteByte(Save+0x3586, 0x32) --Start with 50 Megalixirs
		
		--Start SDG with all abilities equipped
		for Slot = 0,80 do
			local Current = sora +abilOff+ 2*Slot
			local Ability = ReadShort(Current)
			if Ability < 0x8000 and Ability > 0x0000 then
				WriteShort(Current,Ability + 0x8000)
			end
		end
		for Slot = 0,80 do
			local Current = donald +abilOff+ 2*Slot
			local Ability = ReadShort(Current)
			if Ability < 0x8000 and Ability > 0x0000 then
				WriteShort(Current,Ability + 0x8000)
			end
		end
		for Slot = 0,80 do
			local Current = goofy +abilOff+ 2*Slot
			local Ability = ReadShort(Current)
			if Ability < 0x8000 and Ability > 0x0000 then
				WriteShort(Current,Ability + 0x8000)
			end
		end
		--Start All party members on sora attack
		WriteByte(donald + 0x00F4, 0x04)
		WriteByte(goofy + 0x00F4, 0x04)
		WriteByte(Save + 0x2940 + 0x00F4, 0x04)
		WriteByte(Save + 0x2A54 + 0x00F4, 0x04)
		WriteByte(Save + 0x2B68 + 0x00F4, 0x04)
		WriteByte(Save + 0x2C7C + 0x00F4, 0x04)
		WriteByte(Save + 0x2D90 + 0x00F4, 0x04)
		WriteByte(Save + 0x2EA4 + 0x00F4, 0x04)
		WriteByte(Save + 0x2FB8 + 0x00F4, 0x04)
		WriteByte(Save + 0x30CC + 0x00F4, 0x04)
		WriteByte(Save + 0x31E0 + 0x00F4, 0x04)
	end
end

function betterLvl1()
	--Count # of proofs
	if ReadByte(Save+0x36B2) ~= 0x00 then
		pCon = true
	else
		pCon = false
	end
	if ReadByte(Save+0x36B3) ~= 0x00 then
		pNon = true
	else
		pNon = false
	end
	if ReadByte(Save+0x36B4) ~= 0x00 then
		pPea = true
	else
		pPea = false
	end
	if ReadByte(Save+0x3964) ~= 0x00 then
		pCharm = true
	else
		pCharm = false
	end
	
	
	--Boost stats based on how much dmg sora has
	numProof = pCon + pNon + pPea + pCharm
	statsBoost = numProof * (maxHP - curHP)
	Writebyte(sora+0x09,statsBoost)--Power
	Writebyte(sora+0x0A,statsBoost)--Magic
	Writebyte(sora+0x0B,statsBoost+20)--Def
	
	--valor
	if ReadByte(Save + 0x32FE + 0x02) >= 0x02 then
		WriteShort(valor, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(valor+2, 0x81A0) --Once More
	end
	--wisdom
	if ReadByte(Save + 0x332C + 0x02) >= 0x03 then
		WriteShort(wisdom, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x332C + 0x02) >= 0x05 then
		WriteShort(wisdom+2, 0x81A0) --Once More
	end
	--limit
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(limit, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(limit+2, 0x81A0) --Once More
	end
	--master
	if ReadByte(Save + 0x32FE + 0x02) >= 0x04 then
		WriteShort(master, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x06 then
		WriteShort(master+2, 0x81A0) --Once More
	end
	--final
	if ReadByte(Save + 0x32FE + 0x02) >= 0x05 then
		WriteShort(final, 0x819F) --Second Chance
	end
	if ReadByte(Save + 0x32FE + 0x02) >= 0x07 then
		WriteShort(final+2, 0x81A0) --Once More
	end
end

function doubleStuff()
	WriteByte(Sys3+0x03E0,2) -- Valor
	--WriteByte(Sys3+0x0410,3) -- Wisdom --Commented out
	--WriteByte(Sys3+0x7A30,4) -- Limit  --Commented out
	--WriteByte(Sys3+0x04A0,4) -- Master --Commented out
	WriteByte(Sys3+0x0500,1) -- Anti
	--WriteByte(Sys3+0x5180,3) -- Chicken --Commented out
	WriteByte(Sys3+0x1070,5) -- Stitch
	WriteByte(Sys3+0x10A0,2) -- Genie
	--WriteByte(Sys3+0x37A0,3) -- Pan     --Commented out
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

function finnyFun()
	local _roomRead = ReadArray(0x1B086A, 0x0A)

    if _roomRead[1] == 0x0B and _roomRead[2] == 0x07 and _roomRead[9] == 0x01 then
        WriteArray(0x1B086A, {0x0B, 0x02, 0x32, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00})
        WriteArray(0x1B086A + 0x30, {0x0B, 0x02, 0x32, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00})
    end
end