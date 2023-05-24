const std = @import("std");
const fnt = @import("FNT/fnt.zig");

pub const Format = enum(u32) {
    fnt, // file generated using https://snowb.org/
};

const Glyph = struct {
    region: @Vector(4, f32),
    offset: @Vector(2, f32),
    advance: f32,
};

pub const Error = error{
    InvalidFile,
};

pub fn Font(comptime Bitmap: type) type {
    return struct {
        allocator: std.mem.Allocator,
        glyphs: std.AutoArrayHashMap(u32, Glyph),
        path: []const u8,
        bitmapPath: []u8,
        bitmap: Bitmap = undefined,

        pub fn init(allocator: std.mem.Allocator, path: []const u8) !Font(Bitmap) {
            if (!std.mem.endsWith(u8, path, ".fnt")) {
                return error.InvalidFile;
            }

            var file = try std.fs.cwd().openFile(path, .{});
            defer file.close();

            var stream = std.io.StreamSource{ .file = file };
            var fnt_file = try fnt.Parser.parse(allocator, &stream);

            if (fnt_file.pageNames.len > 1) {
                std.log.warn("Multiple pages not supported yet", .{});
            }
            var bitmapPath = try allocator.dupe(fnt_file.pageNames[0]);
            _ = bitmapPath;
        }
    };
}
