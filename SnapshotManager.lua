local ItemProps = table.const{ --注意，这个table的值必须从251开始，连续增加！！！！！！

	COLOR_BLUE 			= 251, 		--颜色,ItemColorType
	COLOR_GREEN 		= 252,		--颜色,ItemColorType
	COLOR_ORANGE 		= 253,		--颜色,ItemColorType
	COLOR_PURPLE 		= 254,		--颜色,ItemColorType
	COLOR_RED 			= 255,		--颜色,ItemColorType
	COLOR_YELLOW 		= 256,		--颜色,ItemColorType
	SPECIAL_LINE 		= 257,		--特效类型,ItemSpecialType
	SPECIAL_COLUMN 		= 258,		--特效类型,ItemSpecialType
	SPECIAL_WRAP 		= 259,		--特效类型,ItemSpecialType
	SPECIAL_COLOR 		= 260,		--特效类型,ItemSpecialType
	SPECIAL_DRIP		= 261,		--特效类型,ItemSpecialType
	BLOCK				= 262,    	--障碍,isBlock
	REVERSE_COUNT		= 263, 		--还有多少步翻转
	SNAIL_ROAD = 264, 
	LAMP_LEVEL = 265,
	LEVEL_199 = 266,
	COLOR_FILTER_COLOR = 267,
	PACMAN_COLOUR = 268, 
	LEVEL_211 = 269,
    BISCUIT_MILK_NUM = 270,
    TRANSMISSION_START = 271,
    TRANSMISSION_END = 272,
    LEVEL_195 = 273,
    GYRO_LEVEL = 274, 
    WATER_BUCKET_LIFE = 275, 		-- 还需要给水桶充能几次
    WIND_TUNNEL_SWITCH_TYPE = 276, 	-- 风洞开关类型，1 = on开关，2 = off开关

    -------------------- TileConst突破250，此后，需要记录在 Snapshot 中的 Tileconst 要在此占位备份 ---------------------

    TILE_CONST_ACTIVITY_COLLECT_ITEM = 277,   	-- [TileConst] 对应 TileConst.kActivityCollectionItem
    TILE_CONST_WIND_TUNNEL_WALL_UP = 278,		-- [TileConst] 对应 TileConst.kWindTunnelWall_Up
    TILE_CONST_WIND_TUNNEL_WALL_RIGHT = 279,	-- [TileConst] 对应 TileConst.kWindTunnelWall_Right
    TILE_CONST_WIND_TUNNEL_WALL_DOWN = 280,		-- [TileConst] 对应 TileConst.kWindTunnelWall_Down
    TILE_CONST_WIND_TUNNEL_WALL_LEFT = 281,		-- [TileConst] 对应 TileConst.kWindTunnelWall_Left
    
    -- STEPS_TO_SUCCESS = 282,		-- 当前state距离成功过关还有多少step
    -- SUCCESS_LEFT_MOVES = 283,		-- 成功过关时的剩余步数
    -- REAL_COST_MOVES = 284,		-- 实际交换步数
    BIG_MONSTER_TYPE = 282,		-- 雪怪类型
    TILE_CONST_MIMOSA_LEFT = 283,
    TILE_CONST_MIMOSA_RIGHT = 284,
    TILE_CONST_MIMOSA_UP = 285,
    TILE_CONST_MIMOSA_DOWN = 286,
    CRYSTAL_STONE_ENERGY = 287 ,
    TOTEMS_STATE = 288 ,
    BLOCKER195_COLLECT_TYPE = 289 ,
    IS_CURR_LOCKGROUP = 290 ,
    TURRET_DIR = 291 ,
    SQUID_DIR = 292 ,
    SQUID_TARGET_TYPE = 293 ,
    SQUID_TARGET_COUNT = 294 ,
    SQUID_TARGET_NEEDED = 295 ,
    WAN_SHENG_PTYPE = 296 ,
    WATER_BUCKET_REAL_LIFE = 297 ,
    GRAVITY_DIR = 298 ,

    CANEVINE_ID = 299,
    CANEVINE_LEVEL = 300,
    CANEVINE_HIT = 301,
    CANEVINE_TYPE = 302,

    TILE_CONST_PLANE = 303,		-- [TileConst] 对应 TileConst.kPlane
    PLANE_DIRECTION = 304,		-- 飞机方向

    TILE_CONST_CATTERY = 305,
    CATTERY_DIRECTION = 306,
    CATTERY_SIZE = 307, --只有左上格子记录
    TILE_CONST_MEOW = 308,

    TILE_CONST_WEEKLY_RACE_2020_FINAL_CHEST = 309,		-- [TileConst] 对应 TileConst.kWeeklyRace2020Chest 新周赛终点宝箱
    WEEKLY_RACE_2020_FINAL_CHEST_LAYER = 310,			-- 终点宝箱的剩余层数
    WEEKLY_RACE_2020_FINAL_CHEST_LAYER_HP = 311,		-- 终点宝箱当前活跃层的剩余耐久值

    TILE_CONST_WEEKLY_RACE_2020_JEWEL_CHEST = 312,		-- [TileConst] 对应 TileConst.kWeeklyRace2020JewelChest 新周赛宝石宝箱
    WEEKLY_RACE_2020_JEWEL_CHEST_LAYER = 313,			-- 宝石宝箱的剩余层数
    WEEKLY_RACE_2020_JEWEL_CHEST_LAYER_HP = 314,		-- 宝石宝箱当前活跃层的剩余耐久值

    STAR_BOTTLE_IS_FULL = 315,  --星星瓶满能量状态
    CRYSTAL_STONE_IS_FULL = 316,  --染色宝宝满能量状态

    TILE_CONST_CUCKOO_BIRD = 317,			-- [TileConst] 对应 TileConst.kCuckooWindupKey 布谷鸟
    TILE_CONST_CUCKOO_WINDUP_KEY = 318,		-- [TileConst] 对应 TileConst.kCuckooWindupKey 布谷鸟的发条钥匙
    TILE_CONST_CUCKOO_CLOCK = 319,			-- [TileConst] 对应 TileConst.kCuckooClock 布谷鸟的钟
    CUCKOO_ROAD = 320,						-- 布谷鸟路径
    SHELL_GIFT = 321,						-- 贝壳宝箱

    TILE_FIREWORK = 322,					-- 鞭炮
    TILE_BATTERY = 323,						-- 蓄电器
}

-- 部分key需要与GameItemOrderData中的对应
local TargetConst = {
	kBlue = 0,
	kGreen = 1,
	kOrange = 2,
	kPurple = 3,
	kRed = 4,
	kYellow = 5,
	kLine = 6,
	kWrap = 7,
	kColor = 8,
	kLineLine = 9,
	kWrapLine = 10,
	kColorLine = 11,
	kWrapWrap = 12,
	kColorWrap = 13,
	kColorColor = 14,
	kSnowFlower = 15,
	kCoin = 16,
	kVenom = 17,
	kSnail = 18,
	kGreyCuteBall = 19,
	kBrownCuteBall = 20,
	kBottleBlocker = 21,
	kChristmasBell = 22,
	kBalloon = 23,
	kBlackCuteBall = 24,
	kHoney = 25,
	kSand = 26,
	kMagicStone = 27,
	kBoomPuffer = 28,
	kBlockerCoverMaterial = 29,
	kBlockerCover = 30,
	kBlocker195 = 31,
	kChameleon = 32,
	kPacman = 33,
	kPenguin = 34,
	kSeal = 35,
	kSeaBear = 36,
	kMistletoe = 37,
	kScarf = 38,
	kElk = 39,
	kLight = 40,
	kFudge = 41,
	kDigJewel_1 = 42,
	kSea_3_3 = 43,
	kLotus = 44,
	kJamSperad = 45,
    kWanSheng = 46,
    kGyro = 47,
    kGhost = 48,
    kMilks = 49,
    kSquid = 50,
	kWater = 51,
    kWaterBucket = 52,
    STEPS_TO_SUCCESS = 53,		-- 当前state距离成功过关还有多少step
    SUCCESS_LEFT_MOVES = 54,		-- 成功过关时的剩余步数
    REAL_COST_MOVES = 55,		-- 实际交换步数
    kCuckoo = 56,
}


