DestinationMode = class(OrderMode)

function DestinationMode:initModeSpecial(config)
	OrderMode.initModeSpecial(self, config)
end

function DestinationMode:afterFail()
	MoveMode.afterFail(self)
end

function DestinationMode:reachEndCondition()
	return MoveMode.reachEndCondition(self) or self:checkOrderListFinished()
end

function DestinationMode:reachTarget()
	return self:checkOrderListFinished()
end

function DestinationMode:hasSpecialBonusAnimation()
	if CuckooLogic:hasCuckooBirdReachedEnd() then
		return true
	end
	return false
end

function DestinationMode:saveDataForRevert(saveRevertData)
	local mainLogic = self.mainLogic
	-- cuckoo
	saveRevertData.cuckooEnergy = mainLogic.cuckooEnergy
	saveRevertData.skipCuckooStateType = mainLogic.skipCuckooStateType
	saveRevertData.currMapTravelRouteLength = mainLogic.currMapTravelRouteLength
	saveRevertData.currMapTravelStep = mainLogic.currMapTravelStep

	OrderMode.saveDataForRevert(self, saveRevertData)
end

function DestinationMode:revertDataFromBackProp()
	local mainLogic = self.mainLogic
	-- cuckoo
	mainLogic.cuckooEnergy = mainLogic.saveRevertData.cuckooEnergy
	mainLogic.skipCuckooStateType = mainLogic.saveRevertData.skipCuckooStateType
	mainLogic.currMapTravelRouteLength = mainLogic.saveRevertData.currMapTravelRouteLength
	mainLogic.currMapTravelStep = mainLogic.saveRevertData.currMapTravelStep

	OrderMode.revertDataFromBackProp(self)
end

function DestinationMode:getFuuuDatas()
	local mainLogic = self.mainLogic
	if mainLogic and mainLogic.theOrderList then 
		for _,v in ipairs(mainLogic.theOrderList) do
			if v.key1 == GameItemOrderType.kDestination then
				if v.key2 == GameItemOrderType_Destination.kCuckoo then
					return CuckooLogic:getCustomizedFuuuDatas(mainLogic)
				end
			end
		end
	end
	return nil
end
