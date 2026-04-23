-- 庄聚贤在我写这段代码的时候无缘无故踢了我一脚 素质极低

WaterBucketLogic = {}

WaterBucketLogic.BucketStatus = {
	kWaiting = 1,  --还没轮到给他充能
	kCharging = 2, --正在充能
	kFullVitality = 3,  --元气满满 准备爆发
}

function WaterBucketLogic:checkHammerHit( main, gameItemData )
	-- body	
	if WaterBucketLogic:hasBucket(gameItemData) and WaterBucketLogic:hasBucketLocked(gameItemData) then
		WaterBucketLogic:chargeBucketItem(main, gameItemData, gameItemData.y, gameItemData.x, 3)
	elseif WaterBucketLogic:canAttackBucket(gameItemData) then
		-- WaterBucketLogic:attackBucket(main, gameItemData.y, gameItemData.x)
	end
end

function WaterBucketLogic:attackWater(mainLogic, r, c, damage) 

	local item = mainLogic.gameItemMap[r][c]

	local damage = damage or 1

	if WaterBucketLogic:canAttackWater(item) then

		item.waterLevel = item.waterLevel - damage
		item.waterLevel = math.max(0, item.waterLevel)

		if item.waterLevel <= 0 then
			item:AddItemStatus(GameItemStatusType.kDestroy)
		end

		local attackWaterAction = GameBoardActionDataSet:createAs(
			GameActionTargetType.kGameItemAction,
			GameItemActionType.kItem_Water_Attack,
			IntCoord:create(r, c),				
			nil,				
			GamePlayConfig_MaxAction_time)
		attackWaterAction.addInt = item.waterLevel
		mainLogic:addDestroyAction(attackWaterAction)
	end

end

function WaterBucketLogic:canAttackWater( gameItemData )
	return gameItemData and gameItemData.waterLevel and gameItemData.waterLevel > 0
end

function WaterBucketLogic:getBucketMaximumCharge( gameItemData )
	return gameItemData.waterBucketMaximumCharge or 9999999
end

function WaterBucketLogic:hasBucket( gameItemData )
	return gameItemData and gameItemData.waterBucketGroupId and gameItemData.waterBucketGroupId > 0
end

-- 没充满能，处于无敌状态
function WaterBucketLogic:hasBucketLocked( gameItemData, careAboutChargingCache )
	if not WaterBucketLogic:hasBucket(gameItemData) then
		return false
	end

	local cur = WaterBucketLogic:getBucketCurCharge(gameItemData, careAboutChargingCache)
	local maximum = WaterBucketLogic:getBucketMaximumCharge(gameItemData)

	return maximum > cur
end

function WaterBucketLogic:getBucketCurCharge(gameItemData, careAboutChargingCache )
	local cur = gameItemData.waterBucketCharge 
	if careAboutChargingCache then
		cur = cur + gameItemData.waterBucketChargingCache
	end
	return cur
end

function WaterBucketLogic:getCurWaterBucketList( mainLogic, onlyTopSide )



	local result = {}

	local function handle( gameItemMap )

		for r = 1, #gameItemMap do
			for c = 1, #gameItemMap[r] do
				local item = gameItemMap[r][c]
				if WaterBucketLogic:hasBucket(item) then
					table.insert(result, item)
				end			
			end
		end	
	end

	
	local function handleDigItemMap( gameItemMap )
		local passedRow = GameBoardLogic:getCurrentLogic().passedRow or 0
		for r = 1, #gameItemMap do
			for c = 1, #gameItemMap[r] do
				local item = gameItemMap[r][c]
				if r > passedRow and WaterBucketLogic:hasBucket(item) then
					table.insert(result, item)
				end			
			end
		end	
	end



	handle(mainLogic.gameItemMap)

	if not onlyTopSide then
		if mainLogic.backItemMap then
			handle(mainLogic.backItemMap)
		end
		if mainLogic.digItemMap then
			handleDigItemMap(mainLogic.digItemMap)
		end
	end
		

	return result

end

function WaterBucketLogic:calcCurChargingGroupId( mainLogic )


	local curWaterBucketList = WaterBucketLogic:getCurWaterBucketList(mainLogic)


	curWaterBucketList = table.filter(curWaterBucketList, function ( v )
		return WaterBucketLogic:hasBucketLocked(v, true)
	end)




	table.sort(curWaterBucketList, function ( a, b )
		return a.waterBucketGroupId < b.waterBucketGroupId
	end)

	if #curWaterBucketList > 0 then
		local curChargingGroupId = curWaterBucketList[1].waterBucketGroupId
		return curChargingGroupId
	else
		return 0
	end
end



