local Calendar = require('includes.ssv2.core.calendar')
local Clock = {}
Clock.__index = Clock

function Clock.new()
    return setmetatable({ last = nil, elapsed = 0, local_offset = nil }, Clock)
end

function Clock:elapsed_ms()
    local raw = MISC.GET_GAME_TIMER() % 4294967296
    if self.last then
        self.elapsed = self.elapsed + (raw - self.last) % 4294967296
    else
        self.elapsed = raw
    end
    self.last = raw
    return self.elapsed
end

function Clock:sync_local()
    local epoch = os.time()
    local local_fields = Calendar.local_fields(epoch)
    local difference = Calendar.to_epoch(local_fields) - epoch
    self.local_offset = math.floor(difference / 60 + 0.5) * 60
end

function Clock:local_text(pattern)
    return Calendar.local_format(os.time(), pattern)
end

return Clock
