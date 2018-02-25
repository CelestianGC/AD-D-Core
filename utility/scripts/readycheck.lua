---
--- Code to manage the /readycheck command
---
---
---

function onInit()
  DB.addHandler("connectedlist.*", "onUpdate", onConnectionsChanged);
end

function onClose()
  DB.removeHandler("connectedlist.*", "onUpdate", onConnectionsChanged);
end

function onConnectionsChanged()

end