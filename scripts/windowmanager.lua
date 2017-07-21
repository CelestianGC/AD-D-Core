function onInit()
    Interface.onWindowOpened = ctOnTopAlways;
end

-- keep the combat tracker on top all the time
function ctOnTopAlways(window)
    if User.isHost() then
        if Interface.findWindow("combattracker_host", "combattracker") then
            Interface.findWindow("combattracker_host", "combattracker").bringToFront();
        end
    else
        if Interface.findWindow("combattracker_client", "combattracker") then
            Interface.findWindow("combattracker_client", "combattracker").bringToFront();
        end
    end
end
