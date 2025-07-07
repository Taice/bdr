pub const std = @import("std");

pub fn get_curr_date() u16 {
    var days_left = @divTrunc(std.time.timestamp(), @as(i64, std.time.s_per_day));

    var year: u16 = 1970;
    var curr_year_days: u32 = 365;
    while (days_left >= curr_year_days) {
        days_left -= curr_year_days;

        year += 1;
        if (std.time.epoch.isLeapYear(year)) {
            curr_year_days = 366;
        } else {
            curr_year_days = 365;
        }
    }

    var curr_month: u16 = 1;
    var month_days: u32 = 31;
    while (days_left >= month_days) {
        days_left -= month_days;

        curr_month += 1;
        month_days = std.time.epoch.getDaysInMonth(year, @enumFromInt(curr_month));
    }

    const days: u16 = @intCast(days_left + 1);

    return curr_month * 100 + days;
}