local kSnapshotVersion = 40 	-- 只要逻辑有变化，输出数据【可能】有变化，就自增。  数据变更后需要升级供后端区分数据版本

local itemMajorVersion = 1    	-- 当gameItemK的定义本身发生改变时，自增
local itemMinorVersion = nil  	-- 基于gameItemK的所有可用的配置（TileConst和ItemProps）自动生成
local maxItemId = nil         	-- gameItemK的最大值，自动生成
local targetMajorVersion = 1  	-- 当targetK的定义本身发生改变时，自增
local targetMinorVersion = nil	-- 基于TargetConst配置自动生成
local maxTargetId = nil       	-- targetK的最大值，自动生成

local kMaxItemStatus = 323		-- 数据的最大维度（它就是maxItemId）

function getSnapshotManagerMainVersion()
	return kSnapshotVersion
end

function getSnapshotManagerVersionData()
	
	if not itemMinorVersion then

		local tileId2NameMap = {}

		for k,v in pairs(TileConst) do
			tileId2NameMap[v] = k
		end

		local str1 = ""
		-- for i = 1 , TileConst.kMaxTile do
		for i = 1, TileConstOldEndVal do
			if tileId2NameMap[i] then
				str1 = str1 .. tileId2NameMap[i]
			end
		end
		for i = TileConstNewStartVal, TileConst.kMaxTile do
			if tileId2NameMap[i] then
				str1 = str1 .. tileId2NameMap[i]
			end
		end

		local md5_1 = HeMathUtils:md5( str1 )

		local itemPropsId2NameMap = {}
		local itemPropsLength = 0
		for k,v in pairs(ItemProps) do
			itemPropsLength = itemPropsLength + 1
			itemPropsId2NameMap[v] = k
		end
		
		maxItemId = itemPropsLength + 250

		local str2 = ""
		for i = 251 , maxItemId do
			if itemPropsId2NameMap[i] then
				str2 = str2 .. itemPropsId2NameMap[i]
			end
		end

		local md5_2 = HeMathUtils:md5( str2 )
		itemMinorVersion = HeMathUtils:md5( str1 .. str2 )


		local targetId2NameMap = {}
		maxTargetId = 0
		for k,v in pairs(TargetConst) do
			targetId2NameMap[v] = k
			maxTargetId = maxTargetId + 1
		end
		
		local str3 = ""
		for i = 0 , maxTargetId do
			if targetId2NameMap[i] then
				str3 = str3 .. targetId2NameMap[i]
			end
		end

		targetMinorVersion = HeMathUtils:md5( str3 )

		kMaxItemStatus = maxItemId
	end

	local data = {}
	data.itemMajorVersion = itemMajorVersion
	data.itemMinorVersion = itemMinorVersion
	data.maxItemId = maxItemId
	data.targetMajorVersion = targetMajorVersion
	data.targetMinorVersion = targetMinorVersion
	data.maxTargetId = maxTargetId

	return data
end

local verData = nil


SnapshotManager = class()
local bOpen, bStop
local gamereplay
local openLevels

local maintenanceKey = "SnapshotPercent"

local function getTileIdByItemType(ptype)
	for k, v in pairs(GameItemType) do
		if v == ptype then
			return TileConst[k]
		end
	end
	return ptype
end

local function getTargetData(mainlogic)
	local targetK, targetV, dataK, dataV = {}, {}, nil, nil
	if GameModeTypeId.CLASSIC_MOVES_ID == mainlogic.theGamePlayType then
	elseif GameModeTypeId.LIGHT_UP_ID == mainlogic.theGamePlayType then
		dataK = TargetConst.kLight
		dataV = mainlogic.kLightUpLeftCount
		table.insert(targetK, dataK)
		table.insert(targetV, dataV)
	elseif GameModeTypeId.DROP_DOWN_ID == mainlogic.theGamePlayType then
		dataK = TargetConst.kFudge
		dataV = mainlogic.ingredientsTotal - mainlogic.ingredientsCount
		table.insert(targetK, dataK)
		table.insert(targetV, dataV)
	elseif GameModeTypeId.ORDER_ID == mainlogic.theGamePlayType 
		or mainlogic.theGamePlayType == GameModeTypeId.JAMSPREAD_ID 
		or mainlogic.theGamePlayType == GameModeTypeId.DESTINATION_MODE_ID
		then
		for _,v in ipairs(mainlogic.theOrderList) do
			dataK = nil
			dataV = nil
			if v.key1 == 1 then 
				if v.key2 == 1 then
					dataK = TargetConst.kBlue
				elseif v.key2 == 2 then 
					dataK = TargetConst.kGreen
				elseif v.key2 == 3 then
					dataK = TargetConst.kOrange
				elseif v.key2 == 4 then
					dataK = TargetConst.kPurple
				elseif v.key2 == 5 then
					dataK = TargetConst.kRed
				elseif v.key2 == 6 then
					dataK = TargetConst.kYellow
				end
			elseif v.key1 == 2 then
				dataK = TargetConst[table.keyOf(GameItemOrderType_SB, v.key2)]--特效部分
			elseif v.key1 == 3 then 
				dataK = TargetConst[table.keyOf(GameItemOrderType_SS, v.key2)]--特效交换部分
			elseif v.key1 == 4 then 
				dataK = TargetConst[table.keyOf(GameItemOrderType_ST, v.key2)]--特效交换部分
			elseif v.key1 == 5 then 
				dataK = TargetConst[table.keyOf(GameItemOrderType_Others, v.key2)]
			elseif v.key1 == 7 then
				dataK = TargetConst[table.keyOf(GameItemOrderType_Destination, v.key2)]
			end

			if dataK then
				dataV = v.v1 - v.f1
				table.insert(targetK, dataK)
				table.insert(targetV, dataV)  
			end
		end
	elseif GameModeTypeId.DIG_MOVE_ID == mainlogic.theGamePlayType then
		dataK = TargetConst.kDigJewel_1
		dataV = mainlogic.digJewelLeftCount
		table.insert(targetK, dataK)
		table.insert(targetV, dataV) 
	elseif mainlogic.theGamePlayType == GameModeTypeId.SEA_ORDER_ID then
		for _,v in ipairs(mainlogic.theOrderList) do
			dataK = nil
			dataV = nil
			if v.key1 == 6 then 
				dataK = TargetConst[table.keyOf(GameItemOrderType_SeaAnimal, v.key2)]--海洋生物部分
			end 

			if dataK then
				dataV = v.v1 - v.f1
				table.insert(targetK, dataK)
				table.insert(targetV, dataV)  
			end
		end
	elseif mainlogic.theGamePlayType == GameModeTypeId.LOTUS_ID then
		dataK = TargetConst.kLotus
		dataV = mainlogic.currLotusNum
		table.insert(targetK, dataK)
		table.insert(targetV, dataV)
	end	

	table.insert(targetK, TargetConst.REAL_COST_MOVES)
	table.insert(targetV, mainlogic.realCostMove)

	return targetK, targetV
end

