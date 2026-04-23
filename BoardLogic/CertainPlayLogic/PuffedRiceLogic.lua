PuffedRiceLogic = class{}
local aroundX = {0, 1, 0, -1}--上右下左
local aroundY = {-1, 0, 1, 0}

function PuffedRiceLogic:onPuffedRiceBeingHit(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end

	if item.ItemType == GameItemType.kpuffedRice then
		if item.puffedRiceHp <= 0 then return end
		item.puffedRiceHp = item.puffedRiceHp - times
		if item.puffedRiceHp < 0 then
			item.puffedRiceHp = 0
		end
		if item.puffedRiceHp == 0 then
			item.puffedRiceBoom = true
			mainLogic:checkItemBlock(r, c)
		end
		item.puffedRiceMoveableSteps = item.puffedRiceMoveableSteps + times
		item.puffedRiceMoveableSteps = math.min(math.max(item.puffedRiceMoveableSteps,0),3)
		local decAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItem_PuffedRice_Add,
					nil,
					nil,
					GamePlayConfig_MaxAction_time)
		decAction.hp = item.puffedRiceHp
		decAction.targetpuffedRice = item
		mainLogic:addDestroyAction(decAction)
		mainLogic:setNeedCheckFalling()	
	end
end

function PuffedRiceLogic:isPuffedRiceReadyToJump(mainLogic, item)
	if item and item.ItemType == GameItemType.kpuffedRice then
		if item.puffedRiceMoveableSteps > 0 and item:isVisibleAndFree() then
			return true
		end
	end
	return false
end

function PuffedRiceLogic:checkPuffedRiceJumped(puffedRiceJumped, checkRow, checkCol)
	local hasJumped = false
	if puffedRiceJumped and #puffedRiceJumped > 0 then
		for k,v in ipairs(puffedRiceJumped) do
			if v.r == checkRow and v.c == checkCol then
				hasJumped = true
				break
			end
		end
	end
	return hasJumped
end

function PuffedRiceLogic:getAllActivePuffedRiceInOrder(mainLogic)
	local allActivePuffedRice = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if PuffedRiceLogic:isPuffedRiceReadyToJump(mainLogic, item) then
            	self:checkJump(mainLogic, allActivePuffedRice, item)
            end
		end
	end

	table.randomOrder(allActivePuffedRice, mainLogic)

	table.sort(allActivePuffedRice,function (a,b)
		if a.item.puffedRiceMoveableSteps ~= b.item.puffedRiceMoveableSteps then
			return a.item.puffedRiceMoveableSteps > b.item.puffedRiceMoveableSteps
		end
		if a.chance ~= b.chance then
			return a.chance > b.chance
		end
		if a.property ~= b.property then
			return a.property > b.property
		end
		return false
	end)
	return allActivePuffedRice
end

function PuffedRiceLogic:checkJump(mainLogic, allActivePuffedRice, item)
	local r = item.y
	local c = item.x
	local property = 0
	local chance = 0

	for i = 1, 4 do
		local checkCol = c + aroundX[i]
		local checkRow = r + aroundY[i]
		local neighborItem = mainLogic:safeGetItemData(checkRow, checkCol)
		if neighborItem and neighborItem:canBeSwap() and 
			not mainLogic:hasChainInNeighbors(r, c, checkRow, checkCol) then
			local neighborBoard = mainLogic:safeGetBoardData(checkRow, checkCol)
			if neighborBoard and neighborBoard.puffedRiceLow then
				if neighborItem.ItemType == GameItemType.kpuffedRice then
					property = property + 1					
				else
					property = property + 2
				end
			elseif self:checkPuffedRiceJumped(item.puffedRiceJumped, checkRow, checkCol) then
				property = property + 3
			elseif neighborItem.ItemType == GameItemType.kpuffedRice then
				property = property + 4
			else
				property = property + 5
			end
			chance = chance + 1
		end		
	end
	if chance > 0 then
		table.insert(allActivePuffedRice, {
			item = item,
			property = property,
			chance = chance,
			r = r,
			c = c,
		})
	end
end

