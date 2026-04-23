NationalDayBunnyLogic = class{}

NationalDayBunnyLogic.BunnyType = {
	kNormal = 1, --普通兔子
	kSnow = 2, --雪兔子
	kFast = 3, --快速兔子
	kIce = 4, --冰兔子
	kHat = 5, --帽子兔子
}

NationalDayBunnyLogic.BunnyIconToType = {
	NationalDayBunnyLogic.BunnyType.kNormal,
	NationalDayBunnyLogic.BunnyType.kSnow,
	NationalDayBunnyLogic.BunnyType.kFast,
	NationalDayBunnyLogic.BunnyType.kIce,
	NationalDayBunnyLogic.BunnyType.kHat,
}

NationalDayBunnyLogic.ProduceNumLimit = {
	min = 2,
	max = 10,
}

NationalDayBunnyLogic.IconOffset = 20925


function NationalDayBunnyLogic:getBunnyType(iconType)
	iconType = iconType or 1
	return NationalDayBunnyLogic.BunnyIconToType[iconType]
end

function NationalDayBunnyLogic:getBunnyMove(iconType)
	if iconType == NationalDayBunnyLogic.BunnyType.kFast then 
		return 2
	else
		return 1
	end
end

function NationalDayBunnyLogic:getBunnySpecialSize(iconType) --一个顶N个的特殊兔子 帽子兔子
	if iconType == NationalDayBunnyLogic.BunnyType.kHat then 
		return true
	else
		return false
	end
end

function NationalDayBunnyLogic:isSkillableBunny(bunnyType)
	if bunnyType == NationalDayBunnyLogic.BunnyType.kSnow or
		bunnyType == NationalDayBunnyLogic.BunnyType.kIce then
		return true
	else
		return false
	end
end

function NationalDayBunnyLogic:getAllNDBunnyProducer(mainLogic)
	local allProducer = {}
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]
            if board and board.isNDBunnyProducer then
            	table.insert(allProducer, board)
            end
		end
	end
	return allProducer
end

function NationalDayBunnyLogic:getAllVisibleNDBunny(mainLogic)
	local allNDBunny = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item and item.ItemType == GameItemType.kNationalDayBunny 
            	and item:isAvailable() then
            	table.insert(allNDBunny, item)
            end
		end
	end
	return allNDBunny
end

function NationalDayBunnyLogic:getAllVisibleNDBunnyNum(mainLogic)
	local allNDBunny = {{},{},{},{},{}}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item and item.ItemType == GameItemType.kNationalDayBunny 
            	and item:isAvailable() then
            	table.insert(allNDBunny[item.NDBunnyType], item)
            end
		end
	end
	return allNDBunny
end

function NationalDayBunnyLogic:getAllToLeaveNDBunny(mainLogic)
	local allToLeaveBunny = {}
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]
            if board and board.isNDBunnyLeave then
            	if mainLogic.gameItemMap[r] and mainLogic.gameItemMap[r][c] then
            		local item = mainLogic.gameItemMap[r][c]
            		if item and item.ItemType == GameItemType.kNationalDayBunny then
            			table.insert(allToLeaveBunny, item)
            		end
            	end
            end
		end
	end
	return allToLeaveBunny
end



