WeeklyRace2020Mode = class(DigMoveMode)
-- 多屏挖地模式

function WeeklyRace2020Mode:onGameInit()
	self.mainLogic.travelMapInitLeftMove = self.mainLogic.theCurMoves or 0
	-- printx(11, "init moves after change board:", self.mainLogic.travelMapInitLeftMove)

	DigMoveMode.onGameInit(self)
end

function WeeklyRace2020Mode:initModeSpecial(config)
	self.mainLogic.passedRow = 0
	
	if not self.mainLogic.digJewelCount then
		self.mainLogic.digJewelCount = DigJewelCount.new()
	end
end

function WeeklyRace2020Mode:reachEndCondition()
	local endFlag = MoveMode.reachEndCondition(self)
	-- local endFlag = MoveMode.reachEndCondition(self) or WeeklyRace2020Logic:weeklyRace2020ReachedEndCondition(self.mainLogic)
	-- local endFlag = DigMoveMode.reachEndCondition(self)
	-- local endFlag = MoveMode.reachEndCondition(self)
	-- printx(11, "~~~ WeeklyRace2020Mode:reachEndCondition ~~~", endFlag)
	return  endFlag
end

function WeeklyRace2020Mode:getScoreStarLevel()
	return 1
end

function WeeklyRace2020Mode:reachTarget()
	return false
	-- return WeeklyRace2020Logic:weeklyRace2020ReachedEndCondition(self.mainLogic)
	-- return MoveMode.reachEndCondition(self)
end

----------------------------------------------------------------------------------------------------
function WeeklyRace2020Mode:onEnterWaitingState()
	WeeklyRace2020Logic:releaseAllWeeklyRace2020ChestLayerLock(self.mainLogic)
end

function WeeklyRace2020Mode:checkScrollDigGround(stableScrollCallback)
	local maxDigGroundRow = self:getDigGroundMaxRow()
	local availableRow = self:getNumAvailableDigGroundRow()
	local SCROLL_GROUND_MIN_LIMIT = 2
	local SCROLL_GROUND_MAX_LIMIT = 4

	-- if (not self:reachTarget() and maxDigGroundRow <= SCROLL_GROUND_MIN_LIMIT and availableRow > 0) 
	-- 	or (self:reachTarget() and maxDigGroundRow < SCROLL_GROUND_MAX_LIMIT and availableRow > 0)
	if maxDigGroundRow <= SCROLL_GROUND_MIN_LIMIT and availableRow > 0 then
		local moveUpRow = 0
		local deltaRow = SCROLL_GROUND_MAX_LIMIT - maxDigGroundRow
		if availableRow < deltaRow then
			moveUpRow = availableRow
		else
			moveUpRow = deltaRow
		end
		moveUpRow = math.floor(moveUpRow / 2) * 2   --因为宝箱的关系，只滚动偶数行
		
		if moveUpRow > 0 then
			self:doScrollDigGround(moveUpRow, stableScrollCallback)
			return true
		else
			return false
		end
	end
	return false
end

--获得从含有挖地云块、周赛宝箱的第一层到最下一层的层数
function WeeklyRace2020Mode:getDigGroundMaxRow()
	local gameItemMap = self.mainLogic.gameItemMap
	for r = 1, #gameItemMap do
		for c = 1, #gameItemMap[r] do
			local itemType = gameItemMap[r][c].ItemType
			if itemType == GameItemType.kDigGround
				or itemType == GameItemType.kDigJewel 
				or WeeklyRace2020Logic:isWeeklyRace2020Chest(itemType) 
				then
				return 10 - r
			end
		end
	end
	return 0
end

function WeeklyRace2020Mode:handleDataAfterScrollCallBack()
	local mainLogic = self.mainLogic
	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)

	local tileDef = TileMetaData.new()
	tileDef:addTileData(TileConst.kEmpty)

	-- 它的挖地图只显示8行
	for r = 1, rowAmount do
		for c = 1, colAmount do
			if mainLogic.boardView and r < mainLogic.boardView.startRowIndex then 
				local itemData = GameItemData:create() 
				itemData:initByConfig(tileDef)
				if mainLogic.gameItemMap and mainLogic.gameItemMap[r] then
					mainLogic.gameItemMap[r][c] = itemData
				end

				if mainLogic.boardmap and mainLogic.boardmap[r] and mainLogic.boardmap[r][c] then
					local boardData = mainLogic.boardmap[r][c]
					boardData.isUsed = false
				end
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
function WeeklyRace2020Mode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic

	saveRevertData.currTravelMapIndex = mainLogic.currTravelMapIndex
	if mainLogic.traveledLevelRecord then
		saveRevertData.traveledLevelRecord = table.clone(mainLogic.traveledLevelRecord)
	end
	saveRevertData.travelMapInitLeftMove = mainLogic.travelMapInitLeftMove

	saveRevertData.passedRow = mainLogic.passedRow
	saveRevertData.digJewelCount = mainLogic.digJewelCount:getValue()

	-- 道具大招数据
	saveRevertData.fireworkEnergy = mainLogic.fireworkEnergy
	saveRevertData.isFullFirework = mainLogic.isFullFirework

	MoveMode.saveDataForRevert(self,saveRevertData)
