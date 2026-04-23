GoldenPodBattleLogic = class{}

function GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if mainLogic and mainLogic.gameMode and mainLogic.gameMode:is(GoldenPodBattleMode) then
		return true
	end
	return false
end

function GoldenPodBattleLogic:getInitGoldenPodBattleData(mainLogic)
	if not mainLogic or not mainLogic.gameMode or not mainLogic.gameMode:is(GoldenPodBattleMode) then
		return nil
	end

	local battleData = {}
	battleData.maxRound = 0							-- 总回合数
	battleData.currRound = 0						-- 当前为第几回合（每个人的一轮操作算一回合）
	battleData.currOperID = 0						-- 当前累计（敌我）操作（交换、使用道具）序号

	battleData.currPlayerID = 0						-- 当前玩家
	battleData.currPlayerStepLeft = 0				-- 当前玩家剩余步数
	battleData.stepBonusGotten = false 				-- 当前奖励轮次获得过步数奖励（一回合只能获得一次）
	battleData.stepBonusAvailableForEachStep = false	-- 奖励轮次为“每一步”，否则为“每回合”
	-- battleData.stopTimeFlowInFalling = false		-- 只有waitingState才有时间流逝
	battleData.trophyCount = {}						-- 收集物数量（playerID对应）

	battleData.lastCheckedTophyGenerateStep = 0		-- 上次检测生成收集物的步数
	battleData.switchPlayerGenerateCheck = false	-- 刚切换了玩家后的豆荚生成检查
	battleData.trophyMaxBoardAmount = 0				--（生成用配置）收集物棋盘最高数量
	battleData.trophyMinBoardAmount = 0				--（生成用配置）收集物棋盘最低数量
	battleData.trophyGenerateQueue = nil			--（生成用配置）收集物生成序列

	battleData.lastNotifiedRoundID = 0				-- 上个通知了服务器 EndRound 的回合
	battleData.lastNotifiedOperID = 0				-- 上个通知了服务器 Snap 的回合

	return battleData
end

function GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if mainLogic then
		return mainLogic.goldenPodBattleData
	end
	return nil
end

-- 玩家是否是反向视角
function GoldenPodBattleLogic:playerInReverseView(mainLogic)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData then
		return battleData.isReverseView
	end
	return false
end

-- 当前为自己的回合
function GoldenPodBattleLogic:inSelfActiveTurn(mainLogic)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and battleData.battleContext then
		if battleData.currPlayerID == battleData.battleContext.selfPlayerID then
			return true
		end
	end
	return false
end

-- 获得当前状态下的预期重力方向
function GoldenPodBattleLogic:getGravityOnCurrRound(mainLogic)
	-- printx(11, "~~~~ GoldenPodBattleLogic:getGravityOnCurrRound !!!")
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	-- printx(11, "~~~~ mainLogic?", mainLogic, mainLogic.goldenPodBattleData)
	if mainLogic and mainLogic.goldenPodBattleData and mainLogic.goldenPodBattleData.battleContext then
		local battleData = mainLogic.goldenPodBattleData

		local isSelfActiveTurn = GoldenPodBattleLogic:inSelfActiveTurn(mainLogic)
		local selfInReverseView = GoldenPodBattleLogic:playerInReverseView(mainLogic)
		-- printx(11, "~~~~ isSelfActiveTurn, selfInReverseView", isSelfActiveTurn, selfInReverseView)
		if (isSelfActiveTurn and selfInReverseView) or (not isSelfActiveTurn and not selfInReverseView) then
			return BoardGravityDirection.kUp
		else
			return BoardGravityDirection.kDown
		end
	end
	return BoardGravityDirection.kDown
end

-- 根据收集口位置为相应玩家添加收集物
function GoldenPodBattleLogic:addPlayerTrophyAmount(mainLogic, r, c)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if not battleData then return end

	local playerID = GoldenPodBattleLogic:_getPlayerIDByCollectorPos(r, c)

	if not battleData.trophyCount then battleData.trophyCount = {} end
	if not battleData.trophyCount[playerID] then battleData.trophyCount[playerID] = 0 end
	battleData.trophyCount[playerID] = battleData.trophyCount[playerID] + 1
end

