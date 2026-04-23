WeeklyRace2020Logic = class{}

WeeklyRace2020ChestType =
{
	kSilverChest = 2,
	kGoldenChest = 3,
	kJewelChest = 4,
}

function WeeklyRace2020Logic:isWeeklyRace2020Level(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > 0 then
		if LevelType:isWeeklyRace2020Level(levelID) then
			return true
		end
	end
	return false
end

function WeeklyRace2020Logic:getWeeklyRace2020LevelConfig()
	if WeeklyRace2020Mgr.getInstance() then
		return WeeklyRace2020Mgr.getInstance():getLevelConfig()
	end
	return nil
end

function WeeklyRace2020Logic:getWeeklyRace2020PetCostume()
	local curDress = {1, 10001}
	pcall(function ( ... )
		require 'zoo.weeklyRace2020.data.WeeklyRace2020Mgr'
		if WeeklyRace2020Mgr 
			and WeeklyRace2020Mgr.getInstance() 
			and WeeklyRace2020Mgr.getInstance().data
			and WeeklyRace2020Mgr.getInstance().data.data
			and WeeklyRace2020Mgr.getInstance().data.data.petInfo
			and WeeklyRace2020Mgr.getInstance().data.data.petInfo.decorationIds
			then
			curDress = WeeklyRace2020Mgr.getInstance().data.data.petInfo.decorationIds
		end
	end)
	return curDress
end

function WeeklyRace2020Logic:getWeeklyRace2020LevelData(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local levelData
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.weeklyRace2020LevelData then
		-- printx(11, " get weeklyRace2020LevelData", table.tostring(mainLogic.PlayUIDelegate.weeklyRace2020LevelData))
		levelData = mainLogic.PlayUIDelegate.weeklyRace2020LevelData 
	end

	return levelData
end

function WeeklyRace2020Logic:setWeeklyRace2020LevelDataForLevel(playUIDelegate)
    -- printx(11, "==== WeeklyRace2020Logic:setWeeklyRace2020LevelDataForLevel", debug.traceback())
    if not playUIDelegate then return end
    -- if not WeeklyRace2020Mgr.getInstance():isInMainTime() then return end

    local currentLevelID = playUIDelegate.levelId

    local configData = WeeklyRace2020Logic:getWeeklyRace2020LevelConfig()
    -- printx(11, "==== configData ?", table.tostring(configData))
    if not configData then 
    	if _G.isLocalDevelopMode then
    		playUIDelegate.weeklyRace2020LevelData = WeeklyRace2020Logic:getTestLevelData(currentLevelID) --testt
    		-- printx(11, "DATA:", table.tostring(playUIDelegate.weeklyRace2020LevelData))
    	end
    	return 
    end

    local levelData = {}
    local dataValid = true

    -- 后续关关卡区段
    if configData.levelBIdRange and #configData.levelBIdRange == 2 then
    	levelData["tailLevelRange"] = table.clone(configData.levelBIdRange)
    else
    	dataValid = false
    end

    -- 第二集：改回读取关卡配置
    -- 收集物宝箱奖励最小/大值
    -- if configData.minShells and configData.maxShells then
    -- 	levelData["collectionChestMinVolume"] = configData.minShells
    -- 	levelData["collectionChestMaxVolume"] = configData.maxShells
    -- else
    -- 	dataValid = false
    -- end

    local function getFinalChestRewards(configReward)
    	local rewardData
    	if configReward then
    		for _, rewardSetWithType in pairs(configReward) do
    			-- type用于区分完整装扮ID与通用道具ID，产品承诺此处不会有完整装扮，故忽略type
    			if rewardSetWithType and rewardSetWithType.reward 
    				and rewardSetWithType.reward.itemId and rewardSetWithType.reward.num then
    				local singleReward = {}
    				singleReward["rewardID"] = rewardSetWithType.reward.itemId
					singleReward["amount"] = rewardSetWithType.reward.num

					if not rewardData then rewardData = {} end
					table.insert(rewardData, singleReward)
    			end
    		end
    	end
    	return rewardData
    end

    -- 终点金宝箱奖励内容
    local goldRewards = getFinalChestRewards(configData.goldRewards)
    if goldRewards then
    	levelData["finalGoldenChestRewards"] = goldRewards
    else
    	dataValid = false
    end

    -- 终点银宝箱奖励内容
    local silverRewards = getFinalChestRewards(configData.sliverRewards)
    if silverRewards then
    	levelData["finalSilverChestRewards"] = silverRewards
    else
    	dataValid = false
    end

    -- 宠物装扮存一下，闪退恢复回来不用从关卡外获取了
    levelData["petCostume"] = WeeklyRace2020Logic:getWeeklyRace2020PetCostume()

    -- printx(11, "dataValid, WeeklyRace2020LevelData", dataValid, table.tostring(levelData))
    -- RemoteDebug:uploadLogWithTag("WeeklyRace2020LevelData!", table.tostring(levelData)) -- Del later: for dev test
    if dataValid then
        playUIDelegate.weeklyRace2020LevelData = levelData
    else
    	playUIDelegate.weeklyRace2020LevelData = nil
    end
end

MACRO_DEV_START()
function WeeklyRace2020Logic:getTestLevelData(currLevelID)
	local levelData = {}

	-- levelData["headLevelRange"] = "380001,380018" 		--第一关关卡区段
	levelData["tailLevelRange"] = {381001, 381018} 			--后续关关卡区段

	levelData["collectionChestMinVolume"] = 50 				--收集物宝箱奖励最小值
	levelData["collectionChestMaxVolume"] = 100 			--收集物宝箱奖励最大值

	local goldRewards = {}
	local goldReward1 = {}
	goldReward1["rewardID"] = ItemType.WEEKLY_RACE_2020_SHELL
	goldReward1["amount"] = 60
	table.insert(goldRewards, goldReward1)
	local goldReward2 = {}
	goldReward2["rewardID"] = ItemType.WEEKLY_RACE_2020_COSTUME_TICKET
	goldReward2["amount"] = 3
	table.insert(goldRewards, goldReward2)

	local silverRewards = {}
	local silverReward1 = {}
	silverReward1["rewardID"] = ItemType.WEEKLY_RACE_2020_SHELL
	silverReward1["amount"] = 40
	table.insert(silverRewards, silverReward1)
	local silverReward2 = {}
	silverReward2["rewardID"] = ItemType.WEEKLY_RACE_2020_COSTUME_TICKET
	silverReward2["amount"] = 3
	table.insert(silverRewards, silverReward2)

	levelData["finalGoldenChestRewards"] = goldRewards 		 	--终点金宝箱奖励内容
	levelData["finalSilverChestRewards"] = silverRewards 		--终点银宝箱奖励内容

	levelData["petCostume"] = {1, 10001}

	-- if not currLevelID then currLevelID = 380001 end
	-- levelData["levelList"] = {}
	-- table.insert(levelData["levelList"], currLevelID)

	return levelData
end
MACRO_DEV_END()

function WeeklyRace2020Logic:addGottenTicketAmount(itemType, amount)
	local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()
	if not raceLevelData then return end

	if itemType == ItemType.WEEKLY_RACE_2020_COSTUME_TICKET then
		if not raceLevelData["gottenTickets"] then raceLevelData["gottenTickets"] = {} end
		local oldAmount = raceLevelData["gottenTickets"][tostring(itemType)]
		if not oldAmount then oldAmount = 0 end
		raceLevelData["gottenTickets"][tostring(itemType)] = oldAmount + amount
	end

	-- printx(11, "addGottenTicketAmount:raceLevelData", table.tostring(raceLevelData))
end

function WeeklyRace2020Logic:getGottenTicketAmount(itemType)
	if not itemType then return 0 end

	local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()
	if raceLevelData and raceLevelData.gottenTickets and raceLevelData.gottenTickets[tostring(itemType)] then
		return raceLevelData.gottenTickets[tostring(itemType)]
	end
	return 0
end

---------------------------------- Chest ---------------------------------
---- Data ----
function WeeklyRace2020Logic:initWeeklyRace2020ChestData()
	local chestData = {}

	chestData.weeklyRace2020ChestType = 0				-- 新周赛宝箱类型，1-3，铜银金宝箱，4，宝石宝箱
	chestData.weeklyRace2020ChestLayer = 0				-- 新周赛大宝箱剩余层数
	chestData.weeklyRace2020ChestLayerHP = 0			-- 新周赛大宝箱本层剩余HP

	chestData.weeklyRace2020ChestJewel = 0				-- 新周赛宝石宝箱宝石数量

	chestData.isWeeklyRace2020ChestRoot = false 		-- 新周赛大宝箱左上角
	chestData.weeklyRace2020ChestDecreaseLock = false	-- 为true时不允许接受攻击

	return chestData
end

function WeeklyRace2020Logic:setWeeklyRace2020FinalChestData(itemData, chestTypeFlag)
	if not itemData.weeklyRace2020ChestData then 
		itemData.weeklyRace2020ChestData = WeeklyRace2020Logic:initWeeklyRace2020ChestData() 
	end
	local chestData = itemData.weeklyRace2020ChestData

	if chestTypeFlag == 4 then --占位格
		chestData.isWeeklyRace2020ChestRoot = false
	else
		chestData.isWeeklyRace2020ChestRoot = true
		chestData.weeklyRace2020ChestType = chestTypeFlag
		chestData.weeklyRace2020ChestLayerHP = WeeklyRace2020Logic:getMaxHPByChestType(chestTypeFlag)
		chestData.weeklyRace2020ChestLayer = chestTypeFlag
	end
end

function WeeklyRace2020Logic:setWeeklyRace2020JewelChestData(itemData, chestTypeFlag, addInfo)
	if not itemData.weeklyRace2020ChestData then 
		itemData.weeklyRace2020ChestData = WeeklyRace2020Logic:initWeeklyRace2020ChestData() 
	end
	local chestData = itemData.weeklyRace2020ChestData

	if chestTypeFlag == 2 then --占位格
		chestData.isWeeklyRace2020ChestRoot = false
	else
		local chestType = WeeklyRace2020ChestType.kJewelChest --配置标记转化为逻辑标记
		chestData.isWeeklyRace2020ChestRoot = true
		chestData.weeklyRace2020ChestType = chestType
		chestData.weeklyRace2020ChestLayerHP = WeeklyRace2020Logic:getMaxHPByChestType(chestType)
		chestData.weeklyRace2020ChestLayer = 2

		-- addInfo作废，改用配置
		-- 第二集：没删代码真是太明智了，产品回心转意，我胡汉三又回来了？？
		if addInfo then
			local addInfoArr = string.split(addInfo, "|")
			if addInfoArr and #addInfoArr >= 2 then
				local jewelMaxAmount = tonumber(addInfoArr[2])
				local jewelMinAmount = tonumber(addInfoArr[1])
				if jewelMaxAmount and jewelMinAmount and jewelMaxAmount >= jewelMinAmount and jewelMaxAmount > 0 then
					local mainLogic = GameBoardLogic:getCurrentLogic()
					if mainLogic then
						chestData.weeklyRace2020ChestJewel = mainLogic.randFactory:rand(jewelMinAmount, jewelMaxAmount)
						-- if _G.isLocalDevelopMode then RemoteDebug:uploadLogWithTag("===weeklyRace2020===shell_amount_for_shell-chest:", chestData.weeklyRace2020ChestJewel) end  --jDelLater
					end
				end
			end
		end

		-- -- 多屏旅行模式第一屏初始化时因为读不到配置这里无效，需用下面的 scanAndUpdateJewelChestByConfig，后面几屏有效
		-- local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()
		-- if raceLevelData and raceLevelData.collectionChestMaxVolume and raceLevelData.collectionChestMinVolume then
		-- 	local jewelMaxAmount = tonumber(raceLevelData.collectionChestMaxVolume)
		-- 	local jewelMinAmount = tonumber(raceLevelData.collectionChestMinVolume)
		-- 	if jewelMaxAmount and jewelMinAmount and jewelMaxAmount >= jewelMinAmount and jewelMaxAmount > 0 then
		-- 		local mainLogic = GameBoardLogic:getCurrentLogic()
		-- 		if mainLogic then
		-- 			chestData.weeklyRace2020ChestJewel = mainLogic.randFactory:rand(jewelMinAmount, jewelMaxAmount)
		-- 		end
		-- 	end
		-- end
	end
end

-- 第二集：又不从活动配置中读取了
-- function WeeklyRace2020Logic:scanAndUpdateJewelChestByConfig(mainLogic)
-- 	-- printx(11, "******************** WeeklyRace2020Logic:scanAndUpdateJewelChestByConfig ! ******************************")
-- 	local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()

-- 	if mainLogic and raceLevelData and raceLevelData.collectionChestMaxVolume and raceLevelData.collectionChestMinVolume then
-- 		local jewelMaxAmount = tonumber(raceLevelData.collectionChestMaxVolume)
-- 		local jewelMinAmount = tonumber(raceLevelData.collectionChestMinVolume)
-- 		if jewelMaxAmount and jewelMinAmount and jewelMaxAmount >= jewelMinAmount and jewelMaxAmount > 0 then

-- 			local function checkAndSetJewelData(gameItem)
-- 				if gameItem and WeeklyRace2020Logic:isWeeklyRace2020Chest(gameItem.ItemType) and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(gameItem) then
-- 					local chestData = gameItem.weeklyRace2020ChestData
-- 					if chestData and WeeklyRace2020Logic:isWeeklyRace2020JewelChest(chestData.weeklyRace2020ChestType) 
-- 						and chestData.weeklyRace2020ChestJewel <= 0
-- 						then
-- 						chestData.weeklyRace2020ChestJewel = mainLogic.randFactory:rand(jewelMinAmount, jewelMaxAmount)
-- 						-- printx(11, "set chest Jewel!", chestData.weeklyRace2020ChestJewel)
-- 					end
-- 				end
-- 			end

-- 			for r = 1, #mainLogic.gameItemMap do
-- 				for c = 1, #mainLogic.gameItemMap[r] do
-- 					local item = mainLogic.gameItemMap[r][c]
-- 					checkAndSetJewelData(item)
-- 				end
-- 			end

-- 			if mainLogic.digItemMap and #mainLogic.digItemMap > 0 then
-- 				for r = 1, #mainLogic.digItemMap do
-- 					for c = 1, #mainLogic.digItemMap[r] do 
-- 						local item = mainLogic.digItemMap[r][c]
-- 						checkAndSetJewelData(item)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end

function WeeklyRace2020Logic:getMaxHPByChestType(chestType)
	-- do return 1 end
	if WeeklyRace2020Logic:isWeeklyRace2020JewelChest(chestType) then
		return 2
	else
		return 4
	end
end

function WeeklyRace2020Logic:compareWeeklyRace2020ChestData(oldItemData, newItemData)
	local chestDataChanged = false
	local newDataHasChest = false

	local oldChestData = oldItemData.weeklyRace2020ChestData
	local newChestData = newItemData.weeklyRace2020ChestData

	if oldChestData and newChestData then
		if oldChestData.weeklyRace2020ChestLayerHP ~= newChestData.weeklyRace2020ChestLayerHP 
			or oldChestData.weeklyRace2020ChestLayer ~= newChestData.weeklyRace2020ChestLayer 
			then
			chestDataChanged = true
		end
	elseif not oldChestData and not newChestData then
		-- no changes
	else
		chestDataChanged = true
	end

	if newChestData then
		if newChestData.isWeeklyRace2020ChestRoot 
			and newChestData.weeklyRace2020ChestLayerHP > 0 
			and newChestData.weeklyRace2020ChestLayer > 0 
			then 
			newDataHasChest = true
		end
	end

	-- printx(11, "++++++++++++++++++++ COMPARE!!! +++++++++++++++++++++++", chestDataChanged, newDataHasChest)
	return chestDataChanged, newDataHasChest
end

function WeeklyRace2020Logic:isWeeklyRace2020Chest(itemType)
	if itemType == GameItemType.kWeeklyRace2020Chest or itemType == GameItemType.kWeeklyRace2020JewelChest then
		return true
	end
	return false
end

function WeeklyRace2020Logic:isWeeklyRace2020JewelChest(chestType)
	if chestType == WeeklyRace2020ChestType.kJewelChest then
		return true
	end
	return false
end

function WeeklyRace2020Logic:getWeeklyRace2020ChestType(itemData)
	if itemData and itemData.weeklyRace2020ChestData then
		return itemData.weeklyRace2020ChestData.weeklyRace2020ChestType
	end
	return 0
end

function WeeklyRace2020Logic:getWeeklyRace2020ChestLayerHP(itemData)
	if itemData and itemData.weeklyRace2020ChestData then
		return itemData.weeklyRace2020ChestData.weeklyRace2020ChestLayerHP
	end
	return 0
end

function WeeklyRace2020Logic:getWeeklyRace2020ChestLayer(itemData)
	if itemData and itemData.weeklyRace2020ChestData then
		return itemData.weeklyRace2020ChestData.weeklyRace2020ChestLayer
	end
	return 0
end

function WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(itemData)
	if itemData and itemData.weeklyRace2020ChestData then
		return itemData.weeklyRace2020ChestData.isWeeklyRace2020ChestRoot
	end
	return false
end

function WeeklyRace2020Logic:setWeeklyRace2020ChestDecreaseLock(itemData, flag)
	if itemData and itemData.weeklyRace2020ChestData then
		itemData.weeklyRace2020ChestData.weeklyRace2020ChestDecreaseLock = flag
	end
end

--- Action ---
function WeeklyRace2020Logic:isHittableWeeklyRace2020Chest(itemData)
	if itemData and WeeklyRace2020Logic:isWeeklyRace2020Chest(itemData.ItemType) and itemData.weeklyRace2020ChestData then
		local chestData = itemData.weeklyRace2020ChestData
		if chestData.isWeeklyRace2020ChestRoot and chestData.weeklyRace2020ChestLayerHP > 0 and not chestData.weeklyRace2020ChestDecreaseLock then
			return true
		end
	end
	return false
end

function WeeklyRace2020Logic:tryDecreaseWeeklyRace2020Chest(mainLogic, item)
	if not item or not WeeklyRace2020Logic:isWeeklyRace2020Chest(item.ItemType) then return end

	local chestRootItem = WeeklyRace2020Logic:getChestRoot(mainLogic, item)
	if not chestRootItem or not WeeklyRace2020Logic:isHittableWeeklyRace2020Chest(chestRootItem) then return end

	local updateChestDurationDelay = 20
	local isFinalHitOfLayer = false
	local isFinalHitOfAll = false
	local isJewelChest = false
	local chestData = chestRootItem.weeklyRace2020ChestData
	if chestData then
		if chestData.weeklyRace2020ChestLayerHP == 1 then
			if chestData.weeklyRace2020ChestLayer == 1 then
				isFinalHitOfAll = true
			else
				isFinalHitOfLayer = true
			end
		end
		if WeeklyRace2020Logic:isWeeklyRace2020JewelChest(chestData.weeklyRace2020ChestType) then
			isJewelChest = true
		end
	end
	if isFinalHitOfAll then
		if isJewelChest then
			updateChestDurationDelay = 150
		else
			updateChestDurationDelay = 180
		end
	end

	WeeklyRace2020Logic:setWeeklyRace2020ChestDecreaseLock(chestRootItem, true)
	local action = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_WeeklyRace2020_Chest_Hit, 
		nil,
		nil,
		GamePlayConfig_MaxAction_time
		)
	action.targetItem = chestRootItem
	action.isFinalHitOfAll = isFinalHitOfAll
	action.isFinalHitOfLayer = isFinalHitOfLayer
	action.isJewelChest = isJewelChest
	action.updateChestDurationDelay = updateChestDurationDelay
	mainLogic:addDestroyAction(action)
	mainLogic:setNeedCheckFalling()
end

function WeeklyRace2020Logic:getChestRoot(mainLogic, chestGridItem)
	if chestGridItem and WeeklyRace2020Logic:isWeeklyRace2020Chest(chestGridItem.ItemType) then
		if  WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(chestGridItem) then
			return chestGridItem
		else
			local checkShiftX = {-1, 0, -1}
			local checkShiftY = {0, -1, -1}
			for i = 1, 3 do
				local checkItem = mainLogic:safeGetItemData(chestGridItem.y + checkShiftY[i], chestGridItem.x + checkShiftX[i])
				if checkItem 
					and WeeklyRace2020Logic:isWeeklyRace2020Chest(checkItem.ItemType) 
					and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(checkItem) 
					then
					return checkItem
				end
			end
		end
	end
	return nil
end

function WeeklyRace2020Logic:onWeeklyRace2020ChestDecreaseLayer(targetChest)
	if targetChest and targetChest.weeklyRace2020ChestData then
		local chestData = targetChest.weeklyRace2020ChestData
		if chestData.weeklyRace2020ChestLayer > 1 then
			chestData.weeklyRace2020ChestLayer = chestData.weeklyRace2020ChestLayer - 1
			chestData.weeklyRace2020ChestLayerHP = WeeklyRace2020Logic:getMaxHPByChestType(chestData.weeklyRace2020ChestType)
			WeeklyRace2020Logic:setWeeklyRace2020ChestDecreaseLock(targetChest, true)
		end
	end
end

function WeeklyRace2020Logic:onWeeklyRace2020ChestDestroyed(mainLogic, targetChest)
	if targetChest then

		local targetChestDestroyed = false
		if targetChest.weeklyRace2020ChestData then
			if WeeklyRace2020Logic:isWeeklyRace2020JewelChest(targetChest.weeklyRace2020ChestData.weeklyRace2020ChestType) then
				-- addJewel
				WeeklyRace2020Logic:_onWeeklyRace2020JewelChestDestroyed(mainLogic, targetChest)
			else
				WeeklyRace2020Logic:_onWeeklyRace2020FinalChestDestroyed(mainLogic, targetChest)
			end
			targetChestDestroyed = true
		end

		local chestShiftX = {0, 1, 0, 1}
		local chestShiftY = {0, 0, 1, 1}
		for i = 1, 4 do
			local currX = targetChest.y + chestShiftX[i]
			local currY = targetChest.x + chestShiftY[i]
			local targetItem = mainLogic:safeGetItemData(currX, currY)

			targetItem:cleanAnimalLikeData()
			targetItem.isNeedUpdate = true
			mainLogic:checkItemBlock(targetItem.y, targetItem.x)
		end

		mainLogic:addScoreToTotal(targetChest.y, targetChest.x, 1000)


		if targetChestDestroyed then
			mainLogic.PlayUIDelegate.topArea:onWeeklyRace2020ChestDestroyed(mainLogic)
		end

		WeeklyRace2020Mgr.getInstance():addChestDestroyedInLevel()

	end
end

function WeeklyRace2020Logic:_onWeeklyRace2020FinalChestDestroyed(mainLogic, targetChest)
	if not mainLogic then return end

	local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()
	if not raceLevelData then return end

	local chestType = WeeklyRace2020Logic:getWeeklyRace2020ChestType(targetChest)
	local finalChestRewards
	if chestType == WeeklyRace2020ChestType.kSilverChest then
		finalChestRewards = raceLevelData.finalSilverChestRewards
	elseif chestType == WeeklyRace2020ChestType.kGoldenChest then
		finalChestRewards = raceLevelData.finalGoldenChestRewards
	end
	if finalChestRewards then
		for _, rewardSet in pairs(finalChestRewards) do
			local rewardID = rewardSet.rewardID
			local rewardAmount = rewardSet.amount
			if rewardAmount > 0 then
				if rewardID == ItemType.WEEKLY_RACE_2020_SHELL then
					WeeklyRace2020Logic:addJewelAmount(mainLogic, rewardAmount, targetChest.y, targetChest.x, false)
				elseif rewardID == ItemType.WEEKLY_RACE_2020_COSTUME_TICKET then
					WeeklyRace2020Logic:addGottenTicketAmount(rewardID, rewardAmount)
				end
			end
		end
	end

	local nextLevelID = WeeklyRace2020Logic:_getNextLevelID(mainLogic)
	-- printx(11, "~~~~~~~~~ Rand next level ID:", nextLevelID)
	-- if _G.isLocalDevelopMode then RemoteDebug:uploadLogWithTag("===weeklyRace2020===nextLevelID:", nextLevelID) end --jDelLater
	if nextLevelID then
		mainLogic.nextBoardLevelID = nextLevelID
	else
		mainLogic.nextBoardLevelID = mainLogic.level --容错，正常应无此种情况
	end

	-- 为了动画，步数数据在 checkPlayWeeklyRace2020ChestOpenAnimation 中增加
	-- mainLogic.theCurMoves = mainLogic.theCurMoves + 10
	-- mainLogic.hasAddMoveStep = {source = "WeeklyRace2020Chest" , steps = 10}
	-- if mainLogic.PlayUIDelegate then
	-- 	local function callback( ... )
	-- 		mainLogic.PlayUIDelegate:setMoveOrTimeCountCallback(mainLogic.theCurMoves, false)
	-- 	end
	-- 	local r, c = targetChest.y, targetChest.x
	-- 	local pos = mainLogic:getGameItemPosInView_ForPreProp(r,c)
	-- 	local icon = Sprite:createWithSpriteFrameName("blocker_weeklyRace2020_add_move_10_0000")
	-- 	local scene = Director:sharedDirector():getRunningScene()
	-- 	local animation = PrefixPropAnimation:createAddMoveAnimation(icon, 0, callback, nil, ccp(pos.x + 50, pos.y + 20))
	-- 	scene:addChild(animation)
	-- end
end

function WeeklyRace2020Logic:_getNextLevelID(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return nil end

	local raceLevelData = WeeklyRace2020Logic:getWeeklyRace2020LevelData()
	if raceLevelData and raceLevelData.tailLevelRange and #raceLevelData.tailLevelRange == 2 then
		local levelRangeArr = raceLevelData.tailLevelRange
		local startLevelID = tonumber(levelRangeArr[1])
		local endLevelID = tonumber(levelRangeArr[2])
		local levelAmount = endLevelID - startLevelID + 1
		-- printx(11, "startLevelID, endLevelID, levelAmount", startLevelID, endLevelID, levelAmount, mainLogic.traveledLevelRecord)
		if levelAmount <= 0 then return nil end

		local newLevelID

		-- 规则：首关后的随机关卡中，前10个随机出的关卡不能重复，从第11个开始，不再在乎是否重复
		-- 产品保证关卡池内关卡多于10关
		if not mainLogic.traveledLevelRecord then mainLogic.traveledLevelRecord = {} end
		local lastUsedLevels = mainLogic.traveledLevelRecord
		if #lastUsedLevels > 0 and #lastUsedLevels < 10 and levelAmount > 10 then
			while (not newLevelID) do
				local levelIndex = mainLogic.travelMapRandFactory:rand(1, levelAmount)
				local tmpNewLevelID = startLevelID + levelIndex - 1
				if not table.indexOf(lastUsedLevels, tmpNewLevelID) then
					newLevelID = tmpNewLevelID
				else
					-- printx(11, "xxx level appeared once! xxx", tmpNewLevelID)
				end
			end
		else
			local levelIndex = mainLogic.travelMapRandFactory:rand(1, levelAmount)
			newLevelID = startLevelID + levelIndex - 1
		end

		if #lastUsedLevels < 10 then
			table.insert(lastUsedLevels, newLevelID)
			-- printx(11, "lastUsedLevels", table.tostring(mainLogic.traveledLevelRecord))
		end

		WeeklyRace2020Mgr.getInstance():addPassLevel()

		-- printx(11, "newLevelID:", newLevelID)
		return newLevelID
	end

	return nil
end

function WeeklyRace2020Logic:_onWeeklyRace2020JewelChestDestroyed(mainLogic, targetChest)
	local jewelAmount = 0
	if targetChest and targetChest.weeklyRace2020ChestData then
		jewelAmount = targetChest.weeklyRace2020ChestData.weeklyRace2020ChestJewel
	end

	if jewelAmount and jewelAmount > 0 then
		WeeklyRace2020Logic:addJewelAmount(mainLogic, jewelAmount, targetChest.y, targetChest.x, false)
	end

	-- WeeklyRace2020Logic:playHugeHeartSmash(mainLogic)
end

function WeeklyRace2020Logic:addJewelAmount(mainLogic, addAmount, r, c, withAnimation)
	-- printx(11, "ADD Jewel AMOUNT!", addAmount, debug.traceback())
	if not mainLogic then return end

	mainLogic.digJewelCount:setValue(mainLogic.digJewelCount:getValue() + addAmount)
	if mainLogic.PlayUIDelegate then
		local position = mainLogic:getGameItemPosInView(r, c)
		mainLogic.PlayUIDelegate:setTargetNumber(0, 0, mainLogic.digJewelCount:getValue(), position, 0, withAnimation)
	end
end

function WeeklyRace2020Logic:releaseAllWeeklyRace2020ChestLayerLock(mainLogic)
	if not mainLogic then return end

	local gameItemMap = mainLogic.gameItemMap
	for r = 1, #gameItemMap do
		for c = 1, #gameItemMap[r] do
			local itemData = gameItemMap[r][c]
			if itemData 
				and WeeklyRace2020Logic:isWeeklyRace2020Chest(itemData.ItemType) 
				and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(itemData) 
				then
				WeeklyRace2020Logic:setWeeklyRace2020ChestDecreaseLock(itemData, false)
			end
		end
	end
end

-------------------------------------------- Chest Animations ------------------------------------------
local rewardFlyDuration = 1

-- 也会改变部分数据
function WeeklyRace2020Logic:checkPlayWeeklyRace2020ChestOpenAnimation(chestItem)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end

	local isFinalChestBreak = false
	local isJewelChestBreak = false
	local animAssetName
	local animShiftY = 0

	local isBonusTime = mainLogic.isBonusTime or mainLogic.gameMode.propReleasedBeforeBonus

	if chestItem then
		local chestData = chestItem.weeklyRace2020ChestData
		if chestData then
			if chestData.weeklyRace2020ChestLayerHP == 1 and chestData.weeklyRace2020ChestLayer == 1 then
				if WeeklyRace2020Logic:isWeeklyRace2020JewelChest(chestData.weeklyRace2020ChestType) then
					isJewelChestBreak = true
					animAssetName = "weeklyRace2020_chest_jewel_rewards"
				else
					isFinalChestBreak = true
					animAssetName = "weeklyRace2020_chest_final_rewards"

					if not isBonusTime then
						mainLogic.theCurMoves = mainLogic.theCurMoves + 10
						mainLogic.hasAddMoveStep = {source = "WeeklyRace2020Chest" , steps = 10}
						GameExtandPlayLogic:tryWarp(GameItemType.kWeeklyRace2020Chest , 10)
					else
						-- bouns 时 去掉加步数奖励
						animAssetName = "weeklyRace2020_chest_final_rewards_2"
					end

					animShiftY = -30
				end
			end
		end
	end
	if not animAssetName then return end

	local chestPos = mainLogic:getGameItemPosInView(chestItem.y + 0.5, chestItem.x + 0.5)
	local chestAnim = UIHelper:createArmature3('skeleton/weeklyRace2020_chest', 
	                    animAssetName, animAssetName, animAssetName)
	local animPos = ccp(chestPos.x, chestPos.y + animShiftY)
	chestAnim:setPosition(animPos)
	scene:addChild(chestAnim)

	-- if isBonusTime and isFinalChestBreak then
	-- 	-- bouns 时 去掉加步数奖励
	-- 	local bb2 = chestAnim:getSlot("bb2")
	-- 	local temp = Sprite:createEmpty()
	-- 	bb2:setDisplayImage( temp.refCocosObj )
	-- 	temp.refCocosObj:retain()
	-- 	temp:dispose()

	-- 	local item2 = chestAnim:getSlot("item2")
	-- 	local temp = Sprite:createEmpty()
	-- 	item2:setDisplayImage( temp.refCocosObj )
	-- 	temp.refCocosObj:retain()
	-- 	temp:dispose()

	-- 	local item2 = chestAnim:getSlot("item3")
	-- 	local temp = Sprite:createEmpty()
	-- 	item2:setDisplayImage( temp.refCocosObj )
	-- 	temp.refCocosObj:retain()
	-- 	temp:dispose()

	-- 	local temp = UIHelper:createUI("ui/WeeklyRace2020/json/MoleWeekly.json", 'moleweek_race_end_game/ticketCon')
	-- 	local img = temp:getChildByName("img")
	-- 	img:setPosition(ccp(50,-40))
	-- 	local item3 = chestAnim:getCon("item3")
	-- 	item3:addChild(temp.refCocosObj)
	-- 	temp.refCocosObj:retain()
	-- 	temp:dispose()
	-- end

	if mainLogic.boardView then 
		local boardScale = mainLogic.boardView:getScale()
		if boardScale then
			chestAnim:setScale(boardScale)
		end
	end

	local function onAppearEnded()
		-- printx(11, "==================== onAppearEnded !! ------------------")
		if chestAnim then
			chestAnim:removeEventListener(ArmatureEvents.COMPLETE, onAppearEnded)
		end

		if isJewelChestBreak then
			WeeklyRace2020Logic:playShellFlyToTarget(chestAnim)
		else
			setTimeOut(function ()
				WeeklyRace2020Logic:playFinalChestRewardFlyToTarget(chestAnim)
			end, 1)
		end
    end
    chestAnim:addEventListener(ArmatureEvents.COMPLETE, onAppearEnded)
	chestAnim:play("1", 1)
end

function WeeklyRace2020Logic:playShellFlyToTarget(chestAnim)
	if not chestAnim or chestAnim.isDisposed then return end

    local flyDelay
	for i = 1, 5 do
		flyDelay = 0.1 * (i - 1)
		local targetCon = UIHelper:getCon(chestAnim, "shell_"..i)
		if targetCon then
			WeeklyRace2020Logic:playWeeklyRace2020TargetFlyAnimation(targetCon, flyDelay, -40)
		end
	end

	local function onFlyAnimationEnded()
		-- printx(11, "============= !! onFlyAnimationEnded ~~~~~~~~~~")
        if chestAnim and not chestAnim.isDisposed then
			chestAnim:removeFromParentAndCleanup(true)
		end
    end
    setTimeOut(onFlyAnimationEnded, rewardFlyDuration + flyDelay + 0.1)
end

function WeeklyRace2020Logic:playFinalChestRewardFlyToTarget(chestAnim)
	if not chestAnim or chestAnim.isDisposed then return end

	local mainLogic = GameBoardLogic:getCurrentLogic()

	-- 一期：奖励固定
	local targetIcon = UIHelper:getCon(chestAnim, "item1")
	if targetIcon then
		WeeklyRace2020Logic:playWeeklyRace2020TargetFlyAnimation(targetIcon, 0, -70, 70)
	end

	local isBonusTime = mainLogic.isBonusTime or mainLogic.gameMode.propReleasedBeforeBonus
	if isBonusTime then
		local ticketIcon = UIHelper:getCon(chestAnim, "item2")
		if ticketIcon then
			WeeklyRace2020Logic:playWeeklyRace2020TicketFlyAnimation(ticketIcon, 30, -180)
		end
	else
		local ticketIcon = UIHelper:getCon(chestAnim, "item2")
		if ticketIcon then
			WeeklyRace2020Logic:playWeeklyRace2020TicketFlyAnimation(ticketIcon, 30, -180)
		end
	
		local stepIcon = UIHelper:getCon(chestAnim, "item3")
		if stepIcon then
			WeeklyRace2020Logic:playWeeklyRace2020AddMoveFlyAnimation(stepIcon, 20, 0)
		end
	end

	for i = 1, 3 do
		local bubbleView = UIHelper:getCon(chestAnim, "bb"..i)
		if bubbleView then
			bubbleView:setVisible(false)
		end
	end

	local function onFlyAnimationEnded()
		-- printx(11, "============= !! onFlyAnimationEnded ~~~~~~~~~~")
        if chestAnim and not chestAnim.isDisposed then
			chestAnim:removeFromParentAndCleanup(true)
		end
    end
    setTimeOut(onFlyAnimationEnded, rewardFlyDuration + 0.1)
end

function WeeklyRace2020Logic:playWeeklyRace2020TargetFlyAnimation(targetIcon, flyDelay, xShift, yShift)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.levelTargetPanel then return end

	local targetPanel = mainLogic.PlayUIDelegate.levelTargetPanel
	if targetPanel.getTargetIcon then
		local targetSprite = targetPanel:getTargetIcon()
		if targetSprite and not targetSprite.isDisposed then
			local endPos = targetSprite:getParent():convertToWorldSpace(targetSprite:getPosition())
			WeeklyRace2020Logic:_playItemsFlyAnimation(targetIcon, endPos, flyDelay, 1, xShift, yShift)
		end
	end
end

function WeeklyRace2020Logic:playWeeklyRace2020TicketFlyAnimation(targetIcon, xShift, yShift)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.topArea then return end

	if mainLogic.PlayUIDelegate.topArea.getNPCPos then
		local endPos = mainLogic.PlayUIDelegate.topArea:getNPCPos(xShift, yShift)
		WeeklyRace2020Logic:_playItemsFlyAnimation(targetIcon, endPos, 0, 2)
	end
end

function WeeklyRace2020Logic:playWeeklyRace2020AddMoveFlyAnimation(targetIcon, xShift, yShift)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic or not mainLogic.PlayUIDelegate or not mainLogic.PlayUIDelegate.moveOrTimeCounter then return end

	local function onFlyAnimationEnded()
        if mainLogic and mainLogic.PlayUIDelegate then
			mainLogic.PlayUIDelegate:setMoveOrTimeCountCallback(mainLogic.theCurMoves, false)
		end
    end

    local moveBoard = mainLogic.PlayUIDelegate.moveOrTimeCounter
	local endPos = moveBoard:getParent():convertToWorldSpace(moveBoard:getPosition())
	WeeklyRace2020Logic:_playItemsFlyAnimation(targetIcon, endPos, 0, 3, xShift, yShift, onFlyAnimationEnded)
end

function WeeklyRace2020Logic:_playItemsFlyAnimation(targetIcon, endPos, flyDelay, iconType, xShift, yShift, flyEndCallBack)
	if not targetIcon or targetIcon.isDisposed 
		or not targetIcon:getParent() or targetIcon:getParent().isDisposed or not endPos then 
		return 
	end
	if not flyDelay then flyDelay = 0 end
	if not xShift then xShift = 0 end
	if not yShift then yShift = 0 end

	local endPosByIcon = targetIcon:getParent():convertToNodeSpace(endPos)
	endPosByIcon.x = endPosByIcon.x + xShift
	endPosByIcon.y = endPosByIcon.y + yShift

	-- local flyDuration = 1
	targetIcon:runAction(UIHelper:sequence{
		CCDelayTime:create(flyDelay),
		-- CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(rewardFlyDuration, ccp(endPosByIcon.x, endPosByIcon.y)), CCFadeOut:create(rewardFlyDuration))),
		CCEaseExponentialInOut:create(CCMoveTo:create(rewardFlyDuration, ccp(endPosByIcon.x, endPosByIcon.y))),
		CCCallFunc:create(function ( ... )
			-- printx(11, "&&&&&& One fly ended!! &&&&&&&")
			if targetIcon and not targetIcon.isDisposed then
				-- targetIcon:removeFromParentAndCleanup(true)
				targetIcon:setVisible(false)
				if flyEndCallBack then flyEndCallBack() end
			end
		end),
	})

	-- 加步数有自己的飞抵效果动画
	if iconType == 3 then
		return
	end

	-- 飞到目标处播放一个效果
	local effectIcon
	local function onEffectIconScaleFinished()
		if effectIcon and not effectIcon.isDisposed then
			effectIcon:removeFromParentAndCleanup(true)
		end
	end

	local scene = Director:sharedDirector():getRunningScene()
	if iconType == 1 then
		effectIcon = Sprite:createWithSpriteFrameName("target.moleweek2020 instance 10000")
	elseif iconType == 2 then
		effectIcon = Sprite:createWithSpriteFrameName("blocker_weeklyRace2020_ticket_0000")
	end

	if effectIcon and scene then
		if iconType == 1 then
			effectIcon:setPositionXY(endPos.x, endPos.y)
		elseif iconType == 2 then
			effectIcon:setPositionXY(endPos.x + xShift + 55, endPos.y + yShift - 55)
		end
		scene:addChild(effectIcon)
		effectIcon:setVisible(false)

		effectIcon:runAction(UIHelper:sequence{
			CCDelayTime:create(flyDelay + rewardFlyDuration * 0.8),
			CCCallFunc:create(function ( ... )
				effectIcon:setVisible(true)
				local animeTime = 0.3
				local sequence = CCSpawn:createWithTwoActions(CCScaleTo:create(animeTime, 2), CCFadeOut:create(animeTime))
				effectIcon:setOpacity(255)
				effectIcon:runAction(CCSequence:createWithTwoActions(sequence, CCCallFunc:create(onEffectIconScaleFinished)))
			end),
		})
	end
	
