local __encryptKeys = {
	theCurMoves = true, 
	totalScore = true, 
	ingredientsCount = true, 
	kLightUpLeftCount = true, 
	fireworkEnergy = true,
	coinDestroyNum = true,
	oringinTotalScore = true,
}

GameBoardModel = memory_class_simple(__encryptKeys)



function GameBoardModel:create()
	local m = GameBoardModel.new()

	--[[
	local keys = {
		"itemMap" ,
		"boardMap" ,
		"backItemMap" ,
		"backBoardMap" ,


		------以下兼容老字段-------
		"gameItemMap" ,
		"boardmap"
	}

	buildGetterSetter( m , keys , "__on_setter" , "__on_getter" , 2 )
	]]

	m:initSelf()

	return m
end

function GameBoardModel:ctor()
	
end

function GameBoardModel:__on_getter( k , rawData )
	-- printx( 1 , "__on_getter  " , k )
	local _context = self
	local _returnData = nil
	lua_switch( k ){

		itemMap = function ( ... )
			_returnData = _context.itemMapList[1]
		end,

		boardMap = function ( ... )
			_returnData = _context.boardMapList[1]
		end,

		backItemMap = function ( ... )
			_returnData = _context.itemMapList[2]
		end,

		backBoardMap = function ( ... )
			_returnData = _context.boardMapList[2]
		end,

		gameItemMap = function ( ... )
			_returnData = _context.itemMapList[1]
		end,

		boardmap = function ( ... )
			_returnData = _context.boardMapList[1]
		end,
	}

	return _returnData
end

function GameBoardModel:__on_setter( k , v , rawData )
	local _context = self
	local _returnData = nil
	-- printx( 1 , "__on_setter  " , k , v)

	lua_switch( k ){

		itemMap = function ( ... )
			_context.itemMapList[1] = v
		end,

		boardMap = function ( ... )
			
			_context.boardMapList[1] = v
		end,

		backItemMap = function ( ... )
			_context.itemMapList[2] = v
		end,

		backBoardMap = function ( ... )
			_context.boardMapList[2] = v
		end,

		gameItemMap = function ( ... )
			_context.itemMapList[1] = v
		end,

		boardmap = function ( ... )
			_context.boardMapList[1] = v
		end,
	}
end

