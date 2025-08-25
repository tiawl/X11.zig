const std = @import("std");
const toolbox_pkg = @import("toolbox");
const Toolbox = toolbox_pkg.Toolbox;

const Paths = struct {
    __GL: []const u8,
    __X11: []const u8,
    __ext: []const u8,
    __tmp: []const u8,
    __tmp2: []const u8,
    __xkbcommon: []const u8,
    __xcb: []const u8,

    fn getGL(self: @This()) []const u8 {
        return self.__GL;
    }

    fn getX11(self: @This()) []const u8 {
        return self.__X11;
    }

    fn getExt(self: @This()) []const u8 {
        return self.__ext;
    }

    fn getTmp(self: @This()) []const u8 {
        return self.__tmp;
    }

    fn getTmp2(self: @This()) []const u8 {
        return self.__tmp2;
    }

    fn getXkbcommon(self: @This()) []const u8 {
        return self.__xkbcommon;
    }

    fn getXcb(self: @This()) []const u8 {
        return self.__xcb;
    }

    fn init(toolbox: *Toolbox) !@This() {
        const X11_path = try toolbox.buildRootJoin(&.{
            "X11",
        });

        return .{
            .__GL = try toolbox.buildRootJoin(&.{
                "GL",
            }),
            .__X11 = X11_path,
            .__tmp = try toolbox.buildRootJoin(&.{
                "tmp",
            }),
            .__tmp2 = try toolbox.buildRootJoin(&.{
                "tmp2",
            }),
            .__xkbcommon = try toolbox.buildRootJoin(&.{
                "xkbcommon",
            }),
            .__xcb = try toolbox.buildRootJoin(&.{
                "xcb",
            }),
            .__ext = toolbox.pathJoin(&.{
                X11_path, "extensions",
            }),
        };
    }
};