local function getItemState(item, board, mainlogic)
	local dataK, dataV = {}, {}

	local uid = UserManager:getInstance():getUID()
	local needAutoCheck = MaintenanceManager:getInstance():isEnabledInGroup( maintenanceKey , "AutoCheck" ,  uid ) or false
	MACRO_DEV_START()
	needAutoCheck = true
	MACRO_DEV_END()

	local function insertK(k)
		if needAutoCheck then
			-- printx( 1 , k , kMaxItemStatus ,   type(k) , k <= 0 , k > kMaxItemStatus , math.ceil(k) , math.floor(k) )
			if not k or type(k) ~= "number" or k <= 0 or k > kMaxItemStatus or math.ceil(k) ~= math.floor(k) then
				local text = "SnapshotManager dataK is illega !! k = " .. tostring(k) .. " x = " .. tostring(item.x) .. " y = " .. tostring(item.y) 
								.. " levelId = " .. tostring( GamePlayContext:getInstance().levelInfo.metaLevelId ) .. " playId = " .. tostring( GamePlayContext:getInstance().playId )
				assert( false , text ) 
				if math.random(1,100) == 1 then
					he_log_error("SnapshotManager_dataK_illega_" .. type(k) .. "_" .. tostring(k) .. "_" .. tostring( GamePlayContext:getInstance().levelInfo.metaLevelId ) .. "_" .. tostring(item.x) .. tostring(item.y)  )
				end
				MACRO_DEV_START()
				RemoteDebug:uploadLogWithTag( "ERROR!" , text .."\n" .. debug.traceback() )
				setTimeOut( function () CommonTip:showTip( text , "negative" , nil , 999 ) end , 3 )
				MACRO_DEV_END()
			end
		end
		table.insert(dataK, k)
	end

	local function insertV(v)
		if needAutoCheck then

			if not v or type(v) ~= "number" --[[or v > 1000]] or math.ceil(v) ~= math.floor(v) then
				
				local text = "SnapshotManager dataV is illega !! v = " .. tostring(v) .. " x = " .. tostring(item.x) .. " y = " .. tostring(item.y)
								.. " levelId = " .. tostring( GamePlayContext:getInstance().levelInfo.metaLevelId ) .. " playId = " .. tostring( GamePlayContext:getInstance().playId )
				assert( false , text ) 
				if math.random(1,100) == 1 then
					he_log_error("SnapshotManager_dataV_illega_" .. type(v) .. "_" .. tostring(v) .. "_" .. tostring( GamePlayContext:getInstance().levelInfo.metaLevelId ) .. "_" .. tostring(item.x) .. tostring(item.y)  )
				end
				-- printx( 1 , "insertV  " , v , type(v) ,  math.ceil(v) , math.floor(v) )
				MACRO_DEV_START()
				RemoteDebug:uploadLogWithTag( "ERROR!" , text .."\n" .. debug.traceback() )
				setTimeOut( function () CommonTip:showTip( text , "negative" , nil , 999 ) end , 3 )
				MACRO_DEV_END()
			end
		end
		table.insert(dataV, v)
	end

	local function insertKV( key, value )
		if value > 0 then
			insertK(key)
			insertV(value)
		end
	end

	-- insertK( ItemProps.REAL_COST_MOVES )
	-- insertV( mainlogic.realCostMove )

	if item then 
		if item.ItemType == GameItemType.kAnimal then
			insertK(TileConst.kAnimal)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kIngredient then
			insertK(TileConst.kFudge)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kCoin then
			insertK(TileConst.kCoin)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kBlackCuteBall and item.blackCuteStrength > 0 then 
			insertK(TileConst.kBlackCute)
			insertV( item.blackCuteStrength )
		end

		if item.ItemType == GameItemType.kCrystal then 
			insertK(TileConst.kCrystal)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kGift or item.ItemType == GameItemType.kNewGift then 
			insertK(TileConst.kGift)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kVenom then 
			insertK(TileConst.kPoison)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kAddMove then 
			insertK(TileConst.kAddMove)
			insertV( 1)
		end

		if item.snowLevel > 0 then
			insertK(TileConst.kFrosting1)
			insertV( item.snowLevel)
		end

		if item.ItemType == GameItemType.kDigGround and item.digGroundLevel > 0 then 
			table.insert( dataK, TileConst.kDigGround_1 )
			insertV( item.digGroundLevel)
		end

		if item.ItemType == GameItemType.kDigJewel and item.digJewelLevel > 0 then 
			table.insert( dataK, TileConst.kDigJewel_1 )
			insertV( item.digJewelLevel)
		end

		if item.ItemType == GameItemType.kRoost then
			insertK(TileConst.kRoost)
			insertV( item.roostLevel)  -- 1~4 loop
		end

		if item.ItemType == GameItemType.kBalloon then 
			insertK(TileConst.kBalloon)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kPoisonBottle then 
			insertK(TileConst.kPoisonBottle)
			insertV( 1)
		end

		if item.bigMonsterFrostingType > 0 and item.bigMonsterFrostingStrength > 0 then 
			insertK( TileConst.kBigMonster )
			insertV( item.bigMonsterFrostingStrength)

			insertK( ItemProps.BIG_MONSTER_TYPE )
			insertV( item.bigMonsterFrostingType )
		end

		if item.ItemType == GameItemType.kMimosa or item.ItemType == GameItemType.kKindMimosa then
			
		 	if item.mimosaDirection == 1 then
		 		insertK( ItemProps.TILE_CONST_MIMOSA_LEFT )
		 	elseif item.mimosaDirection == 2 then
		 		insertK( ItemProps.TILE_CONST_MIMOSA_RIGHT )
		 	elseif item.mimosaDirection == 3 then
		 		insertK( ItemProps.TILE_CONST_MIMOSA_UP )
		 	else
		 		insertK( ItemProps.TILE_CONST_MIMOSA_DOWN )
		 	end

		 	insertV( 1 )
			
			--------旧的不删，代表含羞草头部等级
			insertK(TileConst.kMimosaLeft )
			if item.mimosaLevel >= 2 then
				insertV( 2)
			else
				insertV( 1)
			end
		end

		if item.beEffectByMimosa > 0 then
			insertK(TileConst.kMimosaLeaf )
			insertV( 1)
		end

		if item.ItemType == GameItemType.kMagicLamp then 
			insertK(TileConst.kMagicLamp)
			insertV( 1)
		end

		if item.lampLevel ~= 0 then 
			local level = 5 - item.lampLevel
			if level > 0 then
				insertK(ItemProps.LAMP_LEVEL)
				insertV( level ) -- 4 ~ 1
			end
		end

		if item.ItemType == GameItemType.kSuperBlocker then 
			insertK(TileConst.kSuperBlocker)
			insertV( 1)
		end

		if item.honeyBottleLevel ~= 0 then 
			local level = 4 - item.honeyBottleLevel
			if level > 0 then
				insertK(TileConst.kHoneyBottle)
				insertV( level )
			end
		end

		if item.honeyLevel ~= 0 then 
			insertK(TileConst.kHoney)
			insertV( item.honeyLevel)
		end

		if item.ItemType == GameItemType.kQuestionMark then 
			insertK(TileConst.kQuestionMark)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kMagicStone then 
			insertK(TileConst.kMagicStone_Up + item.magicStoneDir - 1)
			insertV( item.magicStoneLevel + 1 ) -- 1 ~ 3
		end

		if item.ItemType == GameItemType.kBottleBlocker and item.bottleLevel > 0 then 
			insertK(TileConst.kBottleBlocker)
			insertV( item.bottleLevel)
		end

		if item.ItemType == GameItemType.kCrystalStone then 
			insertK(TileConst.kCrystalStone)
			insertV( 1)

			insertK( ItemProps.CRYSTAL_STONE_ENERGY )
			local leftEnergy = GamePlayConfig_CrystalStone_Energy - item.crystalStoneEnergy
			if leftEnergy < 0 then leftEnergy = 0 end
			insertV( leftEnergy )

			if leftEnergy == 0 then
				insertK( ItemProps.CRYSTAL_STONE_IS_FULL )
				insertV( 1 )
			end
		end

		if item.ItemType == GameItemType.kRocket then 
			insertK(TileConst.kRocket)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kTotems then 
			insertK(TileConst.kTotems)
			insertV( 1)

			insertK( ItemProps.TOTEMS_STATE )
			insertV( item.totemsState + 1 )
		end

		-- if item.ItemType == GameItemType.kDrip then 
		-- 	insertK(TileConst.kDrip)
		-- 	insertV( 1)
		-- end

		if item.ItemType == GameItemType.kPuffer then 
			insertK(TileConst.kPuffer)
			if item.pufferState == PufferState.kActivated then
				insertV( 1)
			else
				insertV( 2)
			end
		end

		if item.ItemType == GameItemType.kMissile and item.missileLevel > 0 then 
			insertK(TileConst.kMissile)
			insertV( item.missileLevel)
		end
		-- 大概可以看做一家人吧……
		if item.ItemType == GameItemType.kDynamiteCrate and item.missileLevel > 0 then 
			insertK(TileConst.kMissile)
			insertV( item.missileLevel)
		end

		if item.ItemType == GameItemType.kBlocker195 then 
			insertK(TileConst.kBlocker195)
			insertV( 1)
			
			local collectType = item.subtype or 0
			local tnum = mainlogic.blocker195Nums[collectType] or 0
			local starblevel = tnum - item.level
			if starblevel < 0 then starblevel = 0 end

			if starblevel > 0 then
				insertK( ItemProps.LEVEL_195 )
				insertV( starblevel)
			else
				insertK( ItemProps.STAR_BOTTLE_IS_FULL )
				insertV( 1 )
			end

			insertK( ItemProps.BLOCKER195_COLLECT_TYPE )
			insertV( tonumber(collectType) or 0 )
		end

		if item.ItemType == GameItemType.kBlocker199 then 
			insertK(TileConst.kBlocker199)
			insertV( item.subtype)-- 方向
			if item.level > 0 then
				insertK(ItemProps.LEVEL_199)
				insertV( item.level)
			end
		end

		if item.ItemType == GameItemType.kBlocker211 then 
			insertK(TileConst.kBlocker211)
			insertV( 1)

			local level = item.subtype - item.level
			-- if level < 0 then level = 0 end
			if level > 0 then
				insertK(ItemProps.LEVEL_211)
				insertV( level)
			end
		end

		if item.ItemType == GameItemType.kChameleon then 
			insertK(TileConst.kChameleon)
			insertV( 1)
		end

		if item.ItemType == GameItemType.kPacman then 
			insertK(TileConst.kPacman)
			insertV( 1)

			if item.pacmanColour then 
				insertK(ItemProps.PACMAN_COLOUR)
				insertV( item.pacmanColour)
			end
		end

		if item.ItemType == GameItemType.kPacmansDen then 
			insertK(TileConst.kPacmansDen)
			insertV( 1)
		end

		if item._encrypt.ItemColorType ~= 0 then
			local color = AnimalTypeConfig.convertColorTypeToIndex(item._encrypt.ItemColorType)
			if color then 
				insertK(color + 250)
				insertV( 1)
			end 
		end

		if item.ItemSpecialType ~= 0 then
			local special = AnimalTypeConfig.convertSpecialTypeToIndex(item.ItemSpecialType)
			if special then 
				insertK(special + 256)
				insertV( 1)
			end
		end

		if item.isBlock then 
			insertK(ItemProps.BLOCK)
			insertV( 1)
		end

		if item.cageLevel > 0 then
			insertK(TileConst.kLock)
			insertV( 1)
		end

		if item.furballType == GameItemFurballType.kGrey then 
			insertK(TileConst.kGreyCute)
			insertV( 1)
		elseif item.furballType == GameItemFurballType.kBrown then
			insertK(TileConst.kBrownCute)
			insertV( 1)
		end

		if item.isEmpty then
			insertK(TileConst.kNone)
			insertV( 1)
		end

		if item.isSnail then 
			insertK(TileConst.kSnail)
			insertV( 1)
		end

		-- 等于1时item中存储的lotusLevel会被刷新错误地带走，不可信，故等于1时需用boardData来判断
		if item.lotusLevel > 1 then 
			insertK(158 + item.lotusLevel)--荷叶的三个等级的逻辑完全不同，相当于三个不同障碍，所以应该用三个key
			insertV( 1)
		end

		if item.blockerCoverLevel ~= 0 then 
			insertK(TileConst.kBlockerCover)
			insertV( item.blockerCoverLevel)
		end

		if item.lockLevel ~= 0 then 

			local lockGroupKey , nextGroupKey = GameExtandPlayLogic:getBlocker206GroupIds(mainlogic)
			if lockGroupKey and mainlogic.blocker206Cfg then 
				local needKeyNum = mainlogic.blocker206Cfg[item.lockLevel]

				if needKeyNum and mainlogic.blocker207DestroyNum then
					local leftNum = needKeyNum - mainlogic.blocker207DestroyNum
					if leftNum < 0 then leftNum = 0 end

					insertK(TileConst.kBlocker206)

					if item.lockLevel == lockGroupKey then
						insertV( leftNum)

						insertK( ItemProps.IS_CURR_LOCKGROUP )
						insertV( 1 )
					else
						insertV( needKeyNum)

						insertK( ItemProps.IS_CURR_LOCKGROUP )
						insertV( 0 )
					end
				end
			end
		end

		if item.ItemType == GameItemType.kBlocker207 then 
			insertK(TileConst.kBlocker207)
			insertV( 1)
		end


        if item.ItemType == GameItemType.kTurret then 
			insertK(TileConst.kTurret)

            local turretLevel = item.turretLevel
            if item.turretIsSuper then
                turretLevel = item.turretLevel + 1 -- 0 1 2   未充能 普通充能 高级充能 ， loop
            end

            turretLevel = turretLevel + 1 -- 1 ， 2  ， 3  未充能 普通充能 高级充能 ， loop
            insertV( turretLevel)

            insertK( ItemProps.TURRET_DIR )
            insertV( tonumber(item.turretDir) )
		end

		if item:seizedByGhost() then 
			insertK(TileConst.kGhost)
            insertV( 1)
		end

		if item.ItemType == GameItemType.kSunFlask and item.sunFlaskLevel > 0 then 
			insertK(TileConst.kSunFlask)
            insertV( item.sunFlaskLevel) -- x ~ 1
		end

		if item.ItemType == GameItemType.kSunflower then 
			insertK(TileConst.kSunflower)
            insertV( 1)
		end

		if item.ItemType == GameItemType.kSquid then 
			insertK(TileConst.kSquid)
            insertV( 1)

            insertK( ItemProps.SQUID_DIR )
            insertV( tonumber(item.squidDirection) )

            insertK( ItemProps.SQUID_TARGET_TYPE )
            insertV( tonumber(item.squidTargetType) )

            insertK( ItemProps.SQUID_TARGET_COUNT )
            insertV( tonumber(item.squidTargetCount) )

            insertK( ItemProps.SQUID_TARGET_NEEDED )
            insertV( tonumber(item.squidTargetNeeded) )
            
		end

        if item.ItemType == GameItemType.kWanSheng then 
            local level = 4 - item.wanShengLevel
            -- if level < 0 then level = 0 end
            if level > 0 then
            	insertK(TileConst.kWanSheng)
            	insertV( level)
            end

            if item.wanShengConfig then
            	if item.wanShengConfig.mType then
            		insertK( ItemProps.WAN_SHENG_PTYPE )
            		insertV( item.wanShengConfig.mType + 1 )
            	end

            	-- if item.wanShengConfig.num then

            	-- end
            end
            
        end

        if item.ItemType == GameItemType.kGyro then 
        	insertK( TileConst.kGyro )
			insertV( item.gyroDirection)-- 方向

            local level = 2 - item.gyroLevel
            if level > 0 then
            	insertK( ItemProps.GYRO_LEVEL )
            	insertV( level)
            end
        end

        if item.ItemType == GameItemType.kGyroCreater then 
        	insertK(TileConst.kGyroCreater)
        	insertV( 1)
        end
        
        if item.ItemType == GameItemType.kWater then
        	insertK(TileConst.kWater)
        	insertV(item.waterLevel or 0)
		end

        if WaterBucketLogic:hasBucket(item) then
        	local _, cur, maximum = WaterBucketLogic:getBucketStatus(mainlogic, item)
        	insertK(TileConst.kWaterBucket)
        	insertV(1)



        	local life = maximum - cur 

        	-- just for 万无一失
        	if life < 0 then life = 0 end

        	-- life ε [0,  +∞)
        	-- y_life = {
     --    			0,  life ε [0, 1)
     --    			1,  life ε [1, 3)
     --    			2,  life ε [3, 7)
     --    			3,  life ε [7, 15)
	 --				4,  life ε [15, 31)
	 --				5,  life ε [31, +∞)
        		-- }

        	local y_life = lua_switch(life){
        		[function ( x ) return x >= 0 	and x < 1 end] 	= 	0,
        		[function ( x ) return x >= 1 	and x < 3 end] 	= 	1,
        		[function ( x ) return x >= 3 	and x < 7 end] 	= 	2,
        		[function ( x ) return x >= 7 	and x < 15 end]	= 	3,
        		[function ( x ) return x >= 15 	and x < 31 end]	= 	4,
        		[function ( x ) return x >= 31 end]				=	5,
        		default 										=	5,
         	}

         	if y_life > 0 then
        		insertK(ItemProps.WATER_BUCKET_LIFE)
        		insertV(y_life)
        	end

        	insertK( ItemProps.WATER_BUCKET_REAL_LIFE )
        	insertV( life )
        end

        if CanevineLogic:is_occupy(item) then
            local root = CanevineLogic:get_canevine_root(item)
            if root then

	            insertKV(ItemProps.CANEVINE_TYPE, 1)

	            local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainlogic)
	            local canevine_id = (root.r - 1) * colAmount + (root.c - 1) + 1

		        insertKV(ItemProps.CANEVINE_ID, canevine_id)

	            local root_item_data = mainlogic.gameItemMap[root.r][root.c]
	            insertKV(ItemProps.CANEVINE_HIT, CanevineLogic:get_hit(root_item_data.canevine_data))
	            insertKV(ItemProps.CANEVINE_LEVEL, CanevineLogic:get_level(root_item_data.canevine_data))

	        end
        end

        if item.ItemType == GameItemType.kWindTunnelSwitch then 
        	if item.windTunnelSwitchLevel and item.windTunnelSwitchLevel > 0 then
        		insertK(TileConst.kWindTunnelSwitch)
	            insertV(item.windTunnelSwitchLevel)

	            insertK(ItemProps.WIND_TUNNEL_SWITCH_TYPE)
	            if item.windTunnelSwitchTypeIsOff then
	            	insertV(2)
	            else
	            	insertV(1)
	            end
        	end
		end

		if item.ItemType == GameItemType.kPlane then
			if item.planeCountDown and item.planeCountDown > 0 then
				insertK(ItemProps.TILE_CONST_PLANE)
				insertV(item.planeCountDown)

				insertK(ItemProps.PLANE_DIRECTION)
				insertV(item.planeDirection)
			end
		end

		if item.ItemType == GameItemType.kCattery then
			local catteryLevel = 0
			if item.catteryState == 1 then
				catteryLevel = 2
			elseif item.catteryState == 2 then
				catteryLevel = 1
			end
			if catteryLevel > 0 then
				insertK(ItemProps.TILE_CONST_CATTERY)
				insertV(catteryLevel)

				insertK(ItemProps.CATTERY_DIRECTION)
				insertV(item.catteryDirection)

				insertK(ItemProps.CATTERY_SIZE)
				insertV(item.catterySize)
			end
		end

		if item.ItemType == GameItemType.kCatteryEmpty then
			local root = CatteryLogic:getCatteryRootItem(item)
			local catteryLevel = 0
			if root.catteryState == 1 then
				catteryLevel = 2
			elseif root.catteryState == 2 then
				catteryLevel = 1
			end
			if catteryLevel > 0 then
				insertK(ItemProps.TILE_CONST_CATTERY)
				insertV(catteryLevel)

				insertK(ItemProps.CATTERY_DIRECTION)
				insertV(root.catteryDirection)
			end
		end
		

		if item.ItemType == GameItemType.kMeow then
			if item.meowLevel and item.meowLevel > 0 then
				insertK(ItemProps.TILE_CONST_MEOW)
				insertV(item.meowLevel)
			end
		end


		if item.ItemType == GameItemType.kActivityCollectionItem then
        	insertK(ItemProps.TILE_CONST_ACTIVITY_COLLECT_ITEM)
        	insertV(1)
		end

		if item.ItemType == GameItemType.kWeeklyRace2020Chest then
			local chestRootItem = WeeklyRace2020Logic:getChestRoot(mainlogic, item)
			if chestRootItem then
				local chestLayer = WeeklyRace2020Logic:getWeeklyRace2020ChestLayer(chestRootItem)
				local chestLayerHP = WeeklyRace2020Logic:getWeeklyRace2020ChestLayerHP(chestRootItem)
				if chestLayer > 0 then
					insertK(ItemProps.TILE_CONST_WEEKLY_RACE_2020_FINAL_CHEST)
        			insertV(1)

        			insertK(ItemProps.WEEKLY_RACE_2020_FINAL_CHEST_LAYER)
        			insertV(chestLayer)

        			insertK(ItemProps.WEEKLY_RACE_2020_FINAL_CHEST_LAYER_HP)
        			insertV(chestLayerHP)
				end
			end
		end

		if item.ItemType == GameItemType.kWeeklyRace2020JewelChest then
			local chestRootItem = WeeklyRace2020Logic:getChestRoot(mainlogic, item)
			if chestRootItem then
				local chestLayer = WeeklyRace2020Logic:getWeeklyRace2020ChestLayer(chestRootItem)
				local chestLayerHP = WeeklyRace2020Logic:getWeeklyRace2020ChestLayerHP(chestRootItem)
				if chestLayer > 0 then
					insertK(ItemProps.TILE_CONST_WEEKLY_RACE_2020_JEWEL_CHEST)
        			insertV(1)

        			insertK(ItemProps.WEEKLY_RACE_2020_JEWEL_CHEST_LAYER)
        			insertV(chestLayer)

        			insertK(ItemProps.WEEKLY_RACE_2020_JEWEL_CHEST_LAYER_HP)
        			insertV(chestLayerHP)
				end
			end
		end

		if item.ItemType == GameItemType.kCuckooBird then
			insertK(ItemProps.TILE_CONST_CUCKOO_BIRD)
			insertV(1)
		end
		if item.ItemType == GameItemType.kCuckooClock then
			insertK(ItemProps.TILE_CONST_CUCKOO_CLOCK)
			insertV(1)
		end
		if item.ItemType == GameItemType.kCuckooWindupKey then
			insertK(ItemProps.TILE_CONST_CUCKOO_WINDUP_KEY)
			insertV(1)
		end
		if item.ItemType == GameItemType.kShellGift then
			insertK(ItemProps.SHELL_GIFT)
			insertV(1)
		end
		if item.ItemType == GameItemType.kFirework then
			insertK(ItemProps.TILE_FIREWORK)
			local fireworkLevel = item.fireworkLevel
			insertV(fireworkLevel)
		end
		if item.ItemType == GameItemType.kBattery then
			insertK(ItemProps.TILE_BATTERY)
			local batteryLevel = item.batteryLevel
			insertV(batteryLevel)
		end
	end

	if board then
		-- 等于1时item中存储的lotusLevel会被刷新错误地带走，不可信，故等于1时需用boardData来判断
		if board.lotusLevel == 1 then 
			insertK(158 + board.lotusLevel)
			insertV(1)
		end

		if board.superCuteState ~= GameItemSuperCuteBallState.kNone then   -- 不等于0
			insertK(TileConst.kSuperCute)
			insertV( board.superCuteState ) -- 1 or 2
		end

		if board.iceLevel == 1 then
			insertK(TileConst.kLight1)
			insertV( 1)
		elseif board.iceLevel == 2 then
			insertK(TileConst.kLight1)
			insertV( 2) 
		elseif board.iceLevel == 3 then 
			insertK(TileConst.kLight1)
			insertV( 3)
		end

		-- if board.seaAnimalType and board.seaAnimalType > 0 then
		-- 	insertK( ItemProps.SEA_ANIMAL )
		-- 	insertV( 1 )
		-- end

		if board:hasJamSperad() then 
			insertK( TileConst.kJamSperad )
			insertV( 1)
		end

		if board.isCollector then 
			insertK( TileConst.kCollector )
			insertV( 1)
		end

		-- passType: 1:只有出口，2:只有入口，3:二者皆有
		if (board.passType == 1) or (board.passType == 3) then
			insertK(TileConst.kPortalExit)
			insertV( 1)
		end
		if (board.passType == 2) or (board.passType == 3) then
			insertK(TileConst.kPortalEnter)
			insertV( 1)
		end

		if board:hasTopRopeProperty() then
			insertK(TileConst.kWallUp)
			insertV( 1)
		end
		if board:hasBottomRopeProperty() then
			insertK(TileConst.kWallDown)
			insertV( 1)
		end
		if board:hasLeftRopeProperty() then
			insertK(TileConst.kWallLeft)
			insertV( 1)
		end
		if board:hasRightRopeProperty() then
			insertK(TileConst.kWallRight)
			insertV( 1) 
		end

		-- if board.isRabbitProducer then
		-- 	insertK(TileConst.kRabbitProducer)
		-- 	insertV( 1) 
		-- end

		if board.tileBlockType == 1 then 
			if board.isReverseSide then 
				insertK(TileConst.kTileBlocker)
				insertV( 2) 
			else
				insertK(TileConst.kTileBlocker)
				insertV( 1)
			end

			if board.reverseCount > 0 then
				insertK(ItemProps.REVERSE_COUNT)
				insertV( board.reverseCount)
			end
		end

		if board.tileBlockType == 2 then 
			insertK(TileConst.kDoubleSideTurnTile)
			insertV( 1) 
			if board.reverseCount > 0 then
				insertK(ItemProps.REVERSE_COUNT)
				insertV( board.reverseCount)
			end
		end

		if board.isSnailProducer then
			insertK(TileConst.kSnailSpawn)
			insertV( 1) 
		end

		if board.isSnailCollect then
			insertK(TileConst.kSnailCollect)
			insertV( 1) 
		end

		if board.snailRoadViewType and board.snailRoadViewType > 0 then
			insertK(ItemProps.SNAIL_ROAD)
			insertV( 1 ) 
		end
		
		if board.transType and board.transType ~= 0 then
			insertK(TileConst.kTransmission)
			insertV( 1)
			if board.transType == TransmissionType.kStart then
				insertK(ItemProps.TRANSMISSION_START)
				insertV( 1) 
			elseif board.transType == TransmissionType.kEnd then
				insertK(ItemProps.TRANSMISSION_END)
				insertV( 1) 
			end
			-- insertK(ItemProps.TRANS_TYPE)	--道路形态，AI用下面transLink分析吧
			-- insertV( board.transType) 
		end

		if board.sandLevel ~= 0 then
			insertK(TileConst.kSand)
			insertV( board.sandLevel) 
		end

		if board.chains and table.maxn(board.chains) > 0 then
			for _, chain in pairs(board.chains) do
				if chain.level > 0 then

					if chain.direction == ChainDirConfig.kRight then
						insertK(TileConst.kChain1_Right)
						insertV( chain.level)
					elseif chain.direction == ChainDirConfig.kLeft then
						insertK(TileConst.kChain1_Left)
						insertV( chain.level)
					elseif chain.direction == ChainDirConfig.kDown then
						insertK(TileConst.kChain1_Down)
						insertV( chain.level)
					elseif chain.direction == ChainDirConfig.kUp then
						insertK(TileConst.kChain1_Up)
						insertV( chain.level)
					end


				end
			end
		end

		-- if board.honeySubSelect then  	--AI关心吗？
		-- 	insertK(TileConst.kHoney_Sub_Select)
		-- 	insertV( 1) 
		-- end

		if board.isMoveTile then
			insertK(TileConst.kMoveTile)
			insertV( 1) 
		end

		-- if board.poisonPassSelect then  	--AI关心吗？
		-- 	insertK(TileConst.kPoisonPassSelect)
		-- 	insertV( 1) 
		-- end

		if board.blockerCoverMaterialLevel ~= 0 then
			
			local level = board.blockerCoverMaterialLevel
			-- if level < 0 then level = 0 end
			if level > 0 then
				insertK(TileConst.kBlockerCoverMaterial)
				insertV( level) 
			end
		end

		-- if board.colorFilterState ~= 0 then
		-- 	insertK(ItemProps.COLOR_FILTER_STATE)
		-- 	insertV( board.colorFilterState) 
		-- end

		if board.colorFilterColor ~= 0 then
			insertK(ItemProps.COLOR_FILTER_COLOR)
			insertV( board.colorFilterColor) 
		end
 
		if board.colorFilterBLevel ~= 0 then
			insertK(TileConst.kColorFilter)
			insertV( board.colorFilterBLevel) 
		end

		-- if board.buffBoomPassSelect then	--AI关心吗？
		-- 	insertK(TileConst.kBuffBoomPassSelect)
		-- 	insertV( 1) 
		-- end

		-- if board.preAndBuffFirecrackerPassSelect then	--AI关心吗？
		-- 	insertK(TileConst.kPreAndBuffFirecrackerPassSelect)
		-- 	insertV( 1) 
		-- end
		-- if board.preAndBuffLineWrapPassSelect then	--AI关心吗？
		-- 	insertK(TileConst.kPreAndBuffLineWrapPassSelect)
		-- 	insertV( 1) 
		-- end
		-- if board.preAndBuffMagicBirdPassSelect then	--AI关心吗？
		-- 	insertK(TileConst.kPreAndBuffMagicBirdPassSelect)
		-- 	insertV( 1) 
		-- end

		local biscuitBoard = GameExtandPlayLogic:findBiscuitBoardDataCoveredMe(mainlogic, board.y, board.x)
		if biscuitBoard then

			insertK(TileConst.kBiscuit)
			insertV( 4 - biscuitBoard.biscuitData.level )

			local milkRow, milkCol = biscuitBoard:convertToMilkRC(board.y, board.x)
			local milksCount = biscuitBoard.biscuitData.milks[milkRow][milkCol]
			
			if milksCount + 1 == biscuitBoard.biscuitData.level then
				insertK(ItemProps.BISCUIT_MILK_NUM)
				insertV(  1)
			end
		end

		if board.windTunnelActive then
			-- 风洞风区，只记录当前格子非向下的重力是否生效，不记录具体方向
			if board.windTunnelDir ~= BoardGravityDirection.kDown then
				insertK(TileConst.kWindTunnelTile)
				insertV(1)
			end
		end

		local windTunnelWallStartKey = ItemProps.TILE_CONST_WIND_TUNNEL_WALL_UP - 1
		for windTunnelWallDir = 1, 4 do
			-- 风洞风区边缘，只记录当前格子生效的边缘
			if board:isWindTunnelWallActive(windTunnelWallDir) then
				insertK(windTunnelWallStartKey + windTunnelWallDir)
				insertV(1)
			end
		end

		if board.gravity and board.gravity ~= 0 then
			insertK( ItemProps.GRAVITY_DIR )
			insertV( board.gravity ) 
		end

		if CuckooLogic:gridBelongsToTravelRoad(board) then
			insertK(ItemProps.CUCKOO_ROAD)
			insertV(1) 
		end
	end

	return dataK, dataV
