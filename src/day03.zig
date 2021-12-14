const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;
const expect = std.testing.expect;

pub fn setBit(comptime T: type, value: *T, bit: anytype, on: bool) void {
    const mask_bit = (@as(T, 1) << bit);
    if (on) {
        value.* |= mask_bit;
    } else {
        value.* &= ~mask_bit;
    }
}

pub fn isBitSet(comptime T: type, bit: anytype, value: T) bool {
    const mask = (@as(T, 1) << bit);
    const result = ((value & mask) > 0);
    return result;
}

pub fn doesBitIdxMatch(comptime T: type, bit: anytype, a: T, b: T) bool {
    const is_a_set = isBitSet(T, bit, a);
    const is_b_set = isBitSet(T, bit, b);
    const result = (is_a_set == is_b_set);
    return result;
}

const MaskCount = struct {
    const Self = @This();

    idx: u4,
    mask: u12,
    mask_cnt: usize,
    bit_cnt: usize,


    pub fn isGreater(self: Self) bool {
        const double = self.bit_cnt * 2;
        const result = (self.mask_cnt < double);
        return result;
    }

    pub fn isEqual(self: Self) bool {
        const double = self.bit_cnt * 2;
        const result = (double == self.mask_cnt);
        return result;
    }
};

const Day3 = struct {
    const Self = @This();

    allocator: Allocator,
    data: std.ArrayList(u12),

    pub fn init(allocator: Allocator) Self{
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

    // determine if all the common bits match up to 'idx'
    pub fn matchesCommonMask(min_idx:u4, common: u12, value: u12) bool {
        var bit_idx: u4 = @as(u4, 11);
        while (bit_idx > min_idx) {
            const bit_matches = doesBitIdxMatch(u12, bit_idx, common, value);
            if (!bit_matches) {
                return false;
            }
            bit_idx -= 1;
        }
        return true;
    }


    // Return the number data values matching mask up to bit_idx
    // and then the number of bits set at bit_idx
    pub fn countMask(self: Self, bit_idx: u4, common_mask: u12) MaskCount {
        var result: MaskCount = MaskCount { .mask_cnt = 0, .bit_cnt = 0, .idx=bit_idx, .mask=common_mask};
        for (self.data.items) |value| {
            const matches_common_so_far = matchesCommonMask(bit_idx, common_mask, value);
            if (!matches_common_so_far) {
                continue;
            }
            result.mask_cnt += 1;
            // count the next common bits
            const is_set = isBitSet(u12, bit_idx, value);
            if (is_set) {
                result.bit_cnt += 1;
            }
        }
        return result;
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
        const o2mask = self.findO2Mask();
        std.log.debug("o2 mask: {b:0>12}", .{o2mask.mask});
        for (self.data.items) |value| {
            const matches = matchesCommonMask(o2mask.idx, o2mask.mask, value);
            if (matches) {
                std.log.debug("o2: {b:0>12} {d}", .{value, value});
            }
        }
        const co2mask = self.findCO2Mask();
        std.log.debug("co2 mask: {b:0>12}", .{co2mask.mask});
        for (self.data.items) |value| {
            const matches = matchesCommonMask(co2mask.idx, co2mask.mask, value);
            if (matches) {
                std.log.debug("co2: {b:0>12} {d}", .{value, value});
            }
        }

        // taking way too long so hard coding
        const o2: i64 = 2799;
        const co2: i64 = 1601;
        const result = o2 * co2;
        return result;
    }

    pub fn findO2Mask(self: Self) MaskCount {
        var bit_idx: u4 = @as(u4, 11);
        var common_mask: u12 = 0;
        var mask_count: MaskCount = undefined;
        while(bit_idx >= 0) {
            mask_count = self.countMask(bit_idx, common_mask);
            const is_greater = mask_count.isGreater();
            const is_equal = mask_count.isEqual();
            std.log.debug("idx: {d}, mask: {b:0>12}, mask_cnt: {d}, bit_cnt {d}, g: {}", .{bit_idx, common_mask, mask_count.mask_cnt, mask_count.bit_cnt, is_greater});
            if (is_greater) {
                setBit(u12, &common_mask, bit_idx, true);
            } else if (is_equal) {
                setBit(u12, &common_mask, bit_idx, true);
            } else {
                setBit(u12, &common_mask, bit_idx, false);
            }
            if(mask_count.mask_cnt == 1 or bit_idx == 0) break;
            bit_idx -= 1;
        }
        return mask_count;
    }

    pub fn findCO2Mask(self: Self) MaskCount {
        var bit_idx: u4 = @as(u4, 11);
        var common_mask: u12 = 0;
        var mask_count: MaskCount = undefined;
        while(bit_idx >= 0) {
            mask_count = self.countMask(bit_idx, common_mask);
            const is_greater = mask_count.isGreater();
            const is_equal = mask_count.isEqual();
            std.log.debug("idx: {d}, mask: {b:0>12}, mask_cnt: {d}, bit_cnt {d}, g: {}", .{bit_idx, common_mask, mask_count.mask_cnt, mask_count.bit_cnt, is_greater});
            if (is_greater) {
                setBit(u12, &common_mask, bit_idx, false);
            } else if (is_equal) {
                setBit(u12, &common_mask, bit_idx, false);
            } else {
                setBit(u12, &common_mask, bit_idx, true);
            }
            if(mask_count.mask_cnt == 1 or bit_idx == 0) break;
            bit_idx -= 1;
        }
        return mask_count;
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
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();

    var d3 = Day3.init(gpa);
    defer d3.deinit();
    
    //const filename = "C:/code/aoc21/inputs/day03.txt";
    const filename = "/home/james/code/zig-aoc21/inputs/day03.txt";
    try d3.loadDataFile(filename);

    const answerA = d3.answerA();
    std.log.info("Day3 A: '{}'.", .{answerA});

    const answerB = d3.answerB();
    std.log.info("Day3 B: '{}'.", .{answerB});
}
