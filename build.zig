const std = @import("std");
const build_zig_zon = @import("build.zig.zon");
const toolbox = @import("toolbox");
const VerboseBuilder = toolbox.VerboseBuilder;

const Paths = struct {
    GL: []const u8,
    X11: []const u8,
    X11_include: []const u8,
    X11_include_X11: []const u8,
    X11_include_X11_Xtrans: []const u8,
    X11_include_X11_Xcursor: []const u8,
    X11_include_X11_extensions: []const u8,
    X11_src: []const u8,
    X11_modules: []const u8,
    xkbcommon: []const u8,
    xcb: []const u8,
    xcb_xcb: []const u8,
    Xau: []const u8,

    fn init(pkg_builder: *VerboseBuilder) @This() {
        return .{
            .GL = "GL",
            .X11 = "X11",
            .X11_include = pkg_builder.resolve(&.{ "X11", "include" }),
            .X11_include_X11 = pkg_builder.resolve(&.{ "X11", "include", "X11" }),
            .X11_include_X11_Xtrans = pkg_builder.resolve(&.{ "X11", "include", "X11", "Xtrans" }),
            .X11_include_X11_Xcursor = pkg_builder.resolve(&.{ "X11", "include", "X11", "Xcursor" }),
            .X11_include_X11_extensions = pkg_builder.resolve(&.{ "X11", "include", "X11", "extensions" }),
            .X11_src = pkg_builder.resolve(&.{ "X11", "src" }),
            .X11_modules = pkg_builder.resolve(&.{ "X11", "modules" }),
            .xkbcommon = "xkbcommon",
            .xcb = "xcb",
            .xcb_xcb = pkg_builder.resolve(&.{ "xcb", "xcb" }),
            .Xau = "Xau",
        };
    }
};

fn update_xkbcommon(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xkbcommon_dep = pkg_builder.dependency("xkbcommon");
    var xkbcommon_builder = VerboseBuilder.initFromDependency(xkbcommon_dep);

    while (try xkbcommon_builder.iterate(&.{ "include", "xkbcommon" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try pkg_builder.copy(&.{ path.xkbcommon, entry.name }, &xkbcommon_builder, &.{ "include", "xkbcommon", entry.name });
                }
            },
            else => {},
        }
    }
}

fn update_X11(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const X11_dep = pkg_builder.dependency("X11");
    var X11_builder = VerboseBuilder.initFromDependency(X11_dep);

    while (try X11_builder.walk(&.{ "include", "X11" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename)) {
                    try pkg_builder.copy(&.{ path.X11_include_X11, entry.path }, &X11_builder, &.{ "include", "X11", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ path.X11_include_X11, entry.path }),
            else => {},
        }
    }

    var xlib_conf_h = try X11_builder.readFile(&.{ "include", "X11", "XlibConf.h.in" });
    xlib_conf_h = X11_builder.replace(xlib_conf_h, "#undef XTHREADS", "#define XTHREADS 1");
    xlib_conf_h = X11_builder.replace(xlib_conf_h, "#undef XUSE_MTSAFE_API", "#define XUSE_MTSAFE_API 1");
    try pkg_builder.writeFile(&.{ path.X11_include_X11, "XlibConf.h" }, xlib_conf_h);

    while (try X11_builder.walk(&.{"src"})) |entry| {
        switch (entry.kind) {
            .file => {
                if ((toolbox.isCSource(entry.basename) and
                    !std.mem.startsWith(u8, entry.path, pkg_builder.resolve(&.{ "xlibi18n", "lcUniConv" }))) or
                    toolbox.isCHeader(entry.basename))
                {
                    try pkg_builder.copy(&.{ path.X11_src, entry.path }, &X11_builder, &.{ "src", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ path.X11_src, entry.path }),
            else => {},
        }
    }

    while (try X11_builder.walk(&.{"modules"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.basename)) {
                    try pkg_builder.copy(&.{ path.X11_modules, entry.path }, &X11_builder, &.{ "modules", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ path.X11_modules, entry.path }),
            else => {},
        }
    }
}

fn update_Xcursor(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xcursor_dep = pkg_builder.dependency("Xcursor");
    var xcursor_builder = VerboseBuilder.initFromDependency(xcursor_dep);

    var xcursor_h = try xcursor_builder.readFile(&.{ "include", "X11", "Xcursor", "Xcursor.h.in" });

    const uri = try std.Uri.parse(build_zig_zon.dependencies.Xcursor.url);
    var xcursor_version = pkg_builder.uriComponent(&uri.query.?)[4..];
    xcursor_version = xcursor_version[std.mem.indexOfAny(u8, xcursor_version, "0123456789").?..];

    var it = std.mem.tokenizeScalar(u8, xcursor_version, '.');
    var token = it.next().?;
    xcursor_h = pkg_builder.replace(xcursor_h, "#undef XCURSOR_LIB_MAJOR", pkg_builder.fmt("#define XCURSOR_LIB_MAJOR {s}", .{token}));
    token = it.next().?;
    xcursor_h = pkg_builder.replace(xcursor_h, "#undef XCURSOR_LIB_MINOR", pkg_builder.fmt("#define XCURSOR_LIB_MINOR {s}", .{token}));
    token = it.next().?;
    xcursor_h = pkg_builder.replace(xcursor_h, "#undef XCURSOR_LIB_REVISION", pkg_builder.fmt("#define XCURSOR_LIB_REVISION {s}", .{token}));

    try pkg_builder.writeFile(&.{ path.X11_include_X11_Xcursor, "Xcursor.h" }, xcursor_h);
}

fn update_Xrandr(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xrandr_dep = pkg_builder.dependency("Xrandr");
    var xrandr_builder = VerboseBuilder.initFromDependency(xrandr_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "Xrandr.h" }, &xrandr_builder, &.{ "include", "X11", "extensions", "Xrandr.h" });
}

fn update_Xfixes(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xfixes_dep = pkg_builder.dependency("Xfixes");
    var xfixes_builder = VerboseBuilder.initFromDependency(xfixes_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "Xfixes.h" }, &xfixes_builder, &.{ "include", "X11", "extensions", "Xfixes.h" });
}