-- 根据收集口位置为相应玩家添加收集物
function GoldenPodBattleLogic:getPlayerIDAndCurrTrophyAmountByCollectPos(mainLogic, r, c)
	local playerID = GoldenPodBattleLogic:_getPlayerIDByCollectorPos(r, c)

	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and battleData.trophyCount and battleData.trophyCount[playerID] then
		return playerID, battleData.trophyCount[playerID]
	end
	return playerID, 0
end

-- 获取当前进攻方的收集物数量，后端用
function GoldenPodBattleLogic:_getCurrActivePlayerTrophyAmount()
	local trophyAmount = 0
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and battleData.trophyCount then
		local playerID = battleData.currPlayerID
		if battleData.trophyCount[playerID] then
			trophyAmount = battleData.trophyCount[playerID]
		end
	end
	return trophyAmount
end

-- 玩家双方领地的分隔行，此行以上为玩家2收集区域，以下为玩家1收集区域
function GoldenPodBattleLogic:getPlayerRealmDividingRow()
	local rowCount, colCount = GameBoardUtil:getRowAndColAmountOfBoard()
	if rowCount then
		local dividingRow = math.ceil(rowCount / 2)
		return dividingRow
	end
	return 5
end

function GoldenPodBattleLogic:_getPlayerIDByCollectorPos(r, c)
	local playerID = 1
	local playerRealmDividingRow = GoldenPodBattleLogic:getPlayerRealmDividingRow()
	if r and r < playerRealmDividingRow then 
		playerID = 2 
	end
	return playerID
end

-- 合成特效，增加操作次数
function GoldenPodBattleLogic:onSpecialAnimalBeingMerged(mainLogic)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and not battleData.stepBonusGotten then
		battleData.stepBonusGotten = true

		battleData.currPlayerStepLeft = battleData.currPlayerStepLeft + 1
		-- 我觉得我还能抢救一下
		if battleData.currPlayerStepLeft == 1 and mainLogic.gameMode then
			mainLogic.gameMode.needCheckSwitchPlayerByMove = false
		end

		-- if mainLogic.boardView then
		-- 	mainLogic.boardView:viberate()
		-- end
		GoldenPodBattleLogic:updateLeftStepDisplay(mainLogic)
	end
end

function GoldenPodBattleLogic:updateLeftStepDisplay(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	local descText = GoldenPodBattleLogic:getLeftStepDisplayText(mainLogic)
	if mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.moveOrTimeCounter then
		mainLogic.PlayUIDelegate.moveOrTimeCounter:setCustomizedDescText(descText)
	end
end

function GoldenPodBattleLogic:getLeftStepDisplayText(mainLogic)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and battleData.currPlayerStepLeft then
		local roundLeft = battleData.maxRound - battleData.currRound + 1
		local descText = "余"..battleData.currPlayerStepLeft.."步,"..roundLeft.."轮"
		return descText
	end
	return ""
end

------------------------------------- Generate ------------------------------------
function GoldenPodBattleLogic:getAllBattleTrophyGeneratePoint(mainLogic)
	local allGeneratePoint = {}
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]
			if board and board.isBattleTrophyGridGenerater then
				table.insert(allGeneratePoint, board)
			end
		end
	end
	return allGeneratePoint
end

function GoldenPodBattleLogic:getGoldenPodAmountOnBoard(mainLogic)
	local goldenPodAmount = 0
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item and item.ItemType == GameItemType.kIngredient then
				goldenPodAmount = goldenPodAmount + 1
			end
		end
	end
	return goldenPodAmount
end

