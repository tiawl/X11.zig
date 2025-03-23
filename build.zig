const std = @import("std");
const toolbox = @import("toolbox");

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

    fn init() !@This() {
        const X11_path = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
            "X11",
        });

        return .{
            .__GL = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
                "GL",
            }),
            .__X11 = X11_path,
            .__tmp = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
                "tmp",
            }),
            .__tmp2 = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
                "tmp2",
            }),
            .__xkbcommon = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
                "xkbcommon",
            }),
            .__xcb = try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
                "xcb",
            }),
            .__ext = toolbox.instance().ptrBuilder().pathJoin(&.{
                X11_path, "extensions",
            }),
        };
    }
};

fn update_xkbcommon(path: *const Paths) !void {
    try toolbox.instance().clone("xkbcommon", path.getTmp());

    const include_path = toolbox.instance().ptrBuilder().pathJoin(&.{ path.getTmp(), "include", "xkbcommon" });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    try toolbox.instance().make(path.getXkbcommon());

    var it = include_dir.iterate();
    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.instance().ptrBuilder().pathJoin(&.{
                        path.getXkbcommon(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_X11(path: *const Paths) !void {
    try toolbox.instance().clone("X11", path.getTmp());

    const include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11",
    });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();
    try toolbox.instance().make(path.getX11());

    var it = include_dir.iterate();
    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.instance().ptrBuilder().pathJoin(&.{
                        path.getX11(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    const include_ext_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        include_path, "extensions",
    });
    var include_ext_dir = try std.fs.openDirAbsolute(include_ext_path, .{
        .iterate = true,
    });
    defer include_ext_dir.close();
    try toolbox.instance().make(path.getExt());
    it = include_ext_dir.iterate();

    while (try it.next()) |*entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                        include_ext_path, entry.name,
                    }), toolbox.instance().ptrBuilder().pathJoin(&.{
                        path.getExt(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    var xlib_conf_h = try include_dir.readFileAlloc(toolbox.instance().getBuilder().allocator, "XlibConf.h.in", std.math.maxInt(usize));

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
        xlib_conf_h = try std.mem.replaceOwned(u8, toolbox.instance().getBuilder().allocator, xlib_conf_h, search_and_replace.match, search_and_replace.replace);
    }

    try toolbox.instance().write(path.getX11(), "XlibConf.h", xlib_conf_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xcursor(path: *const Paths) !void {
    const xcursor_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getX11(), "Xcursor",
    });

    try toolbox.instance().clone("Xcursor", path.getTmp());

    const include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11", "Xcursor",
    });
    var include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var xcursor_h = try include_dir.readFileAlloc(toolbox.instance().getBuilder().allocator, "Xcursor.h.in", std.math.maxInt(usize));

    var xcursor_version = try toolbox.reference("Xcursor");
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
        xcursor_h = try std.mem.replaceOwned(u8, toolbox.instance().getBuilder().allocator, xcursor_h, match[index], toolbox.instance().ptrBuilder().fmt("{s} {s}", .{
            replace[index], token.*,
        }));
        index += 1;
    }

    try toolbox.instance().make(xcursor_path);
    try toolbox.instance().write(xcursor_path, "Xcursor.h", xcursor_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xrandr(path: *const Paths) !void {
    try toolbox.instance().clone("Xrandr", path.getTmp());

    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xrandr.h",
    }), toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getExt(), "Xrandr.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xfixes(path: *const Paths) !void {
    try toolbox.instance().clone("Xfixes", path.getTmp());

    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xfixes.h",
    }), toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getExt(), "Xfixes.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xrender(path: *const Paths) !void {
    try toolbox.instance().clone("Xrender", path.getTmp());

    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "Xrender.h",
    }), toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getExt(), "Xrender.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xinerama(path: *const Paths) !void {
    try toolbox.instance().clone("Xinerama", path.getTmp());

    for ([_][]const u8{
        "Xinerama.h", "panoramiXext.h",
    }) |file| {
        try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
            path.getTmp(), "include", "X11", "extensions", file,
        }), toolbox.instance().ptrBuilder().pathJoin(&.{
            path.getExt(), file,
        }));
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xi(path: *const Paths) !void {
    try toolbox.instance().clone("Xi", path.getTmp());

    for ([_][]const u8{
        "XInput.h", "XInput2.h",
    }) |file| {
        try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
            path.getTmp(), "include", "X11", "extensions", file,
        }), toolbox.instance().ptrBuilder().pathJoin(&.{
            path.getExt(), file,
        }));
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_XScrnSaver(path: *const Paths) !void {
    try toolbox.instance().clone("XScrnSaver", path.getTmp());

    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11", "extensions", "scrnsaver.h",
    }), toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getExt(), "scrnsaver.h",
    }));

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_Xext(path: *const Paths) !void {
    try toolbox.instance().clone("Xext", path.getTmp());

    const include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
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
                if (toolbox.isCHeader(entry.name)) {
                    try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                        include_path, entry.name,
                    }), toolbox.instance().ptrBuilder().pathJoin(&.{
                        path.getExt(), entry.name,
                    }));
                }
            },
            else => {},
        }
    }

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_xorgproto(path: *const Paths) !void {
    try toolbox.instance().clone("xorgproto", path.getTmp());

    var include_path: []const u8 = undefined;
    var include_dir: std.fs.Dir = undefined;
    var walker: std.fs.Dir.Walker = undefined;

    try toolbox.instance().make(path.getGL());

    inline for ([_][]const u8{
        "GL", "X11",
    }) |component| {
        include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
            path.getTmp(), "include", component,
        });
        include_dir = try std.fs.openDirAbsolute(include_path, .{
            .iterate = true,
        });
        defer include_dir.close();

        walker = try include_dir.walk(toolbox.instance().getBuilder().allocator);
        defer walker.deinit();

        while (try walker.next()) |*entry| {
            const dest = toolbox.instance().ptrBuilder().pathJoin(&.{
                if (std.mem.eql(u8, "GL", component)) path.getGL() else path.getX11(), entry.path,
            });
            switch (entry.kind) {
                .file => {
                    if (toolbox.isCHeader(entry.basename)) {
                        try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                            include_path, entry.path,
                        }), dest);
                    }
                },
                .directory => try toolbox.instance().make(dest),
                else => return error.UnexpectedEntryKind,
            }
        }
    }

    include_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "include", "X11",
    });
    include_dir = try std.fs.openDirAbsolute(include_path, .{
        .iterate = true,
    });
    defer include_dir.close();

    var xpoll_h = try include_dir.readFileAlloc(toolbox.instance().getBuilder().allocator, "Xpoll.h.in", std.math.maxInt(usize));
    xpoll_h = try std.mem.replaceOwned(u8, toolbox.instance().getBuilder().allocator, xpoll_h, "@USE_FDS_BITS@", "__fds_bits");
    try toolbox.instance().write(path.getX11(), "Xpoll.h", xpoll_h);

    try std.fs.deleteTreeAbsolute(path.getTmp());
}

