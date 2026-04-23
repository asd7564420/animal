CatteryLogic = class{}

CatteryState = {
	kTwoLevel = 1,
	kOneLevel = 2,
	kReadyToRoll = 3,
	kRolling = 4,
	kSplit = 5,
}

function CatteryLogic:getDirectionAndSizeByConfig(configType)
	local direction = 1
	local size = 1
	if configType and configType >= 1 and configType <= 12 then
		direction = (configType-1) % 4 + 1
		size = math.ceil(configType / 4) 
	end

	return direction, size
end


function CatteryLogic:decreaseCattery(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end
	if item.ItemType == GameItemType.kCattery then
		if item.catteryState >= CatteryState.kReadyToRoll then return end
		item.catteryState = item.catteryState + times
		if item.catteryState > CatteryState.kReadyToRoll then
			item.catteryState = CatteryState.kReadyToRoll
		end

		if item.catteryState == CatteryState.kOneLevel then
			local itemView = mainLogic.boardView:safeGetItemView(r, c)
			if itemView then
				itemView:playCatteryAniByState(CatteryState.kOneLevel,{hit = true})
			end
		end

		local action = GameBoardActionDataSet:createAs(
		 		GameActionTargetType.kGameItemAction,
		 		GameItemActionType.kItem_Cattery_Hit_Once,
		 		IntCoord:create(item.x, item.y),
		 		nil,
		 		GamePlayConfig_MaxAction_time)
		action.size = item.catterySize
		mainLogic:addDestroyAction(action)
	end
	
end

function CatteryLogic:decreaseMeow(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end
	if item.ItemType == GameItemType.kMeow then
		if item.meowLevel <= 0 then return end
		item.meowLevel = item.meowLevel - times
		if item.meowLevel < 0 then
			item.meowLevel = 0
		end

		if item.meowLevel == 1 then
			local itemView = mainLogic.boardView:safeGetItemView(r, c)
			if itemView then
				itemView:playMeowDec({hit = true})
			end
		end
		if item.meowLevel == 0 then
			local collectAction = GameBoardActionDataSet:createAs(
			 		GameActionTargetType.kGameItemAction,
			 		GameItemActionType.kItem_Meow_Collect,
			 		IntCoord:create(item.x,item.y),
			 		nil,
			 		GamePlayConfig_MaxAction_time)
			collectAction.targetMeow = item
			mainLogic:addDestroyAction(collectAction)
			mainLogic:setNeedCheckFalling()	
		end
	end
	
end

function CatteryLogic:onCatterySplit(mainLogic, targetCattery)
	if not targetCattery then return end
	if targetCattery.catteryState ~= CatteryState.kRolling then return end
	targetCattery.catteryState = CatteryState.kSplit
end

function CatteryLogic:onMeowDataRefresh(mainLogic, size, row, col)
    for i = 1, size do
        for j = 1, size do
        	local item = mainLogic.gameItemMap[row + i - 1][col + j - 1]
        	if item then
        		item:cleanAnimalLikeData()
        		item:removeMeowHitLock() 
				item:removeMeowLock()
        		item.ItemType = GameItemType.kMeow
				item.meowLevel = 2
				item.isEmpty = false 
				mainLogic:checkItemBlock(item.y, item.x)  
        	end
        end
    end
end

-------------------------------------- Roll -----------------------------------------
function CatteryLogic:isCatteryReadyToRoll(mainLogic, item)
	if item and item.ItemType == GameItemType.kCattery then
		if item.catteryState == CatteryState.kReadyToRoll and item:isVisibleAndFree() then
			return true
		end
	end
	return false
end

function CatteryLogic:sortCatteryList(listUp,listDown,listLeft,listRight)
	if #listUp >= 2 then
		table.sort(listUp,function (a,b)
			if a.y ~= b.y then
				return a.y > b.y
			end
			if a.catterySize ~= b.catterySize then
				return a.catterySize < b.catterySize
			end
			return false
		end)
	end

	if #listDown >= 2 then
		table.sort(listDown,function (a,b)
			if a.y ~= b.y then
				return a.y < b.y
			end
			if a.catterySize ~= b.catterySize then
				return a.catterySize < b.catterySize
			end
			return false
		end)
	end

	if #listLeft >= 2 then
		table.sort(listLeft,function (a,b)
			if a.x ~= b.x then
				return a.x > b.x
			end
			if a.catterySize ~= b.catterySize then
				return a.catterySize < b.catterySize
			end
			return false
		end)
	end

	if #listRight >= 2 then
		table.sort(listRight,function (a,b)
			if a.x ~= b.x then
				return a.x < b.x
			end
			if a.catterySize ~= b.catterySize then
				return a.catterySize < b.catterySize
			end
			return false
		end)
	end

	local list = {}
	for i, v in ipairs(listDown) do table.insert(list, v) end
	for i, v in ipairs(listRight) do table.insert(list, v) end
	for i, v in ipairs(listLeft) do table.insert(list, v) end
    for i, v in ipairs(listUp) do table.insert(list, v) end
    return list
end

function CatteryLogic:getAllActiveOrRollingCattery(mainLogic,state)
	local function copyItem(item)
		local data = {
			x = item.x,
			y = item.y,
			catteryDirection = item.catteryDirection,
		    catterySize = item.catterySize,
			catteryState = item.catteryState
		}
		return data
	end

	local listUp = {}
	local listDown = {}
	local listLeft = {}
	local listRight = {}

	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			local needInsert = CatteryLogic:isCatteryReadyToRoll(mainLogic, item)
			if needInsert then
	            if item.catteryDirection == 1 then
					table.insert(listUp,copyItem(item))
				elseif item.catteryDirection == 2 then
					table.insert(listRight,copyItem(item))
				elseif item.catteryDirection == 3 then
					table.insert(listDown,copyItem(item))
				elseif item.catteryDirection == 4 then
					table.insert(listLeft,copyItem(item))
				end
			end
		end
	end
	local allActiveCatterys = self:sortCatteryList(listUp,listDown,listLeft,listRight)
	
	return allActiveCatterys
end


function CatteryLogic:getNextGrid(mainLogic, cattery)
	if not cattery or not cattery.catteryDirection or cattery.catteryDirection < 1 or cattery.catteryDirection > 4 then 
		return true
	end

	local catteryRow, catteryCol = cattery.y, cattery.x

	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local currR = catteryRow + aroundY[cattery.catteryDirection]
	local currC = catteryCol + aroundX[cattery.catteryDirection]

	local hasReachedEnd, needCheckPosList, chainList = CatteryLogic:_catteryHasReachedEnd(mainLogic, currR, currC, cattery)
	if hasReachedEnd then
		currR = catteryRow
		currC = catteryCol
	end
	return hasReachedEnd, currR, currC, needCheckPosList, chainList
end

-- 到达棋盘边缘或被特定障碍阻挡 另外初始为空的格子也会阻挡 还需要判断下一个格子是否有猫窝 cur是不算体积改为next的格子，now是算上体积。
function CatteryLogic:_catteryHasReachedEnd(mainLogic, currGridR, currGridC, cattery)
	local reachPosList = {}
	local notReachPosList = {}
	local chainList = {}
	local offsetX = {0,1,0,0}
	local offsetY = {0,0,1,0}
	local hasReachedEnd = false
	for i = 1, cattery.catterySize do
		local nowR = currGridR + offsetY[cattery.catteryDirection]*(cattery.catterySize-1) + (i-1)*((cattery.catteryDirection+1)%2)
		local nowC = currGridC + offsetX[cattery.catteryDirection]*(cattery.catterySize-1) + (i-1)*(cattery.catteryDirection%2)

		table.insert(notReachPosList,{r = nowR, c = nowC})
		if not mainLogic:isPosValid(nowR, nowC) then
			hasReachedEnd = true		
		end

		local gridItem = mainLogic:safeGetItemData(nowR, nowC)
		local gridBoard = mainLogic:safeGetBoardData(nowR, nowC)

		if not gridItem or not gridBoard then 
			hasReachedEnd = true
		else
			if CatteryLogic:canBeStoppedByChainAndClean(mainLogic, nowR, nowC, cattery, i) then
				hasReachedEnd = true
				table.insert(chainList,{r = nowR, c = nowC, i = i})
			else
				if  gridItem.isUsed and
					(gridItem.ItemType == GameItemType.kAnimal or --动物。特效动物，魔力鸟
					gridItem.ItemType == GameItemType.kNewGift or --礼盒
					gridItem.ItemType == GameItemType.kAddMove or --礼盒
					gridItem.ItemType == GameItemType.kCrystal or --水晶球
					gridItem.ItemType == GameItemType.kCoin or --银币
					gridItem.ItemType == GameItemType.kVenom or --毒液
					gridItem.ItemType == GameItemType.kBalloon or --气球
					gridItem.ItemType == GameItemType.kChameleon or --染色蛋
					gridItem.ItemType == GameItemType.kBlocker207 or --钥匙
					gridItem.ItemType == GameItemType.kNone or
					gridItem.ItemType == GameItemType.kCuckooWindupKey or
					(CatteryLogic:isCatteryOrMeow(gridItem.ItemType) and (CatteryLogic:checkCatteryCanPass(mainLogic,cattery,gridItem) == 1 ))) and
					not gridItem.isReverseSide and --翻转地格
					not gridItem:hasAnyFurball() and --毛球
						gridBoard.colorFilterBLevel == 0 and--过滤器B状态
					not gridItem:hasLock() and--牢笼 荷塘 蜂蜜 小叶堆 锁 水桶 含羞草 鱿鱼
					not gridItem:seizedByGhost() and--幽灵
					not CanevineLogic:is_occupy(gridItem) and --花藤
					not gridItem.isSnail and --蜗牛
					not gridItem:hasMeowHitLock() and
					CatteryLogic:checkCatteryCanPass(mainLogic,cattery,gridItem)
					then
				else
					hasReachedEnd = true
					table.insert(reachPosList,{r = nowR, c = nowC})
				end
			end
		end
	end

	return hasReachedEnd, hasReachedEnd and reachPosList or notReachPosList, chainList
end

function CatteryLogic:canBeStoppedByChainAndClean(mainLogic, r, c, cattery, i, clean)
	local offset = {
			{1,0},
			{0,-1},
			{-1,0},
			{0,1},
		}

	local lastR = r + offset[cattery.catteryDirection][1]
	local lastC = c + offset[cattery.catteryDirection][2]

	local lastBoard = mainLogic:safeGetBoardData(lastR, lastC)
	local gridBoard = mainLogic:safeGetBoardData(r, c)

	if lastBoard then
		if lastBoard:hasChainInDirection(cattery.catteryDirection) then
			if clean then
				SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, lastBoard.y, lastBoard.x, {cattery.catteryDirection})
			else
				return true
			end
		end
	end

	if gridBoard then
		local checkDir
		if cattery.catteryDirection % 2 == 1 then
			checkDir = {ChainDirConfig.kLeft,ChainDirConfig.kRight}
		else
			checkDir = {ChainDirConfig.kUp,ChainDirConfig.kDown}
		end

		local cleanDir = {}
		local mustClearDir = (cattery.catteryDirection + 1)%4 + 1

		if gridBoard:hasChainInDirection(mustClearDir) then
			if clean then
				table.insert(cleanDir,mustClearDir)
			else
				return true
			end
		end
		if cattery.catterySize == 1 then

		elseif i == 1 then
			if gridBoard:hasChainInDirection(checkDir[2]) then
				if clean then
					table.insert(cleanDir,checkDir[2])
				else
					return true
				end
			end
		elseif i == cattery.catterySize and gridBoard:hasChainInDirection(checkDir[1]) then
			if clean then
				table.insert(cleanDir,checkDir[1])
			else
				return true
			end
		elseif i > 1 and i < cattery.catterySize then
			if gridBoard:hasChainInDirection(checkDir[1]) or gridBoard:hasChainInDirection(checkDir[2]) then
				if clean then
					table.insert(cleanDir,checkDir[1])
					table.insert(cleanDir,checkDir[2])
				else
					return true
				end
			end
		end

		if clean then
			SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, gridBoard.y, gridBoard.x, cleanDir)
		end
	end

