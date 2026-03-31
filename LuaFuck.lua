function getInputFile()
    assert(arg[1], "Please specify the input file!")
    local inputFile = io.open(arg[1])
    assert(inputFile, "Input file not found!")
    return inputFile:read("*a"):gsub("[^><%+%-%.,%[%]]", "")
end

function out(byte)
    io.write(byte and string.char(byte) or "")
end

local code = {}
getInputFile():gsub('.', function(instruction)
    table.insert(code, instruction)
end)

local cell = {
    Limit = 30000,
    Size = 2^8
}

local codeSize = #code
local pos, ptr = 0, 0
local cells = {}

local instructions = {
    [">"] = function()
        ptr = (ptr + 1) % cell.Limit
    end,
    ["<"] = function()
        ptr = (ptr - 1) % cell.Limit
    end,
    ["+"] = function()
        cells[ptr] = ((cells[ptr] or 0) + 1) % cell.Size
    end,
    ["-"] = function()
        cells[ptr] = ((cells[ptr] or 0) - 1) % cell.Size
    end,
    ["."] = function()
        out(cells[ptr])
    end,
    [","] = function()
        cells[ptr] = (io.read(1) or ''):byte()
    end,
    ["["] = function()
        if (cells[ptr] or 0) == 0 then
            local endCount = 1
            local currentPos = pos
            repeat
                currentPos = currentPos + 1
                if code[currentPos] == "]" or code[currentPos] == "[" then
                    endCount = endCount + (code[currentPos] == "]" and -1 or 1)
                end
            until endCount == 0 or code[currentPos] == nil
            pos = currentPos
        end 
    end,
    ["]"] = function()
        if (cells[ptr] or 0) ~= 0 then
            local endCount = 1
            local currentPos = pos
            repeat
                currentPos = currentPos - 1
                if code[currentPos] == "]" or code[currentPos] == "[" then
                    endCount = endCount + (code[currentPos] == "]" and 1 or -1)
                end
            until endCount == 0 or code[currentPos] == nil
            pos = currentPos
        end
    end
}

while pos < codeSize do
    pos = pos + 1
    instructions[code[pos]]()
end
