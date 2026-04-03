local M = {}

function M.merge(t1, t2)
  t1 = t1 or {}
  t2 = t2 or {}

  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      M.merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

return M
