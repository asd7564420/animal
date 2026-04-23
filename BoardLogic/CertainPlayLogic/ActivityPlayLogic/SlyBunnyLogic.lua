SlyBunnyLogic = class{}

function SlyBunnyLogic:getBunnyLaneLevelAndBunnyByConfig(configType)
	local hasBunny = false
	local laneLevel = 2

	if configType and configType >= 1 and configType <= 4 then
		if configType < 3 then
			hasBunny = true
		end
		laneLevel = CalculationUtil:modValueBetween(1, 2, configType)
	end

	-- printx(11, "=== getBunnyLaneLevelAndBunnyByConfig", configType, laneLevel, hasBunny)
	return laneLevel, hasBunny
end

function SlyBunnyLogic:laneIsCommonMultiplePrior1(itemData)
	if itemData.ItemType == GameItemType.kSlyBunnyLane then
		if not itemData.hasSlyBunnyOnLane then
			return true
		end
	end
	return false
end

function SlyBunnyLogic:laneIsCommonMultiplePrior2(itemData)
	if itemData.ItemType == GameItemType.kSlyBunnyLane then
		if itemData.hasSlyBunnyOnLane and itemData.bunnyLaneLevel and itemData.bunnyLaneLevel > 1 then
			return true
		end
	end
	return false
end

function SlyBunnyLogic:laneIsCommonMultiplePrior3(itemData)
	if itemData.ItemType == GameItemType.kSlyBunnyLane then
		if itemData.hasSlyBunnyOnLane and itemData.bunnyLaneLevel and itemData.bunnyLaneLevel == 1 then
			return true
		end
	end
	return false
end

function SlyBunnyLogic:decreaseSlyBunnyLane(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic.gameItemMap[r][c]
	local origLevel = item.bunnyLaneLevel
	item.bunnyLaneLevel = item.bunnyLaneLevel - times
	if item.bunnyLaneLevel < 0 then item.bunnyLaneLevel = 0 end

	if item.bunnyLaneLevel == 0 then
		local action = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItem_SlyBunnyLane_Demolish, 
			IntCoord:create(c, r),
			nil,
			GamePlayConfig_MaxAction_time
			)
		action.targetBunnyLane = item

		mainLogic:addDestroyAction(action)
		mainLogic:setNeedCheckFalling()
	else
		local itemView = mainLogic.boardView.baseMap[r][c]
		itemView:playSlyBunnyLaneBeingHit(item.bunnyLaneLevel)
	end
	
end

function SlyBunnyLogic:onSlyBunnyLaneDestroyed(mainLogic, targetBunnyLane)
	if targetBunnyLane then
		local r, c = targetBunnyLane.y, targetBunnyLane.x
		local hasBunny = targetBunnyLane.hasSlyBunnyOnLane

		targetBunnyLane:cleanAnimalLikeData()
		targetBunnyLane.isNeedUpdate = true
		mainLogic:checkItemBlock(r, c)
		mainLogic:addScoreToTotal(r, c, 100)

		if hasBunny then
			mainLogic:tryDoOrderList(r, c, GameItemOrderType.kOthers, GameItemOrderType_Others.kSlyBunny, 1)
		end
	end
end

