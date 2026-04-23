require 'zoo.gamePlay.propInteractions.BaseInteraction'
require 'zoo.itemView.PropsView'

-- 新扫帚
NewBroomInteraction = class(BroomInteraction)

function NewBroomInteraction:handleTouchBegin(x, y)

    local touchPos = self.boardView:TouchAt(x, y)
    if not touchPos then
        return
    end

    if not self.boardView.gameBoardLogic:isItemInTile(touchPos.x, touchPos.y) then
        return
    end

    if self.currentState == self.waitingState then
        if self.boardView.gameBoardLogic:canUseBroom(touchPos.x, touchPos.y, true) then
            self.itemPos = {r = touchPos.x, c = touchPos.y}
            self:setCurrentState(self.touchedState)
        else
            PropsView:playNewBroomDisableAnimation(self.boardView, IntCoord:create(touchPos.x, touchPos.y))
        end
    end
end

function NewBroomInteraction:onEnter()
    if _G.isLocalDevelopMode then printx(0, '>>> enter NewBroomInteraction') end
end

function NewBroomInteraction:onExit()
    if _G.isLocalDevelopMode then printx(0, '--- exit  NewBroomInteraction') end
end