-- GoldenPodAppearPriority = table.const{ 
-- 	[1] = {GameItemType.kBlocker195, GameItemType.kCrystalStone, GameItemType.kTotems},
-- 	[2] = {GameItemType.kMissile, GameItemType.kDynamiteCrate, GameItemType.kBlocker199, GameItemType.kGift, GameItemType.kNewGift,GameItemType.kShellGift, 
-- 			GameItemType.kMagicLamp, GameItemType.kPacman, GameItemType.kPuffer, GameItemType.kBlocker207, GameItemType.kBalloon,GameItemType.kAddMove, 
-- 			GameItemType.kBuffBoom, GameItemType.kScoreBuffBottle, GameItemType.kFirecracker, GameItemType.kPlane},
-- 	[3] = {GameItemType.kAnimal, GameItemType.kTravelEnergyBag},
-- 	[4] = {GameItemType.kHoneyBottle, GameItemType.kWanSheng, GameItemType.kIngredient, GameItemType.kCoin, GameItemType.kChameleon,
-- 			GameItemType.kCuckooWindupKey},
-- 	[5] = {GameItemType.kCrystal, GameItemType.kAnimal, GameItemType.kWater},
-- }
function GoldenPodBattleLogic:pickGenerateTargets(mainLogic, needAmount)
	local pickedTargets = {}
	local candidateTargets = {}
	-- for i = 1, #GoldenPodAppearPriority do
	for i = 1, 2 do
		candidateTargets[i] = {}
	end

	local function getPriorityOfItem(item)
		-- if item and not item.isEmpty and item:isVisibleAndFree() then
			-- for pri = 1, #GoldenPodAppearPriority do
			-- 	local targetsOfPri = GoldenPodAppearPriority[pri]
			-- 	local index = table.indexOf(targetsOfPri, item.ItemType)
			-- 	-- printx(11, "pri = "..pri..", targetsOfPri", table.tostring(targetsOfPri))
			-- 	-- printx(11, "index", index, item.ItemType)
			-- 	if index and index > 0 then
			-- 		-- printx(11, "index, item.ItemType", index, item.ItemType, item.x, item.y)
			-- 		if item.ItemType == GameItemType.kAnimal then
			-- 			if pri == 3 and AnimalTypeConfig.isSpecialAnimal(item.ItemSpecialType) then		--3号优先级是特效动物
			-- 				return pri
			-- 			elseif pri == 5 and item.ItemSpecialType == 0 then		--5号优先级是普通动物
			-- 				return pri
			-- 			end
			-- 		elseif item.ItemType == GameItemType.kBlocker199 then
			-- 			if item:isBlocker199Active() then return pri else return 0 end
			-- 		elseif item.ItemType == GameItemType.kTotems then
			-- 			if not item:isActiveTotems() then return pri else return 0 end
			-- 		else
			-- 			return pri
			-- 		end
			-- 	end
			-- end
		-- end

		-- DEMO 只区分普通动物和其他
		-- if item and not item.isEmpty then
		if item then
			if item.ItemType == GameItemType.kIngredient then
				return 0
			elseif item.ItemType == GameItemType.kAnimal and item.ItemSpecialType == 0 then
				return 1
			else
				return 2
			end
		end
		return 0
	end

	local candidateAmount = 0
	local allGeneratePoint = GoldenPodBattleLogic:getAllBattleTrophyGeneratePoint(mainLogic)
	if #allGeneratePoint > 0 then
		local pickedPos = {}
		for _, appearPoint in ipairs(allGeneratePoint) do
			local row, col = appearPoint.y, appearPoint.x
			local itemData = mainLogic:safeGetItemData(row, col)
			local boardData = mainLogic:safeGetBoardData(row, col)
			local generatedAmount = 0
			if boardData then generatedAmount = boardData.battleTrophyGeneratedAmount or 0 end

			local priority = getPriorityOfItem(itemData)
			-- printx(11, "row, col, priority", row, col, priority)
			if priority > 0 then
				local candidateSets = {itemData = itemData, generatedAmount = generatedAmount}
				table.insert(candidateTargets[priority], candidateSets)
				candidateAmount = candidateAmount + 1
			end
		end
	end

	-- 对于同一个优先级的列表，按照累计生成收集物数量，进行优先级排序
	for _, targetList in pairs(candidateTargets) do
		-- 先内部打乱次序再排序，相当于对排序结果的同条件对象进行了随机选取
		table.randomOrder(targetList, mainLogic)
		-- 优先累计生成数量少的
		table.sort(targetList, function(a, b)
			if a.generatedAmount < b.generatedAmount then
				return true
			end
			return false
		end)
	end

	local pickAmount = math.min(needAmount, candidateAmount)
	-- printx(11, "pickAmount", pickAmount, table.tostring(candidateTargets))
	-- printx(11, "pickAmount", pickAmount, #candidateTargets)
	if pickAmount > 0 then
		for k = 1, pickAmount do 
			for listIndex = 1, #candidateTargets do
				local subList = candidateTargets[listIndex]
				-- printx(11, "listIndex", listIndex, table.tostring(subList))
				if subList and #subList > 0 then
					local targetCandidateSet = table.remove(subList, 1)
					-- printx(11, "=== PickedPos:", targetCandidateSet.itemData.y, targetCandidateSet.itemData.x)
					table.insert(pickedTargets, targetCandidateSet.itemData)
					break
				end
			end
		end
	end

	return pickedTargets
end

function GoldenPodBattleLogic:replaceGridDataByTrophy(mainLogic, pickedTargets)
	for _, targetItem in pairs(pickedTargets) do
		local r, c = targetItem.y, targetItem.x

		-- printx(11, "replaceGridDataBy golden pod. position Row, Col:", r, c)
		local item = mainLogic:safeGetItemData(r, c)
		if item then
			-- item:changeToIngredient()
			item:cleanAnimalLikeData()
			item.ItemType = GameItemType.kIngredient 
			item.isEmpty = false

			mainLogic:checkItemBlock(r,c)
			item.isNeedUpdate = true
		end

		local boardData = mainLogic:safeGetBoardData(r, c)
		if boardData then 
			if not boardData.battleTrophyGeneratedAmount then boardData.battleTrophyGeneratedAmount = 0 end
			boardData.battleTrophyGeneratedAmount = boardData.battleTrophyGeneratedAmount + 1
		end
	end
end

-------------------------------------------------------------------------------
function GoldenPodBattleLogic:sendReadyToStartBattle(mainLogic)
	printx(11, "============= GoldenPodBattleLogic:sendReadyToStartBattle!")
	local currSectionStr = GoldenPodBattleLogic:getCurrSectionData()
	if not currSectionStr then return end

	local params = {}
	params["snap"] = currSectionStr

	PVPGameManager:getInstance():onGoldenPodBattleSendToServer(PVPRequestName.kGoldenPodPlayerReady, params)
end

function GoldenPodBattleLogic:onStartRoundMessageReceived(roundIndex)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic or not mainLogic.gameMode or not mainLogic.gameMode:is(GoldenPodBattleMode) then return end

	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData()
	local currRound = battleData.currRound
	printx(11, "======== GoldenPodBattleLogic:onStartRoundMessageReceived!", roundIndex, currRound)
	if roundIndex == 1 and currRound == 1 then
		printx(11, "=== first round")
		-- 第一回合，开始游戏
		if GoldenPodBattleLogic:inSelfActiveTurn(mainLogic) then
			mainLogic.inObservingMode = false
		end
		mainLogic.gameMode.timeFreezedByInit = false
		mainLogic.gameMode:updateTimeFlowStatus()

	elseif roundIndex == currRound + 1 then
		printx(11, "=== switch player")
		-- switch player!!
		GoldenPodBattleLogic:switchPlayer(mainLogic)
	else
		printx(11, "Round ID Error! myRoundID, receivedRoundID:", currRound, roundIndex)
		CommonTip:showTip("回合错误！"..currRound.."-"..roundIndex, "negative")
	end
end

--------------------------------- Operations ---------------------------------
function GoldenPodBattleLogic:addOperationToPendingList(operID, operType, operData)
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData()
	if battleData then
		if operID <= battleData.currOperID then
			CommonTip:showTip("寄存操作：ID错误！"..battleData.currOperID.."-"..operID, "negative")
			printx(11, "addOperationToPendingList -- operID Error! myOperID, receivedOperID:", battleData.currOperID, operID)
			--- [NEED SYNC] ???
			return
		end

		if not battleData.pendingOperArr then
			battleData.pendingOperArr = {}
		end
		local operAction = {}
		operAction["operID"] = operID
		operAction["operType"] = operType
		operAction["operData"] = operData
		table.insert(battleData.pendingOperArr, operAction)
	end
end

function GoldenPodBattleLogic:checkOperationList()
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData()
	if battleData then
		if battleData.pendingStepArr and #battleData.pendingStepArr > 0 then
			local nextOperation = battleData.pendingStepArr[1]
			table.remove(battleData.pendingStepArr, 1)
			if #battleData.pendingStepArr == 0 then
				battleData.pendingStepArr = nil
			end

			if nextOperation.operID <= battleData.currOperID then
				CommonTip:showTip("播放寄存操作：ID错误！"..battleData.currOperID.."-"..nextOperation.operID, "negative")
				printx(11, "addOperationToPendingList -- operID Error! myOperID, receivedOperID:", battleData.currOperID, nextOperation.operID)
				--- [NEED SYNC] ???
				return
			end

			local nextOperType = nextOperation.operType
			if nextOperType == PVPGameOperationType.kSwap then
				GoldenPodBattleLogic:onOpponentSwap(nextOperation.operID, nextOperation.operData)
			elseif nextOperType == PVPGameOperationType.kUseProp then
				
			elseif nextOperType == PVPGameOperationType.kSwitchPlayer then

			end

			printx(11, "======== Deal with pending operation: ID, type", nextOperation.operID, nextOperType)
			return true
		end
	end
	return false
end

-- 发送操作（交换/使用道具）
function GoldenPodBattleLogic:checkSendOperations(mainLogic, operType, r1, c1, r2, c2)
	if GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic) then
		local operationType
		if operType == "swap" then
			operationType = PVPGameOperationType.kSwap
		elseif operType == "useProp" then
			operationType = PVPGameOperationType.kUseProp
		elseif operType == "switchPlayer" then
			operationType = PVPGameOperationType.kSwitchPlayer
		end

		if operationType == PVPGameOperationType.kSwitchPlayer or GoldenPodBattleLogic:inSelfActiveTurn(mainLogic) then
			local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
			if battleData and battleData.currOperID then 
				battleData.currOperID = battleData.currOperID + 1

				if operationType then
					local stepOper = {}
					-- stepOper["operType"] = operationType
					if r1 then stepOper["r1"] = r1 end
					if c1 then stepOper["c1"] = c1 end
					if r2 then stepOper["r2"] = r2 end
					if c2 then stepOper["c2"] = c2 end

					local params = {}
					params["stepIndex"] = battleData.currOperID
					params["stepType"] = operationType
					params["step"] = table.serialize(stepOper)

					printx(11, "&&& onSendGoldenPodBattleOperation!!!!", table.tostring(params))
					-- PVPGameManager:getInstance():onSendGoldenPodBattleOperation(params)
					PVPGameManager:getInstance():onGoldenPodBattleSendToServer(PVPRequestName.kGoldenPodSendStep, params)
				end
				-- PVPGameManager:getInstance():onSendGoldenPodBattleOperation(battleData.currOperID, operType, r1, c1, r2, c2)
			end
		end
	end