function NationalDayBunnyLogic:getProduceBunnyList(mainLogic)

	local finalList = {} --最终生成的列表
	local spareList = {} --可以供生成的列表
	local finalMinList = {} --因为棋盘最少补充的列表
	if not mainLogic.NDbunnyConfig or not mainLogic.NDbunnyGlobalConfig then
		return finalList,finalMinList
	end

	local CONFIGHAT = mainLogic.NDbunnyGlobalConfig.x or 1
	local globalDir = mainLogic.NDbunnyGlobalConfig.dir or 1
	local globalSnowLevel = mainLogic.NDbunnyGlobalConfig.carrot or 1
	local boardMaxNum = mainLogic.NDbunnyGlobalConfig.maxRabbitNum or 0	--棋盘（明面上）最多


	local allNdBunnyNum = NationalDayBunnyLogic:getAllVisibleNDBunnyNum(mainLogic)
	local NDBunnySumNum = #allNdBunnyNum[1] + #allNdBunnyNum[2] + #allNdBunnyNum[3] + #allNdBunnyNum[4] + #allNdBunnyNum[5]*CONFIGHAT
	local allowNum = boardMaxNum - NDBunnySumNum --棋盘上还允许生成几个
	local allowNumCopy = allowNum --备份一下allownum

	--if boardMaxNum ~= 0 and allowNum <= 0 then return finalList,finalMinList end --不允许生成就返回

	local globalConfigList = {}

	for i = NationalDayBunnyLogic.IconOffset + 1, NationalDayBunnyLogic.IconOffset + 5 do
		if not mainLogic.NDbunnyGlobalConfig[i] then
			mainLogic.NDbunnyGlobalConfig[i] = {
				p = 0,
				q = 0,
			}
		end
		globalConfigList[i] = {
				max = mainLogic.NDbunnyGlobalConfig[i].p,
				min = mainLogic.NDbunnyGlobalConfig[i].q,
				ready = #allNdBunnyNum[i-20925],
				now = #allNdBunnyNum[i-20925],
			}
	end

	for k,v in pairs(mainLogic.NDbunnyConfig) do

		--if boardMaxNum ~= 0 and allowNum <= 0 then break end

		local rc = string.split(k, '_')
		local r = tonumber(rc[1])
		local c = tonumber(rc[2])
		local curItem = mainLogic:safeGetItemData(r, c)
		local curBoard = mainLogic:safeGetBoardData(r, c)

		if not curBoard.NDBunnyNumData then
			curBoard.NDBunnyNumData = {}
		end
		local bunnyNumData = curBoard.NDBunnyNumData

		if curBoard and curBoard.isNDBunnyProducer and --这个兔子真的有生成口并且可生成
			curItem and curItem:isVisibleAndFree() and 
			(curItem.ItemType ~= GameItemType.kNationalDayBunny) and
			(curItem.ItemType ~= GameItemType.kNDBunnySnow) and 
			(curItem.ItemType ~= GameItemType.kNone) then

			local property
			local tempList = {} --所有能生成的格子
			local tempSpare = {} --所有不应该生成但是没生成满的格子

			for index,oneData in ipairs(v.data) do
				if property and property > oneData.w then
					break
				end
				if globalConfigList[oneData.key] and 
				(globalConfigList[oneData.key].max == 0 or globalConfigList[oneData.key].max > globalConfigList[oneData.key].now) then
					
					local produceMaxNum = oneData.t or 0 --本条最多生成多少个
					local unlockNum = oneData.n or 0 --每间隔n步，生成unlockNum

					if not bunnyNumData[tostring(oneData.key)] then
						bunnyNumData[tostring(oneData.key)] = {}
						bunnyNumData[tostring(oneData.key)].produceByStep = 0
						bunnyNumData[tostring(oneData.key)].produceByMin = 0
					end

					local sumGeneratedAmount = bunnyNumData[tostring(oneData.key)].produceByStep + bunnyNumData[tostring(oneData.key)].produceByMin --这个兔子通过步数+最小值总共生成了几只

					if produceMaxNum >= 0 then
						local leftNum = produceMaxNum - sumGeneratedAmount
						if (leftNum > 0 or produceMaxNum == 0) and unlockNum > 0 then --还有生成名额以及配了生成数量

							local totalUnlockNum = NationalDayBunnyLogic:getTotalUnlockNumOfCurrentStep(mainLogic, oneData.s, oneData.m, oneData.n) --当前步数理应生成的总数							
							local canProduce = (totalUnlockNum - bunnyNumData[tostring(oneData.key)].produceByStep) > 0
							local itemConfig = {}

							itemConfig.item = curItem
							itemConfig.board = curBoard
							itemConfig.k = k
							itemConfig.key = oneData.key
