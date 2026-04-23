require "zoo.gamePlay.ai.AIPlayQAAdjustManager"

AIGamePlayManager = {}

AIGamePlayManager.DebugMode = false
AIGamePlayManager.qaManager = AIPlayQAAdjustManager

local AIGPMVersion = "3.7.4"

AIPlayMode = {

	kAI = "ai" ,
	kAIMock = "ai_mock" ,
    kEditorAutoPlay = "editor_auto_play" ,
	kEditorAutoPlayV2 = "editor_auto_play_v2" ,

}

AIPlayLogChannel = {
    LOG = "LOG" ,
    CRASH = "CRASH" ,
    ERROR = "ERROR" ,
    FORCE_SAVE = "FC" ,
}

AIPlayRunMode = {
    kNormal = "normal",
    kCheckReplay = "checkreplay",
    kCreateSample = "createsample"
}

AIGamePlayManager.logicVersion = 2
local playCount = 0
local autoBootCount = 50
local noTaskRebootCount = 500
local rebootTimeDelay = 1500

AIGamePlayManager.defaultLogFile = "AIGamePlayLOG"
AIGamePlayManager.defaultLogChannel = "LOG"
AIGamePlayManager.autoPrintWhenLog = false
AIGamePlayManager.autoDeleteLog = true
AIGamePlayManager.maxLogCount = 1000

local logCount = 0

local propModeConfig = {
    { propId = 10001 , maxCount = 6 },-- 10001 刷新
    { propId = 10002 , maxCount = 6 },-- 10002 后退
    { propId = 10003 , maxCount = 3 },-- 10003 强制交换
    { propId = 10005, maxCount = 3 },-- 10005 魔法棒
    { propId = 10010 , maxCount = 3 },-- 10010 小木槌
    { propId = 10105 , maxCount = 3 },-- 10105 横排火箭
    { propId = 10109 , maxCount = 3 }-- 10109 竖列火箭
}

function AIGamePlayManager:setLogParam( autoPrintWhenLog , autoDeleteLog )
    self.autoPrintWhenLog = autoPrintWhenLog
    self.autoDeleteLog = autoDeleteLog
end

function AIGamePlayManager:log( channel , ... )

    if not channel then
        channel = self.defaultLogChannel
    end

    if type(channel) ~= "string" then
        channel = tostring( channel )
    end

    if channel == AIPlayLogChannel.LOG then
        if not AIGamePlayManager.DebugMode then
            return
        end
    end

    if AIGamePlayManager.autoPrintWhenLog or _G.AI_LOCAL_TEST_MODE then
        printx( 1 , channel , ... )
    end

    local str = "【" .. channel .. "】 "
    local tmpLen = select( "#", ...)

    for i = 1 , tmpLen do
        local v = select( i , ...)

        if v == nil then
            v = "nil"
        end
        
        str = str .. "  " .. tostring(v)
    end

    -- str = str .. "\n"

    if AIGamePlayManager.autoDeleteLog and logCount > AIGamePlayManager.maxLogCount then
        self:deleteLogFile()
        logCount = 0
    else
        LocalBox:appendData( str , self.defaultLogFile )
    end
    
    logCount = logCount + 1
    -- LocalBox:setData( key , data , fileName , passDecrypt )
    -- LocalBox:getData( key , fileName , passDecrypt ,  disableCache )

end

function AIGamePlayManager:deleteLogFile()
    LocalBox:clearAppendData( self.defaultLogFile )
end

function AIGamePlayManager:getModeType()
	return self.playMode
end

function AIGamePlayManager:getVersion()
    return self.logicVersion
end

function AIGamePlayManager:getCurrPlayConfig()
    if self.startLevelData then
        return self.startLevelData.configData
    end
    return nil
end

function AIGamePlayManager:getCustomContext()
    return self.customContext
end



function AIGamePlayManager:sendMsgToSocket( method , datas )
    local simplejson = require("cjson")

    local req = { 
                    action = method ,
                    detail = datas
                }

    -- local str1 = table.tostring(req)

    local reqStr = simplejson.encode(req)

    local resp = nil

    if _G.AI_LOCAL_TEST_MODE then
        if _G.AIAutoCheckReplayCheck then

            if method == "initGame" then
                resp = {}
                resp.clustersGroup = 1
                resp.containerId = 1
                resp.imageId = 1
                resp.appId = 1
                resp.dummyUid = 1

            elseif method == "startLevel" then
                resp = LocalBox:getData( "datas" , "AI_CHECK_LOCAL_TEST_START_LEVEL_DATA" , true ,  true )
            elseif method == "endLevel" then
                resp = {}
                printx( 1 , "AIGamePlayManager:sendMsgToSocket  endLevel  " , debug.traceback() )
                -- debug.debug()
            end
            
        end
    else
        StartupConfig:getInstance():sendMsg( reqStr )
        resp = self:receiveMsgFromSocket( method )
    end

    if AIGamePlayManager.DebugMode then
        self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:sendMsgToSocket 222   resp:" , tostring(resp)  )
    end
    
    return resp
end            

function AIGamePlayManager:receiveMsgFromSocket( method )

    local simplejson = require("cjson")
    local msgstr = StartupConfig:getInstance():receiveMsg()

    self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:receiveMsgFromSocket 111   msgstr:" , msgstr  )

    local resp = simplejson.decode( msgstr )
    
    if resp and type(resp) == "table" then
        resp.code = 200
    end

    if resp.action == method then
        if resp.code == 200 then
            self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:receiveMsgFromSocket 222   resp.detail:" , resp.detail  )
            return resp.detail
        else
            self:log( AIPlayLogChannel.CRASH , "AIGamePlayManager:receiveMsgFromSocket  Error 111 !!!  msgstr:" , msgstr , "  method:" ,  method )
            Crash["crash_receiveMsgFromSocket_return_code_" .. tostring(resp.code)]()
        end
    else
        self:log( AIPlayLogChannel.CRASH , "AIGamePlayManager:receiveMsgFromSocket  Error 222 !!!  msgstr:" , msgstr , "  method:" ,  method )
        Crash["crash_receiveMsgFromSocket_return_method_" .. tostring(resp.method)]()
    end

end

function AIGamePlayManager:__init( playMode , callback )

    AIPlayQAAdjustManager:setSwitch( false )
    
    math.randomseed(os.time())

    if AIGamePlayManager.DebugMode then
        -- _G.AutoCheckLeakInLevel = true
        _G.DingWebHook = "https://oapi.dingtalk.com/robot/send?access_token=2743c60f52d2dc4e63b6823636859eebd4bbfc797ccf1d4d44af988b2a20d5e7"

        -- he_startGLObjectRefsDebug()
    end
    
    self.playConfigMap = {}
    self.playMode = playMode
    ReplayDataManager:clearMctsLogs()
    
    self:log( AIPlayLogChannel.FORCE_SAVE , "AIGamePlayManager:init  Code Ver :" , AIGPMVersion )
    
    if not _G.AI_LOCAL_TEST_MODE then
        StartupConfig:getInstance():initZmq( "tcp://" .. (_G.launchCmds.ip or "127.0.0.1") .. ":" .. _G.launchCmds.port )
    end
    
    
    local function onFuuuStaticDataInited()
        if callback then callback() end
    end

    if self.playMode == AIPlayMode.kAIMock then
        _G.__root={
            parent = nil,
            child = nil,
            signal = 0,
            success = 0,
            sum = 0
        }
        _G.__scores = {}
    elseif self.playMode == AIPlayMode.kAI then
        local verData = getSnapshotManagerVersionData()
        local msgStr = '{"method":"ready" ' 
                        .. ',"game_item_major_version":"' .. tostring(verData.itemMajorVersion) .. '"'
                        .. ',"game_item_minor_version":"' .. tostring(verData.itemMinorVersion) .. '"'
                        .. ',"max_game_item_id":"' .. tostring(verData.maxItemId) .. '"'
                        .. ',"target_item_major_version":"' .. tostring(verData.targetMajorVersion).. '"'
                        .. ',"target_item_minor_version":"' .. tostring(verData.targetMinorVersion) .. '"'
                        .. ',"max_target_item_id":"' .. tostring(verData.maxTargetId) .. '"'
                        .. '}'

        StartupConfig:getInstance():sendMsg(msgStr)
    elseif self.playMode == AIPlayMode.kEditorAutoPlay then

        self.taskRateMap = {}
        self.taskRateMap.count = 0
        self.taskRateMap.normal = {}
        self.taskRateMap.qa = {}
        self.taskRateMap.top = {}
        self.taskRateMap.bg = {}


        local function loadCSV( filePath )
            local path = CCFileUtils:sharedFileUtils():fullPathForFilename( filePath )

            local file = io.open(path, "rb")
            if file then
                local data = file:read("*a") 
                file:close()

                if data then
                    return table.decodeByCSV( data , true )
                end
            end

            return nil
        end

        self.fuuuRateData = loadCSV( "meta/FUUURateForAI.csv" )
        self.prePropRateData = loadCSV( "meta/PrePropRateForAI.csv" )
        self.top15fuuuRateData = loadCSV( "meta/Top15FUUURateForAI.csv" )
        --[[
        local path = CCFileUtils:sharedFileUtils():fullPathForFilename("meta/FUUURateForAI.csv")

        local file = io.open(path, "rb")
        if file then
            local data = file:read("*a") 
            file:close()

            if data then
                self.fuuuRateData = table.decodeByCSV( data , true )
            end
        end
        ]]
    elseif self.playMode == AIPlayMode.kEditorAutoPlayV2 then
        local function loadCSV( filePath )
            local path = CCFileUtils:sharedFileUtils():fullPathForFilename( filePath )

            local file = io.open(path, "rb")
            if file then
                local data = file:read("*a") 
                file:close()

                if data then
                    return table.decodeByCSV( data , true )
                end
            end

            return nil
        end

        self.fuuuRateData = loadCSV( "meta/FUUURateForAI.csv" )
        self.prePropRateData = loadCSV( "meta/PrePropRateForAI.csv" )
        self.top15fuuuRateData = loadCSV( "meta/Top15FUUURateForAI.csv" )
    end


    GameSpeedManager:changeSpeedForCrashResumePlay()

    if not _G.launchCmds.print and not _G.AI_LOCAL_TEST_MODE then
        print = function() end 
        printx = function() end 
    end

    if not _G.launchCmds.visible then
        HeGameDefault:setFpsValue(-1)
    end

    if _G.useNewAIAutoCheck then

        if self.playMode == AIPlayMode.kEditorAutoPlay then

            local custom_args_str = Localhost:readFileRaw( HeResPathUtils:getUserDataPath() .. "/../custom_args")

            self.REDIS_HOST = "10.2.0.8"
            -- self.REDIS_HOST = "animalmobiledev.happyelements.cn"


            if custom_args_str then
                local custom_args = table.deserialize( custom_args_str ) 
                if custom_args.devMode then
                    self.IS_DEV_MODE = true
                    AIGamePlayManager.DebugMode = true
                end

                if custom_args.redisHost then
                    self.REDIS_HOST = custom_args.redisHost
                end
            end

        elseif self.playMode == AIPlayMode.kEditorAutoPlayV2 then
            local simplejson = require("cjson")
            
            local runMode = AIPlayRunMode.kNormal
            
            if _G.AIAutoCheckReplayCheck then
                runMode = AIPlayRunMode.kCheckReplay
            elseif _G.AIAutoCheckCreateSample then
                runMode = AIPlayRunMode.kCreateSample
            end

            self.runMode = runMode

            local detail = {
                            bundleVersion = _G.bundleVersion , 
                            snapVersion = tostring( getSnapshotManagerMainVersion() ) , 
                            AIGPMVersion = AIGPMVersion , 
                            runMode = runMode
                        }
            local resp = self:sendMsgToSocket( "initGame" , detail )

            self:log( AIPlayLogChannel.FORCE_SAVE , "initGame   resp：" , table.tostring(resp) )

            self.initData = {}
            self.initData.clustersGroup = resp.clustersGroup
            self.initData.containerId = resp.containerId
            self.initData.imageId = resp.imageId
            self.initData.appId = resp.appId
            self.initData.dummyUid = resp.dummyUid
        end
            
        if self.checkPlayCrashListener then
            GlobalEventDispatcher:getInstance():removeEventListener("lua_crash", self.checkPlayCrashListener)
            self.checkPlayCrashListener = nil
        end


        self.checkPlayCrashListener = function(evt)
            
            local datas = nil
            if evt and evt.data and evt.data.errorMsg then
                datas = evt.data.errorMsg
            end

            if AIGamePlayManager.DebugMode then
                local log = {}
                log.method = "CREASH  1   datas = " .. tostring(datas)
                self:log( AIPlayLogChannel.CRASH , log )
            end
            self:endLevelByCrash( datas )
        end

        GlobalEventDispatcher:getInstance():addEventListener("lua_crash", self.checkPlayCrashListener)

    end
end

function AIGamePlayManager:init( playMode , callback )

    local function doAction()
        LocalActCoreModel:getOrCreateInstance():registerLocalActsForAI()
        self:__init( playMode , callback )
    end

    local function onError(errMsg) 
        errMsg = errMsg or ""
        he_log_error( "MCT ERROR " .. tostring(errMsg) .. "\n" .. debug.traceback() )

        self:log( AIPlayLogChannel.ERROR , "AIGamePlayManager:init  Error !!!  errMsg:" , errMsg , "  traceback:" , debug.traceback() )
    end 

    xpcall( doAction , __G__TRACKBACK__ )

end

function AIGamePlayManager:reboot()
    local simplejson = require("cjson")
    local datas = {
        result = -999 ,
    }

    self:log( AIPlayLogChannel.LOG , "reboot   playCount = " , playCount )

    self:sendMsgToSocket( "reboot" , datas )
end

function AIGamePlayManager:__updateLevelConfig( levelId , levelMetaTabel )
    
    --[[
    if batchId and levelId and levelMetaTabel then

        local mapKey = tostring(batchId) .. "_" .. tostring(levelId)
        if self.levelConfigMap[ mapKey ] then
            --do nothing
            return
        else
            levelMetaTabel.totalLevel = levelId
            LevelMapManager:getInstance():addDevMeta( levelMetaTabel )

            local levelMeta = LevelMapManager.getInstance():getMeta( levelId )
            local levelConfig = LevelConfig:create(levelId, levelMeta)
            LevelDataManager.sharedLevelData().levelDatas[levelId] = levelConfig

            self.levelConfigMap[ mapKey ] = true
        end
    end
    ]]


    levelMetaTabel.totalLevel = levelId
    LevelMapManager:getInstance():addDevMeta( levelMetaTabel )

    local levelMeta = LevelMapManager.getInstance():getMeta( levelId )
    local levelConfig = LevelConfig:create(levelId, levelMeta)
    LevelDataManager.sharedLevelData().levelDatas[levelId] = levelConfig

    -- self.levelConfigMap[ mapKey ] = true
