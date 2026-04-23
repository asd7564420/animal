TravelMode = class(MoveMode)

function TravelMode:onGameInit()
	TravelLogic:playHeroDebutAnimation(self.mainLogic)
	self.mainLogic.travelMapInitUsedMove = self.mainLogic.realCostMove or 0

	MoveMode.onGameInit(self)
end

function TravelMode:reachEndCondition()
	local endFlag = MoveMode.reachEndCondition(self) or TravelLogic:travelReachedDestination(self.mainLogic)
	-- printx(11, "~~~ TravelMode:reachEndCondition ~~~", endFlag)
  	return  endFlag
end

function TravelMode:getScoreStarLevel()
	return 1
end

function TravelMode:reachTarget()
	return TravelLogic:travelReachedDestination(self.mainLogic)
end

function TravelMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	saveRevertData.travelEnergy = mainLogic.travelEnergy
	saveRevertData.travelEventBoxOpened = mainLogic.travelEventBoxOpened
	saveRevertData.currTravelMapIndex = mainLogic.currTravelMapIndex
	saveRevertData.currMapTravelRouteLength = mainLogic.currMapTravelRouteLength
	saveRevertData.currMapTravelStep = mainLogic.currMapTravelStep
	saveRevertData.travelMapInitUsedMove = mainLogic.travelMapInitUsedMove
	saveRevertData.travelHeroReachedEndFlag = mainLogic.travelHeroReachedEndFlag
	MoveMode.saveDataForRevert(self,saveRevertData)
end

function TravelMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.travelEnergy = mainLogic.saveRevertData.travelEnergy
	mainLogic.travelEventBoxOpened = mainLogic.saveRevertData.travelEventBoxOpened
	mainLogic.currTravelMapIndex = mainLogic.saveRevertData.currTravelMapIndex
	mainLogic.currMapTravelRouteLength = mainLogic.saveRevertData.currMapTravelRouteLength
	mainLogic.currMapTravelStep = mainLogic.saveRevertData.currMapTravelStep
	mainLogic.travelMapInitUsedMove = mainLogic.saveRevertData.travelMapInitUsedMove
	mainLogic.travelHeroReachedEndFlag = mainLogic.saveRevertData.travelHeroReachedEndFlag
	MoveMode.revertDataFromBackProp(self)
end

function TravelMode:revertUIFromBackProp()
	MoveMode.revertUIFromBackProp(self)

	local mainLogic = self.mainLogic
	if mainLogic then
		if mainLogic.travelEventBoxOpened then
			local travelData = TravelLogic:getTravelData(mainLogic)
			if travelData then
				local accessoryAmount = 0
				if travelData.accessoryID and travelData.accessoryID > 0 then
					accessoryAmount = 1
				end
				-- ActCollectionLogic:setTargetToVisible(5, travelData.scoreAmount, accessoryAmount) --5:Common_collectProgress.panelTypes.kXmas2019
			end
		else
			-- ActCollectionLogic:revertTargetToUnkown(5) --5:Common_collectProgress.panelTypes.kXmas2019
		end
		ActCollectionLogic:refreshProgressBarPosition()

		if mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea and 
			mainLogic.PlayUIDelegate.topArea.updateScoreProgressBar then
			mainLogic.PlayUIDelegate.topArea:updateScoreProgressBar()
		end
	end
end

-- 多屏支持
function TravelMode:saveCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	inheritDataPack.currTravelMapIndex = gameBoardModel.currTravelMapIndex
	inheritDataPack.travelEventBoxOpened = gameBoardModel.travelEventBoxOpened
end

function TravelMode:loadCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	gameBoardModel.currTravelMapIndex = inheritDataPack.currTravelMapIndex
	gameBoardModel.travelEventBoxOpened = inheritDataPack.travelEventBoxOpened

	--业务逻辑放到外面，这里只进行恢复
	-- if gameBoardModel.currTravelMapIndex then
	-- 	gameBoardModel.currTravelMapIndex = self.mygameboardlogic.currTravelMapIndex + 1
	-- end
	gameBoardModel.travelMapInitUsedMove = gameBoardModel.realCostMove
end
