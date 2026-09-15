-- Entry point: PURE native-pack config, no plugin manager.
-- Layout:
--   pack/vendor/start/*  -> auto-loaded plugins (git repos)
--   pack/vendor/opt/*     -> lazy-loaded via :packadd (lazydev only)
--   lua/config/options.lua  -> leader, UI, indent, clipboard (xclip)
--   lua/config/plugins.lua  -> require().setup() for each plugin
--   lua/config/keymaps.lua   -> all keybindings
--   lua/config/autocmds.lua  -> filetype rules (C/C++ format)
--   lua/tools/floatterm.lua  -> floating terminal module
-- See PACKAGES.md for how to add/update/remove plugins.

require("config.options")
require("config.plugins")
require("config.keymaps")
require("config.autocmds")
