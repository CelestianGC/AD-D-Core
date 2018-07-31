--
--
-- Various utility functions
--
--
--

function onInit()
end


-- this is to replace a string value at a specific location
-- why the heck doesn't lua have this natively? -- celestian
function replaceStringAt(sOriginal,sReplacement,nStart,nEnd)
  local sFinal = nil;
  if (nStart == 1) then
    sFinal = sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  else
    sFinal = sOriginal:sub(1,nStart-1) .. sReplacement .. sOriginal:sub(nEnd+1,sOriginal:len());
  end
  return sFinal;
end
