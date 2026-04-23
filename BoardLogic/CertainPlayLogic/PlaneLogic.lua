PlaneLogic = class{}

function PlaneLogic:getDirectionAndCountDownByConfig(configType)
	local direction = 1
	local countDownLevel = 1

	if configType and configType >= 1 and configType <= 16 then
		countDownLevel = math.ceil(configType / 8)
		direction = CalculationUtil:modValueBetween(1, 8, configType)
	end

	-- printx(11, "====== PLANE: getDirectionAndCountDownByConfig", configType, direction, countDownLevel)
	return direction, countDownLevel
end

function PlaneLogic:onPlaneBeingHit(mainLogic, r, c, times, scoreScale)
	-- printx(11, "~~~~~~~~ Plane Being Hit!", r, c, times, debug.traceback())
	-- if mainLogic.isBonusTime then return end

	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end

	local origLevel = item.planeCountDown
	item.planeCountDown = item.planeCountDown - times
	if item.planeCountDown < 0 then item.planeCountDown = 0 end
	-- ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_Plane, ObstacleFootprintAction.k_Hit, origLevel - item.planeCountDown)

	local itemView = mainLogic.boardView:safeGetItemView(r, c)
	if itemView then
		itemView:playPlaneBeingHit(item.planeCountDown, item.planeDirection)
	end
end

function PlaneLogic:onPlaneDestroyed(mainLogic, targetPlane)
	if not targetPlane then return end
	local row, col = targetPlane.y, targetPlane.x

	GameExtandPlayLogic:decreaseLotus(mainLogic, row, col , 1)
	SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, row, col)
	SpecialCoverLogic:SpecialCoverLightUpAtBlocker(mainLogic, row, col, 1, true)

	mainLogic:tryDoOrderList(row, col, GameItemOrderType.kOthers, GameItemOrderType_Others.kPlane, 1)
	SquidLogic:checkSquidCollectItem(mainLogic, row, col, TileConst.kPlane)
	GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, row, col, Blocker195CollectType.kPlane)

	targetPlane:cleanAnimalLikeData()
	-- targetPlane.isUsed = false
	targetPlane.isNeedUpdate = true
	mainLogic:checkItemBlock(row, col)
	mainLogic:addScoreToTotal(row, col, 300)
end

-------------------------------------- Fly -----------------------------------------
function PlaneLogic:isPlaneReadyToTakeOff(mainLogic, item)
	-- printx(11, "check: isPlaneReadyToTakeOff", debug.traceback(), item.planeCountDown)
	if item and item.ItemType == GameItemType.kPlane then
		if item.planeCountDown <= 0 and item:isVisibleAndFree() then
			return true
		end
	end
	return false
end

function PlaneLogic:pickAllActivePlane(mainLogic)
	local allActivePlanes = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if PlaneLogic:isPlaneReadyToTakeOff(mainLogic, item) then
            	table.insert(allActivePlanes, item)
            end
		end
	end
	return allActivePlanes
end

function PlaneLogic:getNextTargetGrid(mainLogic, plane, flyingRound)
	-- printx(11, "======== PlaneLogic:getNextTargetGrid =========", flyingRound)
	if not plane or not plane.planeDirection or plane.planeDirection < 1 or plane.planeDirection > 8 then 
		return true
	end

	local planeRow, planeCol = plane.y, plane.x
	-- printx(11, "Plane:", plane, plane.planeDirection, planeRow, planeCol)

	--- 上 右 下 左 右上 右下 左下 左上
	local aroundX = {0, 1, 0, -1, 1, 1, -1, -1}
	local aroundY = {-1, 0, 1, 0, -1, 1, 1, -1}

	local currR = planeRow + (flyingRound + 1) * aroundY[plane.planeDirection]
	local currC = planeCol + (flyingRound + 1) * aroundX[plane.planeDirection]
	local nextR = currR + aroundY[plane.planeDirection]
	local nextC = currC + aroundX[plane.planeDirection]
	-- printx(11, "currR, currC, nextR, nextC", currR, currC, nextR, nextC)

	local hasReachedEnd = PlaneLogic:_planeHasReachedEnd(mainLogic, currR, currC, nextR, nextC)
	-- printx(11, "hasReachedEnd, currR, currC", hasReachedEnd, currR, currC)
	return hasReachedEnd, currR, currC
end

-- 到达棋盘边缘或被特定障碍阻挡
function PlaneLogic:_planeHasReachedEnd(mainLogic, currGridR, currGridC, nextGridR, nextGridC)
	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	
	if nextGridR < 1 or nextGridR > rowAmount or nextGridC < 1 or nextGridC > colAmount then
		return true
	end

	local gridItem = mainLogic:safeGetItemData(currGridR, currGridC)
	if not gridItem then return false end

	--- 覆盖层类的阻挡
	if WaterBucketLogic:hasBucket(gridItem) then
		return true
	end

	--- 非覆盖层类的阻挡
	if gridItem:isVisibleAndFree() then
		-- 有花藤的格子isEmpty居然是true，所以要单独拎出来处理……………………
		-- if gridItem.ItemType == GameItemType.kCanevine then  	--只有花藤根部格子此判定才成立
		if CanevineLogic:is_occupy(gridItem) then
			return true
		end

		if not gridItem.isEmpty then
			if gridItem.ItemType == GameItemType.kCoin or gridItem.ItemType == GameItemType.kPuffer then
				return true
			end
		end
	end

	return false
end

function PlaneLogic:getDecChainDirByPlaneDir(planeDir)
	local eliminateChainDir = {}
	if planeDir > 0 and planeDir < 5 then
		if planeDir == 1 then
			table.insert(eliminateChainDir, ChainDirConfig.kDown)
			table.insert(eliminateChainDir, ChainDirConfig.kUp)
		elseif planeDir == 2 then
			table.insert(eliminateChainDir, ChainDirConfig.kLeft)
			table.insert(eliminateChainDir, ChainDirConfig.kRight)
		elseif planeDir == 3 then
			table.insert(eliminateChainDir, ChainDirConfig.kUp)
			table.insert(eliminateChainDir, ChainDirConfig.kDown)
		elseif planeDir == 4 then
			table.insert(eliminateChainDir, ChainDirConfig.kRight)
			table.insert(eliminateChainDir, ChainDirConfig.kLeft)
		end
	elseif planeDir >= 5 then
		table.insert(eliminateChainDir, ChainDirConfig.kRight)
		table.insert(eliminateChainDir, ChainDirConfig.kLeft)
		table.insert(eliminateChainDir, ChainDirConfig.kUp)
		table.insert(eliminateChainDir, ChainDirConfig.kDown)
	end
	return eliminateChainDir
end

function PlaneLogic:getFormerGridPosByPlaneDir(planeDir, currR, currC)
	--- 上 右 下 左 右上 右下 左下 左上
	local aroundX = {0, 1, 0, -1, 1, 1, -1, -1}
	local aroundY = {-1, 0, 1, 0, -1, 1, 1, -1}

	local formerR = currR - aroundY[planeDir]
	local formerC = currC - aroundX[planeDir]

	if formerR < 0 or formerC < 0 then
		return nil
	end
	return formerR, formerC
end