end

local currMainlogic = nil

local function clear()
	gamereplay = nil
	bStop = nil
	currMainlogic = nil
end



local function isOpen()--是否开放快照抓取
	if bOpen == nil then
		local uid = UserManager:getInstance():getUID()
		local switch = MaintenanceManager:getInstance():isEnabledInGroup( maintenanceKey , "ON" ,  uid ) or false

		MACRO_DEV_START()
		switch = true
		MACRO_DEV_END()
		-- RemoteDebug:uploadLogWithTag( "isOpen" ,  "key =" , key , "uid =" , uid , "switch =" , switch )

		if switch then
			bOpen = true
			local data = MaintenanceManager:getInstance():getMaintenanceByKey(maintenanceKey)
			local extra = data and data.extra
			if extra then
				openLevels = {}
				local extraArr = string.split(extra, ",")
				for _, v in pairs(extraArr) do
					local levelData = string.split(v, "-")
					table.insert(openLevels, {min = tonumber(levelData[1]), max = tonumber(levelData[2])})
				end
			end
		else
			bOpen = false
		end
	end

	if currMainlogic and currMainlogic.isEdiotrPlay then
		return true
	end

	-- printx(5, 'isOpen', bOpen)
	return bOpen
end

local function upload()
	-- RemoteDebug:uploadLogWithTag( "Snapshot2" , "SnapshotManager upload  NetworkUtil:isEnableWIFI()" , NetworkUtil:isEnableWIFI() , "gamereplay =" , gamereplay)
	-- printx(5, table.serialize(gamereplay))
	if ( NetworkUtil:isEnableWIFI() or __WIN32 ) and gamereplay then 
	--if gamereplay then
		-- local request = HttpRequest:createPost(StartupConfig:getInstance():getDcUrl())
		-- request:addHeader("Content-Type:application/octet-stream")
		-- RemoteDebug:uploadLogWithTag( "Snapshot3.0" , "111" )
		local replayData = table.serialize(gamereplay)
		-- RemoteDebug:uploadLogWithTag( "Snapshot3.0" , "222" )
		MACRO_DEV_START()
		if __ANDROID then
			Localhost:safeWriteStringToFile( replayData , "//sdcard/SnapshotTest.txt")
		elseif __WIN32 then
			Localhost:safeWriteStringToFile( replayData , "SnapshotTest.txt")
			if currMainlogic and currMainlogic.isEdiotrPlay then
				return
			end
		end
		MACRO_DEV_END()
		replayData = compress(replayData)
		replayData = mime.b64(replayData)
		-- replayData = HeDisplayUtil:urlEncode(replayData)
		verData = getSnapshotManagerVersionData()

		local needDC = true
		MACRO_DEV_START()
		needDC = false
		MACRO_DEV_END()

		if needDC then
			--945号点
			DcUtil:sendSnapshotDC( 
									gamereplay.levelId , 
									tostring(gamereplay.isWin) , 
									gamereplay.ranSeeds , 
									gamereplay.finalScore , 
									replayData , 
									tostring(kSnapshotVersion) ,
									gamereplay.groupTag ,
									verData.itemMajorVersion ,
									verData.itemMinorVersion ,
									verData.maxItemId ,
									verData.targetMajorVersion ,
									verData.targetMinorVersion ,
									verData.maxTargetId 
									)
		end
		
		-- local data = "_uniq_key="..StartupConfig:getInstance():getDcUniqueKey()..
		-- "&_user_id="..UserManager:getInstance().user.uid.."&_ac_type=945&levelId="..
		-- gamereplay.levelId.."&isWin="..tostring(gamereplay.isWin).."&ranSeeds="..
		-- gamereplay.ranSeeds.."&finalScore="..gamereplay.finalScore.."&gamereplay="..replayData.."&ver="..tostring(kSnapshotVersion)

    	-- request:setPostData(data, string.len(data))

		local function callback(response)
			-- RemoteDebug:uploadLogWithTag( "Snapshot4" , "SnapshotManager upload callback  response =" , response , response.httpCode)
		end

		-- RemoteDebug:uploadLogWithTag( "Snapshot3.1" , "data =" , data)
		-- RemoteDebug:uploadLogWithTag( "Snapshot3.2" , "SnapshotManager upload done!!")
    	-- HttpClient:getInstance():sendRequest(callback, request)
	end