end

function CatteryLogic:tryToDecrease(mainLogic, item, count)
	if not item then return end
	local catteryRootPos = CatteryLogic:getCatteryRoot(item)
	local catteryRootItem
	if catteryRootPos then
		catteryRootItem = mainLogic.gameItemMap[catteryRootPos.r][catteryRootPos.c]
	end
	if catteryRootItem and catteryRootItem.canAttackCattery then
		CatteryLogic:decreaseCattery(mainLogic, catteryRootPos.r, catteryRootPos.c, count, scoreScale)
		catteryRootItem.canAttackCattery = false
	end
end

-- 找到真正的猫窝位置
function CatteryLogic:getCatteryRoot( gameItemData )
	return CatteryLogic:_findCatteryRoot(gameItemData)
end

function CatteryLogic:_findCatteryRoot( gameItemData )
	local mainLogic = GameBoardLogic:getCurrentLogic()
    for r = 1, gameItemData.catterySize do
        for c = 1, gameItemData.catterySize do
        	if mainLogic:isPosValid(gameItemData.y - r + 1, gameItemData.x - c + 1) then
	        	local rootGameItemData = mainLogic.gameItemMap[gameItemData.y - r + 1][gameItemData.x - c + 1]
	        	if rootGameItemData and rootGameItemData.ItemType == GameItemType.kCattery and rootGameItemData.catterySize == gameItemData.catterySize then 
	        		return {r = rootGameItemData.y, c = rootGameItemData.x}
	        	end
	        end
        end
    end
