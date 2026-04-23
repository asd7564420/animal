TravelLogic = class{}

TravelInteractType =
{
	kNone = 0,
	kWalk = 1,
	kAttackBlocker = 2,
	kAttackChain = 3,
	kEventBox = 4,
}

TravelRouteEventType = 
{
	kAddEnergyBag = 1,
	kBombRoute = 2,
	kBombHeart = 3,
}
TravelRouteEventTypeAmount = 3

-- 前进检测因等待一些障碍的处理(state)而暂时被屏蔽
TravelWalkStateBlockType = 
{
	kBrownCuteBall = 1
}

---------------------------------- Data ---------------------------------
-- 旅行模式相关信息
function TravelLogic:getTravelData(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local travelData
	-- printx(11, "xmas2019Data", mainLogic.PlayUIDelegate.xmas2019Data)
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.xmas2019Data then
		travelData = mainLogic.PlayUIDelegate.xmas2019Data 
	end

	return travelData
end

function TravelLogic:travelEventBoxActive(mainLogic)
	-- printx(11, "===== TravelLogic:travelEventBoxActive ?", debug.traceback())
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end

	local currTravelMapIndex = mainLogic.currTravelMapIndex
	local travelData = TravelLogic:getTravelData(mainLogic)
	-- printx(11, "===== 111", currTravelMapIndex, table.tostring(travelData))
	if travelData and travelData.eventBoxIndex and currTravelMapIndex then
		if travelData.eventBoxIndex == currTravelMapIndex then
			return true
		end
	end
	return false
end

------------------------------- Route ------------------------------------
function TravelLogic:initTravelRouteData(mainLogic, config)
	local tileMap = config.travelRouteRawData
	-- printx(11, "initTravelRouteData, tileMap", table.tostring(tileMap))
	if not tileMap then return end
	if not mainLogic or not mainLogic.boardmap then return end
	
	for r = 1, #tileMap do 
		if tileMap[r] then
			for c = 1, #tileMap[r] do
				local tileDef = tileMap[r][c]
				if tileDef then
					TravelLogic:_initTravelRoadTypeByConfig(mainLogic, r, c, tileDef)
				end
			end
		end
	end

	local travelRouteLength = 0
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]

			if TravelLogic:_gridHasTravelRoad(board) and not TravelLogic:_gridHasPrevTravelRoad(board) then
				board.isTravelRoadStart = true
			end

			if not TravelLogic:_gridHasTravelRoad(board) and TravelLogic:_gridHasPrevTravelRoad(board) then
				board.isTravelRoadEnd = true
			end

			if TravelLogic:_gridHasTravelRoad(board) then
				travelRouteLength = travelRouteLength + 1
			end

			-- 旅行模式第一屏初始化时因为读不到配置这里无效，需用下面的 scanAndMakeTravelEventBox，后面几屏有效
			if board.isTravelEventTile and TravelLogic:travelEventBoxActive(mainLogic) then
				if mainLogic.gameItemMap[r] and mainLogic.gameItemMap[r][c] then
					local item = mainLogic.gameItemMap[r][c]
					item:changeToTravelEventBox()
				end
			end
		end
	end
	mainLogic.currMapTravelRouteLength = travelRouteLength
end

function TravelLogic:scanAndMakeTravelEventBox(mainLogic)
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]
			if board.isTravelEventTile and TravelLogic:travelEventBoxActive(mainLogic) then
				if mainLogic.gameItemMap[r] and mainLogic.gameItemMap[r][c] then
					local item = mainLogic.gameItemMap[r][c]
					item:changeToTravelEventBox()
				end
			end
		end
	end
end

function TravelLogic:_initTravelRoadTypeByConfig(mainLogic, r, c, tileDef)
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

function TravelLogic:_gridHasTravelRoad(boardData)
	if boardData and boardData.travelRoadType and boardData.travelRoadType > 0 then
    	return true
    end
    return false
end

function TravelLogic:_gridHasPrevTravelRoad(boardData)
	if boardData and boardData.prevTravelRoadType and boardData.prevTravelRoadType > 0 then
    	return true
    end
    return false
end

function TravelLogic:getNextGridPositionByDirection(currR, currC)
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

function TravelLogic:convertRoadTypeToAssetDir(roadType)
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
function TravelLogic:getFinalBuildingDirection(roadEndR, roadEndC)
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
		if itemData and itemData.ItemType == GameItemType.kTravelFinishBuilding then
			buildingDir = dir
			break
		end
	end
	return buildingDir
end

