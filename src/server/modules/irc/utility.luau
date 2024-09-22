local utility = {}

function utility.inRange(number: number, min: number, max: number, err: string)
    assert(number >= min and number <= max, err)
end

return utility