function PuffedRiceLogic:getPuffedRiceJumpMap(allActivePuffedRice, mainLogic)
	local map = self:_initInfoMap(map,mainLogic)
	for k,v in ipairs(allActivePuffedRice) do
		local canJumpList = {{},{},{},{},{},{},{}}
		local jumpItem
		local vItem = map[v.r] and map[v.r][v.c]
		if vItem and not vItem.hasJumped then
			for i = 1, 4 do
				local checkCol = v.c + aroundX[i]
				local checkRow = v.r + aroundY[i]
				local neighborItem = map[checkRow] and map[checkRow][checkCol]
				if neighborItem 
					and neighborItem.canBeSwap
					and not mainLogic:hasChainInNeighbors(v.r, v.c, checkRow, checkCol) then
						if neighborItem.order < 6 then
							if self:checkPuffedRiceJumped(vItem.puffedRiceJumped, checkRow, checkCol) then
								neighborItem.order = 5
							elseif neighborItem.hasJumped then
								if neighborItem.isPuffedRice then
									neighborItem.order = 4
								else
									neighborItem.order = 3
								end
							end
						end
					table.insert(canJumpList[neighborItem.order],{r = checkRow,c = checkCol})
				end		
			end

			for index,jumpList in ipairs(canJumpList) do
				if #jumpList > 0 then
					jumpItem = jumpList[mainLogic.randFactory:rand(1, #jumpList)]
					break
				end
			end

			if jumpItem then
				local newOriItem = map[v.r][v.c]
				local newDestItem = map[jumpItem.r][jumpItem.c]
				newOriItem.hasJumped = true
				newDestItem.hasJumped = true
				map[jumpItem.r][jumpItem.c] = newOriItem
				map[v.r][v.c] = newDestItem
			end
		end
	end

	
	return map
	
end

function PuffedRiceLogic:_initInfoMap(map, mainLogic)
	local map = {}
	for r = 1, #mainLogic.gameItemMap do
		map[r] = {}
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			local board = mainLogic.boardmap[r][c]
			map[r][c] = {
				hasJumped = false,
				isPuffedRice = false,
				canBeSwap = false,
				order = 0,
				puffedRiceJumped = item.puffedRiceJumped,
				originR = r,
            	originC = c,
			}
            if item and item:canBeSwap() then
            	map[r][c].canBeSwap = true
				if board and board.puffedRiceLow then
					if item.ItemType == GameItemType.kpuffedRice then
						map[r][c].order = 7
						map[r][c].isPuffedRice = true
					else
						map[r][c].order = 6
					end
				elseif item.ItemType == GameItemType.kpuffedRice then
					map[r][c].order = 2
					map[r][c].isPuffedRice = true
				else
					map[r][c].order = 1
				end
			end		
		end
	end
	return map
end


function PuffedRiceLogic:refreshGameItemDataAfterPuffedRiceJump(mainLogic,moveMap)
	local newMap = {}
	for r = 1, #moveMap do
		for c = 1, #moveMap[r] do
			local item = moveMap[r][c]
            if item.originR ~= r or item.originC ~= c then
            	if not newMap[r] then newMap[r] = {} end
            	local newItemData = mainLogic.gameItemMap[item.originR][item.originC]:copy()
            	newMap[r][c] = newItemData
            end
		end
	end	


	for row, rowLists in pairs(newMap) do
		for col, copiedItem in pairs(rowLists) do
			local currItem = mainLogic:safeGetItemData(row, col)
			if copiedItem and currItem then
				currItem:getAnimalLikeDataFrom(copiedItem)
				if currItem.ItemType == GameItemType.kpuffedRice then
					currItem.puffedRiceMoveableSteps = currItem.puffedRiceMoveableSteps - 1
					if currItem.puffedRiceMoveableSteps == 0 then
						currItem.puffedRiceJumped = nil
					else
						if not currItem.puffedRiceJumped then
							currItem.puffedRiceJumped = {}
						end
						table.insert(currItem.puffedRiceJumped,{r = copiedItem.y, c = copiedItem.x})
					end
				end
				currItem:addFallingLockByPuffedRice()
				mainLogic:checkItemBlock(row, col) --临时锁掉落
				currItem.updateLaterByPuffedRice = true
			end
		end
	end
end

function PuffedRiceLogic:refreshAllBlockStateAfterPuffedRiceJump(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
			if targetItem then
				if targetItem.updateLaterByPuffedRice then
					targetItem.updateLaterByPuffedRice = false
					targetItem:removeFallingLockByPuffedRice()
					
					mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)
				end
			end
		end
	end
	FallingItemLogic:preUpdateHelpMap(mainLogic)
    mainLogic:setNeedCheckFalling()
end