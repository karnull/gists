# SysHacks

A collection of independent shell scripts (gists) designed to power up the
terminal experience. Each script solves one specific task with no
cross-dependencies — drop any of them onto `$PATH` and use it on its own.

## Scripts

### `battery_cap.sh`
Limit a laptop battery from overcharging. Define a maximum charge limit inside
the script; if the model is supported, it installs a systemd service that caps
charging at the specified threshold.

### `colors.sh`
Print every terminal colour alongside its escape sequence. Useful as a visual
reference when customising prompts, themes, or status lines.

### `periodic.sh`
Render the periodic table directly in the terminal, with colour coding for groups and
properties of each element.

### `refresh.sh`
Drop system caches and report memory usage before and after — total, used,
free, shared, and buffer/cache.

### `namedit.sh`
Mass-rename files using your `\$EDITOR` (great with vim motions and macros).
Also supports format conversion: change a file's extension and the script
delegates to `ffmpeg` to convert it.

### `resistor.c`
Decode resistor colour bands. Pass band colours (e.g. `blue red green gold`) to
get the resistance value, or run with no arguments for a reference table.

### `rmsymlink.sh`
Remove a symbolic link together with the file it points to. Cleans up the link
first, then the target.

