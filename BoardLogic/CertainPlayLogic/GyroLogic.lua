
GyroLogic = class{}

------------------------------------------------------------------------------------------------------------
--												GENERATE
------------------------------------------------------------------------------------------------------------
--检测删除生成器
function GyroLogic:gyroCreaterRemoveCheck(mainLogic)

	local allCreater = GyroLogic:_getAllGyroCreater(mainLogic, true)
	local finalRemoveList = {}
	for i,v in ipairs(allCreater) do
		local produceMaxNum = v.gyroCreaterData.produceMaxNum or 0
		local unlockNum = v.gyroCreaterData.unlockNum or 0

		local sumGeneratedAmount = v.gyroGeneratedByStep + v.gyroGeneratedByBoardMin
		if produceMaxNum > 0 then
			if sumGeneratedAmount >= produceMaxNum then
				-- printx(11, "gyro produce reached max")
				local temp = {}
				temp.gyroCreaterPos = IntCoord:create(v.y,v.x) --r,c
				table.insert( finalRemoveList, temp )
			end
		end
	end

	-- printx(12,"finalRemoveList",table.tostring(finalRemoveList))
	return finalRemoveList
end

---检测生成陀螺 如果可以生成陀螺，生成多少个
function GyroLogic:getGenerateGyroAmountIfNeeded(mainLogic)
	-- printx(11, "= = = = = Try calculate gyro generate amount. = = = = =")
	if not mainLogic.GyroConfig then
		return {}
	end

	-- local stepNum = mainLogic.GyroConfig.stepNum or 0		--每隔几步
	-- local unlockNum = mainLogic.GyroConfig.unlockNum or 0		--开放几只吃豆人
	local boardMaxNum = mainLogic.GyroConfig.boardMaxNum or 0		--棋盘（明面上）最多
	local boardMinNum = mainLogic.GyroConfig.boardMinNum or 0		--棋盘（明面上）最少，如果不达到，无视unlockNum生成至达到
	-- local produceMaxNum = mainLogic.GyroConfig.produceMaxNum or 0		--总共生成上限

	local generateNumByBoardMin = 0 --不满足棋盘最小值的时候 需要补充创建的数量
	local generateNumMinUseNum = 0 --最小已使用数 最小是共用的。
	local generateNumMaxUseNum = 0 --最大已使用数 最大是共用的

	local boardCurrAmount = 0 --当前棋盘拥有的陀螺数量
	if boardMinNum > 0 or boardMaxNum > 0 then
		boardCurrAmount = #GyroLogic:_getAllVisibleGyroOnBoard(mainLogic)
	end

	if boardMinNum > 0 and boardCurrAmount < boardMinNum then
		generateNumByBoardMin = boardMinNum - boardCurrAmount
		-- printx(11, "+ + + generate by boardMinNum. generateAmount:", generateNumByBoardMin)
	end

	local allCreater = GyroLogic:_getAllGyroCreater(mainLogic, true)

	--打乱creater顺序
	allCreater = table.randomOrder(allCreater, mainLogic)

	local finalgenerateList = {}
	for i,v in ipairs(allCreater) do

		local bContinue = false

		local real_generateNumByBoardMin = generateNumByBoardMin - generateNumMinUseNum --找出最小可以使用的数量  排除别的生成器使用的
		local real_boardMaxNum = boardMaxNum - generateNumMaxUseNum
		local generateNumByStep = 0 --步数达到要求需要创建的数量
		local toProduceMaxGap = 0 --当前到最大生成数之间的差值 也就是还可以生成陀螺
		local produceMaxNum = v.gyroCreaterData.produceMaxNum or 0
		local unlockNum = v.gyroCreaterData.unlockNum or 0

		local sumGeneratedAmount = v.gyroGeneratedByStep + v.gyroGeneratedByBoardMin
		if produceMaxNum > 0 then
			if sumGeneratedAmount >= produceMaxNum then
				-- printx(11, "gyro produce reached max")
				bContinue = true
			else
				toProduceMaxGap = produceMaxNum - sumGeneratedAmount
			end
		end

		if not bContinue then
			if unlockNum > 0 then
				local totalUnlockNum = GyroLogic:_getTotalUnlockNumOfCurrStep(mainLogic,v) --当前步数理应生成的总数

				-- printx(11, "curr totalUnlockNum:", totalUnlockNum)
				-- printx(11, "curr gyroGeneratedByStep:", mainLogic.gyroGeneratedByStep)
				if v.gyroGeneratedByStep < totalUnlockNum then
					generateNumByStep = totalUnlockNum - v.gyroGeneratedByStep
					-- printx(11, "+ + + generate by step. generateAmount:", generateNumByStep)
					if real_boardMaxNum > 0 then
						generateNumByStep = math.min(generateNumByStep, math.max(real_boardMaxNum - boardCurrAmount - real_generateNumByBoardMin, 0))
						-- printx(11, "- - - cutted by boardMaxNum. generateAmount:", generateNumByStep)
					end
				end
			end

			--如果生产总数未达到 当前可生成的大于可以上产的最大值
			if toProduceMaxGap > 0 and (real_generateNumByBoardMin + generateNumByStep) > toProduceMaxGap then
				real_generateNumByBoardMin = math.min(real_generateNumByBoardMin, toProduceMaxGap)
				generateNumByStep = math.min(generateNumByStep, toProduceMaxGap - real_generateNumByBoardMin)
				-- printx(11, "cutted by toProduceMaxGap. generateNumByBoardMin:", generateNumByBoardMin)
				-- printx(11, "cutted by toProduceMaxGap. generateNumByStep:", generateNumByStep)
			end

			local temp = {}
			temp.generateNumByBoardMin = real_generateNumByBoardMin
			temp.generateNumByStep = generateNumByStep
			temp.gyroCreaterPos = IntCoord:create(v.y,v.x) --r,c
			table.insert( finalgenerateList, temp )

			--公共最小计数
			generateNumMinUseNum = generateNumMinUseNum + real_generateNumByBoardMin
			generateNumMaxUseNum = generateNumMaxUseNum + real_generateNumByBoardMin + generateNumByStep
		end
	end


	--这里生成的数据 都是对应当前棋盘未生成任何陀螺的时候的数据。具体生成的时候需要按照棋盘最大最小生成
	-- printx(12,"finalgenerateList",table.tostring(finalgenerateList))
	return finalgenerateList
