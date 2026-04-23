FuuuDiffAdjustManager = class()


FUUUAdjustUnactivateReason = {
	
	UNKNOW = 1000 ,
	GROUP_ZERO = 1001 ,
	ActivationTagBreak = 1002 ,
	FailCountZeroBreak_1 = 1003 ,
	FailCountZeroBreak_2 = 1004 ,
	FailCountZeroBreak_3 = 1005 ,
	FailCountZeroBreak_4 = 1006 ,
	FailCountZeroBreak_5 = 1007 ,
	PayAmountBreak_1 = 1008 ,
	PayAmountBreak_2 = 1009 ,
	PayAmountBreak_3 = 1010 ,
	PayAmountBreak_4 = 1011 ,
	PayAmountBreak_5 = 1012 ,
	DefaultBreak_1 = 1013 ,
	DefaultBreak_2 = 1014 ,
	PreBuffAct = 1015 ,
	FUUUExpG1 = 1020 ,
}


function FuuuDiffAdjustManager:create( levelDifficultyAdjustManager )
	local logic = FuuuDiffAdjustManager.new()
	logic:reset()
	logic.levelDifficultyAdjustManager = levelDifficultyAdjustManager
	return logic
end

function FuuuDiffAdjustManager:reset()
end

function FuuuDiffAdjustManager:buildLevelTargetProgressByRespData( datastr , mode )
	if datastr then

		local levelTargetProgress = {}
		if mode == "aiMode" then
			levelTargetProgress = datastr

			-- local log = {}
	  --       log.method = "buildLevelTargetProgressByRespData   #levelTargetProgress = " .. tostring( #levelTargetProgress )
	  --       ReplayDataManager:addMctsLogs("N1",log) 
	        
		elseif type(datastr) == "string" then
			levelTargetProgress = table.deserialize( datastr )
		end

		-- printx( 1 , "#levelTargetProgress = " , #levelTargetProgress)
		-- printx( 1 , table.tostring(levelTargetProgress) )
		

		local levelTables = {}

		for i = 1 , #levelTargetProgress do

			local data = levelTargetProgress[i]
			local stepBean = {}

			local level = nil
			local step = nil

			if false then
				level = tonumber(data.level)
				step = tonumber(data.step)

				stepBean.tagetId = tonumber(data.target)
				stepBean.min = 0
				stepBean.low = tonumber(data.low)
				stepBean.mid = tonumber(data.mid)
				stepBean.high = tonumber(data.high)
				stepBean.max = 0
				stepBean.sampleCount = data[9]
			else
				level = data[1]
				step = data[2]

				stepBean.tagetId = data[3]
				stepBean.min = data[4]
				stepBean.low = data[7]
				stepBean.mid = data[6]
				stepBean.high = data[5]
				stepBean.max = data[8]
				stepBean.sampleCount = data[9]
			end
			-- local levelconfig = LevelDataManager.sharedLevelData():getLevelConfigByID( level  , false )

			local levelMeta = LevelMapManager.getInstance():getMeta( level )

			if levelMeta and levelMeta.gameData then

				local moveLimit = levelMeta.gameData.moveLimit or 9999

				if moveLimit == 0 then moveLimit = 9999 end

				if step <= moveLimit then
					if not levelTables[ tostring(level) ] then
						levelTables[ tostring(level) ] = { levelId = level , steps = {} , staticTotalSteps = moveLimit }
					end

					local steps = levelTables[ tostring(level) ].steps

					if not steps[ "s" .. tostring(step) ] then
						steps[ "s" .. tostring(step) ] = {}
					end
					
					local currStep = steps["s" .. tostring(step)]

					currStep[ tostring(stepBean.tagetId) ] = stepBean
				end
			end
			
		end

		return levelTables
	end

	return nil
end

function FuuuDiffAdjustManager:buildLevelTargetProgressDataByReplayDataStr( datastr , staticTotalSteps )

	local leveldata = {}
	leveldata.steps = {}
	leveldata.staticTotalSteps = staticTotalSteps

	local version = 1

	if string.starts(datastr, '@@@Version:2@@@') then
		version = 2
		datastr = string.sub(datastr, #'@@@Version:2@@@' + 1, -1)
	elseif string.starts(datastr, '@@@Version:3@@@') then
		version = 3
		datastr = string.sub(datastr, #'@@@Version:3@@@' + 1, -1)
	end

	for w in string.gmatch( datastr ,"([^';']+)") do
		
		local arr = {}
		for w1 in string.gmatch( w ,"([^'~']+)") do
			table.insert( arr , w1 )
		end

		local targetId = arr[1]
		local stepsStr = arr[2]

		local stepsArr = {}
		for w2 in string.gmatch( stepsStr ,"([^'^']+)") do
			table.insert( stepsArr , w2 )
		end

		for k,v in ipairs(stepsArr) do

			local vt = {}
			for w3 in string.gmatch( v ,"([^'_']+)") do
				table.insert( vt , w3 )
			end

			local realStep = nil

			if version == 2 then
				realStep = k - 1
			elseif version == 3 then
				realStep = tonumber( vt[1] )
			else
				realStep = k
			end

			if not leveldata.steps[ "s" .. tostring(realStep) ] then
				leveldata.steps[ "s" .. tostring(realStep) ] = {}
			end
			
			local step = leveldata.steps[ "s" .. tostring(realStep) ]

			if not step[tostring(targetId)] then
				step[tostring(targetId)] = { tagetId = targetId }
			end

			local stepBean = step[tostring(targetId)]

			if version == 3 then
				stepBean.min = tonumber( vt[2] )
				stepBean.low = tonumber( vt[3] )
				stepBean.mid = tonumber( vt[4] )
				stepBean.high = tonumber( vt[5] )
				stepBean.max = tonumber( vt[6] )
			else
				stepBean.min = tonumber( vt[1] )
				stepBean.low = tonumber( vt[2] )
				stepBean.mid = tonumber( vt[3] )
				stepBean.high = tonumber( vt[4] )
				stepBean.max = tonumber( vt[5] )
			end

		end
		
	end

	return leveldata
end

function FuuuDiffAdjustManager:getLevelTargetProgressDataStrForReplay( localLevelData , levelId )
	if (not localLevelData) or (not localLevelData.levelTargetProgress) then
		return
	end

	local ldata = localLevelData.levelTargetProgress[ tostring(levelId) ]

	if ldata then
		local staticTotalSteps = ldata.staticTotalSteps
		local steps = ldata.steps

		local datastr = ""
		local targetIdMap = {}
		for i = 0 , tonumber(staticTotalSteps) do
			local step = steps["s" .. tostring(i)]

			if step then
				for k,v in pairs(step) do

					if not targetIdMap[k] then
						targetIdMap[k] = ""
					end
					local str = targetIdMap[k]

					if str == "" then
						targetIdMap[k] = tostring(i) .. "_" .. tostring(v.min) .. "_" .. tostring(v.low) .. "_" .. tostring(v.mid) .. "_" .. tostring(v.high) .. "_" .. tostring(v.max)
					else
						targetIdMap[k] = str .. "^" .. tostring(i) .. "_" .. tostring(v.min) .. "_" .. tostring(v.low) .. "_" .. tostring(v.mid) .. "_" .. tostring(v.high) .. "_" .. tostring(v.max)
					end
				end
			end
		end


		for k2,v2 in pairs(targetIdMap) do
			if datastr == "" then
				datastr = tostring(k2) .. "~" .. v2
			else
				datastr = datastr .. ";" .. tostring(k2) .. "~" .. v2
			end
		end

		local version = '@@@Version:3@@@'
		datastr = version .. datastr
		return datastr , staticTotalSteps
	end
end




function FuuuDiffAdjustManager:checkAdjustStrategyByFuuu( levelId , closeToMaxLevel )
	--[[
	-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "111  levelId" , levelId , "closeToMaxLevel" , closeToMaxLevel)

	local uid = getCurrUid()

	local addColorFuuuGroup = 0

	if MaintenanceManager:getInstance():isEnabledInGroup("LevelDifficultyAdjust" , "NewFuuu1" , uid) then
		addColorFuuuGroup = 1
	elseif MaintenanceManager:getInstance():isEnabledInGroup("LevelDifficultyAdjust" , "NewFuuu2" , uid) then
		addColorFuuuGroup = 2
	elseif MaintenanceManager:getInstance():isEnabledInGroup("LevelDifficultyAdjust" , "NewFuuu3" , uid) then
		addColorFuuuGroup = 3
	end

	-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "222  uid" , uid , "addColorFuuuGroup" , addColorFuuuGroup )

	if addColorFuuuGroup ~= 0 then

		if addColorFuuuGroup == 1 then

			if not closeToMaxLevel then

				local activationTag = UserTagManager:getUserTag( UserTagNameKeyFullMap.kActivation )
				local topLevelDiffTag = UserTagManager:getUserTag( UserTagNameKeyFullMap.kTopLevelDiff )

				local activationTagValue = UserTagValueMap[UserTagNameKeyFullMap.kActivation]
				local topLevelDiffTagValue = UserTagValueMap[UserTagNameKeyFullMap.kTopLevelDiff]

				-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "333  activationTag" , activationTag , 
				-- 	"topLevelDiffTag" , topLevelDiffTag , "activationTagValue" , activationTagValue , "topLevelDiffTagValue" , topLevelDiffTagValue )

				if activationTag == activationTagValue.kWillLose 
					or activationTag == activationTagValue.kReturnBack 
					or topLevelDiffTag == topLevelDiffTagValue.kHighDiff4 
					or topLevelDiffTag == topLevelDiffTagValue.kHighDiff5 
					then

					return false

				end

				local failCounts = UserTagManager:getTopLevelFailCounts() or 1

				-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "444  failCounts" , failCounts  )

				--failCounts = failCounts - 2

				if failCounts > 0 then
					if topLevelDiffTag == topLevelDiffTagValue.kHighDiff3 then

						if failCounts % 3 == 0 then
							return true
						end

					elseif topLevelDiffTag == topLevelDiffTagValue.kHighDiff2 then

						if failCounts % 2 == 0 then
							return true
						end

					else
						return true
					end
				end
			end

		elseif addColorFuuuGroup == 2 then

			-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "555  Group 2 closeToMaxLevel =" , closeToMaxLevel  )
			if closeToMaxLevel then

				local failCounts = UserTagManager:getTopLevelFailCounts() or 1
				failCounts = failCounts - 1

				-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "666  Group 2 failCounts =" , failCounts  )
				if failCounts > 0 then
					-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "777  Group 2 true"  )
					return true
				end
			else
				-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "888  Group 2 true"  )
				return true
			end

		elseif addColorFuuuGroup == 3 then

			if closeToMaxLevel then

				local failCounts = UserTagManager:getTopLevelFailCounts() or 1
				failCounts = failCounts - 3

				if failCounts > 0 then
					return true
				end

			else

				local failCounts = UserTagManager:getTopLevelFailCounts() or 1

				if failCounts == 1 then
					return true
				end
			end

		end

	end
	]]
	return false