end

function AIGamePlayManager:__buildBatchPlayConfig( groupBatchId , datas )
    if self.playConfigMap[ groupBatchId ] then
        -- self.currPlayConfig = self.playConfigMap[ batchId ]
        --self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig ------------------------ 000" )
        return self.playConfigMap[ groupBatchId ]
    else
        
        local configData = {}

        configData.groupBatchId = groupBatchId
        configData.oringinConfig = nil
        configData.preProp = "None"
        configData.adjustEnable = "None"
        configData.fixedSteps = nil
        configData.fixedStepData = nil 
        configData.foolMode = false
        configData.fastMode = false
        configData.propMode = false
        configData.propModeMap = {}

        if not datas then
            --回放校验模式没有 datas
            return configData
        end

        configData.oringinConfig = datas
        configData.preProp = datas.preProp
        configData.adjustEnable = datas.adjustEnable
        configData.fixedSteps = datas.fixedSteps

        if datas.fastMode == "F1" then
            configData.fastMode = true
        elseif datas.fastMode == "F2" then
            configData.foolMode = true
        elseif datas.fastMode == "F3" then
            configData.foolMode = true
            configData.propMode = true
        end
        


        if datas.fixedSteps then -- 格式如下：  2341_8979,2434,6656~2322_8979,2434,6656

            configData.fixedStepData = {}

            local str = datas.fixedSteps
            local cfgdata = string.split( str , "~" )

            for k , v in pairs( cfgdata ) do

                local data = string.split( v , "_" )
                local needfixLevelId = data[1] 
                local needfixStepsStr = data[2] 

                local fixdatas = {}
                configData.fixedStepData["lv" .. tostring(needfixLevelId)] = fixdatas

                local arr = string.split( needfixStepsStr , "," )
                for k2 , v2 in ipairs( arr ) do
                    local pos = { 
                                    r1 = tonumber( string.sub( v2 , 1 , 1 ) ) , 
                                    c1 = tonumber( string.sub( v2 , 2 , 2 ) ) ,
                                    r2 = tonumber( string.sub( v2 , 3 , 3 ) ) ,
                                    c2 = tonumber( string.sub( v2 , 4 , 4 ) )
                                }

                    table.insert( fixdatas , pos )
                end               
            end
        end

        -- self:log( AIPlayLogChannel.LOG , "startLevel datas.customParam:" , datas.customParam  )
        --self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig  customParam =" , datas.customParam )

        if datas.customParam and datas.customParam ~= "" then
            local str = datas.customParam
            local strlen = string.len( str )
            local yn = strlen % 4
            if yn > 0 then
                local fixstr = ""
                for i = 1 , yn do
                    fixstr = fixstr .. "="
                end
                str = str .. fixstr
            end
            local jsonstr = mime.unb64(str)

            configData.customParamTable = table.deserialize( jsonstr )

            --self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig  str =" , str )

            if configData.customParamTable then

                -- self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig  ----------- 111" )
                -- if not configData.customParamTable then
                --     local jsonstr = mime.unb64(str)
                --     configData.customParamTable = table.deserialize( jsonstr )
                -- end

                AIGamePlayManager.DebugMode = configData.customParamTable["PRINTX"] or false

                if configData.customParamTable.xmas2019Data then
                    local xmas2019Data = configData.customParamTable.xmas2019Data
                    for i = 1 , 3 do
                        local lvc = xmas2019Data["levelConfig" .. tostring(i)]
                        if lvc then
                            self:__updateLevelConfig( lvc.totalLevel , lvc )
                        end
                    end
                    configData.xmas2019Data = xmas2019Data

                    -- local clipboardData = {}
                    -- clipboardData.xmas2019Data = xmas2019Data
                    -- CCDirector:sharedDirector():setClipboard( table.serialize( clipboardData ) ) 
                end

                local qaAdjustConfig = configData.customParamTable.checkConfig

                if qaAdjustConfig and qaAdjustConfig.checker then
                    -- levelId

                    configData.qaAdjustConfig = qaAdjustConfig

                    local currLevelCheckConfig = nil

                    local level2dataMap = {}

                    for k,v in ipairs( qaAdjustConfig.checker ) do
                        
                        local levelRanges = tostring( v.levelRanges )
                        local arr1 = string.split( levelRanges , "_" )
                        for k2,v2 in ipairs( arr1 ) do
                            local arr2 = string.split( v2 , "~" )
                            if #arr2 == 1 then
                                level2dataMap[ tostring(arr2[1]) ] = v.configs
                            elseif #arr2 == 2 then

                                local start_ = arr2[1]
                                local end_ = arr2[2]

                                start_ = tonumber(start_ or 0) or 0
                                end_ = tonumber(end_ or 0) or 0

                                for i = start_ , end_ do
                                    level2dataMap[ tostring(i) ] = v.configs
                                end
                            end
                        end
                    end

                    configData.qaAdjustConfig.level2dataMap = level2dataMap
                end
            else
                self:log( AIPlayLogChannel.LOG , "startLevel customParam   str:" , str  )
                -- self:log( AIPlayLogChannel.FORCE_SAVE , "startLevel customParam  FORCE_SAVE  ----------- " , str )

                local fixedarr = string.split( str , "=" )
                local fixedstr = fixedarr[1] or ""
                -- self:log( AIPlayLogChannel.LOG , "startLevel customParam   fixedstr:" , fixedstr  )
                local arr = string.split( fixedstr , "~" )

                --self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig  arr:" , table.serialize(arr) )

                configData.tsumBuffList = {}

                for k , v in pairs( arr ) do

                    local strarr = string.split( v , "_" )
                    local strHead = "nil"
                    local strEnd = 0
                    if #strarr > 1 then
                        strHead = strarr[1]
                        strEnd = strarr[2]
                    end
                    -- self:log( AIPlayLogChannel.LOG , "startLevel customParam   strHead:" , strHead , "strEnd:" , tostring(strEnd)  )
                    --self:log( AIPlayLogChannel.FORCE_SAVE , "__buildBatchPlayConfig  strHead:" , strHead , "strEnd:" , tostring(strEnd) )

                    if strHead == "FUUUTestGroup" then
                        _G.AIFuuuTestGroup = tonumber(strEnd)
                    elseif v == "GameInitDiffChangeTest" then
                        configData.GameInitDiffChangeTest = true
                        -- self:log( AIPlayLogChannel.FORCE_SAVE , "startLevel customParam  GameInitDiffChangeTest = true  GameInitDiffChangeLogic = " , tostring(GameInitDiffChangeLogic) )
                    elseif v and string.find(v,"MathFestivalGiftShell") then
                        configData.useMathFestivalGiftShell = v
                    elseif v and string.find(v,"MagicCrystalBall") then
                        configData.useMagicCrystalBall = v
                    elseif v == "EnableRandomTsumBuff_1" then
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kRandomBird_b } )
                    elseif v == "EnableRandomTsumBuff_2" then
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kLineBomb_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kWrapBomb_b } )
                    elseif v == "EnableRandomTsumBuff_3" then
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kRandomBird_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kLineBomb_b } )
                    elseif v == "EnableRandomTsumBuff_4" then
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kRandomBird_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kLineBomb_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kWrapBomb_b } )
                    elseif v == "EnableRandomTsumBuff_5" then
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kRandomBird_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kRandomBird_b } )
                        table.insert( configData.tsumBuffList , { id = GamePropsType.kLineBomb_b } )
                    elseif v == "TEST1" then
                        configData.fixedRandomSeed = 1574771674
                    elseif v == "Weekly2020_RandomChangeBoard" then
                        configData.Weekly2020_RandomChangeBoard = true
                        self.customContext.changeBoardCount = 0
                    end
                end
                -- self:log( AIPlayLogChannel.LOG , "startLevel customParam  load fin" )
            end 
        end

        --to do 团子没空
        -- self.playConfigMap[ groupBatchId ] = configData

        return configData
    end
end

function AIGamePlayManager:__buildStartLevelData( groupBatchId , batchId , levelId , seed , levelCfg , datas , opLog )
    
    if levelCfg then --重放校验模式下，levelCfg为空，使用本地的关卡配置
        local levelMetaTabel = levelCfg
        self:__updateLevelConfig( levelId , levelMetaTabel )
    end
    -- if cmd.snap then
    --     _G.__startCmd = cmd
    -- end
    local configData = self:__buildBatchPlayConfig( groupBatchId , datas )

    local step = nil

    AIPlayQAAdjustManager:setSwitch( false )

    if self.runMode == AIPlayRunMode.kCheckReplay then
        step = opLog
    else
        step = {
            randomSeed = seed , 
            replaySteps = {} , 
            level = levelId , 
            selectedItemsData = {} , 
            SCLogicVer = 1
        }

        step.strategyID = nil

        local prePropList = {}

        local function randomPreProp( code )

            local preProp = {}
            math.randomseed(os.time())

            if code == "None" then
                return preProp
            end

            if code == "P1" then
                table.insert( preProp , { id = 10087} )
                table.insert( preProp , { id = 10099} ) -- replace later
                table.insert( preProp , { id = 10018} )
                table.insert( preProp , { id = 10015} )
                table.insert( preProp , { id = 10007} )
                -- table.insert( preProp , { id = 10099} )
            elseif code == "P2" then
                if math.random() < 0.4 then
                    if math.random() < 0.8 then table.insert(preProp , { id = 10087} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10099} ) end -- replace later
                    if math.random() < 0.8 then table.insert(preProp , { id = 10018} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10015} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10007} ) end
                    -- if math.random() < 0.8 then table.insert(preProp , { id = 10099} ) end
                end
            elseif code == "P3" then
                table.insert( preProp , { id = 10018} )
                table.insert( preProp , { id = 10015} )
                table.insert( preProp , { id = 10007} )
            elseif code == "P4" then
                table.insert( preProp , { id = 10018} )--加三步
                table.insert( preProp , { id = 10007} )--爆炸直线
            elseif code == "P5" then
                table.insert( preProp , { id = 10087} )--魔力鸟
                table.insert( preProp , { id = 10099} )--导弹
                -- table.insert( preProp , { id = 10099} )
            elseif code == "P6" then
                table.insert( preProp , { id = 10087} )--魔力鸟
                table.insert( preProp , { id = 10018} )--加三步
            elseif code == "P7" then
                table.insert( preProp , { id = 10087} )--魔力鸟
                table.insert( preProp , { id = 10007} )--爆炸直线
            elseif code == "P8" then
                table.insert( preProp , { id = 10099} )--导弹
                table.insert( preProp , { id = 10018} )--加三步
            elseif code == "P9" then
                table.insert( preProp , { id = 10099} )--导弹
                table.insert( preProp , { id = 10007} )--爆炸直线
            elseif code == "P9999" then
                if self.prePropRateData and #self.prePropRateData > 0 then
                    
                    local randomArr = {}

                    for k,v in ipairs( self.prePropRateData ) do
                        table.insert( randomArr , tonumber(v.rate) )
                    end

                    -- printx( 1 , "randomArr =" , table.tostring( randomArr ) )
                    
                    local ranI = math.random()
                    local idx = 0
                    for i = 1 , #randomArr do
                        local w = 0
                        for ia = 1 , i do
                            w = w + randomArr[ia]
                        end

                        if ranI <= w then
                            idx = i
                            break
                        end
                    end

                    if idx > 0 then
                        local str = self.prePropRateData[idx].propsType
                        local proplist = string.split( str , "_" )

                        if proplist and #proplist > 0 then
                            for k2 , v2 in ipairs(proplist) do
                                table.insert( preProp , { id = tonumber(v2) } )
                            end
                        end
                    end
                end
            end

            return preProp
        end

        prePropList = randomPreProp( configData.preProp )

        local function randomAdjust( codeStr )

            local code = 0

            if codeStr == "None" then
                return code
            end

            code = tonumber( string.sub( codeStr , 2 ) )
            
            local strategyID = 0

            if code == 9999 then
                if self.fuuuRateData then
                    local fuuudata = self.fuuuRateData[cmd.level]
                    if not fuuudata then fuuudata = self.top15fuuuRateData[1] end

                    if fuuudata then
                        local randomArr = {}
                        table.insert( randomArr , tonumber(fuuudata.none) )
                        table.insert( randomArr , tonumber(fuuudata.diff1) )
                        table.insert( randomArr , tonumber(fuuudata.diff2) )
                        table.insert( randomArr , tonumber(fuuudata.diff3) )
                        table.insert( randomArr , tonumber(fuuudata.diff4) )
                        table.insert( randomArr , tonumber(fuuudata.diff5) )
                        table.insert( randomArr , tonumber(fuuudata.fuuu) )
                        table.insert( randomArr , tonumber(fuuudata.farmFuuu) )

                        -- printx( 1 , "randomArr =" , table.tostring( randomArr ) )
                        math.randomseed(os.time())
                        local ranI = math.random()
                        local idx = 0
                        for i = 1 , #randomArr do
                            local w = 0
                            for ia = 1 , i do
                                w = w + randomArr[ia]
                            end

                            if ranI <= w then
                                idx = i
                                break
                            end
                        end

                        if idx > 0 then
                            if idx == 1 then
                                strategyID = nil
                            elseif idx == 2 then
                                strategyID = 13100000
                            elseif idx == 3 then
                                strategyID = 13200000
                            elseif idx == 4 then
                                strategyID = 13300000
                            elseif idx == 5 then
                                strategyID = 13400000
                            elseif idx == 6 then
                                strategyID = 13500000
                            elseif idx == 7 then
                                strategyID = 14100000
                            elseif idx == 8 then
                                strategyID = 14100000
                                -- strategyID = 15100000
                            end
                        end
                    end
                end
            elseif code == 41 then

                strategyID = 14100000
            elseif code >= 1 and code <= 7 then
                strategyID = 13000000 + ( 100000 * code )
            elseif code >= 61 and code <= 65 then
                strategyID = 10000000 + ( 100000 * code )
            elseif code == 71 then
                strategyID = 17100000
            elseif code == 81 then
                strategyID = 18100000
            end

            return strategyID
        end

        if configData.adjustEnable then
            step.strategyID = randomAdjust( configData.adjustEnable )
        end

        if #prePropList > 0 then
            for k,v in ipairs(prePropList) do
                table.insert(step.selectedItemsData , { id = v.id } )
            end
        end

        if configData.tsumBuffList then
            for k,v in ipairs(configData.tsumBuffList) do
                table.insert(step.selectedItemsData , { id = v.id } )
            end
        end
    end 
    
    local levelCheckParas = nil

    -- self:log( AIPlayLogChannel.LOG , "startLevel configData.tsumBuffList =" , configData.tsumBuffList  )

    

    self:log( AIPlayLogChannel.FORCE_SAVE , "StartMctsLevel   SSSSSSSSS levelId:" , levelId , 

        "seed:" , seed ,  
        --"configData:" , table.serialize(configData) ,  

        debug.traceback() )

    self.getStepCount = 0

    if configData.qaAdjustConfig and configData.qaAdjustConfig.level2dataMap and configData.qaAdjustConfig.level2dataMap[tostring(levelId)] then
        levelCheckParas = configData.qaAdjustConfig.level2dataMap[tostring(levelId)]
    end

    local startLevelData = {}

    startLevelData.levelId = levelId
    startLevelData.batchId = batchId
    startLevelData.seed = seed
    startLevelData.groupBatchId = groupBatchId
    startLevelData.levelCfg = levelCfg
    startLevelData.levelCheckParas = levelCheckParas
    startLevelData.configData = configData
    startLevelData.replayData = step

    -- self:log( AIPlayLogChannel.LOG , "startLevel step.selectedItemsData =" , table.tostring(step.selectedItemsData) )

    
    return startLevelData

