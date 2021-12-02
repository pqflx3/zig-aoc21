const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const expect = std.testing.expect;


const Direction = enum {
    Up,
    Forward,
    Down,
};

const DirectionParseError = error { 
    ParseError,
};

const MovementCommand = struct {
    amount: i32,
    direction: Direction,
};


const Day2 = struct {
    const Self = @This();

    allocator: *Allocator,
    data: std.ArrayList(MovementCommand),

    pub fn init(allocator: *Allocator) Self{
        return Self {
            .allocator = allocator,
            .data = std.ArrayList(MovementCommand).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.data.deinit();
    }


    pub fn loadDataFile(self: *Self, filename: [] const u8) !void {
        const file = try std.fs.cwd().openFile(filename, .{ .read = true });
        defer file.close();

        var reader = file.reader();
        try loadData(self, reader);
    }

    pub fn parseDirection(s: [] const u8) !Direction {
        if (std.mem.eql(u8, s, "up")) {
                return Direction.Up;
            } else if (std.mem.eql(u8, s, "down")) {
                return Direction.Down;
            } else if (std.mem.eql(u8, s, "forward")) {
                return Direction.Forward;
            } else {
                return error.ParseError;
            }
    }


    pub fn loadData(self: *Self, reader: anytype) !void{
        var buffer = ArrayList(u8).init(self.allocator);  // line buffer 
        defer buffer.deinit();

        while (true) {
            reader.readUntilDelimiterArrayList(&buffer, '\n', 1024) catch {
                break;
            };
            const line = std.mem.trimRight(u8, buffer.items, "\r\n");
            const spaceIdx = std.mem.indexOfPos(u8, line, 0, " ").?;
            const dir_word = line[0..spaceIdx];
            const amt_str = line[spaceIdx+1..];
            std.log.debug("wrd: {s}, amt: {s}", .{ dir_word, amt_str });
            const d = try parseDirection(dir_word);
            const amt = try std.fmt.parseInt(i32, amt_str, 10);
            const cmd: MovementCommand = MovementCommand {
                .direction = d, 
                .amount = amt 
            };
            try self.data.append(cmd);
        }
    }

    pub fn answerA(self: Self) i32 {
        var x: i32 = 0;
        var y: i32 = 0; 
        for (self.data.items) |value| {
            if (value.direction == Direction.Up) {
                y += value.amount;
            } else if (value.direction == Direction.Down) {
                y -= value.amount;
            } else if (value.direction == Direction.Forward) {
                x += value.amount;
            }
        }
        std.log.debug("x: {d}, y: {d}", .{x,y});
        var result: i32 = ( (-1 * y) * x);
        return result;
    }

    pub fn answerB(self: Self) i64 {
        var x: i64 = 0;
        var y: i64 = 0;
        var aim: i64 = 0;

        for (self.data.items) |value| {
            if (value.direction == Direction.Up) {
                aim -= value.amount;
            } else if (value.direction == Direction.Down) {
                aim += value.amount;
            } else if (value.direction == Direction.Forward) {
                x += value.amount;
                y += (aim * value.amount);
            }
        }
        std.log.debug("x: {d}, y: {d}", .{x,y});
        const result: i64 = ( x * y );
        return result;
    }
};

pub fn day2() !void {
    std.log.info("Day 2...", .{});
    // std.log.default_level = std.log.Level.debug;
    // std.log.default_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d2 = Day2.init(&gpa.allocator);
    defer d2.deinit();
    
    const filename = "C:/code/aoc21/inputs/02a.txt";
    try d2.loadDataFile(filename);

    const answerA = d2.answerA();
    std.log.info("Day2 A: '{}'.", .{answerA});
    
    const answerB = d2.answerB();
    std.log.info("Day2 B: '{}'.", .{answerB});
}

test "day2" {
    std.testing.log_level = std.log.Level.debug;
    //std.testing.log_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d2 = Day2.init(&gpa.allocator);
    defer d2.deinit();
    
    const filename = "C:/code/aoc21/inputs/02a.txt";
    try d2.loadDataFile(filename);

    const answerA = d2.answerA();
    std.log.info("Day2 A: '{}'.", .{answerA});

    const answerB = d2.answerB();
    std.log.info("Day2 B: '{}'.", .{answerB});
}