end



function FuuuDiffAdjustManager:checkAdjustStrategyByFuuuV2( levelId , closeToMaxLevel , userGroup , adjustContext )

	local fuuuExpGroup = adjustContext.userGroupInfo.fuuuExpGroup or 0

	DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "111  levelId" , levelId , "closeToMaxLevel" , closeToMaxLevel )
	-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "111  levelId" , levelId , "closeToMaxLevel" , closeToMaxLevel)

	local uid = LevelDifficultyAdjustManager:getContext().uid

	DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "222  uid" , uid , "userGroup" , userGroup )
	-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "222  uid" , uid , "userGroup" , userGroup )
	if userGroup == 0 then
		DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.GROUP_ZERO , levelId )
		return false , FUUUAdjustUnactivateReason.GROUP_ZERO
	end
		
	local payUser = false

	if (userGroup >= 12 and userGroup <= 16) or (userGroup == 9 or userGroup == 18 or userGroup == 17) or userGroup == 10 then
		--[[
		A9组
		回流用户、濒临流失、四阶过难、五阶过难：不触发fuuu，只会相应的触发难度自动调整 
		三阶过难：toplevel关每闯关2次后，第2n+1次触发fuuu，其他时候满足自动调关则触发自动调关，不满足则什么都不触发 
		二阶过难：toplevel关每闯关1次后，第n+1次触发fuuu，其他时候满足自动调关则触发自动调关，不满足则什么都不触发 
		非以上用户： toplevel关每次闯关都会触发fuuu
		]]

		local function checkEnableFuuu()
			local activationTag = LevelDifficultyAdjustManager:getContext().fixedActivationTag
			local topLevelDiffTag = LevelDifficultyAdjustManager:getContext().diffTag

			local activationTagValue = UserTagValueMap[UserTagNameKeyFullMap.kActivation]
			local topLevelDiffTagValue = UserTagValueMap[UserTagNameKeyFullMap.kTopLevelDiff]

			DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "333  activationTag" , activationTag , 
				"topLevelDiffTag" , topLevelDiffTag , "activationTagValue" , activationTagValue , "topLevelDiffTagValue" , topLevelDiffTagValue )
			-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "333  activationTag" , activationTag , 
			-- 	"topLevelDiffTag" , topLevelDiffTag , "activationTagValue" , activationTagValue , "topLevelDiffTagValue" , topLevelDiffTagValue )

			if activationTag == activationTagValue.kWillLose 
				or activationTag == activationTagValue.kReturnBack 
				or topLevelDiffTag == topLevelDiffTagValue.kHighDiff4 
				or topLevelDiffTag == topLevelDiffTagValue.kHighDiff5 
				then
				DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "333  return" )
				-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "333  return" )

				DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.ActivationTagBreak , levelId )
				return false , FUUUAdjustUnactivateReason.ActivationTagBreak

			end

			local failCounts = LevelDifficultyAdjustManager:getContext().failCount + 1

			DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "444  failCounts" , failCounts )
			-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "444  failCounts" , failCounts  )

			--failCounts = failCounts - 2

			if failCounts > 0 then
				if topLevelDiffTag == topLevelDiffTagValue.kHighDiff3 then

					if failCounts % 3 == 0 then
						DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "555  return" )
						-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "555  return" )
						return true
					end

				elseif topLevelDiffTag == topLevelDiffTagValue.kHighDiff2 then

					if failCounts % 2 == 0 then
						DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "666  return" )
						-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "666  return" )
						return true
					end

				else
					DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "777  return" )
					-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "777  return" )
					return true
				end
			end

			DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.FailCountZeroBreak_1 , levelId )
			return false , FUUUAdjustUnactivateReason.FailCountZeroBreak_1
		end

		local function checkFailCount()
			local failCounts = LevelDifficultyAdjustManager:getContext().failCount + 1
			if failCounts > 0 then
				if failCounts % 3 == 0 then
					return true
				end
			end
			return false
		end
		-- printx( 1 , "FFFFFFFFFFFFFFFFFFFFFFF 1  closeToMaxLevel" , closeToMaxLevel )
		local function checkPayAmountAndPlayCount()
			-- printx( 1 , "FFFFFFFFFFFFFFFFFFFFFFF 2")
			local last60DayPayAmount = LevelDifficultyAdjustManager:getContext().last60DayPayAmount

			local playCount = LevelDifficultyAdjustManager:getContext().todayPlayCount
			playCount = playCount + 1

			if not LevelDifficultyAdjustManager:getContext().isMock then
				local totalPlayCountData = LevelDifficultyAdjustManager:getContext().totalPlayCountData

				local today = LevelDifficultyAdjustManager:getContext().today
				local todayData = totalPlayCountData[ tostring(today) ]
				todayData["l" .. tostring(LevelDifficultyAdjustManager:getContext().levelId)] = playCount

				LocalBox:setData( "totalPlayCount" , totalPlayCountData , "LB_diffadjust" )
			end

			

			if userGroup == 12 and last60DayPayAmount > 47 then
				if playCount <= 3 then
					DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.PayAmountBreak_1 , levelId , last60DayPayAmount )
					return false , FUUUAdjustUnactivateReason.PayAmountBreak_1
				else
					return true
				end
			elseif userGroup == 13 and last60DayPayAmount > 47 then	
				if playCount <= 3 then
					DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.PayAmountBreak_2 , levelId , last60DayPayAmount )
					return false , FUUUAdjustUnactivateReason.PayAmountBreak_2
				else
					local fc = LevelDifficultyAdjustManager:getContext().failCount + 1
					if checkFailCount() then
						return true
					else
						DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.FailCountZeroBreak_2 , levelId , fc )
						return false , FUUUAdjustUnactivateReason.FailCountZeroBreak_2
					end
				end
			elseif userGroup == 14 and last60DayPayAmount > 47 then	
				DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.PayAmountBreak_3 , levelId , last60DayPayAmount )
				return false , FUUUAdjustUnactivateReason.PayAmountBreak_3
			elseif userGroup == 15 and last60DayPayAmount > 240 then	
				DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.PayAmountBreak_4 , levelId , last60DayPayAmount )
				return false , FUUUAdjustUnactivateReason.PayAmountBreak_4
			elseif userGroup == 16 and last60DayPayAmount > 240 then	
				if playCount <= 3 then
					DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.PayAmountBreak_5 , levelId , last60DayPayAmount )
					return false , FUUUAdjustUnactivateReason.PayAmountBreak_5
				else
					local fc = LevelDifficultyAdjustManager:getContext().failCount + 1
					if checkFailCount() then
						return true
					else
						DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.FailCountZeroBreak_3 , levelId , fc )
						return false , FUUUAdjustUnactivateReason.FailCountZeroBreak_3
					end
				end
			else
				--非以上情况使用A9组逻辑，即“每把都会触发fuuu干预，不触发颜色干预 ”
				return true
			end
		end

		local isPayUser = LevelDifficultyAdjustManager:getContext().isPayUser
		if not closeToMaxLevel then
			--非头部玩家

			if (userGroup == 9 or userGroup == 18 or userGroup == 17) or (userGroup >= 12 and userGroup <= 16) then
				-- printx( 1 , "FFFFFFFFFFFFFFFFFFFFFFF 1.1")
				if isPayUser then
					-- printx( 1 , "FFFFFFFFFFFFFFFFFFFFFFF 1.2")
					if (userGroup == 9 or userGroup == 18 or userGroup == 17) then
						DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N1  return true" )
						return true
					else
						local r , reason = checkPayAmountAndPlayCount()
						DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N2  return " , r )
						return r , reason
					end
				else
					-- printx( 1 , "FFFFFFFFFFFFFFFFFFFFFFF 1.3")
					local fuuuResult , reason = checkEnableFuuu()
					DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N3  return " , fuuuResult )
					return fuuuResult , reason
				end
			elseif userGroup == 10 then
				if isPayUser then
					local failCounts = LevelDifficultyAdjustManager:getContext().failCount + 1
					if failCounts > 0 then
						if failCounts % 3 == 0 then
							DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N4  return true" )
							return true
						end
					end
					DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N5  return false" )
					DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.FailCountZeroBreak_4 , levelId , failCounts )
					return false , FUUUAdjustUnactivateReason.FailCountZeroBreak_4
				else
					local fuuuResult , reason = checkEnableFuuu()
					DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N6  return " , fuuuResult ) 
					return fuuuResult , reason
				end
			end
			
		else
			--头部玩家
			local maxLevelId = LevelDifficultyAdjustManager:getContext().maxLevelId
			if levelId <= maxLevelId - LevelDifficultyAdjustTopLevelLength then
				--非头部15关内的玩家
				if (userGroup == 9 or userGroup == 18 or userGroup == 17) or (userGroup >= 12 and userGroup <= 16) then

					if isPayUser then
						if (userGroup == 9 or userGroup == 18 or userGroup == 17) then

							if fuuuExpGroup == 1 then
								
								local last60DayPayAmount = adjustContext.last60DayPayAmount
								local failCounts = adjustContext.failCount + 1
								
								if last60DayPayAmount < 13 then
									if failCounts >= 2 and failCounts % 2 == 0 then
										DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7.1 return true" ) 
										return true
									end
								elseif last60DayPayAmount < 47 then
									if failCounts >= 3 and failCounts % 3 == 0 then
										DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7.2  return true" ) 
										return true
									end
								elseif last60DayPayAmount < 240 then
									if failCounts >= 4 and failCounts % 4 == 0 then
										DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7.3  return true" ) 
										return true
									end
								else
									if failCounts >= 5 and failCounts % 5 == 0 then
										DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7.4  return true" ) 
										return true
									end
								end

								return false , FUUUAdjustUnactivateReason.FUUUExpG1

							else
								DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7  return true" ) 
								return true
							end
						else
							local r , reason = checkPayAmountAndPlayCount()
							DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N8  return " , r ) 
							return r , reason
						end
					else
						if (userGroup == 9 or userGroup == 18 or userGroup == 17) then
							local fuuuResult , reason = checkEnableFuuu()
							DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N7.2  return " , fuuuResult )
							return fuuuResult , reason
						else
							local r , reason = checkPayAmountAndPlayCount()
							DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N8.2  return " , r ) 
							return r , reason
						end
					end
					
				elseif userGroup == 10 then
					local failCounts = LevelDifficultyAdjustManager:getContext().failCount + 1
					if failCounts > 0 then
						if failCounts % 3 == 0 then
							DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N9  return true" ) 
							return true
						end
					end
					DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "N10  return true" ) 
					DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.FailCountZeroBreak_5 , levelId , failCounts )
					return false , FUUUAdjustUnactivateReason.FailCountZeroBreak_5
				end
			end

		end
		DiffAdjustQAToolManager:print( 1 , "checkAdjustStrategyByFuuu" , "888  return" )
		-- RemoteDebug:uploadLogWithTag( "checkAdjustStrategyByFuuu" , "888  return" )

		DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.DefaultBreak_1 , levelId )
		return false , FUUUAdjustUnactivateReason.DefaultBreak_1

	end

	DcUtil:FUUUAdjustUnactivate( FUUUAdjustUnactivateReason.DefaultBreak_2 , levelId )
	return false , FUUUAdjustUnactivateReason.DefaultBreak_2
end