fn update_xkbcommon(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.xkbcommon, path.getTmp());

    const include_path = toolbox.pathJoin(&.{ path.getTmp(), "include", "xkbcommon" });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    try toolbox.make(path.getXkbcommon());

    var it = include_dir.iterate();
    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox_pkg.isCHeader(entry.name)) {
                    try toolbox.copy(toolbox.pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.pathJoin(&.{
                        path.getXkbcommon(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_X11(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.X11, path.getTmp());

    const include_path = toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11",
    });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();
    try toolbox.make(path.getX11());

    var it = include_dir.iterate();
    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox_pkg.isCHeader(entry.name)) {
                    try toolbox.copy(toolbox.pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.pathJoin(&.{
                        path.getX11(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    const include_ext_path = toolbox.pathJoin(&.{
        include_path, "extensions",
    });
    var include_ext_dir = try std.fs.openDirAbsolute(include_ext_path, .{
        .iterate = true,
    });
    defer include_ext_dir.close();
    try toolbox.make(path.getExt());
    it = include_ext_dir.iterate();

    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox_pkg.isCHeader(entry.name)) {
                    try toolbox.copy(toolbox.pathJoin(&.{
                        include_ext_path, entry.name,
                    }), toolbox.pathJoin(&.{
                        path.getExt(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    var xlib_conf_h = try include_dir.readFileAlloc(toolbox.getAllocator(), "XlibConf.h.in", std.math.maxInt(usize));

    for ([_]struct {
        match: []const u8,
        replace: []const u8,
    }{
        .{
            .match = "#undef XTHREADS",
            .replace = "#define XTHREADS 1",
        },
        .{
            .match = "#undef XUSE_MTSAFE_API",
            .replace = "#define XUSE_MTSAFE_API 1",
        },
    }) |search_and_replace| {
        xlib_conf_h = try std.mem.replaceOwned(u8, toolbox.getAllocator(), xlib_conf_h, search_and_replace.match, search_and_replace.replace);
    }

    try toolbox.write(path.getX11(), "XlibConf.h", xlib_conf_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xcursor(toolbox: *Toolbox, path: *const Paths) !void {
    const xcursor_path = toolbox.pathJoin(&.{
        path.getX11(), "Xcursor",
    });

    try toolbox.clone(.Xcursor, path.getTmp());

    const include_path = toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "Xcursor",
    });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var xcursor_h = try include_dir.readFileAlloc(toolbox.getAllocator(), "Xcursor.h.in", std.math.maxInt(usize));

    var xcursor_version = try toolbox.reference(.Xcursor);
    xcursor_version = xcursor_version[std.mem.indexOfAny(u8, xcursor_version, "0123456789").?..];
    var tokit = std.mem.tokenizeScalar(u8, xcursor_version, '.');
    const match = [_][]const u8{
        "#undef XCURSOR_LIB_MAJOR", "#undef XCURSOR_LIB_MINOR", "#undef XCURSOR_LIB_REVISION",
    };
    const replace = [_][]const u8{
        "#define XCURSOR_LIB_MAJOR", "#define XCURSOR_LIB_MINOR", "#define XCURSOR_LIB_REVISION",
    };
    var index: usize = 0;
    while (tokit.next()) |*token| {
        xcursor_h = try std.mem.replaceOwned(u8, toolbox.getAllocator(), xcursor_h, match[index], toolbox.fmt("{s} {s}", .{
            replace[index], token.*,
        }));
        index += 1;
    }

    try toolbox.make(xcursor_path);
    try toolbox.write(xcursor_path, "Xcursor.h", xcursor_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xrandr(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xrandr, path.getTmp());

    try toolbox.copy(toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xrandr.h",
    }), toolbox.pathJoin(&.{
        path.getExt(), "Xrandr.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xfixes(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xfixes, path.getTmp());

    try toolbox.copy(toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xfixes.h",
    }), toolbox.pathJoin(&.{
        path.getExt(), "Xfixes.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xrender(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xrender, path.getTmp());

    try toolbox.copy(toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xrender.h",
    }), toolbox.pathJoin(&.{
        path.getExt(), "Xrender.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xinerama(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xinerama, path.getTmp());

    for ([_][]const u8{
        "Xinerama.h", "panoramiXext.h",
    }) |file| {
        try toolbox.copy(toolbox.pathJoin(&.{
            path.getTmp(), "include", "X11", "extensions", file,
        }), toolbox.pathJoin(&.{
            path.getExt(), file,
        }));
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xi(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xi, path.getTmp());

    for ([_][]const u8{
        "XInput.h", "XInput2.h",
    }) |file| {
        try toolbox.copy(toolbox.pathJoin(&.{
            path.getTmp(), "include", "X11", "extensions", file,
        }), toolbox.pathJoin(&.{
            path.getExt(), file,
        }));
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_XScrnSaver(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.XScrnSaver, path.getTmp());

    try toolbox.copy(toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "scrnsaver.h",
    }), toolbox.pathJoin(&.{
        path.getExt(), "scrnsaver.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xext(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.Xext, path.getTmp());

    const include_path = toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions",
    });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var it = include_dir.iterate();
    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox_pkg.isCHeader(entry.name)) {
                    try toolbox.copy(toolbox.pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.pathJoin(&.{
                        path.getExt(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_xorgproto(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.xorgproto, path.getTmp());

    var include_path: []const u8 = undefined;
    var include_dir: std.fs.Dir = undefined;
    var walker: std.fs.Dir.Walker = undefined;

    try toolbox.make(path.getGL());

    inline for ([_][]const u8{
        "GL", "X11",
    }) |component| {
        include_path = toolbox.pathJoin(&.{
            path.getTmp(), "include", component,
        });
        include_dir = try std.fs.openDirAbsolute(include_path, .{
            .iterate = true,
        });
        defer include_dir.close();

        walker = try include_dir.walk(toolbox.getAllocator());
        defer walker.deinit();

        while (try walker.next()) |*entry| {
            const dest = toolbox.pathJoin(&.{
                if (std.mem.eql(u8, "GL", component)) path.getGL() else path.getX11(), entry.path,
            });
            switch (entry.kind) {
                .file => {
                    if (toolbox_pkg.isCHeader(entry.basename)) {
                        try toolbox.copy(toolbox.pathJoin(&.{
                            include_path, entry.path,
                        }), dest);
                    }
                },
                .directory => try toolbox.make(dest),
                else => return error.UnexpectedEntryKind,
            }
        }
    }

    include_path = toolbox.pathJoin(&.{
        path.getTmp(), "include", "X11",
    });
    include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var xpoll_h = try include_dir.readFileAlloc(toolbox.getAllocator(), "Xpoll.h.in", std.math.maxInt(usize));
    xpoll_h = try std.mem.replaceOwned(u8, toolbox.getAllocator(), xpoll_h, "@USE_FDS_BITS@", "__fds_bits");
    try toolbox.write(path.getX11(), "Xpoll.h", xpoll_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_xcb(toolbox: *Toolbox, path: *const Paths) !void {
    try toolbox.clone(.xcb, path.getTmp());
    try toolbox.clone(.xcbproto, path.getTmp2());

    try toolbox.make(path.getXcb());

    const out_path = toolbox.pathJoin(&.{
        path.getTmp2(), "out",
    });
    try toolbox.run(.{
        .argv = &[_][]const u8{
            "./autogen.sh",
        },
        .cwd = path.getTmp2(),
    });
    try toolbox.run(.{
        .argv = &[_][]const u8{
            "make",
        },
        .cwd = path.getTmp2(),
    });
    try toolbox.run(.{
        .argv = &[_][]const u8{
            "make",
            toolbox.fmt("DESTDIR=\"{s}\"", .{
                out_path,
            }),
            "install",
        },
        .cwd = path.getTmp2(),
    });

    const c_client_out_path = toolbox.pathJoin(&.{
        path.getTmp2(), "c_client_out",
    });
    try toolbox.make(c_client_out_path);

    var out_dir = try std.fs.openDirAbsolute(out_path, .{
        .iterate = true,
    });
    defer out_dir.close();

    var walker = try out_dir.walk(toolbox.getAllocator());
    defer walker.deinit();

    var python_path: []const u8 = undefined;

    loop: while (try walker.next()) |*entry| {
        switch (entry.kind) {
            .directory => {
                if (std.mem.eql(u8, entry.basename, "site-packages")) {
                    python_path = toolbox.pathJoin(&.{
                        out_path, entry.path,
                    });
                    break :loop;
                }
            },
            else => {},
        }
    }

    var env = std.process.EnvMap.init(toolbox.getAllocator());
    try env.put("PYTHONPATH", python_path);

    const xcbproto_xml_path = toolbox.pathJoin(&.{
        path.getTmp2(), "src",
    });
    var xcbproto_xml_dir = try std.fs.openDirAbsolute(xcbproto_xml_path, .{
        .iterate = true,
    });
    defer xcbproto_xml_dir.close();

    const c_client_py_path = toolbox.pathJoin(&.{
        path.getTmp(), "src", "c_client.py",
    });

    var it = xcbproto_xml_dir.iterate();
    while (try it.next()) |*entry| {
        const xml = toolbox.pathJoin(&.{
            xcbproto_xml_path, entry.name,
        });
        switch (entry.kind) {
            .file => {
                if (std.mem.endsWith(u8, entry.name, ".xml")) {
                    try toolbox.run(.{
                        .argv = &.{
                            "python3", c_client_py_path, "-c", "_", "-l", "_", "-s", "_", xml,
                        },
                        .cwd = c_client_out_path,
                        .env = &env,
                    });
                }
            },
            else => {},
        }
    }

    const xcb_src_path = toolbox.pathJoin(&.{
        path.getTmp(), "src",
    });
    var dir: std.fs.Dir = undefined;

    for ([_][]const u8{
        xcb_src_path, c_client_out_path,
    }) |header_path| {
        dir = try std.fs.openDirAbsolute(header_path, .{
            .iterate = true,
        });
        defer dir.close();

        it = dir.iterate();
        while (try it.next()) |*entry| {
            switch (entry.kind) {
                .file => {
                    if (toolbox_pkg.isCHeader(entry.name)) {
                        try toolbox.copy(toolbox.pathJoin(&.{
                            header_path, entry.name,
                        }), toolbox.pathJoin(&.{
                            path.getXcb(), entry.name,
                        }));
                    }
                },
                else => {},
            }
        }
    }

    for ([_][]const u8{
        path.getTmp(), path.getTmp2(),
    }) |tmp| {
        try std.fs.deleteTreeAbsolute(tmp);
    }
}

fn update(toolbox: *Toolbox) !void {
    const path = try Paths.init(toolbox);

    inline for (@typeInfo(@TypeOf(path)).@"struct".fields) |field| {
        std.fs.deleteTreeAbsolute(@field(path, field.name)) catch |err| {
            switch (err) {
                error.FileNotFound => {},
                else => return err,
            }
        };
    }

    try update_xkbcommon(toolbox, &path);
    try update_X11(toolbox, &path);
    try update_Xcursor(toolbox, &path);
    try update_Xrandr(toolbox, &path);
    try update_Xfixes(toolbox, &path);
    try update_Xrender(toolbox, &path);
    try update_Xinerama(toolbox, &path);
    try update_Xi(toolbox, &path);
    try update_XScrnSaver(toolbox, &path);
    try update_Xext(toolbox, &path);
    try update_xorgproto(toolbox, &path);
    try update_xcb(toolbox, &path);

    try toolbox.clean(&.{
        "GL", "X11", "xcb", "xkbcommon",
    }, &.{});
}

const FromZon = toolbox_pkg.Repositories(.{
    .toolbox,
});

const DuringExec = toolbox_pkg.Repositories(.{
    .X11, .xcb, .xcbproto, .Xcursor, .Xext, .Xfixes, .Xi, .Xinerama, .xkbcommon, .xorgproto, .Xrandr, .Xrender, .XScrnSaver,
});

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    var toolbox = try Toolbox.init(FromZon, DuringExec, builder, optimize, .X11_zig, "0x73d0ebf76c33e052", &.{
        "X11", "GL", "xcb", "xkbcommon",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = .github,
            .ref = .tag,
        },
    }, .{
        .X11 = .{
            .name = "xorg/lib/libx11",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .xcb = .{
            .name = "xorg/lib/libxcb",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .xcbproto = .{
            .name = "xorg/proto/xcbproto",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xcursor = .{
            .name = "xorg/lib/libxcursor",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xext = .{
            .name = "xorg/lib/libxext",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xfixes = .{
            .name = "xorg/lib/libxfixes",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xi = .{
            .name = "xorg/lib/libxi",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xinerama = .{
            .name = "xorg/lib/libxinerama",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .xkbcommon = .{
            .name = "xkbcommon/libxkbcommon",
            .host = .github,
            .ref = .tag,
        },
        .xorgproto = .{
            .name = "xorg/proto/xorgproto",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xrandr = .{
            .name = "xorg/lib/libxrandr",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .Xrender = .{
            .name = "xorg/lib/libxrender",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
        .XScrnSaver = .{
            .name = "xorg/lib/libxscrnsaver",
            .domain = "freedesktop.org",
            .host = .gitlab,
            .ref = .tag,
        },
    });
    defer toolbox.deinit();

    if (toolbox.getUpdate()) try update(&toolbox);

    const lib = builder.addLibrary(.{
        .name = "X11",
        .root_module = std.Build.Module.create(builder, .{
            .root_source_file = builder.addWriteFiles().add("empty.c", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    for ([_][]const u8{
        "GL", "X11", "xcb", "xkbcommon",
    }) |header| {
        toolbox.addHeader(lib, try builder.build_root.join(builder.allocator, &.{
            header,
        }), header, &.{
            ".h",
        });
    }

    builder.installArtifact(lib);
}
