local NewReturnAndLowActiveAdjustLogic = {}

local localFileKey = "NewRLA.ds"
local dataVer = 2
local realStrengthMap = {1,2,6,3,4,5,7}
local debugLog = false

local adjustSeqConfig = {
	[1] = {
		day7 = 0 ,
		day28Min = 0 ,
		day28Max = 0 ,
		seq = {7,7,7,7,5,5,5,5,4,4,4,4} ,
		strength6PassLevelCount = 10 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[2] = {
		day7 = 0 ,
		day28Min = 1 ,
		day28Max = 5 ,
		seq = {7,7,7,7,5,5,5,5,4,4,4,4} ,
		strength6PassLevelCount = 10 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[3] = {
		day7 = 0 ,
		day28Min = 6 ,
		day28Max = 10 ,
		seq = {7,7,7,5,5,4,4} ,
		strength6PassLevelCount = 8 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[4] = {
		day7 = 0 ,
		day28Min = 11 ,
		day28Max = 18 ,
		seq = {7,7,5,5,4,4,4} ,
		strength6PassLevelCount = 5 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[5] = {
		day7 = 0 ,
		day28Min = 19 ,
		day28Max = 21 ,
		seq = {7,5,5,4,4,4} ,
		strength6PassLevelCount = 2 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[6] = {
		day7 = 1 ,
		day28Min = 1 ,
		day28Max = 8 ,
		seq = {7,7,7,5,5,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[7] = {
		day7 = 2 ,
		day28Min = 2 ,
		day28Max = 11 ,
		seq = {7,7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[8] = {
		day7 = 1 ,
		day28Min = 9 ,
		day28Max = 14 ,
		seq = {7,7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[9] = {
		day7 = 3 ,
		day28Min = 3 ,
		day28Max = 8 ,
		seq = {7,7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[10] = {
		day7 = 1 ,
		day28Min = 15 ,
		day28Max = 19 ,
		seq = {7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[11] = {
		day7 = 2 ,
		day28Min = 12 ,
		day28Max = 17 ,
		seq = {7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[12] = {
		day7 = 3 ,
		day28Min = 9 ,
		day28Max = 15 ,
		seq = {7,5,5,4,4,4} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 3 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = -1 ,
	} ,

	[13] = {
		day7 = 4 ,
		day28Min = 4 ,
		day28Max = 12 ,
		seq = {7,5,5,4,4,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[14] = {
		day7 = 2 ,
		day28Min = 18 ,
		day28Max = 20 ,
		seq = {5,5,4,4,4,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[15] = {
		day7 = 3 ,
		day28Min = 16 ,
		day28Max = 21 ,
		seq = {5,5,4,4,4,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[16] = {
		day7 = 4 ,
		day28Min = 13 ,
		day28Max = 19 ,
		seq = {5,5,4,4,4,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[17] = {
		day7 = 1 ,
		day28Min = 20 ,
		day28Max = 22 ,
		seq = {5,5,4,4,3,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[18] = {
		day7 = 5 ,
		day28Min = 5 ,
		day28Max = 16 ,
		seq = {5,5,4,4,3,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 3 ,
	} ,

	[19] = {
		day7 = 2 ,
		day28Min = 21 ,
		day28Max = 23 ,
		seq = {5,4,4,3,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[20] = {
		day7 = 4 ,
		day28Min = 20 ,
		day28Max = 24 ,
		seq = {5,4,4,3,3} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[21] = {
		day7 = 6 ,
		day28Min = 6 ,
		day28Max = 20 ,
		seq = {5,4,3,3,6} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[22] = {
		day7 = 5 ,
		day28Min = 17 ,
		day28Max = 24 ,
		seq = {5,4,3,3,6} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[23] = {
		day7 = 3 ,
		day28Min = 22 ,
		day28Max = 24 ,
		seq = {5,4,3,3,6} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[24] = {
		day7 = 6 ,
		day28Min = 21 ,
		day28Max = 24 ,
		seq = {4,3,3,6} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

	[25] = {
		day7 = 7 ,
		day28Min = 7 ,
		day28Max = 24 ,
		seq = {3,3,6} ,
		strength6PassLevelCount = 0 ,
		fixPointKey1 = 20 ,
		fixPointValue1 = 0 ,
		fixPointKey2 = 10 ,
		fixPointValue2 = 0 ,
	} ,

}


local function getDateInfo( nowtime )
	if not nowtime then nowtime = 0 end
	local date = os.date( "*t" , nowtime )

	local nowDayStr = tostring(date.year) .. "_" .. tostring(date.month) .. "_" .. tostring(date.day)
	--[[
		sec = 47,
	  min = 0,
	  day = 31,
	  isdst = false,
	  wday = 6,
	  yday = 213,
	  year = 2020,
	  month = 7,
	  hour = 16,
	]]

	local todayZeroNight = os.time({year =date.year, month = date.month, day =date.day, hour =0, min =0, sec = 0})
	local todayMidNight = os.time({year =date.year, month = date.month, day =date.day, hour =23, min =59, sec = 59})

	local datas = {
		year = date.year ,
		month = date.month ,
		day = date.day ,
		hour = date.day ,
		hour = date.day ,
		min = date.min ,
		sec = date.sec ,
		weekIdx = date.wday ,
		todayZeroNight = todayZeroNight , --当日凌晨
		todayMidNight = todayMidNight + 1 , --当日午夜（次日凌晨）
		isdst = date.isdst ,
		nowDayStr = nowDayStr
	}
	return datas
end

function NewReturnAndLowActiveAdjustLogic:createNewLocalData()
	local localData = {
		ver = dataVer ,
		activeDays = {} ,
		activeDays7 = 0 ,
		activeDays28 = 0 ,
		currActiveDays7 = 0 ,
		currActiveDays28 = 0 ,
		fuuuAdjustSeq = nil ,
		passLevelNumsUnder6 = 0 ,
		seqIdx = 0 ,
		passLevelNumsToday = 0 ,
		topLevelWhenActived = 0 ,
		currStrength = 0 ,
		passDay = nil ,
		lastDayHasPlayLevel = false ,
		nowDayStr = "" ,
		userCreateTime = 0 ,
		beginTime = 0 ,
	}

	return localData
end

function NewReturnAndLowActiveAdjustLogic:isReturnBackUser()
	local localData = self:getLocalData()

	if localData.seqIdx > 0 and localData.fuuuAdjustSeq and localData.activeDays7 == 0 then
		return true
	end

	return false
end

function NewReturnAndLowActiveAdjustLogic:getLocalData()

	if not self.localData then
		local localData = LocalBox:getData( "localData" , localFileKey )

		if not localData then
			localData = self:createNewLocalData()
			LocalBox:setData( "localData" , localData , localFileKey )
		end

		if (not localData.ver) or (localData.ver < dataVer) then
			localData = self:createNewLocalData()
			LocalBox:setData( "localData" , localData , localFileKey )
		end

		self.localData = localData
	end
	return self.localData
end 

function NewReturnAndLowActiveAdjustLogic:flushLocalData()
	if self.localData then
		LocalBox:setData( "localData" , self.localData , localFileKey )
	end
end


function NewReturnAndLowActiveAdjustLogic:countActivityDays( activeDaysList , nowtime , userCreateTime )

	if not userCreateTime then userCreateTime = 0 end

	if debugLog and not _G.AI_CHECK_ON then printx( 1 , "NewReturnAndLowActiveAdjustLogic:countActivityDays   " , nowtime , userCreateTime ) end
	
	local activeDays7 = 7
	local activeDays28 = 28

	--self.userGroupInfo.newReturnAndLowActiveExpGroup

	if activeDaysList and type(activeDaysList) == "table" then
		
		activeDays7 = 0
		activeDays28 = 0

		for k,v in ipairs(activeDaysList) do
			
			if v then 
				activeDays28 = activeDays28 + 1

				if k <= 7 then
					if v then activeDays7 = activeDays7 + 1 end
				end 
			end
		end

		local nowtimeDay = math.floor( nowtime / (3600 * 24) )
		local userCreateDay = math.floor( userCreateTime / (3600 * 24) )

		if nowtimeDay - userCreateDay >= 7 then
			local createDays = nowtimeDay - userCreateDay

			local fixedV = 1
			if createDays < 28 then
				fixedV =  28 / createDays
			end
			-- activeDays7 = math.floor( activeDays7 * fixedV )
			activeDays28 = math.floor( activeDays28 * fixedV )
		else
			activeDays7 = -1
			activeDays28 = -1
		end

		return activeDays7 , activeDays28
	end
end

function NewReturnAndLowActiveAdjustLogic:getAdjustSeqConfigCopy( day7 , day28 )
	if day7 and day28 and day7 >= 0 and day28 >= 0 then
		for k,v in pairs( adjustSeqConfig ) do
			if day7 == v.day7 then
				if day28 >= v.day28Min and day28 <= v.day28Max then
					return table.clone(v)
				end
			end
		end
	end
	
	return nil
end

function NewReturnAndLowActiveAdjustLogic:getCurrStrength( currConfig )

	if not currConfig then return 0 end
	
	local localData = self:getLocalData()

	local _currStrength = 0

	

	if localData and localData.fuuuAdjustSeq and localData.seqIdx > 0 then


		_currStrength = localData.fuuuAdjustSeq[localData.seqIdx]

		if _currStrength < 7 and localData.passLevelNumsUnder6 < currConfig.strength6PassLevelCount then
			--插入强度6
			table.insert( localData.fuuuAdjustSeq , localData.seqIdx , 7 )
			_currStrength = localData.fuuuAdjustSeq[localData.seqIdx]
		end

		if localData.passLevelNumsToday >= currConfig.fixPointKey1 then
			if currConfig.fixPointValue1 >= 0 then
				_currStrength = currConfig.fixPointValue1
			elseif currConfig.fixPointValue1 < 0 then
				local _currStrengthIdx = table.indexOf( realStrengthMap , _currStrength)
				_currStrengthIdx = _currStrengthIdx + currConfig.fixPointValue1
				if _currStrengthIdx < 1 then
					_currStrength = 0
				else
					_currStrength = realStrengthMap[_currStrengthIdx] or 0
				end
			end
		elseif localData.passLevelNumsToday >= currConfig.fixPointKey2 then
			

			if currConfig.fixPointValue2 >= 0 then
				_currStrength = currConfig.fixPointValue2
			elseif currConfig.fixPointValue2 < 0 then
				local _currStrengthIdx = table.indexOf( realStrengthMap , _currStrength)
				_currStrengthIdx = _currStrengthIdx + currConfig.fixPointValue2
				if _currStrengthIdx < 1 then
					_currStrength = 0
				else
					_currStrength = realStrengthMap[_currStrengthIdx] or 0
				end
			end
		end

		if _currStrength < 0 then _currStrength = 0 end
	end

	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("currConfig", table.serialize(currConfig) ,  "_currStrength" , _currStrength ) end

	return _currStrength
end

--游戏启动时回调
function NewReturnAndLowActiveAdjustLogic:onGameLaunch()

	-- if not _G.AI_CHECK_ON then printx( 1 , "NewReturnAndLowActiveAdjustLogic:onGameLaunch "  ) end

	-- local isPayUser = LevelDifficultyAdjustManager:getDAManager():getIsPayUser()
	local isPayUser = LevelDifficultyAdjustManager:getDAManager():checkIsPayUser()

	local topLevelId = UserManager:getInstance():getUserRef():getTopLevelId()
	local maxLevelId = NewAreaOpenMgr.getInstance():getCanPlayTopLevel()
	local doNotStartNewAdjust = false
	if isPayUser or topLevelId >= maxLevelId - 60 then
		doNotStartNewAdjust = true
	end

	local needPrint = true

	local localData = self:getLocalData()

	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("GameLaunch", "P1  isPayUser" , isPayUser , "maxLevelId" , maxLevelId , "doNotStartNewAdjust" , doNotStartNewAdjust ) end
	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("GameLaunch", "P2   " , table.serialize( localData ) ) end

	local nowtime = Localhost:timeInSec()
	local dateInfo = getDateInfo(nowtime)


	local function startNewAdjust( day7 , day28 , seq )

		localData.beginTime = nowtime
		localData.passDay = 0

		localData.activeDays7 = day7
		localData.activeDays28 = day28
		localData.fuuuAdjustSeq = seq
		localData.seqIdx = 1

		localData.passLevelNumsUnder6 = 0
		localData.passLevelNumsToday = 0
		localData.topLevelWhenActived = UserManager:getInstance():getUserRef():getTopLevelId()
		
		localData.currStrength = localData.fuuuAdjustSeq[localData.seqIdx]

		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("StartNewAdjust", "New Data:   " , table.serialize( localData ) ) end

	end

	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("GameLaunch", "P3   " , localData.nowDayStr , dateInfo.nowDayStr ) end
	if localData.nowDayStr ~= dateInfo.nowDayStr then --日期有变化

		if not localData.activeDays then localData.activeDays = {} end

		local passDay = 0
		if localData.seqIdx > 0 and localData.fuuuAdjustSeq then
			local beginTimeInfo = getDateInfo( localData.beginTime )

			--[RemoteDebug] P5   localData.passDay 0 passDay 0 nowtime 1599235200 localData.beginTime 1599190701 
			--beginTimeInfo.todayMidNight 1599235200
			-- nowtime - localData.beginTime   1599235200-1599190701 = 44499
			-- beginTimeInfo.todayMidNight - localData.beginTime  1599235200-1599190701 = 44499

			if nowtime - localData.beginTime >= beginTimeInfo.todayMidNight - localData.beginTime then
				passDay = 1 + math.floor( (nowtime - beginTimeInfo.todayMidNight) / (24*3600) )
				if debugLog and not _G.AI_CHECK_ON then 
					RemoteDebug:uploadLogWithTag("GameLaunch", "P5.1   passDay:" , passDay  ) 
				end
			end

			if debugLog and not _G.AI_CHECK_ON then 
				RemoteDebug:uploadLogWithTag(
											"GameLaunch", "P5.2   localData.passDay" , localData.passDay , 
											"passDay" , passDay , 
											"nowtime" , nowtime ,
											"localData.beginTime" , localData.beginTime , 
											"beginTimeInfo.todayMidNight" , beginTimeInfo.todayMidNight ) 
			end

		end

		if not localData.passDay then
			localData.passDay = passDay
		end

		if passDay > localData.passDay then

			localData.passLevelNumsToday = 0 --今日过关次数，每日周次登陆置0

			local pd = passDay - localData.passDay

			for i = 1 , pd do
				
				if i == 1 then
					table.insert( localData.activeDays , 1 , localData.lastDayHasPlayLevel )
				else
					table.insert( localData.activeDays , 1 , false )
				end
				
				if #localData.activeDays > 28 then
					table.remove( localData.activeDays )
				end
			end
		end

		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("GameLaunch", "P4.2   localData:" , table.serialize( localData ) , "passDay = " , passDay ) end

		local currActiveDays7 , currActiveDays28 = self:countActivityDays( localData.activeDays , nowtime , localData.userCreateTime )

		localData.currActiveDays7 = currActiveDays7
		localData.currActiveDays28 = currActiveDays28

		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("GameLaunch", "P4.3   localData:" , table.serialize( localData ) , "currActiveDays7" , currActiveDays7 , "currActiveDays28" , currActiveDays28  ) end

		-- if debugLog and not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 0  currActiveDays7" , currActiveDays7 , "currActiveDays28" , currActiveDays28 ) end


		if currActiveDays7 == 0 and not doNotStartNewAdjust then
			-- 重新激活新的回流干预
			-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 1" ) end
			local currConfig = self:getAdjustSeqConfigCopy( currActiveDays7 , currActiveDays28 )
			if currConfig and not doNotStartNewAdjust then
				startNewAdjust( currActiveDays7 , currActiveDays28 , currConfig.seq )
			end
		else

			-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 2" ) end

			if localData.seqIdx > 0 and localData.fuuuAdjustSeq then --正在某一轮干预中
				
				-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 3" ) end

				if localData.passDay and passDay > localData.passDay then
					--新的一天

					if localData.lastDayHasPlayLevel then --昨天有没有打关行为，即昨天算不算活跃日
						
						-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 4" ) end
						
						localData.seqIdx = localData.seqIdx + 1

						if localData.seqIdx > #localData.fuuuAdjustSeq then
							--周期走完，干预结束

							localData.fuuuAdjustSeq = nil
							localData.seqIdx = 0
							localData.currStrength = 0
							localData.passDay = 0

							local currConfig = self:getAdjustSeqConfigCopy( currActiveDays7 , currActiveDays28 )
							if currConfig and not doNotStartNewAdjust then--当前满足某一档干预
								-- 重新激活新的回流干预
								startNewAdjust( currActiveDays7 , currActiveDays28 , currConfig.seq )
							end
						else
							--周期走一天,计算修正后的干预强度
							local currConfig = self:getAdjustSeqConfigCopy( localData.activeDays7 , localData.activeDays28 )
							if currConfig then
								localData.currStrength = self:getCurrStrength( currConfig )
							end
						end
					end

				else

				end

				localData.passDay = passDay

			else --未在激活周期内

				-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 5" ) end

				local currConfig = self:getAdjustSeqConfigCopy( currActiveDays7 , currActiveDays28 )
				
				if currConfig and not doNotStartNewAdjust then--当前满足某一档干预
					
					-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 6" ) end

					-- 重新激活新的回流干预
					startNewAdjust( currActiveDays7 , currActiveDays28 , currConfig.seq )
				else
					
					-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 7" ) end

					localData.seqIdx = 0
					localData.fuuuAdjustSeq = nil
					localData.currStrength = 0
					localData.passDay = 0
				end

			end
		end


		-- if not _G.AI_CHECK_ON then printx( 1 , "onGameLaunch 8" ) end

		localData.nowDayStr = dateInfo.nowDayStr --每天首次登陆更新此字段
		localData.lastDayHasPlayLevel = false --每天首次登陆设置为false，如果后续有passLevel，则会被置为true，那么次日就会执行seqIdx的更新

		if debugLog and not _G.AI_CHECK_ON then 
			RemoteDebug:uploadLogWithTag("GameLaunch", "P5   localData:" , table.serialize( localData )  )
		end


		self:flushLocalData()
	end
	
end

function NewReturnAndLowActiveAdjustLogic:updateByUserResp( respBean )
	-- if not _G.AI_CHECK_ON then printx( 1 , "NewReturnAndLowActiveAdjustLogic:updateByUserResp" ) end
	if respBean.fuuuAdjustInfo then

		if debugLog and not _G.AI_CHECK_ON then 
			RemoteDebug:uploadLogWithTag(
				"updateByUser", "P1   respBean.fuuuAdjustInfo" , table.serialize(respBean.fuuuAdjustInfo) ) 
		end
		
		local localData = self:getLocalData()

		local fuuuAdjustInfo = respBean.fuuuAdjustInfo
		-- if not _G.AI_CHECK_ON then printx( 1 , "updateByUserResp  fuuuAdjustInfo = " , table.tostring(fuuuAdjustInfo) ) end

		local nowtime = Localhost:timeInSec()

		localData.userCreateTime = math.floor( fuuuAdjustInfo.userCreateTime / 1000 )
		localData.beginTime = math.floor( fuuuAdjustInfo.serverCycleInitContext.beginTime / 1000 )

		localData.activeDays = fuuuAdjustInfo.activeDays

		localData.activeDays7 = fuuuAdjustInfo.serverCycleInitContext.activeDays7
		localData.activeDays28 = fuuuAdjustInfo.serverCycleInitContext.activeDays28

		local currActiveDays7 , currActiveDays28 = self:countActivityDays( localData.activeDays , nowtime , localData.userCreateTime )
		-- if not _G.AI_CHECK_ON then printx( 1 , "updateByUserResp  currActiveDays7 = " , currActiveDays7 , "currActiveDays28 = " , currActiveDays28 ) end

		localData.currActiveDays7 = currActiveDays7
		localData.currActiveDays28 = currActiveDays28

		localData.seqIdx = fuuuAdjustInfo.seqIdx + 1
		localData.fuuuAdjustSeq = fuuuAdjustInfo.fuuuAdjustSeq
		localData.passLevelNumsToday = fuuuAdjustInfo.passLevelNumsToday
		localData.passLevelNumsUnder6 = fuuuAdjustInfo.passLevelNumsUnder6

		localData.currStrength = 0

		local currConfig = self:getAdjustSeqConfigCopy( localData.activeDays7 , localData.activeDays28 )

		if currConfig then
			localData.currStrength = self:getCurrStrength( currConfig )
		end

		
		local dateInfo = getDateInfo(nowtime)
		localData.nowDayStr = dateInfo.nowDayStr

		local passDay = 0
		if localData.seqIdx > 0 and localData.fuuuAdjustSeq then
			local beginTimeInfo = getDateInfo( localData.beginTime )

			if nowtime - localData.beginTime > beginTimeInfo.todayMidNight - localData.beginTime then
				passDay = 1 + math.floor( (nowtime - beginTimeInfo.todayMidNight) / (24*3600) )
			end
		end
		localData.passDay = passDay

		if debugLog and not _G.AI_CHECK_ON then 
			RemoteDebug:uploadLogWithTag(
				"updateByUser", "P2   localData" , table.serialize(localData) ) 
		end

		self:flushLocalData()
	end
end

--启动关卡时回调
function NewReturnAndLowActiveAdjustLogic:onStartLevel( context )

	-- if not self.localData then
	-- 	return --unittest not need setData
	-- end

	-- if not self.localData.lastLaunchHasPlayLevel and self.localData.adjustIndex <= 6 then
	-- 	self.localData.lastLaunchHasPlayLevel = true
	-- 	LocalBox:setData( "localData" , self.localData , localFileKey )
	-- end

end

--关卡结束时回调，包含成功过关和失败过关，不包含重玩和退出
function NewReturnAndLowActiveAdjustLogic:onPassLevel( result , levelId , strategyID )

	-- if not _G.AI_CHECK_ON then printx( 1 , "NewReturnAndLowActiveAdjustLogic:onPassLevel" ) end
	local localData = self:getLocalData()
	-- if true then return end
	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("onPassLevel_1", result , levelId , strategyID ) end
	if result then
		local topLevelId = UserManager:getInstance():getUserRef():getTopLevelId()

		local ds = 0
		local dsData = LevelDifficultyAdjustManager:getStrategyReplayDataByStrategyID( strategyID )
		if dsData and dsData.mode == 3 then
			ds = dsData.ds
		end

		local contextTopLevelId = GamePlayContext:getInstance().levelInfo.currTopLevelId

		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("onPassLevel_2", ds , levelId , topLevelId , contextTopLevelId) end

		if levelId == contextTopLevelId then
			local maxLevelId = NewAreaOpenMgr.getInstance():getCanPlayTopLevel()
			if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("onPassLevel_3", maxLevelId ) end

			if not localData.passLevelNumsToday then localData.passLevelNumsToday = 0 end
			localData.passLevelNumsToday = localData.passLevelNumsToday + 1

			if localData.seqIdx > 0 and localData.fuuuAdjustSeq and ds == 7 then
				if not localData.passLevelNumsUnder6 then localData.passLevelNumsUnder6 = 0 end
				localData.passLevelNumsUnder6 = localData.passLevelNumsUnder6 + 1
			end

			local currConfig = self:getAdjustSeqConfigCopy( localData.activeDays7 , localData.activeDays28 )
			localData.currStrength = self:getCurrStrength( currConfig )
		end
	end

	localData.lastDayHasPlayLevel = true

	if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("onPassLevel_4", table.serialize( localData ) ) end

	self:flushLocalData()
end

function NewReturnAndLowActiveAdjustLogic:onPassDay()
	setTimeOut( function () self:onGameLaunch() end , 0.1 )
end


function NewReturnAndLowActiveAdjustLogic:checkEnableAdjust( context )

	local newReturnAndLowActiveExpGroup = context.userGroupInfo.newReturnAndLowActiveExpGroup

	if newReturnAndLowActiveExpGroup == 0 then
		--对照组不激活 
		-- DiffAdjustQAToolManager:print(1, "NewReturnAndLowActiveAdjustLogic", "return 1")
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  newReturnAndLowActiveExpGroup:" , newReturnAndLowActiveExpGroup ) end
		return nil
	end

	if context.isPayUser then
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  context.isPayUser:" , context.isPayUser ) end
		return nil
	end

	if context.levelId ~= context.topLevel then
		--非topLevel关，不激活
		-- DiffAdjustQAToolManager:print(1, "NewReturnAndLowActiveAdjustLogic", "return 2")
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  context.levelId:" , context.levelId , "context.topLevel:" , context.topLevel ) end
		return nil
	end

	if not context.levelStar or (context.levelStar > 0) then
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  context.levelId:" , context.levelId , "context.levelStar:" , context.levelStar ) end
		return nil
	end

	if not ( context.isMainLevel and context.levelId <= context.maxLevelId - 60 ) then
		--非主线关，顶部60以内关 不激活
		-- DiffAdjustQAToolManager:print(1, "NewReturnAndLowActiveAdjustLogic", "return 3")
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  context.isMainLevel:" , context.isMainLevel , "context.maxLevelId:" , context.maxLevelId ) end
		return nil
	end

	local newReturnAndLowActiveData = context.newReturnAndLowActiveStrength

	if not context.newReturnAndLowActiveStrength or context.newReturnAndLowActiveStrength == 0 then
		-- DiffAdjustQAToolManager:print(1, "NewReturnAndLowActiveAdjustLogic", "return 4")
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "return 1  context.newReturnAndLowActiveStrength:" , context.newReturnAndLowActiveStrength ) end
		return nil
	end

	local diffTag = context.diffTag
	local topLevelDiffTagValue = UserTagValueMap[UserTagNameKeyFullMap.kTopLevelDiff]
	local fixedDs = context.newReturnAndLowActiveStrength

	if diffTag == topLevelDiffTagValue.kHighDiff4 and (fixedDs == 6 or fixedDs <= 3) then
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "fix Ds:" , fixedDs , " --> " , diffTag ) end
		return nil --产品期望跳过 NewReturnAndLowActiveAdjustLogic ，执行后续难度调整逻辑 ，而不是直接篡改ds值
	end

	if diffTag == topLevelDiffTagValue.kHighDiff5 and (fixedDs == 6 or fixedDs <= 4) then
		if debugLog and not _G.AI_CHECK_ON then RemoteDebug:uploadLogWithTag("ADJUST CHECK", "fix Ds:" , fixedDs , " --> " , diffTag ) end
		return nil --产品期望跳过 NewReturnAndLowActiveAdjustLogic ，执行后续难度调整逻辑 ，而不是直接篡改ds值
	end


	local resultData = { 
							levelId = context.levelId ,
							mode = ProductItemDiffChangeMode.kAddColor , 
							ds = fixedDs , 
							reason = "NewReturnAndLowActiveAdjust"
						}
	return resultData
end


return NewReturnAndLowActiveAdjustLogic