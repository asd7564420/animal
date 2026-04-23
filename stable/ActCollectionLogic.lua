
ActCollectionLogic = {}

function ActCollectionLogic:init(mainLogic)
	self.mainLogic = mainLogic
    -- print("ActCollectionLogic:init()",self.mainLogic,mainLogic,mainLogic.level)

	self.curMoveNum = 0 			--两次触发之间移动的步数
	self.genCollectMoveLimit = 0    --移动多少步触发
	self.genCollectLimit = 0 		--当关可生成上限
	self.genCollectNum = 0 			--当关已生成数量

	self.chestPosX = nil
	self.chestPosY = nil
	self.chest = nil

    self.CollectInGameTargetPanel = nil
    self.CollectInGameTargetPanelType = 0

    self.collectItemPath = "item_act_collection.png"

	self.isEffectLevel,self.genCollectMoveLimit, self.genCollectLimit = self:checkIsEffetLevel()
    self.genCollectMoveLimit = self.genCollectMoveLimit or 0
    self.genCollectLimit = self.genCollectLimit or 0
    -- print("ActCollectionLogic:checkIsEffetLevel()self.isEffectLevel,self.genCollectMoveLimit, self.genCollectLimit",self.isEffectLevel,self.genCollectMoveLimit, self.genCollectLimit)
-- 
	if self.isEffectLevel then 
		FrameLoader:loadArmature('tempFunctionRes/CountdownParty/skeleton/countdown_party_chest', 'countdown_party_chest', 'countdown_party_chest')
		local isQATest = false
		if isQATest then 
			self.genCollectMoveLimit = 2
			self.genCollectLimit = 999
		end
		if self.genCollectMoveLimit <= 0 or self.genCollectLimit <= 0 then 
			self.isEffectLevel = false
		end
	end
end

function ActCollectionLogic:getDataForRevert()
	local actCollectionRevertData = {}

	actCollectionRevertData.curMoveNum = self.curMoveNum
	actCollectionRevertData.genCollectNum = self.genCollectNum

	return actCollectionRevertData
end

function ActCollectionLogic:setByRevertData(actCollectionRevertData)
	if actCollectionRevertData then
		self.curMoveNum = actCollectionRevertData.curMoveNum or 0
		self.genCollectNum = actCollectionRevertData.genCollectNum or 0
	end
end

function ActCollectionLogic:checkIsEffetLevel()
	if not self.mainLogic then 
		return false
	end
    local level = self.mainLogic.level
    if ( not CloverRaceManager.getInstance():shouldShowActCollection(level) or not CloverRaceManager.getInstance():getCurLevelIsActCollect() ) 
        then
		return false 
	end

    local genCollectMoveLimit, genCollectLimit = 0,0
	if CloverRaceManager.getInstance():shouldShowActCollection(level) or CloverRaceManager.getInstance():getCurLevelIsActCollect() then
		self.collectItemPath = "item_act_collection.png"
		if CloverRaceManager.getInstance():isSpring20() then
			self.collectItemPath = "item_act_collection_corn.png"
		end
        genCollectMoveLimit, genCollectLimit = CloverRaceManager.getInstance():getCollectConfig(level)
	end

	return true, genCollectMoveLimit, genCollectLimit
end

function ActCollectionLogic:isActEffectedLevel()
	return self.isEffectLevel
end

function ActCollectionLogic:addUseMove()
	self.curMoveNum = self.curMoveNum + 1
end

function ActCollectionLogic:resetUseMove()
	self.curMoveNum = 0
end

function ActCollectionLogic:checkGenLimit()
	if self.genCollectNum >= self.genCollectLimit then 
		return false 
	end

	if self.curMoveNum < self.genCollectMoveLimit then 
		return false
	end

	return true
end