end

function GyroLogic:getGenerateGyroList(mainLogic)
	if not mainLogic.GyroConfig then
		return {},{}
	end

	local boardMaxNum = mainLogic.GyroConfig.boardMaxNum or 0		--棋盘（明面上）最多
	local boardMinNum = mainLogic.GyroConfig.boardMinNum or 0		--棋盘（明面上）最少，如果不达到，无视unlockNum生成至达到
	local generateByStepList = {{},{},{}} --因为步数生成的陀螺格子列表
	local gridFlag = {}
	local generateSpare = {{},{},{}} --备用的陀螺格子列表-防止不够最小值
	local boardCurrAmount = 0 --当前棋盘拥有的陀螺数量
	if boardMinNum > 0 or boardMaxNum > 0 then
		boardCurrAmount = #GyroLogic:_getAllVisibleGyroOnBoard(mainLogic)
	end
	--printx(14,"棋盘最多",boardMaxNum,"棋盘最少",boardMinNum,"当前棋盘陀螺数量",boardCurrAmount)
	local allCreater = GyroLogic:_getAllGyroCreater(mainLogic, true)

	--打乱creater顺序
	allCreater = table.randomOrder(allCreater, mainLogic)

	--local finalgenerateList = {}
	for i,v in ipairs(allCreater) do

		local produceMaxNum = v.gyroCreaterData.produceMaxNum or 0 --本只陀螺最多生成多少个
		local unlockNum = v.gyroCreaterData.unlockNum or 0 --每间隔n步，生成unlockNum

		local sumGeneratedAmount = v.gyroGeneratedByStep + v.gyroGeneratedByBoardMin --这个陀螺通过步数+最小值总共生成了几只
		--printx(14,"开始检索第",i,"只陀螺",produceMaxNum,unlockNum,v.gyroGeneratedByStep,v.gyroGeneratedByBoardMin)
		if produceMaxNum >= 0 then
			local leftNum = produceMaxNum - sumGeneratedAmount
			if (leftNum > 0 or produceMaxNum == 0) and unlockNum > 0 then --还有生成名额以及配了生成数量
				--printx(14,"还有生成名额",leftNum)
				local totalUnlockNum = GyroLogic:_getTotalUnlockNumOfCurrStep(mainLogic,v) --当前步数理应生成的总数
				--printx(14,"当前步数理应生成的总数",totalUnlockNum)
				local needGenerateNum = totalUnlockNum - v.gyroGeneratedByStep
				local list = self:_getOneGridCanGenerateList(mainLogic, v)
				local newList = {{},{},{}}
				for index,listItem in ipairs(list) do
					if not gridFlag[listItem.row] then
						gridFlag[listItem.row] = {}
					end
					if not gridFlag[listItem.row][listItem.col] then
						table.insert(newList[listItem.priority],listItem)
						gridFlag[listItem.row][listItem.col] = true
						--printx(14,listItem.row,listItem.col,"这个地方已经生成陀螺")
					end
				end
				for priorityNum,newListItem in ipairs(newList) do
					for index,realItem in ipairs(newListItem) do
						if leftNum > 0 or produceMaxNum == 0 then
							if needGenerateNum > 0 then
								needGenerateNum = needGenerateNum - 1
								--printx(14,"步数插入item",realItem.row,realItem.col)
								table.insert(generateByStepList[priorityNum],realItem)
							else
								table.insert(generateSpare[priorityNum],realItem)
								--printx(14,"替补item",realItem.row,realItem.col)
							end
							leftNum = leftNum - 1
						end
					end		
				end
			end
		end
	end

	local function unionTable(t1,t2,t3)
		 local t = {}
	    for i, v in ipairs(t1) do table.insert(t, v) end
	    for i, v in ipairs(t2) do table.insert(t, v) end
	    for i, v in ipairs(t3) do table.insert(t, v) end
	    return t
	end


	local function insertItem(itemParent,itemTable)
		if itemParent and itemParent.item then
			itemParent.item.gyroDirection = itemParent.gyroDirection
			itemParent.item.gyroLevel = itemParent.gyroLevel
			itemParent.item.gyroCreaterPos = itemParent.gyroCreaterPos
			itemParent.item.gyroCreaterNextDirection = itemParent.gyroCreaterNextDirection
			table.insert(itemTable,itemParent.item)

			local targetItem = mainLogic:getGameItemAt(itemParent.gyroCreaterPos.x, itemParent.gyroCreaterPos.y)
			if targetItem and targetItem.ItemType == GameItemType.kGyroCreater then
				targetItem.gyroCreaterCurDirector = itemParent.gyroCreaterNextDirection
				local targetItemPos = IntCoord:create(itemParent.y,itemParent.x)-- r,c
				table.insert( targetItem.gyroCreaterChildList, targetItemPos)
			end
		end
	end
	local tempList1 = unionTable(generateByStepList[1],generateByStepList[2],generateByStepList[3])
	local tempList2 = unionTable(generateSpare[1],generateSpare[2],generateSpare[3])

	local realGenerateNumByStep = #tempList1
	local finalList = {}
	local finalSpareList = {}

	local currentMaxGenerateNum = boardMaxNum - boardCurrAmount
	local currentMinGenerateNum = boardMinNum - boardCurrAmount
	--printx(14,"优先级123分别为",num1,num2,num3,"最大，最小，当前分别为",currentMaxGenerateNum,currentMinGenerateNum,realGenerateNumByStep)
	if realGenerateNumByStep > currentMaxGenerateNum and boardMaxNum ~= 0 then
		for i = 1,currentMaxGenerateNum do
			if tempList1[i] then
				insertItem(tempList1[i],finalList)
			end
		end
	elseif realGenerateNumByStep < currentMinGenerateNum then
		for i, v in ipairs(tempList1) do 
			insertItem(v,finalList)
		end
		local shortNum = currentMinGenerateNum - realGenerateNumByStep
		for i = 1,shortNum do
			if tempList2[i] then
				insertItem(tempList2[i],finalSpareList)
			end
		end
	else
		for i, v in ipairs(tempList1) do 
			insertItem(v,finalList)
		end
	end
	return finalList,finalSpareList
