const std = @import("std");
const cli_utils = @import("cli_utils.zig");
const date_utils = @import("date_utils.zig");
const file_utils = @import("file_utils.zig");

pub fn main() void {
    var args = std.process.args();
    const name = args.next().?;
    const cli = cli_utils.parse_cli_args(&args) catch |err| switch (err) {
        cli_utils.CliError.GoofyAssArg => {
            std.debug.print("\x1b[33mInvalid Argument. Run with --help to show proper usage.\x1b[0m\n", .{});
            return;
        },
        cli_utils.CliError.IdenticalArgs => {
            std.debug.print("\x1b[33mCan't use a single flag more than once.\x1b[0m\n", .{});
            return;
        },
        cli_utils.CliError.NoFile => {
            std.debug.print("\x1b[33mNo birthday file provided. Run --help to show proper usage.\x1b[0m\n", .{});
            return;
        },
        else => {
            help(name);
            return;
        },
    };

    switch (cli) {
        .cli => |c| {
            const date = date_utils.get_curr_date();
            var list = file_utils.read_file_to_list(c.file) catch {
                std.debug.print("\x1b[33mCouldn't read file.\x1b[0m\n", .{});
                return;
            };

            const allocator = std.heap.page_allocator;
            defer {
                for (list.items) |itm| {
                    allocator.free(itm.name);
                }
                list.deinit();
            }

            var had_bds = false;
            for (list.items) |bday| {
                if (bday.date == date) {
                    std.debug.print("{s} has a birthday today!\n", .{bday.name});
                    had_bds = true;
                }
            }
            if (!c.quiet and !had_bds) {
                std.debug.print("Noone has a birthday today :(\n", .{});
            }
        },
        .file_entry => |file_entry| {
            file_utils.write_bd_to_file(file_entry.file_name, file_entry.name, file_entry.date) catch {
                std.debug.print("Couldn't write to file, something bad happen\n", .{});
                return;
            };
        },
    }
}

fn help(bin: [:0]const u8) void {
    std.debug.print("Usage: {s} --file <filepath> <flags>\n\n", .{bin});
    std.debug.print("flags: \n", .{});
    print_flag(.{ "-h", "--help", "Displays this window." });
    print_flag(.{ "-q", "--quiet", "Displays no text when there are no birthdays to report." });
    print_flag(.{ "-f", "--file <file>", "This flag is necessary for the program to run," });
    print_flag(.{ "  ", "             ", "selects which file to use to load the birthdays." });
}

fn print_flag(args: anytype) void {
    std.debug.print("{s: >6} {s: <15} {s}\n", args);
}
