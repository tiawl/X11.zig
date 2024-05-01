const std = @import ("std");
const toolbox = @import ("toolbox");

const Paths = struct
{
  // prefixed attributes
  __GL: [] const u8 = undefined,
  __X11: [] const u8 = undefined,
  __ext: [] const u8 = undefined,
  __tmp: [] const u8 = undefined,
  __tmp2: [] const u8 = undefined,
  __xkbcommon: [] const u8 = undefined,
  __xcb: [] const u8 = undefined,

  // mandatory getters
  pub fn getGL (self: @This ()) [] const u8 { return self.__GL; }
  pub fn getX11 (self: @This ()) [] const u8 { return self.__X11; }
  pub fn getExt (self: @This ()) [] const u8 { return self.__ext; }
  pub fn getTmp (self: @This ()) [] const u8 { return self.__tmp; }
  pub fn getTmp2 (self: @This ()) [] const u8 { return self.__tmp2; }
  pub fn getXkbcommon (self: @This ()) [] const u8 { return self.__xkbcommon; }
  pub fn getXcb (self: @This ()) [] const u8 { return self.__xcb; }

  // mandatory init
  pub fn init (builder: *std.Build) !@This ()
  {
    var self = @This () {
      .__GL = try builder.build_root.join (builder.allocator, &.{ "GL", }),
      .__X11 = try builder.build_root.join (builder.allocator, &.{ "X11", }),

      .__tmp = try builder.build_root.join (builder.allocator, &.{ "tmp", }),
      .__tmp2 = try builder.build_root.join (builder.allocator, &.{ "tmp2", }),
      .__xkbcommon = try builder.build_root.join (builder.allocator,
        &.{ "xkbcommon", }),
      .__xcb = try builder.build_root.join (builder.allocator, &.{ "xcb", }),
    };

    self.__ext = try std.fs.path.join (builder.allocator,
      &.{ self.getX11 (), "extensions", });

    return self;
  }
};