end

function CatteryLogic:getCatteryRootItem( gameItemData )
	local mainLogic = GameBoardLogic:getCurrentLogic()
    for r = 1, gameItemData.catterySize do
        for c = 1, gameItemData.catterySize do
        	if mainLogic:isPosValid(gameItemData.y - r + 1, gameItemData.x - c + 1) then
	        	local rootGameItemData = mainLogic.gameItemMap[gameItemData.y - r + 1][gameItemData.x - c + 1]
	        	if rootGameItemData and rootGameItemData.ItemType == GameItemType.kCattery and rootGameItemData.catterySize == gameItemData.catterySize then 
	        		return rootGameItemData
	        	end
	        end
        end
    end
end

function CatteryLogic:canRemoveMeow( item )
	return item.ItemType == GameItemType.kMeow and item.meowLevel == 1
end

function CatteryLogic:checkCatteryCanPass( mainLogic, cattery, item)
	local lockDir = item:hasMeowLock()
	if lockDir then
		if lockDir == cattery.catteryDirection then
			return 1
		else
			return false
		end
	else
		return 2
	end
	
end


function CatteryLogic:specialDealForZeroRollnum(mainLogic, size, cattery, direction) --猫猫占的大块地方的地格层和果酱的处理
	for i = 1, size do
		for j = 1, size do
			local r = cattery.y+i-1
			local c = cattery.x+j-1
			CatteryLogic:cleanLightUp(mainLogic, r, c, 1, true)

			if size ~= 1 then
				local formerR, formerC = CatteryLogic:getFormerGridPosByDir(direction, r, c)
				if formerR >= cattery.y and formerR <= cattery.y + size - 1 and 
					formerC >= cattery.x and formerC <= cattery.x + size - 1 then
						local formerBoardData = mainLogic:safeGetBoardData(formerR, formerC)
						if formerBoardData and formerBoardData:hasJamSperad() then
							GameExtandPlayLogic:addJamSperadFlag(mainLogic, r, c)
						end
				end
			end
		end
	end
