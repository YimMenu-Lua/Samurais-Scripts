-- Account transfers use the original game transaction service and status codes.
local Money = {}; Money.__index = Money
function Money.new(ctx)
    return setmetatable({ ctx = ctx, bank = 0, wallet = 0, total = 0, next_update = 0, busy = false }, Money)
end

function Money:update(now)
    if now < self.next_update then return end
    local character = self.ctx.game.character_index()
    if character == nil then return end
    self.bank = MONEY.NETWORK_GET_VC_BANK_BALANCE()
    self.wallet = MONEY.NETWORK_GET_VC_WALLET_BALANCE(character)
    self.total = self.bank + self.wallet
    self.next_update = now + 2000
end

function Money:transfer(deposit, amount, valid)
    if self.busy then return false end
    assert(network.is_session_started() and not NETWORK.NETWORK_IS_ACTIVITY_SESSION(),
        'Account transfers require online freemode')
    amount = math.min(math.floor(amount), deposit and self.wallet or self.bank)
    assert(amount > 0 and amount <= 2147483647, 'Invalid transfer amount')
    local character = assert(self.ctx.game.character_index(), 'Character index is unavailable')
    local start = deposit and NETSHOPPING.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK or
        NETSHOPPING.NET_GAMESERVER_TRANSFER_BANK_TO_WALLET
    local status = deposit and NETSHOPPING.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK_GET_STATUS or
        NETSHOPPING.NET_GAMESERVER_TRANSFER_BANK_TO_WALLET_GET_STATUS
    self.busy = true
    local ok, result = pcall(function()
        if not NETSHOPPING.NET_GAMESERVER_USE_SERVER_TRANSACTIONS() then
            if deposit then MONEY.DEPOSIT_VC(amount) else MONEY.WITHDRAW_VC(amount) end
            self.next_update = 0; return true
        end
        assert(not NETSHOPPING.NET_GAMESERVER_TRANSACTION_IN_PROGRESS(), 'Another account transaction is in progress')
        local outputs = memory.allocate(8)
        assert(outputs and outputs:get_address() ~= 0, 'Cannot allocate account status outputs')
        local status_ok, session_state = pcall(function()
            outputs:set_int(0); outputs:add(4):set_int(0)
            NETSHOPPING.NET_GAMESERVER_GET_SESSION_STATE_AND_STATUS(outputs, outputs:add(4))
            return outputs:get_int()
        end)
        memory.free(outputs)
        if not status_ok then error(session_state) end
        assert(session_state == 8, 'The account transaction session is unavailable')
        assert(start(character, amount), 'The game rejected the account transfer')
        local generation = self.ctx.runtime.generation
        local deadline = util.time() + 30000
        local code = status()
        while code == 1 do
            script.yield(0)
            if not self.ctx.runtime.running or self.ctx.runtime.generation ~= generation or valid and not valid() then return false end
            assert(util.time() < deadline, 'Account transfer status timed out')
            code = status()
        end
        assert(code == 3, 'Account transfer failed with status ' .. tostring(code))
        NETSHOPPING.NET_GAMESERVER_TRANSFER_CASH_SET_TELEMETRY_NONCE_SEED()
        if deposit then MONEY.DEPOSIT_VC(amount) else MONEY.WITHDRAW_VC(amount) end
        self.next_update = 0
        return true
    end)
    self.busy = false
    if not ok then error(result) end
    return result
end

return Money
