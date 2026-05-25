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

### `copy_code.sh`
Copy all source files of a given type into the clipboard in one go. Handy for
sharing snippets in places where uploading files isn't convenient.

### `disk_usage_summary.sh`
Report the top space-consuming directories and files, sorted by size. Helps identify what
is eating up disk space on your system.

### `gl.sh`
Enhanced `git log` visualiser. Renders the commit graph with coloured refs, formatted
dates, and tidied decorations via an `awk` post-processor.

### `gomake.sh`
A more robust `go build` wrapper. Compiles a Go program for multiple architectures into
`./bin/` instead of cluttering the project root.

### `monitor_temp.sh`
Monitor CPU and GPU temperatures in real-time and alert when thresholds are exceeded.
Helps prevent thermal throttling and hardware damage.

### `open_ports.sh`
List all currently listening network ports and the processes bound to them. Quick way to
see what services are running.

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

### `vimacro.sh`
Bring vim macros to the shell - record a sequence of edits and replay them across
input. Useful for batch editing operations.

### `watch_file.sh`
Tail a file for changes and trigger notifications when new content is added. Great for
monitoring logs in real-time.