end


function CatteryLogic:onCatteryDestroyed(mainLogic, row, col)
	local item = mainLogic.gameItemMap[row][col]
	if item then
		item:cleanAnimalLikeData()
		item.isNeedUpdate = true   
		mainLogic:checkItemBlock(item.y, item.x)  
	end
end

function CatteryLogic:cleanLightUp(mainLogic, row, col, scoreScale, condition)
	SpecialCoverLogic:SpecialCoverLightUpAtBlocker(mainLogic, row, col, 1, true)
	SnailLogic:SpecialCoverSnailRoadAtPos( mainLogic, row, col )
	GameExtandPlayLogic:decreaseLotus(mainLogic, row, col , 1)
end

function CatteryLogic:onCatteryMovedTo(mainLogic, row, col, cattery, posList, direction, size)
	if cattery then
		cattery.y = row
		cattery.x = col
	end
	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	
	for k,v in ipairs(posList) do
		local offset = {
			{1,0},
			{0,-1},
			{-1,0},
			{0,1},
		}
		local r = v.r + offset[direction][1]*(size)
		local c = v.c + offset[direction][2]*(size)
		if r >=1 and r <=rowAmount and c >= 1 and c <= colAmount then
			local item = mainLogic.gameItemMap[r][c]
			if item then
				item:removeMeowLock() --把走过的地方解除
				mainLogic:checkItemBlock(item.y, item.x) 
			end
		end
	end
end

function CatteryLogic:isCattery(itemType)
	return itemType == GameItemType.kCattery or itemType == GameItemType.kCatteryEmpty
end

function CatteryLogic:isCatteryOrMeow(itemType)
	return CatteryLogic:isCattery(itemType) or itemType == GameItemType.kMeow
end

function CatteryLogic:destroyRolledGrid(mainLogic,r1,c1,r2,c2,dir)
	local scoreScale = 1
	for r = r1, r2 do
		for c = c1, c2 do
			local formerR, formerC = CatteryLogic:getFormerGridPosByDir(dir, r, c)
			local formerBoardData = mainLogic:safeGetBoardData(formerR, formerC)
			if formerBoardData and formerBoardData:hasJamSperad() then
				GameExtandPlayLogic:addJamSperadFlag(mainLogic, r, c)
			end

			if mainLogic:isPosValid(r, c) then
				local item = mainLogic.gameItemMap[r][c]
				SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, scoreScale)
				BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, scoreScale, true, nil)
				SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, scoreScale, nil, nil, nil, nil)
				--SpecialCoverLogic:specialCoverChainsAtPos(mainLogic, r, c, getEliminateChainDir(r, c))
				GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, 0, true, 3)
				if item.ItemType == GameItemType.kChameleon then
					ChameleonLogic:onChameleonDemolished(mainLogic, item)
					item:cleanAnimalLikeData()
					local targetItemView
					if mainLogic.boardView.baseMap[r] and mainLogic.boardView.baseMap[r][c] then
						targetItemView = mainLogic.boardView.baseMap[r][c]
					end
					if targetItemView then targetItemView:catteryHitChameleon() end
				end
			end
		end
	end
end

function CatteryLogic:getFormerGridPosByDir(dir, currR, currC)
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local formerR = currR - aroundY[dir]
	local formerC = currC - aroundX[dir]

	if formerR < 0 or formerC < 0 then
		return nil
	end
	return formerR, formerC
end


 