WindTunnelLogic = class{}

WindTunnelDirection = table.const{
	kUp = 1,
	kRight = 2,
	kDown = 3,
	kLeft = 4,
}

function WindTunnelLogic:decreaseWindTunnelSwitch(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic.gameItemMap[r][c]
	local origLevel = item.windTunnelSwitchLevel
	item.windTunnelSwitchLevel = item.windTunnelSwitchLevel - times
	if item.windTunnelSwitchLevel < 0 then item.windTunnelSwitchLevel = 0 end
	-- ObstacleFootprintManager:addRecord(ObstacleFootprintType.k_WindTunnelSwitch, ObstacleFootprintAction.k_Hit, origLevel - item.windTunnelSwitchLevel)

	if item.windTunnelSwitchLevel == 0 then
		local action = GameBoardActionDataSet:createAs(
	        GameActionTargetType.kGameItemAction,
	        GameItemActionType.kItem_WindTunnelSwitch_Demolish, 
	        IntCoord:create(c, r),
	        nil,
	        GamePlayConfig_MaxAction_time
	        )
		action.targetSwitch = item

	    mainLogic:addDestroyAction(action)
		mainLogic:setNeedCheckFalling()
	else
		local itemView = mainLogic.boardView.baseMap[r][c]
		itemView:playWindTunnelSwitchBeingHit(item.windTunnelSwitchLevel)
	end
	
end

function WindTunnelLogic:onWindTunnelSwitchDestroyed(mainLogic, targetSwitch)
	if targetSwitch then
		local isOffSwitch = targetSwitch.windTunnelSwitchTypeIsOff
		
		targetSwitch:cleanAnimalLikeData()
		-- targetSwitch.isUsed = false
		targetSwitch.isNeedUpdate = true
		mainLogic:checkItemBlock(targetSwitch.y, targetSwitch.x)
		mainLogic:addScoreToTotal(targetSwitch.y, targetSwitch.x, 100)

		SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, targetSwitch.y, targetSwitch.x)

		-- printx(11, "isOffSwitch", isOffSwitch)
		WindTunnelLogic:_switchAllWindTunnelsOnBoard(mainLogic, not isOffSwitch)
	end
end

function WindTunnelLogic:_switchAllWindTunnelsOnBoard(mainLogic, toActive)
	if not mainLogic or not mainLogic.boardmap then return end
	-- printx(11, "=== Switch Wind Tunnels!!!! ======= TO:", toActive)

    for r = 1, #mainLogic.boardmap do 
        for c = 1, #mainLogic.boardmap[r] do 
            local boardData = mainLogic.boardmap[r][c]
            if boardData and boardData.windTunnelDir and boardData.windTunnelDir > 0 then
            	local itemData = mainLogic:getGameItemAt(r, c)
            	if itemData and not itemData:hasBlocker206() and not itemData.isReverseSide then
            		if toActive then
            			boardData:setGravity(boardData.windTunnelDir)
            		else
            			boardData:setGravity(BoardGravityDirection.kDown)	--默认为下，如果将来应用在别的模式，需要额外记录初始默认重力值
            		end
            		boardData.windTunnelActive = toActive
            		boardData.isNeedUpdate = true
            	end
           	end
        end
    end
end

------------------------------------- tile --------------------------------
function WindTunnelLogic:convertGravityDirToCommonDir(gravityDirection)
	local dir = CalculationUtil:mathBetween(gravityDirection, 1, 4)
	if dir == BoardGravityDirection.kUp then
		dir = 1
	elseif dir == BoardGravityDirection.kRight then
		dir = 2
	elseif dir == BoardGravityDirection.kDown then
		dir = 3
	else
		dir = 4
	end
	return dir
end

-- 获得四周同状态同方向的风区
function WindTunnelLogic:getWindTunnelsAroundOfSameStatusAndDir(row, col)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.boardmap then return nil end

	local function getWindTunnelData(r, c)
		if mainLogic.boardmap[r] and mainLogic.boardmap[r][c] then
			local boardData = mainLogic.boardmap[r][c]
			if boardData and boardData.windTunnelDir and boardData.windTunnelDir > 0 then
				return boardData
			end
		end
	end

	local selfWindTile = getWindTunnelData(row, col)
	if not selfWindTile then return nil end
	local selfActive = selfWindTile.windTunnelActive
	local selfDir = selfWindTile.windTunnelDir

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local hasRealNeighbour = false -- 同状态，同方向的邻接格子
	local hasPotentialNeighbour = false -- 同状态，但不同方向的邻接格子，也许路径相连
	local resultArr = {}
	for i = 1, 4 do
		resultArr[i] = false

		local currCol = col + aroundX[i]
		local currRow = row + aroundY[i]
		local windBoardData = getWindTunnelData(currRow, currCol)
		if windBoardData and windBoardData.windTunnelActive == selfActive then
			if windBoardData.windTunnelDir == selfDir then
				resultArr[i] = true
				hasRealNeighbour = true
				-- printx(11, "hasRealNeighbour!", currCol, currRow)
			else
				hasPotentialNeighbour = true
			end
		end
	end

	return resultArr, hasRealNeighbour, hasPotentialNeighbour
