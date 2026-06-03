const std = @import("std");
const build_zig_zon = @import("build.zig.zon");
const toolbox = @import("toolbox");
const VerboseBuilder = toolbox.VerboseBuilder;

fn updateXkbcommon(pkg_builder: *VerboseBuilder) !void {
    const xkbcommon_dep = pkg_builder.verboseDependency("xkbcommon");
    var xkbcommon_builder = VerboseBuilder.initFromDependency(xkbcommon_dep);

    while (try xkbcommon_builder.iterate(&.{ "include", "xkbcommon" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try pkg_builder.copy(&.{ "xkbcommon", entry.name }, &xkbcommon_builder, &.{ "include", "xkbcommon", entry.name });
                }
            },
            else => {},
        }
    }
}

fn updateX11(pkg_builder: *VerboseBuilder) !void {
    const x11_dep = pkg_builder.verboseDependency("X11");
    var x11_builder = VerboseBuilder.initFromDependency(x11_dep);

    while (try x11_builder.walk(&.{ "include", "X11" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename) or toolbox.isCTemplate(entry.basename)) {
                    try pkg_builder.copy(&.{ "X11", "include", "X11", entry.path }, &x11_builder, &.{ "include", "X11", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ "X11", "include", "X11", entry.path }),
            else => {},
        }
    }

    while (try x11_builder.walk(&.{"src"})) |entry| {
        switch (entry.kind) {
            .file => {
                if ((toolbox.isCSource(entry.basename) and
                    !std.mem.startsWith(u8, entry.path, pkg_builder.resolve(&.{ "xlibi18n", "lcUniConv" }))) or
                    toolbox.isCHeader(entry.basename))
                {
                    try pkg_builder.copy(&.{ "X11", "src", entry.path }, &x11_builder, &.{ "src", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ "X11", "src", entry.path }),
            else => {},
        }
    }

    while (try x11_builder.walk(&.{"modules"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.basename)) {
                    try pkg_builder.copy(&.{ "X11", "modules", entry.path }, &x11_builder, &.{ "modules", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ "X11", "modules", entry.path }),
            else => {},
        }
    }
}

fn updateXcursor(pkg_builder: *VerboseBuilder) !void {
    const xcursor_dep = pkg_builder.verboseDependency("Xcursor");
    var xcursor_builder = VerboseBuilder.initFromDependency(xcursor_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "Xcursor", "Xcursor.h.in" }, &xcursor_builder, &.{ "include", "X11", "Xcursor", "Xcursor.h.in" });
}

fn updateXrandr(pkg_builder: *VerboseBuilder) !void {
    const xrandr_dep = pkg_builder.verboseDependency("Xrandr");
    var xrandr_builder = VerboseBuilder.initFromDependency(xrandr_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "Xrandr.h" }, &xrandr_builder, &.{ "include", "X11", "extensions", "Xrandr.h" });
}

fn updateXfixes(pkg_builder: *VerboseBuilder) !void {
    const xfixes_dep = pkg_builder.verboseDependency("Xfixes");
    var xfixes_builder = VerboseBuilder.initFromDependency(xfixes_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "Xfixes.h" }, &xfixes_builder, &.{ "include", "X11", "extensions", "Xfixes.h" });
}

fn updateXrender(pkg_builder: *VerboseBuilder) !void {
    const xrender_dep = pkg_builder.verboseDependency("Xrender");
    var xrender_builder = VerboseBuilder.initFromDependency(xrender_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "Xrender.h" }, &xrender_builder, &.{ "include", "X11", "extensions", "Xrender.h" });
}

fn updateXinerama(pkg_builder: *VerboseBuilder) !void {
    const xinerama_dep = pkg_builder.verboseDependency("Xinerama");
    var xinerama_builder = VerboseBuilder.initFromDependency(xinerama_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "Xinerama.h" }, &xinerama_builder, &.{ "include", "X11", "extensions", "Xinerama.h" });
    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "panoramiXext.h" }, &xinerama_builder, &.{ "include", "X11", "extensions", "panoramiXext.h" });
}

