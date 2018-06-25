-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
  TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptemp", "wounds"});
  TokenManager.addDefaultEffectFeatures(getEffectInfo);
end
function getHealthInfo(nodeCT)
  local sColor, nPercentWounded, sStatus = ActorManager2.getWoundBarColor("ct", nodeCT);
  return nPercentWounded, sStatus, sColor;
end
function getEffectInfo(nodeCT, bSkipGMOnly)
  local aIconList = {};

  local rActor = ActorManager.getActorFromCT(nodeCT);
  
  -- Iterate through effects
  local aSorted = {};
  for _,nodeChild in pairs(DB.getChildren(nodeCT, "effects")) do
    table.insert(aSorted, nodeChild);
  end
  table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);

  for k,v in pairs(aSorted) do
    if DB.getValue(v, "isactive", 0) == 1 then
      if (not bSkipGMOnly and User.isHost()) or (DB.getValue(v, "isgmonly", 0) == 0) then
        local sLabel = DB.getValue(v, "label", "");
        
        local sEffect = nil;
        local bSame = true;
        local sLastIcon = nil;

        local aEffectComps = EffectManager.parseEffect(sLabel);
        for kComp,sEffectComp in ipairs(aEffectComps) do
          local vComp = EffectManager5E.parseEffectComp(sEffectComp);
          -- CHECK CONDITIONALS
          if vComp.type == "IF" then
            if not EffectManager5E.checkConditional(rActor, v, vComp.remainder) then
              break;
            end
          elseif vComp.type == "IFT" then
            -- Do nothing
          
          else
            local sNewIcon = nil;
            
            -- CHECK FOR A BONUS OR PENALTY
            local sComp = vComp.type;
            if StringManager.contains(DataCommon.bonuscomps, sComp) then
              if #(vComp.dice) > 0 or vComp.mod > 0 then
                sNewIcon = "cond_bonus";
              elseif vComp.mod < 0 then
                sNewIcon = "cond_penalty";
              else
                sNewIcon = "cond_generic";
              end
          
            -- CHECK FOR OTHER VISIBLE EFFECT TYPES
            else
              sNewIcon = DataCommon.othercomps[sComp];
            end
          
            -- CHECK FOR A CONDITION
            if not sNewIcon then
              sComp = vComp.original:lower();
              sNewIcon = DataCommon.condcomps[sComp];
            end
            
            if sNewIcon then
              if bSame then
                if sLastIcon and sLastIcon ~= sNewIcon then
                  bSame = false;
                end
                sLastIcon = sNewIcon;
              end
            else
              if kComp == 1 then
                sEffect = vComp.original;
              end
            end
          end
        end
        
        if #aEffectComps > 0 then
          local sFinalIcon;
          if bSame and sLastIcon then
            sFinalIcon = sLastIcon;
          else
            sFinalIcon = "cond_generic";
          end
          local sFinalName = sEffect or sLabel;
          
          table.insert(aIconList, { sName = sFinalName, sIcon = sFinalIcon, sEffect = sLabel } );
        end
      end
    end
  end
  
  return aIconList;
end