function TravelLogic:posHasFinalBuildingAndRoadDir(posR, posC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local itemData = mainLogic:safeGetItemData(posR, posC)
	if itemData and itemData.ItemType == GameItemType.kTravelFinishBuilding then
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
function TravelLogic:onEnergyBagDemolished(targetBag)
	-- printx(11, "--------------- onEnergyBagDemolished -----------------------", targetBag.y, targetBag.x, debug.traceback())
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end
	TravelLogic:addTravelEnergy(mainLogic)

	local row = targetBag.y
	local col = targetBag.x

	local hero = TravelLogic:getHeroOnBoard(mainLogic)
	if hero then
		local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_Travel_Absorb_Energy_Bag, 
	        IntCoord:create(col, row),
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
		action.travelHero = hero

		local energyBagView = mainLogic.boardView.baseMap[row][col]
		local fromPos = energyBagView:getBasePosition(col, row)
		action.fromPos = fromPos

		local bagColor = targetBag._encrypt.ItemColorType
		local colourIndex = AnimalTypeConfig.convertColorTypeToIndex(bagColor)
		action.bagColour = colourIndex

	    mainLogic:addDestroyAction(action)
		mainLogic:setNeedCheckFalling()
	end
end

function TravelLogic:addTravelEnergy(mainLogic)
	if not mainLogic.travelEnergy then mainLogic.travelEnergy = 0 end
	mainLogic.travelEnergy = mainLogic.travelEnergy + 1
	-- printx(11, "~~~~~ addTravelEnergy ~~~~~, curr:", mainLogic.travelEnergy)
end

function TravelLogic:consumeTravelEnergy()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	if mainLogic.travelEnergy and mainLogic.travelEnergy > 0 then
		mainLogic.travelEnergy = math.max(0, mainLogic.travelEnergy - 1)
		-- printx(11, "~~~~~ consumeTravelEnergy ~~~~~, curr:", mainLogic.travelEnergy)
	end
end

function TravelLogic:clearTravelEnergy()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	mainLogic.travelEnergy = 0
	-- printx(11, "~~~~~ clearTravelEnergy ~~~~~")
end

------------------------------ Hero ----------------------------------
function TravelLogic:getHeroOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kTravelHero then
            	return item
            end
		end
	end
	return nil
end

function TravelLogic:getDirectionByShiftValue(shiftR, shiftC)
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

function TravelLogic:checkNextGridInteractType(hero)
	-- printx(11, "^^^ checkNextGridInteractType", hero.y, hero.x)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return TravelInteractType.kNone end

	local hasNextGrid, nextR, nextC = TravelLogic:getNextGridPositionByDirection(hero.y, hero.x)
	-- printx(11, "^^^ ^^^ hasNextGrid, nextR, nextC", hasNextGrid, nextR, nextC)
	if not hasNextGrid or not mainLogic:isPosValid(nextR, nextC) then 
		return TravelInteractType.kNone 
	end

	local nextItemData = mainLogic:safeGetItemData(nextR, nextC)
	local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
	if not nextItemData or not nextBoardData then return TravelInteractType.kNone end

	local chainLevel = self:_getMaxChainLevelInWalkingDirection(mainLogic, hero.y, hero.x, nextR, nextC)
	-- printx(11, "chainLevel between", hero.y, hero.x, nextR, nextC, chainLevel)
	if chainLevel > 0 then
		-- printx(11, "^^^ ^^^ ATTACK chain!", chainLevel)
		return TravelInteractType.kAttackChain, nextItemData, chainLevel
	end

	-- printx(11, "^^^ ^^^ check action type..")
	if nextItemData.ItemType == GameItemType.kTravelEventBox and not mainLogic.travelEventBoxOpened then
		-- printx(11, "^^^ ^^^ Open Event Box!")
		return TravelInteractType.kEventBox, nextItemData
	elseif TravelLogic:_isExchangeableItemForHero(mainLogic, nextItemData) then
		-- printx(11, "^^^ ^^^ WALK!")
		return TravelInteractType.kWalk, nextItemData
	else
		local attackTimes, blockType = TravelLogic:_getAttackTimes(nextItemData)
		-- printx(11, "attackTimes:", attackTimes)
		if attackTimes and attackTimes > 0 then
			-- printx(11, "^^^ ^^^ ATTACK!")
			return TravelInteractType.kAttackBlocker, nextItemData, attackTimes, blockType
		else
			-- printx(11, "^^^ ^^^ NAH")
			return TravelInteractType.kNone
		end
	end
end

function TravelLogic:_getMaxChainLevelInWalkingDirection(mainLogic, currR, currC, nextR, nextC)
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

-- 先借用一下幽灵的
TravelHeroExchangableItems = table.const{
	GameItemType.kBlocker195, GameItemType.kCrystalStone, GameItemType.kTotems, GameItemType.kMissile, GameItemType.kBlocker199, 
	GameItemType.kGift, GameItemType.kNewGift,GameItemType.kShellGift, GameItemType.kMagicLamp, GameItemType.kPacman, GameItemType.kPuffer, 
	GameItemType.kBlocker207, GameItemType.kBalloon, GameItemType.kBuffBoom, GameItemType.kScoreBuffBottle, GameItemType.kFirecracker,
	GameItemType.kAnimal, GameItemType.kHoneyBottle, GameItemType.kWanSheng, GameItemType.kIngredient, GameItemType.kCoin, 
	GameItemType.kChameleon, GameItemType.kCrystal, GameItemType.kAnimal, GameItemType.kWater, GameItemType.kTravelEnergyBag,GameItemType.kAddMove
}

function TravelLogic:_isExchangeableItemForHero(mainLogic, item)
	if item and item.isUsed and item:isVisibleAndFree() then
		local index = table.indexOf(TravelHeroExchangableItems, item.ItemType)
		if (index and index > 0) or item.isEmpty then
			if item.ItemType == GameItemType.kBlocker199 then
				if item:isBlocker199Active() then return true else return false end
			elseif item.ItemType == GameItemType.kTotems then
				if not item:isActiveTotems() then return true else return false end
			else
				return true
			end
		end
	end
	return false
end

-- 由于每种障碍处理时间长度不定，主人公攻击是定时单向触发，进行下次攻击时障碍的数据不一定因上次攻击而更新过，
-- 所以提前记录下攻击次数，不要打多了
function TravelLogic:_getAttackTimes(item)
	if not item then return 0 end

	if (item:hasFurball() and item.furballType == GameItemFurballType.kGrey) or item.cageLevel > 0 or item.honeyLevel > 0 then
		return 1
	elseif item:hasFurball() and item.furballType == GameItemFurballType.kBrown then
		return 1, TravelWalkStateBlockType.kBrownCuteBall	--棕毛球需要等到自己的state才会处理分裂，在此之前屏蔽主人公行动检测（不然会白白消耗能量）
	elseif item.blockerCoverLevel > 0 then
		return item.blockerCoverLevel
	elseif item.ItemType == GameItemType.kSnow then
		return item.snowLevel
	elseif item.ItemType == GameItemType.kBottleBlocker then
		return item.bottleLevel
	elseif item.ItemType == GameItemType.kSunFlask then
		return item.sunFlaskLevel
	elseif item.ItemType == GameItemType.kGyro then
		return (2 - item.gyroLevel)
	elseif item.ItemType == GameItemType.kVenom then
		return 1
	end
	return 0
end

function TravelLogic:removeBlockStateType(mainLogic, targetType)
	if mainLogic.skipTravelStateType and mainLogic.skipTravelStateType == targetType then
		mainLogic.skipTravelStateType = 0
	end
end

function TravelLogic:refreshGameItemDataAfterHeroWalk(mainLogic)
	local newColumnMap = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local oldItem = mainLogic.gameItemMap[r][c]
		    if oldItem and (oldItem.tempRowShiftByHero ~= 0 or oldItem.tempColShiftByHero ~= 0) then
		    	local newRow = oldItem.y + oldItem.tempRowShiftByHero
		    	local newCol = oldItem.x + oldItem.tempColShiftByHero

		    	if not newColumnMap[newCol] then newColumnMap[newCol] = {} end
		    	local newItemData = oldItem:copy()	--不会copy walkingDirection，tempRowShiftByHero，tempColShiftByHero
		    	newItemData.walkingDirection = oldItem.walkingDirection
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
				if currItem.ItemType == GameItemType.kTravelHero then
					currItem.walkingDirection = copiedItem.walkingDirection
				elseif currItem.ItemType == GameItemType.kTravelEventBox then
					currItem:cleanAnimalLikeData()
                	currItem.isNeedUpdate = true
                	currItem.skipRemoveFallingLock = true
				end
				currItem.tempRowShiftByHero = 0
				currItem.tempColShiftByHero = 0

				-- printx(11, "~~~~~~~ Set Item, row, old", currItem.ItemType, row, col)

				currItem:addFallingLockByTravelHero()
				mainLogic:checkItemBlock(row, col) --临时锁掉落
				currItem.updateLaterByTravelHero = true

				-- if col == 5 and row == 4 then --test
				-- 	local targetItemData = mainLogic.gameItemMap[row][col]
				-- 	-- printx(11, "Item Data : ("..col..","..row..") ", table.tostringByKeyOrder(targetItemData))
				-- 	watchObj(targetItemData, {"ItemType"})
				-- end
			end
		end
	end

end

function TravelLogic:refreshAllBlockStateAfterHeroWalk(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
		    if targetItem then
		    	if targetItem.updateLaterByTravelHero then
		    		-- printx(11, "!!!!!!!!!!!!!!!! updateLaterByTravelHero", r, c)
		    		targetItem.updateLaterByTravelHero = false
		    		if not targetItem.skipRemoveFallingLock then
		    			targetItem:removeFallingLockByTravelHero()
		    		end

			    	mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)

					if targetItem.ItemType == GameItemType.kTravelHero then
						targetItem.walkingDirection = nil

						if mainLogic.boardView and mainLogic.boardView.baseMap and mainLogic.boardView.baseMap[r] then
							local itemView = mainLogic.boardView.baseMap[r][c]
							if itemView then
								itemView:playTravelHeroBackToIdle()
							end
						end
					end
		    	end
		    end
		end
	end
end

----------------------------------- Route Event -------------------------------------
-- 将来也许会有权重……
function TravelLogic:getRouteEventTypeOnTrigger(mainLogic)
	local travelData = TravelLogic:getTravelData(mainLogic)
	if travelData and travelData.hasSkill then
		local typeIndex = mainLogic.randFactory:rand(1, TravelRouteEventTypeAmount)
		-- printx(11, "Rand event type:", typeIndex)
		return typeIndex
	end
	return 0
end

function TravelLogic:getAddEnergyBagTargetGrids(mainLogic, addAmount)
	if not addAmount then addAmount = 7 end

	local candidateTargets = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
		    if targetItem 
		    	and targetItem.ItemType == GameItemType.kAnimal 
		    	and targetItem.ItemSpecialType == 0 
		    	and targetItem:isVisibleAndFree()
		    	then
		    	table.insert(candidateTargets, targetItem)
		    end
		end
	end

	local pickedTargetGrids = {}
	local pickAmount = math.min(#candidateTargets, addAmount)
	if pickAmount > 0 then
		if pickAmount < #candidateTargets then 
			candidateTargets = table.randomOrder(candidateTargets, mainLogic)
		end
		for i = 1, pickAmount do
			local candidateItem = candidateTargets[i]
			local targetGrid = IntCoord:create(candidateItem.x, candidateItem.y)
			table.insert(pickedTargetGrids, targetGrid)
		end
	end

	return pickedTargetGrids
end

function TravelLogic:transformAnimalToEnergyBag(targetItem)
	if targetItem then
		targetItem.ItemType = GameItemType.kTravelEnergyBag
		targetItem.isNeedUpdate = true
	end
end

function TravelLogic:getRouteGrids(mainLogic)
	local pickedTargetGrids = {}

	local startGrid = self:_getStartGridOfRoute(mainLogic)
	local startGridPos = IntCoord:create(startGrid.x, startGrid.y)
	table.insert(pickedTargetGrids, startGridPos)

	local currGrid = startGrid
	while (currGrid and TravelLogic:_gridHasTravelRoad(currGrid)) do
		local nextGrid
		local hasNextGrid, nextR, nextC = TravelLogic:getNextGridPositionByDirection(currGrid.y, currGrid.x)
		if hasNextGrid and mainLogic:isPosValid(nextR, nextC) then
			nextGrid = mainLogic:safeGetBoardData(nextR, nextC)
			if nextGrid then
				local targetGrid = IntCoord:create(nextGrid.x, nextGrid.y)
				table.insert(pickedTargetGrids, targetGrid)
			end
		end
		currGrid = nextGrid
	end

	return pickedTargetGrids
end

function TravelLogic:_getStartGridOfRoute(mainLogic)
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]
			if TravelLogic:_gridHasTravelRoad(board) and not TravelLogic:_gridHasPrevTravelRoad(board) then
				return board
			end
		end
	end
	return nil
end

function TravelLogic:getHeartGridsToBomb(mainLogic, eventGrid)
	local targetGrids = {}

	local heartShapeShifts = {
		{r = -1, c = -1},
		{r = -1, c = 1},
		{r = 0, c = -2},
		{r = 0, c = -1},
		{r = 0, c = 0},
		{r = 0, c = 1},
		{r = 0, c = 2},
		{r = 1, c = -1},
		{r = 1, c = 0},
		{r = 1, c = 1},
		{r = 2, c = 0},
	}

	for _, gridShiftSet in pairs(heartShapeShifts) do
		local currR = eventGrid.r + gridShiftSet.r
		local currC = eventGrid.c + gridShiftSet.c
		if mainLogic:isPosValid(currR, currC) then
			table.insert(targetGrids, IntCoord:create(currC, currR))
		end
	end

	return targetGrids
end

function TravelLogic:playHeartBombHugeAnimation(middileGrid)
	local mainLogic = GameBoardLogic:getCurrentLogic()
 	if not middileGrid or not mainLogic then return end
 	local middlePos = mainLogic:getGameItemPosInView(middileGrid.r, middileGrid.c)
    TravelLogic:playSingleAnimationOnGrid(middlePos, "travelBombHeartEffect")
end

function TravelLogic:playSingleAnimationOnGrid(middlePos, animationName)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene or not middlePos then return end

    local container = Layer:create()
    container:setTouchEnabled(true, 0, true)
    scene:addChild(container)
    
    local anim = gAnimatedObject:createWithFilename('flash/Xmas2019/gaf/'..animationName..'.gaf')
    local animPos = ccp(middlePos.x, middlePos.y)
    anim:setPosition(animPos)

    local function finishCallback( ... )
        if container then
            container:removeFromParentAndCleanup(true)
            container = nil
        end
    end

    anim:setSequenceDelegate('start', finishCallback, true)
    anim:playSequence("start", false, true, ASSH_RESTART)
    anim:start()

    container:addChild(anim)
end

------------------------------ 礼盒的一堆动画 >皿< ---------------------------
function TravelLogic:playEventBoxOpenAnimations(boardView, actionData)
	if not actionData or not boardView then return end
	local mainLogic = boardView.gameBoardLogic
	if not mainLogic then return end

	local displayIcons = {}
	local contentAmount = actionData.contentAmount
	local currContentIndex = 1

	local startPos = mainLogic:getGameItemPosInView(actionData.hero.y, actionData.hero.x)

	if actionData.activityScore and actionData.activityScore > 0 then
		local scoreIcon = TravelLogic:_getBoxDisplayIconSet(true, nil, nil, actionData.activityScore)
		-- local scoreEndPos = ActCollectionLogic:getTargetPosByIndex(5, 1) --5:Common_collectProgress.panelTypes.kXmas2019
		TravelLogic:_playFlyOutAndBackAnimation(scoreIcon, startPos, scoreEndPos, contentAmount, currContentIndex, mainLogic, false, false, true, actionData.activityScore)

		currContentIndex = currContentIndex + 1
	end

	if actionData.accessoryID and actionData.accessoryID > 0 then
		local accessoryIcon = TravelLogic:_getBoxDisplayIconSet(false, actionData.accessoryID, nil, 1)
		-- local accessoryEndPos = ActCollectionLogic:getTargetPosByIndex(5, 2) --5:Common_collectProgress.panelTypes.kXmas2019
		TravelLogic:_playFlyOutAndBackAnimation(accessoryIcon, startPos, accessoryEndPos, contentAmount, currContentIndex, mainLogic, false, false, false, 1)

		currContentIndex = currContentIndex + 1
	end

	if actionData.eventType and actionData.eventType > 0 then
		if actionData.eventType == 1 then
			if actionData.targetGrids then
				local needShowBGLight = true
				for _, targetGrid in pairs(actionData.targetGrids) do
					local singleEndPos = mainLogic:getGameItemPosInView(targetGrid.y, targetGrid.x)
					TravelLogic:_formSkillIconFlyAnimations(actionData.eventType, startPos, singleEndPos, contentAmount, currContentIndex, mainLogic, not needShowBGLight)
					needShowBGLight = false
				end
			end
		elseif actionData.eventType == 2 then
			local bombStartPos
			if actionData.targetGrids and #actionData.targetGrids > 0 then
				local bombStartGrid = actionData.targetGrids[1]
				if bombStartGrid then
					bombStartPos = mainLogic:getGameItemPosInView(bombStartGrid.y, bombStartGrid.x)
				end
			end
			if not bombStartPos then bombStartPos = startPos end
			TravelLogic:_formSkillIconFlyAnimations(actionData.eventType, startPos, bombStartPos, contentAmount, currContentIndex, mainLogic)

		elseif actionData.eventType == 3 then
			TravelLogic:_formSkillIconFlyAnimations(actionData.eventType, startPos, startPos, contentAmount, currContentIndex, mainLogic)
		end
	end
end

function TravelLogic:_formSkillIconFlyAnimations(eventType, startPos, endPos, contentAmount, contentIndex, mainLogic, noBG)
	local skillIcon = TravelLogic:_getBoxDisplayIconSet(false, nil, eventType, 0, noBG)
	TravelLogic:_playFlyOutAndBackAnimation(skillIcon, startPos, endPos, contentAmount, contentIndex, mainLogic, true, noBG)
end

function TravelLogic:_getBoxDisplayIconSet(isScore, accessoryID, eventType, value, noBG)
	local iconSet = Sprite:createEmpty()

	if not noBG then
		local bgAnim = gAnimatedObject:createWithFilename('flash/Xmas2019/gaf/travelEventBoxIconDisplayEffect.gaf')
		bgAnim:setLooped(true)
		bgAnim:start()
		iconSet:addChild(bgAnim)
		iconSet.bgAnim = bgAnim
	end

	if eventType and eventType > 0 then
		local skillPrefix = "skillIcon/blocker_travel_skill_icon_"..eventType
		local skillIcon = Sprite:createWithSpriteFrameName(skillPrefix.."_0000")
		if eventType ~= 1 then
			local frames = SpriteUtil:buildFrames(skillPrefix.."_%04d", 0, 6)
			local animation = SpriteUtil:buildAnimate(frames, 1/30)
			skillIcon:play(animation, 0, 0)
		end
		iconSet:addChild(skillIcon)
		skillIcon:setPosition(ccp(22, 10))

	elseif value > 0 then
		if isScore then
			local scoreAsset = "XMasItem/00.png"
			-- local scoreIcon = Sprite:createWithSpriteFrameName(scoreAsset)
			local scoreIcon = UIHelper:createSpriteWithPlist("tempFunctionResInLevel/Xmas2019/item/XMas2019Item.plist", scoreAsset)
			if scoreIcon then
				iconSet:addChild(scoreIcon)
			end

			local scoreNum = BitmapText:create("x"..value, 'fnt/countdown_bright.fnt')
			scoreNum:setAnchorPoint(ccp(1,1))
			scoreNum:setScale(0.8)
			iconSet:addChild(scoreNum)
			scoreNum:setPosition(ccp(85, -15))

		elseif accessoryID and accessoryID > 0 then
			local accessoryAsset = "XMasItem/"..accessoryID..".png"
			-- local accessoryIcon = Sprite:createWithSpriteFrameName(accessoryAsset)
			local accessoryIcon = UIHelper:createSpriteWithPlist("tempFunctionResInLevel/Xmas2019/item/XMas2019Item.plist", accessoryAsset)
			if accessoryIcon then
				iconSet:addChild(accessoryIcon)

				local accessoryNum = BitmapText:create("x"..value, 'fnt/countdown_bright.fnt')
				accessoryNum:setAnchorPoint(ccp(1,1))
				accessoryNum:setScale(0.8)
				iconSet:addChild(accessoryNum)
				accessoryNum:setPosition(ccp(85, -15))
			end
		end
	end

	return iconSet
end

function TravelLogic:_playFlyOutAndBackAnimation(iconSprite, startPos, endPos, contentAmount, contentIndex, mainLogic, isSkill, noBG, isScore, newValue)
	local scene = Director:sharedDirector():getRunningScene()
	if not scene or not iconSprite then return end

    local function onAnimationFinished()
		if iconSprite then iconSprite:removeFromParentAndCleanup(true) end
		-- if finishCallback then finishCallback() end
    end

    iconSprite:setPosition(startPos)
    iconSprite:setScale(0.1)

    local wSize = Director:sharedDirector():getWinSize()
    local pieceWidth = wSize.width / (contentAmount + 1)
    local selfX = pieceWidth * contentIndex
    local selfPos = ccp(selfX, wSize.height / 2)

    local flyDuration = 0.4
    local endIconScale = 0.3
	iconSprite:runAction(UIHelper:sequence{
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, selfPos), CCScaleTo:create(flyDuration, 1, 1))),
		CCDelayTime:create(1),
		CCCallFunc:create(function ( ... )
			if iconSprite and not iconSprite.isDisposed and iconSprite.bgAnim and not iconSprite.bgAnim.isDisposed then
				iconSprite.bgAnim:removeFromParentAndCleanup(true)
			end
			if isSkill and not noBG then
				TravelLogic:playSingleAnimationOnGrid(selfPos, "travelStartBurstEffect")
			end
		end),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(endPos.x, endPos.y)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if iconSprite and not iconSprite.isDisposed then
				iconSprite:removeFromParentAndCleanup(true)
				if isSkill then
					TravelLogic:playSingleAnimationOnGrid(endPos, "travelSkillHitEffect")
				else
					local targetIndex = 1
					if not isScore then targetIndex = 2 end
					-- ActCollectionLogic:updateTargetNumberByIndex(5, targetIndex, newValue, true) --5:Common_collectProgress.panelTypes.kXmas2019
				end
			end
		end),
	})

    scene:addChild(iconSprite)