end

-- 对手交换
function GoldenPodBattleLogic:onTryOpponentSwap(operID, operData)
	printx(11, "======== GoldenPodBattleLogic:onTryOpponentSwap")
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not operData or not operID then return end

	-- 在WaitingState中时，可以立即拉取新断面，否则等到进入WaitingState之后再行拉取
	if mainLogic.isWaitingOperation then
		GoldenPodBattleLogic:onOpponentSwap(operID, operData)
	else
		GoldenPodBattleLogic:addOperationToPendingList(operID, PVPGameOperationType.kSwap, operData)
	end
end

-- 对手交换
function GoldenPodBattleLogic:onOpponentSwap(operID, operData)
	printx(11, "======== GoldenPodBattleLogic:onOpponentSwap")
	local function failCallback()
		printx(11, "======== GoldenPodBattleLogic:onOpponentSwap: FAILED")
	end

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not operData or not operID then return end

	if GoldenPodBattleLogic:inSelfActiveTurn(mainLogic) then
		printx(11, "MY turn! Ignore OPPONENTS swap.")
		return
	end

	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if not battleData then return end

	local currOperID = battleData.currOperID
	if operID == currOperID + 1 then
		local r1 = operData["r1"]
		local c1 = operData["c1"]
		local r2 = operData["r2"]
		local c2 = operData["c2"]

		printx(11, "TRY SWAP By OPPONENTS:", r1, c1, r2, c2)
		if r1 and c1 and r2 and c2 then
			battleData.currOperID = operID
			mainLogic:startTrySwapedItem(r1, c1, r2, c2, failCallback)
		end
	else
		printx(11, "Operation ID Error! myOperID, receivedOperID:", currOperID, operID)
		CommonTip:showTip("操作顺序混乱！"..currOperID.."-"..operID, "negative")
		GoldenPodBattleLogic:trySyncToLatestBattleField()
	end
