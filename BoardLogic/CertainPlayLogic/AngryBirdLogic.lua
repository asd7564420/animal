AngryBirdLogic = class{}

AngryBirdSpecies =
{
	kRed = 1,
	kBlue = 2,
	kBlack = 3,
}

local specialHandleItem = 
{
	GameItemType.kRoost,
	GameItemType.kHoneyBottle,
	GameItemType.kDynamiteCrate,
	GameItemType.kPlane,
	GameItemType.kMagicLamp,
	GameItemType.kShellGift,
	GameItemType.kBottleBlocker,
}

local propsList =
{
	GamePropsType.kRefresh,
	GamePropsType.kSwap,
	GamePropsType.kHammer,
	GamePropsType.kRowEffect,
	GamePropsType.kColumnEffect,
	GamePropsType.kLineBrush,
}

function AngryBirdLogic:isAngryBirdsLevel(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > 0 then
		if LevelType:isAngryBirdLevel(levelID) then
			return true
		end
	end
	return false
end

function AngryBirdLogic:getChapterID(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	local chapterID = 1
	if levelID and levelID > LevelConstans.ANGRY_BIRD_LEVEL_ID_START then
		chapterID = math.ceil((levelID - LevelConstans.ANGRY_BIRD_LEVEL_ID_START) / 3)
	end
	return chapterID
end

function AngryBirdLogic:getLevelIndexInChapter()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic and mainLogic.currTravelMapIndex and mainLogic.currTravelMapIndex > 0 then
		return mainLogic.currTravelMapIndex
	end
	return 1
end

---------------------------------- configs -----------------------------------------
function AngryBirdLogic:getAngryBirdsLevelConfig()
	if AngryBird2020Manager.getInstance() then
		local rawLevelConfig = AngryBird2020Manager.getInstance():getPreStartLevelData()
		if rawLevelConfig and rawLevelConfig.result and (type(rawLevelConfig.result) == "string") then
			local levelConfig = table.deserialize(rawLevelConfig.result)
			return levelConfig
		end
	end
	return nil
end

function AngryBirdLogic:setAngryBirdsLevelDataForLevel(playUIDelegate)
	-- printx(15, "==== AngryBirdLogic:setAngryBirdsLevelDataForLevel", debug.traceback())
	if not playUIDelegate then return end

	local currentLevelID = playUIDelegate.levelId

	local configData = AngryBirdLogic:getAngryBirdsLevelConfig()
	-- printx(15, "==== configData ?", table.tostringByKeyOrder(configData))
	if not configData then 
		if _G.isLocalDevelopMode then
			playUIDelegate.angryBirdsLevelData = AngryBirdLogic:getTestLevelData(currentLevelID)
			-- printx(11, "TEST DATA:", table.tostringByKeyOrder(playUIDelegate.angryBirdsLevelData))
		end
		return 
	end

	local function getRewardSetFromConfig(configRewardSet)
		if configRewardSet and configRewardSet.num and configRewardSet.itemId then
			local rewardSet = {}
			rewardSet["rewardID"] = configRewardSet.itemId
			rewardSet["amount"] = configRewardSet.num
			return rewardSet
		end
		return nil
	end

	local function getRewardListFromConfig(configRewardList)
		if configRewardList then
			local rewardList = {}
			for _, configRewardSet in pairs(configRewardList) do
				local rewardSet = getRewardSetFromConfig(configRewardSet)
				if rewardSet then
					table.insert(rewardList, rewardSet)
				end
			end
			return rewardList
		end
		return nil
	end

	local levelData = {}
	local dataValid = true

	MACRO_DEV_START()
	------------ 鸟奖励（全局） --------------
	MACRO_DEV_END()
	if configData.birdAttackRewards then
		local birdRewards = {}
		local birdCriticalRewards = {}
		for _, birdRewardData in pairs(configData.birdAttackRewards) do
			local birdType = birdRewardData.birdId
			if birdType and birdType >= 1 and birdType <= 3 then
				if birdRewardData.normalRewards then
					local birdReward = getRewardListFromConfig(birdRewardData.normalRewards)
					if birdReward and #birdReward > 0 then
						birdRewards[birdType] = birdReward
					end
				end

				if birdRewardData.criticalRewards then
					local birdCriticalReward = getRewardListFromConfig(birdRewardData.criticalRewards)
					if birdCriticalReward and #birdCriticalReward > 0 then
						if birdRewardData.minSliverTickets and birdRewardData.maxSliverTickets then
							local criticalRangeReward = {rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, 
							amountMin = birdRewardData.minSliverTickets, amountMax = birdRewardData.maxSliverTickets}
							table.insert(birdCriticalReward, criticalRangeReward)
						end
						birdCriticalRewards[birdType] = birdCriticalReward
					end
				end
			end
		end

		if #birdRewards == 3 and #birdCriticalRewards == 3 then
			levelData["birdRewards"] = birdRewards
			levelData["birdCriticalRewards"] = birdCriticalRewards
		else
			dataValid = false
		end
		-- printx(11, "===== birdRewards:", table.tostring(levelData["birdRewards"]))
		-- printx(11, "===== birdCriticalRewards:", table.tostring(levelData["birdCriticalRewards"]))
	end

	MACRO_DEV_START()
	------------ +5步奖励（随章节） --------------
	MACRO_DEV_END()
	if configData.addFiveRewards then
		local addFiveRewardConfig = configData.addFiveRewards
		if addFiveRewardConfig.collectionNums and addFiveRewardConfig.maxSliverTickets and addFiveRewardConfig.minSliverTickets then
			levelData["addFiveRewards"] = {
				{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = addFiveRewardConfig.collectionNums},
				{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amountMin = addFiveRewardConfig.minSliverTickets, amountMax = addFiveRewardConfig.maxSliverTickets},
			}
		else
			dataValid = false
		end
		-- printx(11, "===== addFiveRewards:", table.tostring(levelData["addFiveRewards"]))
	end

	MACRO_DEV_START()
	------------ 过关Boss奖励（随关卡） --------------
	MACRO_DEV_END()
	if configData.bossRewards then
		local bossRewards = {}
		for _, bossRewardData in pairs(configData.bossRewards) do
			local levelIndex
			local levelID = bossRewardData.levelId
			if levelID then 
				levelIndex = CalculationUtil:modValueBetween(1, 3, levelID)
			end
			if levelIndex then
				if bossRewardData.rewardItems then
					local bossReward = getRewardListFromConfig(bossRewardData.rewardItems)
					if bossReward and #bossReward > 0 then
						bossRewards[levelIndex] = bossReward
					end
				end
			end
		end

		if #bossRewards == 3 then
			levelData["bossRewards"] = bossRewards
		else
			dataValid = false
		end
		-- printx(11, "===== bossRewards:", table.tostring(levelData["bossRewards"]))
	end

	MACRO_DEV_START()
	------------ 过关步数Bonus（随关卡） --------------
	MACRO_DEV_END()
	if configData.moveBonusRewards then
		local moveBonusRewards = {}
		for _, moveBonusRewardData in pairs(configData.moveBonusRewards) do
			local moveVal = moveBonusRewardData.steps
			local levelIndex
			local levelID = moveBonusRewardData.levelId
			if levelID then 
				levelIndex = CalculationUtil:modValueBetween(1, 3, levelID)
			end
			if levelIndex and moveVal then
				if moveBonusRewardData.rewardItems then
					local moveBonusReward = getRewardListFromConfig(moveBonusRewardData.rewardItems)
					if moveBonusReward and #moveBonusReward > 0 then
						local moveBonusSet = {}
						moveBonusSet["moveVal"] = moveVal
						moveBonusSet["rewards"] = moveBonusReward
						moveBonusRewards[levelIndex] = moveBonusSet
					end
				end
			end
		end

		if #moveBonusRewards == 3 then
			levelData["moveBonusRewards"] = moveBonusRewards
		else
			dataValid = false
		end
		-- printx(11, "===== moveBonusRewards:", table.tostring(levelData["moveBonusRewards"]))
	end

	-- printx(11, "dataValid, angryBirdsLevelData", dataValid, table.tostringByKeyOrder(levelData))
	-- RemoteDebug:uploadLogWithTag("angryBirdsLevelData!", table.tostring(levelData)) -- Del later: for dev test
	if dataValid then
		playUIDelegate.angryBirdsLevelData = levelData
	else
		playUIDelegate.angryBirdsLevelData = nil
	end
end

MACRO_DEV_START()
function AngryBirdLogic:getTestLevelData(currLevelID)
	local levelData = {}

	------------ 鸟奖励（全局） --------------
	local redReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 3},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 5},
	}
	local blueReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 8},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 15},
	}
	local blackReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 12},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 25},
	}

	local redCriticalReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 2},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 1},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amountMin = 15, amountMax = 20},
	}
	local blueCriticalReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 3},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 2},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amountMin = 20, amountMax = 30},
	}
	local blackCriticalReward = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 4},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 3},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amountMin = 30, amountMax = 40},
	}

	local birdRewards = {}
	birdRewards[AngryBirdSpecies.kRed] = redReward
	birdRewards[AngryBirdSpecies.kBlue] = blueReward
	birdRewards[AngryBirdSpecies.kBlack] = blackReward
	levelData["birdRewards"] = birdRewards
	local birdCriticalRewards = {}
	birdCriticalRewards[AngryBirdSpecies.kRed] = redCriticalReward
	birdCriticalRewards[AngryBirdSpecies.kBlue] = blueCriticalReward
	birdCriticalRewards[AngryBirdSpecies.kBlack] = blackCriticalReward
	levelData["birdCriticalRewards"] = birdCriticalRewards

	------------ +5步奖励（随章节） --------------
	levelData["addFiveRewards"] = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 5},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amountMin = 10, amountMax = 20},
	}

	------------ 过关Boss奖励（随关卡） --------------
	local bossRewards = {}
	local bossReward1 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 3},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 3},
	}
	local bossReward2 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 4},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 6},
	}
	local bossReward3 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 5},
		{rewardID = ItemType.ANGRY_BIRDS_SILVER_TICKET, amount = 9},
	}
	table.insert(bossRewards, bossReward1)
	table.insert(bossRewards, bossReward2)
	table.insert(bossRewards, bossReward3)
	levelData["bossRewards"] = bossRewards

	------------ 过关步数Bonus（随关卡） --------------
	local moveBonusSet = {}
	local moveBonus1 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 5},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 1},
	}
	local moveBonus2 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 10},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 3},
	}
	local moveBonus3 = {
		{rewardID = ItemType.ANGRY_BIRDS_FEATHER, amount = 15},
		{rewardID = ItemType.ANGRY_BIRDS_GOLD_TICKET, amount = 5},
	}
	table.insert(moveBonusSet, {moveVal = 3, rewards = moveBonus1})
	table.insert(moveBonusSet, {moveVal = 5, rewards = moveBonus2})
	table.insert(moveBonusSet, {moveVal = 7, rewards = moveBonus3})
	levelData["moveBonusRewards"] = moveBonusSet

	return levelData