end

function AIGamePlayManager:__startLevelV2()

    local step = nil 

    local function updateLevelConfig( levelId , levelMetaTabel )
        levelMetaTabel.totalLevel = levelId
        LevelMapManager:getInstance():addDevMeta( levelMetaTabel )

        local levelMeta = LevelMapManager.getInstance():getMeta( levelId )
        local levelConfig = LevelConfig:create(levelId, levelMeta)
        LevelDataManager.sharedLevelData().levelDatas[levelId] = levelConfig
    end

    local function qaFrameCallback( result , response , body )

        if AIGamePlayManager.DebugMode then
            self:log( AIPlayLogChannel.LOG , "qa_startLevel result:" , result , "    response:" , table.serialize( response ) )
        end

        if result and body.code == 200 then
            local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
            newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
        else
            self:__endLevelV2( false , AutoCheckLevelFinishReason.kQAStartLevelErr , 0 , 0 , table.serialize( response ) )
            -- ReplayDataManager:clearMctsLogs()
            self:startLevel()
        end
    end

    if playCount > autoBootCount then
        self:reboot()
        return
    end

    _G.__startTime = os.time()

    self.scorePointData = nil
    self.playout = false

    local startLevelResp = self:sendMsgToSocket( "startLevel" , { fuck = "WTFFFFFFFFFFFFFF" , runMode = self.runMode} )

    local levelId = startLevelResp.levelId

    local simplejson = require("cjson")

    if _G.AutoCheckLeakInLevel then
        self.autoCheckLeakTag = tostring( _G.__startTime )
        startObjectRefDebug(self.autoCheckLeakTag, levelId)
    end

    if not startLevelResp then
        self:log( AIPlayLogChannel.ERROR , "__startLevel 5  startLevelResp is Nil!" )
        setTimeOut( function () self:startLevel() end , rebootTimeDelay / 5 )
        playCount = playCount - 1
        return
    elseif startLevelResp.noTask then
        --to do
        setTimeOut( function () self:startLevel() end , rebootTimeDelay )
        playCount = playCount - 1
        return
    end

    self:log( AIPlayLogChannel.LOG , "__startLevel 6" )

    local startLevelData = self:__buildStartLevelData( 
        startLevelResp.taskId , 
        startLevelResp.batchId , 
        startLevelResp.levelId , 
        startLevelResp.seed , 
        startLevelResp.levelCfg , 
        startLevelResp.extraCfg ,
        startLevelResp.opLog )

    self:log( AIPlayLogChannel.LOG , "__startLevel 7  " , startLevelResp.taskId , startLevelResp.batchId , startLevelResp.levelId , startLevelResp.seed  )

    if startLevelData.configData and startLevelData.configData.fixedStepData then
        self.fixedStepData = startLevelData.configData.fixedStepData[ "lv" .. tostring(startLevelResp.levelId) ]
    end

    if startLevelData.configData.useMathFestivalGiftShell then
        _G.useMathFestivalGiftShellForAI = startLevelData.configData.useMathFestivalGiftShell
    else
        _G.useMathFestivalGiftShellForAI = false
    end

    _G.useMagicCrystalBall = startLevelData.configData.useMagicCrystalBall or false

    -- self:log( AIPlayLogChannel.FORCE_SAVE , "__startLevel 7.1" )

    -- self:log( AIPlayLogChannel.FORCE_SAVE , "__startLevel 7.2 configData.GameInitDiffChangeTest =" , startLevelData.configData.GameInitDiffChangeTest )
    if startLevelData.configData.GameInitDiffChangeTest then
        GameInitDiffChangeLogic:changeMode( 9 )
    else
        GameInitDiffChangeLogic:changeMode( nil )
    end
    -- self:log( AIPlayLogChannel.FORCE_SAVE , "__startLevel 7.3" )

    self.startLevelData = startLevelData

    if self.runMode == AIPlayMode.kCheckReplay and not startLevelResp.opLog then
        AIGamePlayManager:endLevelByErrorAndReboot( AutoCheckLevelFinishReason.kHasNoOplog , nil )
        return
    end

    step = startLevelData.replayData

    local qaAdjustPara = nil
    if startLevelData.levelCheckParas then
        AIPlayQAAdjustManager:setSwitch( true )

        local configData = startLevelData.configData

        qaAdjustPara = {}
        qaAdjustPara.levelId = startLevelResp.levelId
        qaAdjustPara.adjustEnable = configData.adjustEnable
        qaAdjustPara.fixedSteps = configData.fixedSteps
        qaAdjustPara.preProp = configData.preProp
        qaAdjustPara.fastMode = configData.fastMode
        qaAdjustPara.foolMode = configData.foolMode
        qaAdjustPara.propMode = configData.propMode
        qaAdjustPara.checkConfig = startLevelData.levelCheckParas

    end

    if self.runMode ~= AIPlayMode.kCheckReplay and step.strategyID 
        and (   step.strategyID == 14100000 
                or (step.strategyID >= 17100000 and step.strategyID <= 18100000) 
            ) then

        LevelDifficultyAdjustManager:loadSingleLevelTargetProgerssDataByAI( startLevelResp.levelId , function ()

            local datastr , staticTotalSteps = LevelDifficultyAdjustManager:getLevelTargetProgressDataStrForReplay( startLevelResp.levelId )
            step.tplist = datastr
            step.tpTotalSteps = staticTotalSteps

            if AIPlayQAAdjustManager:getSwitch() then
                AIPlayQAAdjustManager:startLevel( startLevelData.levelCfg , qaAdjustPara , qaFrameCallback )
            else
                local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
                newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
            end
        end )
        --]]
    else

        -- local levelConfig = LevelDataManager.sharedLevelData().levelDatas[ step.level ]
        if AIPlayQAAdjustManager:getSwitch() then
            AIPlayQAAdjustManager:startLevel( startLevelData.levelCfg , qaAdjustPara , qaFrameCallback )
        else
            -- self:log( AIPlayLogChannel.LOG , "__startLevel NewStartLevelLogic:create  step.selectedItemsData =" , table.tostring(step.selectedItemsData) )
            local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
            newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
        end
    end
end

function AIGamePlayManager:startLevel()

    local function doAction() 

        self.customContext = {}

        if self.playMode == AIPlayMode.kEditorAutoPlayV2 then
            self:__startLevelV2()
        else
            self:__startLevel()
        end
    end

    local function onError(errMsg) 
        errMsg = errMsg or ""
        he_log_error( "MCT ERROR " .. tostring(errMsg) .. "\n" .. debug.traceback() )
    end 

    local status, msg = xpcall( doAction , __G__TRACKBACK__ )
    if not status then
        self:log( AIPlayLogChannel.CRASH , "AIGamePlayManager startLevel  Crash : " , msg )
    end

    playCount = playCount + 1
end

local batchIdMap = {}






function AIGamePlayManager:__getNextStepV2( gameboardlogic , actions , callback )


    local maxstep = 200
    if self.getStepCount > maxstep then

        local failReason = AutoCheckLevelFinishReason.kOverTooMushStep

        if gameboardlogic.PlayUIDelegate then
            gameboardlogic.PlayUIDelegate:replayResult(
                                gameboardlogic.PlayUIDelegate.levelId, 
                                gameboardlogic.totalScore, 
                                gameboardlogic.gameMode:getScoreStarLevel(), 
                                0, 0, 0, false, failReason )
        end
        return nil
    end

    self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:__getNextStep  p0  realCostMove:" , gameboardlogic.realCostMove )

    local simplejson = require("cjson")