fn update_Xrender(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xrender_dep = pkg_builder.dependency("Xrender");
    var xrender_builder = VerboseBuilder.initFromDependency(xrender_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "Xrender.h" }, &xrender_builder, &.{ "include", "X11", "extensions", "Xrender.h" });
}

fn update_Xinerama(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xinerama_dep = pkg_builder.dependency("Xinerama");
    var xinerama_builder = VerboseBuilder.initFromDependency(xinerama_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "Xinerama.h" }, &xinerama_builder, &.{ "include", "X11", "extensions", "Xinerama.h" });
    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "panoramiXext.h" }, &xinerama_builder, &.{ "include", "X11", "extensions", "panoramiXext.h" });
}

fn update_Xi(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xi_dep = pkg_builder.dependency("Xi");
    var xi_builder = VerboseBuilder.initFromDependency(xi_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "XInput.h" }, &xi_builder, &.{ "include", "X11", "extensions", "XInput.h" });
    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "XInput2.h" }, &xi_builder, &.{ "include", "X11", "extensions", "XInput2.h" });
}

fn update_Xau(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xau_dep = pkg_builder.dependency("Xau");
    var xau_builder = VerboseBuilder.initFromDependency(xau_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11, "Xauth.h" }, &xau_builder, &.{ "include", "X11", "Xauth.h" });

    while (try xau_builder.iterate(&.{"."})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCSource(entry.name) and !std.mem.eql(u8, entry.name, "Autest.c")) {
                    try pkg_builder.copy(&.{ path.Xau, entry.name }, &xau_builder, &.{entry.name});
                }
            },
            else => {},
        }
    }
}

fn update_XScrnSaver(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xscrnsaver_dep = pkg_builder.dependency("XScrnSaver");
    var xscrnsaver_builder = VerboseBuilder.initFromDependency(xscrnsaver_dep);

    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, "scrnsaver.h" }, &xscrnsaver_builder, &.{ "include", "X11", "extensions", "scrnsaver.h" });
}

fn update_Xext(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xext_dep = pkg_builder.dependency("Xext");
    var xext_builder = VerboseBuilder.initFromDependency(xext_dep);

    while (try xext_builder.iterate(&.{ "include", "X11", "extensions" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try pkg_builder.copy(&.{ path.X11_include_X11_extensions, entry.name }, &xext_builder, &.{ "include", "X11", "extensions", entry.name });
                }
            },
            else => {},
        }
    }
}

fn update_Xtrans(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xtrans_dep = pkg_builder.dependency("Xtrans");
    var xtrans_builder = VerboseBuilder.initFromDependency(xtrans_dep);

    while (try xtrans_builder.iterate(&.{"."})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.name)) {
                    try pkg_builder.copy(&.{ path.X11_include_X11_Xtrans, entry.name }, &xtrans_builder, &.{entry.name});
                }
            },
            else => {},
        }
    }
}