end
MACRO_DEV_END()

------------------------------------ Datas ---------------------------------
function AngryBirdLogic:getAngryBirdsLevelData(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local levelData
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.angryBirdsLevelData then
		levelData = mainLogic.PlayUIDelegate.angryBirdsLevelData 
	end
	-- printx(15,"AngryBirdLogic:getAngryBirdsLevelData",table.tostring(levelData))
	return levelData
end

function AngryBirdLogic:_getRealRewardAmountAfterRandom(rewardDatas)
	if not rewardDatas then return nil end

	local realRewards = {}
	for _, rewardData in pairs(rewardDatas) do
		if rewardData.amount then
			table.insert(realRewards, rewardData)
		else
			if rewardData.amountMin and rewardData.amountMax then
				local maxAmount = tonumber(rewardData.amountMax)
				local minAmount = tonumber(rewardData.amountMin)
				if maxAmount and minAmount and maxAmount >= minAmount and maxAmount > 0 then
					local mainLogic = GameBoardLogic:getCurrentLogic()
					if mainLogic then
						local realAmount = mainLogic.randFactory:rand(minAmount, maxAmount)
						-- if _G.isLocalDevelopMode then RemoteDebug:uploadLogWithTag("===angryBirds===rand-amount-for-"..rewardData.rewardID..":", realAmount) end  --jDelLater
						local realReward = {rewardID = rewardData.rewardID, amount = realAmount}
						table.insert(realRewards, realReward)
					end
				end
			end
		end
	end
	return realRewards
end

MACRO_DEV_START()
-- 鸟打猪奖励
MACRO_DEV_END()
function AngryBirdLogic:getRewardsForBird(birdSpecies)
	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.birdRewards and birdSpecies then 
		return angryBirdData.birdRewards[birdSpecies]
	end
	return nil
end

MACRO_DEV_START()
-- 鸟打猪·会心一击奖励（请注意，涉及随机，每次击打只能调用一次）
MACRO_DEV_END()
function AngryBirdLogic:getRewardsForBirdCritical(birdSpecies)
	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.birdCriticalRewards and birdSpecies then 
		local rawRewards = angryBirdData.birdCriticalRewards[birdSpecies]
		local finalRewards = AngryBirdLogic:_getRealRewardAmountAfterRandom(rawRewards)
		return finalRewards
	end
	return nil
end

MACRO_DEV_START()
-- +5步奖励（请注意，涉及随机，每个+5步只能调用一次）
MACRO_DEV_END()
function AngryBirdLogic:getRewardsForAddFive()
	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.addFiveRewards then 
		local finalRewards = AngryBirdLogic:_getRealRewardAmountAfterRandom(angryBirdData.addFiveRewards)
		return finalRewards
	end
	return nil
end

MACRO_DEV_START()
-- +2步奖励（+5步的一半，请注意，涉及随机，每个+2步只能调用一次）
MACRO_DEV_END()
function AngryBirdLogic:getRewardsForAddTwo()
	local addFiveRewards = AngryBirdLogic:getRewardsForAddFive()
	if addFiveRewards then 
		local finalRewards = {}

		for _, rewardSet in pairs(addFiveRewards) do
			if rewardSet.rewardID and rewardSet.amount then
				local twoStepAmount = math.floor(rewardSet.amount / 2)
				if twoStepAmount > 0 then
					local twoStepReward = {rewardID = rewardSet.rewardID, amount = twoStepAmount}
					table.insert(finalRewards, twoStepReward)
				end
			end
		end

		return finalRewards
	end
	return nil
end

MACRO_DEV_START()
-- 过关时的猪奖励
MACRO_DEV_END()
function AngryBirdLogic:getRewardsForBoss(levelIndex)
	if not levelIndex then
		levelIndex = AngryBirdLogic:getLevelIndexInChapter()
	end

	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.bossRewards and levelIndex then 
		return angryBirdData.bossRewards[levelIndex]
	end
	return nil
end

MACRO_DEV_START()
-- 过每一小关时的过关步数Bonus奖励
MACRO_DEV_END()
function AngryBirdLogic:getCurrRewardsForMoveBonus(currLeftMoves, levelIndex)
	if not currLeftMoves then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			 currLeftMoves = mainLogic.theCurMoves
		end
	end

	local moveRewardSet = AngryBirdLogic:getRewardDataForMoveBonus(levelIndex)
	if moveRewardSet and currLeftMoves then
		local moveCondition = moveRewardSet.moveVal
		if currLeftMoves >= moveCondition then
			return moveRewardSet.rewards
		end
	end
	return nil
end

function AngryBirdLogic:getRewardDataForMoveBonus(levelIndex)
	if not levelIndex then
		levelIndex = AngryBirdLogic:getLevelIndexInChapter()
	end

	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.moveBonusRewards and levelIndex then 
		local moveRewardSet = angryBirdData.moveBonusRewards[levelIndex]
		return moveRewardSet
	end
	return nil
end

function AngryBirdLogic:addAngryBirdsRewards(rewardList)
	if not rewardList or #rewardList <= 0 then return end
	-- printx(11, "addAngryBirdsRewards, reward:", table.tostring(rewardList))

	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if not angryBirdData then return end

	if not angryBirdData["gottenRewards"] then angryBirdData["gottenRewards"] = {} end
	local gottenRewards = angryBirdData["gottenRewards"]

	for _, reward in pairs(rewardList) do
		local oldAmount = gottenRewards[tostring(reward.rewardID)]
		if not oldAmount then oldAmount = 0 end
		gottenRewards[tostring(reward.rewardID)] = oldAmount + reward.amount
	end
	-- printx(11, "addAngryBirdsRewards, curr gottenRewards:", table.tostring(angryBirdData.gottenRewards))
end

function AngryBirdLogic:getGottenAngryBirdsRewards()
	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData then 
		return angryBirdData.gottenRewards
	end
	return nil
end

function AngryBirdLogic:getGottenAngryBirdsRewardAmountByID(itemType)
	local angryBirdData = AngryBirdLogic:getAngryBirdsLevelData()
	if angryBirdData and angryBirdData.gottenRewards then 
		local gottenAmount = angryBirdData.gottenRewards[tostring(itemType)]
		if gottenAmount then
			return gottenAmount
		end
	end
	return 0
end

----------------------------------- Add Five --------------------------------
function AngryBirdLogic.createAngryBirdAddFiveFirstAct(panel)
    local ui = panel:buildInterfaceGroup("newAddStepPanel_tip_22")
    if not ui then
        UIHelper:loadJson("ui/panel_add_step.json")
        ui = UIHelper:getBuilder("ui/panel_add_step.json"):buildGroup("newAddStepPanel_tip_22")
        UIHelper:unloadJson("ui/panel_add_step.json")
    end
    ui = UIHelper:replaceLayer2LayerColor(ui)
    UIHelper:setCascadeOpacityEnabled(ui)

    ui:setPositionY(59)
    ui:setPositionX(-15)

    function ui:setTextColor( color )
        if self.isDisposed then return end
        self:getChildByPath("text"):setColor(color)
    end

    return ui
end

function AngryBirdLogic:onAngryBirdAddMoves(mainLogic, isAddTwo)
	if not mainLogic then return end
	-- printx(11, "=================== AngryBird Add Moves =======================", isAddTwo)
	
	local addMoveRewards
	if isAddTwo then
		addMoveRewards = AngryBirdLogic:getRewardsForAddTwo()
	else
		addMoveRewards = AngryBirdLogic:getRewardsForAddFive()
	end
	if not addMoveRewards or #addMoveRewards <= 0 then return end

	AngryBirdLogic:addAngryBirdsRewards(addMoveRewards)

	AngryBirdLogic:playAddFiveRewardAnimations(addMoveRewards)
end

----------------------------------- UI ----------------------------------------
function AngryBirdLogic:updateBGPosition(gamePlayScene)
	if not gamePlayScene or not gamePlayScene.gameBgNode or not gamePlayScene.gameBoardView then return end

	local gameBg = gamePlayScene.gameBgNode
	local gameBoardView = gamePlayScene.gameBoardView
	local posY = (10 - gameBoardView.startRowIndex) * 70
	local gPos = gameBoardView:convertToWorldSpace(ccp(0, posY))

    local topSpritePosY = gameBg:convertToNodeSpace(ccp(0, gPos.y)).y
    if gameBg.midBg then
    	gameBg.midBg:setPositionY(topSpritePosY - 195)
    end

    if gamePlayScene.topArea then
    	local moveBoard = gamePlayScene.topArea.moveOrTimeCounter
		if moveBoard and not moveBoard.isDisposed and moveBoard.parent then
			local topSpriteMoveBoardPosY = gamePlayScene.topArea:convertToNodeSpace(ccp(0, gPos.y)).y
			local moveBoardSize = moveBoard:getGroupBounds().size

			if moveBoardSize then
				moveBoard:setPositionY(topSpriteMoveBoardPosY + moveBoardSize.height + 30)
			end

			local pigBoss = gamePlayScene.topArea.pigBoss
			if pigBoss and not pigBoss.isDisposed then
				pigBoss:setPositionY(topSpriteMoveBoardPosY+100)
				gamePlayScene.topArea.pigBossPosY = pigBoss:getPositionY()
    			gamePlayScene.topArea.boxAnim:setPositionY(gamePlayScene.topArea.pigBossPosY+120)
				-- printx(15,"pigBoss:getPositionY()",pigBoss:getPositionY())
			end
		end
    end
end

-- 更新收集物泡泡中的数字
function AngryBirdLogic:updateFeatherAmountView(newVal)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then return end

	if not newVal then
		newVal = AngryBirdLogic:getGottenAngryBirdsRewardAmountByID(ItemType.ANGRY_BIRDS_FEATHER)
	end

	local angryTopArea = mainLogic.PlayUIDelegate.topArea
	angryTopArea:updateTargetNumberTo(newVal)
end

function AngryBirdLogic:playAnimsBeforeBonus(finishCallback)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then 
		if finishCallback then finishCallback() end
	end

	local index = mainLogic.currTravelMapIndex
	local isBigBox = false
	local rewards = {}
	if index == 3 then
		isBigBox = true
	end
	rewards = self:getRewardsForBoss(index)
	AngryBirdLogic:addAngryBirdsRewards(rewards)
	local function callback( ... )
		self:playAndAddMoveBonus(finishCallback)
	end
	mainLogic.PlayUIDelegate.topArea:playBoxRewardAnim(rewards,isBigBox,callback)
end

-- 获得步数奖励 & 动画
function AngryBirdLogic:playAndAddMoveBonus(finishCallback)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then 
		if finishCallback then finishCallback() end
	end

	local canGainBonus = false
	local moveBonusReward = AngryBirdLogic:getCurrRewardsForMoveBonus()
	if moveBonusReward and #moveBonusReward > 0 then
		AngryBirdLogic:addAngryBirdsRewards(moveBonusReward)
		mainLogic.moveBonusHarvested = true
		canGainBonus = true
	end

	local angryTopArea = mainLogic.PlayUIDelegate.topArea

	local function onStampAnimCallBack()
		if canGainBonus and angryTopArea and not angryTopArea.isDisposed then
			angryTopArea:playAddMoveBonusAnim(moveBonusReward, finishCallback)
		else
			if finishCallback then finishCallback() end
		end
	end
	angryTopArea:playMoveStampAnimation(canGainBonus, onStampAnimCallBack)
end

function AngryBirdLogic:updateUIAfterChangeBoard()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then 
		return
	end

	local angryTopArea = mainLogic.PlayUIDelegate.topArea
	angryTopArea:updateMoveBonusDisplay()

	-- if angryTopArea.levelNumberLabel then
	-- 	local levelDisplayName = AngryBirdLogic:getLevelDisplayNameStr(mainLogic.level)
	-- 	angryTopArea.levelNumberLabel:setString(levelDisplayName)
	-- end
	AngryBirdLogic:updateLevelNumberLabel(angryTopArea, mainLogic)

	if angryTopArea.moveOrTimeCounter then
		angryTopArea.moveOrTimeCounter:setCount(mainLogic.theCurMoves)
	end
end

function AngryBirdLogic:updateLevelNumberLabel(angryTopArea, mainLogic)
	if not angryTopArea.levelNumberLabel or angryTopArea.levelNumberLabel.isDisposed then return end

	local oldParent = angryTopArea.levelNumberLabel:getParent()
	-- getPosition()在对象被remove后可能返回(0,0)
	local oldPosY = angryTopArea.levelNumberLabel:getPositionY()
	local oldPosX = angryTopArea.levelNumberLabel:getPositionX()
	if not oldParent or not oldPosX or not oldPosY then return end

	angryTopArea.levelNumberLabel:removeFromParentAndCleanup(true)

	local levelDisplayName = AngryBirdLogic:getLevelDisplayNameStr(mainLogic.level)
	-- printx(11, "===== Name?", levelDisplayName, mainLogic.level)
	-- printx(11, "===== Pos xy?", oldPosX, oldPosY)
	-- RemoteDebug:uploadLogWithTag( "AngryBIRDS", "Pos x,y : "..oldPosX, oldPosY)
	-- RemoteDebug:uploadLogWithTag( "AngryBIRDS", "Name?" , levelDisplayName, mainLogic.level)
	local len = math.ceil(string.len(levelDisplayName) / 3)
	local levelNumberLabel = PanelTitleLabel:createWithString(levelDisplayName, len, "fnt/bird2.fnt")
	levelNumberLabel:setScale(0.6)

	angryTopArea.levelNumberLabel = levelNumberLabel
	oldParent:addChild(levelNumberLabel)
	levelNumberLabel:ignoreAnchorPointForPosition(false)
	levelNumberLabel:setAnchorPoint(ccp(0,1))
	levelNumberLabel:setPosition(ccp(oldPosX, oldPosY))

	levelNumberLabel:setExpandDockerType(ExpandDockerType.LEFT)
end

function AngryBirdLogic:getLevelDisplayNameStr(levelID)
	if not levelID then return "" end

	local chapterID = AngryBirdLogic:getChapterID(levelID)
	local levelIndex = AngryBirdLogic:getLevelIndexInChapter()
	local levelDisplayName = "第"..chapterID.."-"..levelIndex.."关"
	return levelDisplayName
end

function AngryBirdLogic:playAddFiveRewardAnimations(rewardList)

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then 
		return
	end
	mainLogic.PlayUIDelegate.topArea:playAddFiveAnim(mainLogic,rewardList)

end

------------------------------- Route ------------------------------------
function AngryBirdLogic:initBirdRouteData(mainLogic, config)
	local tileMap = config.birdRouteRawData
	if not tileMap then return end
	if not mainLogic or not mainLogic.boardmap then return end
	
	for r = 1, #tileMap do 
		if tileMap[r] then
			for c = 1, #tileMap[r] do
				local tileDef = tileMap[r][c]
				if tileDef then
					AngryBirdLogic:_initBirdRoadTypeByConfig(mainLogic, r, c, tileDef)
				end
			end
		end
	end

	local dx = { 0, 1, 0, -1 }
    local dy = { 1, 0, -1, 0 }

	local birdRouteLength = 0
	for r = 1, #mainLogic.boardmap do
		for c = 1, #mainLogic.boardmap[r] do
			local board = mainLogic.boardmap[r][c]

			if AngryBirdLogic:_gridHasBirdRoad(board) and not AngryBirdLogic:_gridHasPrevBirdRoad(board) then
				board.isBirdRoadStart = true
			end

			if not AngryBirdLogic:_gridHasBirdRoad(board) and AngryBirdLogic:_gridHasPrevBirdRoad(board) then
				-- board.isBirdRoadEnd = true
				-- printx(15,"road end",r,c)
				--修改：这个位置一定是弹弓，修改后要保持之前的数据格式，所以要判断弹弓周围的格子
				for i = 1 , 4 do
					local row = r + dx[i]
					local col = c + dy[i]
					if mainLogic:isPosValid(row, col) then
						local prevBoard = mainLogic.boardmap[row][col]
						if AngryBirdLogic:_gridHasBirdRoad(prevBoard) and prevBoard.birdRoadType then
							if ( prevBoard.birdRoadType == 1 and i == 2 ) or
							( prevBoard.birdRoadType == 2 and i == 4 ) or
							( prevBoard.birdRoadType == 3 and i == 1 ) or
							( prevBoard.birdRoadType == 4 and i == 3 ) then

								prevBoard.isBirdRoadEnd = true
								-- printx(15,"road end",row,col)
								-- printx(15,"prevBoard.prevBirdRoadType",prevBoard.birdRoadType)
								-- printx(15,"=============================")
							end
						end
					end
				end


			end

			if AngryBirdLogic:_gridHasBirdRoad(board) then
				birdRouteLength = birdRouteLength + 1
			end

			-- 旅行模式第一屏初始化时因为读不到配置这里无效，需用下面的 scanAndMakeTravelEventBox，后面几屏有效
			-- if board.isTravelEventTile and AngryBirdLogic:travelEventBoxActive(mainLogic) then
			-- 	if mainLogic.gameItemMap[r] and mainLogic.gameItemMap[r][c] then
			-- 		local item = mainLogic.gameItemMap[r][c]
			-- 		item:changeToTravelEventBox()
			-- 	end
			-- end
		end
	end
	mainLogic.currMapbirdRouteLength = birdRouteLength
	-- printx(15,"mainLogic.currMapbirdRouteLength",mainLogic.currMapbirdRouteLength)
end

function AngryBirdLogic:_initBirdRoadTypeByConfig(mainLogic, r, c, tileDef)
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
			boardData.birdRoadType = currDir
			-- printx(11, "set birdRoadType:", currDir, r, c)
		end

		local nextBoardData = mainLogic:safeGetBoardData(nextR, nextC)
		if nextBoardData then
			nextBoardData.prevBirdRoadType = currDir
			-- printx(11, "set prevBirdRoadType:", currDir, r, c)
		end
	end
end

function AngryBirdLogic:_gridHasBirdRoad(boardData)
	if boardData and boardData.birdRoadType and boardData.birdRoadType > 0 then
    	return true
    end
    return false
end

function AngryBirdLogic:_gridHasPrevBirdRoad(boardData)
	if boardData and boardData.prevBirdRoadType and boardData.prevBirdRoadType > 0 then
    	return true
    end
    return false
end

function AngryBirdLogic:getNextGridPositionByDirection(currR, currC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local currGridData = mainLogic:safeGetBoardData(currR, currC)
	if currGridData then
		if currGridData.birdRoadType == RouteConst.kUp then
			return true, currR - 1, currC
		elseif currGridData.birdRoadType == RouteConst.kDown then
			return true, currR + 1, currC
		elseif currGridData.birdRoadType == RouteConst.kLeft then
			return true, currR, currC - 1
		elseif currGridData.birdRoadType == RouteConst.kRight then
			return true, currR, currC + 1
		end
	end
	return false
end

function AngryBirdLogic:convertRoadTypeToAssetDir(roadType)
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

function AngryBirdLogic:posHasSlingAndRoadDir(posR, posC)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return false end
	-- printx(15,"posR,posC",posR,posC)
	--- 上右下左
	local dx = {0, 1, 0, -1}
	local dy = {-1, 0, 1, 0}
	local dirs = {}
	local isSling = false

	local itemData = mainLogic:safeGetItemData(posR, posC)
	if itemData and itemData.ItemType == GameItemType.kSling then
		for dir = 1, 4 do
			local targetRow = posR + dx[dir]
			local targetCol = posC + dy[dir]
			local boardData = mainLogic:safeGetBoardData(targetRow, targetCol)
			if boardData then
				-- return true, dir
				local birdRoadType = boardData.birdRoadType
				-- printx(15,"================",dir,posR,posC)
				-- printx(15,"birdRoadType",birdRoadType,targetRow,targetCol)
				if ( birdRoadType == RouteConst.kUp and dir == 2 )
					or (birdRoadType == RouteConst.kDown and dir == 4)
					or (birdRoadType == RouteConst.kLeft and dir == 3)
					or (birdRoadType == RouteConst.kRight and dir == 1) then
					table.insert(dirs,dir)
					isSling = true
					-- printx(15,"posHasSlingAndRoadDir",dir)
				end
			end
		end

	end
	return isSling,dirs
end

function AngryBirdLogic:addBirdEnergy( mainLogic, r, c, item, extra )
	if not mainLogic then
		return
	end

	if not item.birdEnergy then
		-- printx(15,"nodata!1!!")
		item.birdEnergy = 0
	end

	item.birdEnergy = item.birdEnergy + 1

	if extra then
		item.birdEnergy = item.birdEnergy + 1
	end
	-- printx(15,"======r,c,energy=========",r,c,item.birdEnergy)
	local itemView = mainLogic.boardView.baseMap[r][c]
	itemView.itemSprite[ItemSpriteType.kAngryBirdFigure]:playHitAnimation()

end

------------------------------ Bird ----------------------------------
function AngryBirdLogic:getAngryBirdOnBoard(mainLogic)
	local birds = {}
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kAngryBird then
            	-- return item
            	table.insert(birds,item)
            end
		end
	end

	return birds
end

function AngryBirdLogic:getSlingOnBoard(mainLogic)
	local slings = {}
	if not mainLogic then return nil end
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
            if item.ItemType == GameItemType.kSling then
            	-- return item
            	-- printx(15,"find sling",r,c)
            	table.insert(slings,item)
            end
		end
	end
		
	return slings

end

function AngryBirdLogic:getDirectionByShiftValue(shiftR, shiftC)
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

function AngryBirdLogic:checkNextGridInteractType(bird)
	-- printx(11, "^^^ checkNextGridInteractType", hero.y, hero.x)
	if not bird then
		-- printx(15,"nobird!!!!!")
		return
	end
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	local hasNextGrid, nextR, nextC = AngryBirdLogic:getNextGridPositionByDirection(bird.y, bird.x)
	local nextItemData = mainLogic:safeGetItemData(nextR, nextC)
	-- printx(15,"nextItemData",nextItemData)
	if not hasNextGrid or not mainLogic:isPosValid(nextR, nextC) then 
		return
	end
	return nextItemData
end
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--								前进到的格子的消除逻辑，copy自鱿鱼
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
function AngryBirdLogic:onBirdBombGrid(mainLogic, theAction, index, isdestination)
	local targetItem, forwardDirection = theAction.nextItemList[index], theAction.forwardDirectionList[index]

	if not targetItem then return end

	targetItem:reduceSquidLockValue()
	if targetItem:hasSquidLock() then return end --被复数条鱿鱼锁住，没解锁完

	targetItem:addFallingLockByTravelHero()

	local r, c = targetItem.y, targetItem.x
	-- printx(15,"targetItem.y, targetItem.x",targetItem.y, targetItem.x)
	local targetItemType = targetItem.ItemType
	local targetItemView
	if mainLogic.boardView.baseMap[r] and mainLogic.boardView.baseMap[r][c] then
		targetItemView = mainLogic.boardView.baseMap[r][c]
	end
	local targetBoard
	if mainLogic.boardmap[r] and mainLogic.boardmap[r][c] then
		targetBoard = mainLogic.boardmap[r][c]
		if not isdestination then
			targetBoard.birdRoadType = 0
		else
			targetBoard.isBirdRoadStart = true
		end
	end

	-- printx(15, "Deal with targetItem, itemType:", targetItemType)

	-- 处理覆盖物
	SquidLogic:dealWithCovers(mainLogic, targetItem, targetItemView, targetBoard)

	-- 因为锁层级会和底下之物一并处理，不会阻挡效果，所以先处理完锁之后处理底下之物
	SquidLogic:dealWithLocks(mainLogic, targetItem, targetItemView)


	if isdestination and ( table.includes(specialHandleItem,targetItem.ItemType) or targetItem.coveredByGhost ) then
		--对于等待棋盘稳定才能放招的障碍 处于终点的话 只能强行清数据
		-- printx(15,"specialHandleItem",targetItem.ItemType)
		 targetItem:cleanAnimalLikeData()
	else
		if targetItem:isVisibleAndFree() then
			-- printx(11, "targetItem, isVisibleAndFree")
			local isJustRemoveTarget = false
			-- local forbidNeedUpdate = false

			if SquidLogic:isCommonBombItem(targetItem) then
				BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1)
				SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 3, 1)
				mainLogic:checkItemBlock(r, c)	--虽然解开了鱿鱼锁，但是要是不先checkBlock，isBlock的状态会屏蔽一些地表层的消除检测
				SpecialCoverLogic:SpecialCoverLightUpAtPos(mainLogic, r, c, 1)
			elseif SquidLogic:isJustRemoveItem(targetItem) then
				isJustRemoveTarget = true
			else
				if targetItem.snowLevel > 0 then
					-- printx(15,"消除雪块！！！！！")
					if not isdestination then
						SquidLogic:squidRemoveSnow(mainLogic, targetItem)
					else
						isJustRemoveTarget = true
					end
				elseif targetItemType == GameItemType.kHoneyBottle then
					if targetItem.honeyBottleLevel > 0 and targetItem.honeyBottleLevel <= 3  then
						GameExtandPlayLogic:increaseHoneyBottle(mainLogic, r, c, 3, 1)
					end
				elseif targetItemType == GameItemType.kBottleBlocker then
					GameExtandPlayLogic:decreaseBottleBlocker(mainLogic, r, c , 1 , false, true)
				elseif targetItemType == GameItemType.kPuffer then
					if targetItem.pufferState ~= PufferState.kActivated then
						targetItem.pufferState = PufferState.kActivated
						if targetItemView then
							targetItemView:changePufferState({pufferState = PufferState.kActivated})
						end
					end
					GameExtandPlayLogic:decreasePuffer(mainLogic, r, c)
				elseif targetItemType == GameItemType.kPacman then
					local maxDevourAmount = (mainLogic.pacmanConfig and mainLogic.pacmanConfig.devourCount) or 1
					targetItem.pacmanDevourAmount = maxDevourAmount
					targetItem.pacmanIsSuper = 2
				elseif targetItemType == GameItemType.kSunFlask then
					SunflowerLogic:breakSunFlask(mainLogic, r, c, targetItem.sunFlaskLevel, 1)
					-- 暂缓更新视图：格子上别的东西的视图需要更新，但是此障碍因为要播放触发动画，暂时不能更新
					-- 记得在上面个性化逻辑处理完毕后解temporaryForbidUpdateView锁!
					targetItem.temporaryForbidUpdateView = true
					-- forbidNeedUpdate = true	--会影响动画
				elseif targetItemType == GameItemType.kMissile then
					GameExtandPlayLogic:hitMissile(mainLogic, targetItem, r, c, false, true)
				elseif targetItemType == GameItemType.kDynamiteCrate then
					DynamiteCrateLogic:hitDynamiteCrate(mainLogic, targetItem, r, c, false, true)
				elseif targetItemType == GameItemType.kMagicLamp then
					if targetItem.lampLevel ~= 0 then
						targetItem.needRemoveEventuallyBySquid = true
						GameExtandPlayLogic:onChargeMagicLamp(mainLogic, r, c, 4)
					else
						isJustRemoveTarget = true
					end			
				elseif targetItem.ItemType == GameItemType.kShellGift then
					ShellGiftLogic.hitShellGift(mainLogic,r,c,targetItem)
				elseif targetItem:isBlocker199Active() then
					if targetItem._encrypt.ItemColorType ~= 0 then
						targetItem.needRemoveEventuallyBySquid = true
						GameExtandPlayLogic:matchBlocker199(mainLogic, r, c, 1)
					else
						isJustRemoveTarget = true
					end
				elseif targetItem.ItemType == GameItemType.kSunflower then
					SquidLogic:squidHitSunflower(mainLogic, targetItemView)
				elseif targetItem.ItemType == GameItemType.kBlocker211 then
					if targetItem:canDoBlocker211Collect(0, true) then
						targetItem.needRemoveEventuallyBySquid = true
						GameExtandPlayLogic:doABlocker211Collect(mainLogic, nil, nil, r, c, 0, true, targetItem.subtype)
					else
						-- 置灰冷却时间内，无法触发大招，直接消除
						isJustRemoveTarget = true
					end
				elseif targetItem.ItemType == GameItemType.kTurret then
					isJustRemoveTarget = SquidLogic:dealWithTurretRemove(mainLogic, targetItem)
				elseif targetItem.ItemType == GameItemType.kBlackCuteBall then
					GameExtandPlayLogic:onDecBlackCuteball(mainLogic, targetItem, targetItem.blackCuteStrength)
				elseif targetItem.ItemType == GameItemType.kTotems then
					GameExtandPlayLogic:changeTotemsToWattingActive(mainLogic, r, c, 1, true)
				elseif targetItem.ItemType == GameItemType.kCrystalStone then
					GameExtandPlayLogic:specialCoverInactiveCrystalStone(mainLogic, r, c, 1, true)
				elseif targetItem.ItemType == GameItemType.kBlocker195 then
					GameExtandPlayLogic:doABlocker195Collect(mainLogic, targetItem, nil, nil, r, c, nil, 0, false, true)
					-- 暂缓更新视图：格子上别的东西的视图需要更新，但是此障碍因为要播放触发动画，暂时不能更新
					-- 在此添加锁后，需在ItemView中作相应处理
					-- 记得在上面个性化逻辑处理完毕后解temporaryForbidUpdateView锁!
					targetItem.temporaryForbidUpdateView = true
					-- forbidNeedUpdate = true
				elseif targetItem.ItemType == GameItemType.kRoost then
					targetItem.needRemoveEventuallyBySquid = true
					GameExtandPlayLogic:onUpgradeRoost(mainLogic, targetItem, 3)
				elseif targetItem.ItemType == GameItemType.kMagicStone then
					if targetItem:canMagicStoneBeActive() then
						targetItem.needRemoveEventuallyBySquid = true
						GameExtandPlayLogic:onUpgradeMagicStone(mainLogic, targetItem, true)
					else
						isJustRemoveTarget = true
					end
				elseif targetItem.ItemType == GameItemType.kKindMimosa then
					if #targetItem.mimosaHoldGrid == 0 then
						isJustRemoveTarget = true
					else
						SquidLogic:onSquidHitKindMimosa(mainLogic, targetItem)
					end
				elseif targetItem.ItemType == GameItemType.kWanSheng then
	                WanShengLogic:increaseWanSheng(mainLogic, r, c, 3, 1)
	            elseif targetItem.ItemType == GameItemType.kGyro then
	            	targetItem.gyroLevel = 1
	                GyroLogic:updateGyroLevel(mainLogic, r, c)
	            elseif targetItem.ItemType == GameItemType.kGyroCreater then
	                GyroLogic:removeGyroCreater(mainLogic, r, c)
	            elseif WaterBucketLogic:canAttackWater(targetItem) then
	            	targetItem.temporaryForbidUpdateView = true
	            	WaterBucketLogic:attackWater(mainLogic, r, c, 2)
	            elseif targetItemType == GameItemType.kWindTunnelSwitch then
					WindTunnelLogic:decreaseWindTunnelSwitch(mainLogic, r, c, targetItem.windTunnelSwitchLevel, 1)
					targetItem.temporaryForbidUpdateView = true
				elseif targetItemType == GameItemType.kActivityCollectionItem then
					ActivityClollectionItemLogic:destoryCollectionItem(mainLogic, r, c, true)
				elseif targetItemType == GameItemType.kCanevine then
					CanevineLogic:destroy(mainLogic, targetItem)
				elseif CanevineLogic:is_occupy(targetItem) then
					local rootItemRC = CanevineLogic:get_canevine_root(targetItem)
					local rootItem = mainLogic.gameItemMap[rootItemRC.r][rootItemRC.c]
					rootItem.isNeedUpdate = true
					CanevineLogic:destroy(mainLogic, rootItem)
				elseif targetItemType == GameItemType.kPlane then
					PlaneLogic:onPlaneBeingHit(mainLogic, r, c, 2, 1)
				elseif targetItemType == GameItemType.kCattery or targetItemType == GameItemType.kCatteryEmpty then
					CatteryLogic:tryToDecrease(mainLogic, targetItem, 2)
				elseif targetItemType == GameItemType.kMeow and targetItem.meowLevel > 0 then
					CatteryLogic:decreaseMeow(mainLogic, r, c, 2, 1)
	            end
			end

			if isJustRemoveTarget then
				if theAction.SpecialID and mainLogic:checkSrcSpecialCoverListIsHaveJamSperad(theAction.SpecialID) then
					--强制消除，涂上果酱
					GameExtandPlayLogic:addJamSperadFlag(mainLogic, r, c, true )
				end

				SquidLogic:squidRemoveItemData(mainLogic, targetItem)
				--view
				if targetItemView then
					local spriteLayer
					if targetItemType == GameItemType.kPacmansDen then
						targetItemView:squidDestroyPacmansDenAnimation()	--小窝在Batch层，特殊处理下
					elseif targetItemType == GameItemType.kBlocker199 then
						targetItemView:removeBlocker199View()				--水母外边的圈需要特殊处理，不然消失会滞后……
					else
						targetItemView:squidCommonDestroyItemAnimation(spriteLayer)
					end
				end
			end

			SpecialCoverLogic:tryEffectByJamSperadSpecialAt(mainLogic, r, c, theAction.SpecialID, {})

			-- 这里不能forbidUpdate，否则绳子等的视图就不能更新
			-- if not forbidNeedUpdate then
				targetItem.isNeedUpdate = true
			-- end
			mainLogic:checkItemBlock(r, c)
			-- printx(15,"mainLogic:checkItemBlock(r, c)",mainLogic:checkItemBlock(r, c),r,c)
		else
			if WaterBucketLogic:canAttackBucket(targetItem) then
	        	targetItem.temporaryForbidUpdateView = true
	        	WaterBucketLogic:attackBucket(mainLogic, r, c)
			end

			SpecialCoverLogic:tryEffectByJamSperadSpecialAt(mainLogic, r, c, theAction.SpecialID, {})
			targetItem.isNeedUpdate = true
			mainLogic:checkItemBlock(r, c)
		end

	end

	SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, r, c)
	-- 根据章鱼方向处理绳子和冰柱
	SquidLogic:squidRemoveChainAndRope(mainLogic, forwardDirection, r, c, targetItemView)

	if not isdestination and targetItemView.itemSprite[ItemSpriteType.kBirdRoad] and not targetItemView.itemSprite[ItemSpriteType.kBirdRoad].isDisposed then
		targetItemView.itemSprite[ItemSpriteType.kBirdRoad]:removeFromParentAndCleanup(true)
		targetItemView.itemSprite[ItemSpriteType.kBirdRoad] = nil
	end

	if isdestination then
		local boardData = mainLogic:safeGetBoardData(r, c)
		if boardData then
			-- printx(15, "set birdRoadType:", boardData.birdRoadType, r, c)
			local roadType = boardData.birdRoadType
			if roadType and targetItemView.itemSprite[ItemSpriteType.kBirdRoad] and not targetItemView.itemSprite[ItemSpriteType.kBirdRoad].isDisposed then
				targetItemView.itemSprite[ItemSpriteType.kBirdRoad]:removeFromParentAndCleanup(true)
				targetItemView.itemSprite[ItemSpriteType.kBirdRoad] = nil

				local hasNextGrid, nextR, nextC = AngryBirdLogic:getNextGridPositionByDirection(targetItemView.y, targetItemView.x)
				-- printx(15,"nextR, nextC,targetItemView.y,targetItemView.x",nextR, nextC,targetItemView.y,targetItemView.x)
				if hasNextGrid then
					local newDir
					if nextC == targetItemView.x then
						if targetItemView.y == nextR - 1 then
							-- printx(15,"向下")
							newDir = 3
						else
							-- printx(15,"向上")
							newDir = 1
						end
					else
						if targetItem.x == nextC - 1 then
							-- printx(15,"向右")
							newDir = 2
						else
							-- printx(15,"向左")
							newDir = 4
						end
					end


					
					local roadView = TileBirdRoad:create(nil, nil, nil, nil, true, newDir)
					targetItemView.itemSprite[ItemSpriteType.kBirdRoad] = roadView
					roadView:setScale(1.02)
					local position = UsePropState:getItemPosition(IntCoord:create(targetItem.y, targetItem.x))
					roadView:setPositionXY(position.x,position.y)
				end
			end
		end
	end