end

function GyroLogic:_getOneGridCanGenerateList(mainLogic,GyroCreater)
	local row, col = GyroCreater.y, GyroCreater.x 
	local gyroCreaterItem = mainLogic:getGameItemAt(row,col)

	local srcList = { 1,2,3,4 }
	local firstPos = gyroCreaterItem.gyroCreaterCurDirector
	if firstPos == 0 then firstPos = 1 end

	local newList = {}
	for i = firstPos, 4 do
		table.insert( newList, i)
	end

	for i = 1, firstPos-1 do
		table.insert( newList, i)
	end
	--去掉不支持的方向
	local supportDir = {}
	for i,v in pairs(gyroCreaterItem.gyroCreaterData.colourData) do
		if v then
			table.insert(supportDir,tonumber(i))
		end
	end

	--找出最终支持的方向
	local finalSupportList = {}
	for i,v in ipairs(newList) do
		if table.exist(supportDir, v) then
			table.insert(finalSupportList, v)
		end
	end
	--printx(14,"最终支持的方向",table.tostring(finalSupportList))

	local aroundX = {0, 1, 0, -1}
	local aroundY = {-1, 0, 1, 0}
	local findCreateList = {}
	for i,v in ipairs(finalSupportList) do
		local currCol = col + aroundX[v]
		local currRow = row + aroundY[v]
		local locationKey = currCol..","..currRow

		if not mainLogic:hasChainInNeighbors(row, col, currRow, currCol) then
			local item = mainLogic:getGameItemAt(currRow, currCol)
			if item then

				local isCanReplace, priority = GyroLogic:_isReplaceableItemForGenerateGyro(item)
				--printx(14,"这个地方可以生成并且有item",isCanReplace,priority,currRow,currCol,finalSupportList[i+1] or finalSupportList[1])
				if isCanReplace then
					local info = {}
					info.row = currRow
					info.col = currCol
					info.item = item
					info.gyroDirection = v
					info.gyroLevel = 0
					info.gyroCreaterPos = IntCoord:create(row,col)
					info.gyroCreaterNextDirection = finalSupportList[i+1] or finalSupportList[1]
					info.priority = priority
					table.insert(findCreateList, info )
				end
			end
		end
	end
	return findCreateList