end

-- （显示&动画用）获取能被开关影响的，目标状态的区域（即，路径连通）
function WindTunnelLogic:getAllValidAreaOfTargetStatus(isActive)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.boardmap then return nil end

	-- 首先，收集所有同状态、同方向的风区
	-- 检测每个风区格子的流向，如果流向不同的风区，则合并两个风区

	local groupMap = {} -- key:row..col, val:groupID

	-- 可以视为一个区域的各组
	local sameAreaGroups = {}
	local function connectSameAreaGroupIDs(selfGroupID, targetGroupID)
		-- printx(11, "! connectSameAreaGroupIDs !", selfGroupID, targetGroupID)
		if selfGroupID and targetGroupID then
			local selfAreaIndex = -1
			local targetAreaIndex = -1
			for areaIndex, groupList in pairs(sameAreaGroups) do
				if table.indexOf(groupList, selfGroupID) then
					selfAreaIndex = areaIndex
				end
				if table.indexOf(groupList, targetGroupID) then
					targetAreaIndex = areaIndex
				end
			end

			local newGroupList
			local selfAreaGroup, targetAreaGroup
			if targetAreaIndex < 0 and selfAreaIndex < 0 then
				newGroupList = {}
				table.insert(newGroupList, selfGroupID)
				table.insert(newGroupList, targetGroupID)
			elseif targetAreaIndex > 0 and selfAreaIndex > 0 then
				if targetAreaIndex ~= selfAreaIndex then
					selfAreaGroup = sameAreaGroups[selfAreaIndex]
					targetAreaGroup = sameAreaGroups[targetAreaIndex]
					table.remove(sameAreaGroups, math.max(selfAreaIndex, targetAreaIndex))
					table.remove(sameAreaGroups, math.min(selfAreaIndex, targetAreaIndex))
					newGroupList = table.union(selfAreaGroup, targetAreaGroup)
				end
			else
				if targetAreaIndex > 0 then
					targetAreaGroup = sameAreaGroups[targetAreaIndex]
					table.insert(targetAreaGroup, selfGroupID)
				elseif selfAreaIndex > 0 then
					selfAreaGroup = sameAreaGroups[selfAreaIndex]
					table.insert(selfAreaGroup, targetGroupID)
				end
			end

			if newGroupList then
				table.insert(sameAreaGroups, newGroupList)
			end
		end
		-- printx(11, "-- sameAreaGroups:", table.tostring(sameAreaGroups))
	end

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local groupID = 1
	local needSecondCheckGrids = {}
	local boardmap = mainLogic.boardmap
	for r = 1, #boardmap do
		for c = 1, #boardmap[r] do
			local boardData = boardmap[r][c]
			if boardData and boardData.windTunnelDir and boardData.windTunnelDir > 0 
				and boardData.windTunnelActive == isActive 
				then

				local loactionKey = ""..r..","..c
				local currGroupID = groupID
				if groupMap[loactionKey] then
					currGroupID = groupMap[loactionKey]
				else
					groupMap[loactionKey] = groupID
					groupID = groupID + 1
				end

				local aroundDir, hasNeighbour, hasPotentialNeighbour = WindTunnelLogic:getWindTunnelsAroundOfSameStatusAndDir(r, c)
				-- printx(11, "===", r, c, aroundDir, hasNeighbour, hasPotentialNeighbour)
				if aroundDir and hasNeighbour then 
					for dir = 1, 4 do
						if aroundDir[dir] then
							local targetRow = r + aroundY[dir]
							local targetCol = c + aroundX[dir]
							local targetLoactionKey = ""..targetRow..","..targetCol
							local targetGroupID = groupMap[targetLoactionKey]
							if targetGroupID and (targetGroupID ~= currGroupID) then
								connectSameAreaGroupIDs(currGroupID, targetGroupID)
							else
								groupMap[targetLoactionKey] = currGroupID
							end
						end
					end
				end

				if hasPotentialNeighbour then
					-- printx(11, "add to needSecondCheckGrids, ", boardData.y, boardData.x)
					table.insert(needSecondCheckGrids, boardData)
				end
			end
		end
	end

	-- printx(11, "GroupMap 1", table.tostringByKeyOrder(groupMap))
	-- self:_printGroupMap(groupMap)
	-- printx(11, "sameAreaGroups 1", table.tostring(sameAreaGroups))

	-- 合并路径连通的区域
	for _, boardData in pairs(needSecondCheckGrids) do
		local windDir = boardData.windTunnelDir
		windDir = WindTunnelLogic:convertGravityDirToCommonDir(windDir)
		-- printx(11, "111", boardData.y, boardData.x, windDir)
		local flowTargetGrid = mainLogic:safeGetBoardData(boardData.y + aroundY[windDir], boardData.x + aroundX[windDir])
		if flowTargetGrid and flowTargetGrid.windTunnelDir and flowTargetGrid.windTunnelDir > 0 
			and flowTargetGrid.windTunnelActive == isActive 
			then
			-- 不能方向相反
			if math.abs(windDir - WindTunnelLogic:convertGravityDirToCommonDir(flowTargetGrid.windTunnelDir)) ~= 2 then
				local currGridLoactionKey = ""..boardData.y..","..boardData.x
				local currGridGroupID = groupMap[currGridLoactionKey]

				local flowTargetLoactionKey = ""..flowTargetGrid.y..","..flowTargetGrid.x
				local flowTargetGroupID = groupMap[flowTargetLoactionKey]
				-- printx(11, "222", currGridGroupID, flowTargetGroupID)
				if flowTargetGroupID and (flowTargetGroupID ~= currGridGroupID) then
					connectSameAreaGroupIDs(currGridGroupID, flowTargetGroupID)
				end
			end
		end
	end

	-- printx(11, "GroupMap", table.tostringByKeyOrder(groupMap))
	-- self:_printGroupMap(groupMap)
	-- printx(11, "sameAreaGroups 2", table.tostring(sameAreaGroups))

	local function getDummyGroupIDOfSameGroupAreas(rawGroupID)
		for mergeIndex, groupIDs in pairs(sameAreaGroups) do
			if table.indexOf(groupIDs, rawGroupID) then
				return 100 + mergeIndex
			end
		end
		return 0
	end

	-- key: groupID, val: list[{r = r, c = c}]
	local resultList = {}
	for locationStr, rawGroupID in pairs(groupMap) do
		local locationRawSet = string.split(locationStr, ',')
		local locationSet = {r = tonumber(locationRawSet[1]), c = tonumber(locationRawSet[2])}

		local groupID = getDummyGroupIDOfSameGroupAreas(rawGroupID)
		if groupID == 0 then
			groupID = rawGroupID
		end

		if not resultList[groupID] then resultList[groupID] = {} end
		local groupList = resultList[groupID]
		table.insert(groupList, locationSet)
	end

	-- printx(11, "resultList", table.tostringByKeyOrder(resultList))
	-- self:_printAreaMapOfResultList(resultList)
	return resultList