end

----------------------------- Add Step Skill ---------------------------
function TravelLogic:triggerTravelAddStepSkill()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	local throwGrids = TravelLogic:getAddEnergyBagTargetGrids(mainLogic, 10)
	if throwGrids and #throwGrids > 0 then
		local addStepSkillAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kItem_Travel_Add_Step_Skill,
        nil,
        nil,
        GamePlayConfig_MaxAction_time)
		addStepSkillAction.targetGrids = throwGrids

	    mainLogic:addDestroyAction(addStepSkillAction)
	    mainLogic:setNeedCheckFalling()
	    return true
	end

	return false
end

function TravelLogic:playTravelAddStepSkillAnimations(boardView, targetGrids)
	if not targetGrids or not boardView then return end
	local mainLogic = boardView.gameBoardLogic
	if not mainLogic then return end

	if targetGrids and #targetGrids > 0 then
		local needShowBGLight = true
		for _, targetGrid in pairs(targetGrids) do
			local singleEndPos = mainLogic:getGameItemPosInView(targetGrid.y, targetGrid.x)
			TravelLogic:_fromAddStepSkillIconFlyAnimation(singleEndPos, mainLogic, not needShowBGLight)
			needShowBGLight = false
		end
	end
end

function TravelLogic:_fromAddStepSkillIconFlyAnimation(endPos, mainLogic, noBG)
	local iconSprite = TravelLogic:_getBoxDisplayIconSet(false, nil, 1, 0, noBG)
	local scene = Director:sharedDirector():getRunningScene()
	if not scene or not iconSprite then return end

    local function onAnimationFinished()
		if iconSprite then iconSprite:removeFromParentAndCleanup(true) end
    end

    local wSize = Director:sharedDirector():getWinSize()
    local selfPos = ccp(wSize.width / 2, wSize.height / 2)
    iconSprite:setPosition(selfPos)

    local flyDuration = 0.4
    local endIconScale = 0.3
	iconSprite:runAction(UIHelper:sequence{
		CCDelayTime:create(1),
		CCCallFunc:create(function ( ... )
			if iconSprite and not iconSprite.isDisposed and iconSprite.bgAnim and not iconSprite.bgAnim.isDisposed then
				iconSprite.bgAnim:removeFromParentAndCleanup(true)
			end
			if not noBG then
				TravelLogic:playSingleAnimationOnGrid(selfPos, "travelStartBurstEffect")
			end
		end),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(endPos.x, endPos.y)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if iconSprite and not iconSprite.isDisposed then
				iconSprite:removeFromParentAndCleanup(true)
				TravelLogic:playSingleAnimationOnGrid(endPos, "travelSkillHitEffect")
			end
		end),
	})

    scene:addChild(iconSprite)
