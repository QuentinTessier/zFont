const std = @import("std");
const FNTFile = @import("File.zig").File;
const FNTChar = @import("File.zig").Char;

pub const Error = error{
    InvalidToken,
};

fn parseInfo(allocator: std.mem.Allocator, data: *FNTFile, line: []const u8) !void {
    var iterator = std.mem.split(u8, line, " ");
    while (iterator.next()) |token| {
        var index = std.mem.indexOf(u8, token, "=") orelse unreachable;

        var key = token[0..index];
        var value = token[index + 1 ..];

        if (std.mem.eql(u8, key, "face")) {
            data.face = try allocator.dupe(u8, value[1 .. value.len - 1]);
        } else if (std.mem.eql(u8, key, "size")) {
            data.size = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "bold")) {
            data.bold = value[0] == '1';
        } else if (std.mem.eql(u8, key, "italic")) {
            data.italic = value[0] == '1';
        } else if (std.mem.eql(u8, key, "charset")) {
            data.charset = try allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "unicode")) {
            data.unicode = value[0] == '1';
        } else if (std.mem.eql(u8, key, "stretchH")) {
            data.stretchH = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "smooth")) {
            data.smooth = value[0] == '1';
        } else if (std.mem.eql(u8, key, "aa")) {
            data.aa = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "padding")) {
            var ite = std.mem.split(u8, value, ",");
            var i: u32 = 0;
            while (ite.next()) |t| {
                data.padding[i] = try std.fmt.parseInt(u32, t, 10);
                i += 1;
            }
        } else if (std.mem.eql(u8, key, "spacing")) {
            var ite = std.mem.split(u8, value, ",");
            var i: u32 = 0;
            while (ite.next()) |t| {
                data.spacing[i] = try std.fmt.parseInt(u32, t, 10);
                i += 1;
            }
        } else if (std.mem.eql(u8, key, "outline")) {
            data.outline = try std.fmt.parseInt(u32, value, 10);
        } else {
            std.log.warn("Found unsupported key {s} with value {s}", .{ key, value });
            return error.InvalidToken;
        }
    }
}

fn parseCommon(allocator: std.mem.Allocator, data: *FNTFile, line: []const u8) !void {
    var iterator = std.mem.split(u8, line, " ");
    while (iterator.next()) |token| {
        var index = std.mem.indexOf(u8, token, "=") orelse unreachable;

        var key = token[0..index];
        var value = token[index + 1 ..];
        if (std.mem.eql(u8, key, "lineHeight")) {
            data.lineHeight = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "base")) {
            data.base = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "scaleW")) {
            data.scaleW = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "scaleH")) {
            data.scaleH = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "pages")) {
            data.pages = try std.fmt.parseInt(u32, value, 10);
            data.pageNames = try allocator.alloc([]u8, data.pages);
        } else if (std.mem.eql(u8, key, "packed")) {
            data.packed_ = value[0] == '1';
        } else {
            std.log.warn("Found unsupported key {s} with value {s}", .{ key, value });
            return error.InvalidToken;
        }
    }
}

pub fn parsePage(allocator: std.mem.Allocator, data: *FNTFile, line: []const u8) !void {
    var iterator = std.mem.split(u8, line, " ");
    var id: u32 = 0;
    while (iterator.next()) |token| {
        var index = std.mem.indexOf(u8, token, "=") orelse unreachable;

        var key = token[0..index];
        var value = token[index + 1 ..];

        if (std.mem.eql(u8, key, "id")) {
            id = try std.fmt.parseInt(u32, value, 10);
            if (id >= data.pages) {
                return error.InvalidToken;
            }
            var pageName = iterator.next() orelse unreachable;
            data.pageNames[id] = try allocator.dupe(u8, pageName[1 .. pageName.len - 1]);
        } else {
            std.log.warn("Found unsupported key {s} with value {s}", .{ key, value });
            return error.InvalidToken;
        }
    }
}

pub fn parseChars(allocator: std.mem.Allocator, data: *FNTFile, line: []const u8) !void {
    var iterator = std.mem.split(u8, line, " ");
    var id: u32 = 0;
    _ = id;
    while (iterator.next()) |token| {
        var index = std.mem.indexOf(u8, token, "=") orelse unreachable;

        var key = token[0..index];
        var value = token[index + 1 ..];

        if (std.mem.eql(u8, key, "count")) {
            var count: u32 = try std.fmt.parseInt(u32, value, 10);
            data.chars = try allocator.alloc(FNTChar, count);
        } else {
            std.log.warn("Found unsupported key {s} with value {s}", .{ key, value });
            return error.InvalidToken;
        }
    }
}

pub fn parseChar(allocator: std.mem.Allocator, data: *FNTFile, line: []const u8) !void {
    _ = allocator;
    var iterator = std.mem.split(u8, line, " ");
    var current = &data.chars[data.offset];
    while (iterator.next()) |token| {
        var index = std.mem.indexOf(u8, token, "=") orelse unreachable;

        var key = token[0..index];
        var value = token[index + 1 ..];

        if (std.mem.eql(u8, key, "id")) {
            current.id = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "x")) {
            current.x = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "y")) {
            current.y = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "width")) {
            current.width = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "height")) {
            current.height = try std.fmt.parseInt(u32, value, 10);
        } else if (std.mem.eql(u8, key, "xoffset")) {
            current.xoffset = try std.fmt.parseInt(i23, value, 10);
        } else if (std.mem.eql(u8, key, "yoffset")) {
            current.yoffset = try std.fmt.parseInt(i23, value, 10);
        } else if (std.mem.eql(u8, key, "xadvance")) {
            current.xadvance = try std.fmt.parseInt(i32, value, 10);
        } else if (std.mem.eql(u8, key, "page")) {
            current.page = try std.fmt.parseInt(usize, value, 10);
        } else if (std.mem.eql(u8, key, "chnl")) {
            current.chnl = try std.fmt.parseInt(u8, value, 10);
        } else {
            std.log.warn("Found unsupported key {s} with value {s}", .{ key, value });
            return error.InvalidToken;
        }
    }
    data.offset += 1;
}

pub fn parse(allocator: std.mem.Allocator, stream: *std.io.StreamSource) !FNTFile {
    var data: FNTFile = .{};
    var reader = stream.reader();
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 2048)) |line| {
        if (std.mem.startsWith(u8, line, "info ")) {
            try parseInfo(allocator, &data, line[5..]);
        } else if (std.mem.startsWith(u8, line, "common ")) {
            try parseCommon(allocator, &data, line[7..]);
        } else if (std.mem.startsWith(u8, line, "page ")) {
            try parsePage(allocator, &data, line[5..]);
        } else if (std.mem.startsWith(u8, line, "chars ")) {
            try parseChars(allocator, &data, line[6..]);
        } else if (std.mem.startsWith(u8, line, "char ")) {
            try parseChar(allocator, &data, line[5..]);
        } else {
            std.log.err("Unknown line: {s}\n", .{line});
        }
        allocator.free(line);
    }
    return data;
}
