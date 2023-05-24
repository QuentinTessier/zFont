const std = @import("std");
const Font = @import("font.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        switch (deinit_status) {
            .ok => {},
            else => std.log.warn("Allocator found leak", .{}),
        }
    }

    var font = try Font.Font(void).init(allocator, "Unnamed.fnt");
    defer font.deinit();

    std.log.info("Glyph (A): {?}", .{font.getGlyph('A')});
}