fn updateXi(pkg_builder: *VerboseBuilder) !void {
    const xi_dep = pkg_builder.verboseDependency("Xi");
    var xi_builder = VerboseBuilder.initFromDependency(xi_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "XInput.h" }, &xi_builder, &.{ "include", "X11", "extensions", "XInput.h" });
    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "XInput2.h" }, &xi_builder, &.{ "include", "X11", "extensions", "XInput2.h" });
}

fn updateXau(pkg_builder: *VerboseBuilder) !void {
    const xau_dep = pkg_builder.verboseDependency("Xau");
    var xau_builder = VerboseBuilder.initFromDependency(xau_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "Xauth.h" }, &xau_builder, &.{ "include", "X11", "Xauth.h" });

    while (try xau_builder.iterate(&.{"."})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCSource(entry.name) and !std.mem.eql(u8, entry.name, "Autest.c")) {
                    try pkg_builder.copy(&.{ "Xau", entry.name }, &xau_builder, &.{entry.name});
                }
            },
            else => {},
        }
    }
}

fn updateXScrnSaver(pkg_builder: *VerboseBuilder) !void {
    const xscrnsaver_dep = pkg_builder.verboseDependency("XScrnSaver");
    var xscrnsaver_builder = VerboseBuilder.initFromDependency(xscrnsaver_dep);

    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", "scrnsaver.h" }, &xscrnsaver_builder, &.{ "include", "X11", "extensions", "scrnsaver.h" });
}

fn updateXext(pkg_builder: *VerboseBuilder) !void {
    const xext_dep = pkg_builder.verboseDependency("Xext");
    var xext_builder = VerboseBuilder.initFromDependency(xext_dep);

    while (try xext_builder.iterate(&.{ "include", "X11", "extensions" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.name)) {
                    try pkg_builder.copy(&.{ "X11", "include", "X11", "extensions", entry.name }, &xext_builder, &.{ "include", "X11", "extensions", entry.name });
                }
            },
            else => {},
        }
    }
}

fn updateXtrans(pkg_builder: *VerboseBuilder) !void {
    const xtrans_dep = pkg_builder.verboseDependency("Xtrans");
    var xtrans_builder = VerboseBuilder.initFromDependency(xtrans_dep);

    while (try xtrans_builder.iterate(&.{"."})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.name)) {
                    try pkg_builder.copy(&.{ "X11", "include", "X11", "Xtrans", entry.name }, &xtrans_builder, &.{entry.name});
                }
            },
            else => {},
        }
    }
}

fn updateXorgproto(pkg_builder: *VerboseBuilder) !void {
    const xorgproto_dep = pkg_builder.verboseDependency("xorgproto");
    var xorgproto_builder = VerboseBuilder.initFromDependency(xorgproto_dep);

    while (try xorgproto_builder.walk(&.{ "include", "X11" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename) or toolbox.isCTemplate(entry.basename)) {
                    pkg_builder.copy(&.{ "X11", "include", "X11", entry.path }, &xorgproto_builder, &.{ "include", "X11", entry.path }) catch |err| switch (err) {
                        error.OverwritingCopy => {},
                        else => return err,
                    };
                }
            },
            .directory => try pkg_builder.make(&.{ "X11", "include", "X11", entry.path }),
            else => {},
        }
    }

    while (try xorgproto_builder.walk(&.{ "include", "GL" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCHeader(entry.basename)) {
                    try pkg_builder.copy(&.{ "GL", entry.path }, &xorgproto_builder, &.{ "include", "GL", entry.path });
                }
            },
            .directory => try pkg_builder.make(&.{ "GL", entry.path }),
            else => {},
        }
    }
}

fn updateXcb(pkg_builder: *VerboseBuilder) !void {
    const xcb_dep = pkg_builder.verboseDependency("xcb");
    var xcb_builder = VerboseBuilder.initFromDependency(xcb_dep);
    const xcbproto_dep = pkg_builder.verboseDependency("xcbproto");
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

    const c_client_out_dir = try xcbproto_builder.openDir(&.{"c_client_out"});
    defer xcbproto_builder.closeDir(c_client_out_dir);

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
                    try pkg_builder.copy(&.{ "xcb", "xcb", entry.name }, &xcb_builder, &.{ "src", entry.name });
                }
            },
            else => {},
        }
    }

    while (try xcbproto_builder.iterate(&.{"c_client_out"})) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCFile(entry.name)) {
                    try pkg_builder.copy(&.{ "xcb", "xcb", entry.name }, &xcbproto_builder, &.{ "c_client_out", entry.name });
                }
            },
            else => {},
        }
    }
}

