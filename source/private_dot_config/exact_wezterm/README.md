# WezTerm Configuration

This is my WezTerm configuration. No guarantees are made about changes. I _WILL_ push to main, I **WILL** change random things whenever I feel like it.

To install the term info database, run this command:

```shell
> tempfile="$(mktemp)" \
  && curl -o "$tempfile" "https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo" \
  && tic -x -o "/lib/terminfo/w/wezterm" "$tempfile" \
  && rm -f -- "$tempfile"
```

## Usage - Plugin module

Import it:

```lua
local plugin = require('plugin')
```

### Plugin()

Use `plugin.plugin()` or just call it directly (metatable `__call` is set):

```lua
-- These are both equivalent
plugin("a-plugin")
plugin.plugin("a-plugin")
```

If the plugin returns a `table`, it will be deep merged with the current configuration:

```lua
-- config:
{ a = { b = 3, c = 8 } }
plugin("a-plugin")
-- plugins.a-plugin
return { a = { b = 9 } }
--config now:
{ a = { b = 9, c = 8 } }
```

Else if it returns a `function`, the function will be called with the current configuration. If it returns a `table`, it will be deep merged with the current configuration.

```lua
-- config:
{ a = { b = 3, c = 8 } }
plugin("a-plugin")
-- plugins.a-plugin
return function(config)
	return { a = { b = config.a.b + 6 } }
end
--config now:
{ a = { b = 9, c = 8 } }
```

Passing a table to `plugin` will loop over each _integer_ element in the table and call `plugin` on it

```lua
plugin({"a-plugin", "b-plugin"}) -- Both plugins will be loaded (in order)
plugin({"a-plugin", {"b-plugin", "c-plugin"}}) -- all plugins will be loaded (in order)
```

Passing a module who's `init.lua` returns a table with `type='module'` will treat each positional argument as a module relative to _its parent directory_ (NOTE: _only_ works when directories are passed):

```lua
-- wezterm.lua
plugin("package")
-- Does NOT work: plugin("package.init")
    -- Would result in plugin.package.init.hello-world being loaded (and fail).

-- plugins/package/init.lua
return {type="module","hello-world"}
-- plugins.package.hello-world will be loaded
```

`nil` values are ignored at all levels

### Get_config()

The current configuration can be obtained using `plugin.get_config()`. This returns a table, which is simply a reference to the internal table maintained by `plugin()`, so don't rely on it not changing. But also, don't rely on this behavior, as it could change in the future. If you need the values, copy it.

```lua
local config = plugin.get_config()
plugin("a-plugin")
config == plugin.get_config() -- True (for now)
```