fn update_xkbcommon (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "xkbcommon", path.getTmp ());

  const include_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "include", "xkbcommon" });
  var include_dir =
    try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  try toolbox.make (path.getXkbcommon ());

  var it = include_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    switch (entry.kind)
    {
      .file => {
        if (toolbox.isCHeader (entry.name))
        {
          try toolbox.copy (try std.fs.path.join (builder.allocator,
            &.{ include_path, entry.name, }),
          try std.fs.path.join (builder.allocator,
            &.{ path.getXkbcommon (), entry.name, }));
        }
      },
      else => {},
    }
  }

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_X11 (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "X11", path.getTmp ());

  const include_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "include", "X11", });
  var include_dir =
    try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();
  try toolbox.make (path.getX11 ());

  var it = include_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    switch (entry.kind)
    {
      .file => {
        if (toolbox.isCHeader (entry.name))
        {
          try toolbox.copy (try std.fs.path.join (builder.allocator,
            &.{ include_path, entry.name, }),
          try std.fs.path.join (builder.allocator,
            &.{ path.getX11 (), entry.name, }));
        }
      },
      else => {},
    }
  }

  const include_ext_path = try std.fs.path.join (builder.allocator,
    &.{ include_path, "extensions", });
  var include_ext_dir =
    try std.fs.openDirAbsolute (include_ext_path, .{ .iterate = true, });
  defer include_ext_dir.close ();
  try toolbox.make (path.getExt ());
  it = include_ext_dir.iterate ();

  while (try it.next ()) |*entry|
  {
    switch (entry.kind)
    {
      .file => {
        if (toolbox.isCHeader (entry.name))
        {
          try toolbox.copy (try std.fs.path.join (builder.allocator,
            &.{ include_ext_path, entry.name, }),
          try std.fs.path.join (builder.allocator,
            &.{ path.getExt (), entry.name, }));
        }
      },
      else => {},
    }
  }

  var xlib_conf_h = try include_dir.readFileAlloc (builder.allocator,
    "XlibConf.h.in", std.math.maxInt (usize));

  for ([_] struct { match: [] const u8, replace: [] const u8, } {
    .{ .match = "#undef XTHREADS", .replace = "#define XTHREADS 1", },
    .{ .match = "#undef XUSE_MTSAFE_API",
       .replace = "#define XUSE_MTSAFE_API 1", },
  }) |search_and_replace| {
    xlib_conf_h = try std.mem.replaceOwned (u8, builder.allocator, xlib_conf_h,
      search_and_replace.match, search_and_replace.replace);
  }

  try toolbox.write (path.getX11 (), "XlibConf.h", xlib_conf_h);

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xcursor (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  const xcursor_path =
    try std.fs.path.join (builder.allocator, &.{ path.getX11 (), "Xcursor", });

  try dependencies.clone (builder, "Xcursor", path.getTmp ());

  const include_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "include", "X11", "Xcursor", });
  var include_dir =
    try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var xcursor_h = try include_dir.readFileAlloc (builder.allocator,
    "Xcursor.h.in", std.math.maxInt (usize));

  var xcursor_version = try toolbox.version (builder, "Xcursor");
  xcursor_version = xcursor_version [std.mem.indexOfAny (
    u8, xcursor_version, "0123456789").? ..];
  var tokit = std.mem.tokenizeScalar (u8, xcursor_version, '.');
  const match = [_][] const u8 { "#undef XCURSOR_LIB_MAJOR",
    "#undef XCURSOR_LIB_MINOR", "#undef XCURSOR_LIB_REVISION", };
  const replace = [_][] const u8 { "#define XCURSOR_LIB_MAJOR",
    "#define XCURSOR_LIB_MINOR", "#define XCURSOR_LIB_REVISION", };
  var index: usize = 0;
  while (tokit.next ()) |*token|
  {
    xcursor_h = try std.mem.replaceOwned (u8, builder.allocator, xcursor_h,
      match [index], try std.fmt.allocPrint (builder.allocator, "{s} {s}",
        .{ replace [index], token.*, }));
    index += 1;
  }

  try toolbox.make (xcursor_path);
  try toolbox.write (xcursor_path, "Xcursor.h", xcursor_h);

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xrandr (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xrandr", path.getTmp ());

  try toolbox.copy (
    try std.fs.path.join (builder.allocator,
      &.{ path.getTmp (), "include", "X11", "extensions", "Xrandr.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.getExt (), "Xrandr.h", }));

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xfixes (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xfixes", path.getTmp ());

  try toolbox.copy (
    try std.fs.path.join (builder.allocator,
      &.{ path.getTmp (), "include", "X11", "extensions", "Xfixes.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.getExt (), "Xfixes.h", }));

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xrender (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xrender", path.getTmp ());

  try toolbox.copy (
    try std.fs.path.join (builder.allocator,
      &.{ path.getTmp (), "include", "X11", "extensions", "Xrender.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.getExt (), "Xrender.h", }));

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xinerama (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xinerama", path.getTmp ());

  for ([_][] const u8 { "Xinerama.h", "panoramiXext.h", }) |file|
  {
    try toolbox.copy (
      try std.fs.path.join (builder.allocator,
        &.{ path.getTmp (), "include", "X11", "extensions", file, }),
      try std.fs.path.join (builder.allocator, &.{ path.getExt (), file, }));
  }

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xi (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xi", path.getTmp ());

  for ([_][] const u8 { "XInput.h", "XInput2.h", }) |file|
  {
    try toolbox.copy (
      try std.fs.path.join (builder.allocator,
        &.{ path.getTmp (), "include", "X11", "extensions", file, }),
      try std.fs.path.join (builder.allocator, &.{ path.getExt (), file, }));
  }

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_XScrnSaver (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "XScrnSaver", path.getTmp ());

  try toolbox.copy (
    try std.fs.path.join (builder.allocator,
      &.{ path.getTmp (), "include", "X11", "extensions", "scrnsaver.h", }),
    try std.fs.path.join (builder.allocator, &.{ path.getExt (), "scrnsaver.h", }));

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_Xext (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "Xext", path.getTmp ());

  const include_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "include", "X11", "extensions", });
  var include_dir =
    try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var it = include_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    switch (entry.kind)
    {
      .file => {
        if (toolbox.isCHeader (entry.name))
        {
          try toolbox.copy (try std.fs.path.join (builder.allocator,
            &.{ include_path, entry.name, }),
          try std.fs.path.join (builder.allocator,
            &.{ path.getExt (), entry.name, }));
        }
      },
      else => {},
    }
  }

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_xorgproto (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "xorgproto", path.getTmp ());

  var include_path: [] const u8 = undefined;
  var include_dir: std.fs.Dir = undefined;
  var walker: std.fs.Dir.Walker = undefined;

  try toolbox.make (path.getGL ());

  inline for ([_][] const u8 { "GL", "X11", }) |component|
  {
    include_path = try std.fs.path.join (builder.allocator,
      &.{ path.getTmp (), "include", component, });
    include_dir =
      try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
    defer include_dir.close ();

    walker = try include_dir.walk (builder.allocator);
    defer walker.deinit ();

    while (try walker.next ()) |*entry|
    {
      const dest = try std.fs.path.join (builder.allocator,
        &.{ if (std.mem.eql (u8, "GL", component)) path.getGL ()
            else path.getX11 (), entry.path, });
      switch (entry.kind)
      {
        .file => {
          if (toolbox.isCHeader (entry.basename))
          {
            try toolbox.copy (try std.fs.path.join (builder.allocator,
              &.{ include_path, entry.path, }), dest);
          }
        },
        .directory => try toolbox.make (dest),
        else => return error.UnexpectedEntryKind,
      }
    }
  }

  include_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "include", "X11", });
  include_dir =
    try std.fs.openDirAbsolute (include_path, .{ .iterate = true, });
  defer include_dir.close ();

  var xpoll_h = try include_dir.readFileAlloc (builder.allocator,
    "Xpoll.h.in", std.math.maxInt (usize));
  xpoll_h = try std.mem.replaceOwned (u8, builder.allocator, xpoll_h,
    "@USE_FDS_BITS@", "__fds_bits");
  try toolbox.write (path.getX11 (), "Xpoll.h", xpoll_h);

  try std.fs.deleteTreeAbsolute (path.getTmp ());
}

fn update_xcb (builder: *std.Build, path: *const Paths,
  dependencies: *const toolbox.Dependencies) !void
{
  try dependencies.clone (builder, "xcb", path.getTmp ());
  try dependencies.clone (builder, "xcbproto", path.getTmp2 ());

  try toolbox.make (path.getXcb ());

  const out_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp2 (), "out", });
  try toolbox.run (builder,
    .{ .argv = &[_][] const u8 { "./autogen.sh", }, .cwd = path.getTmp2 (), });
  try toolbox.run (builder,
    .{ .argv = &[_][] const u8 { "make", }, .cwd = path.getTmp2 (), });
  try toolbox.run (builder, .{ .argv = &[_][] const u8 { "make",
    try std.fmt.allocPrint (builder.allocator, "DESTDIR=\"{s}\"",
    .{ out_path, }), "install", }, .cwd = path.getTmp2 (), });

  const c_client_out_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp2 (), "c_client_out", });
  try toolbox.make (c_client_out_path);

  var out_dir = try std.fs.openDirAbsolute (out_path, .{ .iterate = true, });
  defer out_dir.close ();

  var walker = try out_dir.walk (builder.allocator);
  defer walker.deinit ();

  var python_path: [] const u8 = undefined;

  loop: while (try walker.next ()) |*entry|
  {
    switch (entry.kind)
    {
      .directory => {
        if (std.mem.eql (u8, entry.basename, "site-packages"))
        {
          python_path = try std.fs.path.join (builder.allocator,
            &.{ out_path, entry.path, });
          break :loop;
        }
      },
      else => {},
    }
  }

  var env = std.process.EnvMap.init (builder.allocator);
  try env.put ("PYTHONPATH", python_path);

  const xcbproto_xml_path =
    try std.fs.path.join (builder.allocator, &.{ path.getTmp2 (), "src", });
  var xcbproto_xml_dir =
    try std.fs.openDirAbsolute (xcbproto_xml_path, .{ .iterate = true, });
  defer xcbproto_xml_dir.close ();

  const c_client_py_path = try std.fs.path.join (builder.allocator,
    &.{ path.getTmp (), "src", "c_client.py", });

  var it = xcbproto_xml_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    const xml = try std.fs.path.join (builder.allocator,
      &.{ xcbproto_xml_path, entry.name, });
    switch (entry.kind)
    {
      .file => {
        if (std.mem.endsWith (u8, entry.name, ".xml"))
        {
          try toolbox.run (builder, .{
            .argv = &.{ "python3", c_client_py_path,
              "-c", "_", "-l", "_", "-s", "_", xml, },
            .cwd = c_client_out_path, .env = &env,
          });
        }
      },
      else => {},
    }
  }

  const xcb_src_path =
    try std.fs.path.join (builder.allocator, &.{ path.getTmp (), "src", });
  var dir: std.fs.Dir = undefined;

  for ([_][] const u8 { xcb_src_path, c_client_out_path, }) |header_path|
  {
    dir = try std.fs.openDirAbsolute (header_path, .{ .iterate = true, });
    defer dir.close ();

    it = dir.iterate ();
    while (try it.next ()) |*entry|
    {
      switch (entry.kind)
      {
        .file => {
          if (toolbox.isCHeader (entry.name))
          {
            try toolbox.copy (try std.fs.path.join (builder.allocator,
              &.{ header_path, entry.name, }),
            try std.fs.path.join (builder.allocator,
              &.{ path.getXcb (), entry.name, }));
          }
        },
        else => {},
      }
    }
  }

  for ([_][] const u8 { path.getTmp (), path.getTmp2 (), }) |tmp|
    try std.fs.deleteTreeAbsolute (tmp);
}

fn update (builder: *std.Build,
  dependencies: *const toolbox.Dependencies) !void
{
  const path = try Paths.init (builder);

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

  try update_xkbcommon (builder, &path, dependencies);
  try update_X11 (builder, &path, dependencies);
  try update_Xcursor (builder, &path, dependencies);
  try update_Xrandr (builder, &path, dependencies);
  try update_Xfixes (builder, &path, dependencies);
  try update_Xrender (builder, &path, dependencies);
  try update_Xinerama (builder, &path, dependencies);
  try update_Xi (builder, &path, dependencies);
  try update_XScrnSaver (builder, &path, dependencies);
  try update_Xext (builder, &path, dependencies);
  try update_xorgproto (builder, &path, dependencies);
  try update_xcb (builder, &path, dependencies);

  try toolbox.clean (builder, &.{ "GL", "X11", "xcb", "xkbcommon", }, &.{});
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  const dependencies = try toolbox.Dependencies.init (builder, "X11.zig",
  &.{ "X11", "GL", "xcb", "xkbcommon", },
  .{
     .toolbox = .{
       .name = "tiawl/toolbox",
       .host = toolbox.Repository.Host.github,
     },
   }, .{
     .X11 = .{
       .name = "xorg/lib/libx11",
       .host = toolbox.Repository.Host.gitlab,
     },
     .xcb = .{
       .name = "xorg/lib/libxcb",
       .host = toolbox.Repository.Host.gitlab,
     },
     .xcbproto = .{
       .name = "xorg/proto/xcbproto",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xcursor = .{
       .name = "xorg/lib/libxcursor",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xext = .{
       .name = "xorg/lib/libxext",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xfixes = .{
       .name = "xorg/lib/libxfixes",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xi = .{
       .name = "xorg/lib/libxi",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xinerama = .{
       .name = "xorg/lib/libxinerama",
       .host = toolbox.Repository.Host.gitlab,
     },
     .xkbcommon = .{
       .name = "xkbcommon/libxkbcommon",
       .host = toolbox.Repository.Host.github,
     },
     .xorgproto = .{
       .name = "xorg/proto/xorgproto",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xrandr = .{
       .name = "xorg/lib/libxrandr",
       .host = toolbox.Repository.Host.gitlab,
     },
     .Xrender = .{
       .name = "xorg/lib/libxrender",
       .host = toolbox.Repository.Host.gitlab,
     },
     .XScrnSaver = .{
       .name = "xorg/lib/libxscrnsaver",
       .host = toolbox.Repository.Host.gitlab,
     },
   });

  if (builder.option (bool, "update", "Update binding") orelse false)
    try update (builder, &dependencies);

  const lib = builder.addStaticLibrary (.{
    .name = "X11",
    .root_source_file = builder.addWriteFiles ().add ("empty.c", ""),
    .target = target,
    .optimize = optimize,
  });

  for ([_][] const u8 { "GL", "X11", "xcb", "xkbcommon", }) |header|
  {
    toolbox.addHeader (lib, try builder.build_root.join (builder.allocator,
      &.{ header, }), header, &.{ ".h", });
  }

  builder.installArtifact (lib);
}