fn update_xorgproto(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xorgproto_dep = pkg_builder.dependency("xorgproto");
    var xorgproto_builder = VerboseBuilder.initFromDependency(xorgproto_dep);

    while (try xorgproto_builder.walk(&.{ "include", "X11" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename)) {
                    pkg_builder.copy(&.{ path.X11_include_X11, entry.path }, &xorgproto_builder, &.{ "include", "X11", entry.path }) catch |err| switch (err) {
                        error.OverwritingCopy => {},
                        else => return err,
                    };
                }
            },
            .directory => try pkg_builder.make(&.{ path.X11_include_X11, entry.path }),
            else => {},
        }
    }

    while (try xorgproto_builder.walk(&.{ "include", "GL" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename)) {
                    try pkg_builder.copy(&.{ path.GL, entry.path }, &xorgproto_builder, &.{ "include", "GL", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ path.GL, entry.path }),
            else => {},
        }
    }

    var xpoll_h = try xorgproto_builder.readFile(&.{ "include", "X11", "Xpoll.h.in" });
    xpoll_h = pkg_builder.replace(xpoll_h, "@USE_FDS_BITS@", "__fds_bits");
    try pkg_builder.writeFile(&.{ path.X11_include_X11, "Xpoll.h" }, xpoll_h);
}

fn update_xcb(pkg_builder: *VerboseBuilder, path: *const Paths) !void {
    const xcb_dep = pkg_builder.dependency("xcb");
    var xcb_builder = VerboseBuilder.initFromDependency(xcb_dep);
    const xcbproto_dep = pkg_builder.dependency("xcbproto");
    var xcbproto_builder = VerboseBuilder.initFromDependency(xcbproto_dep);

    try xcbproto_builder.remove(&.{"c_client.py"});
    try xcbproto_builder.copy(&.{"c_client.py"}, &xcb_builder, &.{ "src", "c_client.py" });
    _ = try xcbproto_builder.run(&.{"./autogen.sh"}, xcbproto_builder.ptrCwd().*);
    _ = try xcbproto_builder.run(&.{"make"}, xcbproto_builder.ptrCwd().*);
    _ = try xcbproto_builder.run(&.{ "make", xcbproto_builder.fmt("DESTDIR={s}", .{xcbproto_builder.resolve(&.{ "..", "out" })}), "install" }, xcbproto_builder.ptrCwd().*);

    try xcbproto_builder.make(&.{"c_client_out"});

    const python_path: []const u8 = loop: {
        while (try xcbproto_builder.walk(&.{"out"})) |entry| {
            switch (entry.kind) {
                .directory => {
                    if (std.mem.eql(u8, entry.basename, "site-packages")) {
                        break :loop pkg_builder.resolve(&.{ "out", entry.path });
                    }
                },
                else => {},
            }
        } else unreachable;
    };

    try xcbproto_builder.putEnvVar("PYTHONPATH", python_path);

    var c_client_out_dir = try xcbproto_builder.openDir(&.{"c_client_out"});
    defer c_client_out_dir.close();

    while (try xcbproto_builder.iterate(&.{"src"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isXmlFile(entry.name)) {
                    _ = try xcbproto_builder.run(&.{ "python3", pkg_builder.resolve(&.{ "..", "c_client.py" }), "-c", "_", "-l", "_", "-s", "_", pkg_builder.resolve(&.{ "..", "src", entry.name }) }, c_client_out_dir);
                }
            },
            else => {},
        }
    }

    while (try xcb_builder.iterate(&.{"src"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.name)) {
                    try pkg_builder.copy(&.{ path.xcb_xcb, entry.name }, &xcb_builder, &.{ "src", entry.name });
                }
            },
            else => {},
        }
    }

    while (try xcbproto_builder.iterate(&.{"c_client_out"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.name)) {
                    try pkg_builder.copy(&.{ path.xcb_xcb, entry.name }, &xcbproto_builder, &.{ "c_client_out", entry.name });
                }
            },
            else => {},
        }
    }
}

fn updateFn(pkg_builder: *VerboseBuilder) !void {
    const path = Paths.init(pkg_builder);

    inline for (@typeInfo(@TypeOf(path)).@"struct".fields) |field| {
        try pkg_builder.remove(&.{@field(path, field.name)});
        try pkg_builder.make(&.{@field(path, field.name)});
    }

    try update_xkbcommon(pkg_builder, &path);
    try update_X11(pkg_builder, &path);
    try update_Xcursor(pkg_builder, &path);
    try update_Xrandr(pkg_builder, &path);
    try update_Xfixes(pkg_builder, &path);
    try update_Xrender(pkg_builder, &path);
    try update_Xinerama(pkg_builder, &path);
    try update_Xi(pkg_builder, &path);
    try update_Xau(pkg_builder, &path);
    try update_XScrnSaver(pkg_builder, &path);
    try update_Xext(pkg_builder, &path);
    try update_Xtrans(pkg_builder, &path);
    try update_xorgproto(pkg_builder, &path);
    try update_xcb(pkg_builder, &path);
}

