--!strict
local AssistRules = {}
function AssistRules.state(failures, seconds)
  return { hint = failures >= 2, grace = failures >= 3, help = failures >= 5 or seconds >= 90 }
end
return AssistRules