end


--- 至今为止累计开放的生成数量
function GyroLogic:_getTotalUnlockNumOfCurrStep(mainLogic,GyroCreater)
	local totalUnlockNum = 0

	local stepNum = GyroCreater.gyroCreaterData.stepNum or 0		--每隔几步
	local unlockNum = GyroCreater.gyroCreaterData.unlockNum or 0		--开放几只吃豆人

	-- printx(11, "realCostMoveWithoutBackProp, stepNum", mainLogic.realCostMoveWithoutBackProp, stepNum)
	if mainLogic.realCostMoveWithoutBackProp >= stepNum then
		if mainLogic.realCostMoveWithoutBackProp == 0 then	--进入游戏就有生成
			totalUnlockNum = unlockNum
		else
			totalUnlockNum = unlockNum * math.floor(mainLogic.realCostMoveWithoutBackProp / math.max(stepNum, 1))
			if stepNum == 0 then	--初始生成的话，要加上一轮
				totalUnlockNum = totalUnlockNum + unlockNum
			end
		end
	end

	return totalUnlockNum
end

function GyroLogic:_getAllVisibleGyroOnBoard(mainLogic)
	local allGyro = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item and item.ItemType == GameItemType.kGyro 
            	and item:isAvailable() then
            	table.insert(allGyro, item)
            end
		end
	end
	return allGyro
end

