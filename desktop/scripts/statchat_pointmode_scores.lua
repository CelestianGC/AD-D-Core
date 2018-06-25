-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function setRows(n)
  if n < 0 then
    return;
  end

  local windows = getWindows();
  
  if #windows > n then
    -- Need to close some entries
    for i = n+1, #windows do
      windows[i].close();
    end
    return;
  end
  
  -- Otherwise, need to create some
  for i = 1, n - #windows do
    createWindow();
  end
end

function updateTotals()
  local sum = 0;

  for k, w in ipairs(getWindows()) do
    local score = w.score.getValue();
    local points = calculatePointCost(score);
    
    w.points.setValue(points);
    
    sum = sum + points;
  end
  
  window.total.setValue(sum);
end

function calculatePointCost(score)
  return window.ranges.calculatePointCost(score);
end