function ActCollectionLogic:handleTurn(callback,bBonsTimeTurn)
	if bBonsTimeTurn == nil then bBonsTimeTurn = false end

	local mainLogic = self.mainLogic
    local gameItemData = mainLogic.gameItemMap
    local gameBoardData = mainLogic.boardmap

    local priTable = {}
    priTable[1] = {} 		--普通小动物
    priTable[2] = {}		--小动物特效
    priTable[3] = {}		--水晶球
    priTable[4] = {} 		--含羞草_普通小动物
    priTable[5] = {}		--含羞草_小动物特效
    priTable[6] = {}		--含羞草_水晶球
    priTable[7] = {} 		--牢笼_普通小动物
    priTable[8] = {}		--牢笼_小动物特效
    priTable[9] = {}		--牢笼_水晶球

    local priMax = 9
    local function insertTargets(priority, info)
    	if priority <= priMax then 
    		table.insert(priTable[priority], info)
    		priMax = priority
    	end
    end

    for r = 1, #gameItemData do 
        for c = 1, #gameItemData[r] do
        	local data = gameItemData[r][c]
        	if not data.hasActCollection then 
	        	if data.ItemType == GameItemType.kAnimal and AnimalTypeConfig.isColorTypeValid(data._encrypt.ItemColorType) and data._encrypt.ItemColorType ~= AnimalTypeConfig.kDrip then
	        		local posInfo = {}
	        		posInfo.r = r
	        		posInfo.c = c
	        		if AnimalTypeConfig.isSpecialTypeValid(data.ItemSpecialType) and data.ItemSpecialType ~= AnimalTypeConfig.kColor then 
		        		if data.beEffectByMimosa > 0 then 
		        			insertTargets(5, posInfo)
		        		elseif data.cageLevel > 0 then 
		        			insertTargets(8, posInfo)
	        			elseif data:isAvailable() and not data:hasLock() and not data:hasAnyFurball() then 
	        				insertTargets(2, posInfo)
		        		end
	        		else
	        			if data.beEffectByMimosa > 0 then 
	        				insertTargets(4, posInfo)
	        			elseif data.cageLevel > 0 then 
	        				insertTargets(7, posInfo)
	        			elseif data:isAvailable() and not data:hasLock() and not data:hasAnyFurball() then 
	        				insertTargets(1, posInfo)
	        			end
	        		end
	        	elseif data.ItemType == GameItemType.kCrystal then 
	        		local posInfo = {}
	        		posInfo.r = r
	        		posInfo.c = c
        			if data.beEffectByMimosa > 0 then 
        				insertTargets(6, posInfo)
        			elseif data.cageLevel > 0 then 
        				insertTargets(9, posInfo)
        			elseif data:isAvailable() and not data:hasLock() and not data:hasAnyFurball() then 
        				insertTargets(3, posInfo)
	        		end
	        	end
	        end
        end
    end
    local targetNum = #priTable[priMax]
    if targetNum > 0 then 
    	local targets = {}
    	table.insert(targets, priTable[priMax][mainLogic.actCollectRandFactory:rand(1, targetNum)])
	    local action = GameBoardActionDataSet:createAs(
				GameActionTargetType.kGameItemAction,
				GameItemActionType.kAct_Collection_Turn,
				nil,
				nil,				
				GamePlayConfig_MaxAction_time)	
	    action.turnTargets = targets 
	    action.bBonsTimeTurn = bBonsTimeTurn
	    self.genCollectNum = self.genCollectNum + 1
	   	-- action.turnTargets = {{r = 7, c = 7}} --test
		if callback then 
			action.completeCallback = function () callback() end
		end

		self.mainLogic:addGlobalCoreAction(action)
		return true,targets
	end

	return false
end

function ActCollectionLogic:handleTurnByPos(callback,bBonsTimeTurn,Pos)
	if bBonsTimeTurn == nil then bBonsTimeTurn = false end

	local mainLogic = self.mainLogic
    local gameItemData = mainLogic.gameItemMap
    local gameBoardData = mainLogic.boardmap

    local targets = {}
	table.insert(targets, Pos)
    local action = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kAct_Collection_Turn,
			nil,
			nil,				
			GamePlayConfig_MaxAction_time)	
    action.turnTargets = targets 
    action.bBonsTimeTurn = bBonsTimeTurn
    self.genCollectNum = self.genCollectNum + 1
   	-- action.turnTargets = {{r = 7, c = 7}} --test
	if callback then 
		action.completeCallback = function () callback() end
	end

	self.mainLogic:addGlobalCoreAction(action)
	return true
