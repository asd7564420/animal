BridgeCrossLogic = class{}

function BridgeCrossLogic:initBridgeRouteData(mainLogic, config)
	local tileMap = config.bridgeRouteRawData
	if not tileMap then return end
	if not mainLogic or not mainLogic.boardmap then return end
	
	for r = 1, #tileMap do 
		if tileMap[r] then
			for c = 1, #tileMap[r] do
				local tileDef = tileMap[r][c]
				if tileDef then
					BridgeCrossLogic:_initBridgeRoadTypeByConfig(mainLogic, r, c, tileDef)
				end
			end
		end
	end

	local dx = { 0, 1, 0, -1 }
    local dy = { 1, 0, -1, 0 }

	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]

			if BridgeCrossLogic:_gridHasBridgeRoad(board) and not BridgeCrossLogic:_gridHasPrevBridgeRoad(board) then
				board.isBridgeRoadStart = true
			end

			if not BridgeCrossLogic:_gridHasBridgeRoad(board) and BridgeCrossLogic:_gridHasPrevBridgeRoad(board) then
				for i = 1 , 4 do
					local row = r + dx[i]
					local col = c + dy[i]
					if mainLogic:isPosValid(row, col) then
						local prevBoard = mainLogic.boardmap[row][col]
						if BridgeCrossLogic:_gridHasBridgeRoad(prevBoard) and prevBoard.bridgeRoadType then
							if ( prevBoard.bridgeRoadType == 1 and i == 2 ) or
							( prevBoard.bridgeRoadType == 2 and i == 4 ) or
							( prevBoard.bridgeRoadType == 3 and i == 1 ) or
							( prevBoard.bridgeRoadType == 4 and i == 3 ) then

								prevBoard.isBridgeRoadEnd = true
								-- printx(15,"road end",row,col)
								-- printx(15,"prevBoard.prevBridgeRoadType",prevBoard.bridgeRoadType)
								-- printx(15,"=============================")
							end
						end
					end
				end


			end

		end
	end

end

function BridgeCrossLogic:_initBridgeRoadTypeByConfig(mainLogic, r, c, tileDef)
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
		-- printx(15,"r,c,currDir",r,c,currDir)
	end

	if currDir then
		local boardData = mainLogic:safeGetBoardData(r, c)
		if boardData then
			boardData.bridgeRoadType = currDir
			-- printx(11, "set bridgeRoadType:", currDir, r, c)
		end

		local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
		if nextBoardData then
			nextBoardData.prevBridgeRoadType = currDir
			-- printx(11, "set prevBridgeRoadType:", currDir, r, c)
		end
	end
end

function BridgeCrossLogic:_gridHasBridgeRoad(boardData)
	if boardData and boardData.bridgeRoadType and boardData.bridgeRoadType > 0 then
    	return true
    end
    return false
end

function BridgeCrossLogic:_gridHasPrevBridgeRoad(boardData)
	if boardData and boardData.prevBridgeRoadType and boardData.prevBridgeRoadType > 0 then
    	return true
    end
    return false
end

