pub const std = @import("std");

pub const FileEntry = struct {
    file_name: [:0]const u8 = undefined,
    date: []const u8 = undefined,
    name: []const u8 = undefined,
};

pub const Cli = struct {
    quiet: bool = false,
    file: [:0]const u8 = undefined,
};

pub const CliResult = union(enum) {
    cli: Cli,
    file_entry: FileEntry,
};

pub const CliError = error{
    InvalidIterator,
    GoofyAssArg,
    IdenticalArgs,
    NoFile,
    HelpRequested,
};

pub const Arg = enum { file, quiet, add, date, name };

pub fn parse_cli_args(args: *std.process.ArgIterator) !CliResult {
    var file: [:0]const u8 = undefined;
    var got_file = false;
    var cli = Cli{};
    var file_entry = FileEntry{};

    var is_cli = true;
    var curr_arg: ?Arg = null;

    var arg_set = std.AutoHashMap(Arg, void).init(std.heap.page_allocator);
    defer arg_set.deinit();

    while (args.next()) |arg| {
        // File argument
        if (std.mem.eql(u8, "-f", arg) or std.mem.eql(u8, "--file", arg)) {
            if (arg_set.get(Arg.file) != null) {
                return CliError.IdenticalArgs;
            }

            curr_arg = Arg.file;

            try arg_set.put(Arg.file, {});
        } else if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
            return CliError.HelpRequested;
        } else if (std.mem.eql(u8, "-a", arg) or std.mem.eql(u8, "-a", arg)) {
            if (arg_set.get(Arg.add) != null) {
                return CliError.IdenticalArgs;
            }

            curr_arg = Arg.date;
            is_cli = false;

            try arg_set.put(Arg.add, {});
        } else if (std.mem.eql(u8, "-q", arg) or std.mem.eql(u8, "--quiet", arg)) {
            if (!is_cli) {
                continue;
            }
            if (arg_set.get(Arg.quiet) != null) {
                return CliError.IdenticalArgs;
            }

            cli.quiet = true;
            curr_arg = Arg.quiet;

            try arg_set.put(Arg.quiet, {});
        } else {
            switch (curr_arg orelse return CliError.GoofyAssArg) {
                Arg.file => {
                    file = arg;
                    got_file = true;
                },
                Arg.date => {
                    file_entry.date = arg;

                    curr_arg = Arg.name;
                },
                Arg.name => {
                    file_entry.name = arg;
                },
                else => return CliError.GoofyAssArg,
            }
        }
    }

    if (!got_file) {
        return CliError.NoFile;
    }

    if (is_cli) {
        cli.file = file;
        return CliResult{ .cli = cli };
    } else {
        file_entry.file_name = file;
        return CliResult{ .file_entry = file_entry };
    }
}
