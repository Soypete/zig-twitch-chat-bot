const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("setting up irc client.\n", .{});

    // non-ssl, in real life I think we want ssl
    // var uri = try std.Uri.parse("ws://irc-ws.chat.twitch.tv:80");
    var uri = try std.Uri.parse("irc://irc.chat.twitch.tv:6667");

    var client = std.http.Client{
        .allocator = allocator,
    };

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    var headers = std.http.Headers{ .allocator = allocator };
    // // does the deinit() remove headers?
    defer headers.deinit();

    try headers.append("accept", "*/*");

    var req = try client.request(.GET, uri, headers, .{});
    // does the deinit() remove the variable allocation?

    try stdout.print("encoding {!}\n", .{req.transfer_encoding});
    defer req.deinit();

    // run request
    try req.start();
    // write payload
    // try req.writer().writeAll("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands");
    // try req.finish();

    // wait for respond
    try req.wait();

    // method requires two arguements
    const body = req.reader().readAllAlloc(allocator, 8192) catch unreachable;
    defer allocator.free(body);
    // free up client bytes
    // outstanding question:
    // - will we be able to make additional calls after the defer executes
    // - is defer run at the end of the function
    // - what happens if we get more data than bytes? does streaming via several data packets?
    // - what is the buffer used for?
    try stdout.print("body {s}\n", .{body});

    try bw.flush(); // don't forget to flush!
}

// call twitch api auth
fn doAuth() []u8 {
    var uri = try std.Uri.parse("https://id.twitch.tv/oauth2/token");
    var client = std.http.Client{
        .allocator = allocator,
    };

    // what does this do?
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    var headers = std.http.Headers{ .allocator = allocator };
    // // does the deinit() remove headers?
    defer headers.deinit();

    try headers.append("content-type", "application/x-www-form-urlencoded");

    var req = try client.request(.GET, uri, headers, .{});

    try req.start;

    return "";
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