end

function WeeklyRace2020Mode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	local saveRevertData = mainLogic.saveRevertData

	mainLogic.currTravelMapIndex = mainLogic.saveRevertData.currTravelMapIndex
	mainLogic.traveledLevelRecord = mainLogic.saveRevertData.traveledLevelRecord
	mainLogic.travelMapInitLeftMove = mainLogic.saveRevertData.travelMapInitLeftMove

	mainLogic.passedRow = mainLogic.saveRevertData.passedRow
	mainLogic.digJewelCount:setValue(saveRevertData.digJewelCount or 0)

	mainLogic.fireworkEnergy = saveRevertData.fireworkEnergy
	mainLogic.isFullFirework = saveRevertData.isFullFirework

	MoveMode.revertDataFromBackProp(self)
end

function WeeklyRace2020Mode:revertUIFromBackProp()
	local mainLogic = self.mainLogic
	if mainLogic.PlayUIDelegate then
		-- mainLogic.digJewelLeftCount
		mainLogic.PlayUIDelegate:revertTargetNumber(0, 0, mainLogic.digJewelCount:getValue())
		-- mainLogic.PlayUIDelegate:setFireworkEnergy(mainLogic.fireworkEnergy)
		mainLogic.PlayUIDelegate:resetFireworkStatusForRevert(mainLogic.fireworkEnergy)

		mainLogic.PlayUIDelegate.topArea:resetForRevert(mainLogic)

	end

	MoveMode.revertUIFromBackProp(self)
end

-- 多屏支持
function WeeklyRace2020Mode:saveCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	inheritDataPack.currTravelMapIndex = gameBoardModel.currTravelMapIndex
	if gameBoardModel.traveledLevelRecord then
		inheritDataPack.traveledLevelRecord = table.clone(gameBoardModel.traveledLevelRecord)
	end

	inheritDataPack.fireworkEnergy = gameBoardModel.fireworkEnergy
	inheritDataPack.isFullFirework = gameBoardModel.isFullFirework

	inheritDataPack.digJewelCount = mainLogic.digJewelCount:getValue()
end

function WeeklyRace2020Mode:loadCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	gameBoardModel.currTravelMapIndex = inheritDataPack.currTravelMapIndex
	gameBoardModel.traveledLevelRecord = inheritDataPack.traveledLevelRecord

	gameBoardModel.fireworkEnergy = inheritDataPack.fireworkEnergy
	gameBoardModel.isFullFirework = inheritDataPack.isFullFirework

	mainLogic.digJewelCount:setValue(inheritDataPack.digJewelCount or 0)

	mainLogic.travelMapInitLeftMove = mainLogic.theCurMoves or 0
	-- printx(11, "init moves after change board:", mainLogic.travelMapInitLeftMove)
end

