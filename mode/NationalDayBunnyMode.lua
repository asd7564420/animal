NationalDayBunnyMode = class(OrderMode)

function NationalDayBunnyMode:initModeSpecial(config,replayData)
	local moves
	if self.mainLogic.replayMode and replayData then
		moves = replayData.originBunnyModeMove or self.mainLogic.theCurMoves
	else
		moves = NDLevelDropLogic:tryGetMoveLimit() or self.mainLogic.theCurMoves
	end
	self.mainLogic.theCurMoves = moves
	self.mainLogic.staticLevelMoves = self.mainLogic.theCurMoves
	OrderMode.initModeSpecial(self, config)
end

function NationalDayBunnyMode:afterFail()
	if NationalDayBunnyLogic:hasAnyBunnyLeave(self.mainLogic) then
    	GameExtandPlayLogic:tryShowNDBunnyResurrectPanel(self)
	else
    	GameExtandPlayLogic:showAddStepPanel(self)
	end
end

function NationalDayBunnyMode:reachEndCondition()
	return MoveMode.reachEndCondition(self) or self:checkOrderListFinished() or NationalDayBunnyLogic:hasAnyBunnyLeave(self.mainLogic)
end

function NationalDayBunnyMode:reachTarget()
	return self:checkOrderListFinished()
end

function NationalDayBunnyMode:getScoreStarLevel()
	return 1
end

function NationalDayBunnyMode:hasSpecialBonusAnimation()
	if CuckooLogic:hasCuckooBirdReachedEnd() then
		return true
	end
	return false
end

function NationalDayBunnyMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	saveRevertData.bunnyLeaveFlag = mainLogic.bunnyLeaveFlag
	OrderMode.saveDataForRevert(self, saveRevertData)
end

function NationalDayBunnyMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.bunnyLeaveFlag = mainLogic.saveRevertData.bunnyLeaveFlag
	OrderMode.revertDataFromBackProp(self)
end