end

-- For Test Print
function WindTunnelLogic:_printGroupMap(groupMap)
	local function getGroupIDOfTargetGrid(row, col)
		for locationKey, groupID in pairs(groupMap) do
			local locationSet = string.split(locationKey, ',')
			if tonumber(locationSet[1]) == row and tonumber(locationSet[2]) == col then
				return ""..groupID
			end
		end
		return "-"
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard()
	for r = 1, rowAmount do
		local rowStr = ""
		for c = 1, colAmount do
			local groupIDStr = getGroupIDOfTargetGrid(r, c)
			rowStr = rowStr.." "..groupIDStr
		end
		printx(11, rowStr)
	end
end

-- For Test Print
function WindTunnelLogic:_printAreaMapOfResultList(resultList)
	printx(11, "============ resultList =============")
	local function getGroupIDOfTargetGrid(row, col)
		for groupID, gridList in pairs(resultList) do
			for _, gridLoc in pairs(gridList) do
				if gridLoc.r == row and gridLoc.c == col then
					return ""..groupID
				end
			end
		end
		return "---"
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard()
	for r = 1, rowAmount do
		local rowStr = ""
		for c = 1, colAmount do
			local groupIDStr = getGroupIDOfTargetGrid(r, c)
			rowStr = rowStr.." "..groupIDStr
		end
		printx(11, rowStr)
	end