end

function AngryBirdLogic:removeAngryBirdDataOfGrid(mainLogic, targetItem)
	-- printx(15,"~~~~~~~~~~~~~~~~~~~~~removeAngryBirdDataOfGrid~~~~~~~~~~~~~~~~~~",birdEnergy)
	targetItem.ItemType = GameItemType.kNone
	targetItem.ItemStatus = GameItemStatusType.kNone
	targetItem.birdEnergy = 0
	targetItem.birdType = 0
	targetItem.birdRoadType = 0

	targetItem.isEmpty = true
	targetItem.isBlock = false
	targetItem.isNeedUpdate = true

	local board = mainLogic.boardmap[targetItem.y][targetItem.x]
	board.isBirdRoadStart = false
	board.isBirdRoadEnd = false
	board.birdRoadType = 0

	-- printx(15,"targetItem.y, targetItem.x",targetItem.y, targetItem.x)
	mainLogic:checkItemBlock(targetItem.y, targetItem.x)

	-- SnailLogic:SpecialCoverSnailRoadAtPos(mainLogic, targetItem.y, targetItem.x)
end

function AngryBirdLogic:checkSlingNeedRemove( mainLogic, sling )
	if not sling then return end

	local row = sling.y
	local col = sling.x
	-- printx(15,"^^^^^^^^^^^^^^^^^^^^^checkSling^^^^^^^^^^^^^^^^^^^^",row,col)
	local dx = { 0, 1, 0, -1 }
    local dy = { -1, 0, 1, 0 }

    local needRemove = true
    for i = 1 , 4 do
    	if mainLogic:isPosValid(row+dx[i], col+dy[i]) then
	    	local board = mainLogic.boardmap[row+dx[i]][col+dy[i]]
	    	local birdRoadType = board.birdRoadType
	    	if board.isBirdRoadEnd then
	    		if ( birdRoadType == RouteConst.kUp and i == 2 )
					or (birdRoadType == RouteConst.kDown and i == 4)
					or (birdRoadType == RouteConst.kLeft and i == 3)
					or (birdRoadType == RouteConst.kRight and i == 1) then


		    		-- printx(15,"find bird still not remove!!!!",i)
		    		needRemove = false
		    	end
	    	end
	    end
    end

    return needRemove
