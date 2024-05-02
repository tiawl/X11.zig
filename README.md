# X11.zig

This is a fork of [hexops/x11-headers][1] which itself gather various [X11][2] headers [GLFW][3] needs.

## Why this forkception ?

The intention under this fork is the same as [hexops][4] had when they opened their repository: gather [X11][2] headers and package them to compile [GLFW][4] with [Zig][5].
However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check [X11][2] repositories. Then it updates this repository if a new release is available.

## How to use it

The current usage of this repository is centered around [tiawl/glfw.zig][3] compilation. But you could use it for your own projects. Headers are here and there are no planned evolution to modify them. See [tiawl/glfw.zig][3] to see how you can use it. Maybe for your own need, some headers are missing. If it happens, open an issue: this repository is open to potential usage evolution.

## Dependencies

The [Zig][5] part of this package is relying on the latest [Zig][5] release (0.12.0) and will only be updated for the next one (so for the 0.13.0).

Here the repositories' version used by this fork:
* [xorg/lib/libx11](https://github.com/tiawl/X11.zig/blob/trunk/.versions/X11)
* [xorg/lib/libxcb](https://github.com/tiawl/X11.zig/blob/trunk/.versions/xcb)
* [xorg/proto/xcbproto](https://github.com/tiawl/X11.zig/blob/trunk/.versions/xcbproto)
* [xorg/lib/libxcursor](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xcursor)
* [xorg/lib/libxext](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xext)
* [xorg/lib/libxfixes](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xfixes)
* [xorg/lib/libxi](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xi)
* [xorg/lib/libxinerama](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xinerama)
* [xkbcommon/libxkbcommon](https://github.com/tiawl/X11.zig/blob/trunk/.versions/xkbcommon)
* [xorg/proto/xorgproto](https://github.com/tiawl/X11.zig/blob/trunk/.versions/xorgproto)
* [xorg/lib/libxrandr](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xrandr)
* [xorg/lib/libxrender](https://github.com/tiawl/X11.zig/blob/trunk/.versions/Xrender)
* [xorg/lib/libxscrnsaver](https://github.com/tiawl/X11.zig/blob/trunk/.versions/XScrnSaver)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/glfw.zig][6]

This repository is automatically updated when a new release is available from these repositories:
* [xorg/lib/libx11][2]
* [xorg/lib/libxcb][7]
* [xorg/proto/xcbproto][8]
* [xorg/lib/libxcursor][9]
* [xorg/lib/libxext][10]
* [xorg/lib/libxfixes][11]
* [xorg/lib/libxi][12]
* [xorg/lib/libxinerama][13]
* [xkbcommon/libxkbcommon][14]
* [xorg/proto/xorgproto][15]
* [xorg/lib/libxrandr][16]
* [xorg/lib/libxrender][17]
* [xorg/lib/libxscrnsaver][18]
* [tiawl/toolbox][19]
* [tiawl/spaceporn-action-bot][20]
* [tiawl/spaceporn-action-ci][21]
* [tiawl/spaceporn-action-cd-ping][22]
* [tiawl/spaceporn-action-cd-pong][23]

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.

[1]:https://github.com/hexops/x11-headers
[2]:https://gitlab.freedesktop.org/xorg/lib/libx11
[3]:https://github.com/glfw/glfw
[4]:https://github.com/hexops
[5]:https://github.com/ziglang/zig
[6]:https://github.com/tiawl/glfw.zig
[7]:https://gitlab.freedesktop.org/xorg/lib/libxcb
[8]:https://gitlab.freedesktop.org/xorg/proto/xcbproto
[9]:https://gitlab.freedesktop.org/xorg/lib/libxcursor
[10]:https://gitlab.freedesktop.org/xorg/lib/libxext
[11]:https://gitlab.freedesktop.org/xorg/lib/libxfixes
[12]:https://gitlab.freedesktop.org/xorg/lib/libxi
[13]:https://gitlab.freedesktop.org/xorg/lib/libxinerama
[14]:https://gitlab.freedesktop.org/xkbcommon/libxkbcommon
[15]:https://gitlab.freedesktop.org/xorg/proto/xorgproto
[16]:https://gitlab.freedesktop.org/xorg/lib/libxrandr
[17]:https://gitlab.freedesktop.org/xorg/lib/libxrender
[18]:https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver
[19]:https://github.com/tiawl/toolbox
[20]:https://github.com/tiawl/spaceporn-action-bot
[21]:https://github.com/tiawl/spaceporn-action-ci
[22]:https://github.com/tiawl/spaceporn-action-cd-ping
[23]:https://github.com/tiawl/spaceporn-action-cd-pong