end


--（开关击打动画用）获取能被开关影响的，目标状态的区域（即，路径连通）中，被击打的格子（距离开关最近）
function WindTunnelLogic:getHitPointOfAllValidArea(isActive, startRow, startCol)
	-- printx(11, "==== WindTunnelLogic:getHitPointOfAllValidArea")

	local allAreaList = self:getAllValidAreaOfTargetStatus(isActive)
	if not allAreaList then return nil end

	local function getDistanceOfTargetGrid(targetRow, targetCol)
		local disC = math.abs(targetCol - startCol)
		local disR = math.abs(targetRow - startRow)
		local dis = math.pow(disC, 2) + math.pow(disR, 2) --不开了
		return dis
	end

	local function getNearestPointOfArea(areaGrids)
		local minDisGrid
		for _, gridPos in pairs(areaGrids) do
			if not minDisGrid then
				minDisGrid = gridPos
			else
				if gridPos.r and gridPos.c and minDisGrid.r and minDisGrid.c then
					if getDistanceOfTargetGrid(gridPos.r, gridPos.c) < getDistanceOfTargetGrid(minDisGrid.r, minDisGrid.c) then
						minDisGrid = gridPos
					end
				end
			end
		end
		-- printx(11, "minDisGrid", table.tostring(minDisGrid))
		return minDisGrid
	end

	local hitPoints = {}
	for groupID, groupList in pairs(allAreaList) do
		-- printx(11, "scan area grids", groupID, table.tostring(groupList))
		local hitPointOfArea = getNearestPointOfArea(groupList)
		if hitPointOfArea then
			table.insert(hitPoints, hitPointOfArea)
		end
	end

	-- printx(11, "getHitPointOfAllValidArea", table.tostring(hitPoints))
	return hitPoints
end

function WindTunnelLogic:getAllWindTunnelGroupAreas()
	local activeGroups = self:getAllValidAreaOfTargetStatus(true)
	local nonActiveGroups = self:getAllValidAreaOfTargetStatus(false)

	local function getGroupIDOfTargetGrid(row, col, targetList)
		if not targetList then return 0 end
		for groupID, gridList in pairs(targetList) do
			for _, gridLoc in pairs(gridList) do
				if gridLoc.r == row and gridLoc.c == col then
					return groupID
				end
			end
		end
		return 0
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard()
	local groupIDMap = {}
	for r = 1, rowAmount do
		local rowList = {}
		for c = 1, colAmount do
			local groupID = getGroupIDOfTargetGrid(r, c, activeGroups)
			if groupID == 0 then
				groupID = getGroupIDOfTargetGrid(r, c, nonActiveGroups)
				if groupID ~= 0 then
					groupID = groupID + 1000 --为了不和active的重复
				end
			end
			rowList[c] = groupID
		end
		groupIDMap[r] = rowList
	end
	-- printx(11, "=== getAllWindTunnelGroupAreas:", table.tostring(groupIDMap))
	return groupIDMap
end

--------------------------------- Wind Tunnel Wall -------------------------------
function WindTunnelLogic:updateWindTunnelWallActiveStatusOnBoard()
	-- printx(11, "*.*.*.*.*.*.*.*.*.*.*.*. WindTunnelLogic:updateWindTunnelWallActiveStatusOnBoard")

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.boardmap then return nil end

	local function resetWindTunnelWallActiveStatus(targetBoard)
		targetBoard.windTunnelActiveWalls = {false, false, false, false}
	end

	--- 上右下左
	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}

	local boardmap = mainLogic.boardmap
	for r = 1, #boardmap do
		for c = 1, #boardmap[r] do
			local boardData = boardmap[r][c]
			if boardData and boardData.windTunnelDir and boardData.windTunnelDir > 0
				and boardData.windTunnelWalls and #boardData.windTunnelWalls > 0
				then
				resetWindTunnelWallActiveStatus(boardData)

				-- 风区边缘生效条件：1、本格为开启的风区 2、边缘另一侧格子为非开启的风区
				if boardData.windTunnelActive then
					for dir = 1, 4 do
						if boardData.windTunnelWalls[dir] then
							local neighbourRow = r + aroundY[dir]
							local neighbourCol = c + aroundX[dir]
							local neighbourBoard = mainLogic:safeGetBoardData(neighbourRow, neighbourCol)
							if neighbourBoard and not neighbourBoard:isWindTunnelActive() then
								boardData.windTunnelActiveWalls[dir] = true
							end
						end
					end
				end
			end
		end
	end
end

