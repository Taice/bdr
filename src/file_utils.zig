const std = @import("std");

const Date = struct {
    year: u16,
    month: u8,
    date: u8,
};

pub const Bday = struct {
    date: u16,
    name: []const u8,
};

pub fn read_file_to_list(path: [:0]const u8) !std.ArrayList(Bday) {
    const allocator = std.heap.page_allocator;

    var list = std.ArrayList(Bday).init(allocator);
    const file = try std.fs.cwd().openFileZ(path, .{ .mode = std.fs.File.OpenMode.read_only });

    defer file.close();

    const stat = try file.stat();
    const size = stat.size;

    // Allocate a buffer for the file contents
    const buffer = try allocator.alloc(u8, size);
    defer allocator.free(buffer);

    // Read the file into the buffer
    _ = try file.readAll(buffer);

    var lines = std.mem.splitScalar(u8, buffer, '\n');

    while (lines.next()) |line| {
        // no use to read line if len = 0
        if (line.len == 0) {
            continue;
        }
        // allow for comments
        if (line[0] == '#') {
            continue;
        }

        var split = std.mem.splitScalar(u8, line, '=');

        const lhs = split.next() orelse continue;
        const rhs = split.next() orelse continue;

        var lhs_iter = std.mem.splitScalar(u8, lhs, '.');
        const llhs = lhs_iter.next() orelse continue;
        const lrhs = lhs_iter.next() orelse continue;

        const days = std.fmt.parseInt(u16, llhs, 10) catch continue;
        const months = std.fmt.parseInt(u16, lrhs, 10) catch continue;

        const date = months * 100 + days;

        try list.append(Bday{ .date = date, .name = try allocator.dupe(u8, rhs) });
    }

    return list;
}

pub fn write_bd_to_file(path: [:0]const u8, name: []const u8, date: []const u8) !void {
    const file = try std.fs.cwd().createFileZ(path, .{ .truncate = false });
    defer file.close();

    try file.seekFromEnd(0);

    var buffer: [100]u8 = undefined;

    // Write some text to the file
    try file.writer().writeAll(try std.fmt.bufPrint(&buffer, "{s}={s}\n", .{ date, name }));
}