function GyroLogic:pickGenerateTargets(mainLogic, finalgenerateList )

	local pickedTargets = {}

	local allCreater = GyroLogic:_getAllGyroCreater(mainLogic, true)
	if #allCreater > 0 then
		local pickedPos = {}
		for _, den in ipairs(allCreater) do

			local bContinue = false
			local candidateTargets = {}

			local row, col = den.y, den.x

			local finalgenerateListIndex = 0
			for i,v in ipairs(finalgenerateList) do
				if v.gyroCreaterPos.x == row and v.gyroCreaterPos.y == col then
					finalgenerateListIndex = i
					break
				end
			end

			if finalgenerateListIndex == 0 then
				bContinue = true
			end

			if not bContinue then 
				local generateInfo = finalgenerateList[finalgenerateListIndex]

				local needAmount = generateInfo.generateNumByBoardMin + generateInfo.generateNumByStep

				local row, col = den.y, den.x
				--- 上右下左
				local aroundX = {0, 1, 0, -1}
				local aroundY = {-1, 0, 1, 0}

				local gyroCreaterItem = mainLogic:getGameItemAt(row,col)

				--先从指定位置找 找不到依次往下
				local srcList = { 1,2,3,4 }
				local firstPos = gyroCreaterItem.gyroCreaterCurDirector
				if firstPos == 0 then firstPos = 1 end
				local newList = {}
				for i = firstPos, 4 do
					table.insert( newList, i)
				end

				for i = 1, firstPos-1 do
					table.insert( newList, i)
				end

				--去掉不支持的方向
				local supportDir = {}
				for i,v in pairs(gyroCreaterItem.gyroCreaterData.colourData) do
					if v then
						table.insert(supportDir,tonumber(i))
					end
				end

				--找出最终支持的方向
				local finalSupportList = {}
				for i,v in ipairs(newList) do
					if table.exist(supportDir, v) then
						table.insert(finalSupportList, v)
					end
				end


				-- printx(12,"gyroCreaterItem.gyroCreaterCurDirector",col, row, gyroCreaterItem.gyroCreaterCurDirector, firstPos)
				-- printx(12,"gyroCreaterItem.gyroCreaterData",table.tostring(gyroCreaterItem.gyroCreaterData))
				-- printx(12,"newList",table.tostring(newList))
				-- printx(12,"supportDir",table.tostring(supportDir))
				-- printx(12,"finalSupportList",table.tostring(finalSupportList))

				local findCreatePriorityList = {}
				--当前优先级支持到3
				for i=1, 3 do
					findCreatePriorityList[i] = {}
				end

				for i,v in ipairs(finalSupportList) do
					local currCol = col + aroundX[v]
					local currRow = row + aroundY[v]
					local locationKey = currCol..","..currRow

					if not pickedPos[locationKey] and not mainLogic:hasChainInNeighbors(row, col, currRow, currCol) then
						local item = mainLogic:getGameItemAt(currRow, currCol)
						if item then
							local isCanReplace, priority = GyroLogic:_isReplaceableItemForGenerateGyro(item)
							if isCanReplace then

								local info = {}
								info.Row = currRow
								info.Col = currCol
								info.item = item
								info.locationKey = locationKey
								info.gyroDirection = v
								info.gyroCreaterPos = IntCoord:create(row,col)
								info.gyroCreaterNextDirection = finalSupportList[i+1] or finalSupportList[1]
								table.insert( findCreatePriorityList[priority], info )

								-- item.gyroDirection = v --初始生成的方向
								-- item.gyroLevel = 0 --初始等级
								-- item.gyroCreaterPos = IntCoord:create(row,col)
								-- item.gyroCreaterNextDirection = finalSupportList[i+1] or finalSupportList[1]

								-- table.insert(candidateTargets, item)
								-- pickedPos[locationKey] = true
								-- break
							end
						end
					end
				end

				for i=1, #findCreatePriorityList do
					for j=1, #findCreatePriorityList[i] do
						local item = findCreatePriorityList[i][j].item
						local locationKey = findCreatePriorityList[i][j].locationKey
						local gyroDirection = findCreatePriorityList[i][j].gyroDirection
						local gyroCreaterPos = findCreatePriorityList[i][j].gyroCreaterPos
						local gyroCreaterNextDirection = findCreatePriorityList[i][j].gyroCreaterNextDirection

						local itemInfo = {}
						itemInfo.gyroDirection = gyroDirection --初始生成的方向
						itemInfo.gyroLevel = 0 --初始等级
						itemInfo.gyroCreaterPos = gyroCreaterPos
						itemInfo.gyroCreaterNextDirection = gyroCreaterNextDirection
						itemInfo.item = item

						table.insert(candidateTargets, itemInfo)
						pickedPos[locationKey] = true
					end 
				end

				--生成
				local pickAmount = math.min(#candidateTargets, needAmount)
				if pickAmount > 0 then
					for j = 1, pickAmount do
						local targetItem = candidateTargets[j].item
						if targetItem then
							targetItem.gyroDirection = candidateTargets[j].gyroDirection
							targetItem.gyroLevel = candidateTargets[j].gyroLevel
							targetItem.gyroCreaterPos = candidateTargets[j].gyroCreaterPos
							targetItem.gyroCreaterNextDirection = candidateTargets[j].gyroCreaterNextDirection
						end

						local Item = mainLogic:getGameItemAt(targetItem.gyroCreaterPos.x, targetItem.gyroCreaterPos.y)
						if Item and Item.ItemType == GameItemType.kGyroCreater then
							Item.gyroCreaterCurDirector = targetItem.gyroCreaterNextDirection
							local targetItemPos = IntCoord:create(targetItem.y,targetItem.x)-- r,c
							table.insert( Item.gyroCreaterChildList, targetItemPos)
						end
						table.insert(pickedTargets, targetItem)
					end
				end
			end
		end
	end

	return pickedTargets
end

function GyroLogic:_getAllGyroCreater(mainLogic, isAvailableOnly)
	local allGyroCreater = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item and item.ItemType == GameItemType.kGyroCreater then
            	if not isAvailableOnly or item:isVisibleAndFree() then
	            	table.insert(allGyroCreater, item)
	            end
            end
		end
	end
	return allGyroCreater
end

function GyroLogic:_isReplaceableItemForGenerateGyro(item)
	if not item.isEmpty and item:isVisibleAndFree() then
		local priority = 1
		if item.ItemType == GameItemType.kCrystal then
			return true, priority
		-- elseif item.ItemType == GameItemType.kAnimal and item.ItemSpecialType == 0 then
		elseif item.ItemType == GameItemType.kAnimal then
			if  item.ItemSpecialType == AnimalTypeConfig.kWrap
		        or item.ItemSpecialType == AnimalTypeConfig.kLine 
		        or item.ItemSpecialType == AnimalTypeConfig.kColumn  then
				priority = 2
			elseif item.ItemSpecialType == AnimalTypeConfig.kColor then
				priority = 3
			end
			return true, priority
		end
	end
	return false
end

function GyroLogic:updateNewGyro(mainLogic, targetItem)

	GyroLogic:_addDevouredItemAsRemoved(mainLogic, targetItem, targetItem)

	--- 赋予新格子相应属性
	targetItem.ItemType = GameItemType.kGyro
	-- printx(11, " = = = updateNewGyro at ("..targetItem.x..","..targetItem.y..")")
	-- printx(11, "setGyroColour. old("..targetItem.x..","..targetItem.y.."):"..targetItem.gyroColour..", new("..oldGyro.x..","..oldGyro.y.."):"..oldGyro.gyroColour)
	targetItem.isEmpty = false
	targetItem.isBlock = true
	targetItem._encrypt.ItemColorType = 0
	targetItem.ItemSpecialType = 0
	targetItem.isNeedUpdate = true

	mainLogic:checkItemBlock(targetItem.y, targetItem.x)
end

------------------------------------------------------------------------------------------------------------
--												EAT
------------------------------------------------------------------------------------------------------------
function GyroLogic:gyroIsFull(mainLogic, item)
	local devourAmount = item.gyroDevourAmount
	local maxDevourAmount = (mainLogic.GyroConfig and mainLogic.GyroConfig.devourCount) or 1
	if devourAmount >= maxDevourAmount then
		return true
	end
	return false
end

-- function GyroLogic:updateGyroPosition(mainLogic, oldGyro, targetItem, gyroCollection)

-- 	GyroLogic:_addDevouredItemAsRemoved(mainLogic, oldGyro, targetItem)

-- 	--- 删除老格子的吃豆人属性
-- 	oldGyro.ItemType = GameItemType.kNone

-- 	--- 赋予新格子相应属性
-- 	targetItem.ItemType = GameItemType.kGyro
-- 	-- printx(11, "+ + + updateGyroPosition to ("..targetItem.x..","..targetItem.y..")")
-- 	-- printx(11, "setGyroColour. old("..targetItem.x..","..targetItem.y.."):"..targetItem.gyroColour..", new("..oldGyro.x..","..oldGyro.y.."):"..oldGyro.gyroColour)
-- 	targetItem.gyroColour = oldGyro.gyroColour
-- 	targetItem.gyroDevourAmount = oldGyro.gyroDevourAmount + 1
-- 	targetItem.gyroIsSuper = oldGyro.gyroIsSuper

-- 	targetItem.isEmpty = false
-- 	targetItem.isBlock = true
-- 	targetItem._encrypt.ItemColorType = 0
-- 	targetItem.ItemSpecialType = 0
-- 	targetItem.isNeedUpdate = true

-- 	if gyroCollection then
-- 		table.removeValue(gyroCollection, oldGyro)
-- 		table.insert(gyroCollection, targetItem)
-- 	end
-- end

--- 虽然是被吃掉了，但是需要加上被消除的效果（但不触发特效）
function GyroLogic:_addDevouredItemAsRemoved(mainLogic, oldGyro, targetItem)

	-- local r, c = targetItem.y, targetItem.x
	
	-- local addScore = GamePlayConfigScore.MatchDeletedBase
	-- if targetItem.ItemType == GameItemType.kAnimal then
	-- 	if targetItem.ItemSpecialType ~= 0 then
	-- 		-- oldGyro.gyroIsSuper = 0	--动画先不更新，故先置为0

	-- 		if targetItem.ItemSpecialType == AnimalTypeConfig.kLine or targetItem.ItemSpecialType == AnimalTypeConfig.kColumn then
	-- 			mainLogic:tryDoOrderList(r, c, GameItemOrderType.kSpecialBomb, GameItemOrderType_SB.kLine)
	-- 			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r, c, Blocker195CollectType.kLine)
	-- 			SquidLogic:checkSquidCollectItem(mainLogic, r, c, SquidCollectType[1])	--直线特效没有自己的大类型，故在SquidCollectType中获取特殊代号
	-- 			addScore = GamePlayConfigScore.SpecialBombkLine
	-- 		elseif targetItem.ItemSpecialType == AnimalTypeConfig.kWrap then
	-- 			mainLogic:tryDoOrderList(r, c, GameItemOrderType.kSpecialBomb, GameItemOrderType_SB.kWrap)
	-- 			GameExtandPlayLogic:doAllBlocker195Collect(mainLogic, r, c, Blocker195CollectType.kWrap)
	-- 			SquidLogic:checkSquidCollectItem(mainLogic, r, c, SquidCollectType[2])	--爆炸特效没有自己的大类型，故在SquidCollectType中获取特殊代号
	-- 			addScore = GamePlayConfigScore.SpecialBombkWrap
	-- 		end
	-- 	end
	-- elseif targetItem.ItemType == GameItemType.kCrystal then
	-- 	addScore = GamePlayConfigScore.MatchDeletedCrystal
	-- 	ObstacleFootprintManager:addCrystalBallEliminateRecord(targetItem)
	-- elseif targetItem.ItemType == GameItemType.kNewGift then
	-- 	addScore = 0
	-- elseif targetItem.ItemType == GameItemType.kBalloon then
	-- 	addScore = GamePlayConfigScore.Balloon
	-- end

	-- --- 加分
	-- --- 统计关卡目标
	-- if addScore > 0 then
	-- 	mainLogic:addScoreToTotal(r, c, addScore, targetItem._encrypt.ItemColorType)
	-- end
	-- mainLogic:tryDoOrderList(r, c, GameItemOrderType.kAnimal, targetItem._encrypt.ItemColorType)

	-- --- 检查其他
	-- SnailLogic:doEffectSnailRoadAtPos(mainLogic, r, c)
	-- GameExtandPlayLogic:decreaseLotus(mainLogic, r, c)
	-- ---- 检测冰块沙子
	-- SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, scoreScale)

	-- if targetItem:canChargeCrystalStone() then
	-- 	-- printx(11, "ChargeCrystalStone")
	-- 	GameExtandPlayLogic:chargeCrystalStone(mainLogic, r, c, targetItem._encrypt.ItemColorType)
	-- 	GameExtandPlayLogic:doAllBlocker211Collect(mainLogic, r, c, targetItem._encrypt.ItemColorType, false, 1)
	-- end

	-- GameExtandPlayLogic:itemDestroyHandler(mainLogic, r, c)
