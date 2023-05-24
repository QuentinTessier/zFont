const std = @import("std");

pub const Char = struct {
    id: u32,
    x: u32,
    y: u32,

    width: u32,
    height: u32,

    xoffset: i32,
    yoffset: i32,

    xadvance: i32,
    page: usize,
    chnl: u8,
};

pub const File = struct {
    // Info
    face: []u8 = undefined,
    size: u32 = 0,
    bold: bool = false,
    italic: bool = false,
    charset: []u8 = undefined,
    unicode: bool = false,
    stretchH: u32 = 0,
    smooth: bool = false,
    aa: u32 = 0,
    padding: [4]u32 = .{ 0, 0, 0, 0 },
    spacing: [2]u32 = .{ 0, 0 },
    outline: u32 = 0,

    // Common
    lineHeight: u32 = 0,
    base: u32 = 0,
    scaleW: u32 = 0,
    scaleH: u32 = 0,
    pages: u32 = 0,
    packed_: bool = false,

    // Pages
    pageNames: [][]u8 = undefined,

    // Chars
    offset: usize = 0,
    chars: []Char = undefined,

    pub fn destroy(self: *File, allocator: std.mem.Allocator) void {
        allocator.free(self.face);
        allocator.free(self.charset);
        for (self.pageNames) |pageName| {
            allocator.free(pageName);
        }
        allocator.free(self.pageNames);
        allocator.free(self.chars);
    }
};