----------------------------------------------------------------------------------------------
function WeeklyRace2020Mode:afterFail()
	-- printx(11, "----------- = = = * * * WeeklyRace2020Mode === afterFail * * * = = = -----------")
	-- if _G.isLocalDevelopMode then printx(0, 'WeeklyRace2020Mode:afterFail') end

	local mainLogic = self.mainLogic
	local function tryAgainWhenFailed(isTryAgain, propId, deltaStep)   ----确认加5步之后，修改数据
		-- printx(11, "----------- = = = * * *  afterFail == tryAgainWhenFailed * * * = = = -----------")
		if isTryAgain then
			-- self:addStepSucess()

			SnapshotManager:stop()
			self:getAddSteps(deltaStep or 5)

			mainLogic:setGamePlayStatus(GamePlayStatus.kNormal)
			mainLogic.fsm:changeState(mainLogic.fsm.waitingState)

			mainLogic:checkUpdateLevelDifficultyAdjustByUseProp( UsePropsType.NORMAL , propId or GamePropsType.kAdd5 )

			--确保在使用中途闪退，恢复后能加上
			mainLogic:useProps(propId, 0, 0, 0, 0, UsePropsType.TEMP)

			GameGuide:sharedInstance():onEndgameAddStepBomb()
		else
			-- 准备结束
			WeeklyRace2020Mgr.getInstance():cachePlayId(GamePlayContext:getInstance():getIdStr())

			-- 有大招先放大招
			if mainLogic.isFullFirework then
				self.propReleasedBeforeBonus = true

				mainLogic:setGamePlayStatus(GamePlayStatus.kNormal)
				mainLogic.fsm:changeState(mainLogic.fsm.fallingMatchState)

				local function toForceUseProp()
					mainLogic:useMegaPropSkill(false, true, true, true)
				end
				local delay = 1
				local curScene = Director:sharedDirector():getRunningScene()
				if curScene.name ~= "GamePlaySceneUI" then
					toForceUseProp()
				else
					local proxy = curScene.topArea:getSpringItemProxy()
					proxy:use()
					delay = delay+0.5
				end
			else
				-- 直接进
				mainLogic:setGamePlayStatus(GamePlayStatus.kBonus)
			end
		end
	end 

	if mainLogic.PlayUIDelegate then
		mainLogic.PlayUIDelegate:addStep(mainLogic.level, mainLogic.totalScore, self:getScoreStarLevel(), self:reachTarget(), tryAgainWhenFailed)
	end
end

function WeeklyRace2020Mode:enterRealBonusState()
    self.propReleasedBeforeBonus = false
    self.mainLogic:setGamePlayStatus(GamePlayStatus.kBonus)
end

-- function WeeklyRace2020Mode:addStepSucess()
-- 	GameGuide:sharedInstance():onEndgameAddStepBomb()

-- 	WeeklyRace2020Logic:onWeeklyRace2020AddFive(self.mainLogic)

-- 	self:getAddSteps(deltaStep or 5)
-- end

function WeeklyRace2020Mode:scrollToPreviewNextChest( waitDuration, previewCallback, stableScrollCallback )
	-- body

	local mainLogic = self.mainLogic
	local _chestInfo = {}

	local chestPosInfo = {}

	local digItemMap = mainLogic.digItemMap
	for r = 1, #digItemMap do
		for c = 1, #digItemMap[r] do
			local itemData = digItemMap[r][c]
			if WeeklyRace2020Logic:isWeeklyRace2020Chest(itemData.ItemType) and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(itemData) then
				if itemData.weeklyRace2020ChestData then
					chestType = itemData.weeklyRace2020ChestData.weeklyRace2020ChestType
					if not _chestInfo[r] then
						_chestInfo[r] = {}
					end
					table.insert(_chestInfo[r], chestType)
					chestPosInfo[r] = c
				end
			end
		end
	end




	local chestType = 0
	local chestDistance = 0
	local chestPos 

	local gameItemMap = mainLogic.gameItemMap
	for r = 1, #gameItemMap do
		for c = 1, #gameItemMap[r] do
			local itemData = gameItemMap[r][c]
			if WeeklyRace2020Logic:isWeeklyRace2020Chest(itemData.ItemType) and WeeklyRace2020Logic:isWeeklyRace2020ChestRoot(itemData) then
				if itemData.weeklyRace2020ChestData then
					chestType = itemData.weeklyRace2020ChestData.weeklyRace2020ChestType
					break
				end
			end
		end
	end

	if chestType > 0 then
	else
		for i = mainLogic.passedRow+1, table.max(table.keys(_chestInfo)) do
			if _chestInfo[i] then
				chestType = _chestInfo[i][1]
				chestDistance = i - mainLogic.passedRow
				chestPos = {r = i, c = chestPosInfo[i]}
				break
			end
		end
	end

	if chestDistance > 0 then
		if chestDistance % 2 == 1 then
			chestDistance = chestDistance + 1
		end
		local extraItemMap = self:getExtraItemMap(self.mainLogic.passedRow, chestDistance)
		local extraBoardMap = self:getExtraBoardMap(self.mainLogic.passedRow, chestDistance)

		local mainLogic = self.mainLogic
		local context = self

		self.mainLogic.boardView:hideItemViewLayer()
		self.mainLogic.boardView:scrollToPreviewDigView(extraItemMap, extraBoardMap, function ( ... )
			-- self.mainLogic.boardView:reInitByGameBoardLogic()
			self.mainLogic.boardView:showItemViewLayer()
			self.mainLogic.boardView:removeDigScrollView()
			-- self.mainLogic.squidOnBoard = nil

			if stableScrollCallback then stableScrollCallback() end
		end, previewCallback, waitDuration)
		return chestPos, chestType
	end
end