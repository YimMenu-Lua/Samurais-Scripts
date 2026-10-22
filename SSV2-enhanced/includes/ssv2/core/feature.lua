local Feature = {}
function Feature.new(ctx, spec)
    spec.ctx = ctx
    function spec:enabled() return ctx.settings:get(self.path) == true end

    function spec:disable() ctx.settings:set(self.path, false) end

    return spec
end

return Feature
