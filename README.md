# Gists

A collection of independent shell scripts designed to power up the terminal
experience. Each script solves one specific task with no cross-dependencies -
drop any of them onto `$PATH` and use it on its own.

<details>
<summary>Git</summary>

### `git_fuzzy.sh`
![](.media/git_fuzzy.png)

Fuzzy pickers for everyday branch, worktree and stash chores, built on `fzf`. Add or
remove worktrees, switch to, make local, rebase onto or delete branches, each
picked from a list with a preview of its recent log. `worktree_check` and
`branch_check` open a remote branch as a detached checkout, without fetching it
or making a local branch. `stash_pop` and `stash_drop` pick stashes with a
`git stash show` preview.

### `git_logs.sh`
![](.media/git_logs.png)

Enhanced `git log` visualiser. Renders the commit graph with coloured refs, formatted
dates, and tidied decorations via an `awk` post-processor. With `fzf`, `cp` copies a
picked commit's id, `check` checks it out, and `show` and `revert` run on every
picked commit. Formerly `gl.sh`, where `cp` was called `fzf`.

</details>

<details>
<summary>Maintenance</summary>

### `battery_cap.sh`
![](.media/battery_cap.png)

Limit a laptop battery from overcharging. Define a maximum charge limit inside
the script; if the model is supported, it installs a systemd service that caps
charging at the specified threshold.

### `refresh.sh`
![](.media/refresh.png)

Drop system caches and report memory usage before and after — total, used,
free, shared, and buffer/cache.

</details>

<details>
<summary>Monitoring</summary>

### `disk_usage_summary.sh`
![](.media/disk_usage_summary.png)

Report the top space-consuming directories and files, sorted by size. Helps identify what
is eating up disk space on your system.

### `monitor_temp.sh`
![](.media/monitor_temp.png)

Monitor CPU and GPU temperatures in real-time and alert when thresholds are exceeded.
Helps prevent thermal throttling and hardware damage.

### `open_ports.sh`
![](.media/open_ports.png)

List all currently listening network ports and the processes bound to them. Quick way to
see what services are running.

### `watch_file.sh`
![](.media/watch_file.png)

Tail a file for changes and trigger notifications when new content is added. Great for
monitoring logs in real-time.

</details>

<details>
<summary>Reference</summary>

### `colors.sh`
![](.media/colors.png)

Print every terminal colour alongside its escape sequence. Useful as a visual
reference when customising prompts, themes, or status lines.

### `periodic.sh`
![](.media/periodic.png)

Render the periodic table directly in the terminal, with colour coding for groups and
properties of each element.

### `resistor.c`
![](.media/resistor.png)

Decode resistor colour bands. Pass band colours (e.g. `blue red green gold`) to
get the resistance value, or run with no arguments for a reference table.

</details>

<details>
<summary>Workflow</summary>

### `copy_code.sh`
![](.media/copy_code.png)

Copy all source files of a given type into the clipboard in one go. Handy for
sharing snippets in places where uploading files isn't convenient.

### `namedit.sh`
![](.media/namedit.png)

Mass-rename files using your `$EDITOR` (great with vim motions and macros).
Also supports format conversion: change a file's extension and the script
delegates to `ffmpeg` to convert it.

### `rmsymlink.sh`
![](.media/rmsymlink.png)

Remove a symbolic link together with the file it points to. Cleans up the link
first, then the target.

### `vimacro.sh`
![](.media/vimacro.png)

Bring vim macros to the shell - record a sequence of edits and replay them across
input. Useful for batch editing operations.

</details>
