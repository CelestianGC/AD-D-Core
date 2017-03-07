-- data library for ad&d core ruleset
function onInit()
    DesktopManager.showDockTitleText(true);
    DesktopManager.setDockTitleFont("sidebar");
    DesktopManager.setDockTitleFrame("", 25, 2, 25, 5);
    DesktopManager.setDockTitlePosition("top", 2, 14);
    DesktopManager.setStackIconSizeAndSpacing(43, 27, 3, 3);
    DesktopManager.setDockIconSizeAndSpacing(100, 24, 0, 6);
    DesktopManager.setLowerDockOffset(2, 0, 2, 0);
end