function BridgeCrossLogic:getNextGridPositionByDirection(currR, currC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local currGridData = mainLogic:safeGetBoardData(currR, currC)
	if currGridData then
		if currGridData.bridgeRoadType == RouteConst.kUp then
			return true, currR - 1, currC
		elseif currGridData.bridgeRoadType == RouteConst.kDown then
			return true, currR + 1, currC
		elseif currGridData.bridgeRoadType == RouteConst.kLeft then
			return true, currR, currC - 1
		elseif currGridData.bridgeRoadType == RouteConst.kRight then
			return true, currR, currC + 1
		end
	end
	return false
end

function BridgeCrossLogic:convertRoadTypeToAssetDir(roadType)
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

function BridgeCrossLogic:isBridgeEnd(posR, posC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end
	-- printx(15,"posR,posC",posR,posC)
	--- 上右下左
	if mainLogic.walkChickEndPos and mainLogic.walkChickEndPos.r and mainLogic.walkChickEndPos.c then
		if posR == mainLogic.walkChickEndPos.r and posC == mainLogic.walkChickEndPos.c then
			return true
		end
	end

	local isBridgeEnd = false

	local itemData = mainLogic:safeGetItemData(posR, posC)
	if itemData and itemData.ItemType == GameItemType.kWalkChickEnd then
		isBridgeEnd = true
		mainLogic.walkChickEndPos = { r = posR, c = posC}
	end

	return isBridgeEnd
end

function BridgeCrossLogic:clearOldBoard( mainLogic, r, c )
	if not mainLogic then
		mainLogic = GameBoardLogic:getCurrentLogic()
	end
	local board = mainLogic.boardmap[r][c]
	-- printx(15,"BridgeCrossLogic:clearOldBoard",r,c,board.haveBoard)
	board.haveBoard = false
	
	board.isNeedUpdate = true

	mainLogic:checkItemBlock(r, c)
end

function BridgeCrossLogic:createNewBoard( mainLogic, r, c )
	if not mainLogic then
		mainLogic = GameBoardLogic:getCurrentLogic()
	end
	local board = mainLogic.boardmap[r][c]
	-- printx(15,"BridgeCrossLogic:createNewBoard",r,c,board.haveBoard)
	board.haveBoard = true
	
	board.isNeedUpdate = true

	mainLogic:checkItemBlock(r, c)
end

function BridgeCrossLogic:chickHasReachedEnd(mainLogic, firstTimeCheck)
	-- printx(11, "++++++++++++ CHECK, TravelLogic:heroHasReachedEnd")
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
    local walkChick = self:getChickOnBoard(mainLogic)
    if not mainLogic or not walkChick then return false end

    local statusAllowed = true
    if firstTimeCheck and walkChick.walkChickReachEndActivated then
    	statusAllowed = false
    end

    if statusAllowed then
        local boardData = mainLogic:safeGetBoardData(walkChick.y, walkChick.x)
        if boardData and boardData.isBridgeRoadEnd then
        	return true
        end
    end
    return false
end

function BridgeCrossLogic:isBoardAheadWalkChick( mainLogic )
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
    local walkChick = self:getChickOnBoard(mainLogic)
    if not mainLogic or not walkChick then return false end
    local walkChickRow = walkChick.y
    local walkChickCol = walkChick.x
    local isBridgeRoad,aheadRow,aheadCol = self:getNextGridPositionByDirection(walkChick.y,walkChick.x)
  
   	if isBridgeRoad then
	    local aheadBoardData = mainLogic:safeGetBoardData(aheadRow,aheadCol)
	    if aheadBoardData and aheadBoardData.haveBoard then
	    	return true
	    end
	end
    return false
end

function BridgeCrossLogic:getChickOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kWalkChick then
            	return item
            end
		end
	end
	return nil
end

function BridgeCrossLogic:getBridgeEndOnBoard(mainLogic)
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kWalkChickEnd then
            	return item
            end
		end
	end
	return nil
end

function BridgeCrossLogic:onWalkChickReachBridgeEnd(mainLogic)
	local walkChick = BridgeCrossLogic:getChickOnBoard(mainLogic)
	local bridgeEnd = BridgeCrossLogic:getBridgeEndOnBoard(mainLogic)
	if walkChick then
		walkChick.walkChickReachEndActivated = true
	end

	if walkChick and bridgeEnd then

		-- local function completeCallback( ... )
			
		-- end


		local walkChickGrid = ccp(walkChick.x, walkChick.y)
		local bridgeEndGrid = ccp(bridgeEnd.x, bridgeEnd.y)

		local action = GameBoardActionDataSet:createAs(
	            GameActionTargetType.kGameItemAction,
	            GameItemActionType.kItem_Walk_Chick_Reach_End, 
	            nil,
	            nil,
	            GamePlayConfig_MaxAction_time
	            )
	    action.walkChick = walkChickGrid
	    action.walkChickEnd = bridgeEndGrid
	    action.walkChickItem = walkChick
	    action.bridgeEndItem = bridgeEnd
	    -- action.completeCallback = completeCallback
	    mainLogic:addGlobalCoreAction(action)

	    mainLogic:addScoreToTotal(walkChickGrid.y,walkChickGrid.x, GamePlayConfigScore.WalkChick)

	end

end

local WalkChickExchangableItems = table.const{
	GameItemType.kBlocker195, GameItemType.kCrystalStone, GameItemType.kTotems, GameItemType.kMissile, GameItemType.kBlocker199, 
	GameItemType.kGift, GameItemType.kNewGift,GameItemType.kShellGift, GameItemType.kMagicLamp, GameItemType.kPacman, GameItemType.kPuffer, 
	GameItemType.kBlocker207, GameItemType.kBalloon, GameItemType.kBuffBoom, GameItemType.kScoreBuffBottle, GameItemType.kFirecracker,
	GameItemType.kAnimal, GameItemType.kHoneyBottle, GameItemType.kWanSheng, GameItemType.kIngredient, GameItemType.kCoin, 
	GameItemType.kChameleon, GameItemType.kCrystal, GameItemType.kAnimal, GameItemType.kWater, GameItemType.kTravelEnergyBag, GameItemType.kPlane,
	GameItemType.kAddMove,
}

function BridgeCrossLogic:_isExchangeableItemForWalkChick(mainLogic, walkChick)

	if not mainLogic then
		mainLogic = GameBoardLogic:getCurrentLogic()
	end

	if not walkChick or not mainLogic then
		return
	end

	local hasNextGrid, nextR, nextC = self:getNextGridPositionByDirection(walkChick.y, walkChick.x)
	-- printx(11, "^^^ ^^^ hasNextGrid, nextR, nextC", hasNextGrid, nextR, nextC)
	if not hasNextGrid or not mainLogic:isPosValid(nextR, nextC) then 
		return false
	end

	local item = mainLogic:safeGetItemData(nextR, nextC)

	if item and item.isUsed and item:isVisibleAndFree() then
		local index = table.indexOf(WalkChickExchangableItems, item.ItemType)
		-- if (index and index > 0) or item.isEmpty then
		if index and index > 0 then
			-- if CanevineLogic:is_occupy(item) then
			-- 	-- printx(15,"前方花藤！！！！！")
			-- 	return false
			-- end

			--产品现在要求空格不能交换了，所以花藤非头部就不用再判断了

			if mainLogic:hasRopeInNeighbors(walkChick.y, walkChick.x, nextR, nextC) then
				return false
			end

			if item.ItemType == GameItemType.kBlocker199 then
				if item:isBlocker199Active() then return true else return false end
			elseif item.ItemType == GameItemType.kTotems then
				if not item:isActiveTotems() then return true else return false end
			else
				return true,item
			end
		end
	end
	return false
end

function BridgeCrossLogic:refreshGameItemDataAfterChickWalk(mainLogic)
	local newColumnMap = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local oldItem = mainLogic.gameItemMap[r][c]
		    if oldItem and (oldItem.tempRowShiftByWalkChick ~= 0 or oldItem.tempColShiftByWalkChick ~= 0) then
		    	local newRow = oldItem.y + oldItem.tempRowShiftByWalkChick
		    	local newCol = oldItem.x + oldItem.tempColShiftByWalkChick

		    	if not newColumnMap[newCol] then newColumnMap[newCol] = {} end
		    	local newItemData = oldItem:copy()	--不会copy walkingDirection，tempRowShiftByHero，tempColShiftByHero
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

				currItem.tempRowShiftByWalkChick = 0
				currItem.tempColShiftByWalkChick = 0

				currItem:addFallingLockByTravelHero()
				mainLogic:checkItemBlock(row, col) --临时锁掉落
				currItem.updateLaterByWalkChick = true

			end
		end
	end

end

function BridgeCrossLogic:refreshAllBlockStateAfterChickWalk(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
		    if targetItem then
		    	if targetItem.updateLaterByWalkChick then
		    		targetItem.updateLaterByWalkChick = false

		    		targetItem:removeFallingLockByTravelHero()

			    	mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)

		    	end
		    end
		end
	end
end

function BridgeCrossLogic:walkChickReachedDestination(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end

	if mainLogic.walkChickReachedEndFlag then
		return true
	end

	return false
end

function BridgeCrossLogic:playWalkChickDebutAnimation(mainLogic)
	if not mainLogic then return end

	local walkChick = self:getChickOnBoard(mainLogic)
	if mainLogic.boardView and mainLogic.boardView.baseMap[walkChick.y] then
		local itemView = mainLogic.boardView.baseMap[walkChick.y][walkChick.x]
		itemView:playWalkChickAppear()
	end
end

function BridgeCrossLogic:cleanEndItemData( mainLogic, item1, item2 )
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic or not item1 or not item2 then 
		return
	end

	item1:cleanAnimalLikeData()
	item2:cleanAnimalLikeData()
	item1.isNeedUpdate = true
	item2.isNeedUpdate = true
	mainLogic:checkItemBlock(item1.y, item1.x)
	mainLogic:checkItemBlock(item2.y, item2.x)
end