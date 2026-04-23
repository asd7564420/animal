SpringFes2020Logic = class{}
local CloverRaceCircleCtrl = require('zoo.localActivity.CloverRace.inGameView.CloverRaceCircleCtrl')
local NewYearStageContext = require 'zoo.localActivity.NewYear2020.NewYearStageContext'
-- require "zoo.localActivity.NewYear2020.NewYearStageContext"

---------------------------------- Data ---------------------------------
function SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end

	local springFesData
	-- printx(11, "springFes2020Data", mainLogic.PlayUIDelegate.springFes2020Data)
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.springFes2020Data then
		springFesData = mainLogic.PlayUIDelegate.springFes2020Data 
	end

	return springFesData
end

function SpringFes2020Logic:setSpringFes2020DataForLevel(playUIDelegate, replayDataSet, levelID)
	-- printx(11, "==== SpringFes2020Logic:setSpringFes2020DataForLevel", table.tostring(replayDataSet), levelID)
	if not playUIDelegate then return end

	local springFes2020DataSet
	local dataValid = false
	if replayDataSet then
		springFes2020DataSet = replayDataSet

		local activityData = NewYearStageContext:getInstance()
		if activityData then
			activityData:decode(springFes2020DataSet, levelID)
		end

		dataValid = true
	else
		-- printx(11, "not from replay...")
		self:initDataForSpringFes2020(playUIDelegate)
		-- self:setTestDataForSpringFes2020(playUIDelegate) -- testt
	end

	-- printx(11, "dataValid, springFes2020DataSet", dataValid, table.tostring(springFes2020DataSet))
	if springFes2020DataSet and dataValid then
		playUIDelegate.springFes2020Data = springFes2020DataSet
	end
end

-- 初始化时调用一次
function SpringFes2020Logic:initDataForSpringFes2020(playUIDelegate)
	-- NewYearStageContext:reset() --testt
	local activityData = NewYearStageContext:getInstance()
	if not activityData then return end
	-- printx(11, "context SF-2020 activityData:", table.tostring(activityData))

	local springFes2020Data = {}
	springFes2020Data["chapterID"] = activityData.stageIndex or 1
	springFes2020Data["accessoryMap"] = {}
	if activityData.dressupPieces then
		for acceID, acceNum in pairs(activityData.dressupPieces) do
			if acceID and acceNum and acceNum > 0 then
				springFes2020Data["accessoryMap"][tostring(acceID)] = acceNum
			end
		end
	end
	springFes2020Data["ticketNum"] = activityData.exchangeNum or 0

	local boostAmount = activityData.buff or 0
	springFes2020Data["accessoryBoost"] = boostAmount * 100 --存储的是小数

	springFes2020Data["cheeseCount"] = activityData.targetCount or 0
	springFes2020Data["isFirstRound"] = activityData.isFirstRound

	local function setStepDatas(selfKey, dataKey)
		springFes2020Data[selfKey] = {}

		if activityData[dataKey] then
			for i = 1, 3 do
				local stepVal = activityData[dataKey][i]
				if stepVal and type(stepVal) == "number" then
					springFes2020Data[selfKey][i] = stepVal
				end
			end
		end
	end
	setStepDatas("leftStepRecord", "steps")
	setStepDatas("currLeftStepRecord", "stepResults")

	springFes2020Data["cheeseFinalCalculated"] = false

	-- printx(11, "springFes2020Data inited", table.tostring(springFes2020Data))
	playUIDelegate.springFes2020Data = springFes2020Data
end

MACRO_DEV_START()
function SpringFes2020Logic:setTestDataForSpringFes2020(playUIDelegate)
	if not playUIDelegate then return end
   
	local springFes2020Data = {}
	springFes2020Data["chapterID"] = 1
	springFes2020Data["accessoryMap"] = {}
	springFes2020Data["accessoryMap"]["2"] = 3
	springFes2020Data["accessoryMap"]["6"] = 5
	springFes2020Data["ticketNum"] = 6
	springFes2020Data["accessoryBoost"] = 20

	springFes2020Data["cheeseCount"] = 0
	springFes2020Data["leftStepRecord"] = {5, 2, -2}	--历史数据
	springFes2020Data["currLeftStepRecord"] = {}		--本轮数据，关卡外用
	springFes2020Data["isFirstRound"] = true

	springFes2020Data["cheeseFinalCalculated"] = false

	printx(11, "dummy springFes2020Data", table.tostring(springFes2020Data))
	playUIDelegate.springFes2020Data = springFes2020Data
