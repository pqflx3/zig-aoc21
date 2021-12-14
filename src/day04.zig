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
                const bit_mask = @as(u25, 1) << @intCast(u5, offset);
                const item = self.board[offset];
                const is_marked = ((self.marked & bit_mask) > 0);
                const mark_char = if(is_marked) "x" else "o";
                    
                //std.log.debug("idx: {}, item: {}", .{offset, item});
                try stdout.print("{d:0>2} {s} ", .{ item, mark_char });
            }
            try stdout.print("\n", .{});
        }
        //try stdout.print("\n", .{});
    }

    // Attempt to mark bingo board will 'call'.
    // Returns whether or not board was marked
    pub fn mark(self: *Self, call: u8) bool {
        for (self.board) | n, idx | {
            const bit_mask = @as(u25, 1) << @intCast(u5, idx);
            if ( n == call) {
                self.marked |= bit_mask;
                return true;
            }
        }
        return false;
    }

    // Checks rows, cols, and diags for bingo
    pub fn hasBingo(self: Self) bool {
        // check rows
        var row: usize = 0;
        var col: usize = 0;
        outer: while ( row < 5 ) : (row += 1) {
            col = 0;
             while ( col < 5): (col += 1) {
                const bit_mask = @as(u25, 1) << @intCast(u5, (row * 5 + col));
                const is_set = ((self.marked & bit_mask) > 0);
                if (!is_set) {
                    continue :outer;
                }
            }
            return true;
        }
        // check columns
        col = 0;
        outer: while ( col < 5): (col += 1) {
            row = 0;
             while ( row < 5 ) : (row += 1) {
                const bit_mask = @as(u25, 1) << @intCast(u5, (row * 5 + col));
                const is_set = ((self.marked & bit_mask) > 0);
                if (!is_set) {
                    continue :outer;
                }
            }
            return true;
        }
        // check TL->BR diag, counting by 6 moves down and right 1
        return false;

        // var idx: isize = 0;
        // var bingo = true;
        // while (idx < 25) : (idx += 6) {
        //     const bit_mask = @as(u25, 1) << @intCast(u5, idx);
        //     const is_set = ((self.marked & bit_mask) > 0);
        //     if (!is_set) {
        //         bingo = false;
        //         break;
        //     }
        // }
        // if (bingo) return true;

        // // check BL->TR diag, subtract 4 moves up, right by 1
        // idx = 20;
        // bingo = true;
        // while (idx > 0) : (idx -= 4) {
        //     const bit_mask = @as(u25, 1) << @intCast(u5, idx);
        //     const is_set = ((self.marked & bit_mask) > 0);
        //     if (!is_set) {
        //         bingo = false;
        //         break;
        //     }
        // }
        // return bingo;
    }

    // Returns the sum of unmarked spaces
    pub fn sumUnmarked(self: Self) i64 {
        var result: i64 = 0;
        for(self.board) |n, idx| {
            const bit_mask = @as(u25, 1) << @intCast(u5, idx);
            const is_set = ((self.marked & bit_mask) > 0);
            if (!is_set) {
                result += n;
            }
        }
        return result;
    }
};

test "BingoBoard" {
    const board = BingoBoard {.board = undefined, .marked = 0b00000_00000_00000_00000_00000};
    try std.testing.expectEqual(board.hasBingo(), false);
    
    const board_row = BingoBoard {.board = undefined, .marked = 0b00000_11111_00000_00000_00000};
    try std.testing.expectEqual(board_row.hasBingo(), true);

    const board_col = BingoBoard {.board = undefined, .marked = 0b00100_00100_00100_00100_00100};
    try std.testing.expectEqual(board_col.hasBingo(), true);
    
    const board_lr = BingoBoard {.board = undefined, .marked = 0b10000_01000_00100_00010_00001};
    try std.testing.expectEqual(board_lr.hasBingo(), true);
    
    const board_rl = BingoBoard {.board = undefined, .marked = 0b00001_00010_00100_01000_10000};
    try std.testing.expectEqual(board_rl.hasBingo(), true);
}

const Day4 = struct {
    const Self = @This();

    allocator: Allocator,
    bingo_calls: ArrayList(u8),
    bingo_boards: std.ArrayList(BingoBoard),

    pub fn init(allocator: Allocator) Self{
        return Self {
            .allocator = allocator,
            .bingo_calls = std.ArrayList(u8).init(allocator),
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
                //try board.print();
                continue;
            }
            //std.log.debug("Row: {d}, {s}", .{row, line});
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

        //for(self.bingo_boards.items) | b | {
        //    try b.print();
        //    try std.io.getStdOut().writer().print("\n", .{});
        //}
    }

    pub fn answerA(self: Self) i64 {
        _ = self;
        var result: i64 = 0;
        outer: for (self.bingo_calls.items) | call | {
            // mark
            for(self.bingo_boards.items) |*board | {
                _ = board.mark(call);
            }

            // bingo check
            for(self.bingo_boards.items) | board | {
                const has_bingo = board.hasBingo();
                if( has_bingo ) {
                    var sum_unmarked = board.sumUnmarked();
                    result = (sum_unmarked * call);
                    break :outer;
                }
            }
        }
        return result;
    }

    pub fn answerB(self: Self) !i64 {
        _ = self;
        var last_board: BingoBoard = undefined;
        var last_call: u8 = 0;
        var total_count: u8 = 0;
        for (self.bingo_calls.items) | call, idx | {
            // mark
            var count: u8 = 0;
            inner: for(self.bingo_boards.items) |*board | {
                // skip boards that already have bingo

                if(board.hasBingo()) {
                    continue :inner; 
                }
                _ = board.mark(call);
                if(board.hasBingo()) {
                    count += 1;
                    last_board = board.*;
                    last_call = call;
                }
            }
            if(count > 0) {
                std.log.debug("{}: Call {d:0>2}, cnt: {}", .{idx, call, count});
            }
            total_count += count;
        }
        std.log.debug("Total: {}", .{total_count});

        try last_board.print();

        std.log.debug("Last bingo call: {}.", .{last_call});

        const sum_unmarked = last_board.sumUnmarked();
        std.log.debug("Sum Last: {}.", .{sum_unmarked});
        
        const result = (sum_unmarked * last_call);
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
    const answerB = try day_impl.answerB();
    std.log.info("Day{d} B: '{}'.", .{day, answerB});
}

pub fn day4() !void {
    try main4();
}

test "day3" {
    std.testing.log_level = std.log.Level.debug;
    try main4();
}
