const std = @import ("std");
const toolbox = @import ("toolbox");
const pkg = .{
               .name = "X11.zig",
               .version = .{
                 .X11 = "1.8.7",
                 .xkbcommon = "1.6.0",
                 .Xcursor = "1.2.2",
                 .Xrandr = "1.5.4",
                 .Xfixes = "6.0.1",
                 .Xrender = "0.9.11",
                 .Xinerama = "1.1.5",
                 .Xi = "1.8.1",
                 .XScrnSaver = "1.2.4",
                 .Xext = "1.3.6",
                 .xorgproto = "2023.2",
                 .xcb = "1.16.1",
                 .xcbproto = "1.16.0",
               },
             };

const Paths = struct
{
  GL: [] const u8 = undefined,
  X11: [] const u8 = undefined,
  ext: [] const u8 = undefined,
  tmp: [] const u8 = undefined,
  tmp2: [] const u8 = undefined,
  xkbcommon: [] const u8 = undefined,
  xcb: [] const u8 = undefined,
};

fn update_xkbcommon (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://github.com/xkbcommon/libxkbcommon.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "xkbcommon-" ++ pkg.version.xkbcommon, }, });

  const include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "xkbcommon" });
  var include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  try toolbox.make (path.xkbcommon);

  var it = include_dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => if (std.mem.endsWith (u8, entry.name, ".h")) try toolbox.copy (
                 try std.fs.path.join (builder.allocator, &.{ include_path, entry.name, }),
                 try std.fs.path.join (builder.allocator, &.{ path.xkbcommon, entry.name, })),
      else => {},
    }
  }

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_X11 (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libx11.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libX11-" ++ pkg.version.X11, }, });

  const include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", });
  var include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();
  try toolbox.make (path.X11);

  var it = include_dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => if (std.mem.endsWith (u8, entry.name, ".h")) try toolbox.copy (
                 try std.fs.path.join (builder.allocator, &.{ include_path, entry.name, }),
                 try std.fs.path.join (builder.allocator, &.{ path.X11, entry.name, })),
      else => {},
    }
  }

  const include_ext_path = try std.fs.path.join (builder.allocator, &.{ include_path, "extensions", });
  var include_ext_dir = try std.fs.openDirAbsolute (include_ext_path, .{ .iterate = true, });
  defer include_ext_dir.close ();
  try toolbox.make (path.ext);
  it = include_ext_dir.iterate ();

  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => if (std.mem.endsWith (u8, entry.name, ".h")) try toolbox.copy (
                 try std.fs.path.join (builder.allocator, &.{ include_ext_path, entry.name, }),
                 try std.fs.path.join (builder.allocator, &.{ path.ext, entry.name, })),
      else => {},
    }
  }

  var xlib_conf_h = try include_dir.readFileAlloc (builder.allocator, "XlibConf.h.in", std.math.maxInt (usize));

  for ([_] struct { match: [] const u8, replace: [] const u8, } {
        .{ .match = "#undef XTHREADS", .replace = "#define XTHREADS 1", },
        .{ .match = "#undef XUSE_MTSAFE_API", .replace = "#define XUSE_MTSAFE_API 1", },
      }) |search_and_replace|
  {
    xlib_conf_h = try std.mem.replaceOwned (u8, builder.allocator, xlib_conf_h, search_and_replace.match, search_and_replace.replace);
  }

  try toolbox.write (path.X11, "XlibConf.h", xlib_conf_h);

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xcursor (builder: *std.Build, path: *const Paths) !void
{
  const xcursor_path = try std.fs.path.join (builder.allocator, &.{ path.X11, "Xcursor", });

  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxcursor.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXcursor-" ++ pkg.version.Xcursor, }, });

  const include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "Xcursor", });
  var include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var xcursor_h = try include_dir.readFileAlloc (builder.allocator, "Xcursor.h.in", std.math.maxInt (usize));

  var tokit = std.mem.tokenizeScalar (u8, pkg.version.Xcursor, '.');
  const match = [_][] const u8 { "#undef XCURSOR_LIB_MAJOR", "#undef XCURSOR_LIB_MINOR", "#undef XCURSOR_LIB_REVISION", };
  const replace = [_][] const u8 { "#define XCURSOR_LIB_MAJOR", "#define XCURSOR_LIB_MINOR", "#define XCURSOR_LIB_REVISION", };
  var index: usize = 0;
  while (tokit.next ()) |*token|
  {
    xcursor_h = try std.mem.replaceOwned (u8, builder.allocator, xcursor_h, match [index], try std.fmt.allocPrint (builder.allocator, "{s} {s}", .{ replace [index], token.*, }));
    index += 1;
  }

  try toolbox.make (xcursor_path);
  try toolbox.write (xcursor_path, "Xcursor.h", xcursor_h);

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xrandr (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxrandr.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXrandr-" ++ pkg.version.Xrandr, }, });

  try toolbox.copy (
    try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", "Xrandr.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.ext, "Xrandr.h", }));

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xfixes (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxfixes.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXfixes-" ++ pkg.version.Xfixes, }, });

  try toolbox.copy (
    try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", "Xfixes.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.ext, "Xfixes.h", }));

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xrender (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxrender.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXrender-" ++ pkg.version.Xrender, }, });

  try toolbox.copy (
    try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", "Xrender.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.ext, "Xrender.h", }));

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xinerama (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxinerama.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXinerama-" ++ pkg.version.Xinerama, }, });

  for ([_][] const u8 { "Xinerama.h", "panoramiXext.h", }) |file|
  {
    try toolbox.copy (
      try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", file, }),
      try std.fs.path.join (builder.allocator, &.{ path.ext, file, }));
  }

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xi (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxi.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXi-" ++ pkg.version.Xi, }, });

  for ([_][] const u8 { "XInput.h", "XInput2.h", }) |file|
  {
    try toolbox.copy (
      try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", file, }),
      try std.fs.path.join (builder.allocator, &.{ path.ext, file, }));
  }

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_XScrnSaver (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXScrnSaver-" ++ pkg.version.XScrnSaver, }, });

  try toolbox.copy (
    try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", "scrnsaver.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.ext, "scrnsaver.h", }));

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_Xext (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxext.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libXext-" ++ pkg.version.Xext, }, });

  const include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", "extensions", });
  var include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var it = include_dir.iterate ();
  while (try it.next ()) |entry|
  {
    switch (entry.kind)
    {
      .file => if (std.mem.endsWith (u8, entry.name, ".h")) try toolbox.copy (
                 try std.fs.path.join (builder.allocator, &.{ include_path, entry.name, }),
                 try std.fs.path.join (builder.allocator, &.{ path.ext, entry.name, })),
      else => {},
    }
  }

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_xorgproto (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/proto/xorgproto.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "xorgproto-" ++ pkg.version.xorgproto, }, });

  var include_path: [] const u8 = undefined;
  var include_dir: std.fs.Dir = undefined;
  var walker: std.fs.Dir.Walker = undefined;

  try toolbox.make (path.GL);

  inline for ([_][] const u8 { "GL", "X11", }) |component|
  {
    include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", component, });
    include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
    defer include_dir.close ();

    walker = try include_dir.walk (builder.allocator);
    defer walker.deinit();

    while (try walker.next ()) |entry|
    {
      const dest = try std.fs.path.join (builder.allocator, &.{ @field (path, component), entry.path, });
      switch (entry.kind)
      {
        .file => if (std.mem.endsWith (u8, entry.basename, ".h")) try toolbox.copy (
            try std.fs.path.join (builder.allocator, &.{ include_path, entry.path, }), dest),
        .directory => try toolbox.make (dest),
        else => return error.UnexpectedEntryKind,
      }
    }
  }

  include_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "include", "X11", });
  include_dir = try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var xpoll_h = try include_dir.readFileAlloc (builder.allocator, "Xpoll.h.in", std.math.maxInt (usize));
  xpoll_h = try std.mem.replaceOwned (u8, builder.allocator, xpoll_h, "@USE_FDS_BITS@", "__fds_bits");
  try toolbox.write (path.X11, "Xpoll.h", xpoll_h);

  try std.fs.deleteTreeAbsolute (path.tmp);
}