fn buildFn(pkg_builder: *VerboseBuilder) !void {
    const path = Paths.init(pkg_builder);

    const XLOCALELIBDIR = pkg_builder.option([]const u8, pkg_builder.resolve(&.{ "", "usr", "share", "X11", "locale" }), "with-locale-lib-dir", "");
    const XCB_QUEUE_BUFFER_SIZE = pkg_builder.option([]const u8, "16384", "with-queue-size", "");
    _ = try std.fmt.parseUnsigned(u32, XCB_QUEUE_BUFFER_SIZE, 10);
    const IOV_MAX = pkg_builder.option([]const u8, "16", "iov-max", "");
    _ = try std.fmt.parseUnsigned(u32, IOV_MAX, 10);

    const makekeys = pkg_builder.addExecutable("makekeys");
    pkg_builder.linkLibC(makekeys);
    pkg_builder.addCSource(makekeys, &.{ path.X11_src, "util", "makekeys.c" }, &.{});

    const run_makekeys = pkg_builder.addRunArtifact(makekeys);
    pkg_builder.expectExitCode(run_makekeys, 0);
    pkg_builder.setCwd(run_makekeys, &.{"."});
    pkg_builder.addArgs(run_makekeys, &.{pkg_builder.resolve(&.{ path.X11_include_X11, "keysymdef.h" })});
    const ks_tables_h_content = pkg_builder.captureStdOut(run_makekeys);
    const write_file = pkg_builder.addWriteFiles();
    const ks_tables_h = pkg_builder.addCopyFile(write_file, ks_tables_h_content, &.{ "include", "ks_tables.h" });

    const lib = pkg_builder.addLibrary("X11");
    pkg_builder.addIncludePath(lib, ks_tables_h.dirname());
    pkg_builder.addInclude(lib, &.{ "X11", "include" });
    pkg_builder.addInclude(lib, &.{ "X11", "include", "X11" });
    pkg_builder.addInclude(lib, &.{ "X11", "src" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xcms" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xkb" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xlibi18n" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xlibi18n", "lcUniConv" });
    pkg_builder.addInclude(lib, &.{"xcb"});

    //pkg_builder.installHeaders(lib, &.{"GL"}, "GL", &toolbox.ext.c.header);
    //pkg_builder.installHeaders(lib, &.{"X11"}, "X11", &toolbox.ext.c.header);
    //pkg_builder.installHeaders(lib, &.{"xcb"}, "xcb", &toolbox.ext.c.header);
    //pkg_builder.installHeaders(lib, &.{"xkbcommon"}, "xkbcommon", &toolbox.ext.c.header);

    pkg_builder.linkLibC(lib);

    const src_flags = [_][]const u8{
        pkg_builder.concat(&.{ "-DXCMSDIR=\"", pkg_builder.resolve(&.{ path.X11_src, "xcms" }), "\"" }),
        pkg_builder.concat(&.{ "-DXLOCALELIBDIR=\"", XLOCALELIBDIR, "\"" }),
        "-DHAVE_SYS_IOCTL_H=1",
        "-DXKB=1",
    };

    while (try pkg_builder.walk(&.{path.X11_src})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCSource(entry.basename) and
                    !std.mem.startsWith(u8, entry.basename, "os2") and
                    !std.mem.eql(u8, entry.path, pkg_builder.resolve(&.{ "util", "makekeys.c" })))
                {
                    pkg_builder.addCSource(lib, &.{ path.X11_src, entry.path }, &src_flags);
                }
            },
            else => {},
        }
    }

    const modules_flags = [_][]const u8{ "-DXIM_t=1", "-DTRANS_CLIENT=1" };

    while (try pkg_builder.walk(&.{path.X11_modules})) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ path.X11_modules, entry.path }, &modules_flags),
            else => {},
        }
    }

    const xcb_flags = [_][]const u8{
        pkg_builder.concat(&.{ "-DXCB_QUEUE_BUFFER_SIZE=", XCB_QUEUE_BUFFER_SIZE }),
        pkg_builder.concat(&.{ "-DIOV_MAX=", IOV_MAX }),
    };

    while (try pkg_builder.walk(&.{path.xcb_xcb})) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ path.xcb_xcb, entry.path }, &xcb_flags),
            else => {},
        }
    }

    while (try pkg_builder.walk(&.{path.Xau})) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ path.Xau, entry.path }, &.{}),
            else => {},
        }
    }

    pkg_builder.installArtifact(lib);
    pkg_builder.dependOn(&lib.step, &write_file.step);
    pkg_builder.dependOn(pkg_builder.getInstallStep(), &write_file.step);
}

pub fn build(builder: *std.Build) !void {
    var pkg_builder = try VerboseBuilder.init(builder, build_zig_zon, buildFn, updateFn);

    try pkg_builder.fetch(build_zig_zon);
    try pkg_builder.update();
    try pkg_builder.build();
}
