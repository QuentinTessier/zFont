const std = @import("std");

pub const zFont = struct {
    zfont: *std.Build.Module,

    pub fn link(self: zFont, exe: *std.Build.CompileStep) void {
        exe.addModule("zfont", self.zfont);
    }
};

pub fn package(b: *std.Build, _: std.zig.CrossTarget, _: std.builtin.Mode) zFont {
    const zfont = b.createModule(.{
        .source_file = .{ .path = comptime std.fs.path.dirname(@src().file) orelse "." ++ "/src/font.zig" },
        .dependencies = &.{},
    });
    return zFont{ .zfont = zfont };
}