end

-- 对手使用道具
function GoldenPodBattleLogic:onOpponentUseProp(operData)

end

-- 发送断面
function GoldenPodBattleLogic:checkSendSnapshot(mainLogic)
	if GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic) then
		local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
		if not battleData then return end

		local operID = battleData.currOperID
		local lastNotifiedID = battleData.lastNotifiedOperID or 0
		printx(11, "============= GoldenPodBattleLogic:checkSendEndRound! operID, lastNotifiedOper:", operID, lastNotifiedID)
		if operID <= lastNotifiedID then return end

		battleData.lastNotifiedOperID = operID

		local currSectionStr = GoldenPodBattleLogic:getCurrSectionData()
		if not currSectionStr then return end

		local params = {}
		params["stepIndex"] = operID
		params["score"] = GoldenPodBattleLogic:_getCurrActivePlayerTrophyAmount()
		params["snap"] = currSectionStr
		-- params["snap"] = "SnapshotOfTheEmperor_"..operID --这里要发送断面数据哒

		printx(11, "%.*.%.*.%.*.%.*.%.*.%.*.%.*.%.*. SEND SNAPSHOT, ID:", operID)
		-- PVPGameManager:getInstance():onSendGoldenPodBattleSnapshot(params)
		PVPGameManager:getInstance():onGoldenPodBattleSendToServer(PVPRequestName.kGoldenPodSnap, params)
	end