end 

function AngryBirdLogic:refreshAllBlockStateAfterHeroWalk(mainLogic)
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local targetItem = mainLogic.gameItemMap[r][c]
		    if targetItem then
		    	if targetItem.updateLaterByAngryBird then
		    		-- printx(11, "!!!!!!!!!!!!!!!! updateLaterByTravelHero", r, c)
		    		targetItem.updateLaterByAngryBird = false
		    		if not targetItem.skipRemoveFallingLock then
		    			targetItem:removeFallingLockByTravelHero()
		    		end

			    	mainLogic:checkItemBlock(r, c)
					mainLogic:addNeedCheckMatchPoint(r , c)
					mainLogic.gameMode:checkDropDownCollect(r, c)

					if targetItem.ItemType == GameItemType.kAngryBird then
						targetItem.walkingDirection = nil

						if mainLogic.boardView and mainLogic.boardView.baseMap and mainLogic.boardView.baseMap[r] then
							local itemView = mainLogic.boardView.baseMap[r][c]
							if itemView then
								-- itemView:playTravelHeroBackToIdle()
							end
						end
					end
		    	end
		    end
		end
	end
end

function AngryBirdLogic:handlePigBoss( mainLogic , birdType )
	local pigDie = false
	local closeDie = false
	local baoji = false
	if mainLogic.angryBirdNum == 0 then
		pigDie = true
	elseif mainLogic.angryBirdNum == 1 then
		closeDie = true
	end

	if mainLogic.PlayUIDelegate.topArea.baojiState and mainLogic.PlayUIDelegate.topArea.baojiState == 0 then
		if mainLogic.theCurMoves <= 3 and mainLogic.currMapbirdRouteLength >= 10 then
			-- printx(15,"baoji!!!!!!!!!!!!!!!!!")
			baoji = true
			mainLogic.PlayUIDelegate.topArea.baojiState = 1
		end
	end


	local rewardList = AngryBirdLogic:getRewardsForBird(birdType)
	if baoji then
		rewardList = AngryBirdLogic:getRewardsForBirdCritical(birdType)
	end

	-- local rewardList = AngryBirdLogic:getRewardsForBirdCritical(birdType)
	AngryBirdLogic:addAngryBirdsRewards(rewardList)--这加数据，视图后面更新
	mainLogic.PlayUIDelegate.topArea:onHit(birdType , rewardList, pigDie, closeDie,baoji)

