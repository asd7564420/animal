BridgeCrossMode = class(MoveMode)

function BridgeCrossMode:onGameInit()
	-- self.mainLogic
	BridgeCrossLogic:playWalkChickDebutAnimation(self.mainLogic)
	MoveMode.onGameInit(self)
end

function BridgeCrossMode:reachEndCondition()
	local endFlag = MoveMode.reachEndCondition(self) or BridgeCrossLogic:walkChickReachedDestination(self.mainLogic)
  	return  endFlag
end

function BridgeCrossMode:reachTarget()
	return BridgeCrossLogic:walkChickReachedDestination(self.mainLogic)
end

function BridgeCrossMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	saveRevertData.walkChickReachedEndFlag = mainLogic.walkChickReachedEndFlag
	saveRevertData.walkChickEndPos = table.clone(mainLogic.walkChickEndPos or {})
	MoveMode.saveDataForRevert(self,saveRevertData)
end

function BridgeCrossMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.walkChickReachedEndFlag = mainLogic.saveRevertData.walkChickReachedEndFlag
	mainLogic.walkChickEndPos = mainLogic.saveRevertData.walkChickEndPos
	MoveMode.revertDataFromBackProp(self)
end

function BridgeCrossMode:revertUIFromBackProp()
	local mainLogic = self.mainLogic
	if mainLogic.walkChickReachedEndFlag then
        if mainLogic.PlayUIDelegate then
            mainLogic.PlayUIDelegate:revertTargetNumber(0, 0, 0)
        end
    end
    MoveMode.revertUIFromBackProp(self)
end