---------------------------------------------------- Move -----------------------------------------------------
function SlyBunnyLogic:hasSlyBunnyOnBoard(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item.ItemType == GameItemType.kSlyBunnyLane and item.hasSlyBunnyOnLane then
				return true
			end
		end
	end
	return false
end

function SlyBunnyLogic:arrangeSlyBunnyMovements(mainLogic)
	local bunnyMovePlanList = {}

	-- 草坪地形信息图
	local laneMap = SlyBunnyLogic:_makeLaneMap(mainLogic)
	-- 有移动机会的狡兔，按照检测移动的顺序排好序
	local bunnyCheckMoveList = SlyBunnyLogic:_getBunnyMoveCheckListWithOrder(mainLogic, laneMap)

	for i = 1, #bunnyCheckMoveList do
		local targetBunny = bunnyCheckMoveList[i]
		-- printx(11, "========= ========= ======= move bunny:", targetBunny.y, targetBunny.x)
		local destinationPos = SlyBunnyLogic:_pickDestinationPosForBunny(targetBunny, laneMap, mainLogic)

		if destinationPos then
			local movePlanSet = {}
			movePlanSet.targetBunny = targetBunny
			movePlanSet.nextPos = destinationPos
			table.insert(bunnyMovePlanList, movePlanSet)

			-- update lane map
			SlyBunnyLogic:_updateLaneMapAfterOneBunnyArranged(laneMap, targetBunny.y, targetBunny.x, destinationPos.r, destinationPos.c)

			-- MACRO_DEV_START()
			-- printx(11, "+ + + + + + + One Moving Arranged: ("..targetBunny.y..","..targetBunny.x..") to ("..destinationPos.r..","..destinationPos.c)
			-- SlyBunnyLogic:_testPrintLaneMap(laneMap)
			-- MACRO_DEV_END()
		end
	end

	-- MACRO_DEV_START()
	-- printx(11, "************ ******** Arrange Ended ******** *************", #bunnyMovePlanList)
	-- SlyBunnyLogic:_testPrintLaneMap(laneMap)
	-- MACRO_DEV_END()
	return bunnyMovePlanList
end

-------------------------------------------------------------
--- 上 右 下 左
local aroundX = {0, 1, 0, -1}
local aroundY = {-1, 0, 1, 0}

function SlyBunnyLogic:_getLaneMapGridInitData()
	local laneGrid = {}
	laneGrid.available = false				--格子是否是狡兔草坪（即，是否是可移动范围）
	-- 以下属性仅对 available 的格子有效
	laneGrid.hasBunny = false				--格子是否是狡兔
	laneGrid.freeNeightbourAmount = 0		--四周无兔草坪的数量
	laneGrid.bunnyNeightbourAmount = 0		--四周狡兔的数量

	return laneGrid
end

-- 绘制移动地形信息图
function SlyBunnyLogic:_makeLaneMap(mainLogic)
	local laneMap = {}

	for r = 1, #mainLogic.gameItemMap do
		laneMap[r] = {}
		for c = 1, #mainLogic.gameItemMap[r] do
			local laneGrid = SlyBunnyLogic:_getLaneMapGridInitData()

			local item = mainLogic.gameItemMap[r][c]
			if item.ItemType == GameItemType.kSlyBunnyLane and item.bunnyLaneLevel > 0 and item:isVisibleAndFree() then
				laneGrid.available = true
				if item.hasSlyBunnyOnLane then
					laneGrid.hasBunny = true
				end

				for i = 1, 4 do
					local checkCol = c + aroundX[i]
					local checkRow = r + aroundY[i]
					local checkItem = mainLogic:safeGetItemData(checkRow, checkCol)
					if checkItem and checkItem.ItemType == GameItemType.kSlyBunnyLane and checkItem.bunnyLaneLevel > 0 then
						if not mainLogic:hasChainInNeighbors(r, c, checkRow, checkCol) then
							if checkItem.hasSlyBunnyOnLane then
								laneGrid.bunnyNeightbourAmount = laneGrid.bunnyNeightbourAmount + 1
							else
								laneGrid.freeNeightbourAmount = laneGrid.freeNeightbourAmount + 1
							end
						end
					end
				end
			end

			laneMap[r][c] = laneGrid
		end
	end

	-- MACRO_DEV_START()
	-- SlyBunnyLogic:_testPrintLaneMap(laneMap)
	-- MACRO_DEV_END()
	return laneMap
end

function SlyBunnyLogic:_getLaneGridOfMap(laneMap, r, c)
	if laneMap and r and c and laneMap[r] and laneMap[r][c] then
		return laneMap[r][c]
	end
	return SlyBunnyLogic:_getLaneMapGridInitData() --应该不会有这种情况
end

-- 获取安检测顺序排好序的，有移动机会的兔子列表
function SlyBunnyLogic:_getBunnyMoveCheckListWithOrder(mainLogic, laneMap)
	local moveableBunnyList = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item.ItemType == GameItemType.kSlyBunnyLane and item.hasSlyBunnyOnLane and item:isVisibleAndFree() then
				local laneGridData = SlyBunnyLogic:_getLaneGridOfMap(laneMap, r, c)
				-- 排除掉孤岛兔
				if laneGridData.freeNeightbourAmount > 0 or laneGridData.bunnyNeightbourAmount > 0 then
					table.insert(moveableBunnyList, item)
				end
			end
		end
	end

	-- 先内部打乱次序再排序，相当于对排序结果的同条件对象进行了随机选取
	table.randomOrder(moveableBunnyList, mainLogic)
	-- 按检测顺序，对兔子列表进行排序
	table.sort(moveableBunnyList, function(a, b)
		local laneDataOfA = SlyBunnyLogic:_getLaneGridOfMap(laneMap, a.y, a.x)
		local laneDataOfB = SlyBunnyLogic:_getLaneGridOfMap(laneMap, b.y, b.x)
		-- printx(11, "...", a.y, a.x, b.y, b.x)
		-- printx(11, "... A", laneDataOfA.freeNeightbourAmount, laneDataOfA.bunnyNeightbourAmount)
		-- printx(11, "... B", laneDataOfB.freeNeightbourAmount, laneDataOfB.bunnyNeightbourAmount)

		--优先级1：周围有更多空闲草地的（能轻松走的先走）
		if laneDataOfA.freeNeightbourAmount > laneDataOfB.freeNeightbourAmount then
			return true
		elseif laneDataOfA.freeNeightbourAmount < laneDataOfB.freeNeightbourAmount then
			return false
		end

		--优先级2：周围有更多兔子的（你走了别人才有更多机会走）
		if laneDataOfA.bunnyNeightbourAmount > laneDataOfB.bunnyNeightbourAmount then
			return true
		elseif laneDataOfA.bunnyNeightbourAmount < laneDataOfB.bunnyNeightbourAmount then
			return false
		end

		return false
	end)

	-- MACRO_DEV_START()
	-- SlyBunnyLogic:_testPrintMoveableBunnyList(moveableBunnyList, laneMap)
	-- MACRO_DEV_END()
	return moveableBunnyList
end

-- 为指定兔子甄选逃跑路线
function SlyBunnyLogic:_pickDestinationPosForBunny(targetBunny, laneMap, mainLogic)
	local bunnyR, bunnyC = targetBunny.y, targetBunny.x

	local aroundLaneList = {}			-- 周边格子合集，包含有兔，无兔两类
	local noBunnyAroundLaneList = {}	--（除了自己）周围没有兔子的
	local hasBunnyAroundLaneList = {}	-- 周围有别的兔子的
	--优先级0：周围（除了自己）没有兔子的格子
	table.insert(aroundLaneList, noBunnyAroundLaneList)
	table.insert(aroundLaneList, hasBunnyAroundLaneList)

	-- 自己四周
	for i = 1, 4 do
		local checkCol = bunnyC + aroundX[i]
		local checkRow = bunnyR + aroundY[i]
		local checkLaneData = SlyBunnyLogic:_getLaneGridOfMap(laneMap, checkRow, checkCol)
		local laneDataWithPos = {}
		laneDataWithPos.laneData = checkLaneData
		laneDataWithPos.pos = {r = checkRow, c = checkCol}
		-- printx(11, "AROUND:", checkCol, checkRow, table.tostring(checkLaneData))

		-- 是可进行移动的格子
		if checkLaneData.available and not checkLaneData.hasBunny 
			and not mainLogic:hasChainInNeighbors(bunnyR, bunnyC, checkRow, checkCol) then
			if checkLaneData.bunnyNeightbourAmount <= 1 then
				-- printx(11, "to no bunny!")
				table.insert(noBunnyAroundLaneList, laneDataWithPos)
			else
				-- printx(11, "to bunny!")
				table.insert(hasBunnyAroundLaneList, laneDataWithPos)
			end
		end
	end

	local function sortAroundLaneList(targetLaneList)
		-- 按选取优先级，对周边格子进行排序
		table.sort(targetLaneList, function(a, b)
			local laneDataOfA = a.laneData
			local laneDataOfB = b.laneData
			-- printx(11, "... A", laneDataOfA.freeNeightbourAmount, laneDataOfA.bunnyNeightbourAmount)
			-- printx(11, "... B", laneDataOfB.freeNeightbourAmount, laneDataOfB.bunnyNeightbourAmount)

			--优先级1：周围有更多空闲草地的（广阔的天地任你翱翔……呃，躲藏）
			if laneDataOfA.freeNeightbourAmount > laneDataOfB.freeNeightbourAmount then
				return true
			elseif laneDataOfA.freeNeightbourAmount < laneDataOfB.freeNeightbourAmount then
				return false
			end

			--优先级2：周围有更少兔子的（疫情期间不要聚集）
			if laneDataOfA.bunnyNeightbourAmount < laneDataOfB.bunnyNeightbourAmount then
				return true
			elseif laneDataOfA.bunnyNeightbourAmount > laneDataOfB.bunnyNeightbourAmount then
				return false
			end

			return false
		end)
	end

	local function pickTargetLane()
		-- 优先级高的列表在前，顺序检索
		for i = 1, #aroundLaneList do
			local targetList = aroundLaneList[i]
			if targetList and #targetList > 0 then
				if #targetList > 1 then
					-- 先内部打乱次序再排序，相当于对排序结果的同条件对象进行了随机选取
					table.randomOrder(targetList, mainLogic)
					sortAroundLaneList(targetList)
				end
				return targetList[1]	--排序后，第一位的就是想要的目的地啦
			end
		end
		return nil
	end

	local pickedTargetLane = pickTargetLane()
	if pickedTargetLane then
		return pickedTargetLane.pos
	end
	return nil
end

-- 安排好一只兔子的去向后，按去向更新草坪地形信息图
function SlyBunnyLogic:_updateLaneMapAfterOneBunnyArranged(laneMap, bunnyOrigR, bunnyOrigC, bunnyNextR, bunnyNextC)
	-- centerGrid、spcecialGrid：兔子移动关联的两个格子； bunnyArriving:对于centerGrid来说，兔子是离去还是到达
	local function updateLaneGridWhenBunnyMoves(bunnyArriving, centerGridR, centerGridC, spcecialGridR, spcecialGridC)
		local bunnyAddAmount
		if bunnyArriving then
			bunnyAddAmount = 1
		else
			bunnyAddAmount = -1
		end

		-- 更新四周的信息标记
		for i = 1, 4 do
			local currR = centerGridR + aroundY[i]
			local currC = centerGridC + aroundX[i]
			local laneData = SlyBunnyLogic:_getLaneGridOfMap(laneMap, currR, currC)
			if laneData and laneData.available then
				if currR == spcecialGridR and currC == spcecialGridC then
					laneData.hasBunny = not bunnyArriving
				end

				laneData.bunnyNeightbourAmount = laneData.bunnyNeightbourAmount + bunnyAddAmount
				laneData.freeNeightbourAmount = laneData.freeNeightbourAmount - bunnyAddAmount
			end
		end
	end

	updateLaneGridWhenBunnyMoves(false, bunnyOrigR, bunnyOrigC, bunnyNextR, bunnyNextC)
	updateLaneGridWhenBunnyMoves(true, bunnyNextR, bunnyNextC, bunnyOrigR, bunnyOrigC)
end

function SlyBunnyLogic:updateBunnyPos(mainLogic, oldBunny, newPos)
	--- 赋予新格子相应属性
	oldBunny.hasSlyBunnyOnLane = false
	oldBunny.isNeedUpdate = true

	local newBunnyItem = mainLogic:safeGetItemData(newPos.r, newPos.c)
	if newBunnyItem then
		newBunnyItem.hasSlyBunnyOnLane = true
		newBunnyItem.isNeedUpdate = true
	end
end

MACRO_DEV_START()
-- 一些打印
function SlyBunnyLogic:_testPrintLaneMap(laneMap)
	printx(11, "\n============================================== Lane Map:")
	for r = 1, #laneMap do
		local rowData = ""
		for c = 1, #laneMap[r] do
			local laneData = laneMap[r][c]
			local laneStr = ""
			if laneData.available then
				if laneData.hasBunny then
					laneStr = laneStr.."Y "
				else
					laneStr = laneStr.."  "
				end

				laneStr = laneStr..laneData.freeNeightbourAmount..","..laneData.bunnyNeightbourAmount
			else
				laneStr = "  -  "
			end

			rowData = rowData..laneStr.." | "
		end
		printx(11, rowData)
	end
end

function SlyBunnyLogic:_testPrintMoveableBunnyList(moveableBunnyList, laneMap)
	printx(11, "\n============================================== Bunny check list:")
	for i = 1, #moveableBunnyList do
		local bunnyItem = moveableBunnyList[i]
		local laneDataOfBunny = SlyBunnyLogic:_getLaneGridOfMap(laneMap, bunnyItem.y, bunnyItem.x)
		printx(11, "No."..i..":  ("..bunnyItem.y..","..bunnyItem.x..")")
		printx(11, "      laneData:", table.tostring(laneDataOfBunny))
	end
end
MACRO_DEV_END()