end

------------------------------------------------------------------------------------------------------------
--												BLOW
------------------------------------------------------------------------------------------------------------
function GyroLogic:isReadyToBlowGyro(mainLogic, item)
	if item and item.ItemType == GameItemType.kGyro then
		if GyroLogic:gyroIsFull(mainLogic, item) 
			and item:isVisibleAndFree()
			then
			return true
		end
	end
	return false
end

function GyroLogic:pickAllFullGyro(mainLogic)
	local allFullGyro = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if GyroLogic:isReadyToBlowGyro(mainLogic, item) then
            	table.insert(allFullGyro, item)
            end
		end
	end
	return allFullGyro
end

function GyroLogic:updateGyroLevel(mainLogic, r, c)
	local item = mainLogic.gameItemMap[r][c]

	if item and item:isVisibleAndFree() then
        local upgradeAction = GameBoardActionDataSet:createAs(
								 		GameActionTargetType.kGameItemAction,
								 		GameItemActionType.kItem_gyro_upgrade,
								 		IntCoord:create(r, c),
								 		nil,
								 		GamePlayConfig_MaxAction_time)
		mainLogic:addDestroyAction(upgradeAction)
	end
end

function GyroLogic:removeGyroCreater(mainLogic, r, c)
	local item = mainLogic.gameItemMap[r][c]

	if item and item:isVisibleAndFree() then
        if item and item.ItemType == GameItemType.kGyroCreater then
			item:cleanAnimalLikeData()
		    item.isNeedUpdate = true
		    mainLogic:checkItemBlock(item.y, item.x)
		end
	end