end

---------------------------------- heart smash -------------------------------
function WeeklyRace2020Logic:playHugeHeartSmash(mainLogic)
	local heartGrids = WeeklyRace2020Logic:getHugeHeartGridsToBomb()
	local action = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_WeeklyRace2020_Heart_Smash, 
		nil,
		nil,
		GamePlayConfig_MaxAction_time
		)
	action.middileGrid = {r = 7, c = 5}
	action.targetGrids = heartGrids

	mainLogic:addDestroyAction(action)
	mainLogic:setNeedCheckFalling()
end

function WeeklyRace2020Logic:getHugeHeartGridsToBomb()
	local targetGrids = {}

	-- 一个形状和位置都固定的心形...
	for col1 = 3, 7 do
		if col1 ~= 5 then
			table.insert(targetGrids, IntCoord:create(col1, 4))
		end
	end
	for rowMid = 5, 7 do
		for colMid = 2, 8 do
			table.insert(targetGrids, IntCoord:create(colMid, rowMid))
		end
	end
	for col5 = 3, 7 do
		table.insert(targetGrids, IntCoord:create(col5, 8))
	end
	for col6 = 4, 6 do
		table.insert(targetGrids, IntCoord:create(col6, 9))
	end
	-- table.insert(targetGrids, IntCoord:create(5, 8))

	return targetGrids