end

function SnapshotManager:stop()
	--printx(5, "SnapshotManager:stop", debug.traceback())
	if _G.isLocalDevelopMode then return end
	bStop = true
	-- bStop = false
end

function SnapshotManager:init(mainlogic)

	currMainlogic = mainlogic
	if not isOpen() then return end
	clear() 
	--支持的关卡类型
	--[[
	if not table.exist({GameModeTypeId.CLASSIC_MOVES_ID, GameModeTypeId.LIGHT_UP_ID, 
		GameModeTypeId.DROP_DOWN_ID, GameModeTypeId.ORDER_ID, GameModeTypeId.DIG_MOVE_ID,
		GameModeTypeId.SEA_ORDER_ID, GameModeTypeId.LOTUS_ID}, 
		mainlogic.theGamePlayType) then
		self:stop()
		return
	end
	]]

	verData = getSnapshotManagerVersionData()

	--是不是配置中的关卡
	local bHave = false
	if openLevels then
		for _, v in pairs(openLevels) do
			if not bHave then 
				if mainlogic.level >= v.min and mainlogic.level <= v.max then
					bHave = true
				end
			else
				break
			end
		end
	end
	if not bHave then self:stop() return end

	gamereplay = {}

	gamereplay.maxItemStatus = kMaxItemStatus  --gameitemk's category amount limited (item的维度不超过298)
	gamereplay.starLevel = mainlogic.scoreTargets  --星级配置
	gamereplay.maxTargetStatus = table.size(TargetConst) -- count of TargetConst
	
	gamereplay.levelId = mainlogic.level
	gamereplay.ranSeeds = mainlogic.randomSeed
	gamereplay.gameStates = {}
	
	if GamePlayContext:getInstance().preStartContext then

		local preStartContext = GamePlayContext:getInstance().preStartContext

		local preProps = {}
		if preStartContext.prePropCostInfo then
			for k,v in pairs(preStartContext.prePropCostInfo) do
				table.insert( preProps , v )
			end
		end
		gamereplay.pre_props = preProps
		
		gamereplay.coinWhenStart = preStartContext.baseInfoSnapshot.coinWhenStart
		gamereplay.cashWhenStart = preStartContext.baseInfoSnapshot.cashWhenStart
		gamereplay.energyWhenStart = preStartContext.baseInfoSnapshot.energyWhenStart

		gamereplay.propsWhenStart = preStartContext.bagSnapshot or {}
	end
	
	gamereplay.buffs = GamePlayContext:getInstance().buffs


	gamereplay.newStar = -1
	gamereplay.oldStar = -1
	gamereplay.playLevelCount = -1
	gamereplay.playType = -1
	gamereplay.levelType = -1

	gamereplay.use_prop = false
	gamereplay.used_prop_list = {}
	gamereplay.buy_prop_list = {}

	gamereplay.rewards = {}

	gamereplay.isWin = false

	-- printx( 1 , "WTFFFFFFFFFFFFF!!!!!!!!   gamereplay =" , table.tostring(gamereplay) )
	gamereplay.staticMoves = mainlogic.staticLevelMoves
	self:updateMoves( mainlogic )