function WaterBucketLogic:getBucketStatus( mainLogic, gameItemData )

	if __WIN32 then
		assert( WaterBucketLogic:hasBucket(gameItemData), 'WaterBucketLogic:getBucketStatus( gameItemData )' )
	end

	if not WaterBucketLogic:hasBucketLocked(gameItemData) then
		return WaterBucketLogic.BucketStatus.kFullVitality, WaterBucketLogic:getBucketMaximumCharge(gameItemData), WaterBucketLogic:getBucketMaximumCharge(gameItemData)
	end

	local curChargingGroupId = mainLogic.curWaterBucketChargingGroupId
	if curChargingGroupId == gameItemData.waterBucketGroupId or (gameItemData.waterBucketGroupId ~= 0 and (gameItemData.waterBucketGroupId < curChargingGroupId or curChargingGroupId == 0)) then
		local cur = WaterBucketLogic:getBucketCurCharge(gameItemData)
		local maximum = WaterBucketLogic:getBucketMaximumCharge(gameItemData)

		return WaterBucketLogic.BucketStatus.kCharging, cur, maximum
	else
		return WaterBucketLogic.BucketStatus.kWaiting, 0, WaterBucketLogic:getBucketMaximumCharge(gameItemData)
	end

end

function WaterBucketLogic:chargeBucketItem( mainLogic, toChargeItem, r, c , chargeNum)
	-- body

	-- printx(61, 'chargeBucketItem', toChargeItem.x, toChargeItem.y)

	chargeNum = chargeNum or 1


	local chargeBucketAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_WaterBucket_Charge,
		IntCoord:create(r, c),				
		IntCoord:create(toChargeItem.y, toChargeItem.x),		
		GamePlayConfig_MaxAction_time)
	chargeBucketAction.addInt = chargeNum

	mainLogic:addDestroyAction(chargeBucketAction)

	toChargeItem.waterBucketChargingCache = toChargeItem.waterBucketChargingCache + chargeNum

	if not WaterBucketLogic:hasBucketLocked(toChargeItem, true) then
		local prevValue = mainLogic.curWaterBucketChargingGroupId
		mainLogic.curWaterBucketChargingGroupId = WaterBucketLogic:calcCurChargingGroupId(mainLogic)
		-- printx(61, 'mainLogic.curWaterBucketChargingGroupId', mainLogic.curWaterBucketChargingGroupId)
		if prevValue ~= mainLogic.curWaterBucketChargingGroupId then


			local nextGroupBucketList = WaterBucketLogic:getCurWaterBucketList(mainLogic, true)
			nextGroupBucketList = table.filter(nextGroupBucketList, function ( v )
				return v.waterBucketGroupId == mainLogic.curWaterBucketChargingGroupId
			end)

			for _, v in ipairs(nextGroupBucketList) do
				local readyBucketAction = GameBoardActionDataSet:createAs(
					GameActionTargetType.kGameItemAction,
					GameItemActionType.kItem_WaterBucket_Ready,
					IntCoord:create(v.y, v.x),				
					nil,		
					GamePlayConfig_MaxAction_time)
				mainLogic:addDestroyAction(readyBucketAction)
			end
		end
	end
end

function WaterBucketLogic:chargeBucket(mainLogic, r, c)

	-- printx(61, 'chargeBucket', r, c)

	local bucketList = WaterBucketLogic:getCurWaterBucketList(mainLogic, true)
	bucketList = table.filter(bucketList, function ( v )
		return WaterBucketLogic:canChargeBucket(mainLogic, v)
	end)


	if #bucketList > 0 then
		for _, toChargeItem in ipairs(bucketList) do
			WaterBucketLogic:chargeBucketItem(mainLogic, toChargeItem, r, c)
		end
	end
end

function WaterBucketLogic:canChargeBucket( mainLogic, gameItemData )
	-- body
	return WaterBucketLogic:hasBucket(gameItemData)
		and WaterBucketLogic:hasBucketLocked(gameItemData)
		and gameItemData.waterBucketGroupId == mainLogic.curWaterBucketChargingGroupId
		and (not gameItemData.isReverseSide)
end

function WaterBucketLogic:doChargeBucket(mainLogic, gameItemData, delta )
		-- body

	gameItemData.waterBucketCharge = gameItemData.waterBucketCharge + delta
	gameItemData.waterBucketChargingCache = gameItemData.waterBucketChargingCache - delta
	gameItemData.waterBucketChargingCache = math.max(gameItemData.waterBucketChargingCache, 0)

	gameItemData.waterBucketCharge = math.min(gameItemData.waterBucketCharge, gameItemData.waterBucketMaximumCharge)

end

function WaterBucketLogic:canAttackBucket( gameItemData )
	return WaterBucketLogic:hasBucket(gameItemData) and (not WaterBucketLogic:hasBucketLocked(gameItemData)) and (not gameItemData.isReverseSide) and (not gameItemData.waterBucketDestroying)
end

function WaterBucketLogic:attackBucket( mainLogic, r, c )

	local attackWaterAction = GameBoardActionDataSet:createAs(
		GameActionTargetType.kGameItemAction,
		GameItemActionType.kItem_WaterBucket_Attack,
		IntCoord:create(r, c),				
		nil,				
		GamePlayConfig_MaxAction_time)
	mainLogic:addDestroyAction(attackWaterAction)
	mainLogic.gameItemMap[r][c].waterBucketDestroying = true

end

function WaterBucketLogic:cleanWaterBucket( gameItemData )
	gameItemData.waterBucketGroupId = 0
	gameItemData.waterBucketDestroying = false
	
end