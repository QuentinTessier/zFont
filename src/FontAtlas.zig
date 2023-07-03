const std = @import("std");
const fnt = @import("FNT/fnt.zig");

pub const FontAtlas = @This();

pub const Glyph = struct {
    region: @Vector(4, f32),
    offset: @Vector(2, f32),
    advance: f32,
};

glyphs: std.AutoHashMapUnmanaged(u32, Glyph) = .{},
atlasTexturePath: [:0]u8 = undefined,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !FontAtlas {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var stream = std.io.StreamSource{ .file = file };
    return initFromFntFile(allocator, &stream);
}

pub fn deinit(self: *FontAtlas, allocator: std.mem.Allocator) void {
    self.glyphs.deinit(allocator);
    allocator.free(self.atlasTexturePath);
}

fn initFromFntFile(allocator: std.mem.Allocator, stream: *std.io.StreamSource) !FontAtlas {
    var content = try fnt.Parser.parse(allocator, stream);
    defer content.destroy(allocator);

    const atlasTextureSize: @Vector(2, f32) = .{ @intToFloat(f32, content.scaleW), @intToFloat(f32, content.scaleH) };
    var glyphs: std.AutoHashMapUnmanaged(u32, Glyph) = .{};
    glyphs.ensureTotalCapacity(allocator, content.chars.len);
    for (content.chars) |c| {
        const region = @Vector(4, f32){
            @intToFloat(f32, c.x) / atlasTextureSize[0],
            @intToFloat(f32, c.y) / atlasTextureSize[1],
            @intToFloat(f32, c.width) / atlasTextureSize[0],
            @intToFloat(f32, c.height) / atlasTextureSize[1],
        };
        const offset = @Vector(2, f32){
            @intToFloat(f32, c.xoffset),
            @intToFloat(f32, c.yoffset),
        };
        const advance = @intToFloat(f32, c.xadvance);
        try glyphs.put(allocator, c.id, .{ .region = region, .offset = offset, .advance = advance });
    }
    var name = try allocator.dupeZ(u8, content.pageNames[0]);
    return .{
        .glyphs = glyphs,
        .atlasTexturePath = name,
    };
}