end

function GyroLogic:onHitTargets(mainLogic, item, direction )
	local startPos = IntCoord:create(0,0)
	local endPos = IntCoord:create(0,0)
	local itemPos = IntCoord:create(item.x, item.y)

	if direction == 1 then
		startPos = IntCoord:create(itemPos.x, itemPos.y-3)
		endPos = IntCoord:create(itemPos.x, itemPos.y-1)
	elseif direction == 2 then
		startPos = IntCoord:create(itemPos.x+1, itemPos.y)
		endPos = IntCoord:create(itemPos.x+3, itemPos.y)
	elseif direction == 3 then
		startPos = IntCoord:create(itemPos.x, itemPos.y+1)
		endPos = IntCoord:create(itemPos.x, itemPos.y+3)
	elseif direction == 4 then
		startPos = IntCoord:create(itemPos.x-3, itemPos.y)
		endPos = IntCoord:create(itemPos.x-1, itemPos.y)
	end

	--打三格
	local rectangleAction = GameBoardActionDataSet:createAs(
								GameActionTargetType.kGameItemAction,
								GameItemActionType.kItemSpecial_rectangle,
								startPos,
								endPos,
								GamePlayConfig_MaxAction_time)
	rectangleAction.addInt2 = 1
	rectangleAction.eliminateChainIncludeHem = true
	-- rectangleAction.footprintType = ObstacleFootprintType.k_Turret
	mainLogic:addDestructionPlanAction(rectangleAction)
