require "zoo.localActivity.Valentine2020.Valentine2020Manager"

Valentine2020Logic = class{}
-- local CloverRaceCircleCtrl = require('zoo.localActivity.CloverRace.inGameView.CloverRaceCircleCtrl')

function Valentine2020Logic:isValentine2020Level(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > 0 then
		if LevelType:isValentine2020Level(levelID) then
			return true
		end
	end
	return false
end

-- 是本活动的第几关
function Valentine2020Logic:getLevelIndexInActivity(levelID)
	-- printx(11, "==== Valentine2020Logic:getLevelIndexInActivity", levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID >= LevelConstans.VALENTINE_2020_LEVEL_ID_START then
		local activityLevelID = levelID - (LevelConstans.VALENTINE_2020_LEVEL_ID_START - 1)
		return activityLevelID
	end
	return 1
end

-- 活动关禁用道具栏+5步
function Valentine2020Logic:isForbiddenPropsInLevel(propID)
	if propID == ItemType.ADD_FIVE_STEP or propID == ItemType.TIMELIMIT_ADD_FIVE_STEP 
		or propID == ItemType.ADD_15_STEP 
		then
		return true
	end
	return false
end

---------------------------------- Data ---------------------------------
function Valentine2020Logic:getValentine2020Data(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local valentineData
	-- printx(11, "valentine2020Data", mainLogic.PlayUIDelegate.valentine2020Data)
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.valentine2020Data then
		valentineData = mainLogic.PlayUIDelegate.valentine2020Data 
	end

	return valentineData
end

function Valentine2020Logic:setValentine2020DataForLevel(playUIDelegate, fromReplay, replayDataSet, levelID)
	-- printx(11, "==== Valentine2020Logic:setValentine2020DataForLevel", fromReplay, table.tostring(replayDataSet))
	if not playUIDelegate then return end

	if fromReplay then
		if replayDataSet then
			playUIDelegate.valentine2020Data = replayDataSet
		end
	else
		-- printx(11, "not from replay...")
		self:initDataForValentine2020(playUIDelegate, levelID)
		-- self:setTestDataForValentine2020(playUIDelegate) -- testt
	end

	-- printx(11, "valentine2020Data:", table.tostring(playUIDelegate.valentine2020Data))
end

-- 初始化时调用一次
function Valentine2020Logic:initDataForValentine2020(playUIDelegate, levelID)
	local valentine2020Data = {}
	valentine2020Data["ingredients"] = {}

	if Valentine2020Manager.getInstance() then
		local ingredientIDs = Valentine2020Manager.getInstance():getMaterialIds()
		if ingredientIDs and #ingredientIDs > 0 then
			valentine2020Data["ingredients"] = ingredientIDs
		end

		-- local cacheData = Valentine2020Manager.getInstance():getInLevelCatchData(levelID)
		-- if cacheData then
		-- 	valentine2020Data["cacheData"] = table.clone(cacheData)
		-- end
	end

	-- printx(11, "valentine2020Data inited", table.tostring(valentine2020Data))
	playUIDelegate.valentine2020Data = valentine2020Data
end

MACRO_DEV_START()
function Valentine2020Logic:setTestDataForValentine2020(playUIDelegate)
	if not playUIDelegate then return end

	local valentine2020Data = {}

	local ingredientList = {}
	table.insert(ingredientList, 1)
	table.insert(ingredientList, 3)
	-- table.insert(ingredientList, 5)
	table.insert(ingredientList, 8)

	valentine2020Data["ingredients"] = ingredientList

	-- printx(11, "dummy valentine2020Data", table.tostring(valentine2020Data))
	playUIDelegate.valentine2020Data = valentine2020Data
end
MACRO_DEV_END()

function Valentine2020Logic:_getOrigIngredientList(mainLogic)
	local activityData = Valentine2020Logic:getValentine2020Data(mainLogic)
	if activityData and activityData.ingredients and #activityData.ingredients > 0 then
		return activityData.ingredients
	end
	return nil
end

-- 初始化、分配收集物
function Valentine2020Logic:initScanAndUpdateValentineSnow(mainLogic)
	local ingredientList = Valentine2020Logic:_getOrigIngredientList(mainLogic)
	if not ingredientList or not mainLogic then return end

	local snowBlockers = {}
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local item = mainLogic.gameItemMap[r][c]
			if item and item.ItemType == GameItemType.kSnow then
				table.insert(snowBlockers, item)
			end
		end
	end

	local ingredientAmount = #ingredientList
	local snowBlockerAmount = #snowBlockers
	-- 理论上，如果雪块数量小于掉落物数量，则是关卡配只出了问题。故不特别处理这种情况
	local pickAmount = math.min(ingredientAmount, snowBlockerAmount)
	if pickAmount <= 0 then return end

	for i = 1, pickAmount do
		local ingredientID = ingredientList[i]
		local snowBlockerIndex = mainLogic.randFactory:rand(1, #snowBlockers)

		local targetSnow = snowBlockers[snowBlockerIndex]
		targetSnow.valentineIngredientID = ingredientID
		targetSnow.isNeedUpdate = true

		table.remove(snowBlockers, snowBlockerIndex)
		-- printx(11, "set ingredient to snow:", ingredientID, targetSnow.x, targetSnow.y, #snowBlockers)
	end
end

function Valentine2020Logic:isRareIngredient(ingredientID)
	if Valentine2020Manager.getInstance() then
		if Valentine2020Manager.getInstance():isLegendPiece(ingredientID) 
			or Valentine2020Manager.getInstance():isRarePiece(ingredientID) 
			then
			return true
		end
	end
	return false
end

-- index 1:common 2:rare
function Valentine2020Logic:getIngredientCollectedAmountByIndex(index)
	local collectNum = 0
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		local collectNums = mainLogic.collectTargetNums
		if collectNums and collectNums[index] and collectNums[index] > 0 then
			collectNum = collectNums[index]
		end
	end
	return collectNum
end

-- 本有 + 加5步获得
function Valentine2020Logic:getMergedAllIngredients(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return nil end

	local origIngredientList = Valentine2020Logic:_getOrigIngredientList(mainLogic)
	local mergedList = Valentine2020Logic:getMergedIngredientsFromList(origIngredientList)

	local extraIngredientList = mainLogic.extraGainedActCollections
	if extraIngredientList then
		for extraIngredientID, amount in pairs(extraIngredientList) do
			if amount > 0 then
				if not mergedList[extraIngredientID] then mergedList[extraIngredientID] = 0 end
				mergedList[extraIngredientID] = mergedList[extraIngredientID] + amount
			end
		end
	end

	return mergedList
end

function Valentine2020Logic:getMergedIngredientsFromList(ingredientList)
	local mergedList = {}

	if ingredientList and #ingredientList > 0 then
		for _, ingrediendID in pairs(ingredientList) do
			if not mergedList[ingrediendID] then mergedList[ingrediendID] = 0 end
			mergedList[ingrediendID] = mergedList[ingrediendID] + 1
		end
	end

	return mergedList
end

-- 转换成manager需要的格式……
function Valentine2020Logic:getMergedAllIngredientsManagerType()
	local managerIngredientList = {}

	local mergedIngredients = Valentine2020Logic:getMergedAllIngredients()
	if mergedIngredients then
		for extraIngredientID, amount in pairs(mergedIngredients) do
			local ingredientPack = {}
			ingredientPack["pieceId"] = extraIngredientID
			ingredientPack["num"] = amount
			table.insert(managerIngredientList, ingredientPack)
		end
	end

	return managerIngredientList
end

function Valentine2020Logic:addStepCanMakeNewCake()
	if not Valentine2020Manager.getInstance() then return false end

	local currIngredientList = Valentine2020Logic:getMergedAllIngredientsManagerType()
	-- printx(11, "check can make cake: currIngredientList:", table.tostring(currIngredientList))

	local canMakeList
	if Valentine2020Manager.getInstance() then
		canMakeList = Valentine2020Manager.getInstance():getCanMakeNewCake(currIngredientList)
	end
	if canMakeList and #canMakeList > 0 then
		return true
	end
	return false
end

-------------------------- Add Five ----------------------
function Valentine2020Logic:addIngredientsAfterAddFive(mainLogic)
	if not mainLogic then return end

	local addFiveIngredients = Valentine2020Logic:_getAddFiveIngredients(mainLogic)
	Valentine2020Logic:dcValentine2020AddFiveIngredients(addFiveIngredients)
	for i = 1, #addFiveIngredients do
		local ingredientID = addFiveIngredients[i]
		mainLogic:addExtraGainedActCollection(ingredientID, 1)

		local currCol = CalculationUtil:mathBetween(3 + (i - 1) * 2, 1, 9) --只会有三个
		local midPos = mainLogic:getGameItemPosInView(4, currCol)

		Valentine2020Logic:playDropIngredientAnimation(ingredientID, midPos)
	end
end

function Valentine2020Logic:_getAddFiveIngredients(mainLogic)
	local ingredients = {}

	local wghtList = {15,15,15, 12,12,11, 5,5,5, 2,2,1}
	local sumWght = 0
	for _, wVal in pairs(wghtList) do
		sumWght = sumWght + wVal
	end

	local function getOneIngredient()
		local randVal = mainLogic.randFactory:rand(1, sumWght)

		local accuWght = 0
		for id = 1, #wghtList do
			local wghtVal = wghtList[id]
			accuWght = accuWght + wghtVal

			if randVal <= accuWght then
				return id
			end
		end
		return 1
	end

	for i = 1, 3 do
		local ingredientID = getOneIngredient()
		table.insert(ingredients, ingredientID)
	end

	-- printx(11, "res", table.tostring(ingredients))
	return ingredients
end

----------------------------- pass level --------------------------
function Valentine2020Logic:getValentine2020PasslevelExtraData(star)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local extraData = {}
	extraData["materialIds"] = {}
	extraData["extraMaterialMap"] = {}

	-- 这边不需要区分过关于否
	local data = Valentine2020Logic:getValentine2020Data(mainLogic)
	if data and data.ingredients then
		extraData["materialIds"] = table.clone(data.ingredients)
	end

	local extraIngredientList = mainLogic.extraGainedActCollections
	if extraIngredientList then
		local extraIngredientData = {}
		for extraIngredientID, amount in pairs(extraIngredientList) do
			local ingredientIDStr = tostring(extraIngredientID)
			if amount > 0 then
				extraIngredientData[ingredientIDStr] = amount
			end
		end
		extraData["extraMaterialMap"] = extraIngredientData
	end

	if data and data.ingredients and star > 0 then
		local managerIngredientList = {}
		for i, v in pairs(data.ingredients) do
			local ingredientPack = {}
			ingredientPack["pieceId"] = v
			ingredientPack["num"] = 1
			table.insert(managerIngredientList, ingredientPack)
		end
        Valentine2020Manager.getInstance():addPiece(managerIngredientList) --加收集物
	end

	local extraIngredientList = mainLogic.extraGainedActCollections
	if extraIngredientList and star > 0 then
		local managerIngredientList = {}
		for extraIngredientID, amount in pairs(extraIngredientList) do
			if amount > 0 then
				local ingredientPack = {}
				ingredientPack["pieceId"] = extraIngredientID
				ingredientPack["num"] = amount
				table.insert(managerIngredientList, ingredientPack)
			end
		end
		Valentine2020Manager.getInstance():addPiece(managerIngredientList) --加收集物
	end

	if Valentine2020Manager.getInstance() then
		local nextNearlyMadeCakeID = Valentine2020Manager.getInstance():getNearlyCanMakeCakeId()
		if nextNearlyMadeCakeID then
			extraData["priorChocolateId"] = nextNearlyMadeCakeID
		end
	end

	-- printx(11, "++ Pass Level extra Data:", table.tostring(extraData))
	return extraData
end

function Valentine2020Logic:getValentine2020NoitfyData(levelType, levelID, isWin)
	local notifyData = {}
	notifyData["levelType"] = levelType
	notifyData["levelID"] = levelID

	local mainLogic = GameBoardLogic:getCurrentLogic()
	-- if mainLogic then
	-- 	notifyData["stageStartTime"] = mainLogic.stageStartTime
	-- end

	-- local valentineData = Valentine2020Logic:getValentine2020Data(mainLogic)
	-- if valentineData.cacheData then
	-- 	notifyData["catchData"] = valentineData.cacheData
	-- end

	if isWin then
		notifyData["ingredients"] = Valentine2020Logic:getMergedAllIngredientsManagerType(mainLogic)
	end

	-- printx(11, "++ PassLevel NotifyData Data:", table.tostring(notifyData))
	return notifyData
end

---------------------------------------- DC -------------------------------------------
function Valentine2020Logic:_getIngredientRecordStrForDC(ingredientMap)
	local ingredientRecord = ""
	local hasIngredient = false
	if ingredientMap then
		for ingredientID, amount in pairs(ingredientMap) do
			if amount > 0 then
				hasIngredient = true
				if ingredientRecord ~= "" then
					ingredientRecord = ingredientRecord..","
				end
				ingredientRecord = ingredientRecord..ingredientID.."_"..amount
			end
		end
	end
	return hasIngredient, ingredientRecord
end

function Valentine2020Logic:dcValentine2020PassLevel(levelID, isWin, isQuit)
	local t1 = levelID
	local t2 = 1
	if not isWin then
		if isQuit then
			t2 = 3
		else
			t2 = 2
		end
	end

	local t3
	local origIngredientList = Valentine2020Logic:_getOrigIngredientList(mainLogic)
	local origIngredientMap = Valentine2020Logic:getMergedIngredientsFromList(origIngredientList)
	local hasOrigIngredient, origIngredientRecord = Valentine2020Logic:_getIngredientRecordStrForDC(origIngredientMap)
	if hasOrigIngredient then
		t3 = origIngredientRecord
	end

	local t4
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		local extraIngredientMap = mainLogic.extraGainedActCollections
		local hasExtraIngredient, extraIngredientRecord = Valentine2020Logic:_getIngredientRecordStrForDC(extraIngredientMap)
		if hasExtraIngredient then
			t4 = extraIngredientRecord
		end
	end

	local params = {
		game_type = "stage",
		game_name = "20Valentine",
		category = "canyu",
		sub_category = "end_level",
		t1 = t1,
		t2 = t2,
		t3 = t3,
		t4 = t4,
	}
	DcUtil:activity(params)
end

function Valentine2020Logic:dcValentine2020AddFiveIngredients(ingredientList)
	local ingredientMap = Valentine2020Logic:getMergedIngredientsFromList(ingredientList)
	local hasIngredient, ingredientRecord = Valentine2020Logic:_getIngredientRecordStrForDC(ingredientMap)
	if hasIngredient then
		local params = {
			game_type = "stage",
			game_name = "20Valentine",
			category = "canyu",
			sub_category = "add_5steps_material",
			t1 = ingredientRecord,
		}
		DcUtil:activity(params)
	end
end

function Valentine2020Logic:dcValentine2020AddFivePanel(tapAddFive, tipState)
	local t1 = 2
	local rareIngredientAmount = Valentine2020Logic:getIngredientCollectedAmountByIndex(2)
	if rareIngredientAmount > 0 then
		t1 = 1
	end

	local t2 = 2
	if Valentine2020Logic:addStepCanMakeNewCake() then
		t2 = 1
	end

	local t3 = 2
	if tapAddFive then
		t3 = 1
	end

	local t4
	if tipState and tipState == 3 then
		t4 = 1
	end

	local params = {
		game_type = "stage",
		game_name = "20Valentine",
		category = "canyu",
		sub_category = "add_5steps_check",
		t1 = t1,
		t2 = t2,
		t3 = t3,
		t4 = t4,
	}
	DcUtil:activity(params)
end

function Valentine2020Logic:dcValentine2020SuccessPanel(canMakeCake, tapType)
	local t1 = 2
	if canMakeCake then
		t1 = 1
	end
	local t2 = tapType

	local params = {
		game_type = "stage",
		game_name = "20Valentine",
		category = "canyu",
		sub_category = "pass_level_make",
		t1 = t1,
		t2 = t2,
	}
	DcUtil:activity(params)
end

function Valentine2020Logic:dcValentine2020FailPanel(tapRetry)
	local t1 = 2
	if tapRetry then
		t1 = 1
	end
	local params = {
		game_type = "stage",
		game_name = "20Valentine",
		category = "canyu",
		sub_category = "fail_panel",
		t1 = t1,
	}
	DcUtil:activity(params)
end

---------------------------------------------------- Some Animations -------------------------------------------------------
----------------------------------- drop ingredient
function Valentine2020Logic:playSnowDropIngredientAnimation(ingredientID, dropGridRow, dropGridCol)
	-- printx(11, "Valentine2020Logic:playSnowDropIngredientAnimation", ingredientID, dropGridRow, dropGridCol)
	if not ingredientID or not (ingredientID > 0) 
		or not dropGridRow or not (dropGridRow > 0)
		or not dropGridCol or not (dropGridCol > 0) 
		then 
		return 
	end

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	local midPos = mainLogic:getGameItemPosInView(dropGridRow, dropGridCol)
	Valentine2020Logic:playDropIngredientAnimation(ingredientID, midPos)
end

function Valentine2020Logic:playDropIngredientAnimation(ingredientID, middlePos)
	-- printx(11, "Valentine2020Logic:playDropIngredientAnimation", ingredientID, middlePos.x, middlePos.y)
	if not ingredientID or not middlePos then return end

	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end

	local rewardAssetName = "valentine2020_snow_dropped_ingredient"
	local rewardDropAnim = UIHelper:createArmature3("tempFunctionResInLevel/Valentine2020/skeleton/valentine2020DropIngredient", 
		"valentine2020DropIngredient", "valentine2020DropIngredient", rewardAssetName)
	if not rewardDropAnim then return end

	local container = Layer:create()
	container:setTouchEnabled(true, 0, true)
	scene:addChild(container)

	local animPos = ccp(middlePos.x - 35, middlePos.y + 30)
	rewardDropAnim:setPosition(animPos)

	local iconSprite = Sprite:createEmpty()

	local iconPos = ccp(30, 35)
	local icon = UIHelper:createSpriteWithPlist("tempFunctionResInLevel/Valentine2020/itesm/Valentine2020_pieces.plist", "Valentine2020_pieces/piece"..ingredientID..".png")
	icon:setAnchorPoint(ccp(0.5,0.5))
	icon:setScale(0.8)
	icon:setPosition(ccp(30, 35))
	iconSprite:addChild(icon)
	-- iconSprite.accessoryIcon = icon

	local itemPlate = UIHelper:getCon(rewardDropAnim, "item")
	if itemPlate and iconSprite.refCocosObj then
		itemPlate:addChild(iconSprite.refCocosObj)
		-- iconSprite:dispose()
	end

	local function onRewardDisappearFinished()
		if rewardDropAnim then
			rewardDropAnim:removeEventListener(ArmatureEvents.COMPLETE, onRewardDisappearFinished)
			if not rewardDropAnim.isDisposed then
				rewardDropAnim:removeFromParentAndCleanup(true)
			end
		end

		if container and not container.isDisposed then
			container:removeFromParentAndCleanup(true)
			container = nil
		end
	end

	local function onRewardAppearAnimFinished()
		if rewardDropAnim then
			rewardDropAnim:removeEventListener(ArmatureEvents.COMPLETE, onRewardAppearAnimFinished)

			Valentine2020Logic:playIngredientFlyAnimation(ingredientID, icon, scene)
			if iconSprite and not iconSprite.isDisposed then
				iconSprite:dispose()
			end

			if not rewardDropAnim.isDisposed then
				rewardDropAnim:addEventListener(ArmatureEvents.COMPLETE, onRewardDisappearFinished)
				rewardDropAnim:playByIndex(1, 1)
			end
		end
	end

	rewardDropAnim:addEventListener(ArmatureEvents.COMPLETE, onRewardAppearAnimFinished)
	rewardDropAnim:playByIndex(0, 1)
	container:addChild(rewardDropAnim)
end

function Valentine2020Logic:playIngredientFlyAnimation(ingredientID, targetIcon, scene)
	-- printx(11, "Valentine2020Logic:playIngredientFlyAnimation", ingredientID, targetIcon, targetIcon.isDisposed, scene)
	if not targetIcon or targetIcon.isDisposed or not scene then return end

	local targetIconPos = targetIcon:getPosition()
	local iconPos = ccp(0, 0)
	if targetIcon.parent and targetIconPos then
		iconPos = targetIcon.parent:convertToWorldSpace(ccp(targetIconPos.x, targetIconPos.y))
	end
	targetIcon:removeFromParentAndCleanup(false)
	scene:addChild(targetIcon)
	targetIcon:setPosition(ccp(iconPos.x, iconPos.y))

	local targetIconIndex = 1
	local isRareIngredient = Valentine2020Logic:isRareIngredient(ingredientID)
	if isRareIngredient then 
		targetIconIndex = 2
	end

	local effectIcon
	local function onEffectIconScaleFinished()
		if effectIcon and not effectIcon.isDisposed then
			effectIcon:removeFromParentAndCleanup(true)
		end
		self.animNode = nil
	end

	local flyDuration = 0.4
	local endIconScale = 0.4
	-- local accessoryEndPos = ActCollectionLogic:getTargetPosByIndex(6, targetIconIndex) --6:Common_collectProgress.panelTypes.kValnetine2020
	targetIcon:runAction(UIHelper:sequence{
		CCDelayTime:create(0.5),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(accessoryEndPos.x, accessoryEndPos.y)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if targetIcon and not targetIcon.isDisposed then
				targetIcon:removeFromParentAndCleanup(true)
			end
			-- ActCollectionLogic:addTargetNumberByIndex(6, targetIconIndex, 1, true) --6:Common_collectProgress.panelTypes.kValnetine2020

			local effectAssetName = "valentine2020/heartIcon/shinyHeartIcon0000"
			effectIcon = UIHelper:createSpriteFrame('tempFunctionResInLevel/Valentine2020/Valentine2020InGame.json', effectAssetName)
			if effectIcon then
				effectIcon:setPositionXY(accessoryEndPos.x, accessoryEndPos.y)
				scene:addChild(effectIcon)

				local animeTime = 0.3
				local sequence = CCSpawn:createWithTwoActions(CCScaleTo:create(animeTime, 2), CCFadeOut:create(animeTime))
				effectIcon:setOpacity(255)
				effectIcon:runAction(CCSequence:createWithTwoActions(sequence, CCCallFunc:create(onEffectIconScaleFinished)))
			end
		end),
	})
end

