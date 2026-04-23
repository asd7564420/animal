LowActiveAdjustLogic = {}


local localFileKey = "LAALogicLD_2.ds"

function LowActiveAdjustLogic:getLocalData()
	return self.localData
end

function LowActiveAdjustLogic:createNewLocalData()
	local nowtime = Localhost:timeInSec()

	local localData = {}
	localData.enableAdjust = false
	localData.adjustIndex = 0
	localData.enabledTime = nowtime
	localData.enabledTopLevelId = 0
	localData.fixedV = 1

	localData.lastLaunchHasPlayLevel = false  --上次启用游戏的周期内，有没有打关（上次登陆是否算作有效登陆）
	

	localData.daymap = {}

	return localData
end

--游戏启动时回调
function LowActiveAdjustLogic:onGameLaunch( context )

	local nowtime = Localhost:timeInSec()

	local active30Days = UserManager:getInstance().active30Days or 30

	local localData = LocalBox:getData( "localData" , localFileKey )

	if not localData then
		localData = self:createNewLocalData()
		LocalBox:setData( "localData" , localData , localFileKey )
	end

	self.localData = localData
	-- printx( 1 , "LowActiveAdjustLogic:onGameLaunch  localData = " , table.tostring(localData) , "active30Days = " , active30Days )

	if self.localData.enableAdjust then

		if active30Days > 20 * self.localData.fixedV then
			--不再处于低活越状态，重置
			self.localData = self:createNewLocalData()
			LocalBox:setData( "localData" , self.localData , localFileKey )
		elseif nowtime - self.localData.enabledTime > 3600 * 24 * 7 then
			--已经激活超过7天，重置
			self.localData = self:createNewLocalData()
			LocalBox:setData( "localData" , self.localData , localFileKey )
		end
	end

	if not self.localData.enableAdjust then
		--尝试判断是否激活

		local userCreateTime = nowtime

		if UserManager:getInstance().mark and UserManager:getInstance().mark.createTime then
			userCreateTime = math.floor( tonumber( UserManager:getInstance().mark.createTime ) / 1000 )
		end

		local fixedV = 1
		local createDays = 0

		if nowtime - userCreateTime < 3600 * 24 * 28 then
			createDays = math.ceil( (nowtime - userCreateTime) / (3600 * 24) )
			fixedV = createDays / 28
			if fixedV > 1 then fixedV = 1 end
		end
		
		if createDays ~= 1 and active30Days <= 20 * fixedV then

			--激活一轮低活干预

			self.localData.enableAdjust = true
			self.localData.adjustIndex = 1
			self.localData.enabledTime = nowtime
			self.localData.enabledTopLevelId = UserManager:getInstance().user:getTopLevelId()

			self.localData.lastLaunchHasPlayLevel = false
			self.localData.fixedV = fixedV


			LocalBox:setData( "localData" , self.localData , localFileKey )
		end

	end

	if self.localData.adjustIndex > 0 and self.localData.adjustIndex <= 6 then

		if self.localData.enableAdjust and self.localData.lastLaunchHasPlayLevel then
			self.localData.adjustIndex = self.localData.adjustIndex + 1
		end

		self.localData.enabledTopLevelId = UserManager:getInstance().user:getTopLevelId()

		self.localData.lastLaunchHasPlayLevel = false
		LocalBox:setData( "localData" , self.localData , localFileKey )

	end
	
end

--启动关卡时回调
function LowActiveAdjustLogic:onStartLevel( context )

	if not self.localData then
		return --unittest not need setData
	end

	if not self.localData.lastLaunchHasPlayLevel and self.localData.adjustIndex <= 6 then
		self.localData.lastLaunchHasPlayLevel = true
		LocalBox:setData( "localData" , self.localData , localFileKey )
	end

end

function LowActiveAdjustLogic:checkEnableAdjust( context )

	local lowActiveAdjustExpGroup = context.userGroupInfo.lowActiveAdjustExpGroup

	if lowActiveAdjustExpGroup == 0 then
		--对照组不激活
		return nil
	end

	if context.levelId ~= context.topLevel then
		--非topLevel关，不激活
		return nil
	end

	if not ( context.isMainLevel and context.levelId <= context.maxLevelId - 60 ) then
		--非主线关，顶部60以内关 不激活
		return nil
	end

	if context.isPayUser then
		--付费用户不激活
		return nil
	end

	local lowActiveAdjustData = context.lowActiveAdjustData

	if not lowActiveAdjustData then
		--旧版本
		return nil
	end

	if not lowActiveAdjustData.enableAdjust then
		--未激活
		return nil
	end

	local nowtime = Localhost:timeInSec()
	local adjustIndex = lowActiveAdjustData.adjustIndex --第几次有效登陆
	local diffTag = context.diffTag
	local topLevelDiffTagValue = UserTagValueMap[UserTagNameKeyFullMap.kTopLevelDiff]

	local function tryAdjust( ds , topLevelLength )

		if context.topLevel < lowActiveAdjustData.enabledTopLevelId + topLevelLength then
------
			local fixedDs = ds
			if diffTag >= topLevelDiffTagValue.kHighDiff3 and diffTag <= topLevelDiffTagValue.kHighDiff5 then
				fixedDs = diffTag
			end

			local resultData = { 
									levelId = context.levelId ,
									mode = ProductItemDiffChangeMode.kAddColor , 
									ds = fixedDs , 
									reason = "lowActiveAdjustExp2_" .. tostring(lowActiveAdjustExpGroup) .. "_" .. tostring(adjustIndex) .. "_" .. tostring(diffTag)
								}
			return resultData

		end

		return nil
	end

	if lowActiveAdjustExpGroup == 1 then

		if adjustIndex == 1 then
			return tryAdjust( 5 , 10 )
		elseif adjustIndex == 2 then
			return tryAdjust( 4 , 10 )
		elseif adjustIndex == 3 then
			return tryAdjust( 3 , 10 )
		elseif adjustIndex == 4 then
			return tryAdjust( 6 , 10 )
		elseif adjustIndex == 5 then
			return tryAdjust( 2 , 10 )
		end

	elseif lowActiveAdjustExpGroup == 2 then

		if adjustIndex == 1 then
			return tryAdjust( 5 , 20 )
		elseif adjustIndex == 2 then
			return tryAdjust( 4 , 20 )
		elseif adjustIndex == 3 then
			return tryAdjust( 3 , 20 )
		elseif adjustIndex == 4 then
			return tryAdjust( 6 , 20 )
		elseif adjustIndex == 5 then
			return tryAdjust( 2 , 20 )
		end

	end

	return nil
end