end

----------------------------------------------------------------------------
function TravelLogic:getNextMapLevelID(mainLogic)
	if not mainLogic then return nil end
	local travelData = TravelLogic:getTravelData(mainLogic)
	if travelData and travelData.levelList then
		local currMapIndex = mainLogic.currTravelMapIndex
		if currMapIndex and currMapIndex > 0 then
			if currMapIndex < #travelData.levelList then
				local nextLevelID = travelData.levelList[currMapIndex + 1]
				return nextLevelID
			end
		end
	end
	return nil
end

----------------------------------------------------------------------------
function TravelLogic:heroHasReachedEnd(mainLogic, hero, firstTimeCheck)
	-- printx(11, "++++++++++++ CHECK, TravelLogic:heroHasReachedEnd")
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
    if not hero then
        hero = TravelLogic:getHeroOnBoard(mainLogic)
    end
    if not mainLogic or not hero then return false end

    -- printx(11, "travelHeroReachEndActivated", hero.travelHeroReachEndActivated)
    local statusAllowed = true
    if firstTimeCheck and hero.travelHeroReachEndActivated then
    	statusAllowed = false
    end

    if statusAllowed then
        local boardData = mainLogic:safeGetBoardData(hero.y, hero.x)
        if boardData and boardData.isTravelRoadEnd then
        	return true
        end
    end
    return false