end

-- 判定回合结束，通知服务器
function GoldenPodBattleLogic:checkSendEndRound(mainLogic)
	if GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic) then
		local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
		if not battleData then return end

		local currRoundID = battleData.currRound
		local lastNotifiedID = battleData.lastNotifiedRoundID or 0
		printx(11, "============= GoldenPodBattleLogic:checkSendEndRound! round, lastNotifiedRound:", currRoundID, lastNotifiedID)
		if currRoundID <= lastNotifiedID then return end

		battleData.lastNotifiedRoundID = currRoundID

		local params = {}
		params["roundIndex"] = currRoundID
		PVPGameManager:getInstance():onGoldenPodBattleSendToServer(PVPRequestName.kGoldenPodEndRound, params)
	end

	-- -- 规则：只有当前进攻方才可以向服务器发送切换玩家的请求
	-- if GoldenPodBattleLogic:inSelfActiveTurn(mainLogic) then
	-- 	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	-- 	local nextPlayerID = CalculationUtil:modValueBetween(1, 2, battleData.currPlayerID + 1)
	-- 	PVPGameManager:getInstance():onSendGoldenPodBattleEndRound(nextPlayerID)
	-- end
end

-- function GoldenPodBattleLogic:switchPlayer(mainLogic, toActivePlayerID)
function GoldenPodBattleLogic:switchPlayer(mainLogic)
	printx(11, "-------- GoldenPodBattleLogic:switchPlayer ----------")--, toActivePlayerID)
	-- printx(11, "status:", mainLogic.goldenPodBattleData.currPlayerID, 
	-- 	mainLogic.goldenPodBattleData.currPlayerStepLeft, mainLogic.goldenPodBattleData.currRound)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic or not mainLogic.goldenPodBattleData then return end

	-- 切换玩家信息
	local battleData = mainLogic.goldenPodBattleData

	-- -- 回放用？先瞎写一下
	-- if not toActivePlayerID then
	-- 	toActivePlayerID = CalculationUtil:modValueBetween(1, 2, battleData.currPlayerID + 1)
	-- end
	battleData.currPlayerID = CalculationUtil:modValueBetween(1, 2, battleData.currPlayerID + 1)
	battleData.currPlayerStepLeft = GoldenPodBattleConsts.kDefaultStepPerPlayer
	battleData.stepBonusGotten = false
	battleData.currRound = battleData.currRound + 1
	battleData.switchPlayerGenerateCheck = true

	GoldenPodBattleLogic:updateLeftStepDisplay(mainLogic)

	local selfPlayerID = 0
	if battleData.battleContext and battleData.battleContext.selfPlayerID then
		selfPlayerID = battleData.battleContext.selfPlayerID
	end
	
	-- 重置时间
	mainLogic.timeTotalUsed = 0
	-- 重置一些状态
	if mainLogic.gameMode then
		mainLogic.gameMode.needCheckSwitchPlayerByTime = false
		mainLogic.gameMode.needCheckSwitchPlayerByMove = false
	end

	-- -- demo: 用玩家ID作为重力方向的标志
	-- local switchOnWindTunnels = false
	-- if toActivePlayerID == 2 then
	-- 	switchOnWindTunnels = true
	-- end
	-- WindTunnelLogic:_switchAllWindTunnelsOnBoard(mainLogic, switchOnWindTunnels)
	local currGravity = GoldenPodBattleLogic:getGravityOnCurrRound(mainLogic)
	GoldenPodBattleLogic:flipGravity(mainLogic, currGravity)

	if GoldenPodBattleLogic:inSelfActiveTurn(mainLogic) then
		mainLogic.inObservingMode = false
		printx(11, "!!!!!!!!! Exit observing !!!!!")
	else
		mainLogic.inObservingMode = true
		printx(11, ".......... observing ............")
	end

	mainLogic:setNeedCheckFalling()
	mainLogic.fsm:onSwitchPlayer()

	if mainLogic.boardView then
		mainLogic.boardView:viberate()
	end

	GoldenPodBattleLogic:checkSendOperations(mainLogic, "switchPlayer")

	-- 添加Replay记录
	if not mainLogic.replaying 
		or mainLogic.replayMode == ReplayMode.kConsistencyCheck_Step1 
		or mainLogic.replayMode == ReplayMode.kAutoPlayCheck  
		or (mainLogic.replayMode == ReplayMode.kMcts and _G.launchCmds.domain and not _G.AIAutoCheckReplayCheck) then
		mainLogic:addReplayStep({switchPlayer = battleData.currPlayerID})
	end