end

function AngryBirdLogic:refreshUIafterChangeBoard( mainLogic,revert )
	-- printx(15,"mainLogic.needResetPropUseTimes",mainLogic.needResetPropUseTimes)
	--这块设计的不好 但是没时间改了，主要记录一下问题
	--首先道具使用次数重置就应该在切屏前进行，否则的话闪退恢复相当于先拿错误的数据把道具使用次数设值，然后再根据断面里的标记重置
	--之所以一开始设计成放在切屏完成的是希望切屏后置灰的道具才重新发亮，但是实际上可以先把数据设置正确，切完屏再把视图刷新
	--而且这样就不存在需要兼容闪退恢复的问题了，因为断面的数据是对的
	--最后除了动画尽量别用setTimeOut
	if mainLogic.needResetPropUseTimes then
		local delay = 0
		if mainLogic.replayMode == ReplayMode.kResume or mainLogic.replayMode == ReplayMode.kSectionResume then
			delay = 1
		end
		setTimeOut(function ( ... )
			if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.propList or not mainLogic.PlayUIDelegate.propList.leftPropList then
				return
			end
			local leftPropList = mainLogic.PlayUIDelegate.propList.leftPropList
			
			for i = 1 ,#propsList do
				-- printx(15,"leftPropList:findItemByItemID(propsList[i])",leftPropList:findItemByItemID(propsList[i]))--一个PropListItem对象
				local item = leftPropList:findItemByItemID(propsList[i])
				if item then
					item:resetUseTimes()
				end
			end
			-- printx(15,"hideAddMoveItem!!!!!!!!!!!!!!!!")
			leftPropList:hideAddMoveItem()
			if leftPropList.handAnim and not leftPropList.handAnim.isDisposed then
		        leftPropList.handAnim:removeFromParentAndCleanup(true)
		        leftPropList.handAnim = nil
		    end
		    mainLogic.needResetPropUseTimes = false
		end,delay)
		
	end

	mainLogic.PlayUIDelegate.topArea:initPigBoss(revert)
	mainLogic.PlayUIDelegate.topArea:refreshCollectProgress()
	ActCollectionLogic:refreshProgressBarPosition()
	AngryBirdLogic:updateBGPosition(mainLogic.PlayUIDelegate)
	if not revert then
		local birds = {}
		birds = self:getAngryBirdOnBoard(mainLogic)
		mainLogic.angryBirdNum = #birds
		mainLogic.PlayUIDelegate.topArea.moveOrTimeCounter:stopShaking()
	end
	self:updateUIAfterChangeBoard()
