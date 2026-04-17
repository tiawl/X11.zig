# X11.zig

This is a fork of [hexops/x11-headers][1] which itself gather various [xorg][6] headers [GLFW][3] needs.

## Why this forkception ?

The intention under this fork is the same as [hexops][4] had when they opened their repository: gather [xorg][6] headers and package them to compile [GLFW][4] with [Zig][5].

However this repository has subtle differences:
* Add [xorg][6] sources needed for [libX11][2] compilation,
* No shell scripting for maintainability tasks,
* A cron runs every day to check [xorg][6] repositories and other dependencies. Then it updates this repository if a new release is available.

## Dependencies

The [Zig][5] part of this package requires the latest (0.16.0) or the master (0.17.0-dev) [Zig][5] release.

For other dependencies see [the build.zig.zon](https://github.com/tiawl/X11.zig/blob/zig-stable/build.zig.zon)

## `zig build` options

These additional options have mainly been implemented for maintainability tasks but they maybe could be useful for edge usecases:
```
  -Dfetch   Update build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

[1]:https://github.com/hexops/x11-headers
[2]:https://gitlab.freedesktop.org/xorg/lib/libx11
[3]:https://github.com/glfw/glfw
[4]:https://github.com/hexops
[5]:https://codeberg.org/ziglang/zig
[6]:https://gitlab.freedesktop.org/xorg
