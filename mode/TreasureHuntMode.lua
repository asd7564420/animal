TreasureHuntMode = class(MoveMode)


function TreasureHuntMode:reachEndCondition()
	local endFlag = MoveMode.reachEndCondition(self) or TreasureHuntLogic:treasuresAllFound(self.mainLogic)
  	return endFlag
end

function TreasureHuntMode:reachTarget()
	return TreasureHuntLogic:treasuresAllFound(self.mainLogic)
end

function TreasureHuntMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	saveRevertData.treasuresAllFoundFlag = mainLogic.treasuresAllFoundFlag
	MoveMode.saveDataForRevert(self,saveRevertData)
end

function TreasureHuntMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	mainLogic.treasuresAllFoundFlag = mainLogic.saveRevertData.treasuresAllFoundFlag
	MoveMode.revertDataFromBackProp(self)
end

function TreasureHuntMode:initModeSpecial(config)
	
	self.config = config
	MoveMode.initModeSpecial(self, config)

	local _tileMap = config.tileMap
	  for r = 1, #_tileMap do
	    if self.mainLogic.boardmap[r] == nil then self.mainLogic.boardmap[r] = {} end        --地形
	    for c = 1, #_tileMap[r] do
	      local tileDef = _tileMap[r][c]
	      self.mainLogic.boardmap[r][c]:initLightUp(tileDef)              
	    end
	  end
end

function TreasureHuntMode:revertUIFromBackProp()
	local mainLogic = self.mainLogic
	if mainLogic.treasuresAllFoundFlag then
        if mainLogic.PlayUIDelegate then
            mainLogic.PlayUIDelegate:revertTargetNumber(0, 0, 0)
        end
    end
    MoveMode.revertUIFromBackProp(self)
end
