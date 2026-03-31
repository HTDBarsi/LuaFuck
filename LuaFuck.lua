local config = {
    CellLimit = 30000, -- og limit
    CellSize = 2^8 -- 1 byte
}

function getInputFile()
    assert(arg[1], "Please specify the input file!")
    local inputFile = io.open(arg[1])
    assert(inputFile, "Input file not found!")
    return inputFile:read("*a"):gsub("[^><%+%-%.,%[%]]", "")
end

function out(byte)
    io.write(byte and string.char(byte) or "")
end

local output = config.DirectOutput and function(text)  end

local code = {}
getInputFile():gsub('.', function(instruction)
    table.insert(code, instruction)
end)

local cell = {
    Limit = config.CellLimit,
    Size = config.CellSize
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

--[[
    >	Increment the data pointer by one (to point to the next cell to the right).
    <	Decrement the data pointer by one (to point to the next cell to the left). Undefined if at 0.
    +	Increment the byte at the data pointer by one modulo 256.
    -	Decrement the byte at the data pointer by one modulo 256.
    .	Output the byte at the data pointer.
    ,	Accept one byte of input, storing its value in the byte at the data pointer.[b]
    [	If the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command.
    ]	If the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command.[c]
]]
