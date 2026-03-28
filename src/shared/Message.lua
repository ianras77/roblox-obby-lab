local Message = {}

function Message.greet(name)
  return string.format("Hello, %s!", name)
end

return Message
