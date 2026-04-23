BatteryLogic = class{}

function BatteryLogic:batteryCharge( mainLogic, item )
    -- printx(15,"BatteryLogic:batteryCharge",debug.traceback())
    if not mainLogic then
        mainLogic = GameBoardLogic:getCurrentLogic()
    end

    if not mainLogic or not item or not item.batteryLevel or item.batteryLevel == 0 then
        return
    end

    item.batteryLevel = item.batteryLevel - 1

    if item.batteryLevel == 0 then

        local function actionCallback()

        end

        local batteryChargeAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kBattery_Charge_For_Thunderbird,
        IntCoord:create(item.x, item.y),
        nil,
        GamePlayConfig_MaxAction_time)

        item.batteryCharged = true
        mainLogic:checkItemBlock(item.y,item.x)
        SnailLogic:doEffectSnailRoadAtPos(mainLogic, item.y, item.x)
    
        batteryChargeAction.completeCallback = actionCallback
        batteryChargeAction.battery = item
      
        mainLogic:addDestroyAction(batteryChargeAction)

        -- mainLogic:tryDoOrderList(item.y, item.x, GameItemOrderType.kOthers, GameItemOrderType_Others.kFirework, 1)

        mainLogic:addScoreToTotal(item.y, item.x, GamePlayConfigScore.Battery)

        mainLogic:setNeedCheckFalling()
    else

        local batteryDecAction = GameBoardActionDataSet:createAs(
        GameActionTargetType.kGameItemAction,
        GameItemActionType.kBattery_Dec_Level,
        IntCoord:create(item.x, item.y),
        nil,
        GamePlayConfig_MaxAction_time)
    
        batteryDecAction.battery = item
      
        mainLogic:addDestroyAction(batteryDecAction)
        mainLogic:setNeedCheckFalling()
    end
end