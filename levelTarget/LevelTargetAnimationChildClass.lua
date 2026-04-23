require "zoo.gamePlay.levelTarget.LevelTargetAnimationOrder"
-----------------------------------------
--class LevelTargetAnimationOtherMode
-----------------------------------------

LevelTargetAnimationOtherMode = class(LevelTargetAnimationOrder)
function LevelTargetAnimationOtherMode:getTargetTypeBySelectItem(selectedItem)
	-- body
	return selectedItem.type
end
------------------------------------
--class LevelTargetAnimationDrop
------------------------------------
LevelTargetAnimationDrop = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationDrop:getIconFullName( itemType, id )
	-- body
	local mainLogic = GameBoardLogic:getCurrentLogic()
	if mainLogic and mainLogic.level and LevelType:isCoconutLevel(mainLogic.level) then
		if PlatformConfig:isPlatform(PlatformNameEnum.kMI) then
			return "target."..itemType.."_mi_mi"
		elseif PlatformConfig:isPlatform(PlatformNameEnum.kHuaWei) then
			return "target."..itemType.."_hw_carrot"
		else
			return "target."..itemType.."_nm_coconut"
		end
	else
		return "target."..itemType
	end
end

function LevelTargetAnimationDrop:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	self.c1:setTargetNumber(itemId, itemNum, animate, globalPosition)
end

function LevelTargetAnimationDrop:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	self.c1:revertTargetNumber(itemId, itemNum)
end

------------------------------------
--class LevelTargetAnimationIce
------------------------------------
LevelTargetAnimationIce = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationIce:getIconFullName( itemType, id )
	-- body
	return "target."..itemType
end

------------------------------------
--class LevelTargetAnimationSeaOrder
------------------------------------
LevelTargetAnimationSeaOrder = class(LevelTargetAnimationOrder)

function LevelTargetAnimationSeaOrder:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)


--    local mainLogic = GameBoardLogic:getCurrentLogic()
--    local bisSummerType = false
--	if mainLogic  then
--        local levelType = LevelType:getLevelTypeByLevelId( mainLogic.level )
--        if levelType == GameLevelType.kSummerFish then
--            bisSummerType = true
--		end
--	end

--    if bisSummerType then
--	    local targetIconNode = self.levelTarget and self.levelTarget:getChildByName("c1")
--	    if targetIconNode then
--		    local replaceBg = targetIconNode:getChildByName("bg")
--		    local newBg = Sprite:createWithSpriteFrameName("SummerFish_targetbg.png")
--		    newBg.name = "bg"
--		    newBg:setPosition(ccp(3, -5+44/0.7))
--		    local zIndex = replaceBg:getZOrder()
--		    replaceBg:removeFromParentAndCleanup(true)
--		    targetIconNode:addChildAt(newBg, zIndex)
--	    end
--    end
end

function LevelTargetAnimationSeaOrder:playLeafAnimation()
end