fn update_xcb (builder: *std.Build, path: *const Paths) !void
{
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/lib/libxcb.git", path.tmp, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp, "checkout", "libxcb-" ++ pkg.version.xcb, }, });

  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "clone", "https://gitlab.freedesktop.org/xorg/proto/xcbproto.git", path.tmp2, }, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "git", "-C", path.tmp2, "checkout", "xcb-proto-" ++ pkg.version.xcbproto, }, });

  try toolbox.make (path.xcb);

  const out_path = try std.fs.path.join (builder.allocator, &.{ path.tmp2, "out", });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "./autogen.sh", }, .cwd = path.tmp2, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "make", }, .cwd = path.tmp2, });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "make",
    try std.fmt.allocPrint (builder.allocator, "DESTDIR=\"{s}\"", .{ out_path, }),
    "install", }, .cwd = path.tmp2, });

  const c_client_out_path = try std.fs.path.join (builder.allocator, &.{ path.tmp2, "c_client_out", });
  try toolbox.make (c_client_out_path);

  var out_dir = try std.fs.openDirAbsolute (out_path, .{ .iterate = true, });
  defer out_dir.close ();

  var walker = try out_dir.walk (builder.allocator);
  defer walker.deinit();

  var python_path: [] const u8 = undefined;

  loop: while (try walker.next ()) |entry|
  {
    switch (entry.kind)
    {
      .directory => if (std.mem.eql (u8, entry.basename, "site-packages"))
                    {
                      python_path = try std.fs.path.join (builder.allocator, &.{ out_path, entry.path, });
                      break :loop;
                    },
      else => {},
    }
  }

  var env = std.process.EnvMap.init (builder.allocator);
  try env.put ("PYTHONPATH", python_path);

  const xcbproto_xml_path = try std.fs.path.join (builder.allocator, &.{ path.tmp2, "src", });
  var xcbproto_xml_dir = try std.fs.openDirAbsolute (xcbproto_xml_path, .{ .iterate = true, });
  defer xcbproto_xml_dir.close ();

  const c_client_py_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "src", "c_client.py", });

  var it = xcbproto_xml_dir.iterate ();
  while (try it.next ()) |entry|
  {
    const xml = try std.fs.path.join (builder.allocator, &.{ xcbproto_xml_path, entry.name, });
    switch (entry.kind)
    {
      .file => if (std.mem.endsWith (u8, entry.name, ".xml")) try toolbox.run (builder, .{
                 .argv = &.{ "python3", c_client_py_path, "-c", "_", "-l", "_", "-s", "_", xml, },
                 .cwd = c_client_out_path, .env = &env, }),
      else => {},
    }
  }

  const xcb_src_path = try std.fs.path.join (builder.allocator, &.{ path.tmp, "src", });
  var dir: std.fs.Dir = undefined;

  for ([_][] const u8 { xcb_src_path, c_client_out_path, }) |header_path|
  {
    dir = try std.fs.openDirAbsolute (header_path, .{ .iterate = true, });
    defer dir.close ();

    it = dir.iterate ();
    while (try it.next ()) |entry|
    {
      switch (entry.kind)
      {
        .file => if (std.mem.endsWith (u8, entry.name, ".h")) try toolbox.copy (
                   try std.fs.path.join (builder.allocator, &.{ header_path, entry.name, }),
                   try std.fs.path.join (builder.allocator, &.{ path.xcb, entry.name, })),
        else => {},
      }
    }
  }

  for ([_][] const u8 { path.tmp, path.tmp2, }) |tmp| try std.fs.deleteTreeAbsolute (tmp);
}