-- local resp = '{"method":"playout"}' 
    
    local mime = require("mime.core")

    
    local function doNextStepWithAI2()

        if self.startLevelData.configData.foolMode or self.startLevelData.configData.propMode then

            if self.startLevelData.configData.propMode and math.random() < 0.3 then 

                local ri = math.random( 1 , 7 )
                local pid = propModeConfig[ri].propId
                local maxCount = propModeConfig[ri].maxCount

                if not self.startLevelData.configData.propModeMap["p" .. tostring(pid)] then
                    self.startLevelData.configData.propModeMap["p" .. tostring(pid)] = 0
                end

                local currCount = self.startLevelData.configData.propModeMap["p" .. tostring(pid)]

                if currCount < maxCount then
                    self.startLevelData.configData.propModeMap["p" .. tostring(pid)] = currCount + 1

                    local nextStepCmd = {}
                    -- { propId = 10001 , maxCount = 6 },-- 10001 刷新
                    -- { propId = 10002 , maxCount = 6 },-- 10002 后退
                    -- { propId = 10003 , maxCount = 3 },-- 10003 强制交换
                    -- { propId = 10005, maxCount = 3 },-- 10005 魔法棒
                    -- { propId = 10010 , maxCount = 3 },-- 10010 小木槌
                    -- { propId = 10105 , maxCount = 3 },-- 10105 横排火箭
                    -- { propId = 10109 , maxCount = 3 }-- 10109 竖列火箭
                    nextStepCmd.action = { propId = pid }
                    nextStepCmd.dataType = "prop"

                    if pid == 10001 or pid == 10002 then --刷新和后退
                        --do nothing
                    elseif pid == 10010 or pid == 10105 or pid == 10109 or pid == 10005 then--小木槌，横排火箭，竖列火箭，魔法棒
                        local gameboardlogic = GameBoardLogic:getInstance()

                        local _list = {}

                        for r = 1, #gameboardlogic.gameItemMap do
                            for c = 1, #gameboardlogic.gameItemMap[r] do
                                local item = gameboardlogic.gameItemMap[r][c]
                                if pid == 10010 and item:canBeEffectByHammer() then
                                    table.insert( _list , { r = r , c = c } )     
                                elseif pid == 10005 and item.ItemType == GameItemType.kAnimal and item:isVisibleAndFree() then
                                    table.insert( _list , { r = r , c = c } )  
                                elseif item:canBeEffectByLineEffectProp() then
                                    table.insert( _list , { r = r , c = c } )      
                                end
                            end
                        end

                        local pos = _list[ math.random( 1 , #_list ) ]

                        nextStepCmd.action.r1 = pos.r
                        nextStepCmd.action.c1 = pos.c

                        if pid == 10005 then
                            if math.random(1,2) == 1 then
                                nextStepCmd.action.para = { lineBrushType = "H" }
                            else
                                nextStepCmd.action.para = { lineBrushType = "V" }
                            end
                        end

                    elseif pid == 10003 then--强制交换

                        local _list = {}

                        for r = 1, #gameboardlogic.gameItemMap do
                            for c = 1, #gameboardlogic.gameItemMap[r] do
                                
                                local item = gameboardlogic.gameItemMap[r][c]
                                
                                if item.ItemType == GameItemType.kAnimal and item:isVisibleAndFree() then
                                    
                                    local function checkSideItem( _r , _c )
                                        local _item = nil
                                        if gameboardlogic.gameItemMap[_r] then
                                            _item = gameboardlogic.gameItemMap[_r][_c]
                                        end

                                        if _item and _item.ItemType == GameItemType.kAnimal and _item:isVisibleAndFree() then
                                            return true
                                        end
                                        return false
                                    end     

                                    if checkSideItem( r , c + 1 ) then
                                        table.insert( _list , { r1 = r , c1 = c , r2 = r , c2 = c + 1  } )  
                                    elseif checkSideItem( r , c - 1 ) then
                                        table.insert( _list , { r1 = r , c1 = c , r2 = r , c2 = c - 1  } )  
                                    elseif checkSideItem( r + 1 , c ) then
                                        table.insert( _list , { r1 = r , c1 = c , r2 = r + 1 , c2 = c  } )  
                                    elseif checkSideItem( r - 1 , c ) then
                                        table.insert( _list , { r1 = r , c1 = c , r2 = r - 1 , c2 = c  } )  
                                    end
                                    
                                end
                            end
                        end

                        if #_list > 0 then

                            local pos = _list[ math.random( 1 , #_list ) ]

                            nextStepCmd.action.r1 = pos.r1
                            nextStepCmd.action.c1 = pos.c1
                            nextStepCmd.action.r2 = pos.r2
                            nextStepCmd.action.c2 = pos.c2

                        else
                            nextStepCmd.action.propId = 10001
                        end

                    end

                    nextStepCmd.method = "nextStep"

                    if callback then callback( true , nextStepCmd ) end
                end

            else
                if math.random() < 0.3 then

                    local nextStepCmd = {}
                    if gameboardlogic.isFullFirework then
                        -- doUseProp(0, 0, 0, 0, GamePropsType.kMoleWeeklyRaceSPProp)
                        nextStepCmd.action = function () gameboardlogic:useMegaPropSkill( false , false , true , false) end
                        nextStepCmd.dataType = "function"
                    else
                        local possibleSwapList = nil
                        if math.random(0,9) < 1 then
                            possibleSwapList = SwapItemLogic:calculatePossibleSwap( gameboardlogic , {PossibleSwapPriority.kNormal4})
                        end
                        if not possibleSwapList or #possibleSwapList == 0 then
                            possibleSwapList = SwapItemLogic:calculatePossibleSwap( gameboardlogic )
                        end

                        local targetPossibleSwap = possibleSwapList[math.random(#possibleSwapList)]
                        local r1 = targetPossibleSwap[1].r
                        local c1 = targetPossibleSwap[1].c
                        local r2 = r1 + targetPossibleSwap["dir"].r
                        local c2 = c1 + targetPossibleSwap["dir"].c

                        nextStepCmd.action = { r1 = r1 , c1 = c1 , r2 = r2 , c2 = c2 }
                        nextStepCmd.dataType = "rc"
                    end
                    nextStepCmd.method = "nextStep"

                    if callback then callback( true , nextStepCmd ) end
                    return
                end
            end
            
        end

        local simplejson = require("cjson")

        local state = table.serialize(SnapshotManager:getStepState(gameboardlogic))
        state = compress(state)
        state = mime.b64(state)

        local detail = {
                        score = gameboardlogic.totalScore ,
                        actionList = table.keys(actions) ,
                        snap = state ,  
                    }

        local getNextStepResp = self:sendMsgToSocket( "getNextStep" , detail )

        if getNextStepResp then
            getNextStepResp.method = "nextStep"
            if callback then callback( true , getNextStepResp ) end
        end
    end

    local breakAfterAll = false
    if gameboardlogic.gameBoardModel then
        breakAfterAll = gameboardlogic:getBoardModel().AIPlayQAAdjustBreakAfterAll
    else
        breakAfterAll = gameboardlogic.AIPlayQAAdjustBreakAfterAll
    end

    if AIPlayQAAdjustManager:getSwitch() and (not breakAfterAll) then

        local function onQANextStep( result , response , body )
            
            if result and body.code >= 200 then
                local action = body.action
                
                if action.breakAfterAll then
                    if gameboardlogic.gameBoardModel then
                        gameboardlogic:getBoardModel().AIPlayQAAdjustBreakAfterAll = true
                    else
                        gameboardlogic.AIPlayQAAdjustBreakAfterAll = true
                    end
                end
                
                if action.type == "swap" then
                    if AIGamePlayManager.DebugMode then
                        self:log( AIPlayLogChannel.LOG , "QANextStep:doSwap  ! " , table.serialize(action) )
                    end
                    AIPlayQAAdjustManager:doSwap( action )
                elseif action.type == "prop" then
                    if AIGamePlayManager.DebugMode then
                        self:log( AIPlayLogChannel.LOG , "QANextStep:doUserProp  ! " , table.serialize(action) )
                    end
                    AIPlayQAAdjustManager:doUserProp( action )
                else
                    if AIGamePlayManager.DebugMode then
                        self:log( AIPlayLogChannel.LOG , "QANextStep:UseAIResult  ! " , table.serialize(body) )
                    end
                    doNextStepWithAI2()
                end
            else
                if AIGamePlayManager.DebugMode then
                    self:log( AIPlayLogChannel.ERROR , "QANextStep:Error  !" , table.serialize(response) )
                end
                local mainlogic = GameBoardLogic:getInstance()
                mainlogic.PlayUIDelegate:replayResult(
                                    mainlogic.PlayUIDelegate.levelId, 
                                    mainlogic.totalScore, 
                                    mainlogic.gameMode:getScoreStarLevel(), 
                                    0, 0, 0, false, AutoCheckLevelFinishReason.kQANextLevelErr , table.serialize(response) )
            end
        end
        local sectionData = SectionResumeManager:getCurrSectionData()
        local dataTable = SectionResumeManager:encodeBySection( sectionData )

        dataTable.canSwaps = SwapItemLogic:calculatePossibleSwap(GameBoardLogic:getInstance(), nil, true)

        local jsonStr = table.serialize( dataTable )
        local snapStr = mime.b64( compress(jsonStr) )
        
        self:log( AIPlayLogChannel.LOG , "try get QANextStep ......... step:" , gameboardlogic.realCostMove )

        AIPlayQAAdjustManager:getNextStep( snapStr , onQANextStep )
    else
        doNextStepWithAI2()
    end

end

function AIGamePlayManager:__getNextStepForCheckReplay( gameboardlogic , callback )

    -- printx( 1 , "AIGamePlayManager:__getNextStepForCheckReplay  !!!!!!!!!!" )

    -- if true then return end

    local nextStepCmd = {}

    local possibleSwapList = nil

    local stepData = nil

    if gameboardlogic.replayStep <= #gameboardlogic.replaySteps then
        stepData = gameboardlogic.replaySteps[gameboardlogic.replayStep]
    else
        if callback then callback( false , nil ) end 
        return
    end

    local r1 = stepData.x1
    local c1 = stepData.y1
    local r2 = stepData.x2
    local c2 = stepData.y2
    local propId = stepData.prop
    local propsUseType = stepData.pt
    local switchPlayer = stepData.switchPlayer

    nextStepCmd.action = { r1 = r1 , c1 = c1 , r2 = r2 , c2 = c2 }

    local resp = self:sendMsgToSocket( "playingHeartBeat" , nextStepCmd.action )

    if propId then
        nextStepCmd.dataType = "prop"
        nextStepCmd.action.propId = propId
    elseif switchPlayer then
        nextStepCmd.dataType = "switchPlayer"  --瞎写一下，不要在意
    else
        nextStepCmd.dataType = "rc"
    end

    nextStepCmd.method = "nextStep"

    if callback then callback( true , nextStepCmd ) end 
end

function AIGamePlayManager:getNextStep( gameboardlogic , actions , callback )

    local nextData = nil

    local function doAction()
        self.getStepCount = self.getStepCount + 1

        if self.playMode == AIPlayMode.kEditorAutoPlayV2 then
            if _G.AIAutoCheckReplayCheck then
                nextData = self:__getNextStepForCheckReplay( gameboardlogic , callback )
            else
                nextData = self:__getNextStepV2( gameboardlogic , actions , callback )
            end
        else
            nextData = self:__getNextStep( gameboardlogic , actions , callback )
        end
    end

    local function onError(errMsg) 
        errMsg = errMsg or ""
        he_log_error( "MCT ERROR " .. tostring(errMsg) .. "\n" .. debug.traceback() )
    end

    xpcall( doAction , __G__TRACKBACK__ )

    return nextData
end






function AIGamePlayManager:__endLevelV2( result , failReason , score , star , failDatas )
   
    local simplejson = require("cjson")
    
    local levelId = self.startLevelData.levelId
    local batchId = self.startLevelData.batchId
    local seed = self.startLevelData.seed
    local groupBatchId = self.startLevelData.groupBatchId
    local levelCfg = self.startLevelData.levelCfg
    local configData = self.startLevelData.configData
    local levelCheckParas = self.startLevelData.levelCheckParas


    local scorePoint = self:getScorePoint()
    -- local configs = self:getCurrPlayConfig()

    if result ~= 1 then
    
        -- kFinished = 1 , --正常结束
        -- kCrash = 2 , --系统级闪退（强杀进程）
        -- kLuaCrash = 3 , --代码闪退（有bug）
        -- kOverTooMushStep = 4 , --超过最大步数且没有过关
        -- kReplay_Crash = 5 , --重放时系统级闪退（强杀进程）
        -- kReplay_LuaCrash = 6 , --重放时代码闪退（有bug）
        -- kReplay_ConsistencyError = 7 , --重放结束但结果和原始情况不一致
        -- kFinishedButNotReachOneStar = 11 , --关卡结束但未达到一星
        -- kFinishedButHasNoSwap = 12 , --没有可交换的物体，关卡失败
        -- kFinishedButHasNoVenom = 13 , --没有毒液，关卡失败
        -- kEndlessLoopByPortal = 14 , --无限掉落(传送门循环)
        -- kEndlessLoopByColor = 15 , --无限掉落（无限三消）
        -- kUnexpectedStoped = 16 , --意外停止，原因不明

        if failReason == "refresh" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoSwap
        elseif failReason == "venom" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoVenom
        end

        
        if configData and not configData.fastMode then
            if not failReason then
                failReason = AutoCheckLevelFinishReason.kFinishedButNotReachOneStar
            end
        end

        result = failReason or 0
    end

    if type(result) == 'number' and result ~= 0 and result ~= 1 then

        local failReason = tostring(result)

        local filename_section = 'section_' .. batchId .. '_' .. levelId .. '_' .. failReason
        local filename_snap = 'snap_' .. batchId .. '_' .. levelId .. '_' .. failReason

        local pathname_section = HeResPathUtils:getUserDataPath() .. "/" .. filename_section
        local pathname_snap = HeResPathUtils:getUserDataPath() .. "/" .. filename_snap

        
        local function _process( sz )
            sz = compress(sz)
            sz = mime.b64(sz)
            return sz
        end

        if GameBoardLogic:getInstance() ~= nil then

            if not HeFileUtils:exists( pathname_section ) then

                pcall( function () 
                    local sectionData = SectionResumeManager:getCurrSectionData()
                    local dataTable = SectionResumeManager:encodeBySection( sectionData )
                    dataTable.canSwaps = SwapItemLogic:calculatePossibleSwap(GameBoardLogic:getInstance(), nil, true)
                    local jsonStr = table.serialize( dataTable )
                    Localhost:safeWriteStringToFile( jsonStr , pathname_section)
                    Localhost:safeWriteStringToFile( _process(jsonStr) , pathname_section .. '.zzz')


                    local snapData = table.serialize(SnapshotManager:getStepState(GameBoardLogic:getInstance()))
                    Localhost:safeWriteStringToFile( snapData , pathname_snap)
                    Localhost:safeWriteStringToFile( _process(snapData) , pathname_snap .. '.zzz')
                end )

            end
        end
    end

    local replayData = ReplayDataManager:getCurrLevelReplayDataCopyWithoutSectionData() or {}
    local logic = GameBoardLogic:getCurrentLogic()

    local useAddStep = true

    if logic and not scorePoint and GamePlayContext:getInstance().inLevelAndInited then
        self:checkAndSetScorePoint( logic )
        scorePoint = self:getScorePoint()

        useAddStep = false
    end

    

    if logic and scorePoint and configData and GamePlayContext:getInstance().inLevelAndInited then

        local realResult = result
        local realScore = score
        local realStar = star

        local diff1 = -9999  --不用加五步，关卡成功时的剩余步数
        local diff2 = -9999  --使用加五步过关，实际使用步数 - 关卡配置步数的差值
        local diff3 = -9999  --Diff2的数值除以5，并向上取整
        local diff4 = -9999  --不用加五步，关卡失败时，搜集目标进度的百分比的平均数
        local diff5 = -9999  --不用加五步，关卡失败时，搜集目标进度的值（字符串）

        local scoreSnapCount = #scorePoint.scoreSnaps
        local sp = scorePoint.scoreSnaps[1]


        if useAddStep then
            --使用了加五步才过关
            if result == 1 then
                realResult = 0
            end

            local staticLevelMoves = logic.staticLevelMoves or logic:getBoardModel().staticLevelMoves
            local realCostMove = logic.realCostMove or logic:getBoardModel().realCostMove
            local diffMoves = realCostMove - staticLevelMoves
            local ysmove = diffMoves % 5
            local bcount = 0
            if ysmove ~= 0 then
                bcount = 5 - ysmove
            end
            diff2 = ( scoreSnapCount * 5 ) - bcount
            diff3 = scoreSnapCount
            --[[
                解释一哈，为毛要这么算
                看起来，好像直接用 realCostMove - staticLevelMoves 就是我们要的diff2的值
                但是实际上，staticLevelMoves不是关卡原本的步数，而是关卡配置记录的这关的初始化剩余步数
                初始化剩余步数等于这关的静态可用步数吗？不一定！
                关卡内有一种情况：开局的静态步数很少（比如只有5步），但是棋盘内有加五步气球，如果你在五步内消掉了气球，那么就开启下一个气球，否则就失败
                这样的关卡，可能预埋了多个气球，实际的可用步数大于staticLevelMoves
                只有两种情况玩家会使用加五步：
                    1，气球没消完，步数用完了，没过关
                    2，气球消完了，步数用完了，没过关

                以上两种情况，diff2需要正确统计的都是玩家实际购买加五步并额外消耗的步数
                
                这样即使玩家执行如下复杂的操作，如何保证diff2的结果是准确的？
                    消除了气球，得到免费步数；
                    步数用完了，还有气球没消完，没过关，使用加五步道具续命；
                    继续消除，气球全部消完了，又得到了免费步数
                    步数又用完了，棋盘上也没有气球了，没过关，使用加五步道具续命；
                    最后剩余2步过关

                最终算法如上所示：
                加五步使用次数 * 5 - (5-（realCostMove - staticLevelMoves）取余5的余数)
            ]]

        else
            --未使用加五步就过关
            if realResult == 1 then
                diff1 = (logic.staticLevelMoves or logic:getBoardModel().staticLevelMoves) - sp.realCostMove
            end
        end

        if realResult == 0 then
            local progressData = sp.progressData

            local diffRate = 0 
            local diffRateStr = ""

            local total_tv = 0
            local total_cv = 0
            for k,v in ipairs( progressData ) do

                total_tv = total_tv + v.tv
                if v.cv <= v.tv then
                    total_cv = total_cv + v.cv
                end

                local r = (v.tv - v. cv) / v.tv
                if r > 1 then r = 1 end
                diffRate = diffRate + r

                if diffRateStr == "" then
                    diffRateStr = tostring(v.ty) .. "_" .. tostring(v.cv) .. "_" .. tostring(v.tv)
                else
                    diffRateStr = diffRateStr .. "|" .. tostring(v.ty) .. "_" .. tostring(v.cv) .. "_" .. tostring(v.tv)
                end
            end
            diffRate = diffRate / #progressData

            -- diff4 = diffRate
            if total_tv == 0 then
                diff4 = 0
            else
                diff4 = ( total_tv - total_cv ) / total_tv
            end
            
            diff5 = diffRateStr
        end

        realScore = sp.score
        realStar = sp.star

        replayData.aiDiffResults = {}
        replayData.aiDiffResults.diff1 = diff1
        replayData.aiDiffResults.diff2 = diff2
        replayData.aiDiffResults.diff3 = diff3
        replayData.aiDiffResults.diff4 = diff4
        replayData.aiDiffResults.diff5 = diff5
        replayData.aiDiffResults.realResult = realResult
        replayData.aiDiffResults.realScore = realScore
        replayData.aiDiffResults.realStar = realStar
    end

    self:log( AIPlayLogChannel.LOG , "__endLevelV2:endLevel  9" )

    replayData.scoreSnapsData = scorePoint

    replayData.aiReplayMode = true
    replayData.aiResult = result
    replayData.aiFailData = failDatas
    replayData.levelCheckParas = levelCheckParas


    if configData then
        replayData.AIAutoPLayConfig = configData.oringinConfig
    end
    -------------------------------------------------------------

    local realResultCode = result
    if replayData.aiDiffResults and replayData.aiDiffResults.realResult then
        realResultCode = replayData.aiDiffResults.realResult
    end

    local statisticalFail = realResultCode ~= 1

    if realResultCode == AutoCheckLevelFinishReason.kOverTooMushStep 
        or realResultCode == AutoCheckLevelFinishReason.kFinishedButNotReachOneStar 
        or realResultCode == AutoCheckLevelFinishReason.kFinishedButHasNoSwap 
        or realResultCode == AutoCheckLevelFinishReason.kFinishedButHasNoVenom 
        then

        statisticalFail = true
    else
        statisticalFail = false
    end

    local extraData = {}
    extraData.resultCode = result
    extraData.realResultCode = realResultCode
    extraData.statisticalFail = statisticalFail
    extraData.failReason = failReason
    
    extraData.replayData = replayData
    local levelConfigData = LevelDataManager.sharedLevelData().levelDatas[levelId]
    if levelConfigData and levelConfigData.scoreTargets then
        extraData.scoreTargets = scoreTargets
    end

    if logic:getBoardModel() then
        extraData.bonusTimeScore = logic:getBoardModel().bonusTimeScore
    else
        extraData.bonusTimeScore = logic.bonusTimeScore
    end
    
    -- extraData.diffResults = replayData.aiDiffResults

    local detail = {
                    resultCode = realResultCode ,
                    batchId = batchId ,
                    levelId = levelId ,
                    seed = seed ,
                    score = score ,
                    star = star ,

                    extraData = extraData
                }

    local endLevelResp = self:sendMsgToSocket( "endLevel" , detail )

end

function AIGamePlayManager:__endLevelForCheckReplay( result , failReason , score , star , failDatas )
    
    local levelId = self.startLevelData.levelId
    local batchId = self.startLevelData.batchId
    local seed = self.startLevelData.seed
    local groupBatchId = self.startLevelData.groupBatchId
    local levelCfg = self.startLevelData.levelCfg
    local configData = self.startLevelData.configData
    local levelCheckParas = self.startLevelData.levelCheckParas


    local scorePoint = self:getScorePoint()
    -- local configs = self:getCurrPlayConfig()

    if result ~= 1 then

        if failReason == "refresh" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoSwap
        elseif failReason == "venom" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoVenom
        end

        result = failReason or 0
    end

    local extraData = {}
    extraData.failReason = failReason
    extraData.failDatas = failDatas
    extraData.checkResult = tostring(score) .. "_" .. tostring(star)

    local detail = {
                    resultCode = result ,
                    taskId = configData.groupBatchId ,
                    batchId = batchId ,
                    levelId = levelId ,
                    seed = seed ,
                    score = score ,
                    star = star ,

                    extraData = extraData
                }

    local endLevelResp = self:sendMsgToSocket( "endLevel" , detail )

end

function AIGamePlayManager:endLevelByErrorAndReboot( errorCode , errorDatas , score , star )
    local simplejson = require("cjson")

    local levelId = self.startLevelData.levelId
    local batchId = self.startLevelData.batchId
    local seed = self.startLevelData.seed
    local groupBatchId = self.startLevelData.groupBatchId
    local levelCfg = self.startLevelData.levelCfg
    local configData = self.startLevelData.configData
    local levelCheckParas = self.startLevelData.levelCheckParas

    local replayData = ReplayDataManager:getCurrLevelReplayDataCopyWithoutSectionData() or {}

    replayData.aiReplayMode = true
    replayData.aiResult = errorCode
    replayData.aiFailData = errorDatas

    local extraData = {}
    extraData.resultCode = 0
    extraData.realResultCode = errorCode
    extraData.statisticalFail = false
    extraData.failReason = errorCode
    
    extraData.replayData = replayData


    local detail = {
                    resultCode = errorCode ,
                    batchId = batchId ,
                    levelId = levelId ,
                    seed = seed ,
                    score = score ,
                    star = star ,

                    extraData = extraData
                }

    local endLevelResp = self:sendMsgToSocket( "endLevel" , detail )

    self:reboot()
end

function AIGamePlayManager:endLevelByCrash( datas )
    self:endLevelByErrorAndReboot( AutoCheckLevelFinishReason.kLuaCrash , datas )
end

function AIGamePlayManager:endLevel( result , failReason , score , star , failDatas , callback , passQAAdjust )
    self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:endLevel result:" , result , "failReason:" , failReason , score , star , failDatas )
    -- self:log( AIPlayLogChannel.LOG , "AIGamePlayManager:endLevel traceback:" , debug.traceback() )
    local function doAction()

        local function onQAEndLevel( qaResult , response , body)
            
            self:log( AIPlayLogChannel.LOG , "QAEndLevel    qaResult:" , qaResult , "response.httpCode =" , response.httpCode )

            if qaResult and body.code == 200 then
                if self.playMode == AIPlayMode.kEditorAutoPlayV2 then
                    self:__endLevelV2( result , failReason , score , star , failDatas )
                else
                    self:__endLevel( result , failReason , score , star , failDatas )
                end
                if callback then callback() end
            else
                -- self:__endLevel( false , AutoCheckLevelFinishReason.kQAEndLevelErr , score , star , table.serialize(response) )
                local mainlogic = GameBoardLogic:getInstance()
                mainlogic.PlayUIDelegate:replayResult(
                            mainlogic.PlayUIDelegate.levelId, 
                            mainlogic.totalScore, 
                            mainlogic.gameMode:getScoreStarLevel(), 
                            0, 0, 0, false, AutoCheckLevelFinishReason.kQAEndLevelErr , table.serialize(response) , true )
            end
            
        end

        if AIPlayQAAdjustManager:getSwitch() and (not passQAAdjust) then
           AIPlayQAAdjustManager:endLevel( result , onQAEndLevel ) 
        else
            if self.playMode == AIPlayMode.kEditorAutoPlayV2 then
                if _G.AIAutoCheckReplayCheck then
                    self:__endLevelForCheckReplay( result , failReason , score , star , failDatas )
                else
                    self:__endLevelV2( result , failReason , score , star , failDatas )
                end
            else
                self:__endLevel( result , failReason , score , star , failDatas )
            end
            if callback then callback() end
        end
        
    end

    local function onError(errMsg) 
        errMsg = errMsg or ""
        self:log( AIPlayLogChannel.ERROR , "AIGamePlayManager endLevel onError  " , errMsg , "\n" , debug.traceback() )
    end

    xpcall( doAction , __G__TRACKBACK__ )

end



function AIGamePlayManager:checkAndSetScorePoint( gameboardlogic )

    if not self.scorePointData then
        self.scorePointData = {}
        self.scorePointData.staticLevelMoves = gameboardlogic.staticLevelMoves or gameboardlogic:getBoardModel().staticLevelMoves
        self.scorePointData.scoreSnaps = {}
    end

    local datas = {}

    datas.realCostMove = gameboardlogic.realCostMove
    datas.score = gameboardlogic.totalScore
    datas.star = gameboardlogic.gameMode:getScoreStarLevel()


    local result , fuuuLogID , progressData = FUUUManager:lastGameIsFUUU( false , false )

    datas.fuuu = result
    datas.progressData = progressData


    table.insert( self.scorePointData.scoreSnaps , datas )
end

function AIGamePlayManager:getScorePoint()
    return self.scorePointData
end






--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


























-- old version , to be deleted ...
function AIGamePlayManager:__startLevel()

    local step = nil 

    ReplayDataManager:addMctsLogs( "NEW" , { method = "__startLevel 1" } )

    local function updateLevelConfig( levelId , levelMetaTabel )
        levelMetaTabel.totalLevel = levelId
        LevelMapManager:getInstance():addDevMeta( levelMetaTabel )

        local levelMeta = LevelMapManager.getInstance():getMeta( levelId )
        local levelConfig = LevelConfig:create(levelId, levelMeta)
        LevelDataManager.sharedLevelData().levelDatas[levelId] = levelConfig
    end

    local function qaFrameCallback( result , response , body )

        if AIGamePlayManager.DebugMode then
            local log = {}
            log.method = "qa_startLevel result:" .. tostring(result) .. "    response:" .. table.serialize( response )
            ReplayDataManager:addMctsLogs("qaFrame", log )
        end
        

        if result and body.code == 200 then
            ReplayDataManager:addMctsLogs( "NEW" , { method = "__startLevel 9.3" } )
            local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
            newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
        else
            ReplayDataManager:addMctsLogs( "NEW" , { method = "__startLevel 9.4" } )
            self:__endLevel( false , AutoCheckLevelFinishReason.kQAStartLevelErr , 0 , 0 , table.serialize( response ) )
            ReplayDataManager:clearMctsLogs()
            self:startLevel()
        end
    end

    if playCount > autoBootCount then
        self:reboot()
        return
    end

    _G.__startTime = os.time()

    self.scorePointData = nil
    self.playout = false

    local levelId = _G.launchCmds.level
    local taskConfigData = nil
    local simplejson = require("cjson")
    local resp = '{"method":"start","level":' .. (levelId or 200) .. ',"seed":' .. (_G.launchCmds.seed or 1) .. '}' 
    local cmd = nil
    local startLevelResp = nil

    if _G.AutoCheckLeakInLevel then
        self.autoCheckLeakTag = tostring( _G.__startTime )
        startObjectRefDebug(self.autoCheckLeakTag, levelId)
    end

    if self.playMode == AIPlayMode.kEditorAutoPlay then

        local redisClient = _G.redisClient
        if not redisClient then
            local redis = require 'zoo.util.redis'
            redisClient = redis.connect( self.REDIS_HOST , 6379)
            redisClient:auth("animal_2017")
            _G.redisClient = redisClient
        end

        local function getTaskFromRedis( queueOrder )
            
            for k,v in ipairs( queueOrder ) do
                local t = redisClient:brpop( v , 1 )
                if t then
                    return t , v
                end
            end

            return nil
        end

        local msg = nil

        local cnnNames = {
            kNormal = "cnn_tasks" ,
            kQA = "cnn_tasks_qa" ,
            kTOP = "cnn_tasks_top" , 
            kBG = "cnn_tasks_bg" ,
        }

        if self.IS_DEV_MODE or _G.launchCmds.ai_dev then
            cnnNames = {
                kNormal = "cnn_dev_tasks" ,
                kQA = "cnn_dev_tasks_qa" ,
                kTOP = "cnn_dev_tasks_top" , 
                kBG = "cnn_dev_tasks_bg" ,
            }
        end

        if AIGamePlayManager.DebugMode then
            local log = {}
            log.method = "New startMctsLevel getTaskFromRedis 1  ttt123"
            ReplayDataManager:addMctsLogs(7,log)
        end

        while not msg do

            local cn = self.taskRateMap.count % 8
            
            ----[[
            if cn == 0 then
                msg = getTaskFromRedis( { cnnNames.kBG , cnnNames.kTOP , cnnNames.kNormal , cnnNames.kQA } )
            elseif cn == 7 then
                msg = getTaskFromRedis( { cnnNames.kTOP , cnnNames.kNormal , cnnNames.kQA , cnnNames.kBG } )
            elseif cn == 1 or cn == 3 or cn == 5 then
                msg = getTaskFromRedis( { cnnNames.kTOP , cnnNames.kQA , cnnNames.kNormal , cnnNames.kBG } )
            else
                msg = getTaskFromRedis( { cnnNames.kBG , cnnNames.kTOP , cnnNames.kQA , cnnNames.kNormal } )
            end
            --]]

            --[[
            if cn == 0 then
                msg = getTaskFromRedis( { "cnn_tasks_top" , "cnn_tasks" , "cnn_tasks_qa" } )
            elseif cn == 7 then
                msg = getTaskFromRedis( { "cnn_tasks_top" , "cnn_tasks" , "cnn_tasks_qa" } )
            elseif cn == 1 or cn == 3 or cn == 5 then
                msg = getTaskFromRedis( { "cnn_tasks_top" , "cnn_tasks_qa" , "cnn_tasks" } )
            else
                msg = getTaskFromRedis( { "cnn_tasks_top" , "cnn_tasks_qa" , "cnn_tasks" } )
            end
            ]]

        end

        self.taskRateMap.count = self.taskRateMap.count + 1

        local task = simplejson.decode(msg[2])
        levelId = task.l
        local batchId = (task.b or 0)
        local levelSeed = task.s
        _G.cnnTask = task

        resp = '{"method":"start","level":' .. (levelId or 50) .. ',"seed":' .. (levelSeed or 0) .. '}' 

        if AIGamePlayManager.DebugMode then
            local log = {}
            log.method = "New startMctsLevel task.l = " .. tostring(task.l) .. "  task.b = " .. tostring(task.b) .. "  task.s = " .. tostring(task.s)
            ReplayDataManager:addMctsLogs(7,log)
        end
        
        if false and self.playConfigMap[ batchId ] then
            self.currPlayConfig = self.playConfigMap[ batchId ]
        else
            local testConfStr = redisClient:get("cnn_conf_" .. batchId)
            taskConfigData = table.deserialize(testConfStr)

            if taskConfigData then
                self.currPlayConfig = taskConfigData
                self.currPlayConfig.originConfigStr = testConfStr
            else
                -- local log = {}
                -- log.method = "startLevel cnn_conf Error:" .. "    testConfStr:" .. tostring(testConfStr) .. "  batchId:" .. tostring(batchId)
                -- ReplayDataManager:addMctsLogs("Error", log )

                self:__endLevel( false , AutoCheckLevelFinishReason.kCNNConfigErr , 0 , 0 , "configStr:" .. tostring(testConfStr) )
                ReplayDataManager:clearMctsLogs()
                self:startLevel()
            end
        end

        if self.currPlayConfig then
            local levelConf = self.currPlayConfig.levelCfg
            updateLevelConfig( levelId , levelConf )
        end

        cmd = simplejson.decode(resp)
    elseif self.playMode == AIPlayMode.kAI then
        resp = StartupConfig:getInstance():receiveMsg()
        cmd = simplejson.decode(resp)
    end


    if cmd and cmd.method == "start" then
        if cmd.snap then
            _G.__startCmd = cmd
        end
        step = {randomSeed = cmd.seed, replaySteps = {}, level = cmd.level, selectedItemsData = {}}

        

        local preProp = {}

        if self.currPlayConfig then
            math.randomseed(os.time())

            -- step.mctsData = {}
            -- step.mctsData.ver = taskConfigData.ver
            -- step.mctsData.sourceType = taskConfigData.sourceType
            -- step.mctsData.adjustEnable = taskConfigData.adjustEnable
            -- step.mctsData.fastMode = taskConfigData.fastMode

            -- self.currPlayConfig.adjustEnable = false

            if self.currPlayConfig.fastMode == 2 then
                self.currPlayConfig.foolMode = true
            end

            if self.currPlayConfig.fastMode == 1 then
                self.currPlayConfig.fastMode = true
            else
                self.currPlayConfig.fastMode = false
            end

            -- self.currPlayConfig.fastMode = true

            if self.currPlayConfig.preProp == 1 then
                table.insert( preProp , { id = 10087} )
                table.insert( preProp , { id = 10099} ) -- replace later
                table.insert( preProp , { id = 10018} )
                table.insert( preProp , { id = 10015} )
                table.insert( preProp , { id = 10007} )
                -- table.insert( preProp , { id = 10099} )
            elseif self.currPlayConfig.preProp == 2 then
                if math.random() < 0.4 then
                    if math.random() < 0.8 then table.insert(preProp , { id = 10087} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10099} ) end -- replace later
                    if math.random() < 0.8 then table.insert(preProp , { id = 10018} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10015} ) end
                    if math.random() < 0.8 then table.insert(preProp , { id = 10007} ) end
                    -- if math.random() < 0.8 then table.insert(preProp , { id = 10099} ) end
                end
            elseif self.currPlayConfig.preProp == 3 then
                table.insert( preProp , { id = 10018} )
                table.insert( preProp , { id = 10015} )
                table.insert( preProp , { id = 10007} )
            elseif self.currPlayConfig.preProp == 4 then
                table.insert( preProp , { id = 10018} )
                table.insert( preProp , { id = 10007} )
            elseif self.currPlayConfig.preProp == 5 then
                table.insert( preProp , { id = 10087} )
                table.insert( preProp , { id = 10099} ) -- replace later
                -- table.insert( preProp , { id = 10099} )
            elseif self.currPlayConfig.preProp == 9999 then
                if self.prePropRateData and #self.prePropRateData > 0 then
                    
                    local randomArr = {}

                    for k,v in ipairs( self.prePropRateData ) do
                        table.insert( randomArr , tonumber(v.rate) )
                    end

                    -- printx( 1 , "randomArr =" , table.tostring( randomArr ) )
                    
                    local ranI = math.random()
                    local idx = 0
                    for i = 1 , #randomArr do
                        local w = 0
                        for ia = 1 , i do
                            w = w + randomArr[ia]
                        end

                        if ranI <= w then
                            idx = i
                            break
                        end
                    end

                    if idx > 0 then
                        local str = self.prePropRateData[idx].propsType
                        local proplist = string.split( str , "_" )

                        if proplist and #proplist > 0 then
                            for k2 , v2 in ipairs(proplist) do
                                table.insert( preProp , { id = tonumber(v2) } )
                            end
                        end
                    end
                end
            end

            AIPlayQAAdjustManager:setSwitch( false )

            -- if AIGamePlayManager.DebugMode then
            --     ReplayDataManager:addMctsLogs( "N2" , {method="customParam  1  step:  " .. tostring(step)  } )
            -- end

            if self.currPlayConfig.customParam and self.currPlayConfig.customParam ~= "" then
                local str = self.currPlayConfig.customParam
                local strlen = string.len( str )
                local yn = strlen % 4
                if yn > 0 then
                    local fixstr = ""
                    for i = 1 , yn do
                        fixstr = fixstr .. "="
                    end
                    str = str .. fixstr
                end
                local jsonstr = mime.unb64(str)

                -- if AIGamePlayManager.DebugMode then
                --     ReplayDataManager:addMctsLogs( "N2" , {method="customParam  2  jsonstr:  " .. tostring(jsonstr)  } )
                -- end

                self.currPlayConfig.customParamTable = table.deserialize( jsonstr )

                if self.currPlayConfig.customParamTable then
                    -- if not self.currPlayConfig.customParamTable then
                    --     local jsonstr = mime.unb64(str)
                    --     self.currPlayConfig.customParamTable = table.deserialize( jsonstr )
                    -- end

                    AIGamePlayManager.DebugMode = self.currPlayConfig.customParamTable["PRINTX"] or false

                    if self.currPlayConfig.customParamTable.xmas2019Data then
                        local xmas2019Data = self.currPlayConfig.customParamTable.xmas2019Data
                        for i = 1 , 3 do
                            local lvc = xmas2019Data["levelConfig" .. tostring(i)]
                            if lvc then
                                updateLevelConfig( lvc.totalLevel , lvc )
                                -- xmas2019Data["levelConfig" .. tostring(i)] = nil
                            end
                        end
                        step.xmas2019Data = xmas2019Data

                        -- if AIGamePlayManager.DebugMode then
                        --     ReplayDataManager:addMctsLogs( "N2" , {method="customParam  3  step:  " .. tostring(step) .. "   " .. table.serialize(step)  } )
                        -- end

                        -- local clipboardData = {}
                        -- clipboardData.xmas2019Data = xmas2019Data
                        -- CCDirector:sharedDirector():setClipboard( table.serialize( clipboardData ) ) 
                    end

                    
                    if not self.currPlayConfig.levelCheckConfigMap then
                        self.currPlayConfig.levelCheckConfigMap = {}
                    end

                    if not self.currPlayConfig.levelCheckConfigMap[levelId] then

                        local checkConfig = self.currPlayConfig.customParamTable.checkConfig

                        if checkConfig and checkConfig.checker then
                            -- levelId

                            self.currPlayConfig.checkConfig = checkConfig

                            local currLevelCheckConfig = nil

                            for k,v in ipairs( checkConfig.checker ) do
                                
                                local levelRanges = tostring( v.levelRanges )
                                local arr1 = string.split( levelRanges , "_" )
                                for k2,v2 in ipairs( arr1 ) do
                                    local arr2 = string.split( v2 , "~" )
                                    if #arr2 == 1 then
                                        if tostring(arr2[1]) == tostring(levelId) then
                                            currLevelCheckConfig = v.configs
                                            break
                                        end
                                    elseif #arr2 == 2 then

                                        local start_ = arr2[1]
                                        local end_ = arr2[2]

                                        start_ = tonumber(start_ or 0) or 0
                                        end_ = tonumber(end_ or 0) or 0

                                        local levelId_ = tonumber(levelId or -1) or -1

                                        if levelId_ >= start_ and levelId_ <= end_ then
                                            currLevelCheckConfig = v.configs
                                            break
                                        end
                                    end
                                end

                                if currLevelCheckConfig then
                                    break
                                end
                            end

                            if currLevelCheckConfig then
                                local paras = {}
                                paras.levelId = levelId
                                paras.adjustEnable = self.currPlayConfig.adjustEnable
                                paras.customParam = self.currPlayConfig.customParam
                                paras.fixedSteps = self.currPlayConfig.fixedSteps
                                paras.preProp = self.currPlayConfig.preProp
                                paras.fastMode = self.currPlayConfig.fastMode
                                paras.foolMode = self.currPlayConfig.foolMode
                                paras.checkConfig = currLevelCheckConfig

                                self.currPlayConfig.levelCheckConfigMap[levelId] = paras
                            end
                        end

                        if not self.currPlayConfig.levelCheckConfigMap[levelId] then
                            self.currPlayConfig.levelCheckConfigMap[levelId] = "PASS"
                        end
                    end
                else

                    local arr = string.split( str , "~" )

                    for k , v in pairs( arr ) do
                        if v == "EnableRandomTsumBuff_1" then
                            table.insert( preProp , { id = GamePropsType.kRandomBird_b } )
                        elseif v == "EnableRandomTsumBuff_2" then
                            table.insert( preProp , { id = GamePropsType.kLineBomb_b } )
                            table.insert( preProp , { id = GamePropsType.kWrapBomb_b } )
                        elseif v == "EnableRandomTsumBuff_3" then
                            table.insert( preProp , { id = GamePropsType.kRandomBird_b } )
                            table.insert( preProp , { id = GamePropsType.kLineBomb_b } )
                        elseif v == "EnableRandomTsumBuff_4" then
                            table.insert( preProp , { id = GamePropsType.kRandomBird_b } )
                            table.insert( preProp , { id = GamePropsType.kLineBomb_b } )
                            table.insert( preProp , { id = GamePropsType.kWrapBomb_b } )
                        elseif v == "EnableRandomTsumBuff_5" then
                            table.insert( preProp , { id = GamePropsType.kRandomBird_b } )
                            table.insert( preProp , { id = GamePropsType.kRandomBird_b } )
                            table.insert( preProp , { id = GamePropsType.kLineBomb_b } )
                        elseif v == "TEST1" then
                            step.randomSeed = 1574771674
                        end
                    end
                    
                end 
            end

            self.fixedStepData = nil 
            if self.currPlayConfig.fixedSteps then -- 格式如下：  2341_8979,2434,6656~2322_8979,2434,6656
                local str = self.currPlayConfig.fixedSteps
                local cfgdata = string.split( str , "~" )

                for k , v in pairs( cfgdata ) do

                    local data = string.split( v , "_" )
                    local needfixLevelId = data[1] 
                    local needfixStepsStr = data[2] 

                    if tostring(needfixLevelId) == tostring(cmd.level) then
                        local arr = string.split( needfixStepsStr , "," )
                        self.fixedStepData = {}
                        for k2 , v2 in ipairs( arr ) do
                            local pos = { 
                                            r1 = tonumber( string.sub( v2 , 1 , 1 ) ) , 
                                            c1 = tonumber( string.sub( v2 , 2 , 2 ) ) ,
                                            r2 = tonumber( string.sub( v2 , 3 , 3 ) ) ,
                                            c2 = tonumber( string.sub( v2 , 4 , 4 ) )
                                        }

                            table.insert( self.fixedStepData , pos )
                        end                   
                    end
                end
            end

            local needBlockByHttp = false

            local function startLevelOnNextFrame()
                local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
                newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
            end

            local function onFuuuStaticData(rst)
                setTimeOut( startLevelOnNextFrame , 0.1 )
            end

            if self.currPlayConfig.adjustEnable then
                
                if self.currPlayConfig.adjustEnable == 9999 then
                    if self.fuuuRateData then
                        local fuuudata = self.fuuuRateData[cmd.level]
                        if not fuuudata then fuuudata = self.top15fuuuRateData[1] end

                        if fuuudata then
                            local randomArr = {}
                            table.insert( randomArr , tonumber(fuuudata.none) )
                            table.insert( randomArr , tonumber(fuuudata.diff1) )
                            table.insert( randomArr , tonumber(fuuudata.diff2) )
                            table.insert( randomArr , tonumber(fuuudata.diff3) )
                            table.insert( randomArr , tonumber(fuuudata.diff4) )
                            table.insert( randomArr , tonumber(fuuudata.diff5) )
                            table.insert( randomArr , tonumber(fuuudata.fuuu) )
                            table.insert( randomArr , tonumber(fuuudata.farmFuuu) )

                            -- printx( 1 , "randomArr =" , table.tostring( randomArr ) )
                            math.randomseed(os.time())
                            local ranI = math.random()
                            local idx = 0
                            for i = 1 , #randomArr do
                                local w = 0
                                for ia = 1 , i do
                                    w = w + randomArr[ia]
                                end

                                if ranI <= w then
                                    idx = i
                                    break
                                end
                            end

                            if idx > 0 then
                                if idx == 1 then
                                    step.strategyID = nil
                                elseif idx == 2 then
                                    step.strategyID = 13100000
                                elseif idx == 3 then
                                    step.strategyID = 13200000
                                elseif idx == 4 then
                                    step.strategyID = 13300000
                                elseif idx == 5 then
                                    step.strategyID = 13400000
                                elseif idx == 6 then
                                    step.strategyID = 13500000
                                elseif idx == 7 then
                                    step.strategyID = 14100000
                                elseif idx == 8 then
                                    step.strategyID = 14100000
                                    -- step.strategyID = 15100000
                                end
                            end
                        end
                    end
                elseif self.currPlayConfig.adjustEnable == 41 then
                    -- local log = {}
                    -- log.method = "AIGamePlayManager   adjustEnable   41    uid =" .. tostring(UserManager:getInstance():getUID())
                    -- ReplayDataManager:addMctsLogs("N1",log)

                    step.strategyID = 14100000
                elseif self.currPlayConfig.adjustEnable >= 1 and self.currPlayConfig.adjustEnable <= 6 then
                    step.strategyID = 13000000 + ( 100000 * self.currPlayConfig.adjustEnable )
                elseif self.currPlayConfig.adjustEnable >= 61 and self.currPlayConfig.adjustEnable <= 65 then
                    step.strategyID = 10000000 + ( 100000 * self.currPlayConfig.adjustEnable )
                elseif self.currPlayConfig.adjustEnable == 71 then
                    step.strategyID = 17100000
                elseif self.currPlayConfig.adjustEnable == 81 then
                    step.strategyID = 18100000
                end
            end

        end


        if #preProp > 0 then
            for k,v in ipairs(preProp) do
                table.insert(step.selectedItemsData , { id = v.id } )
            end
        end

        -- if AIGamePlayManager.DebugMode then
            local log = {}
            -- log.method = "New startMctsLevel  SSSSSSSSSSSSSS  self.currPlayConfig.checkConfig = " .. table.tostring(self.currPlayConfig.checkConfig)
            log.method = "New startMctsLevel  SSSSSSSSSSSSSS  " .. debug.traceback()
            ReplayDataManager:addMctsLogs(7,log)
        -- end

        -- ReplayDataManager:addMctsLogs(7,{method = "strategyID = " .. tostring(step.strategyID) .. "  " .. tostring( type(step.strategyID) ) })

        self.getStepCount = 0

        

        local levelCheckParas = nil
        if self.currPlayConfig.levelCheckConfigMap then
            levelCheckParas = self.currPlayConfig.levelCheckConfigMap[levelId]
        end

        if levelCheckParas and levelCheckParas ~= "PASS" then
            -- if AIGamePlayManager.DebugMode then
            --     ReplayDataManager:addMctsLogs( "N2" , {method="levelCheckParas:  " .. tostring(levelCheckParas) .. " levelId:" .. tostring(levelId) } )
            -- end
            AIPlayQAAdjustManager:setSwitch( true )
        else
            -- if AIGamePlayManager.DebugMode then
            --     ReplayDataManager:addMctsLogs( "N2" , {method="levelCheckParas : " .. tostring(levelCheckParas) } )
            -- end
        end
        
        -- if AIGamePlayManager.DebugMode then
        --     --step.xmas2019Data
        --     ReplayDataManager:addMctsLogs( "N2" , {method="newStartLevelLogic:startWithReplay : " .. table.serialize( step ) .. "    step:" .. tostring(step) } )
        -- end

        if step.strategyID and ( step.strategyID == 14100000 or (step.strategyID >= 17100000 and step.strategyID <= 18100000) ) then
            -- local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
            -- newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
            ----[[

            -- local log = {}
            -- log.method = "AIGamePlayManager startLevel  p1  uid:" .. tostring(UserManager:getInstance():getUID())
            -- ReplayDataManager:addMctsLogs("N3",log)

            LevelDifficultyAdjustManager:loadSingleLevelTargetProgerssDataByAI( levelId , function ()

                -- local log = {}
                -- log.method = "AIGamePlayManager startLevel  p2  "
                -- ReplayDataManager:addMctsLogs("N3",log)

                local datastr , staticTotalSteps = LevelDifficultyAdjustManager:getLevelTargetProgressDataStrForReplay( levelId )
                step.tplist = datastr
                step.tpTotalSteps = staticTotalSteps

                -- local log = {}
                -- log.method = "AIGamePlayManager startLevel  p3  tpTotalSteps:" .. tostring(staticTotalSteps) .. "  tplist:" .. tostring(datastr)
                -- ReplayDataManager:addMctsLogs("N3",log)
                -- local levelConfig = LevelDataManager.sharedLevelData().levelDatas[ step.level ]

                if AIPlayQAAdjustManager:getSwitch() then
                    AIPlayQAAdjustManager:startLevel( self.currPlayConfig.levelCfg , levelCheckParas , qaFrameCallback )
                else
                    local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
                    newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
                end
            end )
            --]]
        else

            -- local levelConfig = LevelDataManager.sharedLevelData().levelDatas[ step.level ]
            if AIPlayQAAdjustManager:getSwitch() then
                AIPlayQAAdjustManager:startLevel( self.currPlayConfig.levelCfg , levelCheckParas , qaFrameCallback )
            else
                local newStartLevelLogic = NewStartLevelLogic:create( nil , step.level , step.selectedItemsData , false , {} )
                newStartLevelLogic:startWithReplay( ReplayMode.kMcts , step )
            end
        end
        
    else
        -- he_log_error("MCT ERROR !! you must start level now!")
    end
end













-- old version , to be deleted ...
function AIGamePlayManager:__getNextStep( gameboardlogic , actions , callback )


    local maxstep = 200
    if self.getStepCount > maxstep then

        local failReason = AutoCheckLevelFinishReason.kOverTooMushStep

        if gameboardlogic.PlayUIDelegate then
            gameboardlogic.PlayUIDelegate:replayResult(
                                gameboardlogic.PlayUIDelegate.levelId, 
                                gameboardlogic.totalScore, 
                                gameboardlogic.gameMode:getScoreStarLevel(), 
                                0, 0, 0, false, failReason )
        end
        return nil
    end
    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p0  realCostMove:" .. tostring(gameboardlogic.realCostMove)} )
    end
    -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p1"} )

    local simplejson = require("cjson")

-- local resp = '{"method":"playout"}' 
    
    local mime = require("mime.core")

    -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p1.2"} )

    -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p1.3 " .. tostring(actions) } )
    
    local function doNextStepWithAI()

        if self.currPlayConfig.foolMode then
            if math.random() < 0.3 then

                -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p0"} )

                local nextStepCmd = {}
                if gameboardlogic.isFullFirework then
                    -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p1"} )
                    -- doUseProp(0, 0, 0, 0, GamePropsType.kMoleWeeklyRaceSPProp)
                    nextStepCmd.action = function () gameboardlogic:useMegaPropSkill( false , false , true , false) end
                    nextStepCmd.dataType = "function"
                else
                    -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p2"} )
                    local possibleSwapList = nil
                    if math.random(0,9) < 1 then
                        -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p3"} )
                        possibleSwapList = SwapItemLogic:calculatePossibleSwap( gameboardlogic , {PossibleSwapPriority.kNormal4})
                        -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p4"} )
                    end
                    if not possibleSwapList or #possibleSwapList == 0 then
                        -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p5"} )
                        possibleSwapList = SwapItemLogic:calculatePossibleSwap( gameboardlogic )
                        -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p6  " .. table.tostring( possibleSwapList ) } )
                    end
                    -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p7  " .. table.tostring( possibleSwapList )} )
                    local targetPossibleSwap = possibleSwapList[math.random(#possibleSwapList)]
                    local r1 = targetPossibleSwap[1].r
                    local c1 = targetPossibleSwap[1].c
                    local r2 = r1 + targetPossibleSwap["dir"].r
                    local c2 = c1 + targetPossibleSwap["dir"].c

                    nextStepCmd.action = { r1 = r1 , c1 = c1 , r2 = r2 , c2 = c2 }
                    nextStepCmd.dataType = "rc"
                    -- ReplayDataManager:addMctsLogs( "foolMode" , {method="foolMode  p8  " .. 
                    --                                 " r1:" .. tostring(r1) ..
                    --                                 " c1:" .. tostring(c1) ..
                    --                                 " r2:" .. tostring(r2) ..
                    --                                 " c2:" .. tostring(c2)
                    --                             } )
                end
                -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p0.1"} )
                nextStepCmd.method = "nextStep"

                if callback then callback( true , nextStepCmd ) end
                return
            end
        end

        local resp = nil
        local req = {
            result = nil,
            score = gameboardlogic.totalScore,
            -- targets = self.PlayUIDelegate.levelTargetPanel:getTargets(),
            actionList = table.keys(actions),
            method = "status",
        }

        -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p2.1"} )
        local state = table.serialize(SnapshotManager:getStepState(gameboardlogic))
        -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager:__getNextStep  p2.2"} )
        state = compress(state)
        state = mime.b64(state)
        req.snap = state

        -- he_log_error(table.tostring(req.actionList))

        -- he_log_error("MCT_" .. AIGamePlayManager:getVersion() .. "  sendMsg !")
        -- ReplayDataManager:addMctsLogs( "N1" , {method="AIGamePlayManager:__getNextStep  p2"} )
        StartupConfig:getInstance():sendMsg(simplejson.encode(req))
        -- ReplayDataManager:addMctsLogs( "N1" , {method="AIGamePlayManager:__getNextStep  p3"} )
        -- he_log_error("MCT_" .. AIGamePlayManager:getVersion() .. "  receiveMsg ...")

        -- local jsonstr = Localhost:readFileRaw( HeResPathUtils:getUserDataPath() .. "/MctsLauncherData.ds" )
        -- local localdata = {}
        -- if jsonstr then localdata = table.deserialize( jsonstr ) end
        -- if not localdata.datas then localdata.datas = {} end
        
        -- table.insert( localdata.datas , "AIGamePlayManager:__getNextStep  p3  " .. tostring(localdata.launchCount) )
        -- local str = table.serialize( localdata )
        -- Localhost:safeWriteStringToFile( str , HeResPathUtils:getUserDataPath() .. "/MctsLauncherData.ds")

        resp = StartupConfig:getInstance():receiveMsg()
        
        -- table.insert( localdata.datas , "AIGamePlayManager:__getNextStep  p4  " .. tostring(localdata.launchCount) )
        -- local str2 = table.serialize( localdata )
        -- Localhost:safeWriteStringToFile( str2 , HeResPathUtils:getUserDataPath() .. "/MctsLauncherData.ds")
        
        if AIGamePlayManager.DebugMode then
            ReplayDataManager:addMctsLogs( "N1" , {method="AIGamePlayManager:__getNextStep  p4 ---" .. resp .. " realCostMove:" .. tostring(gameboardlogic.realCostMove)} )
        end
        -- he_log_error("MCT_" .. AIGamePlayManager:getVersion() .. "  receiveMsg = " .. table.tostring(resp) )

        if resp then
            
            local cmd = simplejson.decode(resp)

            if cmd.method == "nextStep" then
                if callback then callback( true , cmd ) end
                return
            else
                -- he_log_error("MCT_" .. AIGamePlayManager:getVersion() .. "  ERROR  you must send nextStep now!")
            end
        else
            -- he_log_error("MCT_" .. AIGamePlayManager:getVersion() .. "  ERROR   AIGamePlayManager:getNextStep ERR!")
        end
        
        if callback then callback( false , nil ) end
    end

    -- if AIGamePlayManager.DebugMode then
    --     ReplayDataManager:addMctsLogs( "N1" , {method="AIPlayQAAdjustManager:getSwitch :" .. tostring(AIPlayQAAdjustManager:getSwitch()) } )
    -- end
    local breakAfterAll = false
    if gameboardlogic.gameBoardModel then
        breakAfterAll = gameboardlogic:getBoardModel().AIPlayQAAdjustBreakAfterAll
    else
        breakAfterAll = gameboardlogic.AIPlayQAAdjustBreakAfterAll
    end

    if AIPlayQAAdjustManager:getSwitch() and (not breakAfterAll) then

        local function onQANextStep( result , response , body )
            -- ReplayDataManager:addMctsLogs( "N1" , {method="AIGamePlayManager:__getNextStep  QAAdjust 2  " .. tostring(result)  ..  "  response:".. table.tostring(response)} )
            if result and body.code >= 200 then
                local action = body.action
                
                if action.breakAfterAll then
                    if gameboardlogic.gameBoardModel then
                        gameboardlogic:getBoardModel().AIPlayQAAdjustBreakAfterAll = true
                    else
                        gameboardlogic.AIPlayQAAdjustBreakAfterAll = true
                    end
                end
                
                if action.type == "swap" then
                    if AIGamePlayManager.DebugMode then
                        ReplayDataManager:addMctsLogs( "N1" , {method="QANextStep:doSwap  ! " .. table.serialize(action) } )
                    end
                    AIPlayQAAdjustManager:doSwap( action )
                elseif action.type == "prop" then
                    if AIGamePlayManager.DebugMode then
                        ReplayDataManager:addMctsLogs( "N1" , {method="QANextStep:doUserProp  ! "  .. table.serialize(action) } )
                    end
                    AIPlayQAAdjustManager:doUserProp( action )
                else
                    if AIGamePlayManager.DebugMode then
                        ReplayDataManager:addMctsLogs( "N1" , {method="QANextStep:UseAIResult  ! " .. table.serialize(body) } )
                    end
                    doNextStepWithAI()
                end
            else
                if AIGamePlayManager.DebugMode then
                    ReplayDataManager:addMctsLogs( "N1" , {method="QANextStep:Error  !" .. table.serialize(response)} )
                end
                local mainlogic = GameBoardLogic:getInstance()
                mainlogic.PlayUIDelegate:replayResult(
                                    mainlogic.PlayUIDelegate.levelId, 
                                    mainlogic.totalScore, 
                                    mainlogic.gameMode:getScoreStarLevel(), 
                                    0, 0, 0, false, AutoCheckLevelFinishReason.kQANextLevelErr , table.serialize(response) )
            end
        end
        -- ReplayDataManager:addMctsLogs( "N1" , {method="AIGamePlayManager:__getNextStep  QAAdjust 1"} )
        local sectionData = SectionResumeManager:getCurrSectionData()
        local dataTable = SectionResumeManager:encodeBySection( sectionData )

        dataTable.canSwaps = SwapItemLogic:calculatePossibleSwap(GameBoardLogic:getInstance(), nil, true)

        local jsonStr = table.serialize( dataTable )
        local snapStr = mime.b64( compress(jsonStr) )
        
        if AIGamePlayManager.DebugMode then
            ReplayDataManager:addMctsLogs( "N1" , {method="try get QANextStep ......... step:" .. tostring(gameboardlogic.realCostMove) } )
        end
        AIPlayQAAdjustManager:getNextStep( snapStr , onQANextStep )
    else
        doNextStepWithAI()
    end

end











-- old version , to be deleted ...
function AIGamePlayManager:__endLevel( result , failReason , score , star , failDatas )
    local simplejson = require("cjson")
    local task = _G.cnnTask
    --self.startLevelData.configData.foolMode
    if not task then
        task = {}
        task.b = "unknow"
        task.s = "unknow"
    end

    if AIGamePlayManager.DebugMode then
        local log = {}
        log.method = "AIGamePlayManager __endLevel  p0     " .. tostring(task.b) .. "_" .. tostring(task.s) .. " result:" .. tostring(result)
        ReplayDataManager:addMctsLogs("N9",log)
    end
    

    if batchIdMap[tostring(task.b) .. "_" .. tostring(task.s)] then
        return
    else
        batchIdMap[tostring(task.b) .. "_" .. tostring(task.s)] = true
    end

    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p1"} )
    end

    local scorePoint = self:getScorePoint()
    --self.scorePointData.staticLevelMoves = gameboardlogic.staticLevelMoves
    -- self.scorePointData.scoreSnaps = {}
    local configs = self:getCurrPlayConfig()

    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p2"} )
    end
    
    if result ~= 1 then
    
        -- kFinished = 1 , --正常结束
        -- kCrash = 2 , --系统级闪退（强杀进程）
        -- kLuaCrash = 3 , --代码闪退（有bug）
        -- kOverTooMushStep = 4 , --超过最大步数且没有过关
        -- kReplay_Crash = 5 , --重放时系统级闪退（强杀进程）
        -- kReplay_LuaCrash = 6 , --重放时代码闪退（有bug）
        -- kReplay_ConsistencyError = 7 , --重放结束但结果和原始情况不一致
        -- kFinishedButNotReachOneStar = 11 , --关卡结束但未达到一星
        -- kFinishedButHasNoSwap = 12 , --没有可交换的物体，关卡失败
        -- kFinishedButHasNoVenom = 13 , --没有毒液，关卡失败
        -- kEndlessLoopByPortal = 14 , --无限掉落(传送门循环)
        -- kEndlessLoopByColor = 15 , --无限掉落（无限三消）
        -- kUnexpectedStoped = 16 , --意外停止，原因不明

        if failReason == "refresh" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoSwap
        elseif failReason == "venom" then
            failReason = AutoCheckLevelFinishReason.kFinishedButHasNoVenom
        end

        
        if configs and not configs.fastMode then
            if not failReason then
                failReason = AutoCheckLevelFinishReason.kFinishedButNotReachOneStar
            end
        end

        result = failReason or 0
    end






    if type(result) == 'number' and result ~= 0 and result ~= 1 then

        local batchId = tostring(task.b)
        local levelId = tostring(task.l)
        local failReason = tostring(result)

        local filename_section = 'section_' .. batchId .. '_' .. levelId .. '_' .. failReason
        local filename_snap = 'snap_' .. batchId .. '_' .. levelId .. '_' .. failReason

        local pathname_section = HeResPathUtils:getUserDataPath() .. "/" .. filename_section
        local pathname_snap = HeResPathUtils:getUserDataPath() .. "/" .. filename_snap

        
        local function _process( sz )
            sz = compress(sz)
            sz = mime.b64(sz)
            return sz
        end

        if GameBoardLogic:getInstance() ~= nil then

            if not HeFileUtils:exists( pathname_section ) then

                local sectionData = SectionResumeManager:getCurrSectionData()
                local dataTable = SectionResumeManager:encodeBySection( sectionData )
                dataTable.canSwaps = SwapItemLogic:calculatePossibleSwap(GameBoardLogic:getInstance(), nil, true)
                local jsonStr = table.serialize( dataTable )
                Localhost:safeWriteStringToFile( jsonStr , pathname_section)
                Localhost:safeWriteStringToFile( _process(jsonStr) , pathname_section .. '.zzz')


                local snapData = table.serialize(SnapshotManager:getStepState(GameBoardLogic:getInstance()))
                Localhost:safeWriteStringToFile( snapData , pathname_snap)
                Localhost:safeWriteStringToFile( _process(snapData) , pathname_snap .. '.zzz')

            end
        end

        
    end



    local replayData = ReplayDataManager:getCurrLevelReplayDataCopyWithoutSectionData() or {}
    local logic = GameBoardLogic:getCurrentLogic()

    local useAddStep = true

    if logic and not scorePoint and GamePlayContext:getInstance().inLevelAndInited then
        self:checkAndSetScorePoint( logic )
        scorePoint = self:getScorePoint()

        useAddStep = false
    end

    -- local log = {}
    -- log.method = "AIGamePlayManager __endLevel  p0.1     scorePoint  " .. tostring(scorePoint)
    -- ReplayDataManager:addMctsLogs("N9",log)
    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p3"} )
    end
    

    if logic and scorePoint and configs and GamePlayContext:getInstance().inLevelAndInited then

        local realResult = result
        local realScore = score
        local realStar = star

        local diff1 = -1  --不用加五步，关卡成功时的剩余步数
        local diff2 = -1  --使用加五步过关，实际使用步数 - 关卡配置步数的差值
        local diff3 = -1  --Diff2的数值除以5，并向上取整
        local diff4 = -1  --不用加五步，关卡失败时，搜集目标进度的百分比的平均数
        local diff5 = -1  --不用加五步，关卡失败时，搜集目标进度的值（字符串）

        local scoreSnapCount = #scorePoint.scoreSnaps
        local sp = scorePoint.scoreSnaps[1]

        -- local log = {}
        -- log.method = "AIGamePlayManager __endLevel  p1  scoreSnapCount =" .. tostring(scoreSnapCount) .. "  sp =" .. tostring(sp)
        -- ReplayDataManager:addMctsLogs("N9",log)

        if useAddStep then
            --使用了加五步才过关
            if result == 1 then
                realResult = 0
            end

            local staticLevelMoves = logic.staticLevelMoves or logic:getBoardModel().staticLevelMoves
            local realCostMove = logic.realCostMove or logic:getBoardModel().realCostMove
            local diffMoves = realCostMove - staticLevelMoves
            local ysmove = diffMoves % 5

            diff2 = ( scoreSnapCount * 5 ) + ysmove
            diff3 = scoreSnapCount
            --[[
                解释一哈，为毛要这么算
                看起来，好像直接用 realCostMove - staticLevelMoves 就是我们要的diff2的值
                但是实际上，staticLevelMoves不是关卡原本的步数，而是关卡配置记录的这关的初始化剩余步数
                初始化剩余步数等于这关的静态可用步数吗？不一定！
                关卡内有一种情况：开局的静态步数很少（比如只有5步），但是棋盘内有加五步气球，如果你在五步内消掉了气球，那么就开启下一个气球，否则就失败
                这样的关卡，可能预埋了多个气球，实际的可用步数大于staticLevelMoves
                只有两种情况玩家会使用加五步：
                    1，气球没消完，步数用完了，没过关
                    2，气球消完了，步数用完了，没过关

                以上两种情况，diff2需要正确统计的都是玩家实际购买加五步并额外消耗的步数
                
                这样即使玩家执行如下复杂的操作，如何保证diff2的结果是准确的？
                    消除了气球，得到免费步数；
                    步数用完了，还有气球没消完，没过关，使用加五步道具续命；
                    继续消除，气球全部消完了，又得到了免费步数
                    步数又用完了，棋盘上也没有气球了，没过关，使用加五步道具续命；
                    最后剩余2步过关

                最终算法如上所示：
                加五步使用次数 * 5 + （realCostMove - staticLevelMoves）取余5的余数
            ]]

        else
            --未使用加五步就过关
            if realResult == 1 then
                -- diff1 = (logic.staticLevelMoves or logic:getBoardModel().staticLevelMoves) - sp.realCostMove
                diff1 = (logic.leftMoves or logic:getBoardModel().leftMoves)
            end
        end

        if realResult == 0 then
            local progressData = sp.progressData

            local diffRate = 0 
            local diffRateStr = ""

            local total_tv = 0
            local total_cv = 0
            for k,v in ipairs( progressData ) do

                total_tv = total_tv + v.tv
                if v.cv <= v.tv then
                    total_cv = total_cv + v.cv
                end

                local r = (v.tv - v. cv) / v.tv
                if r > 1 then r = 1 end
                diffRate = diffRate + r

                if diffRateStr == "" then
                    diffRateStr = tostring(v.ty) .. "_" .. tostring(v.cv) .. "_" .. tostring(v.tv)
                else
                    diffRateStr = diffRateStr .. "|" .. tostring(v.ty) .. "_" .. tostring(v.cv) .. "_" .. tostring(v.tv)
                end
            end
            diffRate = diffRate / #progressData

            -- diff4 = diffRate
            if total_tv == 0 then
                diff4 = 0
            else
                diff4 = ( total_tv - total_cv ) / total_tv
            end
            
            diff5 = diffRateStr
        end

        realScore = sp.score
        realStar = sp.star

        replayData.aiDiffResults = {}
        replayData.aiDiffResults.diff1 = diff1
        replayData.aiDiffResults.diff2 = diff2
        replayData.aiDiffResults.diff3 = diff3
        replayData.aiDiffResults.diff4 = diff4
        replayData.aiDiffResults.diff5 = diff5
        replayData.aiDiffResults.realResult = realResult
        replayData.aiDiffResults.realScore = realScore
        replayData.aiDiffResults.realStar = realStar

        -- local log = {}
        -- log.method = "AIGamePlayManager __endLevel  p6 " .. table.tostring(replayData.aiDiffResults)
        -- ReplayDataManager:addMctsLogs("N9",log)
    end

    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p4"} )
    end
    
    local obj = {
        r = result,
        fr = failReason,
        sc = score,
        st = star,
        s = task.s,
        b = task.b,
        o = replayData
    }

    -- local log = {}
    -- log.method = "TEST_LOG result:" .. tostring(result) .. "  failReason:" .. tostring(failReason)
    -- ReplayDataManager:addMctsLogs( 101 , log )

    if result > 1 then
        -- sendAICheckErrorToDingTalkRobot( obj , failDatas , configs , nil )
    end

    -- local log = {}
    -- log.method = "TEST_LOG result:" .. tostring(result) .. "  failReason:" .. tostring(failReason)
    -- ReplayDataManager:addMctsLogs( 102 , log )

    --以下代码应该在 sendAICheckErrorToDingTalkRobot 调用之后再赋值

    replayData.scoreSnapsData = scorePoint

    replayData.aiReplayMode = true
    replayData.aiResult = result
    replayData.aiFailData = failDatas

    if configs and configs.originConfigStr then
        replayData.aiConfigs = table.deserialize( configs.originConfigStr )
    end

    if replayData.aiConfigs then 
        replayData.aiConfigs.levelCfg = nil
    end
    -------------------------------------------------------------

    if AIGamePlayManager.DebugMode then

        local str = "AIGamePlayManager __endLevel  p5  result:" .. tostring(result)
                    .. " failReason:" .. tostring(failReason)
                    .. " score:" .. tostring(score)
                    .. " star:" .. tostring(star)
                    .. " levelId:" .. tostring(task.l)
                    .. " batchId:" .. tostring(task.b)
                    .. " seed:" .. tostring(task.s)
        ReplayDataManager:addMctsLogs( "PASSLEVEL" , { method = str } )
    end
    
    
    -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p5.1  replayData.scoreSnapsData = " .. table.serialize(replayData.scoreSnapsData) } )
    -- ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p5.1  replayData.aiConfigs.levelCfg = " .. table.serialize(replayData.aiConfigs.levelCfg) } )

    local redisClient = _G.redisClient
    local jsonData = simplejson.encode(obj)
    local pushResult = redisClient:lpush("cnn_result" , jsonData )
    if AIGamePlayManager.DebugMode then
        ReplayDataManager:addMctsLogs( "N2" , {method="AIGamePlayManager __endLevel  p6  " .. table.tostring(replayData.aiDiffResults) .. "  pushResult :" .. tostring(pushResult) } )
    end

end














local function sendToDingTalk( url , postData , callback )
  local request = HttpRequest:createPost( url )
  request:setConnectionTimeoutMs( 2000 )
  request:setTimeoutMs( 10000 )
  request:addHeader("Content-Type: application/json")
  request:setPostData( postData , string.len(postData) )
  
  HttpClient:getInstance():sendRequest(
        function ( ... )
            if callback then 
                callback(...) 
            end
        end , request )
end

function sendTextMessageToDingTalkRobot( robotToken , messages , callback )
    local url = "https://oapi.dingtalk.com/robot/send?access_token=" .. tostring(robotToken)

    local requestData = {
        msgtype = "text",
        text = { content = messages },
    }

    sendToDingTalk( url , table.serialize(requestData) , callback )
end

function sendAICheckErrorToDingTalkRobot( datas , failDatas , configs , callback )
    
    failDatas = failDatas or {}
    configs = configs or {}

    local failReasonStr = "未知"
    local prePropStr = "未知"
    local adjustEnableStr = "未知"
    
    local levelCfg = configs.levelCfg or {}

    if datas.r then
        if datas.r == 3 then
            failReasonStr = "代码闪退"
        elseif datas.r == 4 then
            failReasonStr = "超过最大步数且没有过关"
        elseif datas.r == 11 then
            failReasonStr = "关卡结束但未达到一星"
        elseif datas.r == 12 then
            failReasonStr = "没有可交换的物体，关卡失败"
        elseif datas.r == 13 then
            failReasonStr = "没有毒液，关卡失败"
        elseif datas.r == 14 then
            failReasonStr = "无限掉落(传送门循环)"
        elseif datas.r == 15 then
            failReasonStr = "无限掉落（无限三消）"
        elseif datas.r == 16 then
            failReasonStr = "意外停止，原因不明"
        end
    end

    if configs.preProp then
        if configs.preProp == 0 then
            prePropStr = "不使用"
        elseif configs.preProp == 1 then
            prePropStr = "爆炸直线、刷新、加三步、魔力鸟、导弹，全选"
        elseif configs.preProp == 2 then
            prePropStr = "爆炸直线、刷新、加三步、魔力鸟、导弹，随机选"
        elseif configs.preProp == 3 then
            prePropStr = "爆炸直线、刷新、加三步，全选"
        elseif configs.preProp == 4 then
            prePropStr = "爆炸直线、加三步，全选"
        elseif configs.preProp == 5 then
            prePropStr = "魔力鸟、导弹，全选"
        elseif configs.preProp == 9999 then
            prePropStr = "按线上比例随机"
        end
    end

    if configs.adjustEnable then
        if configs.adjustEnable == 0 then
            adjustEnableStr = "不激活"
        elseif configs.adjustEnable == 1 then
            adjustEnableStr = "一阶过难"
        elseif configs.adjustEnable == 2 then
            adjustEnableStr = "二阶过难"
        elseif configs.adjustEnable == 3 then
            adjustEnableStr = "三阶过难"
        elseif configs.adjustEnable == 4 then
            adjustEnableStr = "四阶过难"
        elseif configs.adjustEnable == 5 then
            adjustEnableStr = "五阶过难"
        elseif configs.adjustEnable == 6 then
            adjustEnableStr = "FUUU调整"
        elseif configs.adjustEnable == 9999 then
            adjustEnableStr = "按线上比例随机"
        end
    end
    
    --钉钉群组【报警专用-消消乐技术】
    local url = "https://oapi.dingtalk.com/robot/send?access_token=f48387987fb5f6ad2fb699caebcf244bac9a4ed7b9b6bf0ee9e2096062afacb1"
    --钉钉群组【AI自动打关 报错处理】
    local url_2 = "https://oapi.dingtalk.com/robot/send?access_token=2743c60f52d2dc4e63b6823636859eebd4bbfc797ccf1d4d44af988b2a20d5e7"
    -- local url = "https://oapi.dingtalk.com/robot/send?access_token=e19d595c14495806ffc9c91f2a045488a5ee91021f78af5b63a988e1de65aecd"
    
    local levelDetailURL = "http://10.130.136.29/animal-fc/cnn_summary.jsp?uuid=" .. tostring(levelCfg.id) 
                                                                        .. "&fixedBatchId=" .. tostring(datas.b)
                                                                        .. "&viewMode=1"

    local txtTitle =    "# 囧囧囧囧囧囧囧囧囧囧囧囧囧囧囧\n" ..
                        "# 囧囧囧 [自动打关报错啦](" .. levelDetailURL .. ") 囧囧囧\n" ..
                        "# 囧囧囧囧囧囧囧囧囧囧囧囧囧囧囧\n"
    local levelIdStr = tostring(datas.o.level)
    if levelIdStr == "9999" or levelIdStr == "1" then
        levelIdStr = "未分配ID"
    end

    

    local resultStr =  txtTitle
                    .. "## 关卡信息 ：  \n"
                    .. "LevelId : " .. tostring(datas.o.level) .."  \n"
                    .. "UUID : " .. tostring(levelCfg.id) .."  \n"
                    .. "BatchId : " .. tostring(datas.b) .."  \n"
                    .. "Seed : " .. tostring(datas.s) .."  \n"
                    .. "前置 : " .. tostring(prePropStr) .."  \n"
                    .. "难度调整 : " .. tostring(adjustEnableStr) .."  \n"
                    .. "## 检测结果 ：  \n"
                    .. "Result : " .. tostring(datas.r) .."  \n"
                    .. "FailReason : " .. tostring(failReasonStr) .."  \n"
                    .. "## 关卡得分 ：  \n"
                    .. "Score : " .. tostring(datas.sc) .."  \n"
                    .. "Star : " .. tostring(datas.st) .."  \n"
                    .. "## OpLog :  \n" 
                    .. table.serialize( datas.o ) .. "  \n"
                    .. "## ErrorStack :  \n" 
                    .. table.serialize( failDatas ) .. "  \n"
                    .. "![screenshot](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSd1Q_V2r8_tlCQhTQHYIzbDeKS10w7dLxGvCEM6u3lmdjHyAsoxA)"

    local requestData = {
                            msgtype = "actionCard",
                            actionCard = { 
                                title = "自动打关",
                                text = resultStr,
                                hideAvatar = 1,
                                btnOrientation = 1,
                                btns = {
                                            [1] = {
                                                title = "队列信息", 
                                                actionURL  = "http://10.130.136.29/animal-fc/cnn_task_manager_status.jsp?viewMode=1"
                                            } ,
                                            [2] = {
                                                title = "所有记录", 
                                                actionURL  = "http://10.130.136.29/animal-fc/cnn_batch_level_task_summary_v2.jsp?viewMode=1"
                                            } ,
                                            [3] = {
                                                    title = "此关详情", 
                                                    actionURL  = levelDetailURL
                                            } ,
                                        }
                            },
                        }

    local callbackCount = 0
    local function sendCallback()
        callbackCount = callbackCount + 1
        if callbackCount == 4 then
            if callback then callback() end
        end
    end

    local requestDataStr = table.serialize(requestData)
    -- printx( 1 , "requestDataStr = " , requestDataStr)
    -- sendToDingTalk( url , requestDataStr , sendCallback )
    sendToDingTalk( url_2 , requestDataStr , sendCallback )


    local requestData2 = {
        msgtype = "text",
        text = { content = "囧TL" },
        at = {
                atMobiles = {
                    [1] = "18601153105", 
                    [2] = "18510162721",
                    [3] = "18600755023",
                    [4] = "13034366972",
                    [5] = "15313585879",
                }, 
                isAtAll = false
            }
    }

    local requestData2Str = table.serialize(requestData2)

    setTimeOut( function () 
                    -- sendToDingTalk( url , requestData2Str , sendCallback ) 
                    sendToDingTalk( url_2 , requestData2Str , sendCallback ) 
                end , 6 )
end