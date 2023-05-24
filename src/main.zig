const std = @import("std");
const fnt = @import("FNT/fnt.zig");

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
    var file = try std.fs.cwd().openFile("Unnamed.fnt", .{});
    defer file.close();

    var stream = std.io.StreamSource{ .file = file };
    var res = try fnt.Parser.parse(allocator, &stream);
    std.log.info("{}", .{res});
    res.destroy(allocator);
}