fn update_xcb(path: *const Paths) !void {
    try toolbox.instance().clone("xcb", path.getTmp());
    try toolbox.instance().clone("xcbproto", path.getTmp2());

    try toolbox.instance().make(path.getXcb());

    const out_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp2(), "out",
    });
    try toolbox.instance().run(.{
        .argv = &[_][]const u8{
            "./autogen.sh",
        },
        .cwd = path.getTmp2(),
    });
    try toolbox.instance().run(.{
        .argv = &[_][]const u8{
            "make",
        },
        .cwd = path.getTmp2(),
    });
    try toolbox.instance().run(.{
        .argv = &[_][]const u8{
            "make",
            toolbox.instance().ptrBuilder().fmt("DESTDIR=\"{s}\"", .{
                out_path,
            }),
            "install",
        },
        .cwd = path.getTmp2(),
    });

    const c_client_out_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp2(), "c_client_out",
    });
    try toolbox.instance().make(c_client_out_path);

    var out_dir = try std.fs.openDirAbsolute(out_path, .{
        .iterate = true,
    });
    defer out_dir.close();

    var walker = try out_dir.walk(toolbox.instance().getBuilder().allocator);
    defer walker.deinit();

    var python_path: []const u8 = undefined;

    loop: while (try walker.next()) |*entry| {
        switch (entry.kind) {
            .directory => {
                if (std.mem.eql(u8, entry.basename, "site-packages")) {
                    python_path = toolbox.instance().ptrBuilder().pathJoin(&.{
                        out_path, entry.path,
                    });
                    break :loop;
                }
            },
            else => {},
        }
    }

    var env = std.process.EnvMap.init(toolbox.instance().getBuilder().allocator);
    try env.put("PYTHONPATH", python_path);

    const xcbproto_xml_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp2(), "src",
    });
    var xcbproto_xml_dir = try std.fs.openDirAbsolute(xcbproto_xml_path, .{
        .iterate = true,
    });
    defer xcbproto_xml_dir.close();

    const c_client_py_path = toolbox.instance().ptrBuilder().pathJoin(&.{
        path.getTmp(), "src", "c_client.py",
    });

    var it = xcbproto_xml_dir.iterate();
    while (try it.next()) |*entry| {
        const xml = toolbox.instance().ptrBuilder().pathJoin(&.{
            xcbproto_xml_path, entry.name,
        });
        switch (entry.kind) {
            .file => {
                if (std.mem.endsWith(u8, entry.name, ".xml")) {
                    try toolbox.instance().run(.{
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

    const xcb_src_path = toolbox.instance().ptrBuilder().pathJoin(&.{
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
                    if (toolbox.isCHeader(entry.name)) {
                        try toolbox.instance().copy(toolbox.instance().ptrBuilder().pathJoin(&.{
                            header_path, entry.name,
                        }), toolbox.instance().ptrBuilder().pathJoin(&.{
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

fn update() !void {
    const path = try Paths.init();

    inline for (@typeInfo(@TypeOf(path)).@"struct".fields) |field| {
        std.fs.deleteTreeAbsolute(@field(path, field.name)) catch |err| {
            switch (err) {
                error.FileNotFound => {},
                else => return err,
            }
        };
    }

    try update_xkbcommon(&path);
    try update_X11(&path);
    try update_Xcursor(&path);
    try update_Xrandr(&path);
    try update_Xfixes(&path);
    try update_Xrender(&path);
    try update_Xinerama(&path);
    try update_Xi(&path);
    try update_XScrnSaver(&path);
    try update_Xext(&path);
    try update_xorgproto(&path);
    try update_xcb(&path);

    try toolbox.instance().clean(&.{
        "GL", "X11", "xcb", "xkbcommon",
    }, &.{});
}

const FromZon = toolbox.Repositories(.{
    .toolbox,
});

const DuringExec = toolbox.Repositories(.{
    .X11, .xcb, .xcbproto, .Xcursor, .Xext, .Xfixes, .Xi, .Xinerama, .xkbcommon, .xorgproto, .Xrandr, .Xrender, .XScrnSaver,
});

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    try toolbox.init(FromZon, DuringExec, builder, optimize, .X11_zig, "0x73d0ebf76c33e052", &.{
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

    if (toolbox.instance().getUpdate()) try update();

    const lib = toolbox.instance().ptrBuilder().addStaticLibrary(.{
        .name = "X11",
        .root_source_file = toolbox.instance().ptrBuilder().addWriteFiles().add("empty.c", ""),
        .target = target,
        .optimize = optimize,
    });

    for ([_][]const u8{
        "GL", "X11", "xcb", "xkbcommon",
    }) |header| {
        toolbox.instance().addHeader(lib, try toolbox.instance().getBuilder().build_root.join(toolbox.instance().getBuilder().allocator, &.{
            header,
        }), header, &.{
            ".h",
        });
    }

    toolbox.instance().ptrBuilder().installArtifact(lib);
}
