-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_sIndexPath = "";
local m_sPrevPath = "";
local m_sNextPath = "";

function onInit()
  local vNode = getDatabaseNode();
  local sPath = vNode.getPath();
  
  local sRootMapping = LibraryData.getRootMapping("story");
  local bCloseCampaign = false;
  local wCampaign = Interface.findWindow("masterindex", sRootMapping);
  if not wCampaign then
    wCampaign = Interface.openWindow("masterindex", sRootMapping);
    bCloseCampaign = true;
  end
  
  if wCampaign then
    local vIndexNode = wCampaign.getIndexRecord(vNode);
    if vIndexNode then
      m_sIndexPath = vIndexNode.getPath();
    end
    local vPrevNode = wCampaign.getPrevRecord(vNode);
    if vPrevNode then
      m_sPrevPath = vPrevNode.getPath();
    end
    local vNextNode = wCampaign.getNextRecord(vNode);
    if vNextNode then
      m_sNextPath = vNextNode.getPath();
    end
    if bCloseCampaign then
      wCampaign.close();
    end
  end
  
  page_top.setVisible(m_sIndexPath ~= "");
  page_prev.setVisible(m_sPrevPath ~= "");
  page_next.setVisible(m_sNextPath ~= "");
end

function handlePageTop()
  if m_sIndexPath ~= "" then
    replaceWindow(m_sIndexPath);
  end
end

function handlePagePrev()
  if m_sPrevPath ~= "" then
    replaceWindow(m_sPrevPath);
  end
end

function handlePageNext()
  if m_sNextPath ~= "" then
    replaceWindow(m_sNextPath);
  end
end

function replaceWindow(sPath)
  local x,y = getPosition();
  local w,h = getSize();
  local wNew = Interface.openWindow("encounter", sPath);
  wNew.setPosition(x,y);
  wNew.setSize(w,h);
  if not WindowManagerADND then -- test to look for WindowManagerADND -celestian
    close();
  end
end

function onLockChanged()
  if header.subwindow then
    header.subwindow.update();
  end
  
  local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
  text.setReadOnly(bReadOnly);
end

