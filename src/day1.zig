const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const expect = std.testing.expect;

const Day1 = struct {
    const Self = @This();

    allocator: *Allocator,
    data: std.ArrayList(u32),

    pub fn init(allocator: *Allocator) Self{
        return Self {
            .allocator = allocator,
            .data = std.ArrayList(u32).init(allocator),
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

    pub fn loadData(self: *Self, reader: anytype) !void{
        var buffer = ArrayList(u8).init(self.allocator);  // line buffer 
        defer buffer.deinit();

        while (true) {
            reader.readUntilDelimiterArrayList(&buffer, '\n', 1024) catch {
                break;
            };
            const line = std.mem.trimRight(u8, buffer.items, "\r\n");
            const val = try std.fmt.parseInt(u32, line, 10);
            try self.data.append(val);
        }
    }

    /// Find number of times two consecutive numbers increase
    pub fn answerA(self: Self) u32 {
        var result: u32 = 0;
        var r2:u32 = 0;
        var last: u32 = 1000000; // some large number
        for (self.data.items) |val1, idx1| {
            _ = idx1;
            if (val1 > last) {
                result += 1;
            } else {
                r2 += 1;
            }
            last = val1;
        }
        std.log.debug("r1: {}, r2: {}", .{ result, r2 });
        return result;
    }

    /// Find number of times two consecutive windows of 3 increase
    pub fn answerB(self: Self) u32 {
        var result: u32 = 0;
        //var r2:u32 = 0;
        var last0: u32 = 0;
        var last1: u32 = 0;
        var last2: u32 = 0; 
        var last_sum: u32 = 1000000; // some large number

        for (self.data.items) |val1, idx1| {
            last2 = last1;
            last1 = last0;
            last0 = val1;

            // establish window of 3
            if (idx1 < 2) continue;

            const sum = last2 + last1 + last0;
            if (sum > last_sum ) { 
                result += 1;
            }
            last_sum = sum;
        }
        //std.log.debug("r1: {}, r2: {}", .{ result, r2 });
        return result;
    }
};

pub fn day1() !void {
    std.log.info("Day 1...", .{});
    // std.log.default_level = std.log.Level.debug;
    // std.log.default_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d1 = Day1.init(&gpa.allocator);
    defer d1.deinit();
    
    const filename = "C:/code/aoc21/inputs/01a.txt";
    try d1.loadDataFile(filename);

    const answerA = d1.answerA();
    std.log.info("Day1 A: '{}'.", .{answerA});
    
    const answerB = d1.answerB();
    std.log.info("Day1 B: '{}'.", .{answerB});
}

test "day1" {
    std.testing.log_level = std.log.Level.debug;
    //std.testing.log_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d1 = Day1.init(&gpa.allocator);
    defer d1.deinit();
    
    const filename = "C:/code/aoc21/inputs/01a.txt";
    try d1.loadDataFile(filename);

    const answerA = d1.answerA();
    std.log.info("Day1 A: '{}'.", .{answerA});

    const answerB = d1.answerB();
    std.log.info("Day1 B: '{}'.", .{answerB});
}
