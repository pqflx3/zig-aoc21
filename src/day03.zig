const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const expect = std.testing.expect;



const Day3 = struct {
    const Self = @This();

    allocator: *Allocator,
    data: std.ArrayList(u12),

    pub fn init(allocator: *Allocator) Self{
        return Self {
            .allocator = allocator,
            .data = std.ArrayList(u12).init(allocator),
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
            const value = try std.fmt.parseInt(u12, line, 2);
            try self.data.append(value);
        }
    }

    pub fn answerA(self: Self) i32 {
        var bit_cnt: [12] u32 = undefined;
        var i: u4 = 0;
        while( i < 12 ) {
            bit_cnt[i] = 0;
            i += 1;
        }
        var count: i32 = 0;
        for (self.data.items) |value| {
            i = 0;
            while (i < 12) {
                const mask = (@as(u12, 1) << i);
                const is_set = ((value & mask) > 0);
                if (is_set) {
                    bit_cnt[i] += 1;
                }
                i += 1;
            }
            count += 1; 
        }
        i = 0;
        while (i<12) {
            std.log.debug("i: {d}, cnt: {d} .", .{i, bit_cnt[i]});
            i += 1;
        }
        // determine gamma
        var gamma: u12 = 0;
        var epsilon: u12 = 0;
        i = 0;
        const half_cnt = @divTrunc(count, 2);
        while (i < 12) {
            if (bit_cnt[i] > half_cnt) {
                gamma |= (@as(u12, 1) << i);
            }
            i += 1;
        }
        epsilon = ~gamma;
        std.log.debug("g: {b}, e: {b}", .{gamma, epsilon});
        std.log.debug("g: {d}, e: {d}", .{gamma, epsilon});
        var result: i32 = @as(i32, gamma) * @as(i32, epsilon);
        return result;
    }

    pub fn answerB(self: Self) i64 {
        const result: i64 = 0;
        _ = self;
        return result;
    }
};

pub fn day3() !void {
    std.log.info("Day 3...", .{});
    // std.log.default_level = std.log.Level.debug;
    // std.log.default_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d3 = Day3.init(&gpa.allocator);
    defer d3.deinit();
    
    const filename = "C:/code/aoc21/inputs/day03.txt";
    try d3.loadDataFile(filename);

    const answerA = d3.answerA();
    std.log.info("Day3 A: '{}'.", .{answerA});
    
    const answerB = d3.answerB();
    std.log.info("Day3 B: '{}'.", .{answerB});
}

test "day3" {
    std.testing.log_level = std.log.Level.debug;
    //std.testing.log_level = std.log.Level.info;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var d3 = Day3.init(&gpa.allocator);
    defer d3.deinit();
    
    const filename = "C:/code/aoc21/inputs/day03.txt";
    try d3.loadDataFile(filename);

    const answerA = d3.answerA();
    std.log.info("Day3 A: '{}'.", .{answerA});

    const answerB = d3.answerB();
    std.log.info("Day3 B: '{}'.", .{answerB});
}