fn updateFn(pkg_builder: *VerboseBuilder) !void {
    for ([_][]const []const u8{ &.{"GL"}, &.{"X11"}, &.{ "X11", "include" }, &.{ "X11", "include", "X11" }, &.{ "X11", "include", "X11", "Xtrans" }, &.{ "X11", "include", "X11", "Xcursor" }, &.{ "X11", "include", "X11", "extensions" }, &.{ "X11", "src" }, &.{ "X11", "modules" }, &.{"xkbcommon"}, &.{"xcb"}, &.{ "xcb", "xcb" }, &.{"Xau"} }) |path| {
        try pkg_builder.remove(path);
        try pkg_builder.make(path);
    }

    try updateXkbcommon(pkg_builder);
    try updateX11(pkg_builder);
    try updateXcursor(pkg_builder);
    try updateXrandr(pkg_builder);
    try updateXfixes(pkg_builder);
    try updateXrender(pkg_builder);
    try updateXinerama(pkg_builder);
    try updateXi(pkg_builder);
    try updateXau(pkg_builder);
    try updateXScrnSaver(pkg_builder);
    try updateXext(pkg_builder);
    try updateXtrans(pkg_builder);
    try updateXorgproto(pkg_builder);
    try updateXcb(pkg_builder);
}

fn buildFn(pkg_builder: *VerboseBuilder) !void {
    const XLOCALELIBDIR = pkg_builder.option([]const u8, pkg_builder.resolve(&.{ "", "usr", "share", "X11", "locale" }), "with-locale-lib-dir", "");
    const XCB_QUEUE_BUFFER_SIZE = pkg_builder.option([]const u8, "16384", "with-queue-size", "");
    _ = try std.fmt.parseUnsigned(u32, XCB_QUEUE_BUFFER_SIZE, 10);
    const IOV_MAX = pkg_builder.option([]const u8, "16", "iov-max", "");
    _ = try std.fmt.parseUnsigned(u32, IOV_MAX, 10);

    const makekeys = pkg_builder.addExecutable("makekeys");
    pkg_builder.linkLibC(makekeys);
    pkg_builder.addCSource(makekeys, &.{ "X11", "src", "util", "makekeys.c" }, &.{});

    const run_makekeys = pkg_builder.addRunArtifact(makekeys);
    pkg_builder.expectExitCode(run_makekeys, 0);
    pkg_builder.setCwd(run_makekeys, &.{"."});
    pkg_builder.addArgs(run_makekeys, &.{pkg_builder.resolve(&.{ "X11", "include", "X11", "keysymdef.h" })});
    const ks_tables_h_content = pkg_builder.captureStdOut(run_makekeys);
    const write_file = pkg_builder.addWriteFiles();
    const ks_tables_h = pkg_builder.addCopyFile(write_file, ks_tables_h_content, &.{ "include", "ks_tables.h" });

    const lib = pkg_builder.addLibrary("X11");
    pkg_builder.addIncludePath(@TypeOf(lib.*), lib, ks_tables_h.dirname());
    pkg_builder.addInclude(lib, &.{ "X11", "include" });
    pkg_builder.addInclude(lib, &.{ "X11", "include", "X11" });
    pkg_builder.addInclude(lib, &.{ "X11", "src" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xcms" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xkb" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xlibi18n" });
    pkg_builder.addInclude(lib, &.{ "X11", "src", "xlibi18n", "lcUniConv" });
    pkg_builder.addInclude(lib, &.{"xcb"});
    pkg_builder.addInclude(lib, &.{"."});

    for ([_][]const u8{ "GL", "X11", "xcb", "xkbcommon" }) |dir| {
        while (try pkg_builder.walk(&.{dir})) |*entry| {
            if (toolbox.isCHeader(entry.basename)) pkg_builder.installHeader(lib, &.{ dir, entry.path }, &.{entry.path});
        }
    }

    pkg_builder.linkLibC(lib);

    pkg_builder.generateConfigHeader(lib, &.{ "X11", "include" }, &.{ "X11", "XlibConf.h.in" }, .autoconf_undef, .{
        .XTHREADS = 1,
        .XUSE_MTSAFE_API = 1,
    });

    const xcursor_uri = try std.Uri.parse(build_zig_zon.dependencies.Xcursor.url);
    var xcursor_version = pkg_builder.uriComponent(&xcursor_uri.query.?)[4..];
    xcursor_version = xcursor_version[std.mem.indexOfAny(u8, xcursor_version, "0123456789").?..];
    const xcursor_version_sem = std.SemanticVersion.parse(xcursor_version) catch unreachable;

    pkg_builder.generateConfigHeader(lib, &.{ "X11", "include" }, &.{ "X11", "Xcursor", "Xcursor.h.in" }, .autoconf_undef, .{
        .XCURSOR_LIB_MAJOR = @as(i64, @intCast(xcursor_version_sem.major)),
        .XCURSOR_LIB_MINOR = @as(i64, @intCast(xcursor_version_sem.minor)),
        .XCURSOR_LIB_REVISION = @as(i64, @intCast(xcursor_version_sem.patch)),
    });

    pkg_builder.generateConfigHeader(lib, &.{ "X11", "include" }, &.{ "X11", "Xpoll.h.in" }, .autoconf_at, .{
        .USE_FDS_BITS = "__fds_bits",
    });

    const src_flags = [_][]const u8{
        pkg_builder.concat(&.{ "-DXCMSDIR=\"", pkg_builder.resolve(&.{ "X11", "src", "xcms" }), "\"" }),
        pkg_builder.concat(&.{ "-DXLOCALELIBDIR=\"", XLOCALELIBDIR, "\"" }),
        "-DHAVE_SYS_IOCTL_H=1",
        "-DXKB=1",
    };

    while (try pkg_builder.walk(&.{ "X11", "src" })) |entry| {
        switch (entry.kind) {
            .file => {
                if (toolbox.isCSource(entry.basename) and
                    !std.mem.startsWith(u8, entry.basename, "os2") and
                    !std.mem.eql(u8, entry.path, pkg_builder.resolve(&.{ "util", "makekeys.c" })))
                {
                    pkg_builder.addCSource(lib, &.{ "X11", "src", entry.path }, &src_flags);
                }
            },
            else => {},
        }
    }

    const modules_flags = [_][]const u8{ "-DXIM_t=1", "-DTRANS_CLIENT=1" };

    while (try pkg_builder.walk(&.{ "X11", "modules" })) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ "X11", "modules", entry.path }, &modules_flags),
            else => {},
        }
    }

    const xcb_flags = [_][]const u8{
        pkg_builder.concat(&.{ "-DXCB_QUEUE_BUFFER_SIZE=", XCB_QUEUE_BUFFER_SIZE }),
        pkg_builder.concat(&.{ "-DIOV_MAX=", IOV_MAX }),
    };

    while (try pkg_builder.walk(&.{ "xcb", "xcb" })) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ "xcb", "xcb", entry.path }, &xcb_flags),
            else => {},
        }
    }

    while (try pkg_builder.walk(&.{"Xau"})) |entry| {
        switch (entry.kind) {
            .file => if (toolbox.isCSource(entry.basename)) pkg_builder.addCSource(lib, &.{ "Xau", entry.path }, &.{}),
            else => {},
        }
    }

    pkg_builder.installArtifact(lib);
    pkg_builder.dependOn(&lib.step, &write_file.step);
    pkg_builder.dependOn(pkg_builder.getInstallStep(), &write_file.step);
}

pub fn build(builder: *std.Build) !void {
    var pkg_builder = try VerboseBuilder.init(builder, @tagName(build_zig_zon.name), buildFn, updateFn);

    try pkg_builder.fetch(@TypeOf(build_zig_zon.dependencies), build_zig_zon.dependencies, pkg_builder.ptrCwd());
    try pkg_builder.update();
    try pkg_builder.build();
}