function LevelTargetAnimationSeaOrder:initGameModeTargets( ... )
	--[[
	local function isChristmasBellItem( i )
		if _G.IS_PLAY_YUANXIAO2017_LEVEL and self.targets[i] then
			local itemType,id = self.targets[i].type,self.targets[i].id
			if itemType == "order4" and id == 2 then
				return true
			end
		end
		return false
	end

	for i=1, 4 do
		if isChristmasBellItem(i) then
  			self["c"..i] = TargetItemFactory.create(ChristmasBellTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
		else
  			self["c"..i] = TargetItemFactory.create(SeaOrderTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  		end
  	end
  	]]
	
	for i=1, 4 do
  		self["c"..i] = TargetItemFactory.create(SeaOrderTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  	end

  	self:updateTargets()
end

------------------------------------------------
--class LevelTargetAnimationDigMoveEndless
------------------------------------------------
LevelTargetAnimationDigMoveEndless = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationDigMoveEndless:getIconFullName( itemType, id )
	-- body
	return "target."..itemType
end

function LevelTargetAnimationDigMoveEndless:initGameModeTargets( ... )
	-- body
	self:createTargets(2,4) 
    self.c1 = TargetItemFactory.create(EndlessTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
    self:updateTargets()
end

function LevelTargetAnimationDigMoveEndless:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	self.c1:setTargetNumber(itemId, itemNum, animate, globalPosition)
end

function LevelTargetAnimationDigMoveEndless:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	self.c1:revertTargetNumber(itemId, itemNum)
end

------------------------------------------------
--class LevelTargetAnimationDigMoveEndlessQixi
------------------------------------------------
LevelTargetAnimationDigMoveEndlessQixi = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationDigMoveEndlessQixi:getIconFullName( itemType, id )
	-- body
	return "target."..itemType
end

------------------------------------------------
--class LevelTargetAnimationDigMove
------------------------------------------------
LevelTargetAnimationDigMove = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationDigMove:getIconFullName( itemType, id )
	-- body
	return "target."..itemType
end

function LevelTargetAnimationDigMove:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	self.c1:setTargetNumber(itemId, itemNum, animate, globalPosition)
end

function LevelTargetAnimationDigMove:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	self.c1:revertTargetNumber(itemId, itemNum)
end

------------------------------------------------
--class LevelTargetAnimationMoleWeekly
------------------------------------------------
LevelTargetAnimationMoleWeekly = class(LevelTargetAnimationOtherMode)

function LevelTargetAnimationMoleWeekly:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
	local targetIconNode = self.levelTarget and self.levelTarget:getChildByName("c1")
	if targetIconNode then
		local replaceBg = targetIconNode:getChildByName("bg")
		local newBg = Sprite:createWithSpriteFrameName("MoleWeekly_targetbg.png")
		newBg.name = "bg"
		newBg:setPosition(ccp(3, -5))
		local zIndex = replaceBg:getZOrder()
		replaceBg:removeFromParentAndCleanup(true)
		targetIconNode:addChildAt(newBg, zIndex)
	end
end

function LevelTargetAnimationMoleWeekly:playLeafAnimation()
end

function LevelTargetAnimationMoleWeekly:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	self.c1:setTargetNumber(itemNum, animate, globalPosition)
end

function LevelTargetAnimationMoleWeekly:revertTargetNumber( itemType, itemId, itemNum )
	self.c1:revertTargetNumber(itemNum)
end

function LevelTargetAnimationMoleWeekly:initGameModeTargets( ... )
	-- body
	self:createTargets(2,4)  
    self.c1 = TargetItemFactory.create(MoleWeeklyTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
    self:updateTargets()
    self.c1:initMaxTargetValue()
end

function LevelTargetAnimationMoleWeekly:getIconFrameName(itemType, id, fname)
	if 1 == id then
		return "target.moleweek instance 10000"
	end
	return LevelTargetAnimationOrder.getIconFrameName(self, itemType, id, fname)
end

function LevelTargetAnimationMoleWeekly:getTargetTypeByTargets()
	return kLevelTargetType.moleWeekly
end






LevelTargetAnimationMoleWeekly2020 = class(LevelTargetAnimationOtherMode)

function LevelTargetAnimationMoleWeekly2020:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
	local targetIconNode = self.levelTarget and self.levelTarget:getChildByName("c1")
	if targetIconNode then
		local replaceBg = targetIconNode:getChildByName("bg")
		local newBg = UIHelper:createSpriteFrame("flash/WeeklyRace2020/ingame_ui.json", "weekly_race_2020_ingame.ui/target_icon_bg0000")
		newBg.name = "bg"
		newBg:setPosition(ccp(0, -88))
		local zIndex = replaceBg:getZOrder()
		replaceBg:removeFromParentAndCleanup(true)
		targetIconNode:addChildAt(newBg, zIndex)
	end
end


function LevelTargetAnimationMoleWeekly2020:createIcon( itemType, id, width, height , fname)
	local layer = LevelTargetAnimationOtherMode.createIcon(self, itemType, id, width, height , fname)
	layer:getChildByName('content'):setAnchorPointCenterWhileStayOrigianlPosition()
	layer:getChildByName('content'):setScale(0.6)
	return layer
end


function LevelTargetAnimationMoleWeekly2020:getIconFullName( itemType, id )
	return "target."..itemType
end


function LevelTargetAnimationMoleWeekly2020:playLeafAnimation()
end

function LevelTargetAnimationMoleWeekly2020:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	self.c1:setTargetNumber(itemNum, animate, globalPosition)
end

function LevelTargetAnimationMoleWeekly2020:revertTargetNumber( itemType, itemId, itemNum )
	self.c1:revertTargetNumber(itemNum)
end

function LevelTargetAnimationMoleWeekly2020:initGameModeTargets( ... )
	self:createTargets(2,4)  
	require 'zoo.panel.component.levelTarget.MoleWeekly2020TargetItem'
    self.c1 = TargetItemFactory.create(MoleWeekly2020TargetItem, self.levelTarget:getChildByName("c1"), 1, self)
    self:updateTargets()
    self.c1:initMaxTargetValue()
end

function LevelTargetAnimationMoleWeekly2020:getIconFrameName(itemType, id, fname)
	return LevelTargetAnimationOrder.getIconFrameName(self, itemType, id, fname)
end

function LevelTargetAnimationMoleWeekly2020:getTargetTypeByTargets()
	return kLevelTargetType.weeklyRace2020
end

function LevelTargetAnimationMoleWeekly2020:getTargetIcon()
	if self.c1 then
		local targetIcon = self.c1.icon
		if targetIcon and not targetIcon.isDisposed then
			return targetIcon
		end
	end
	return nil
end



LevelTargetAnimationWukongEndless = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationWukongEndless:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	if itemId == 2 then
		self.c2:setTargetNumber(itemId, itemNum, animate, globalPosition)
	else
		self.c1:setTargetNumber(itemId, itemNum, animate, globalPosition)
	end
end

function LevelTargetAnimationWukongEndless:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	if itemId == 0 then
		self.c1:revertTargetNumber( itemId, itemNum)
	elseif itemId == 2 then 
		self.c2:revertTargetNumber(itemId, itemNum)
	end
end

function LevelTargetAnimationWukongEndless:initGameModeTargets( ... )
	-- body
	self:createTargets(2,4)  
    self.c1 = TargetItemFactory.create(EndlessMayDayTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
    self:updateTargets()
end



------------------------------------------------
--class LevelTargetAnimationHedgehogEndless
------------------------------------------------
LevelTargetAnimationHedgehogEndless = class(LevelTargetAnimationOrder)
function LevelTargetAnimationHedgehogEndless:initGameModeTargets( ... )
	-- body
	self:createTargets(3,4)
    self.c1 = TargetItemFactory.create(FillTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
	self.c2 = TargetItemFactory.create(EndlessTargetItem, self.levelTarget:getChildByName("c2"), 2, self)
	self:updateTargets()
end

function LevelTargetAnimationHedgehogEndless:getTargetTypeBySelectItem( selectedItem )
	-- body
	return kLevelTargetType.hedgehog_endless
end


LevelTargetAnimationLotus = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationLotus:setTargetNumber( itemType, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	if globalPosition and globalPosition.x == 0 and globalPosition.y == 0 then
		globalPosition = nil
	end
	self.c1:setTargetNumber(itemId, itemNum , animate, globalPosition)
end

function LevelTargetAnimationLotus:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	self.c1:revertTargetNumber( itemId, itemNum)
end

function LevelTargetAnimationLotus:initGameModeTargets( ... )
	-- body
	self:createTargets(1,4)  
    --self.c1 = TargetItemFactory.create(EndlessMayDayTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
    self:updateTargets()
end

local LevelTargetAnimationNoTarget = class(LevelTargetAnimationOtherMode)

function LevelTargetAnimationNoTarget:getTargetTopTexts()
	assert(false)
end

function LevelTargetAnimationNoTarget:initGameModeTargets( ... )
	self:createTargets(1,4)  
	self.numberOfTargets = 0
    self:updateTargets()
end

function LevelTargetAnimationNoTarget:updateTargets( ... )
	LevelTargetAnimationOtherMode.updateTargets(self, ... )

	local itemType = self:getTargetTypeByTargets()
	self.tip_label:setDimensions(CCSizeMake(400, 200))
	self.tip_label:setString(Localization:getInstance():getText(kLevelTargetTypeTexts[itemType], {n="\n"}))
	if not self.tip_label.centerPos then
		local tipPos = self.tip_label:getPosition()
		self.tip_label:setPosition(ccp(tipPos.x+50, tipPos.y - 130))
	end
end

LevelTargetAnimationOlympicEndless = class(LevelTargetAnimationNoTarget)

function LevelTargetAnimationOlympicEndless:getTargetTypeByTargets()
	return kLevelTargetType.olympic_2016
end

function LevelTargetAnimationOlympicEndless:playLeafAnimation()
end

LevelTargetAnimationSpringEndless = class(LevelTargetAnimationNoTarget)

function LevelTargetAnimationSpringEndless:getTargetTypeByTargets()
	return kLevelTargetType.spring_2017
end

LevelTargetAnimationSpring2018 = class(LevelTargetAnimationOrder)
function LevelTargetAnimationSpring2018:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
	local targetIconNode = self.levelTarget and self.levelTarget:getChildByName("c1")
	if targetIconNode then
		local replaceBg = targetIconNode:getChildByName("bg")
		local newBg = Sprite:createWithSpriteFrameName("sp2018_level_target_bg")
		newBg.name = "bg"
		newBg:setPosition(ccp(3, -53))
		local zIndex = replaceBg:getZOrder()
		replaceBg:removeFromParentAndCleanup(true)
		targetIconNode:addChildAt(newBg, zIndex)
	end
end

function LevelTargetAnimationSpring2018:playLeafAnimation()
end

function LevelTargetAnimationSpring2018:getIconFrameName(itemType, id, fname)
	if 2 == id and _G.SPRING2018_COLLECTION_TYPE and _G.SPRING2018_COLLECTION_TYPE > 0 then
		local targetFrameName = {
			"sp2018_target_icon_1",
			"sp2018_target_icon_2",
			"sp2018_target_icon_3",
			"sp2018_target_icon_6",
			"sp2018_target_icon_5",
			"sp2018_target_icon_4",
		}
		return targetFrameName[_G.SPRING2018_COLLECTION_TYPE]
	end
	return LevelTargetAnimationOrder.getIconFrameName(self, itemType, id, fname)
end

function LevelTargetAnimationSpring2018:getTargetTypeByTargets()
	return kLevelTargetType.spring_2018
end


--¹û½´target
------------------------------------------------
--class LevelTargetAnimationJamSperad
------------------------------------------------
LevelTargetAnimationJamSperad = class(LevelTargetAnimationOrder)

function LevelTargetAnimationJamSperad:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)

    for i=1, 4 do
	    local targetIconNode = self.levelTarget and self.levelTarget:getChildByName("c"..i)
	    if targetIconNode then
		    local replaceBg = targetIconNode:getChildByName("bg")
		    local newBg = Sprite:createWithSpriteFrameName("JamSperad_targtbg.png")
		    newBg.name = "bg"
		    newBg:setPosition(ccp(3, -15))
            newBg:setScale(0.8)
		    local zIndex = replaceBg:getZOrder()
		    replaceBg:removeFromParentAndCleanup(true)
		    targetIconNode:addChildAt(newBg, zIndex)
	    end
    end
end

function LevelTargetAnimationJamSperad:playLeafAnimation()
end

function LevelTargetAnimationJamSperad:initGameModeTargets( ... )

    for i=1, 4 do
  		self["c"..i] = TargetItemFactory.create(JamSperadTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  	end

  	self:updateTargets()

	-- body
--	self:createTargets(2,4)  
--    self.c1 = TargetItemFactory.create(JamSperadTargetItem, self.levelTarget:getChildByName("c1"), 1, self)
--    self:updateTargets()
--    self.c1:initMaxTargetValue()
--    self.c1:setTargetNumber()
end

function LevelTargetAnimationJamSperad:getIconFrameName(itemType, id, fname)

    if 'order'..GameItemOrderType.kOthers == itemType and id == GameItemOrderType_Others.kJamSperad then
		return "target.jamsperad instance 10000"
	end
	return LevelTargetAnimationOrder.getIconFrameName(self, itemType, id, fname)
end

function LevelTargetAnimationJamSperad:getTargetTypeByTargets()
	return kLevelTargetType.JamSperad
end

--六周年 收集物
------------------------------------------------
--class LevelTargetAnimationSixYearCls
------------------------------------------------
LevelTargetAnimationSixYearCls = class(LevelTargetAnimationOrder)

function LevelTargetAnimationSixYearCls:playLeafAnimation()
end

function LevelTargetAnimationSixYearCls:initGameModeTargets( ... )
    for i=1, 4 do
  		self["c"..i] = TargetItemFactory.create(SixYearTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  	end

  	self:updateTargets()
end

function LevelTargetAnimationSixYearCls:createIcon( itemType, id, width, height , fname)
	-- body
	local resname = self:getIconFrameName(itemType, id, fname)

	local layer = Sprite:createEmpty()
	layer:setCascadeOpacityEnabled(true)

	local sprite = Sprite:createWithSpriteFrameName(resname)
	local spriteSize = sprite:getContentSize()
	local scaleFactor = 0.6
	sprite.name = "content"
	sprite:setCascadeOpacityEnabled(true)
	sprite:setScale(scaleFactor)
	sprite:setAnchorPoint(ccp(0,0))
	layer.name = "icon"
	layer:addChild(sprite)
	layer:setContentSize(CCSizeMake(spriteSize.width*scaleFactor, spriteSize.height*scaleFactor))

	layer.clone = function( self, copyParentAndPos )
		local old = self:getChildByName("content")
		local cloned = old:clone(false)
		local result = Sprite:createEmpty()
		local size = self:getContentSize()
		result.name = "icon"
		result:setCascadeOpacityEnabled(true)
		
		cloned.name = "content"
		cloned:setCascadeOpacityEnabled(true)
		cloned:setScale(0.5)
		cloned:setAnchorPoint(ccp(0,0))
		result:addChild(cloned)
		result:setContentSize(CCSizeMake(size.width, size.height))
		if copyParentAndPos then
			local position = self:getPosition()
			local parent = self:getParent()
			if parent then
				local grandParent = parent:getParent()
				if grandParent then 
					local position_parent = parent:getPosition()
					result:setPosition(ccp(position.x + position_parent.x, position.y + position_parent.y))
					grandParent:addChild(result)
				end
			end
		end
		return result
	end
	return layer
end

------------------------------------
--class LevelTargetAnimationAngryBird
------------------------------------
LevelTargetAnimationAngryBird = class(LevelTargetAnimationOrder)

function LevelTargetAnimationAngryBird:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
end

function LevelTargetAnimationAngryBird:getIconFrameName(itemType, id, fname)	
	return "target.angryBird_1 instance 10000"
end

function LevelTargetAnimationAngryBird:getTargetTypeByTargets()
	return kLevelTargetType.angryBird
end

function LevelTargetAnimationAngryBird:playLeafAnimation()
end

function LevelTargetAnimationAngryBird:initGameModeTargets( ... )
 	self:createTargets(1,4)  
    self:updateTargets(true)
end

--消除节 按图索骥
-----------------------------------------
--class LevelTargetAnimationTreasureHunt
-----------------------------------------
LevelTargetAnimationTreasureHunt = class(LevelTargetAnimationOrder)

function LevelTargetAnimationTreasureHunt:buildLevelTargets(x, yDelta, noBatch)
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
end

function LevelTargetAnimationTreasureHunt:getIconFullName( itemType, id )
	return "target."..itemType
end

function LevelTargetAnimationTreasureHunt:initGameModeTargets( ... )
	for i=1, 4 do
  		self["c"..i] = TargetItemFactory.create(TreasureHuntTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  	end

  	self:updateTargets()
end

-----------------------------------------
--class LevelTargetAnimationBridgeCross
-----------------------------------------

LevelTargetAnimationBridgeCross = class(LevelTargetAnimationOrder)

function LevelTargetAnimationBridgeCross:buildLevelTargets(x, yDelta, noBatch)
	--printx(15,"LevelTargetAnimationBridgeCross:buildLevelTargets")
	LevelTargetAnimationOrder.buildLevelTargets(self, x, yDelta, true)
end

function LevelTargetAnimationBridgeCross:getIconFullName( itemType, id )
	return "target.walk_chick"
end

function LevelTargetAnimationBridgeCross:initGameModeTargets( ... )
	--printx(15,"LevelTargetAnimationBridgeCross:initGameModeTargets")
	for i=1, 4 do
  		self["c"..i] = TargetItemFactory.create(BridgeCrossTargetItem, self.levelTarget:getChildByName("c"..i), i, self)
  	end

  	self:updateTargets()
end

------------------------------------------------------------------------------
LevelTargetAnimationGoldenPodBattle = class(LevelTargetAnimationOtherMode)
function LevelTargetAnimationGoldenPodBattle:getIconFullName( itemType, id )
	-- return "target."..itemType
	return "target.drop"
end

function LevelTargetAnimationGoldenPodBattle:setTargetNumber(playerID, itemId, itemNum, animate, globalPosition, rotation, percent )
	-- body
	-- printx(11, "============== target panel :setTargetNumber", playerID, itemId, itemNum, percent, debug.traceback())
	if playerID == 1 then
		if self.c1 then
			self.c1:setTargetNumber(itemId, itemNum, animate, globalPosition)
		end
	else
		if self.c2 then
			self.c2:setTargetNumber(itemId, itemNum, animate, globalPosition)
		end
	end
end

function LevelTargetAnimationGoldenPodBattle:revertTargetNumber( itemType, itemId, itemNum )
	-- body
	self.c1:revertTargetNumber(itemId, itemNum)
end

