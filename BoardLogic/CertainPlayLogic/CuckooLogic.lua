CuckooLogic = class{}

CuckooBirdInteractType =
{
	kNone = 0,
	kWalk = 1,
	kAttackBlocker = 2,
	kAttackChain = 3,
}

-- 前进检测因等待一些障碍的处理(state)而暂时被屏蔽
CuckooBirdWalkStateBlockType = 
{
	kBrownCuteBall = 1
}

------------------------------- Route ------------------------------------
function CuckooLogic:initTravelRouteData(mainLogic, config)
	local tileMap = config.cuckooRouteRawData
	-- printx(11, "cuckoo initTravelRouteData, tileMap", table.tostring(tileMap))
	if not tileMap then return end
	if not mainLogic or not mainLogic.boardmap then return end
	
	for r = 1, #tileMap do 
		if tileMap[r] then
			for c = 1, #tileMap[r] do
				local tileDef = tileMap[r][c]
				if tileDef then
					CuckooLogic:_initTravelRoadTypeByConfig(mainLogic, r, c, tileDef)
				end
			end
		end
	end

	local travelRouteLength = 0
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]

			if CuckooLogic:_gridHasTravelRoadData(board) and not CuckooLogic:_gridHasPrevTravelRoad(board) then
				board.isTravelRoadStart = true
			end

			if not CuckooLogic:_gridHasTravelRoadData(board) and CuckooLogic:_gridHasPrevTravelRoad(board) then
				board.isTravelRoadEnd = true
			end

			if CuckooLogic:_gridHasTravelRoadData(board) then
				-- 多算了鸟脚下一格，少算了终点前一格，正负相抵总数不变
				travelRouteLength = travelRouteLength + 1
			end
		end
	end
	mainLogic.currMapTravelRouteLength = travelRouteLength
end

function CuckooLogic:_initTravelRoadTypeByConfig(mainLogic, r, c, tileDef)
	local currDir
	local nextR = r
	local nextC = c
	if tileDef then 
		if tileDef:hasProperty(RouteConst.kUp) then
			currDir = RouteConst.kUp
			nextR = nextR - 1
		elseif tileDef:hasProperty(RouteConst.kDown) then
			currDir = RouteConst.kDown
			nextR = nextR + 1
		elseif tileDef:hasProperty(RouteConst.kLeft) then
			currDir = RouteConst.kLeft
			nextC = nextC - 1
		elseif tileDef:hasProperty(RouteConst.kRight) then
			currDir = RouteConst.kRight
			nextC = nextC + 1
		end
	end

	if currDir then
		local boardData = mainLogic:safeGetBoardData(r, c)
		if boardData then
			boardData.travelRoadType = currDir
			-- printx(11, "set travelRoadType:", currDir, r, c)
		end

		local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
		if nextBoardData then
			nextBoardData.prevTravelRoadType = currDir
			-- printx(11, "set prevTravelRoadType:", currDir, r, c)
		end
	end
end

function CuckooLogic:_gridHasTravelRoadData(boardData)
	if boardData and boardData.travelRoadType and boardData.travelRoadType > 0 then
		return true
	end
	return false
end

function CuckooLogic:_gridHasPrevTravelRoad(boardData)
	if boardData and boardData.prevTravelRoadType and boardData.prevTravelRoadType > 0 then
		return true
	end
	return false
end

-- 与_gridHasTravelRoadData的区别：最后一格也算上
function CuckooLogic:gridBelongsToTravelRoad(boardData)
	if boardData then
		if (boardData.travelRoadType and boardData.travelRoadType > 0) or boardData.isTravelRoadEnd then
			return true
		end
	end
	return false
end

