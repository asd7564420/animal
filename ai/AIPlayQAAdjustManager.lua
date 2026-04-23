AIPlayQAAdjustManager = {}

local _switch = false

function AIPlayQAAdjustManager:setSwitch( value )
	_switch = value
end

function AIPlayQAAdjustManager:getSwitch()
	return _switch
end

function AIPlayQAAdjustManager:send( method , datas , callback )
	
	if not _switch then return end
	--table.deserialize
	printx( 1 , "AIPlayQAAdjustManager:send  method = " , method )
	local request = HttpRequest:createPost( "http://127.0.0.1:25011/" .. method )
    request:setConnectionTimeoutMs( 5 * 1000 )
    request:setTimeoutMs(15 * 1000)

    request:addHeader("Content-Type:application/json")

    
    if AIGamePlayManager.currPlayConfig and AIGamePlayManager.currPlayConfig.customParamTable then
    	datas["PRINTX"] = AIGamePlayManager.currPlayConfig.customParamTable["PRINTX"] or false
    end

    if AIGamePlayManager.DebugMode then
    	-- ReplayDataManager:addMctsLogs("PRINTX",{method = "AIGamePlayManager:send  method:" .. tostring(method) .. " PRINTX:" .. tostring(datas["PRINTX"]) })
	end

    local str = "ANIMALFORM__" .. table.serialize( datas )
	request:setPostData( str , string.len( str ) )
    
    local callbackHanler       -- 必须前置声明，否则在闭包本身内访问为nil
    callbackHanler = function(response)
        
        if response.httpCode ~= 200  then
        	-- ReplayDataManager:addMctsLogs( "N2" , {method="QAAdjust HTTP ERROR " .. tostring(method) .. " httpCode:" .. tostring(response.httpCode) } )
        	-- printx( 1 , "AIPlayQAAdjustManager:send  callbackHanler  response.httpCode = " , response.httpCode )
        	if callback then callback( false , response ) end
        else
        	--[[
        	response = 
			{
				errorCode = 0,
				errorMsg = "",
				bodyLength = 38,
				body = "{\"method\": \"/startLevel\", \"code\": 200}",
				httpCode = 200,
				headers = {
				1 = "HTTP/1.0 200 OK",
				2 = "Server: SimpleHTTP/0.6 Python/3.7.3",
				3 = "Date: Fri, 01 Nov 2019 10:43:42 GMT",
				4 = "Content-type: application/json",
			}
        	]]
        	local _body = nil
        	if response and response.body then
        		_body = table.deserialize( response.body )
        	end

        	if AIGamePlayManager.DebugMode then
        		-- ReplayDataManager:addMctsLogs("PRINTX",{method = "QAAdjust HTTP callback : " .. tostring(response.body)  })
        		-- printx( 1 , "AIPlayQAAdjustManager:send  response = "  ,  table.tostring( response ) )
        	end
        	
        	if callback then callback( true , response , _body ) end
        end
    end

    HttpClient:getInstance():sendRequest( callbackHanler , request )
end


function AIPlayQAAdjustManager:startLevel( levelConfig , paras , callback )
	if not _switch then return end
	local levelConfigStr = table.serialize( levelConfig )
	local parasStr = table.serialize( paras )
	self:send( "startLevel" , { levelCfg = mime.b64( compress(levelConfigStr) ) , paras = mime.b64( compress(parasStr) ) } , callback )
end

function AIPlayQAAdjustManager:getNextStep( snapStr , callback )
	if not _switch then return end
	self:send( "getNextStep" , { snap = snapStr } , callback )
end

function AIPlayQAAdjustManager:endLevel( result , callback )
	if not _switch then return end
	self:send( "endLevel" , {result = result} , callback )
end


function AIPlayQAAdjustManager:doSwap( action )
	if not _switch then return end

	local r1 = action.r1
	local c1 = action.c1
	local r2 = action.r2
	local c2 = action.c2

	local mainlogic = GameBoardLogic:getInstance()
	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainlogic)
	if (r1 and c1 and r2 and c2)
		and r1 > 0 and r1 <= rowAmount
		and c1 > 0 and c1 <= colAmount
		and r2 > 0 and r2 <= rowAmount
		and c2 > 0 and c2 <= colAmount
		and mainlogic:SwapedItemAndMatch( r1 , c1 , r2 , c2 , false ) then
		mainlogic:startTrySwapedItem( r1 , c1 , r2 , c2 )
	else
		local str = "step " .. tostring(mainlogic.realCostMove) .. "   " .. tostring(r1) .. tostring(c1) .. " --> " .. tostring(r2)..tostring(c2)
		mainlogic.PlayUIDelegate:replayResult(
							mainlogic.PlayUIDelegate.levelId, 
							mainlogic.totalScore, 
							mainlogic.gameMode:getScoreStarLevel(), 
							0, 0, 0, false, AutoCheckLevelFinishReason.kQASwapErr , str )
	end
end


function AIPlayQAAdjustManager:doUserProp( action )
	if not _switch then return end

	local r1 = action.r1 or 0
	local c1 = action.c1 or 0
	local r2 = action.r2 or 0
	local c2 = action.c2 or 0
	local propId = action.propId or 0
	local propPara = action.para

	local mainlogic = GameBoardLogic:getInstance()

	local function onQAPropErr()
		local str = "propId " .. tostring(propId) .. "   " .. tostring(r1) .. "_" .. tostring(c1) .. "_" .. tostring(r2).. "_" .. tostring(c2)
		mainlogic.PlayUIDelegate:replayResult(
							mainlogic.PlayUIDelegate.levelId, 
							mainlogic.totalScore, 
							mainlogic.gameMode:getScoreStarLevel(), 
							0, 0, 0, false, AutoCheckLevelFinishReason.kQAPropErr , str )
	end

	local bf1 = false
	local bf2 = false
	local rowAmount, colAmount = GameBoardUtil:getRowAndColAmountOfBoard(mainlogic)

	if r1 ~= 0 or c1 ~= 0 then
		if r1 > 0 and r1 <= rowAmount and c1 > 0 and c1 <= colAmount then
			bf1 = true
		end
	else
		bf1 = true
	end

	if r2 ~= 0 or c2 ~= 0 then
		if r2 > 0 and r2 <= rowAmount and c2 > 0 and c2 <= colAmount then
			bf2 = true
		end
	else
		bf2 = true
	end

	-- printx( 1 , "AIPlayQAAdjustManager:doUserProp !!!!!!!!!!!!  action = " , table.tostring(action) )
	if bf1 and bf2 and propId > 0 then

		local usePropResult = mainlogic:replayDoUseProp( r1 , c1 , r2 , c2 , propId , UsePropsType.FAKE , propPara )
		
		if not usePropResult then
			onQAPropErr()
		end
	else
		onQAPropErr()
	end

	
end
