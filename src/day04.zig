const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const expect = std.testing.expect;

const BingoBoard = struct {
    const Self = @This();

    board: [25]u8,
    marked: u25 = 0,
    bingo: bool = false,

    pub fn print(self: Self) !void {
        var stdout = std.io.getStdOut().writer();
        var row: usize = 0;
        var col: usize = 0;
        while (row < 5) : (row += 1) {
            col = 0;
            while (col < 5) : (col += 1) {
                const offset = (row * 5 + col);
                const item = self.board[offset];
                //std.log.debug("idx: {}, item: {}", .{offset, item});
                try stdout.print("{d: >4}", .{ item });
            }
            try stdout.print("\n", .{});
        }
        //try stdout.print("\n", .{});
    }
};

const Day4 = struct {
    const Self = @This();

    allocator: Allocator,
    bingo_calls: ArrayList(u32),
    bingo_boards: std.ArrayList(BingoBoard),

    pub fn init(allocator: Allocator) Self{
        return Self {
            .allocator = allocator,
            .bingo_calls = std.ArrayList(u32).init(allocator),
            .bingo_boards = std.ArrayList(BingoBoard).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.bingo_calls.deinit();
        self.bingo_boards.deinit();
    }


    pub fn loadDataFile(self: *Self, filename: [] const u8) !void {
        const file = try std.fs.cwd().openFile(filename, .{ .read = true });
        defer file.close();

        var reader = file.reader();
        try loadData(self, reader);
    }

    pub fn loadData(self: *Self, reader: anytype) !void{
        var buffer = ArrayList(u8).init(self.allocator);  // line buffer 
        defer buffer.deinit();
        
        // first line is bingo calls
        reader.readUntilDelimiterArrayList(&buffer, '\n', 1024) catch unreachable; 
        var calls = std.mem.tokenize(u8, buffer.items, ",");
        while(calls.next()) | call | {
            const call_no = try std.fmt.parseInt(u8, call, 10);
            try self.bingo_calls.append(call_no);
        }


        var board: BingoBoard = BingoBoard { .board = undefined };
        _  = board;
        var row : usize = 0;
        while (true) {
            reader.readUntilDelimiterArrayList(&buffer, '\n', 1024) catch {
                break;
            };
            const line = std.mem.trimRight(u8, buffer.items, "\r\n");
            if(line.len == 0) {
                row = 0;
                try self.bingo_boards.append(board);
                try board.print();
                continue;
            }
            std.log.debug("Row: {d}, {s}", .{row, line});
            var items = std.mem.tokenize(u8, line, " ");
            var col: usize = 0;
            while (items.next()) | item_str | {
                const item = try std.fmt.parseInt(u8, item_str, 10);
                const idx = ((row * 5 ) + col);
                //std.log.debug("idx: {}, item: {}", .{idx, item});
                board.board[idx] = item;
                col += 1;
            }
            row += 1;
        }

        std.log.debug("Call count: {}.", .{self.bingo_calls.items.len});
        std.log.debug("board count: {}.", .{self.bingo_boards.items.len});

        for(self.bingo_boards.items) | b | {
            try b.print();
            try std.io.getStdOut().writer().print("\n", .{});
        }
    }

    pub fn answerA(self: Self) i32 {
        _ = self;
        var result: i32 = 0;
        return result;
    }

    pub fn answerB(self: Self) i64 {
        _ = self;
        const result = 0;
        return result;
    }
};

pub fn main4() !void {
    const day: u32 = 4;
    std.log.info("Day {d}...", .{day});
    const input_dir = "/home/james/code/zig-aoc21/inputs";

    // std.log.default_level = std.log.Level.debug;
    // std.log.default_level = std.log.Level.info;
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();
    var day_impl = Day4.init(gpa);
    defer day_impl.deinit();
    const filename = std.fmt.comptimePrint("{s}/day{1d:0>2}.txt", .{input_dir, day});
    std.log.debug("input: {s}", .{filename});

    try day_impl.loadDataFile(filename);

    const answerA = day_impl.answerA();
    std.log.info("Day{d} A: '{}'.", .{day, answerA});
    const answerB = day_impl.answerB();
    std.log.info("Day{d} B: '{}'.", .{day, answerB});
}

pub fn day4() !void {
    try main4();
}

test "day3" {
    std.testing.log_level = std.log.Level.debug;
    try main4();
}