function CuckooLogic:_getNextGridPositionByDirection(currR, currC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local currGridData = mainLogic:safeGetBoardData(currR, currC)
	if currGridData then
		if currGridData.travelRoadType == RouteConst.kUp then
			return true, currR - 1, currC
		elseif currGridData.travelRoadType == RouteConst.kDown then
			return true, currR + 1, currC
		elseif currGridData.travelRoadType == RouteConst.kLeft then
			return true, currR, currC - 1
		elseif currGridData.travelRoadType == RouteConst.kRight then
			return true, currR, currC + 1
		end
	end
	return false
end

function CuckooLogic:convertRoadTypeToAssetDir(roadType)
	local roadDirection = 0
	if roadType == RouteConst.kUp then
		roadDirection = 1
	elseif roadType == RouteConst.kRight then
		roadDirection = 2
	elseif roadType == RouteConst.kDown then
		roadDirection = 3
	elseif roadType == RouteConst.kLeft then
		roadDirection = 4
	end
	return roadDirection
end

-- 返回终点建筑之于路径最后一格的相对方位
function CuckooLogic:getFinalBuildingDirection(roadEndR, roadEndC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return 0 end

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local buildingDir = 0
	
	--- 1-4:上右下左
	for dir = 1, 4 do
		local targetRow = roadEndR + aroundY[dir]
		local targetCol = roadEndC + aroundX[dir]
		local itemData = mainLogic:safeGetItemData(targetRow, targetCol)
		if itemData and itemData.ItemType == GameItemType.kCuckooClock then
			buildingDir = dir
			break
		end
	end
	return buildingDir
end

function CuckooLogic:posHasFinalBuildingAndRoadDir(posR, posC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local itemData = mainLogic:safeGetItemData(posR, posC)
	if itemData and itemData.ItemType == GameItemType.kCuckooClock then
		for dir = 1, 4 do
			local targetRow = posR + aroundY[dir]
			local targetCol = posC + aroundX[dir]
			local boardData = mainLogic:safeGetBoardData(targetRow, targetCol)
			if boardData and boardData.isTravelRoadEnd then
				return true, dir
			end
		end

	end
	return false
end

-----------------------------------------------------------------------------------------
function CuckooLogic:onCuckooWindUpKeyDemolished(targetKey)
	-- printx(11, "--------------- onCuckooWindUpKeyDemolished -----------------------", targetKey.y, targetKey.x, debug.traceback())
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	local row = targetKey.y
	local col = targetKey.x

	local cuckoo = CuckooLogic:getCuckooOnBoard(mainLogic)
	if cuckoo and not cuckoo.cuckooBirdReachedEnd then
		if not cuckoo.cuckooBirdReachedEnd then
			CuckooLogic:_addCuckooEnergy(mainLogic)

			local action = GameBoardActionDataSet:createAs(
				GameActionTargetType.kGameItemAction,
				GameItemActionType.kItem_Cuckoo_Absorb_Energy, 
				IntCoord:create(col, row),
				nil,
				GamePlayConfig_MaxAction_time
				)
			action.cuckooBird = cuckoo

			local windupKeyView = mainLogic.boardView.baseMap[row][col]
			local fromPos = windupKeyView:getBasePosition(col, row)
			action.fromPos = fromPos

			local bagColor = targetKey._encrypt.ItemColorType
			local colourIndex = AnimalTypeConfig.convertColorTypeToIndex(bagColor)
			action.bagColour = colourIndex

			mainLogic:addDestroyAction(action)
			mainLogic:setNeedCheckFalling()
		end

		SquidLogic:checkSquidCollectItem(mainLogic, row, col, TileConst.kCuckooWindupKey)
		GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, row, col, Blocker195CollectType.kCuckooWindupKey)
	end
end

function CuckooLogic:_addCuckooEnergy(mainLogic)
	if not mainLogic.cuckooEnergy then mainLogic.cuckooEnergy = 0 end
	mainLogic.cuckooEnergy = mainLogic.cuckooEnergy + 1
	-- printx(11, "~~~~~ _addCuckooEnergy ~~~~~, curr:", mainLogic.cuckooEnergy)
end

function CuckooLogic:consumeCuckooEnergy()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	if mainLogic.cuckooEnergy and mainLogic.cuckooEnergy > 0 then
		mainLogic.cuckooEnergy = math.max(0, mainLogic.cuckooEnergy - 1)
		-- printx(11, "~~~~~ consumeCuckooEnergy ~~~~~, curr:", mainLogic.cuckooEnergy)
	end
end

function CuckooLogic:clearCuckooEnergy()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	mainLogic.cuckooEnergy = 0
	-- printx(11, "~~~~~ clearCuckooEnergy ~~~~~")
end

------------------------------ Bird ----------------------------------
function CuckooLogic:getCuckooOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item.ItemType == GameItemType.kCuckooBird then
				return item
			end
		end
	end
	return nil
end

function CuckooLogic:getDirectionByShiftValue(shiftR, shiftC)
	local direction = 0
	if shiftR < 0 then
		direction = 1
	elseif shiftR > 0 then
		direction = 3
	elseif shiftC < 0 then
		direction = 4
	elseif shiftC > 0 then
		direction = 2
	end
	return direction
end

function CuckooLogic:checkNextGridInteractType(cuckooBird)
	-- printx(11, "^^^ checkNextGridInteractType", cuckooBird.y, cuckooBird.x)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return CuckooBirdInteractType.kNone end

	local hasNextGrid, nextR, nextC = CuckooLogic:_getNextGridPositionByDirection(cuckooBird.y, cuckooBird.x)
	-- printx(11, "^^^ ^^^ hasNextGrid, nextR, nextC", hasNextGrid, nextR, nextC)
	if not hasNextGrid or not mainLogic:isPosValid(nextR, nextC) then 
		return CuckooBirdInteractType.kNone 
	end

	local nextItemData = mainLogic:safeGetItemData(nextR, nextC)
	local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
	if not nextItemData or not nextBoardData then return CuckooBirdInteractType.kNone end

	local chainLevel = CuckooLogic:_getMaxChainLevelInWalkingDirection(mainLogic, cuckooBird.y, cuckooBird.x, nextR, nextC)
	-- printx(11, "chainLevel between", cuckooBird.y, cuckooBird.x, nextR, nextC, chainLevel)
	if chainLevel > 0 then
		-- printx(11, "^^^ ^^^ ATTACK chain!", chainLevel)
		return CuckooBirdInteractType.kAttackChain, nextItemData, chainLevel
	end

	-- printx(11, "^^^ ^^^ check action type..")
	if CuckooLogic:_isExchangeableItemForCuckooBird(mainLogic, nextItemData) then
		-- printx(11, "^^^ ^^^ WALK!")
		return CuckooBirdInteractType.kWalk, nextItemData
	else
		-- 攻击次数，攻击后是否清除能量，攻击后等候类型
		local attackTimes, clearEnergyAfterAttack, blockType = CuckooLogic:_getAttackTimes(nextItemData, mainLogic)
		-- printx(11, "* * * ____ attackTimes:", attackTimes, clearEnergyAfterAttack, blockType)
		if attackTimes and attackTimes > 0 then
			-- printx(11, "^^^ ^^^ ATTACK!")
			return CuckooBirdInteractType.kAttackBlocker, nextItemData, attackTimes, clearEnergyAfterAttack, blockType
		else
			-- printx(11, "^^^ ^^^ NAH")
			return CuckooBirdInteractType.kNone
		end
	end
end

function CuckooLogic:_getMaxChainLevelInWalkingDirection(mainLogic, currR, currC, nextR, nextC)
	local currBoardData = mainLogic:safeGetBoardData(currR, currC)
	local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
	if not currBoardData or not nextBoardData then return 0 end

	local currChain, nextChain
	if currBoardData.travelRoadType == RouteConst.kUp then
		currChain = currBoardData:getChainInDirection(ChainDirConfig.kUp)
		nextChain = nextBoardData:getChainInDirection(ChainDirConfig.kDown)
	elseif currBoardData.travelRoadType == RouteConst.kDown then
		currChain = currBoardData:getChainInDirection(ChainDirConfig.kDown)
		nextChain = nextBoardData:getChainInDirection(ChainDirConfig.kUp)
	elseif currBoardData.travelRoadType == RouteConst.kLeft then
		currChain = currBoardData:getChainInDirection(ChainDirConfig.kLeft)
		nextChain = nextBoardData:getChainInDirection(ChainDirConfig.kRight)
	elseif currBoardData.travelRoadType == RouteConst.kRight then
		currChain = currBoardData:getChainInDirection(ChainDirConfig.kRight)
		nextChain = nextBoardData:getChainInDirection(ChainDirConfig.kLeft)
	end

	local maxChainLevel = 0
	if currChain and currChain.level then
		maxChainLevel = math.max(maxChainLevel, currChain.level)
	end
	if nextChain and nextChain.level then
		maxChainLevel = math.max(maxChainLevel, nextChain.level)
	end
	return maxChainLevel
end

CuckooBirdExchangableItems = table.const{
	GameItemType.kBlocker195, GameItemType.kCrystalStone, GameItemType.kTotems, GameItemType.kMissile, GameItemType.kBlocker199, 
	GameItemType.kGift, GameItemType.kNewGift,GameItemType.kShellGift, GameItemType.kMagicLamp, GameItemType.kPacman, GameItemType.kPuffer, 
	GameItemType.kBlocker207, GameItemType.kBalloon, GameItemType.kBuffBoom, GameItemType.kScoreBuffBottle, GameItemType.kFirecracker,
	GameItemType.kAnimal, GameItemType.kHoneyBottle, GameItemType.kWanSheng, GameItemType.kIngredient, GameItemType.kCoin, 
	GameItemType.kChameleon, GameItemType.kCrystal, GameItemType.kAnimal, GameItemType.kWater, GameItemType.kCuckooWindupKey,
	GameItemType.kPlane,GameItemType.kAddMove,GameItemType.kBattery,GameItemType.kpuffedRice,
}

function CuckooLogic:_isExchangeableItemForCuckooBird(mainLogic, item)
	if item and item.isUsed then
		-- printx(11, "----------- Exchange?", index, item.isEmpty)
		if not CanevineLogic:is_occupy(item) and item:isVisibleAndFree() then
			local index = table.indexOf(CuckooBirdExchangableItems, item.ItemType)
			if (index and index > 0) or item.isEmpty then
				if item.ItemType == GameItemType.kBlocker199 then
					if item:isBlocker199Active() then return true else return false end
				elseif item.ItemType == GameItemType.kTotems then
					if not item:isActiveTotems() then return true else return false end
				else
					return true
				end
			end
		elseif item:isTopCover(GameItemDataTopCoverName.k_Ghost) then
			return true
		end
	end
	return false
end

-- 由于每种障碍处理时间长度不定，布谷鸟攻击是定时单向触发，进行下次攻击时障碍的数据不一定因上次攻击而更新过，
-- 所以提前记录下攻击次数，不要打多了
-- 对于不能被清除的对象，攻击后需清除能量
-- 返回：攻击次数，攻击后是否清除能量，攻击后等候类型
function CuckooLogic:_getAttackTimes(item, mainLogic)
	if not item then return 0 end

	--------------- 覆盖物层 -------------
	local topCoverType = item:getTopCoverType()
	-- 有覆盖物
	if topCoverType then
		if topCoverType == GameItemDataTopCoverName.k_Leafpile then
			return item.blockerCoverLevel
		elseif topCoverType == GameItemDataTopCoverName.k_WaterBucket and WaterBucketLogic:canAttackBucket(item) then
			return 1
		-- elseif topCoverType == GameItemDataTopCoverName.k_SuperFurball then
		-- 	return 1
		else
			return 0
		end
	end

	--------------- 锁类层 ----------------
	if (item:hasFurball() and item.furballType == GameItemFurballType.kGrey) 
		or item.cageLevel > 0 
		or item.honeyLevel > 0 
		or item.beEffectByMimosa == GameItemType.kKindMimosa 
		then
		return 1
	elseif item:hasFurball() and item.furballType == GameItemFurballType.kBrown then
		return 1, false, CuckooBirdWalkStateBlockType.kBrownCuteBall	--棕毛球需要等到自己的state才会处理分裂，在此之前屏蔽布谷鸟行动检测（不然会白白消耗能量）

	--------------- 本体层 ---------------
	elseif item:isVisibleAndFree() then
		-- 愚公移山，无需 clearEnergy
		if item.ItemType == GameItemType.kVenom then
			return 1
		elseif item.ItemType == GameItemType.kSnow then
			return item.snowLevel
		elseif item.ItemType == GameItemType.kBottleBlocker then
			return item.bottleLevel
		elseif item.ItemType == GameItemType.kSunFlask then
			return item.sunFlaskLevel
		elseif item.ItemType == GameItemType.kGyro then
			return (2 - item.gyroLevel)
		elseif item.ItemType == GameItemType.kBlackCuteBall then
			return item.blackCuteStrength
		elseif item.ItemType == GameItemType.kBlocker199 and not item:isBlocker199Active() then
			return item.level
		elseif item.ItemType == GameItemType.kWindTunnelSwitch then
			return item.windTunnelSwitchLevel
		elseif item.ItemType == GameItemType.kMeow then
			return item.meowLevel

		-- 蚍蜉撼树，以下 clearEnergy 均为 true
		elseif item.ItemType == GameItemType.kKindMimosa 
			then
			return 1, true
		elseif item.ItemType == GameItemType.kRoost then
			return (4 - item.roostLevel), true	--最高4级
		elseif item.ItemType == GameItemType.kMagicStone and item:canMagicStoneBeActive() then
			return (TileMagicStoneConst.kMaxLevel - item.magicStoneLevel + 1), true
		elseif item.ItemType == GameItemType.kTurret and not item.turretLocked then
			return (2 - item.turretLevel), true
		elseif CanevineLogic:is_occupy(item) then
			local caneVineRootPos = CanevineLogic:get_canevine_root(item)
			if caneVineRootPos then
				local caneVineRoot = mainLogic:safeGetItemData(caneVineRootPos.r, caneVineRootPos.c)
				if caneVineRoot and caneVineRoot.canevine_data then
					return CanevineLogic:getHitNeededToLevelUp(caneVineRoot.canevine_data)
				end
			end
		elseif item.ItemType == GameItemType.kCattery or item.ItemType == GameItemType.kCatteryEmpty then
			local catteryRootPos = CatteryLogic:getCatteryRoot(item)
			if catteryRootPos then
				local catteryRootItem = mainLogic.gameItemMap[catteryRootPos.r][catteryRootPos.c]
				if catteryRootItem and catteryRootItem.canAttackCattery then
					return (CatteryState.kReadyToRoll - catteryRootItem.catteryState), true
				end
			end
		elseif item.ItemType == GameItemType.kFirework then
			return 1, false
		end
	end

	return 0
end

function CuckooLogic:removeBlockStateType(mainLogic, targetType)
	if mainLogic.skipCuckooStateType and mainLogic.skipCuckooStateType == targetType then
		mainLogic.skipCuckooStateType = 0
	end
end

function CuckooLogic:refreshGameItemDataAfterCuckooBirdWalk(mainLogic)
	local newColumnMap = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local oldItem = mainLogic.gameItemMap[r][c]
			if oldItem and (oldItem.tempRowShiftByHero ~= 0 or oldItem.tempColShiftByHero ~= 0) then
				local newRow = oldItem.y + oldItem.tempRowShiftByHero
				local newCol = oldItem.x + oldItem.tempColShiftByHero

				if not newColumnMap[newCol] then newColumnMap[newCol] = {} end
				local newItemData = oldItem:copy()	--不会copy faceBack，tempRowShiftByHero，tempColShiftByHero
				newItemData.faceBack = oldItem.faceBack
				newColumnMap[newCol][newRow] = newItemData
				-- printx(11, "~~~ Old Item, row, old", oldItem.ItemType, r, c)
				-- printx(11, "~~~ To row, old", newItemData.ItemType, newRow, newCol)
			end
		end
	end

	for col, colLists in pairs(newColumnMap) do
		for row, copiedItem in pairs(colLists) do
			if mainLogic.gameItemMap[row] and mainLogic.gameItemMap[row][col] then

				local currItem = mainLogic.gameItemMap[row][col]
				currItem:getAnimalLikeDataFrom(copiedItem)
				-- currItem.isNeedUpdate = true
				-- currItem.forceUpdate = true
				if currItem.ItemType == GameItemType.kCuckooBird then
					currItem.faceBack = copiedItem.faceBack
				end
				currItem.tempRowShiftByHero = 0
				currItem.tempColShiftByHero = 0
				-- printx(11, "~~~~~~~ Set Item, row, old", currItem.ItemType, row, col)

				currItem:addFallingLockByCuckoo()
				mainLogic:checkItemBlock(row, col) --临时锁掉落
				currItem.updateLaterByCuckooBird = true
			end
		end
	end

end

function CuckooLogic:refreshAllBlockStateAfterCuckooBirdWalk(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
			if targetItem then
				if targetItem.updateLaterByCuckooBird then
					-- printx(11, "!!!!!!!!!!!!!!!! updateLaterByCuckooBird", r, c)
					targetItem.updateLaterByCuckooBird = false
					targetItem:removeFallingLockByCuckoo()

					mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)

					if targetItem.ItemType == GameItemType.kCuckooBird then
						if mainLogic.boardView and mainLogic.boardView.baseMap and mainLogic.boardView.baseMap[r] then
							local itemView = mainLogic.boardView.baseMap[r][c]
							if itemView then
								itemView:playCuckooBirdBackToIdle()
							end
						end
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------------
function CuckooLogic:checkCuckooBirdHasReachedEndPos(mainLogic, cuckooBird)
	-- printx(11, "++++++++++++ CHECK, CuckooLogic:checkCuckooBirdHasReachedEndPos")
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end
	if not cuckooBird then cuckooBird = CuckooLogic:getCuckooOnBoard(mainLogic) end
	if not cuckooBird then return false end

	local boardData = mainLogic:safeGetBoardData(cuckooBird.y, cuckooBird.x)
	if boardData and boardData.isTravelRoadEnd then
		return true
	end
	return false
end

function CuckooLogic:onCuckooBirdReachClock(mainLogic)
	local cuckooBird = CuckooLogic:getCuckooOnBoard(mainLogic)
	local clock = CuckooLogic:getFinalBuildingOnBoard(mainLogic)
	if cuckooBird then
		cuckooBird.cuckooBirdReachedEnd = true

		mainLogic:tryDoOrderList(cuckooBird.y, cuckooBird.x, GameItemOrderType.kDestination, GameItemOrderType_Destination.kCuckoo)
		mainLogic:addScoreToTotal(cuckooBird.y, cuckooBird.x, GamePlayConfigScore.CuckooBirdReachEnd)
	end
end

function CuckooLogic:hasCuckooBirdReachedEnd()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end

	local cuckooBird = CuckooLogic:getCuckooOnBoard(mainLogic)
	if not cuckooBird then return false end

	if cuckooBird.cuckooBirdReachedEnd then
		return true
	else
		return false
	end
end

function CuckooLogic:useRealBonusAnimation()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.theCurMoves then return false end

	if BombItemLogic:getNumSpecialBomb(mainLogic) > 0 or mainLogic.theCurMoves > 0 then
		return true
	end
	return false
end

function CuckooLogic:playBonusAnimationEffect(animationLayer, useRealBonusAnimation, onAnimationFinished)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not animationLayer or animationLayer.isDisposed or not mainLogic then
		if onAnimationFinished then onAnimationFinished() end
		return
	end

	local function playBonusAnimation()
		if useRealBonusAnimation then
			if _G.dev_kxxxl_bonus then
				GamePlayMusicPlayer:playEffect(GameMusicType.kXXLBonusTime)
			else
				GamePlayMusicPlayer:playEffect(GameMusicType.kBonusTime)
			end
		end

    	local bonusEffect = CuckooLogic:buildBonusEffect(useRealBonusAnimation, onAnimationFinished)
		if animationLayer and not animationLayer.isDisposed and bonusEffect then
			animationLayer:addChild(bonusEffect)

			GamePlayMusicPlayer:playEffect(GameMusicType.kCuckooBonus)
		end
    end

	-- cuckoo bird part
	local cuckooBird = CuckooLogic:getCuckooOnBoard(mainLogic)
	local clock = CuckooLogic:getFinalBuildingOnBoard(mainLogic)
	if cuckooBird and clock then
		local cuckooBirdView = mainLogic.boardView:safeGetItemView(cuckooBird.y, cuckooBird.x)
		if cuckooBirdView then
			local cuckooSprite = cuckooBirdView:getGameItemSprite()
			if cuckooSprite and not cuckooSprite.isDisposed then
				local position = UsePropState:getItemPosition(
					IntCoord:create(clock.y, clock.x)
					)
				local arr = CCArray:create()
				arr:addObject(CCDelayTime:create(0.2))
				arr:addObject(CCCallFunc:create(function ( ... )
							GamePlayMusicPlayer:playEffect(GameMusicType.kCuckooWalk)
						end))
				arr:addObject(CCMoveTo:create(0.3, position))
				arr:addObject(CCCallFunc:create(function( ... )
					if cuckooSprite and not cuckooSprite.isDisposed then
						cuckooSprite:setVisible(false)
					end
				end))
				local move_action = CCSequence:create(arr) 
				cuckooSprite:runAction(move_action)

				local walkingDirection = CuckooLogic:getDirectionByShiftValue(clock.y - cuckooBird.y, clock.x - cuckooBird.x)
				if walkingDirection > 0 then
					if walkingDirection == 4 then
						cuckooBird.faceBack = true
					elseif walkingDirection == 2 then
						cuckooBird.faceBack = false
					end
					cuckooBirdView:playCuckooBirdWalk(walkingDirection, cuckooBird.faceBack)
				end
			end
		end

		local moveEndPos = ccp(5, 3)
		local moveDuration = 0.3
		local moveEndScale = 3
		-- 根据距离调整动画减少穿帮
		local distance = math.abs(clock.x - moveEndPos.x) + math.abs(clock.y - moveEndPos.y)
		-- printx(11, "------------- distance:", distance, clock.x, moveEndPos.x, clock.y, moveEndPos.y)
		if distance < 4 then
			moveDuration = 0.1
			moveEndScale = 2
		end

		local clockView = mainLogic.boardView:safeGetItemView(clock.y, clock.x)
		if clockView then
			local clockSprite = clockView:getGameItemSprite()
			if clockSprite and not clockSprite.isDisposed then
				local position2 = UsePropState:getItemPosition(
					IntCoord:create(moveEndPos.y, moveEndPos.x)
					)

				local arr2 = CCArray:create()
				arr2:addObject(CCDelayTime:create(0.5))
				arr2:addObject(CCSpawn:createWithTwoActions(
					CCMoveTo:create(moveDuration, position2), CCScaleTo:create(moveDuration, moveEndScale, moveEndScale))
				)
				arr2:addObject(CCCallFunc:create(function( ... )
					if clockSprite and not clockSprite.isDisposed then
						clockSprite:setVisible(false)
					end
					playBonusAnimation()
				end))
				local move_action2 = CCSequence:create(arr2) 
				clockSprite:runAction(move_action2)
			end
		end
	end

    -- setTimeOut(playBonusAnimation, 0.7)
end

function CuckooLogic:buildBonusEffect(useRealBonusAnimation, onAnimationFinished)
	local winSize = CCDirector:sharedDirector():getWinSize()
	local winOrigin = CCDirector:sharedDirector():getVisibleOrigin()

	local container = CocosObject.new(CCNode:create())
	local darkLayer = LayerColor:createWithColor(ccc3(0, 0, 0), winSize.width + ExpandDocker:getExtraWidth(), winSize.height)
	darkLayer:setOpacity(255 * 0.6)
	darkLayer:setPositionX(-ExpandDocker:getExtraWidth()/2)
	container:addChild(darkLayer)

	local animName
	if useRealBonusAnimation then
		animName = "cuckooBonusAnim/cuckooBonusAnim_withBonus"
	else
		animName = "cuckooBonusAnim/cuckooBonusAnim_noBonus"
	end
	local anim = UIHelper:createArmature3("skeleton/cuckooBonusAnim", 
				animName, animName, animName)
	anim:playByIndex(0)
	anim:update(0.001)
	anim:stop()

	local function finishCallback( ... )
	    if anim then
	    	anim:removeEventListener(ArmatureEvents.COMPLETE, finishCallback)
	    	if not anim.isDisposed then
	    		anim:removeFromParentAndCleanup(true)
	    	end
		end
	    if darkLayer and not darkLayer.isDisposed then
			darkLayer:removeFromParentAndCleanup(true)
		end
		if container and not container.isDisposed then
			container:removeFromParentAndCleanup(true)
		end
     	if onAnimationFinished then onAnimationFinished() end
	end
	anim:addEventListener(ArmatureEvents.COMPLETE, finishCallback)
	anim:playByIndex(0)
	anim:setPositionXY(winOrigin.x+winSize.width/2, winOrigin.y+winSize.height/2)
	container:addChild(anim)

	return container
end

function CuckooLogic:getFinalBuildingOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item.ItemType == GameItemType.kCuckooClock then
				return item
			end
		end
	end
	return nil
end

function CuckooLogic:getCustomizedFuuuDatas(mainLogic)
	local fuuuTypeSuffix = "cuckoo"
	local currVal = mainLogic.currMapTravelStep or 0
	local totalVal = mainLogic.currMapTravelRouteLength or 1
	local fuuuResult = false
	if mainLogic.currMapTravelStep and mainLogic.currMapTravelRouteLength then
		local stepToFinish = mainLogic.currMapTravelRouteLength - mainLogic.currMapTravelStep
		if stepToFinish <= 2 then
			fuuuResult = true
		end
	end
	return fuuuTypeSuffix, currVal, totalVal, fuuuResult, GameItemOrderType_Destination.kCuckoo
end