end


-- 解释一下：还有多少只陀螺有可能被产出。
-- < 0 : 不限制数量，步数够管够
function GyroLogic:calculateGyrosLeftMaxAppearAmount(mainLogic)
	local allCreaterPoint = GyroLogic:_getAllGyroCreater(mainLogic, true)
	if #allCreaterPoint > 0 then

		local canGeneralNum = 0
		local bAlwaysCanGeneral = false
		for i,v in ipairs(allCreaterPoint) do
			local produceMaxNum = v.gyroCreaterData.produceMaxNum or 0
			local gyroGeneratedByStep = v.gyroGeneratedByStep or 0
			local gyroGeneratedByBoardMin = v.gyroGeneratedByBoardMin or 0
			local unlockNum = v.gyroCreaterData.unlockNum or 0

			if produceMaxNum > 0 then
				local sumGeneratedAmount = gyroGeneratedByStep + gyroGeneratedByBoardMin
				if sumGeneratedAmount >= produceMaxNum then
					
				else
					canGeneralNum = canGeneralNum + (produceMaxNum - sumGeneratedAmount)
				end
			else
				bAlwaysCanGeneral = true
				break
			end
		end

		if bAlwaysCanGeneral then
			return -1
		else
			return canGeneralNum
		end
	end

	return 0
end

-- --遍历所有陀螺。展示陀螺运行方向特效
-- function GyroLogic:runAllGyroArrow()
-- 	local mainLogic
-- 	local boardView
-- 	if GameBoardLogic:getCurrentLogic() then
-- 		mainLogic = GameBoardLogic:getCurrentLogic()
-- 		if mainLogic.PlayUIDelegate then
-- 		end
-- 		if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.gameBoardView then
-- 			boardView = mainLogic.PlayUIDelegate.gameBoardView
-- 		end
-- 	else
-- 		return
-- 	end

-- 	if not mainLogic or not boardView then return end

-- 	local allGyroList = {}
-- 	for r = 1, #mainLogic.gameItemMap do
-- 		for c = 1, #mainLogic.gameItemMap[r] do
-- 			local item = mainLogic.gameItemMap[r][c]
--             if item and item.ItemType == GameItemType.kGyro then
--             	table.insert(allGyroList,item)
--             end
-- 		end
-- 	end

-- 	for i,v in ipairs(allGyroList) do 
-- 		local toRow = v.y
-- 		local toCol = v.x

-- 		local gyroView = boardView.baseMap[toRow][toCol]
-- 		local toPos = gyroView:getBasePositionWeek(toCol, toRow)
-- 		gyroView:playGyroArrowAnim( v.gyroDirection, toPos, toCol, toRow)
-- 	end
-- end
------------------------------------------------------------------------------------------------------------
--												PROPS
------------------------------------------------------------------------------------------------------------
-- function GyroLogic:dealWithHammerHit(mainLogic, item)
-- 	if item and item.ItemType == GameItemType.kGyro and item:isVisibleAndFree() then
-- 		if not GyroLogic:gyroIsFull(mainLogic, item) then
-- 			item.gyroLevel = item.gyroLevel + 1
-- 			if item.gyroLevel >2  then
-- 				item.gyroLevel = 2
-- 			end
-- 			item.isNeedUpdate = true
-- 		end
-- 	end
-- end
