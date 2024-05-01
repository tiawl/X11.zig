# X11.zig

This is a fork of [hexops/x11-headers](https://github.com/hexops/x11-headers) which itself gather various X11 headers @glfw needs.

## Why this forkception ?

The intention under this fork is the same as hexops had when they opened their repository: gather X11 headers and package them to compile @glfw with @ziglang.
However this repository has subtle differences for maintainability tasks:
* No shell scripting,
* A cron runs every day to check X11 repositories. Then it updates this repository if a new release is available.

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
* [tiawl/glfw.zig](https://github.com/tiawl/glfw.zig)

This repository is automatically updated when a new release is available from these repositories:
* [xorg/lib/libx11](https://gitlab.freedesktop.org/xorg/lib/libx11)
* [xorg/lib/libxcb](https://gitlab.freedesktop.org/xorg/lib/libxcb)
* [xorg/proto/xcbproto](https://gitlab.freedesktop.org/xorg/proto/xcbproto)
* [xorg/lib/libxcursor](https://gitlab.freedesktop.org/xorg/lib/libxcursor)
* [xorg/lib/libxext](https://gitlab.freedesktop.org/xorg/lib/libxext)
* [xorg/lib/libxfixes](https://gitlab.freedesktop.org/xorg/lib/libxfixes)
* [xorg/lib/libxi](https://gitlab.freedesktop.org/xorg/lib/libxi)
* [xorg/lib/libxinerama](https://gitlab.freedesktop.org/xorg/lib/libxinerama)
* [xkbcommon/libxkbcommon](https://gitlab.freedesktop.org/xkbcommon/libxkbcommon)
* [xorg/proto/xorgproto](https://gitlab.freedesktop.org/xorg/proto/xorgproto)
* [xorg/lib/libxrandr](https://gitlab.freedesktop.org/xorg/lib/libxrandr)
* [xorg/lib/libxrender](https://gitlab.freedesktop.org/xorg/lib/libxrender)
* [xorg/lib/libxscrnsaver](https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver)
* [tiawl/toolbox](https://github.com/tiawl/toolbox)
* [tiawl/spaceporn-action-bot](https://github.com/tiawl/spaceporn-action-bot)
* [tiawl/spaceporn-action-ci](https://github.com/tiawl/spaceporn-action-ci)
* [tiawl/spaceporn-action-cd-ping](https://github.com/tiawl/spaceporn-action-cd-ping)
* [tiawl/spaceporn-action-cd-pong](https://github.com/tiawl/spaceporn-action-cd-pong)

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.