end

function SnapshotManager:updateMoves( mainlogic )
	if not isOpen() or bStop then return end
	if gamereplay then
		gamereplay.leftMoves = mainlogic.theCurMoves
		gamereplay.realCostMove = mainlogic.realCostMove
		gamereplay.realCostMoveWithoutBackProp = mainlogic.realCostMoveWithoutBackProp
		gamereplay.allMoves = mainlogic.theCurMoves + mainlogic.realCostMove
	end
end

function SnapshotManager:catchSwapData(data)--交换数据
	-- printx( 1 , "SnapshotManager:catchSwapData",  table.tostring( data ) )
	if not isOpen() or bStop then return end
	if gamereplay and gamereplay.gameStates and (#gamereplay.gameStates > 0) then 
		local stepState = gamereplay.gameStates[#gamereplay.gameStates]
		stepState.swapAction = data
	end
end

function SnapshotManager:catchUseProp(data)--使用道具
	-- printx( 1 , "SnapshotManager:catchUseProp",  table.tostring( data ) )
	if not isOpen() or bStop then return end
	if gamereplay and gamereplay.gameStates and (#gamereplay.gameStates > 0) then 
		local stepState = gamereplay.gameStates[#gamereplay.gameStates]
		stepState.propAction = data
	end
end

function SnapshotManager:removeLastUsePropAction()--移除最后一个state的propAction
	-- printx( 1 , "SnapshotManager:removeLastUsePropAction")
	if not isOpen() or bStop then return end
	if gamereplay and gamereplay.gameStates and (#gamereplay.gameStates > 0) then 
		local stepState = gamereplay.gameStates[#gamereplay.gameStates]
		-- printx( 1 , "SnapshotManager:removeLastUsePropAction   remove : " , stepState.propAction)
		stepState.propAction = nil
	end
end

function SnapshotManager:releaseBuffOrPreProp(data)--实际释放了Buff或者前置道具
	-- printx( 1 , "SnapshotManager:releaseBuffOrPreProp",  table.tostring( data ) )
	if not isOpen() or bStop then return end
	if gamereplay and gamereplay.gameStates and (#gamereplay.gameStates > 0) then 
		local stepState = gamereplay.gameStates[#gamereplay.gameStates]

		if not stepState.buffOrPreActions then
			stepState.buffOrPreActions = {}
		end

		local fixData = {}
		fixData.buffType = data.buffType
		fixData.createType = data.createType
		fixData.x1 = data.c
		fixData.y1 = data.r
		fixData.x2 = data.c2
		fixData.y2 = data.r2

		table.insert( stepState.buffOrPreActions , fixData )
	end
end

function SnapshotManager:buy(data)--购买行为
	-- printx( 1 , "SnapshotManager:buy",  table.tostring( data ) )
	if not isOpen() or bStop then return end
	if gamereplay and gamereplay.gameStates and (#gamereplay.gameStates > 0) then 
		local stepState = gamereplay.gameStates[#gamereplay.gameStates]

		if not stepState.buyActions then
			stepState.buyActions = {}
		end

		table.insert( stepState.buyActions , data )
	end
end

function SnapshotManager:catchStep(mainlogic, bLastStep)--捕获快照
	-- printx( 1 , "SnapshotManager:catchStep", isOpen(), bStop , bLastStep )
	if not isOpen() or bStop then return end
	if mainlogic.replaying then self:stop() return end
	
	if gamereplay then
		gamereplay.finalScore = mainlogic.totalScore

		if not bLastStep then
			self:updateMoves( mainlogic )
		end
		local stepState = self:getStepState(mainlogic)
		table.insert(gamereplay.gameStates, stepState)
	end
	--printx(5, "SnapshotManager:catchStep", table.serialize(gamereplay))
end

function SnapshotManager:getStepState(mainlogic)--BI用，自己只是内部调用

	local stepState = {}
	stepState.isWin = false
	stepState.isEnd = false
	stepState.curScore = mainlogic.totalScore
	stepState.curMoves = mainlogic.realCostMove
	local targetK, targetV = getTargetData(mainlogic)
	stepState.targetK = targetK
	stepState.targetV = targetV
	stepState.canSwaps = SwapItemLogic:calculatePossibleSwap(mainlogic, nil, true)
	stepState.gameItemK = {}
	stepState.gameItemV = {}

	stepState.realCostMove = mainlogic.realCostMove
	stepState.leftMoves = mainlogic.leftMoves

	for r = 1, #mainlogic.gameItemMap do
		local rowK, rowV = {}, {}
  		for c = 1, #mainlogic.gameItemMap[r] do
  			-- printx(11, "============= check data at :", r, c)
  			local item = mainlogic.gameItemMap[r][c]
  			local board = mainlogic.boardmap[r][c]
  			local dataK, dataV = getItemState(item, board, mainlogic)
  			-- printx(11, "dataK, dataV :", table.tostring(dataK), table.tostring(dataV))
  			table.insert(rowK, dataK)
  			table.insert(rowV, dataV)
  		end
  		table.insert(stepState.gameItemK, rowK)
  		table.insert(stepState.gameItemV, rowV)
  	end
  	
  	-- printx(11, "GameItemK:", table.tostring(stepState.gameItemK))
  	-- printx(11, "GameItemV:", table.tostring(stepState.gameItemV))
  	-- printx(11, "targetK", table.tostring(targetK))
  	-- printx(11, "targetV", table.tostring(targetV))
  	-- printx(11, "stepState", table.tostring(stepState))

  	return stepState
end

function SnapshotManager:passLevel(mainlogic, bWin)
	-- RemoteDebug:uploadLogWithTag( "Snapshot1" , "SnapshotManager:passLevel 123123  isOpen() =" , isOpen() , "bStop =" , bStop , "gamereplay =" , gamereplay , "bWin =" , bWin , "FFFFF")
	if not isOpen() or bStop then clear() return end

	local uid = UserManager:getInstance():getUID()
	local onlyUploadByPassed = MaintenanceManager:getInstance():isEnabledInGroup( maintenanceKey , "OnlyPassed" ,  uid ) or false --仅成功过关才上传

	MACRO_DEV_START()
	onlyUploadByPassed = false
	MACRO_DEV_END()

	if onlyUploadByPassed and not bWin then
		clear()
		return
	end

	local groupTag = "forAI"

	if onlyUploadByPassed then
		groupTag = "forAnipop"
	end

	if gamereplay then 
		self:catchStep(mainlogic, true)

		gamereplay.groupTag = groupTag
		gamereplay.isWin = bWin

		local lastState = nil
		local stepNum = #gamereplay.gameStates;
		if stepNum > 0 then
			lastState = gamereplay.gameStates[stepNum]
			lastState.isWin = bWin
			lastState.isEnd = true
		end

		if lastState and gamereplay.isWin then

			local realCostMove = lastState.realCostMove

			for k,v in ipairs( gamereplay.gameStates ) do
				--[[
				local gameItemK = v.gameItemK
				local gameItemV = v.gameItemV
				
				local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainlogic)
				for i = 1 , rowAmount do
					for j = 1 , colAmount do
						local dataK = gameItemK[i][j]
						local dataV = gameItemV[i][j]

						-- STEPS_TO_SUCCESS = 282,		-- 当前state距离成功过关还有多少step
 						--    SUCCESS_LEFT_MOVES = 283,		-- 成功过关时的剩余步数
 						table.insert( dataK , ItemProps.SUCCESS_LEFT_MOVES )
						table.insert( dataV , lastState.leftMoves )

						table.insert( dataK , ItemProps.STEPS_TO_SUCCESS )
						table.insert( dataV , realCostMove - v.realCostMove )
					end
				end
				]]

				local targetK = v.targetK
				local targetV = v.targetV

				table.insert( targetK , TargetConst.SUCCESS_LEFT_MOVES )
				table.insert( targetV , lastState.leftMoves )

				table.insert( targetK , TargetConst.STEPS_TO_SUCCESS )
				table.insert( targetV , realCostMove - v.realCostMove )
			end
		end


		gamereplay.used_prop_list = GamePlayContext:getInstance().usePropList
		gamereplay.buy_prop_list = GamePlayContext:getInstance().buyPropList
		if #gamereplay.used_prop_list > 0 then
			gamereplay.use_prop = true
		end

		gamereplay.newStar = mainlogic.gameMode:getScoreStarLevel()
		gamereplay.oldStar = GamePlayContext:getInstance().levelInfo.oldStar
		if GamePlayContext:getInstance().levelInfo.scoreRefIsNil then
			gamereplay.oldStar = -1
		end
		gamereplay.playLevelCount = GamePlayContext:getInstance():getTotalEndLevelCount()
		gamereplay.playType = GamePlayContext:getInstance().levelInfo.playType
		gamereplay.levelType = GamePlayContext:getInstance().levelInfo.levelType

		gamereplay.rewards = {}
		if GamePlayContext:getInstance().rewards then
			for k,v in pairs(GamePlayContext:getInstance().rewards) do
				local r = {}
				table.insert( r , v.itemId )
				table.insert( r , v.num )
				table.insert( gamereplay.rewards , r )
			end
		end

		gamereplay.playId = GamePlayContext:getInstance():getIdStr()
		gamereplay.replayModeWhenStart = GamePlayContext:getInstance().replayModeWhenStart
		-- printx(5, "SnapshotManager:passLevel", table.serialize(gamereplay))

		gamereplay.major_version = _G.bundleVersion
		gamereplay.minor_version = ResourceLoader.getCurVersion()
		gamereplay.level_config_md5 = LevelMapManager.getInstance():getLevelUpdateVersion()

		gamereplay.seed = GamePlayContext:getInstance().levelInfo.seedValue
		gamereplay.seed_value = GamePlayContext:getInstance().levelInfo.aiSeedValue
		gamereplay.event_id = GamePlayContext:getInstance().levelInfo.aiEventId

		gamereplay.skiped_stage = GamePlayContext:getInstance():getData("isJumpedLevelWhenStart")
		gamereplay.helped_stage = GamePlayContext:getInstance():getData("isHelpedLevelWhenStart")

		xpcall(upload, function(err)
	    	local message = err
	   	 	local traceback = debug.traceback("", 2)
	    	if _G.isLocalDevelopMode then printx(-99, message) end
	   		if _G.isLocalDevelopMode then printx(-99, traceback) end

	   		MACRO_DEV_START()
			RemoteDebug:uploadLogWithTag( "ERR" , "message " , message)
	   		RemoteDebug:uploadLogWithTag( "ERR" , "traceback " , traceback)
	   		setTimeOut( function () CommonTip:showTip( message .. traceback , "negative" , nil , 999 ) end , 3 )
			MACRO_DEV_END()
	   		
	   	end)

	end

	clear()
end

function SnapshotManager:parseString(data)
	local mime = require("mime.core")
	data = HeDisplayUtil:urlDecode(data)
	data = mime.unb64(data)
	data = uncompress(data)
	-- printx(5, "SnapshotManager:parseString", data)
end

function SnapshotManager:getWanshengDef(Def)

    local ColorType = AnimalTypeConfig.getType(Def)
    local specialType = AnimalTypeConfig.getSpecial( Def )

    local colorIndex = AnimalTypeConfig.convertColorTypeToIndex(ColorType)
    local specialIndex = AnimalTypeConfig.convertSpecialTypeToIndex(specialType)

    return specialIndex*10 + colorIndex
end