Handlers = {}
Handlers.Utility = {}
Handlers.Utility.CFrame = {
    Get = function(self, Part)
        local Pointer = memory.Read("pointer", Part.Address + 0x148)
        local Matrix = {}
        for I = 0, 15 do
            Matrix[I + 1] = memory.Read("float", Pointer + 0xC0 + (I * 4))
        end
        return {
            Position = Vector3.new(Matrix[10], Matrix[11], Matrix[12]),
            Right = Vector3.new(Matrix[1], Matrix[4], Matrix[7]),
            Up = Vector3.new(Matrix[2], Matrix[5], Matrix[8]),
            Look = Vector3.new(-Matrix[3], -Matrix[6], -Matrix[9])
        }
    end,
    Set = function(self, Part, CFrame)
        local Pointer = memory.Read("pointer", Part.Address + 0x148)
        local Right = CFrame.Right
        local Up = CFrame.Up
        local Look = CFrame.Look
        local Iterations = 36
        for I = 1, Iterations do
            memory.Write("float", Pointer + 0xC0, Right.X)
            memory.Write("float", Pointer + 0xC4, Up.X)
            memory.Write("float", Pointer + 0xC8, -Look.X)
            memory.Write("float", Pointer + 0xCC, Right.Y)
            memory.Write("float", Pointer + 0xD0, Up.Y)
            memory.Write("float", Pointer + 0xD4, -Look.Y)
            memory.Write("float", Pointer + 0xD8, Right.Z)
            memory.Write("float", Pointer + 0xDC, Up.Z)
            memory.Write("float", Pointer + 0xE0, -Look.Z)
        end
    end
}
return Handlers