end

function GoldenPodBattleLogic:flipGravity(mainLogic, newGravity)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic or not mainLogic.boardmap then return end
	-- if not mainLogic.goldenPodBattleData then return end

	if newGravity == BoardGravityDirection.kUp then
		printx(11, "=== Flip Gravity!!!! ======= TO: UP")
	else
		printx(11, "=== Flip Gravity!!!! ======= TO: DOWN")
	end

	for r = 1, #mainLogic.boardmap do 
		for c = 1, #mainLogic.boardmap[r] do 
			local boardData = mainLogic.boardmap[r][c]
			if boardData then
				-- local currGravity = boardData:getGravity()
				-- if currGravity == BoardGravityDirection.kDown then
				-- 	boardData:setGravity(BoardGravityDirection.kUp)
				-- else
				-- 	boardData:setGravity(BoardGravityDirection.kDown)
				-- end

				boardData:setGravity(newGravity)
				boardData.isNeedUpdate = true
			end
		end
	end
end

function GoldenPodBattleLogic:checkSendEndGame(mainLogic)
	-- printx(11, "GoldenPodBattleLogic:checkSendEndGame", debug.traceback())
	if GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic) then
		PVPGameManager:getInstance():onSendGoldenPodBattleGameEnd()
	end
end

-------------------------------- Sync --------------------------
-- 向后端获取最新战况（断面 & 最新操作）
function GoldenPodBattleLogic:trySyncToLatestBattleField()
	printx(11, "========== Logic:trySyncToLatestBattleField")
	-- todo：WaitingState再请求
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.goldenPodBattleData then return end
	local battleData = mainLogic.goldenPodBattleData

	-- 在WaitingState中时，可以立即拉取新断面，否则等到进入WaitingState之后再行拉取
	if mainLogic.isWaitingOperation then
		GoldenPodBattleLogic:_checkLatestBattleFieldData()
	else
		battleData.needCheckSyncData = true
	end
end

function GoldenPodBattleLogic:checkSyncDataIfNeeded()
	local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	if battleData and battleData.needCheckSyncData then
		battleData.needCheckSyncData = false
		GoldenPodBattleLogic:_checkLatestBattleFieldData()
		return true
	end
	return false
end