end

function AngryBirdLogic:handleBoardState( mainLogic, delegate, finishCallback )

	if not mainLogic or not delegate then
		return
	end

	if mainLogic.PlayUIDelegate.topArea.playingRewardAnim then
		delegate.needCheckingContinuously = true
	else
		delegate.needCheckingContinuously = false
		AngryBirdLogic:playAnimsBeforeBonus(finishCallback)
	end
end	

function AngryBirdLogic:replaceEndData( mainLogic, action )
	if not mainLogic or not action then
		return
	end
	if action.tempBirdView and not action.tempBirdView.isDisposed then
			--还需要一个判断 终点的itemType是空
		action.tempBirdView:stop()
		action.tempBirdView:removeFromParentAndCleanup(true)
	end
	local dest = action.nextItemList[action.walkSteps]
	local destRow = dest.y
	local destCol = dest.x
	dest:removeFallingLockByTravelHero()--解锁
	local itemView = mainLogic.boardView.baseMap[destRow][destCol]
	-- local sprite = TileAngryBird:create(action.birdType)
	-- itemView.itemSprite[ItemSpriteType.kAngryBirdFigure] = sprite
	-- dest.ItemType = GameItemType.kAngryBird
	
	-- local position = UsePropState:getItemPosition(
	-- 	IntCoord:create(destRow,destCol)
	-- 	)

	-- sprite:setPosition(position)
	-- itemView.isNeedUpdate = true

	local gameItemdata = mainLogic.gameItemMap[destRow][destCol]
	gameItemdata.birdEnergy = action.birdEnergy or 0
	gameItemdata.ItemType = GameItemType.kAngryBird
	gameItemdata.isBlock = true
	gameItemdata.isEmpty = false
	gameItemdata.ItemStatus = GameItemStatusType.kNone
	gameItemdata.birdType = action.birdType
	gameItemdata.isNeedUpdate = true

	mainLogic:checkItemBlock(destRow, destCol)
end		