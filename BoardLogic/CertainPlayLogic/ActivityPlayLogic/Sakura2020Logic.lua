Sakura2020Logic = class{}
-- local CloverRaceCircleCtrl = require('zoo.localActivity.CloverRace.inGameView.CloverRaceCircleCtrl')
local levelConfigForIngredients = {15,25,30,30,35,35,40,45,45,50,50,50,55,55,60}

function Sakura2020Logic:isSakura2020Level(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > 0 then
		if LevelType:isSakura2020Level(levelID) then
			return true
		end
	end
	return false
end

-- 是本活动的第几关
function Sakura2020Logic:getLevelIndexInActivity(levelID)
	-- printx(11, "==== Sakura2020Logic:getLevelIndexInActivity", levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID >= LevelConstans.SAKURA_2020_LEVEL_ID_START then
		local activityLevelID = levelID - (LevelConstans.SAKURA_2020_LEVEL_ID_START - 1)
		return activityLevelID
	end
	return 1
end

-- 活动关禁用道具栏+5步
function Sakura2020Logic:isForbiddenPropsInLevel(propID)
	if propID == ItemType.ADD_FIVE_STEP or propID == ItemType.TIMELIMIT_ADD_FIVE_STEP 
		or propID == ItemType.ADD_15_STEP 
		then
		return true
	end
	return false
end

---------------------------------- Data ---------------------------------
function Sakura2020Logic:getSakura2020Data(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local sakuraData
	-- printx(15, "Sakura2020Data", mainLogic.PlayUIDelegate.Sakura2020Data)
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.sakura2020Data then
		sakuraData = mainLogic.PlayUIDelegate.sakura2020Data 
	end

	return sakuraData
end

function Sakura2020Logic:setSakura2020DataForLevel(playUIDelegate, fromReplay, replayDataSet, levelID)
	-- printx(15, "==== Sakura2020Logic:setSakura2020DataForLevel", fromReplay, table.tostring(replayDataSet))
	if not playUIDelegate then return end

	if fromReplay then
		if replayDataSet then
			playUIDelegate.sakura2020Data = replayDataSet
		end
	else
		-- printx(11, "not from replay...")
		self:initDataForSakura2020(playUIDelegate, levelID)
		-- self:setTestDataForSakura2020(playUIDelegate) -- testt
	end

	-- printx(11, "Sakura2020Data:", table.tostring(playUIDelegate.Sakura2020Data))
end

-- 初始化时调用一次
function Sakura2020Logic:initDataForSakura2020(playUIDelegate, levelID)
	if levelID < LevelConstans.SAKURA_2020_LEVEL_ID_START then
		return
	end
	local sakura2020Data = {}
	sakura2020Data["ingredients"] = levelConfigForIngredients[levelID - LevelConstans.SAKURA_2020_LEVEL_ID_START + 1]
	-- printx(15,"====",Sakura2020Data["ingredients"])
	playUIDelegate.sakura2020Data = sakura2020Data
end

function Sakura2020Logic:_getOrigIngredientList(mainLogic)
	local activityData = Sakura2020Logic:getSakura2020Data(mainLogic)
	if activityData and activityData.ingredients and activityData.ingredients > 0 then
		return activityData.ingredients
	end
	return nil
end

-- 初始化、分配收集物
function Sakura2020Logic:initScanAndUpdateSakuraSnow(mainLogic)
	local ingredientList = Sakura2020Logic:_getOrigIngredientList(mainLogic)
	-- printx(15,"initScanAndUpdateSakuraSnow",ingredientList,mainLogic)
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

	local ingredientAmount = ingredientList
	local snowBlockerAmount = #snowBlockers
	-- 理论上，如果雪块数量小于掉落物数量，则是关卡配只出了问题。故不特别处理这种情况
	local bigBoxNum = 0
	if ingredientAmount == snowBlockerAmount then
		bigBoxNum = 0
	else
		bigBoxNum = math.ceil((ingredientAmount-snowBlockerAmount)/9) -- 小礼盒变大礼盒最多增加9个
	end
	-- printx(15,"ingredientAmount,snowBlockerAmount,bigBoxNum",ingredientAmount,snowBlockerAmount,bigBoxNum)
	local leftIngredient = ingredientAmount-snowBlockerAmount+bigBoxNum
	local averageNum = math.min(10,math.ceil((ingredientAmount-snowBlockerAmount+bigBoxNum)/bigBoxNum))
	for i = 1, bigBoxNum do
		local ingredientID = averageNum
		if i == bigBoxNum then
			ingredientID = leftIngredient
		else
			leftIngredient = leftIngredient - ingredientID
		end
		local snowBlockerIndex = mainLogic.randFactory:rand(1, #snowBlockers)

		local targetSnow = snowBlockers[snowBlockerIndex]
		targetSnow.SakuraIngredientID = ingredientID
		targetSnow.isNeedUpdate = true

		table.remove(snowBlockers, snowBlockerIndex)
		-- printx(15, "set ingredient to snow:", ingredientID, targetSnow.x, targetSnow.y, #snowBlockers)
	end
	-- printx(15,"#snowBlockers",#snowBlockers)
	for i = 1 , #snowBlockers do
		local targetSnow = snowBlockers[i]
		targetSnow.SakuraIngredientID = 1
		targetSnow.isNeedUpdate = true
	end
end


-- index 1:common 2:rare
-- function Sakura2020Logic:getIngredientCollectedAmountByIndex(index)
-- 	local collectNum = 0
-- 	local mainLogic = GameBoardLogic:getCurrentLogic()
-- 	if mainLogic then
-- 		local collectNums = mainLogic.collectTargetNums
-- 		if collectNums and collectNums[index] and collectNums[index] > 0 then
-- 			collectNum = collectNums[index]
-- 		end
-- 	end
-- 	return collectNum
-- end

-- -- 本有 + 加5步获得
-- function Sakura2020Logic:getMergedAllIngredients(mainLogic)
-- 	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
-- 	if not mainLogic then return nil end

-- 	local origIngredientList = Sakura2020Logic:_getOrigIngredientList(mainLogic)
-- 	local mergedList = Sakura2020Logic:getMergedIngredientsFromList(origIngredientList)

-- 	local extraIngredientList = mainLogic.extraGainedActCollections
-- 	if extraIngredientList then
-- 		for extraIngredientID, amount in pairs(extraIngredientList) do
-- 			if amount > 0 then
-- 				if not mergedList[extraIngredientID] then mergedList[extraIngredientID] = 0 end
-- 				mergedList[extraIngredientID] = mergedList[extraIngredientID] + amount
-- 			end
-- 		end
-- 	end

-- 	return mergedList
-- end

-- function Sakura2020Logic:getMergedIngredientsFromList(ingredientList)
-- 	local mergedList = {}

-- 	if ingredientList and #ingredientList > 0 then
-- 		for _, ingrediendID in pairs(ingredientList) do
-- 			if not mergedList[ingrediendID] then mergedList[ingrediendID] = 0 end
-- 			mergedList[ingrediendID] = mergedList[ingrediendID] + 1
-- 		end
-- 	end

-- 	return mergedList
-- end

-- -- 转换成manager需要的格式……
-- function Sakura2020Logic:getMergedAllIngredientsManagerType()
-- 	local managerIngredientList = {}

-- 	local mergedIngredients = Sakura2020Logic:getMergedAllIngredients()
-- 	if mergedIngredients then
-- 		for extraIngredientID, amount in pairs(mergedIngredients) do
-- 			local ingredientPack = {}
-- 			ingredientPack["pieceId"] = extraIngredientID
-- 			ingredientPack["num"] = amount
-- 			table.insert(managerIngredientList, ingredientPack)
-- 		end
-- 	end

-- 	return managerIngredientList
-- end

-- function Sakura2020Logic:addStepCanMakeNewCake()
-- 	if true then
-- 		return true
-- 	end
-- 	-- if not Sakura2020Manager.getInstance() then return false end

-- 	-- local currIngredientList = Sakura2020Logic:getMergedAllIngredientsManagerType()
-- 	-- -- printx(11, "check can make cake: currIngredientList:", table.tostring(currIngredientList))

-- 	-- local canMakeList
-- 	-- if Sakura2020Manager.getInstance() then
-- 	-- 	canMakeList = Sakura2020Manager.getInstance():getCanMakeNewCake(currIngredientList)
-- 	-- end
-- 	-- if canMakeList and #canMakeList > 0 then
-- 	-- 	return true
-- 	-- end
-- 	-- return false
-- end

-------------------------- Add Five ----------------------
function Sakura2020Logic:addIngredientsAfterAddFive(mainLogic)
	if not mainLogic then return end
end

function Sakura2020Logic:_getAddFiveIngredients(mainLogic)
end

----------------------------- pass level --------------------------
function Sakura2020Logic:getSakura2020PasslevelExtraData(star)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return nil end

	local extraData = {}
	extraData["materialIds"] = {}
	extraData["extraMaterialMap"] = {}

	-- 这边不需要区分过关于否
	local data = Sakura2020Logic:getSakura2020Data(mainLogic)
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
        -- Sakura2020Manager.getInstance():addPiece(managerIngredientList) --加收集物
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
		-- Sakura2020Manager.getInstance():addPiece(managerIngredientList) --加收集物
	end

	-- printx(11, "++ Pass Level extra Data:", table.tostring(extraData))
	return extraData
end

function Sakura2020Logic:getSakura2020NoitfyData(levelType, levelID, isWin,isGiveUp)
	local notifyData = {}
	notifyData["levelType"] = levelType
	notifyData["levelID"] = levelID

	local mainLogic = GameBoardLogic:getCurrentLogic()


	if isWin then
		notifyData["addSakuraNum"] = Sakura2020Logic:getCollectSakura(mainLogic)
	end

	if isGiveUp then
		notifyData["isGiveUp"] = true
	end

	-- printx(11, "++ PassLevel NotifyData Data:", table.tostring(notifyData))
	return notifyData
end

function Sakura2020Logic:getCollectSakura(mainLogic)
	local collectNum = 0
	collectNum = Sakura2020Manager.getInstance():getCurrentLevelCollection()
	return collectNum
end

---------------------------------------- DC -------------------------------------------
function Sakura2020Logic:_getIngredientRecordStrForDC(ingredientMap)
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

function Sakura2020Logic:dcSakura2020PassLevel(levelID, isWin, isQuit)
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
	local origIngredientList = Sakura2020Logic:_getOrigIngredientList(mainLogic)
	local origIngredientMap = Sakura2020Logic:getMergedIngredientsFromList(origIngredientList)
	local hasOrigIngredient, origIngredientRecord = Sakura2020Logic:_getIngredientRecordStrForDC(origIngredientMap)
	if hasOrigIngredient then
		t3 = origIngredientRecord
	end

	local t4
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		local extraIngredientMap = mainLogic.extraGainedActCollections
		local hasExtraIngredient, extraIngredientRecord = Sakura2020Logic:_getIngredientRecordStrForDC(extraIngredientMap)
		if hasExtraIngredient then
			t4 = extraIngredientRecord
		end
	end

	local params = {
		game_type = "stage",
		game_name = "20Sakura",
		category = "canyu",
		sub_category = "end_level",
		t1 = t1,
		t2 = t2,
		t3 = t3,
		t4 = t4,
	}
	DcUtil:activity(params)
end

function Sakura2020Logic:dcSakura2020AddFiveIngredients(ingredientList)
	local ingredientMap = Sakura2020Logic:getMergedIngredientsFromList(ingredientList)
	local hasIngredient, ingredientRecord = Sakura2020Logic:_getIngredientRecordStrForDC(ingredientMap)
	if hasIngredient then
		local params = {
			game_type = "stage",
			game_name = "20Sakura",
			category = "canyu",
			sub_category = "add_5steps_material",
			t1 = ingredientRecord,
		}
		DcUtil:activity(params)
	end
end

function Sakura2020Logic:dcSakura2020AddFivePanel(tapAddFive, tipState)
	local t1 = 2
	if tapAddFive then
		t1 = 1
	end
	local t2 = tipState
	if t2 > 2 then 
		t2 = 2
	end

	local params = {
		game_type = "stage",
		game_name = "20Sakura",
		category = "canyu",
		sub_category = "add_5steps_check",
		t1 = t1,
		t2 = t2,
	}
	DcUtil:activity(params)
end

function Sakura2020Logic:dcSakura2020SuccessPanel(canMakeCake, tapType)
	local t1 = 2
	if canMakeCake then
		t1 = 1
	end
	local t2 = tapType

	local params = {
		game_type = "stage",
		game_name = "20Sakura",
		category = "canyu",
		sub_category = "pass_level_make",
		t1 = t1,
		t2 = t2,
	}
	DcUtil:activity(params)
end

function Sakura2020Logic:dcSakura2020FailPanel(tapRetry)
	local t1 = 2
	if tapRetry then
		t1 = 1
	end
	local params = {
		game_type = "stage",
		game_name = "20Sakura",
		category = "canyu",
		sub_category = "fail_panel",
		t1 = t1,
	}
	DcUtil:activity(params)
end


---------------------------------------------------- Some Animations -------------------------------------------------------
----------------------------------- drop ingredient
function Sakura2020Logic:playAddFiveAnim( ... )
	printx(15,"playAddFiveAnim")
	Sakura2020Manager.getInstance():addcollectSakuraNum(15)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	local visibleOrigin = Director:sharedDirector():getVisibleOrigin()
    local visibleSize =  Director:sharedDirector():getVisibleSize()

    local animAssetName = "add5Anim"
	local anim = UIHelper:createArmature3("tempFunctionResInLevel/Cherry/skeleton/sakura2020AddFiveAnim", 
		"sakura2020AddFiveAnim", "sakura2020AddFiveAnim", animAssetName)
	anim:setPositionX(visibleOrigin.x + visibleSize.width/2)
	anim:setPositionY(visibleOrigin.y + visibleSize.height/2)
	scene:addChild(anim)
	anim:playByIndex(0, 1)
	-- local accessoryEndPos = ActCollectionLogic:getTargetPosByIndex(7, 1)

	local flyDuration = 8/30
	local flyDelayTime = {35,36,36,36,37,37,39,40}
	for i = 1 , 8 do
		local f = UIHelper:getCon(anim,"f"..i)
		local targetIconPos = f:getParent():convertToNodeSpace(ccp(accessoryEndPos.x-10, accessoryEndPos.y+20))
		f:runAction(UIHelper:sequence{
		CCDelayTime:create((flyDelayTime[i])/30),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(targetIconPos.x,targetIconPos.y)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if f and not f.isDisposed then
				f:removeFromParentAndCleanup(true)
			end
			if i == 1 then
				-- ActCollectionLogic:addTargetNumberByIndex(7, 1, 15, true) --7:Common_collectProgress.panelTypes.kSakura2020
			end
			local effectAssetName = "Sakura2020/heartIcon/shinyHeartIcon0000"
			effectIcon = UIHelper:createSpriteFrame('tempFunctionResInLevel/Cherry/Sakura2020InGame.json', effectAssetName)
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
	
end

function Sakura2020Logic:playSnowDropIngredientAnimation(ingredientID, dropGridRow, dropGridCol)
	-- printx(15, "Sakura2020Logic:playSnowDropIngredientAnimation", ingredientID, dropGridRow, dropGridCol)
	if not ingredientID 
		or not dropGridRow or not (dropGridRow > 0)
		or not dropGridCol or not (dropGridCol > 0) 
		then 
		return 
	end

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return end

	local midPos = mainLogic:getGameItemPosInView(dropGridRow, dropGridCol)

	if ingredientID > 1 then
		Sakura2020Logic:playBigBoxAnim(ingredientID,midPos,dropGridRow,dropGridCol)
	else
		Sakura2020Logic:playDropIngredientAnimation(ingredientID, midPos)
	end
end

function Sakura2020Logic:playBigBoxAnim( ingredientID, middlePos,dropGridRow,dropGridCol )
	if not ingredientID or not middlePos then return end
	Sakura2020Manager.getInstance():addcollectSakuraNum(ingredientID)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end
	local cherries = UIHelper:createUI('tempFunctionResInLevel/Cherry/Sakura2020InGame.json', 'Sakura2020/cherries')
	cherries:setScale(0.92)
	cherries:setVisible(false)
	local a = mainLogic.boardView:safeGetItemView(dropGridRow,dropGridCol)
	local b = a.getContainer(ItemSpriteType.kTopLevelEffect)

	local worldPos = scene:convertToWorldSpace(ccp(middlePos.x, middlePos.y))
	local animPos = b:convertToNodeSpace(ccp(worldPos.x, worldPos.y))
	cherries:setPositionX(animPos.x-66)
	cherries:setPositionY(animPos.y+79.5)
	b:addChild(cherries)

	local array = CCArray:create()
	array:addObject(CCDelayTime:create(21/30))
	array:addObject(CCCallFunc:create(function ( ... )
		cherries:setVisible(true)
	end))
	cherries:runAction(CCSequence:create(array))

	
	local flyDuration = 0.6
	local endIconScale = 0.4
	local delayTime = 2/30

	-- local accessoryEndPos = ActCollectionLogic:getTargetPosByIndex(7, 1)

	local effectIcon
	local function onEffectIconScaleFinished()
		if effectIcon and not effectIcon.isDisposed then
			effectIcon:removeFromParentAndCleanup(true)
		end
		self.animNode = nil
	end

	for i = 1 , 5 do
		local oneCherry = cherries:getChildByName("f"..i)
		UIHelper:changeParentWhileStayOriPos(oneCherry,scene)
		oneCherry:setScale(UIHelper:convert2WorldSpace(oneCherry, 1))


		oneCherry:runAction(UIHelper:sequence{
		CCCallFunc:create(function ( ... )
			oneCherry:setVisible(false)
		end),
		CCDelayTime:create(21/30),
		CCCallFunc:create(function ( ... )
			oneCherry:setVisible(true)
		end),
		CCDelayTime:create(i*delayTime),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(accessoryEndPos.x-20,accessoryEndPos.y+20)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if oneCherry and not oneCherry.isDisposed then
				oneCherry:removeFromParentAndCleanup(true)
			end
			if i == 1 then
				-- printx(15,"addTargetNumberByIndex0000")
				-- ActCollectionLogic:addTargetNumberByIndex(7, 1, ingredientID, true) --7:Common_collectProgress.panelTypes.kSakura2020
			end
			local effectAssetName = "Sakura2020/heartIcon/shinyHeartIcon0000"
			effectIcon = UIHelper:createSpriteFrame('tempFunctionResInLevel/Cherry/Sakura2020InGame.json', effectAssetName)
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
end

function Sakura2020Logic:playDropIngredientAnimation(ingredientID, middlePos)
	-- printx(15, "Sakura2020Logic:playDropIngredientAnimation_ingredientID", ingredientID)
	if not ingredientID or not middlePos then return end
	Sakura2020Manager.getInstance():addcollectSakuraNum(ingredientID)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end




 	local iconSprite = Sprite:createEmpty()
 	local iconAssetName = "Sakura2020/ingredientIcon/commonIngredientIcon0000"
	local icon = UIHelper:createSpriteFrame('tempFunctionResInLevel/Cherry/Sakura2020InGame.json', iconAssetName)
	icon:setAnchorPoint(ccp(0.5,0.5))
	icon:setScale(2*GamePlayConfig_Tile_ScaleX)
	icon:setPosition(ccp(middlePos.x+5 , middlePos.y-5 ))
	iconSprite:addChild(icon)


	Sakura2020Logic:playIngredientFlyAnimation(ingredientID, icon, scene)

end

function Sakura2020Logic:playIngredientFlyAnimation(ingredientID, targetIcon, scene, delayTime)
	-- printx(11, "Sakura2020Logic:playIngredientFlyAnimation", ingredientID, targetIcon, targetIcon.isDisposed, scene)
	if not targetIcon or targetIcon.isDisposed or not scene then return end
	local targetIconPos = targetIcon:getPosition()
	local iconPos = ccp(0, 0)
	if targetIcon.parent and targetIconPos then
		iconPos = targetIcon.parent:convertToWorldSpace(ccp(targetIconPos.x, targetIconPos.y))
	end
	local parent = targetIcon.parent
	targetIcon:removeFromParentAndCleanup(false)
	parent:removeFromParentAndCleanup(true)
	scene:addChild(targetIcon)
	targetIcon:setPosition(ccp(iconPos.x, iconPos.y))
	targetIcon:setVisible(false)

	local targetIconIndex = 1


	local effectIcon
	local function onEffectIconScaleFinished()
		if effectIcon and not effectIcon.isDisposed then
			effectIcon:removeFromParentAndCleanup(true)
		end
		self.animNode = nil
	end

	if not delayTime then
		delayTime = 21/30
	end

	local flyDuration = 0.6
	local endIconScale = 0.4
	-- local accessoryEndPos = ActCollectionLogic:getTargetPosByIndex(7, targetIconIndex) --7:Common_collectProgress.panelTypes.kSakura2020
	targetIcon:runAction(UIHelper:sequence{
		CCDelayTime:create(delayTime),
		CCCallFunc:create(function ( ... )
			targetIcon:setVisible(true)
			-- local pos = scene:convertToWorldSpace(ccp(accessoryEndPos.x, accessoryEndPos.y))
			-- printx(15,"scene22",pos.x,pos.y)
		end),
		CCEaseExponentialInOut:create(CCSpawn:createWithTwoActions(CCMoveTo:create(flyDuration, ccp(accessoryEndPos.x, accessoryEndPos.y)), CCScaleTo:create(flyDuration, endIconScale, endIconScale))),
		CCCallFunc:create(function ( ... )
			if targetIcon and not targetIcon.isDisposed then
				targetIcon:removeFromParentAndCleanup(true)
			end
			-- printx(15,"addTargetNumberByIndex222",ingredientID)
			-- ActCollectionLogic:addTargetNumberByIndex(7, 1, ingredientID, true) --7:Common_collectProgress.panelTypes.kSakura2020

			local effectAssetName = "Sakura2020/heartIcon/shinyHeartIcon0000"
			effectIcon = UIHelper:createSpriteFrame('tempFunctionResInLevel/Cherry/Sakura2020InGame.json', effectAssetName)
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

function Sakura2020Logic:createTempIcon( icon, copyParentAndPos )
	local resname = "blocker_cherry_snow_anim_1_fly_0000"

	local layer = Sprite:createEmpty()
	layer:setCascadeOpacityEnabled(true)

	local sprite = Sprite:createWithSpriteFrameName(resname)
	local spriteSize = sprite:getContentSize()
	local scaleFactor = 0.5
	sprite.name = "content"
	sprite:setCascadeOpacityEnabled(true)
	sprite:setScale(scaleFactor)
	sprite:setAnchorPoint(ccp(0,0))
	layer.name = "icon"
	layer:addChild(sprite)
	local size = icon:getContentSize()
	layer:setContentSize(CCSizeMake(size.width, size.height))

	if copyParentAndPos then
		local position = icon:getPosition()
		local parent = icon:getParent()
		if parent then
			local grandParent = parent:getParent()
			if grandParent then 
				local position_parent = parent:getPosition()
				layer:setPosition(ccp(position.x + position_parent.x, position.y + position_parent.y))
				grandParent:addChild(layer)
			end
		end
	end

	return layer
end