end

function WeeklyRace2020Logic:playHeartSmashHugeAnimation(middileGrid)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not middileGrid or not mainLogic then return end
	local middlePos = mainLogic:getGameItemPosInView(middileGrid.r, middileGrid.c)
	-- WeeklyRace2020Logic:playSingleAnimationOnGrid(middlePos, "weeklyRace2020HeartEffect", 1.40, 0, 20)
	WeeklyRace2020Logic:playSingleAnimationOnGrid(middlePos, "heart_effect", 1.40, 0, 20)
end

function WeeklyRace2020Logic:playSingleAnimationOnGrid(middlePos, animationName, scale, xShift, yShift)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene or not middlePos then return end

	local container = Layer:create()
	container:setTouchEnabled(true, 0, true)
	scene:addChild(container)
	
	-- local anim = gAnimatedObject:createWithFilename('gaf/weeklyRace2020/'..animationName..'.gaf')
	local animName = "weeklyRace2020_"..animationName
	local anim = UIHelper:createArmature3('skeleton/'..animName, 
                    animName, animName, animName)
	if scale and scale > 0 then
		anim:setScale(scale)
	end
	if not xShift then xShift = 0 end
	if not yShift then yShift = 0 end
	local animPos = ccp(middlePos.x + xShift, middlePos.y + yShift)
	anim:setPosition(animPos)

	local function finishCallback( ... )
		if container then
			container:removeFromParentAndCleanup(true)
			container = nil
		end
	end

	-- anim:setSequenceDelegate("start", finishCallback, true)
	-- anim:playSequence("start", false, true, ASSH_RESTART)
	-- anim:start()
	anim:addEventListener(ArmatureEvents.COMPLETE, finishCallback)
	anim:play("1", 1)
	anim:update(0.01)

	container:addChild(anim)