function GameBoardModel:initSelf()

	self.isDisposed = false

	self.originLevelConfig = nil
	self.levelConfig = self.originLevelConfig

	self.itemMapList = {}
	self.boardMapList = {}

	self.itemMapList[1] = {}
	self.boardMapList[1] = {}

	self.itemMapList[2] = {}
	self.boardMapList[2] = {}


	-------------------------
	self.itemMap = self.itemMapList[1]
	self.boardMap = self.boardMapList[1]
	self.backItemMap = self.itemMapList[2]
	self.backBoardMap = self.boardMapList[2]


	------以下兼容老字段-------
	self.gameItemMap = self.itemMap
	self.boardmap = self.boardMap
	--------------------------

	-- debug.debug()

	-- 初始化时不知道棋盘大小，只能先用默认的9做初始化
	for i= 1,9 do
		self.boardMap[i] = {}
		self.backBoardMap[i] = {}
		for j=1,9 do
			self.boardMap[i][j] = GameBoardData:create();
		end
	end

	for i=1,9 do
		self.itemMap[i] = {}
		self.backItemMap[i] = {}
		for j=1,9 do
			self.itemMap[i][j] = GameItemData:create();
		end
	end
  	
  	self.level = 0
  	self.entranceLevel = 0			--进入关卡时的关卡号（旅行模式会切换关卡，但此值不变）
  	self.theGamePlayType = 0
  	self.levelType = nil
  	self.theGamePlayStatus = 0
  	self.gameDataVersion = 0

	self.replayMode = ReplayMode.kNone
	self.replaying = false
	self.replaySteps = {}
	self.replayStep = 1
	self.replayWithDropBuff = false
	self.replay = nil               ------本关卡需要记录的replay
	self.allReplay = nil            ------所有replay信息
	self.setWriteReplayEnable = true     ----------是否可以写replay
	self.blockReplayReord = 0
	self.AIPlayQAAdjustBreakAfterAll = false

	-- self.gameMode = nil

	self.theCurMoves = 0;				----当前剩余移动量
	self.realCostMove = 0 				----实际使用过的步数
	self.realCostMoveWithoutBackProp = 0
	self.leftMoves = 0                  -----BonusTime时的剩余步数
	self.scoreTargets = {1,2,3};

	self.theOrderList = {};				----目标列表

	self.posAdd = nil 					----NewGameBoardLogic:getGameItemPosInView_ForPreProp做偏移用
  	
	self.mapColorList = {}  			--当前地图可选颜色列表
	self.mapColorWeightList = nil 		--当前地图可选颜色中，每种颜色的权重（影响全局掉落）
	self.numberOfColors = 3;			--地图方块颜色数量
	self.colortypes = {}				--颜色集合
	self.dropCrystalStoneColors = nil   --染色宝宝掉落颜色
	self.replaceColorMaxNum = nil

	self.swapHelpMap = nil; 			--帮助做交换和Match的辅助Map
	self.swapHelpList = nil;
	self.swapHelpMakePos = nil;

	self.needCheckFalling = true			-- 标志位确定是否需要检查掉落（开关，设置为true后执行掉落消除直至稳定时被设置为false,isFallingStable属性为结果）
	self.isFallingStable = false			-- 标志位，表示当前是否处于掉落稳定状态
	self.isFallingStablePreFrame = false 	-- 标志位，表示上一帧是否处于掉落稳定状态
	self.isRealFallingStable = false 	-- 标志位，表示当前是否处于掉落稳定状态，由于增加了onRealStable方法，只有这个方法执行后，isRealFallingStable才为true
	
	self.isBonusTime = false
	self.isInStep = false 				----此次Falling&Match状态是否由swap操作引起，与之对应的是由道具操作引起
	self.isWaitingOperation = false		----正在等待用户操作 
	self.isGamePaused = false;			----是否暂停
	self.isShowAdvise = false;



	self.FallingHelpMap = nil;
	self.isBlockChange = false;

	self.EffectHelpMap = nil;			--匹配对格子的影响，数据为棋盘数组，-1表示格子上有消除，0表示不受影响，>0表示周边格子参与匹配的次数
	self.EffectSHelpMap = nil;			--好像没有任何引用？=___=
	self.EffectLightUpHelpMap = nil
	self.EffectChameleonHelpMap = nil 	--影响变色龙的周围消除记录，棋盘数组索引，每格中存入“颜色,类型(区分特效)”字符串组成的数组数据【目前只有格子上有变色龙才会记录】

	self.comboCount = 0;
	self.comboHelpDataSet = nil;		----连击帮助集合
	self.comboHelpList = nil;			----连击帮助列表
	self.comboHelpNumCountList = nil; 	----连击消除小动物数量
	self.comboSumBombScore = nil;		----连击的引爆分数
	self.totalScore = 0;				----当前得分
	self.oringinTotalScore = 0;			----被修正前的原始得分
	self.bonusTimeScore = 0				----进入bonusTime的一瞬间的得分
	self.coinDestroyNum = 0 			----销毁的银币数量

	self.hasUseRevertThisRound = false   ----是否在此次操作回合内使用过回退道具,游戏初始化后未操作前需要禁用回退
	self.isVenomDestroyedInStep = false ----是否在本次操作回合内消除过毒液
	self.questionMarkFirstBomb = true
	self.isFirstRefreshComplete = true

	self.snapshotModeEnable = false

	self.actCollectionNum = 0 		--活动收集物数量

	self.lastCreateBuffBoomMoveSteps = 0

	self.bigMonsterMark = nil
	self.chestSquareMark = nil

	------气球
	self.balloonFrom = 0             ---------气球的剩余步数
	self.addMoveBase = GamePlayConfig_Add_Move_Base                 ---------气球爆炸增加的步数

	------豆荚
	self.ingredientsTotal = 0;			----需要掉落的豆荚总数
	self.ingredientsCount = 0;
	self.ingredientsProductDropList = {};		----可以掉落豆荚的掉落口列表
	self.toBeCollected = 0

	self.digJewelLeftCount = 0
	self.digJewelTotalCount = 0

	------冰块
	self.kLightUpTotal = 0;
	self.kLightUpLeftCount = 0;			----剩余的冰层数量

	------荷塘
	self.lotusEliminationNum = 0
	self.lotusPrevStepEliminationNum = 0
	self.initLotusNum = 0
	self.currLotusNum = 0
	self.destroyLotusNum = 0

	------蜗牛
	self.snailCount = 0
	self.snailMoveCount = 0
	self.snailMark = false

	------吃豆人
	self.pacmanConfig = nil
	self.pacmanGeneratedByStep = 0		--- 生成的吃豆人数量（通过步数）
	self.pacmanGeneratedByBoardMin = 0	---	生成的吃豆人数量（通过棋盘最少限制）

	------小幽灵
	self.ghostConfig = nil
	self.ghostGeneratedByStep = 0		--- 生成的鬼魂数量（通过步数）
	self.ghostGeneratedByBoardMin = 0	---	生成的鬼魂数量（通过棋盘最少限制）

	------刷分瓶子
	self.generatedScoreBuffBottle = 0	-- 已生成的刷星瓶子数
	self.destroyedScoreBuffBottle = 0	-- 已使用的刷星瓶子数（提升检测效率用）
	self.scoreBuffBottleLeftSpecialTypes = nil 	--剩余特效池
	self.scoreBuffBottleInitAmount = nil 		-- 初始数量（断面用 & 回放）
	self.globalScoreBuffVal = nil 			-- 获得分数时的倍数，与刷分模块一定程度关联

	------太阳花
	self.sunflowersAppetite = 0 				-- 还需多少份太阳砂
	self.sunflowerEnergy = 0 					-- 已经吃掉了多少份太阳

	------小叶堆
	self.blockerCoverTarNum1 = 0
	self.blockerCoverTarNum2 = 0
	self.blockerCoverTarNum3 = 0

	----------- 旅行模式只有NewGameBoardLogic支持 -----------
	self.currTravelMapIndex = 1					-- 当前旅行地图进度（多屏模式通用）
	self.traveledLevelRecord = nil 				-- 多屏旅行中，历经的关卡记录（需根据具体需求自行调整入选内容）
	self.travelMapInitLeftMove = 0 				-- (统计用)开始每张图时的初始步数
	self.travelMapInitUsedMove = 0 				-- (统计用)进入每张图时的已用步数

	self.travelEnergy = 0 						-- 当前积攒的旅行能量
	self.skipTravelStateType = 0 				-- [临时] 某些障碍被攻击后，不会影响stable状态并需要等到自己的state才会处理，此间屏蔽旅行检测
	self.travelEventBoxOpened = false 			-- 事件盒子是否打开过（回退用，目前全程只会有一个盒子，所以为节省效率单独记录）
	self.currMapTravelRouteLength = 0			-- 当前地图的路径长度
	self.currMapTravelStep = 0					-- 当前地图走了多少格
	--------------------------------------------------------

	self.blocker195Nums = nil  	--星星瓶需要多少个充满
	self.blocker199Cfg = nil		--水母宝宝
	self.blocker206Cfg = nil    --锁
	self.blocker207DestroyNum = 0

	self.GyroConfig = nil
	self.waterBucketCfg = nil
	self.curWaterBucketChargingGroupId = 1

	self.honeys = 0        ----------------蜂蜜罐破裂要传染的个数
	self.missileSplit = 0	----------------冰封导弹分裂数
	self.squidOnBoard = nil 					-- 棋盘上的鱿鱼（优化检测效率用）
	self.blockerCoverMaterialTotalNum = 0
	self.hadAutoSnowMonsterBuff = false
	self.hadAutoBuffActived = false
	
	self.uncertainCfg1 = nil
	self.uncertainCfg2 = nil
	self.hedgehogBoxCfg = nil
	
	self.generateFirecrackerTemp = 0  				--生成过爆竹
	self.generateFirecrackerTimes = 0  				--生成过多少次爆竹
	self.generateFirecrackerTimesForPreBuff = 0

	self.needUpdateSeaAnimalStaticData = nil

	self.getProps = {}                    ---- 本关获得的道具

	-- CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()

	self.initAdjustData = nil

	-- random bonus
	self.randomAnimalHelpList = {}		----最后随机时屏幕中所有可以被随机到的item

	self.collectTargetNums = nil 			--（显示用）收集物展示条上(Common_collectProgress)记录的数量们
	self.extraGainedActCollections = nil  	-- 因一些原因额外获得的收集物们
	self.moveBonusHarvested = false 		-- 步数奖励是否已经展示过了（一般活动用）

	self.moveTileCarryProductRuleMode = false

	self.angryBirdNum = 0 --棋盘中愤怒的小鸟的数量

	self.NDbunnyConfig = nil
	self.NDbunnyGlobalConfig = nil
	self.NDbunnyGridConfig = nil
	self.NDbunnySnowGridConfig = nil

	if ResumeGamePlayPopoutActionCheckFlag == "checked" then
		ResumeGamePlayPopoutActionCheckFlag = "done"
	elseif ResumeGamePlayPopoutActionCheckFlag == "done" then

	else
		if not _G.isLocalDevelopMode then
			he_log_error("ResumeGamePlayPopoutAction has passed !!! V3")
		end
		ResumeGamePlayPopoutActionCheckFlag = "done"
	end

	self.stageStartTime = 0
	self.passFailedCount = 0

	-----------------------废弃字段------------------------------------
	self.timeTotalLimit = 0;			----总时间限制
	self.extraTime = 0;					----获得的总额外时间
	self.timeTotalUsed = 0;				----总时间消耗
	self.flyingAddTime = 0

	self.hasDropDownUFO = false         -----ufo
	self.isUFOWin = false
	self.UFOCollection = {}           ------ufo 收集的豌豆荚
	self.UFOSleepCD = 0 			-- UFO眩晕回合数
	self.oldUFOSleepCD = 0			-- 该回合开始前UFO晕眩回合数，用于回退一步处理

	self.pm25 = nil
	self.pm25count = 0        --------pm2.5计数

	self.fireworkEnergy = 0
	self.forbidChargeFirework = nil
	self.isFullFirework = false