end
MACRO_DEV_END()

-- 是本章的第几小关
function SpringFes2020Logic:getLevelIndexInChapter(levelID)
	-- printx(11, "==== SpringFes2020Logic:getLevelIndexInChapter", levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > LevelConstans.SPRING_FES_2020_LEVEL_ID_START then
		local activityLevelID = levelID - LevelConstans.SPRING_FES_2020_LEVEL_ID_START
		local index = CalculationUtil:modValueBetween(1, 3, activityLevelID)
		-- printx(11, "==== SpringFes2020Logic:getLevelIndexInChapter", index)
		return index
	end
	return 2 --返回一个不特殊的
end

function SpringFes2020Logic:getChapterIDByLevelID(levelID)
	if not levelID then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			levelID = mainLogic.level
		end
	end

	if levelID and levelID > LevelConstans.SPRING_FES_2020_LEVEL_ID_START then
		local activityLevelID = levelID - LevelConstans.SPRING_FES_2020_LEVEL_ID_START
		local chapterID = math.ceil(activityLevelID / 3)
		-- printx(11, "==== SpringFes2020Logic:getChapterIDByLevelID", chapterID)
		return chapterID
	end
	return 1
end

-- 本关上次步数记录值
function SpringFes2020Logic:getLastStepRecord(levelID)
	local data = SpringFes2020Logic:getSpringFes2020Data()
	if not data or not data.leftStepRecord or data.isFirstRound then return nil end

	local levelIndex = SpringFes2020Logic:getLevelIndexInChapter(levelID)
	local lastStepRecord = data.leftStepRecord[levelIndex]
	if lastStepRecord and type(lastStepRecord) == "number" and lastStepRecord ~= -2 then
		return math.max(0, lastStepRecord)
	end

	return nil
end

MACRO_DEV_START()
-- 多关连续下来的总收集量，每关过关时更新一次。若在打关途中，则此值只表示前几关的收集量。
MACRO_DEV_END()
function SpringFes2020Logic:getWholeCheeseCollectNum(mainLogic)
	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if springFesData and springFesData.cheeseCount then
		-- printx(11, "springFesData.cheeseCount", springFesData.cheeseCount)
		return springFesData.cheeseCount
	end
	return 0
end

-- 本关目标奶酪收集量
function SpringFes2020Logic:getCurrLevelTargetCheeseCollectNum(mainLogic)
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if not mainLogic then return 0 end

	local collectedNum = 0
 	if mainLogic.theOrderList and #mainLogic.theOrderList then
		for i, v in ipairs(mainLogic.theOrderList) do
			-- 所有都被转化为了6-4
	        if v.key1 == GameItemOrderType.kSeaAnimal and v.key2 == GameItemOrderType_SeaAnimal.kMistletoe then
	        	collectedNum = v.f1
	        end
	    end
	end

	return collectedNum
end

function SpringFes2020Logic:getCurrLevelCheeseCollectNumWithBoost(mainLogic, considerSteps)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return 0 end

	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if not springFesData then return 0 end

	local targetCheeseNum = SpringFes2020Logic:getCurrLevelTargetCheeseCollectNum(mainLogic)
	local moveBonusCheeseNum = 0
	local accessoryBoostRate = 0
	local surpassRecordBoostRate = 0

	if springFesData.accessoryBoost then
		accessoryBoostRate = springFesData.accessoryBoost / 100
	end
	
	if considerSteps then
		local leftSteps = math.max(0, mainLogic.theCurMoves or 0)
		moveBonusCheeseNum = leftSteps * 20

		local lastStepRecord = SpringFes2020Logic:getLastStepRecord(mainLogic.level)
		if lastStepRecord then
			if leftSteps > lastStepRecord then
				surpassRecordBoostRate = 0.8
			end
		end
	end

	local finalCheeseNum = math.ceil((targetCheeseNum + moveBonusCheeseNum) * (1 + accessoryBoostRate + surpassRecordBoostRate))
	-- printx(11, "getCurrLevelCheeseCollectNumWithBoost:", finalCheeseNum, targetCheeseNum, moveBonusCheeseNum, accessoryBoostRate, surpassRecordBoostRate, finalCheeseNum)
	return finalCheeseNum
end

function SpringFes2020Logic:recordStepsOnFinal(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if not springFesData then return end

	local leftSteps = math.max(0, mainLogic.theCurMoves or 0)
	local levelIndex = SpringFes2020Logic:getLevelIndexInChapter()
	if not springFesData.currLeftStepRecord then
		springFesData.currLeftStepRecord = {}
	end
	if levelIndex and levelIndex > 0 then
		springFesData.currLeftStepRecord[levelIndex] = leftSteps
	end
end

function SpringFes2020Logic:getLogicalMaxCheeseNumAtNow()
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return 0 end

	local oldCheeseNum = 0
	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if springFesData and springFesData.cheeseCount then
		oldCheeseNum = springFesData.cheeseCount
	end

	local logicalCurrCheeseNum = SpringFes2020Logic:getCurrLevelCheeseCollectNumWithBoost(mainLogic, false)

	local finalCheeseNum = oldCheeseNum + logicalCurrCheeseNum
	-- printx(11, "=== getLogicalMaxCheeseNumAtNow", finalCheeseNum, oldCheeseNum, logicalCurrCheeseNum)
	return finalCheeseNum
end

-- 过关时调用一次
function SpringFes2020Logic:calculateFinalCheeseNumAndRecordStep(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	if not mainLogic then return end

	-- 更新步数记录
	SpringFes2020Logic:recordStepsOnFinal(mainLogic)
	-- 更新分数
	local currFinalCheeseNum = SpringFes2020Logic:getCurrLevelCheeseCollectNumWithBoost(mainLogic, true)
	local oldCheeseNum = 0
	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if springFesData then
		if springFesData.cheeseCount then
			oldCheeseNum = springFesData.cheeseCount
		end
		springFesData.cheeseCount = currFinalCheeseNum + oldCheeseNum
		-- printx(11, "=== calculateFinalCheeseNumAndRecordStep:", springFesData.cheeseCount)
		springFesData.cheeseFinalCalculated = true
	end
end

function SpringFes2020Logic:getSpringFes2020PasslevelExtraData(star)
	local extraData = {}
	extraData["chipMap"] = {}
	extraData["ticketNums"] = 0
	extraData["collectNums"] = 0
	extraData["stepRemains"] = 0

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic then
		extraData["stepRemains"] = mainLogic.theCurMoves
	end

	if star and star > 0 then
		local levelIndex = SpringFes2020Logic:getLevelIndexInChapter()
		-- 成功的情境下，前两关不传相关数据
		if levelIndex == 3 then
			local data = SpringFes2020Logic:getSpringFes2020Data()
			if data then
				if data.accessoryMap then
					extraData["chipMap"] = table.clone(data.accessoryMap)
				end
				if data.ticketNum then
					extraData["ticketNums"] = data.ticketNum
				end
				if data.cheeseCount then
					extraData["collectNums"] = data.cheeseCount
				end
				if data.chapterID then
					extraData["chapterId"] = data.chapterID
				end
			end
		end
	else
		-- 失败
		extraData["collectNums"] = 5
	end
	-- printx(11, "++ Pass Level extra Data:", table.tostring(extraData))
	return extraData
end

function SpringFes2020Logic:getSpringFes2020NoitfyData(levelType, levelID, isWin)
	local notifyData = {}
	notifyData["levelType"] = levelType
	notifyData["levelId"] = levelID

	local mainLogic = GameBoardLogic:getCurrentLogic()
	if isWin then
		notifyData["leftMoves"] = 0
		if mainLogic and mainLogic.theCurMoves then
			notifyData["leftMoves"] = mainLogic.theCurMoves
		end
		notifyData["targetCount"] = SpringFes2020Logic:getWholeCheeseCollectNum(mainLogic)

		local data = SpringFes2020Logic:getSpringFes2020Data()
		if data then
			notifyData["ticketNums"] = data.ticketNum
			notifyData["chipMap"] = table.clone(data.accessoryMap)
		end
	else
		notifyData["leftMoves"] = -1
		notifyData["targetCount"] = 5
	end

	return notifyData
end

function SpringFes2020Logic:dcSpringFes2020PassLevel(levelID, isWin, isQuit)
	local t1 = levelID
	local t2 = 1
	if not isWin then
		if isQuit then
			t2 = 3
		else
			t2 = 2
		end
	end

	local lastStepRecord = SpringFes2020Logic:getLastStepRecord(levelID)
	if lastStepRecord then
		t3 = 2
	else
		t3 = 1
	end

	local t4, t5
	if isWin then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		local leftSteps
		if mainLogic and mainLogic.theCurMoves then
			leftSteps = mainLogic.theCurMoves
			t4 = leftSteps
		end

		if lastStepRecord and leftSteps then
			if leftSteps > lastStepRecord then
				t5 = 1
			else
				t5 = 2
			end
		end
	end

	local params = {
		game_type = "stage",
		game_name = "20spring",
		category = "canyu",
		sub_category = "stage_end",
		t1 = t1,
		t2 = t2,
		t3 = t3,
		t4 = t4,
		t5 = t5,
	}
	DcUtil:activity(params)
end

function SpringFes2020Logic:dcSpringFes2020ChapterRewardPanelShare()
	local params = {
		game_type = "stage",
		game_name = "20spring",
		category = "share",
		sub_category = "share_pass_one",
	}
	DcUtil:activity(params)
end

---------------------------------------------------- Some Animations -------------------------------------------------------
----------------------------------- Enter
function SpringFes2020Logic:checkPlayEnterAnimation(levelID, mainLogic)
	-- printx(11, "SpringFes2020Logic:checkPlayEnterAnimation", levelID, mainLogic)
	local levelIndex = SpringFes2020Logic:getLevelIndexInChapter(levelID)
	if levelIndex == 1 then
		SpringFes2020Logic:playHamsterEnterAnimation(mainLogic)
		return true
	end
	return false
end

function SpringFes2020Logic:playHamsterEnterAnimation(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end

	local hamsterAnim = gAnimatedObject:createWithFilename('tempFunctionResInLevel/SpringFes2020/gaf/springFes2020Enter_hamster.gaf')
	if not hamsterAnim then return end
	local middlePos = mainLogic:getGameItemPosInView(5, 5)
	local animPos = ccp(middlePos.x - 430, middlePos.y + 830)
	hamsterAnim:setPosition(animPos)

	local container = Layer:create()
	container:setTouchEnabled(true, 0, true)
	scene:addChild(container)

	local darkLayer = UIHelper:createDarkLayer(130)
	container:addChild(darkLayer)

	local function finishCallback( ... )
		if container and not container.isDisposed then
			container:removeFromParentAndCleanup(true)
			container = nil
		end
	end

	local function onStartPeriodFinished()
		if hamsterAnim and not hamsterAnim.isDisposed then
			hamsterAnim:setSequenceDelegate('boxFly', finishCallback)
			hamsterAnim:playSequence("boxFly", false, true, ASSH_RESTART)
			hamsterAnim:start()

			self:_playHamsterEnterBoxFlyAnimation(mainLogic, animPos)
		end
	end

	hamsterAnim:setSequenceDelegate('start', onStartPeriodFinished, true)
	hamsterAnim:playSequence("start", false, true, ASSH_RESTART)
	hamsterAnim:start()

	container:addChild(hamsterAnim)
end

function SpringFes2020Logic:_playHamsterEnterBoxFlyAnimation(mainLogic, hamsterPos)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end

	local branchTreasureBox

	local treasureBoxAnim = gAnimatedObject:createWithFilename('tempFunctionResInLevel/SpringFes2020/gaf/springFes2020Enter_box.gaf')
	if not treasureBoxAnim then return end
	local animPos = ccp(hamsterPos.x, hamsterPos.y)
	treasureBoxAnim:setPosition(animPos)

	local container = Layer:create()
	container:setTouchEnabled(true, 0, true)
	scene:addChild(container)

	local function finishCallback( ... )
		if container and not container.isDisposed then
			container:removeFromParentAndCleanup(true)
			container = nil
		end
	end

	local function onReachedIcon()
		if treasureBoxAnim and not treasureBoxAnim.isDisposed then
			treasureBoxAnim:setSequenceDelegate('reachIcon', finishCallback)
			treasureBoxAnim:playSequence("reachIcon", false, true, ASSH_RESTART)
			treasureBoxAnim:start()
		end
		if branchTreasureBox and not branchTreasureBox.isDisposed then
			branchTreasureBox:setVisible(true)
		end
	end

	treasureBoxAnim:setSequenceDelegate('start', onReachedIcon, true)
	treasureBoxAnim:playSequence("start", false, true, ASSH_RESTART)
	treasureBoxAnim:start()

	local endPos
	if mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea then
		branchTreasureBox = mainLogic.PlayUIDelegate.topArea.treasureBox
		if branchTreasureBox and not branchTreasureBox.isDisposed and branchTreasureBox.parent then
			local posOnBranch = branchTreasureBox:getPosition()
			branchTreasureBoxPos = branchTreasureBox.parent:convertToWorldSpace(ccp(posOnBranch.x, posOnBranch.y))
			endPos = ccp(branchTreasureBoxPos.x - 320, branchTreasureBoxPos.y + 550)
		end
	end

	if not endPos then endPos = hamsterPos end
	local flyAniDuration = 0.1
	local actArr = CCArray:create()
	actArr:addObject(CCMoveTo:create(flyAniDuration, ccp(endPos.x, endPos.y)))
	-- actArr:addObject(CCCallFunc:create(onfinish) )
	treasureBoxAnim:runAction(CCSequence:create(actArr))

	container:addChild(treasureBoxAnim)
end

function SpringFes2020Logic:showBranchTreasureBox(mainLogic)
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea then
		branchTreasureBox = mainLogic.PlayUIDelegate.topArea.treasureBox
		if branchTreasureBox and not branchTreasureBox.isDisposed then
			branchTreasureBox:setVisible(true)
		end
	end
end

----------------------------------- End level cheese collection
function SpringFes2020Logic:playReceiveCheeseAnimation(mainLogic)
	if not mainLogic then mainLogic = GameBoardLogic:getCurrentLogic() end
	local scene = Director:sharedDirector():getRunningScene()
	if not mainLogic or not scene then return end

	local cheeseAmountLabel

	local foodBowlID = 1

	local foodBowlAsset = "foodBowlAni"..foodBowlID
	local foodBowlAnim = gAnimatedObject:createWithFilename("tempFunctionResInLevel/SpringFes2020/gaf/"..foodBowlAsset..".gaf")
	if not foodBowlAnim then return end
	local middlePos = mainLogic:getGameItemPosInView(8, 5)
	local foodBowlPos = ccp(middlePos.x, middlePos.y)
	foodBowlAnim:setPosition(foodBowlPos)

	local container = Layer:create()
	container:setTouchEnabled(true, 0, true)
	scene:addChild(container)

	local darkLayer = UIHelper:createDarkLayer(0)
	container:addChild(darkLayer)

	local function removeAllParts()
		if container and not container.isDisposed then
			container:removeFromParentAndCleanup(true)
			container = nil
		end
	end

	local function finishCallback( ... )
		setTimeOut(removeAllParts, 2)
	end

	local function onFlyPeriodFinished()
		if foodBowlAnim and not foodBowlAnim.isDisposed then
			foodBowlAnim:setSequenceDelegate('idle', finishCallback)
			foodBowlAnim:playSequence("idle", false, true, ASSH_RESTART)
			foodBowlAnim:start()
		end

		if darkLayer and not darkLayer.isDisposed then
			darkLayer:runAction(CCFadeTo:create(0.2, 180))
		end

		SpringFes2020Logic:playDescAnimation(container, foodBowlPos, mainLogic)
	end

	local function onAppearPeriodFinished()
		if foodBowlAnim and not foodBowlAnim.isDisposed then
			foodBowlAnim:setSequenceDelegate('receive', onFlyPeriodFinished)
			foodBowlAnim:playSequence("receive", false, true, ASSH_RESTART)
			foodBowlAnim:start()
		end

		SpringFes2020Logic:playNumberRollingAnimation(cheeseAmountLabel, mainLogic)
	end

	foodBowlAnim:setSequenceDelegate('appear', onAppearPeriodFinished, true)
	foodBowlAnim:playSequence("appear", false, true, ASSH_RESTART)
	foodBowlAnim:start()
	container:addChild(foodBowlAnim)

	cheeseAmountLabel = CloverRaceCircleCtrl:create(container, ccp(foodBowlPos.x + 110, foodBowlPos.y + 20), 
		0, "fnt/bzds2.fnt", 1.4, kCCTextAlignmentRight, 5, 28)

	-- fly cheese
	local endPos = ccp(foodBowlPos.x, foodBowlPos.y)

	local orderBoardPos = mainLogic:getLevelTargetGlobalPosition(1)

	local leftSteps = math.max(0, mainLogic.theCurMoves or 0)
	local moveBoardPos
	if leftSteps and leftSteps > 0 and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea then
		local moveBoard = mainLogic.PlayUIDelegate.topArea.moveOrTimeCounter
		if moveBoard and not moveBoard.isDisposed and moveBoard.parent then
			local moveBoardLocalPos = moveBoard:getPosition()
			moveBoardPos = moveBoard.parent:convertToWorldSpace(ccp(moveBoardLocalPos.x, moveBoardLocalPos.y))
		end
	end

	local flyCount = 0
	local function tryFlyCheeseToBowl()
		if flyCount < 6 then
			-- 按美术的示意，错落一点
			if flyCount == 0 or flyCount == 3 or flyCount == 4 then
				if orderBoardPos then
					SpringFes2020Logic:playCheeseFlyToBowlAnimation(ccp(orderBoardPos.x - 15, orderBoardPos.y + 20), endPos, container)
				end
			else
				if moveBoardPos then
					SpringFes2020Logic:playCheeseFlyToBowlAnimation(ccp(moveBoardPos.x - 20, moveBoardPos.y - 100), endPos, container)
				end
			end
			flyCount = flyCount + 1
			setTimeOut(tryFlyCheeseToBowl, 0.05)
		end
	end
	setTimeOut(tryFlyCheeseToBowl, 0.6)
end

function SpringFes2020Logic:playCheeseFlyToBowlAnimation(rawStartPos, rawEndPos, container)
	if not container or container.isDisposed then return end

	local startPos = ccp(rawStartPos.x - 100, rawStartPos.y + 80)
	local endPos = ccp(rawEndPos.x - 120, rawEndPos.y + 240)

	local cheeseSprite = UIHelper:createUI('tempFunctionResInLevel/SpringFes2020/SpringFes2020InGame.json', 
		'springFes2020/cheeseCollectIcon')
	cheeseSprite:setScale(1.3)
	cheeseSprite:setPosition(startPos)

	local function onfinish()
		if cheeseSprite and not cheeseSprite.isDisposed then 
			cheeseSprite:removeFromParentAndCleanup(true) 
		end
	end

	local flyAniDuration = 0.4
	local actArr = CCArray:create()
	actArr:addObject(CCMoveTo:create(flyAniDuration, ccp(endPos.x, endPos.y)))
	actArr:addObject(CCCallFunc:create(onfinish) )
	cheeseSprite:runAction(CCSequence:create(actArr))
		
	container:addChildAt(cheeseSprite, 0)
end

function SpringFes2020Logic:playNumberRollingAnimation(amountLabel, mainLogic)
	if not mainLogic or not amountLabel or amountLabel.isDisposed then return end

	local cheeseAmount = SpringFes2020Logic:getCurrLevelCheeseCollectNumWithBoost(mainLogic, true)
	if cheeseAmount > 0 then
		amountLabel.updateNumStep = math.ceil(cheeseAmount / 6)  --只增加一次
		amountLabel:setNumber(cheeseAmount, true)
	end
end

function SpringFes2020Logic:playDescAnimation(container, bowlPos, mainLogic)
	if not container or container.isDisposed then return end

	local descAnim = UIHelper:createArmature3("tempFunctionResInLevel/SpringFes2020/skeleton/springFes2020ReceiveCheese", 
		"springFes2020ReceiveCheese", "springFes2020ReceiveCheese", "springFes2020_receiveCheeseDesc")
	if not descAnim then return end

	local springFesData = SpringFes2020Logic:getSpringFes2020Data(mainLogic)
	if not springFesData then return end
	
	local accessoryBoost = 0
	if springFesData.accessoryBoost then
		accessoryBoost = springFesData.accessoryBoost
	end

	local surpassRecord = false
	local leftSteps = math.max(0, mainLogic.theCurMoves or 0)
	local lastStepRecord = SpringFes2020Logic:getLastStepRecord(mainLogic.level)
	if lastStepRecord and leftSteps > lastStepRecord then
		surpassRecord = true
	end

	local breakRecordDesc = UIHelper:getCon(descAnim, "recordDesc")
	if not surpassRecord then
		breakRecordDesc:setOpacity(0)
	end

    local cheeseAmountPlate = UIHelper:getCon(descAnim, "sumNum")
    local cheeseAmount = SpringFes2020Logic:getCurrLevelCheeseCollectNumWithBoost(mainLogic, true)
    local cheeseAmountLabel = BitmapText:create("x"..cheeseAmount, "fnt/bzds2.fnt", 0)
    cheeseAmountLabel:setScale(1.2)
    cheeseAmountLabel:setAnchorPoint(ccp(0, 0))
    cheeseAmountLabel:setPosition(ccp(-15, -20))
    cheeseAmountPlate:addChild(cheeseAmountLabel.refCocosObj)
    cheeseAmountLabel:dispose()

    local accessoryBoostPlate = UIHelper:getCon(descAnim, "accessoryNum")
    local acceBoostLabel = BitmapText:create("+"..accessoryBoost.."%", "fnt/bzds2.fnt", 0)
    -- acceBoostLabel:setScale(1.2)
    acceBoostLabel:setAnchorPoint(ccp(0, 0))
    acceBoostLabel:setPosition(ccp(-15, -15))
    accessoryBoostPlate:addChild(acceBoostLabel.refCocosObj)
    acceBoostLabel:dispose()

	descAnim:setPosition(ccp(bowlPos.x + 15, bowlPos.y + 400))
	container:addChild(descAnim)

	descAnim:playByIndex(0, 1)
end

------------------------------- Some calculation --------------------------------
function SpringFes2020Logic:getMultiCollectSingleNumberByValue(numberValue)
	local num1 = 0
	local num2 = 0
	local num3 = 0

	if not numberValue then
		local mainLogic = GameBoardLogic:getCurrentLogic()
		if mainLogic then
			numberValue = mainLogic.SunmerFish3x3GetNum
		end
	end

	if numberValue then
		if numberValue > 999 then
			numberValue = 999
		end

		num1 = math.floor(numberValue / 100)

		numberValue = numberValue - num1 * 100
		num2 = math.floor(numberValue / 10)

		numberValue = numberValue - num2 * 10
		num3 = numberValue
	end

	local numberList = {}
	table.insert(numberList, num1)
	table.insert(numberList, num2)
	table.insert(numberList, num3)

	return numberList
end

function SpringFes2020Logic:isNightTime()
	local currTime = os.time()
	local todayStartTime = getDayStartTimeByTS(currTime)
	local currTimeShift = currTime - todayStartTime
	if currTimeShift < 0 then return false end 

	local nightEndTime = 6 * 3600
	local nightStartTime = 18 * 3600

	if (currTimeShift > nightEndTime) and (currTimeShift < nightStartTime) then
		return false
	end
	return true
end