end

function TravelLogic:onHeroReachFinalBuilding(mainLogic)
	local hero = TravelLogic:getHeroOnBoard(mainLogic)
	local finalBuilding = TravelLogic:getFinalBuildingOnBoard(mainLogic)
	if hero then
		hero.travelHeroReachEndActivated = true
	end

	if hero and finalBuilding then
		local heroGrid = ccp(hero.x, hero.y)
		local finalBuildingGrid = ccp(finalBuilding.x, finalBuilding.y)

		local action = GameBoardActionDataSet:createAs(
	            GameActionTargetType.kGameItemAction,
	            GameItemActionType.kItem_Travel_Hero_Reach_End, 
	            nil,
	            nil,
	            GamePlayConfig_MaxAction_time
	            )
	    action.heroGrid = heroGrid
	    action.finalBuildingGrid = finalBuildingGrid
	    action.isFinalMap = TravelLogic:isFinalMap(mainLogic)
	    -- action.completeCallback = actionCallback
	    mainLogic:addGlobalCoreAction(action)
	end

	local usedSteps = 0
	if mainLogic.travelMapInitUsedMove and mainLogic.realCostMove then
		usedSteps = math.max(mainLogic.realCostMove - mainLogic.travelMapInitUsedMove, 0)
	end
	TravelLogic:formAndSendLevelDC("map_end", mainLogic.level, usedSteps)