end


function GameBoardModel:dispose()
	self.isDisposed = true
end

function GameBoardModel:initByConfig( levelConfig , otherDatas )
	-- local level

	self.theGamePlayStatus = GamePlayStatus.kPreStart

	self.replayMode = otherDatas.replayMode or ReplayMode.kNone

	self.replayData = otherDatas.replayData
	self.forceUseDropBuff = otherDatas.forceUseDropBuff


	self.originLevelConfig = levelConfig
	self.levelConfig = levelConfig

	self.level = levelConfig.level
	self.entranceLevel = self.level
	self.levelType = LevelType:getLevelTypeByLevelId( self.level )
	self.theGamePlayType = LevelMapManager:getLevelGameModeByName(levelConfig.gameMode)

	self.totalScore = 0
	self.oringinTotalScore = 0
	self.bonusTimeScore = 0
	self.pre_prop_pos = {}
	self.gameDataVersion = levelConfig.gameDataVersion or 0

    self.SunmerFish3x3GetNum = levelConfig.SunmerFish3x3GetNum or 1

	local modeProcessorDatas = {}
	if levelConfig.pluginMode then
		if levelConfig.pluginMode.pluginSwitchInfo and levelConfig.pluginMode.pluginSwitchInfo.m1 then
			modeProcessorDatas.changeGlobalGravityBySwap = true
		end
	end
	self.modeProcessorDatas = modeProcessorDatas
	

	--气球处理
	if levelConfig.balloonFrom then 
		self.balloonFrom = levelConfig.balloonFrom
	end

	if levelConfig.addMoveBase and levelConfig.addMoveBase > 0 then
		self.addMoveBase = tonumber(levelConfig.addMoveBase)
		if self.addMoveBase > 9 then
			self.addMoveBase = 9
		end
	end

	if levelConfig.addTime then
		self.addTime = tonumber(levelConfig.addTime)
		if self.addTime > 9 then
			self.addTime = 9
		end
	end

	self.uncertainCfg1 = levelConfig.uncertainCfg1
	self.uncertainCfg2 = levelConfig.uncertainCfg2
	self.hedgehogBoxCfg = levelConfig.hedgehogBoxCfg

	self.blockerCoverTarNum1 = levelConfig.blockerCoverTarNum1 or 0
	self.blockerCoverTarNum2 = levelConfig.blockerCoverTarNum2 or 0
	self.blockerCoverTarNum3 = levelConfig.blockerCoverTarNum3 or 0

	self.blocker195Nums = levelConfig.blocker195Nums
	self.blocker199Cfg = levelConfig.blocker199Cfg

	if levelConfig.blocker206Cfg then self.blocker206Cfg = table.clone(levelConfig.blocker206Cfg) end
	self.pacmanConfig = levelConfig.pacmanConfig
	self.ghostConfig = levelConfig.ghostConfig
	self.GyroConfig = levelConfig.gyroCreaterData
	self.waterBucketCfg = levelConfig.waterBucketCfg
	self.NDbunnyConfig = levelConfig.NDbunnyConfig
	self.NDbunnyGlobalConfig = levelConfig.NDbunnyGlobalConfig
	self.NDbunnyGridConfig = levelConfig.NDbunnyGridConfig
	self.NDbunnySnowGridConfig = levelConfig.NDbunnySnowGridConfig

	self.honeys = levelConfig.honeys
	self.missileSplit = levelConfig.missileSplit
	self.hasDropDownUFO = levelConfig.hasDropDownUFO or self.theGamePlayType == GameModeTypeId.RABBIT_WEEKLY_ID
	self.pm25 = levelConfig.pm25
	self.sunflowersAppetite = levelConfig.sunflowersAppetite

	self.theCurMoves = levelConfig.moveLimit
	if not self.theCurMoves then self.theCurMoves = 0 end
	self.staticLevelMoves = self.theCurMoves

	
	self.scoreTargets = levelConfig.scoreTargets
	self.replaceColorMaxNum = levelConfig.replaceColorMaxNum

	self.singleDropCfg = levelConfig.singleDropCfg

	--------------------------------------------
	--以下字段是新掉落规则框架下的字段，
	--在ProductItemLogic:init中进行初始化
	self.singleDropConfigGroup = nil         --分组存储的掉落颜色配置
	self.productRuleGroup = nil              --分组存储的掉落规则配置
	self.productRuleConfig = nil             --储存每个掉落口对应的组ID，默认配置存在坐标0_0上
	self.productRuleGlobalConfig = nil       --全局配置的Q和P信息，将覆盖productRuleGroup里的对应字段
	self.cachePoolV2 = nil                   --新版cachePool，分组存储

	self.moveTileCarryProductRuleMode = levelConfig.moveTileCarryProductRuleMode
	---------------------------------------------

	self.needCheckFalling = true
	self.isFallingStable = false
	self.isFallingStablePreFrame = false
	self.timeTotalUsed = 0
	self.ingredientsCount = 0

	self.hadAutoSnowMonsterBuff = GameInitBuffLogic:isSnowMonsterBuff()	

	self.gamePlayEventTrigger = GamePlayEventTrigger:create()

	-- if self.replaying then
	-- 	self.initialMapData = self:getSaveDataForRevert()
	-- end
	
end

function GameBoardModel:mergeFrom()

end

function GameBoardModel:dispose()

end

function GameBoardModel:encryptionFunc( key, value )
	-- assert(__encryptKeys[key])
	if value == nil then value = 0 end
	HeMemDataHolder:setInteger(self:getEncryptKey(key), value)
end

function GameBoardModel:decryptionFunc( key )
	-- assert(__encryptKeys[key])
	return HeMemDataHolder:getInteger(self:getEncryptKey(key))
end

function GameBoardModel:getEncryptKey(key)
	return key .. "_" .. self.__class_id
end