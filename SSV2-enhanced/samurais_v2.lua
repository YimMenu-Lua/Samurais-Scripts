-- Samurai's Scripts V2 port. GPL-3.0-or-later; see LICENSE.
-- Original feature behavior and data: SAMURAI (xesdoog) and contributors.
-- This entry point loads the V2 application, not the V1 compatibility layer.

if not natives.are_natives_loaded() then natives.load_natives() end
require('includes.ssv2.app').start()