end

function TravelLogic:formAndSendLevelDC(subCategory, levelID, t3)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	local travelData = TravelLogic:getTravelData()
	if travelData and levelID then
		local coverLevelID = travelData.coverLevelID
		local currLevelID = levelID
		DcUtil:dcTravelXmas19(subCategory, coverLevelID, currLevelID, t3)
	end
end

function TravelLogic:getFinalBuildingOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kTravelFinishBuilding then
            	return item
            end
		end
	end
	return nil
end

function TravelLogic:isFinalMap(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end

	if mainLogic.currTravelMapIndex == 3 then
		return true
	end
	return false
end

function TravelLogic:travelReachedDestination(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end

	if mainLogic.travelHeroReachedEndFlag then
		return true
	end
	-- if TravelLogic:heroHasReachedEnd(mainLogic, nil, false) and TravelLogic:isFinalMap(mainLogic) then
	-- 	return true
	-- end
	return false
end

function TravelLogic:playHeroDebutAnimation(mainLogic)
	if not mainLogic then return end

	local hero = TravelLogic:getHeroOnBoard(mainLogic)
	if mainLogic.boardView and mainLogic.boardView.baseMap[hero.y] then
		local itemView = mainLogic.boardView.baseMap[hero.y][hero.x]
		itemView:playTravelHeroAppear()
	end
end

--------------------------- Difficulty Adjust Sys -------------------------------
function TravelLogic:getCurrDiffAdjustLevel(travelData)
	-- 初始化时gameboardLogic与playSceneUI还没建立联系，无法取到活动数据，故需传入
	-- printx(11, "TravelLogic:getCurrDiffAdjustLevel   travelData:", table.tostring(travelData))
	if not travelData then return 0 end

	local adjustLevel = 0
    if  travelData.expectDiff and travelData.expectDiff > 0 then
    	local failCounts = travelData.failCounts
    	if not failCounts or not type(failCounts) == "number" then
    		failCounts = 0
    	end

    	local valueGap = failCounts - (travelData.expectDiff - 1)
    	adjustLevel = CalculationUtil:mathBetween(valueGap, 0, 5)
    end

    return adjustLevel
end

---------------------------------------------------------------------------------
function TravelLogic:updateBGPosition(gamePlayScene)
	if not gamePlayScene or not gamePlayScene.gameBgNode or not gamePlayScene.gameBoardView then return end

	local gameBg = gamePlayScene.gameBgNode
	local gameBoardView = gamePlayScene.gameBoardView
	local posY = (10 - gameBoardView.startRowIndex) * 70
	local gPos = gameBoardView:convertToWorldSpace(ccp(0, posY))

    local topSpritePosY = gameBg:convertToNodeSpace(ccp(0, gPos.y)).y
    if gameBg.upBg then
    	gameBg.upBg:setPositionY(topSpritePosY - 195)
    end
end
