const std = @import("std");
const fnt = @import("FNT/fnt.zig");

pub const Format = enum(u32) {
    fnt, // file generated using https://snowb.org/
};

pub const Glyph = struct {
    region: @Vector(4, f32),
    offset: @Vector(2, f32),
    advance: f32,
};

pub const Error = error{
    InvalidFile,
};

// TODO: Find a better way to pass the Bitmap type
pub fn Font(comptime Bitmap: type) type {
    return struct {
        allocator: std.mem.Allocator,
        fontSize: u32,
        glyphs: std.AutoArrayHashMap(u32, Glyph),
        path: []const u8,
        bitmapPath: []u8,
        bitmap: Bitmap = undefined,

        pub fn init(allocator: std.mem.Allocator, path: []const u8) !Font(Bitmap) {
            if (std.mem.endsWith(u8, path, ".fnt")) {
                var file = try std.fs.cwd().openFile(path, .{});
                defer file.close();

                var stream = std.io.StreamSource{ .file = file };
                return initFromFNTFile(allocator, path, &stream);
            } else {
                std.log.warn("Unsupported font format: {s}", .{path});
                return error.InvalidFile;
            }
        }

        fn initFromFNTFile(allocator: std.mem.Allocator, path: []const u8, fileStream: *std.io.StreamSource) !Font(Bitmap) {
            var data = try fnt.Parser.parse(allocator, fileStream);
            defer data.destroy(allocator);
            if (data.pages > 1) {
                // TODO: Add support for multiple pages (fuse them into a single bitmap ?)
                std.log.warn("Font has more than one page, only the first one will be used", .{});
            }
            const fontSize = data.size;
            var bitmapPath = try allocator.dupe(u8, data.pageNames[0]);
            var glyphs = std.AutoArrayHashMap(u32, Glyph).init(allocator);
            for (data.chars) |c| {
                const g: Glyph = blk: {
                    const region: @Vector(4, f32) = .{
                        @intToFloat(f32, c.x),
                        @intToFloat(f32, c.y),
                        @intToFloat(f32, c.width),
                        @intToFloat(f32, c.height),
                    };
                    const offset: @Vector(2, f32) = .{
                        @intToFloat(f32, c.xoffset),
                        @intToFloat(f32, c.yoffset),
                    };
                    const advance = @intToFloat(f32, c.xadvance);

                    break :blk .{
                        .region = region,
                        .offset = offset,
                        .advance = advance,
                    };
                };
                try glyphs.put(c.id, g);
            }
            return Font(Bitmap){
                .allocator = allocator,
                .fontSize = fontSize,
                .glyphs = glyphs,
                .path = path,
                .bitmapPath = bitmapPath,
            };
        }

        pub fn deinit(self: *Font(Bitmap)) void {
            self.glyphs.deinit();
            self.allocator.free(self.bitmapPath);
        }

        pub fn getGlyph(self: *Font(Bitmap), codepoint: u32) ?Glyph {
            return self.glyphs.get(codepoint);
        }
    };
}
