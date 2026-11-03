local Players = game:GetService("Players")
local player = Players.LocalPlayer

task.spawn(function()
    while true do
        local character = player.Character
        if character then
            local weight = character:FindFirstChild("Weight")
            local muscleEvent = player:FindFirstChild("muscleEvent")
            if weight and muscleEvent then
                local args = { "rep", weight }
                muscleEvent:FireServer(unpack(args))
            end
        end
        task.wait(0.01)
    end
end)