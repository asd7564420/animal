LotusMode = class(MoveMode)

function LotusMode:initModeSpecial(config)
	self.mainLogic.currLotusNum = self:checkAllLotusCount()
	self.mainLogic.initLotusNum = self.mainLogic.currLotusNum
end

function LotusMode:reachEndCondition(onlyCheck)
	local lotusNum = self:checkAllLotusCount()
	if not onlyCheck then
		self.mainLogic.currLotusNum = lotusNum
	end
	return  MoveMode.reachEndCondition(self) or lotusNum <= 0
end

function LotusMode:reachTarget()
  return self.mainLogic.currLotusNum <= 0
end

----统计所有的冰
function LotusMode:checkAllLotusCount()
  local mainLogic = self.mainLogic
	local countsum = 0
	for r = 1, #mainLogic.gameItemMap do
		for c = 1, #mainLogic.gameItemMap[r] do
			local board1 = mainLogic.boardmap[r][c]
			if board1.isUsed == true and board1.lotusLevel > 0 then
				countsum = countsum + 1
			end
		end
	end

	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainLogic)
	for r = 1, rowAmount do
		if mainLogic.backBoardMap[r] then
			for c = 1, colAmount do
				local board1 = mainLogic.backBoardMap[r][c]
				if board1 and board1.isUsed == true and board1.lotusLevel > 0 then
					countsum = countsum + 1
				end
			end
		end
	end
	-- MACRO_DEV_START()
	if mainLogic.lotusModify then
		countsum = countsum + mainLogic.lotusModify
	end
	-- MACRO_DEV_END()
	--if _G.isLocalDevelopMode then printx(0, "checkAllIngredientCount", countsum) end
	--debug.debug()
	return countsum;
end

function LotusMode:saveDataForRevert(saveRevertData)
  local mainLogic = self.mainLogic
  saveRevertData.currLotusNum = mainLogic.currLotusNum
  saveRevertData.lotusEliminationNum = mainLogic.lotusEliminationNum
  saveRevertData.lotusPrevStepEliminationNum = mainLogic.lotusPrevStepEliminationNum
  MoveMode.saveDataForRevert(self,saveRevertData)
end

function LotusMode:revertDataFromBackProp()
  local mainLogic = self.mainLogic
  mainLogic.currLotusNum = mainLogic.saveRevertData.currLotusNum
  mainLogic.lotusEliminationNum = mainLogic.saveRevertData.lotusEliminationNum
  mainLogic.lotusPrevStepEliminationNum = mainLogic.saveRevertData.lotusPrevStepEliminationNum
  MoveMode.revertDataFromBackProp(self)
end

function LotusMode:revertUIFromBackProp()
  local mainLogic = self.mainLogic
  if mainLogic.PlayUIDelegate then
    mainLogic.PlayUIDelegate:revertTargetNumber(0, 0, mainLogic.currLotusNum)
  end
  MoveMode.revertUIFromBackProp(self)
end