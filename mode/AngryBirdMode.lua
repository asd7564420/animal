AngryBirdMode = class(MoveMode)

function AngryBirdMode:onGameInit()
	local birds = {}
	birds = AngryBirdLogic:getAngryBirdOnBoard(self.mainLogic)
	self.mainLogic.angryBirdNum = #birds
	MoveMode.onGameInit(self)
end

function AngryBirdMode:getScoreStarLevel()
	return 1
end

function AngryBirdMode:reachEndCondition()
	if not self.mainLogic or not self.mainLogic.currTravelMapIndex or not self.mainLogic.angryBirdNum then
		return
	end
	
	return self.mainLogic.theCurMoves <= 0 or (self.mainLogic.currTravelMapIndex == 3 and self.mainLogic.angryBirdNum == 0)
end

function AngryBirdMode:reachTarget()

	if not self.mainLogic or not self.mainLogic.currTravelMapIndex or not self.mainLogic.angryBirdNum then
		return
	end
	-- printx(15,"AngryBirdMode:reachTarget",self.mainLogic.currTravelMapIndex,self.mainLogic.angryBirdNum)
	return self.mainLogic.currTravelMapIndex == 3 and self.mainLogic.angryBirdNum == 0
end

function AngryBirdMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	saveRevertData.currTravelMapIndex = mainLogic.currTravelMapIndex
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.angryBirdsLevelData then
		saveRevertData.angryBirdsLevelData = table.clone(mainLogic.PlayUIDelegate.angryBirdsLevelData or {})
	end
	saveRevertData.currMapbirdRouteLength = mainLogic.currMapbirdRouteLength
	saveRevertData.needResetPropUseTimes = mainLogic.needResetPropUseTimes
	saveRevertData.angryBirdNum = mainLogic.angryBirdNum
	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea then
		saveRevertData.baojiState = mainLogic.PlayUIDelegate.topArea.baojiState
		saveRevertData.closeDie = mainLogic.PlayUIDelegate.topArea.closeDie
		-- printx(15,"saveRevertData.havebaoji",saveRevertData.havebaoji)
		-- printx(15,"saveRevertData.closeDie",saveRevertData.closeDie)
	end

	MoveMode.saveDataForRevert(self,saveRevertData)
	-- printx(15,"saveRevertData.angryBirdNum",saveRevertData.angryBirdNum)
end

function AngryBirdMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.currTravelMapIndex = mainLogic.saveRevertData.currTravelMapIndex
	mainLogic.needResetPropUseTimes = mainLogic.saveRevertData.needResetPropUseTimes
	mainLogic.angryBirdNum = mainLogic.saveRevertData.angryBirdNum
	-- printx(15,"mainLogic.needResetPropUseTimes",mainLogic.needResetPropUseTimes)

	if mainLogic and mainLogic.PlayUIDelegate and mainLogic.PlayUIDelegate.topArea then
		mainLogic.PlayUIDelegate.angryBirdsLevelData = mainLogic.saveRevertData.angryBirdsLevelData
		mainLogic.PlayUIDelegate.topArea.baojiState = mainLogic.saveRevertData.baojiState
		mainLogic.PlayUIDelegate.topArea.closeDie = mainLogic.saveRevertData.closeDie
		-- printx(15,"mainLogic.PlayUIDelegate.topArea.havebaoji",mainLogic.PlayUIDelegate.topArea.havebaoji)
		-- printx(15,"mainLogic.PlayUIDelegate.topArea.closeDie",mainLogic.PlayUIDelegate.topArea.closeDie)
	end
	mainLogic.currMapbirdRouteLength = mainLogic.saveRevertData.currMapbirdRouteLength
	MoveMode.revertDataFromBackProp(self)

	AngryBirdLogic:refreshUIafterChangeBoard(mainLogic,true)
end

-- 多屏支持
function AngryBirdMode:saveCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	inheritDataPack.currTravelMapIndex = gameBoardModel.currTravelMapIndex
end

function AngryBirdMode:loadCustomValuesNeedToInheritInChangingBoard(mainLogic, inheritDataPack)
	if not mainLogic or not inheritDataPack then return end
	local gameBoardModel = mainLogic:getBoardModel()
	if not gameBoardModel then return end

	gameBoardModel.currTravelMapIndex = inheritDataPack.currTravelMapIndex

end