fn update (builder: *std.Build) !void
{
  var path: Paths = .{};
  path.GL = try builder.build_root.join (builder.allocator, &.{ "GL", });
  path.X11 = try builder.build_root.join (builder.allocator, &.{ "X11", });
  path.ext = try std.fs.path.join (builder.allocator, &.{ path.X11, "extensions", });
  path.tmp = try builder.build_root.join (builder.allocator, &.{ "tmp", });
  path.tmp2 = try builder.build_root.join (builder.allocator, &.{ "tmp2", });
  path.xkbcommon = try builder.build_root.join (builder.allocator, &.{ "xkbcommon", });
  path.xcb = try builder.build_root.join (builder.allocator, &.{ "xcb", });

  inline for (@typeInfo (@TypeOf (path)).Struct.fields) |field|
  {
    std.fs.deleteTreeAbsolute (@field (path, field.name)) catch |err|
    {
      switch (err)
      {
        error.FileNotFound => {},
        else => return err,
      }
    };
  }

  try update_xkbcommon (builder, &path);
  try update_X11 (builder, &path);
  try update_Xcursor (builder, &path);
  try update_Xrandr (builder, &path);
  try update_Xfixes (builder, &path);
  try update_Xrender (builder, &path);
  try update_Xinerama (builder, &path);
  try update_Xi (builder, &path);
  try update_XScrnSaver (builder, &path);
  try update_Xext (builder, &path);
  try update_xorgproto (builder, &path);
  try update_xcb (builder, &path);
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  if (builder.option (bool, "update", "Update binding") orelse false) try update (builder);

  const lib = builder.addStaticLibrary (.{
    .name = "X11",
    .root_source_file = builder.addWriteFiles ().add ("empty.c", ""),
    .target = target,
    .optimize = optimize,
  });

  for ([_][] const u8 { "GL", "X11", "xcb", "xkbcommon", }) |header|
  {
    std.debug.print ("[X11 headers dir] {s}\n", .{ try builder.build_root.join (builder.allocator, &.{ header, }), });
    lib.installHeadersDirectory (header, header);
  }

  builder.installArtifact (lib);
}