--							itemConfig.color = self:getColorByConfig(oneData.c,mainLogic)
							itemConfig.typeId = oneData.key - NationalDayBunnyLogic.IconOffset
							itemConfig.dir = self:getDirByConfigWithOutRandom(v.dir,mainLogic) or self:getDirByConfigWithRandom(globalDir,mainLogic)
							itemConfig.move = NationalDayBunnyLogic:getBunnyMove(itemConfig.typeId)
							itemConfig.hp = oneData.h
							if v.carrot and v.carrot > 0 then
								itemConfig.snowLevel = v.carrot
							else
								itemConfig.snowLevel = globalSnowLevel
							end
							if canProduce then
								property = oneData.w
								table.insert(tempList,itemConfig)
							else
								table.insert(tempSpare,itemConfig)
							end
						end
					end
				end
			end
			if #tempList > 0 then
				local hasBoss = false
				local readyOne
				for k,v in ipairs(tempList) do
					if self:getBunnySpecialSize(v.typeId) then
						hasBoss = true
						readyOne = v
						break
					end
				end
				if not hasBoss then
					readyOne = tempList[mainLogic.randFactory:rand(1, #tempList)]
				end
				table.insert(finalList,readyOne)
				globalConfigList[readyOne.key].now = globalConfigList[readyOne.key].now + 1
				if self:getBunnySpecialSize(readyOne.typeId) then
					allowNum = allowNum - CONFIGHAT
				else
					allowNum = allowNum - 1
				end
			else
				if tempSpare[1] then
					table.insert(spareList,tempSpare)
				end
			end
		end		
	end

	if boardMaxNum == 0 or allowNum > 0 then
		local shortList = {}
		for k,v in pairs(globalConfigList) do
			if v.now < v.min then
				table.insert(shortList,{
					key = k,
					num = v.min - v.now
				})
			end
		end

		local function checkKey(key)
			for k,v in pairs(shortList) do
				if v.key == key and v.num > 0 then
					return k
				end
			end
		end

		local function updateShortList()
			local newList = {}
			local notSame = false
			for k,v in pairs(shortList) do
				if v.num > 0 then
					table.insert(newList,v)
				else
					notSame = true
				end
			end
			if notSame then
				shortList = newList
			end

			return notSame
		end

		while #shortList ~= 0 do
			local firstList = {}
			for k,v in ipairs(spareList) do
				local secondList = {}
				local getIndex
				for k1,v1 in ipairs(v) do
					local tempIndex = checkKey(v1.key)
					if tempIndex then
						getIndex = tempIndex
						table.insert(secondList,v1)
					end
				end
				if #secondList == 1 then
					table.insert(finalMinList,secondList[1])
					shortList[getIndex].num = shortList[getIndex].num - 1
					if self:getBunnySpecialSize(secondList[1].typeId) then
						allowNum = allowNum - CONFIGHAT
					else
						allowNum = allowNum - 1
					end
					if boardMaxNum ~= 0 and allowNum <= 0 then break end
				elseif #secondList > 1 then
					table.insert(firstList,secondList)
				end
			end

			spareList = firstList
			if #spareList == 0 then break end
			if boardMaxNum ~= 0 and allowNum <= 0 then break end

			local notSame = updateShortList()
			if not notSame then
				local needEnd = false
				local newSpareList = {}
				table.randomOrder(spareList,mainLogic)
				for k,v in ipairs(spareList) do
					if needEnd then
						table.insert(newSpareList,v)
					else
						local secondList = {}
						local getIndex = checkKey(v[1].key)

						if getIndex then
							table.insert(finalMinList,v[1])
							shortList[getIndex].num = shortList[getIndex].num - 1
							if self:getBunnySpecialSize(v[1].typeId) then
								allowNum = allowNum - CONFIGHAT
							else
								allowNum = allowNum - 1
							end
							if boardMaxNum ~= 0 and allowNum <= 0 then break end
							if shortList[getIndex].num == 0 then
								needEnd = true
							end
						end
					end
				end
				spareList = newSpareList
			end
			if #spareList == 0 then break end
			if boardMaxNum ~= 0 and allowNum <= 0 then break end
		end
	elseif boardMaxNum ~= 0 and allowNum < 0 then
		local newFinalList = {}
		local otherList = {}
		local shortList = {}
		local moreNeedList = {}
		local lessNeedList = {}
		table.randomOrder(finalList,mainLogic)
		for k,v in ipairs(finalList) do
			if self:getBunnySpecialSize(v.typeId) then
				table.insert(newFinalList,v)
				allowNumCopy = allowNumCopy - CONFIGHAT
			else
				if globalConfigList[v.key].ready - globalConfigList[v.key].min < 0 then
					table.insert(moreNeedList,v)
					globalConfigList[v.key].ready = globalConfigList[v.key].ready + 1
				else
					table.insert(lessNeedList,v)
				end
			end
		end

		for k,v in ipairs(moreNeedList) do
			if allowNumCopy <= 0 then break end
			table.insert(newFinalList,v)
			allowNumCopy = allowNumCopy - 1
		end

		for k,v in ipairs(lessNeedList) do
			if allowNumCopy <= 0 then break end
			table.insert(newFinalList,v)
			allowNumCopy = allowNumCopy - 1
		end

		finalList = newFinalList
	end


	return finalList,finalMinList
end

--- 至今为止累计开放的生成数量 开始生成的步数 每几步 生成几个
function NationalDayBunnyLogic:getTotalUnlockNumOfCurrentStep(mainLogic, startStep, stepNum, unlockNum)
	local totalUnlockNum = 0

	if mainLogic.realCostMoveWithoutBackProp >= startStep then
		if mainLogic.realCostMoveWithoutBackProp == startStep then	--初始生成
			totalUnlockNum = unlockNum
		else
			totalUnlockNum = unlockNum * math.floor((mainLogic.realCostMoveWithoutBackProp - startStep) / math.max(stepNum, 1)) + unlockNum
		end
	end

	return totalUnlockNum
end

function NationalDayBunnyLogic:getColorByConfig(config,mainLogic)
	local colorList = {}
	if type(config) == "number" then
		colorList = {config}
	elseif type(config) == "table" then
		for k,v in pairs(config) do
			table.insert(colorList,k)
		end
	else
		return nil
	end

	if #colorList == 0 then
		colorList = {1,2,3,4,5,6}
	end
	return colorList[mainLogic.randFactory:rand(1, #colorList)]
end

function NationalDayBunnyLogic:getDirByConfigWithRandom(dir,mainLogic)
	local realDir = {}
	if type(dir) == "number" then
		realDir = {dir}
	elseif type(dir) == "table" then
		realDir = dir
	else
		realDir = {}
	end

	if #realDir == 0 then
		realDir = {1,2,3,4}
	end
	return realDir[mainLogic.randFactory:rand(1, #realDir)]
end

function NationalDayBunnyLogic:getDirByConfigWithOutRandom(dir,mainLogic)
	local realDir = {}
	if type(dir) == "number" then
		realDir = {dir}
	elseif type(dir) == "table" then
		realDir = dir
	else
		return nil
	end

	if #realDir == 0 then
		return nil
	end
	return realDir[1] --针对一个方向的临时修改
end


function NationalDayBunnyLogic:replaceItemToBunny(mainLogic, config)
	--- 赋予新格子相应属性
	local targetItem = config.item
	targetItem:cleanAnimalLikeData()
	targetItem.ItemType = GameItemType.kNationalDayBunny
	targetItem.NDBunnyType = config.typeId
	targetItem.NDBunnyHp = config.hp
	targetItem.NDBunnyFullHp = config.hp
	targetItem.NDBunnyMove = config.move
	targetItem.NDBunnyDir = config.dir
	targetItem.isEmpty = false
	targetItem.NDSnowBunnyReadyLevel = config.snowLevel
	-- targetItem._encrypt.ItemColorType = AnimalTypeConfig.convertIndexToColorType(config.color)
	--targetItem.isLockColorOnInit = true
	mainLogic:checkItemBlock(targetItem.y, targetItem.x)
	mainLogic:addNeedCheckMatchPoint(targetItem.y, targetItem.x)

end


function NationalDayBunnyLogic:getNDBunnyMoveMap(mainLogic)
	local skillList = {}
	local map = {}
	local boardMap = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item then 
            	if not map[r] then map[r] = {} end
            	local tempList = {}
            	tempList.bunnyType = item.NDBunnyType
            	tempList.ItemType = item.ItemType
            	tempList.originR = r
            	tempList.originC = c
            	tempList.dir = item.NDBunnyDir
            	tempList.move = item.NDBunnyMove
            	tempList.isUsed = item.isUsed
            	tempList.hp = item.NDBunnyHp
            	tempList.snowLevel = item.NDSnowBunnyReadyLevel
            	map[r][c] = tempList
            else
            	map[r][c] = {}
            end
            local board = mainLogic.boardmap[r][c]
        	if board then
        		if not boardMap[r] then boardMap[r] = {} end
        		local tempBoardList = {}
        		tempBoardList.hasIce = board.NDBunnyIceLevel > 0
        		tempBoardList.isLeave = board.isNDBunnyLeave
        		boardMap[r][c] = tempBoardList
        	else
        		boardMap[r][c] = {}
        	end
		end
	end

	--r是行 c是列 所以这个是从左到右

	for r = 1, #map do
		for c = 1, #map[r] do
			local item = map[r][c]
            if item and item.dir == DirConfig.kLeft then 
            	local moveNum = 1
            	local hasHelpedByIce = false
            	while moveNum <= item.move do
            		if map[r] and map[r][c-moveNum] and map[r][c-moveNum+1] and
            		boardMap[r] and boardMap[r][c-moveNum] and boardMap[r][c-moveNum+1] then
            			
	            		local itemLeft = map[r][c-moveNum]
	            		local boardNow = boardMap[r][c-moveNum+1]
	            		local boardLeft = boardMap[r][c-moveNum]

	            		if not hasHelpedByIce and boardLeft.hasIce then
	            			hasHelpedByIce = true
	            			item.move = item.move + 1
	            		end

	            		if itemLeft and itemLeft.isUsed and itemLeft.ItemType ~= GameItemType.kNationalDayBunny 
	            			and itemLeft.ItemType ~= GameItemType.kNDBunnySnow
	            			and itemLeft.ItemType ~= GameItemType.kNone
	            			and not boardNow.isLeave then

	            			map[r][c-moveNum+1] = itemLeft
	            			map[r][c-moveNum] = item
	            			moveNum = moveNum + 1
	            		else
	            			break
	            		end
	            	else
	            		break
	            	end
            	end
            	if moveNum > 1 then
            		self:checkSkill(item,skillList,r,c-moveNum+2)
            	end
            end
		end
	end

	for r = 1, #map do
		for c = #map[r], 1, -1  do
			local item = map[r][c]
            if item and item.dir == DirConfig.kRight then 
            	local moveNum = 1
 				local hasHelpedByIce = false

            	while moveNum <= item.move do
            		if map[r] and map[r][c+moveNum] and map[r][c+moveNum-1] and
            			boardMap[r] and boardMap[r][c+moveNum] and boardMap[r][c+moveNum-1] then

	            		local itemRight = map[r][c+moveNum]
						local boardNow = boardMap[r][c+moveNum-1]
	            		local boardRight = boardMap[r][c+moveNum]

	            		if not hasHelpedByIce and boardRight.hasIce then
	            			hasHelpedByIce = true
	            			item.move = item.move + 1
	            		end

	            		if itemRight and itemRight.isUsed and itemRight.ItemType ~= GameItemType.kNationalDayBunny 
	            			and itemRight.ItemType ~= GameItemType.kNDBunnySnow
	            			and itemRight.ItemType ~= GameItemType.kNone
	            			and not boardNow.isLeave then
	            			map[r][c+moveNum-1] = itemRight
	            			map[r][c+moveNum] = item
	            			moveNum = moveNum + 1
	            		else
	            			break
	            		end
	            	else
	            		break
	            	end
            	end
            	if moveNum > 1 then
            		self:checkSkill(item,skillList,r,c+moveNum-2)
            	end
            end
		end
	end

	for r = 1, #map do
		for c = 1, #map[r] do
			local item = map[r][c]
            if item and item.dir == DirConfig.kUp then 
            	local moveNum = 1
            	local hasHelpedByIce = false

            	while moveNum <= item.move do
            		if map[r-moveNum] and map[r-moveNum][c] and map[r-moveNum+1] and map[r-moveNum+1][c] and
            			boardMap[r-moveNum] and boardMap[r-moveNum][c] and boardMap[r-moveNum+1] and boardMap[r-moveNum+1][c] then
	            		
	            		local itemUp = map[r-moveNum][c]
	            		local boardNow = boardMap[r-moveNum+1][c]
	            		local boardUp = boardMap[r-moveNum][c]

	            		if not hasHelpedByIce and boardUp.hasIce then
	            			hasHelpedByIce = true
	            			item.move = item.move + 1
	            		end

	            		if itemUp and itemUp.isUsed and itemUp.ItemType ~= GameItemType.kNationalDayBunny 
	            			and itemUp.ItemType ~= GameItemType.kNDBunnySnow 
	            			and itemUp.ItemType ~= GameItemType.kNone
	            			and not boardNow.isLeave then
	            			map[r-moveNum+1][c] = itemUp
	            			map[r-moveNum][c] = item
	            			moveNum = moveNum + 1
	            		else
	            			break
	            		end
	            	else
	            		break
	            	end
            	end
            	if moveNum > 1 then
            		self:checkSkill(item,skillList,r-moveNum+2,c)
            	end
            end
		end
	end

	for r = #map, 1, -1 do
		for c = 1, #map[r] do
			local item = map[r][c]
            if item and item.dir == DirConfig.kDown then 
            	local moveNum = 1
            	local hasHelpedByIce = false

            	while moveNum <= item.move do
            		if map[r+moveNum] and map[r+moveNum][c] and map[r+moveNum-1] and map[r+moveNum-1][c] 
            			and boardMap[r+moveNum] and boardMap[r+moveNum][c] and boardMap[r+moveNum-1] and boardMap[r+moveNum-1][c] then
	            		
	            		local itemDown = map[r+moveNum][c]
	            		local boardNow = boardMap[r+moveNum-1][c]
	            		local boardDown = boardMap[r+moveNum][c]

	            		if not hasHelpedByIce and boardDown.hasIce then
	            			hasHelpedByIce = true
	            			item.move = item.move + 1
	            		end

	            		if itemDown and itemDown.isUsed and itemDown.ItemType ~= GameItemType.kNationalDayBunny 
	            			and itemDown.ItemType ~= GameItemType.kNDBunnySnow
	            			and itemDown.ItemType ~= GameItemType.kNone
	            			and not boardNow.isLeave then
	            			map[r+moveNum-1][c] = itemDown
	            			map[r+moveNum][c] = item
	            			moveNum = moveNum + 1
	            		else
	            			break
	            		end
	            	else
	            		break
	            	end
            	end
            	if moveNum > 1 then
            		self:checkSkill(item,skillList,r+moveNum-2,c)
            	end
            end
		end
	end

	return map, skillList
end


function NationalDayBunnyLogic:decreaseBunny(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end
	if item.ItemType == GameItemType.kNationalDayBunny then
		if item.NDBunnyHp <= 0 then return end
		item.NDBunnyHp = item.NDBunnyHp - times
		if item.NDBunnyHp < 0 then
			item.NDBunnyHp = 0
		end
		local decAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItem_NDBunny_Dec_Hp,
					IntCoord:create(c,r),
					nil,
					GamePlayConfig_MaxAction_time)
		decAction.actionTime = item.NDBunnyHp == 0 and 0 or 52
		decAction.hp = item.NDBunnyHp
		decAction.targetBunny = item
		mainLogic:addDestroyAction(decAction)
		mainLogic:setNeedCheckFalling()	
	end
end


function NationalDayBunnyLogic:decreaseBunnySnow(mainLogic, r, c, times, scoreScale)
	scoreScale = scoreScale or 1
	local item = mainLogic:safeGetItemData(r, c)
	if not item then return end
	if item.ItemType == GameItemType.kNDBunnySnow then
		if item.NDBunnySnowLevel <= 0 then return end
		item.NDBunnySnowLevel = item.NDBunnySnowLevel - times
		if item.NDBunnySnowLevel < 0 then
			item.NDBunnySnowLevel = 0
		end

		local decAction = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItem_NDBunnySnow_Dec,
			IntCoord:create(c,r),
			nil,
			GamePlayConfig_MaxAction_time)
		if item.NDBunnySnowLevel == 0 then
			decAction.actionTime = 21
		else
			decAction.actionTime = 42
		end
		decAction.level = item.NDBunnySnowLevel
		decAction.targetSnow = item
		mainLogic:addDestroyAction(decAction)
		mainLogic:setNeedCheckFalling()	

	end
end


function NationalDayBunnyLogic:decreaseBunnyIce(mainLogic, r, c)
	local item = mainLogic.gameItemMap[r][c]
	local board = mainLogic.boardmap[r][c]

	if board.NDBunnyIceLevel <= 0 then return end
	board.NDBunnyIceLevel = board.NDBunnyIceLevel - 1

	local decAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_NDBunnyIce_Dec,
		IntCoord:create(c,r),
		nil,
		GamePlayConfig_MaxAction_time)
	decAction.actionTime = 40
	decAction.level = board.NDBunnyIceLevel
	decAction.IceBoard = board
	decAction.IceItem = item
	mainLogic:addDestroyAction(decAction)
	mainLogic:setNeedCheckFalling()	

end

function NationalDayBunnyLogic:refreshGameItemDataAfterNDBunnyMove(mainLogic, moveMap)
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
			if mainLogic.gameItemMap[row] and mainLogic.gameItemMap[row][col] then
				local currItem = mainLogic.gameItemMap[row][col]
				currItem:getAnimalLikeDataFrom(copiedItem)
				currItem:addFallingLockByNDBunny()
				mainLogic:checkItemBlock(row, col) --临时锁掉落
				currItem.updateLaterByNDBunny = true
			end
		end
	end

end


function NationalDayBunnyLogic:refreshAllBlockStateAfterNDBunnyMove(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
			if targetItem then
				if targetItem.updateLaterByNDBunny then
					targetItem.updateLaterByNDBunny = false
					targetItem:removeFallingLockByNDBunny()

					mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)

					-- if targetItem.ItemType == GameItemType.kCuckooBird then
					-- 	if mainLogic.boardView and mainLogic.boardView.baseMap and mainLogic.boardView.baseMap[r] then
					-- 		local itemView = mainLogic.boardView.baseMap[r][c]
					-- 		if itemView then
					-- 			itemView:playCuckooBirdBackToIdle()
					-- 		end
					-- 	end
					-- end
				end
			end
		end
	end
	FallingItemLogic:preUpdateHelpMap(mainLogic)
    mainLogic:setNeedCheckFalling()
end

function NationalDayBunnyLogic:checkSkill(item,skillList,r,c)
	if item.ItemType == GameItemType.kNationalDayBunny and
		(item.bunnyType == NationalDayBunnyLogic.BunnyType.kSnow or item.bunnyType == NationalDayBunnyLogic.BunnyType.kIce) then
			table.insert(skillList,{r = r, c = c, bunnyType = item.bunnyType, snowLevel = item.snowLevel, dir = item.dir})
	end
end

function NationalDayBunnyLogic:releaseSkill(mainLogic, skillList)
	for k,v in ipairs(skillList) do
		local curItem = mainLogic:safeGetItemData(v.r, v.c)
		local curBoard = mainLogic:safeGetBoardData(v.r, v.c)
		if curItem then
			if v.bunnyType == NationalDayBunnyLogic.BunnyType.kSnow then
				if curItem.ItemType == GameItemType.kAnimal then
					curItem:cleanAnimalLikeData()
					curItem.ItemType = GameItemType.kNDBunnySnow
					curItem.NDBunnySnowLevel = v.snowLevel
					curItem.isEmpty = false
					curItem:addFallingLockByNDBunny()
					curItem.updateLaterByNDBunny = true
					mainLogic:checkItemBlock(curItem.y, curItem.x)
				end
			end
		end
		if curBoard then
			if v.bunnyType == NationalDayBunnyLogic.BunnyType.kIce then
				if curItem and not curItem.isUsed then return end
				if curBoard.NDBunnyIceLevel ~= 1 then
					curBoard.NDBunnyIceLevel = 1
					curBoard.isNeedUpdate = true
					if curItem then
						curItem.isNeedUpdate = true
					end
				end
			end
		end
	end
end

function NationalDayBunnyLogic:hasAnyBunnyLeave(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end
	if mainLogic.bunnyLeaveFlag then
		return true
	end
	return false
end

function NationalDayBunnyLogic:checkNDBunnyGuide(mainLogic,onlyRemove)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return false end

	local map = {}
	local leaveList = {}

	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local view = mainLogic.boardView:safeGetItemView(r, c)
			if view then
				view:removeNDBunnyDangerTip()
			end
			if not onlyRemove then
				if not map[r] then map[r] = {} end
				map[r][c] = false

				local board = mainLogic.boardmap[r][c]
	            if board and board.isNDBunnyLeave then
	            	table.insert(leaveList,{r = r, c = c})
	            end
	        end
		end
	end

	if onlyRemove then return end

	local dir
	if mainLogic and mainLogic.NDbunnyGlobalConfig then
		local globalDir
		local globalConfig = mainLogic.NDbunnyGlobalConfig
		if globalConfig then
			globalDir = NationalDayBunnyLogic:getDirByConfigWithOutRandom(globalConfig.dir,mainLogic)
		end
		if globalDir then
			dir = globalDir
		end
	end

	dir = dir or 1

	for k,v in ipairs(leaveList) do
		local hasIce = false
		local itemCurrent = mainLogic:safeGetItemData(v.r, v.c)
		if itemCurrent and 
		(itemCurrent.ItemType == GameItemType.kNDBunnySnow or
		itemCurrent.ItemType == GameItemType.kNone) then 
		else
			local offset = {{0,1},{0,-1},{1,0},{-1,0}}
			for i = 1,3 do
				local newItem = mainLogic:safeGetItemData(v.r+offset[dir][2]*i, v.c+offset[dir][1]*i)
				if newItem then
					if newItem.ItemType == GameItemType.kNDBunnySnow or
						newItem.ItemType == GameItemType.kNone or
						not newItem.isUsed
					then break end 
					if newItem.ItemType == GameItemType.kNationalDayBunny then
						local move = (hasIce and 1 or 0) + newItem.NDBunnyMove
						if move >= i then
							local curGrid = i
							while curGrid >= 0 do
								map[v.r+offset[dir][2]*curGrid][v.c+offset[dir][1]*curGrid] = true
								curGrid = curGrid - 1
							end
						end
						break
					end
				end
				local newBoard = mainLogic:safeGetBoardData(v.r+offset[dir][2]*i, v.c+offset[dir][1]*i)
				if newBoard and newBoard.NDBunnyIceLevel > 0 then
					hasIce = true
				end
				
			end
		end

	end


	for r = 1, #map do
		for c = 1, #map[r] do
			if map[r][c] then
				local view = mainLogic.boardView:safeGetItemView(r, c)
				if view then
					view:playNDBunnyDangerTip()
				end
			end
		end
	end

end