function GoldenPodBattleLogic:_checkLatestBattleFieldData()
	printx(11, "========== Logic:_checkLatestBattleFieldData")
	CommonTip:showTip("尝试同步到最新局面...", "positive")

	if GoldenPodBattleLogic:isGoldenPodBattleMode(mainLogic) then
		local params = {} --没有参数
		PVPGameManager:getInstance():onGoldenPodBattleSendToServer(PVPRequestName.kGoldenPodSyncRoom, params)
	end
end

-- 获得了后端返回的最新战况
function GoldenPodBattleLogic:onGoldenPodLatestBattleFieldGotten(resultData)
	printx(11, "========== Logic:onGoldenPodLatestBattleFieldGotten")
	CommonTip:showTip("---开始恢复到最新局面---", "positive")

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.goldenPodBattleData or not resultData then return end
	local battleData = mainLogic.goldenPodBattleData

	local latestRoundID = resultData.roundIndex					-- 最新局面的"currRound"
	local latestSectionOperID = resultData.lastSnapStepIndex	-- 上个断面数据生成时的"currOperID"

	printx(11, "========== latest: RoundID, SectionOperID, stepIndex, stepType, stepParam:", latestRoundID, latestSectionOperID, resultData.lastStepIndex, resultData.lastStepType, resultData.lastStep)

	if resultData.lastStepIndex and resultData.lastStepType 
		and (resultData.lastStepIndex > latestSectionOperID) then 	-- 只处理晚于最新断面的操作
		local latestStepOperID = resultData.lastStepIndex 			-- 上一个断面后的最新操作的"currOperID"（不一定存在）
		if latestStepOperID > battleData.currOperID then
			-- if resultData.lastStepType ~= PVPGameOperationType.kSwitchPlayer then
				-- 将step存住，以便在恢复后播放
				GoldenPodBattleLogic:addOperationToPendingList(latestStepOperID, resultData.lastStepType, resultData.lastStep)
			-- end
		end
	end

	local function onSyncResumeFinished()
		GoldenPodBattleLogic:checkNextActionAfterSyncResume(latestRoundID)
	end

	-- 有更加新的断面，用断面恢复
	if latestSectionOperID > battleData.currOperID then
		if resultData.lastSnap then
			GoldenPodBattleLogic:resumeWithSectionData(mainLogic, resultData.lastSnap, onSyncResumeFinished)
		else
			CommonTip:showTip("错误：没有断面数据", "negative")
		end
	else
		GoldenPodBattleLogic:checkNextActionAfterSyncResume(latestRoundID)
	end
end

function GoldenPodBattleLogic:getCurrSectionData()
	local sectionData = SectionResumeManager:getCurrSectionData()
	local dataTable = SectionResumeManager:encodeBySection( sectionData )

	-- local jsonStr = table.serialize(dataTable)
	-- CCDirector:sharedDirector():setClipboard(table.tostring(jsonStr))
	-- -- printx(11, "========== Section STR:", jsonStr)
	-- local sectionStr = mime.b64(compress(jsonStr))

	local amf3Str = amf3.encode(dataTable)
	local sectionStr = compress(amf3Str)
	-- CCDirector:sharedDirector():setClipboard(sectionStr)

	-- local sectionStr = SectionResumeManager:getCurrSerializedSectionData()

	-- local battleData = GoldenPodBattleLogic:getGoldenPodBattleData(mainLogic)
	-- local sectionStr = "SectionData_"..battleData.currOperID
	return sectionStr
end

function GoldenPodBattleLogic:resumeWithSectionData(mainLogic, sectionData, onResumeFinished)
	if not mainLogic or not sectionData then return end

	SectionResumeManager:revertBySerializedSectionData(sectionData, onResumeFinished)
end

-- 根据同步数据回复棋盘局面后，检测下一个操作
function GoldenPodBattleLogic:checkNextActionAfterSyncResume(lastestRoundBySync)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.goldenPodBattleData or not resultData then return end
	local battleData = mainLogic.goldenPodBattleData

	printx(11, "========== Logic:checkNextActionAfterSyncResume, lastestRoundID, pendingStep:", lastestRoundBySync, table.tostring(battleData.pendingStepArr))
	local currRound = battleData.currRound


end