end

local function getItemPosition(x, y)
	local tempX = (x - 0.5) * GamePlayConfig_Tile_Width
	local tempY = (GamePlayConfig_Max_Item_Y - y - 0.5) * GamePlayConfig_Tile_Width
	return ccp(tempX, tempY)
end

function ActCollectionLogic:playGenFlyAni(parentLayer, x, y, callback)
	local container = CocosObject:create()
	local sp1 = Sprite:createWithSpriteFrameName(self.collectItemPath)
	local sp2 = Sprite:createWithSpriteFrameName(self.collectItemPath)
	sp1:setScale(0)
	sp2:setScale(0)
	container:addChild(sp1)
	container:addChild(sp2)

	local aniTime = 0.4
	local arr = CCArray:create()
	arr:addObject(CCScaleTo:create(aniTime+0.2, 1.5))
	arr:addObject(CCFadeTo:create(aniTime+0.2, 0))
	sp1:runAction(CCSequence:createWithTwoActions(CCSpawn:create(arr), CCCallFunc:create(function ()	
		if sp1 then sp1:removeFromParentAndCleanup(true) end
		if sp2 then sp2:removeFromParentAndCleanup(true) end
		if callback then callback() end
	end)))

	sp2:runAction(CCScaleTo:create(aniTime, 1))

	local posX = x - 0.5 * GamePlayConfig_Tile_Width
	local posY = y - 0.5 * GamePlayConfig_Tile_Width
	container:setPosition(ccp(posX, posY))
	parentLayer:addChild(container)
end

function ActCollectionLogic:initCollectionBars(parent)
	local _data = {
		levelId = self.mainLogic.level,
		collectionBars = {} ,
	}
	
	LocalActCoreModel.getOrCreateInstance():notify(ActInterface.kCPBCreate, _data)
	

    if #_data.collectionBars == 0 then
        return
    end

    local Common_collectProgress = require 'zoo.localActivity.common.Common_collectProgress'
    local collectionContainer = Common_collectProgress:create(_data.collectionBars)
    parent:addChild(collectionContainer)
    self.collectionContainer = collectionContainer
    collectionContainer:initCommonCollectPos()

end

--关卡内的收集条，与上面不同的地方是位置在棋盘右上方，默认是隐藏的
function ActCollectionLogic:initCollectionBars2(parent)
	local _data2 = {
		levelId = self.mainLogic.level,
		collectionBars = {} ,
	}

	LocalActCoreModel.getOrCreateInstance():notify(ActInterface.kCollectProgressTopRightCreate, _data2)

	if #_data2.collectionBars == 0 then
        return
    end

    local Common_collectProgress = require 'zoo.localActivity.common.Common_collectProgress'
    local collectionContainer2 = Common_collectProgress:create(_data2.collectionBars,15)
    parent:addChild(collectionContainer2)
    self.collectionContainer2 = collectionContainer2
    collectionContainer2:initCommonCollectPos(true)
    self.collectionContainer2:setVisible(false)
end

--这里获取到进度条的container
function ActCollectionLogic:getCollectionContainer()
	return self.collectionContainer
end

--这里获取到进度条的container2
function ActCollectionLogic:getCollectionContainer2()
	return self.collectionContainer2
end

--这里获取到单个进度条。进度条内的方法不再做统一封装，获取引用后，自行调用
function ActCollectionLogic:getCollectionBar(barName)
	if not self.collectionContainer then return end
	return self.collectionContainer:getPanelByName(barName)
end

function ActCollectionLogic:getCollectionBar2(barName)
	if not self.collectionContainer2 then return end
	return self.collectionContainer2:getPanelByName(barName)
end

function ActCollectionLogic:refreshProgressBarPosition()
	if self.collectionContainer then
		self.collectionContainer:refreshProgressBarPosition()
	end
end

function ActCollectionLogic:refreshProgressBar2Position()
	if self.collectionContainer2 then
		self.collectionContainer2:refreshProgressBarPosition()
	end
end