end

-------------------------------- special props ----------------------------------
function WeeklyRace2020Logic:playSpecialPropBombAllAnimation(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	-- animation
	local uri = "spine/weeklyRace2020/shuizhadan"
	local animNode = SpineAnimation:createWithFile(uri .. ".json", uri .. ".atlas")
	local scene = Director:sharedDirector():getRunningScene()
	local middlePos = mainLogic:getGameItemPosInView(6, 5)
	animNode:setPosition(middlePos)

	if scene and animNode then
		animNode:addEventListener(SpineAnimationEvents.kSpineEvt, function(event)
			-- printx(11, "==== kSpineEvt event:", table.tostring(event))
			if event and event.data and event.data.eventType then
				if event.data.eventType == SpineEventTypes.SP_ANIMATION_COMPLETE then
					if animNode and not animNode.isDisposed then
						animNode:removeFromParentAndCleanup(true)
					end
				end
			end
		end)

		animNode:runAction(CCSequence:createWithTwoActions(
			CCDelayTime:create(0.01), 
			CCCallFunc:create(function( ... )
				if animNode and not animNode.isDisposed then
					animNode:playByName("baozha", false)
					animNode:setVisible(true)
				end
			end)
		))

		scene:addChild(animNode)
		animNode:setVisible(false)
	end
end

function WeeklyRace2020Logic:onSpecialPropBombAllLogic(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	--全屏爆炸不计大招能量
	if mainLogic and not mainLogic.isDisposed then
		mainLogic.forbidChargeFirework = true
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	local rectangleAction = GameBoardActionDataSet:createAs(
								GameActionTargetType.kGameItemAction,
								GameItemActionType.kItemSpecial_rectangle,
								IntCoord:create(1, 1),
								IntCoord:create(rowAmount, colAmount),
								GamePlayConfig_MaxAction_time)
	rectangleAction.addInt2 = 1
	-- rectangleAction.eliminateChainIncludeHem = true
	mainLogic:addDestructionPlanAction(rectangleAction)
	mainLogic:setNeedCheckFalling()
end

-------------------------- Add Five ----------------------
function WeeklyRace2020Logic:onWeeklyRace2020AddFive(mainLogic)
	if not mainLogic then return end

	-- mainLogic:setGamePlayStatus(GamePlayStatus.kNormal) -- mode里面改了
	mainLogic.fsm:changeState(mainLogic.fsm.fallingMatchState)

	local addStepSkillAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_WeeklyRace2020_Add_Five_Effect,
		nil,
		nil,
		GamePlayConfig_MaxAction_time)

	mainLogic:addDestructionPlanAction(addStepSkillAction)
	mainLogic:setNeedCheckFalling()
end

function WeeklyRace2020Logic:playWeeklyRace2020AddFiveBombAnimation(mainLogic)
	if not mainLogic then return end
	local middlePos = mainLogic:getGameItemPosInView(5, 5)
	-- WeeklyRace2020Logic:playSingleAnimationOnGrid(middlePos, "weeklyRace2020AddFiveEffect") --gaf
	WeeklyRace2020Logic:playSingleAnimationOnGrid(middlePos, "add_five_effect") --skeleton
end

function WeeklyRace2020Logic:weeklyRace2020AddFiveBombBoard(mainLogic)
	if not mainLogic then return end

	local function bombItemMultiTimes(r, c, times, bomb, special)
		for i=1, times do
			if bomb then
				BombItemLogic:tryCoverByBomb(mainLogic, r, c, true, 1, nil, true)
			end
			if special then
				SpecialCoverLogic:SpecialCoverAtPos(mainLogic, r, c, 0, nil, nil, true, true) 
			end
		end
	end

	local function bombJewel(mainLogic, r, c)
		local item = mainLogic.gameItemMap[r][c]
		if item.digJewelLevel > 0 then
			if item.digBlockCanbeDelete then
				GameExtandPlayLogic:decreaseDigJewel(mainLogic, r, c, nil, true, true)
			end
		end
	end

	local gameItemMap = mainLogic.gameItemMap
	for r = 1, #gameItemMap do
		for c = 1, #gameItemMap[r] do
			local item = gameItemMap[r][c]

			if item.ItemType == GameItemType.kDigGround then
				bombItemMultiTimes(r, c, item.digGroundLevel, false, true)
			elseif item.ItemType == GameItemType.kDigJewel then
				-- bombItemMultiTimes(r, c, item.digJewelLevel, false, true)
				for i = 1, item.digJewelLevel do
					bombJewel(mainLogic, r, c)
				end
			elseif WeeklyRace2020Logic:isWeeklyRace2020Chest(item.ItemType) and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(item) then
				local chestData = item.weeklyRace2020ChestData
				if chestData then
					chestData.weeklyRace2020ChestLayer = 1
					chestData.weeklyRace2020ChestLayerHP = 1
					chestData.weeklyRace2020ChestDecreaseLock = false
					WeeklyRace2020Logic:tryDecreaseWeeklyRace2020Chest(mainLogic, item)
				end
			end	
		end
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	local rectangleAction = GameBoardActionDataSet:createAs(
								GameActionTargetType.kGameItemAction,
								GameItemActionType.kItemSpecial_rectangle,
								IntCoord:create(1, 1),
								IntCoord:create(rowAmount, colAmount),
								GamePlayConfig_MaxAction_time)
	rectangleAction.addInt2 = 1
	-- rectangleAction.eliminateChainIncludeHem = true
	mainLogic:addDestructionPlanAction(rectangleAction)
	mainLogic:setNeedCheckFalling()
end

---------------------------------- Game mode ---------------------------------
-- function WeeklyRace2020Logic:isFinalMap(mainLogic)
-- 	-- 取消了终点地图的设定，改为了无限循环
-- 	-- if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
-- 	-- if not mainLogic then return false end

-- 	-- if mainLogic.currTravelMapIndex == 3 then
-- 	-- 	return true
-- 	-- end
-- 	return false
-- end

-- function WeeklyRace2020Logic:weeklyRace2020ReachedEndCondition(mainLogic)
-- 	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
-- 	if not mainLogic then return false end

-- 	-- printx(11, "--------- weeklyRace2020ReachedEndCondition?", mainLogic.currTravelMapIndex, mainLogic.travelReachedEndFlag)
-- 	if mainLogic.travelReachedEndFlag then
-- 		return true
-- 	end
-- 	return false
-- end

----------------------------- pass level --------------------------
function WeeklyRace2020Logic:getWeeklyRace2020PasslevelExtraData()
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local extraData = {}
	extraData["shells"] = 0
	extraData["tickets"] = 0
	extraData["specialTickets"] = 0
	extraData["passedLevelNums"] = 1

	if mainLogic.digJewelCount and mainLogic.digJewelCount:getValue() then
		extraData["shells"] = mainLogic.digJewelCount:getValue()
	end

	local ticketAmount = WeeklyRace2020Logic:getGottenTicketAmount(ItemType.WEEKLY_RACE_2020_COSTUME_TICKET)
	if ticketAmount and ticketAmount > 0 then
		extraData["tickets"] = ticketAmount
	end

	if mainLogic.currTravelMapIndex and mainLogic.currTravelMapIndex > 0 then
		extraData["passedLevelNums"] = mainLogic.currTravelMapIndex
	end

	-- printx(11, "++ Pass Level extra Data:", table.tostring(extraData), debug.traceback())
	return extraData
end

function WeeklyRace2020Logic:dcWeeklyRace2020(mainLogic, sub_category, t3Val, hasT5)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	local t1 = mainLogic.level
	local t2 = mainLogic.currTravelMapIndex
	local t3 = t3Val
    local t4 = GamePlayContext:getInstance():getIdStr()
    local t5
    if hasT5 then
    	t5 = mainLogic.travelMapInitLeftMove
    end

    DcUtil:UserTrack({
		category = "weeklyrace2020",
		sub_category = sub_category,
		t1 = t1,
		t2 = t2,
		t3 = t3,
		t4 = t4,
		t5 = t5,
	})
end

function WeeklyRace2020Logic:onWeeklyRace2020PassLevel(levelId, levelType, isQuitLevel)
	local playId = GamePlayContext:getInstance():getIdStr()
	--printx(15,"GamePlayContext:getInstance():getIdStr()",GamePlayContext:getInstance():getIdStr())

	if WeeklyRace2020Mgr and WeeklyRace2020Mgr.getInstance() then
		WeeklyRace2020Mgr.getInstance():updateData()
	end

	local function shareDisabled()
		if WXJPPackageUtil.getInstance():isWXJPPackage() then
			return true
		end

		local function  isSupportShare( ... )
		    local fuck_platforms = {
		        PlatformNameEnum.k189Store,
		        PlatformNameEnum.kMiTalk,
		    }

		    for _, platform in ipairs(fuck_platforms) do
		        if PlatformConfig:isPlatform(platform) then
		            return false
		        end
		    end
		    return true
		end

		return not isSupportShare()
	end
	
	-- if shareDisabled() then
	-- 	Director:sharedDirector():popScene()
	-- 	Notify:dispatch("BackToWeeklyRace2020MainPanel")
	-- else
	-- 	local panel = require"zoo.weeklyRace2020.view.PassLevelShowOff"
	-- 	panel:create(self.levelId,playId)
	-- end
	local isShareDisabled = shareDisabled()
	local panel = require"zoo.weeklyRace2020.view.PassLevelShowOff"
	panel:create(levelId, playId, isShareDisabled)

	if not isQuitLevel then
		Notify:dispatch("AchiEventPassLevel", levelId, levelType)

		local LadybugABTestManager = require 'zoo.panel.newLadybug.LadybugABTestManager'
		if LadybugABTestManager:isNew() then
			local LadybugDataManager = require 'zoo.panel.newLadybug.LadybugDataManager'
			LadybugDataManager:getInstance():onPlaySeasonWeekly()
		end
		GamePlayEvents.dispatchPassLevelEvent({
			levelType = levelType,
			levelId = levelId,
		})
	else
		printx(15,"0000000")
		GamePlayEvents.dispatchFailLevelEvent({
			levelType = levelType,
			levelId = levelId,
			isQuit = true,
		})
	end

	

	local data = {id = levelId, levelType = levelType}
	GlobalEventDispatcher:getInstance():dispatchEvent(Event.new(kGlobalEvents.kReturnFromGamePlay, data))
end
