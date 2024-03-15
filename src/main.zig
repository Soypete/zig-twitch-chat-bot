const std = @import("std");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const allocator = std.heap.page_allocator;

    try stdout.print("setting up irc client.\n", .{});

    // non-ssl, in real life I think we want ssl
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);

    var uri = try std.Uri.parse("https://id.twitch.tv/oauth2/token");
    var client = std.http.Client{
        .allocator = allocator,
    };

    var headers = std.http.Headers{ .allocator = allocator };
    // // does the deinit() remove headers?
    defer headers.deinit();

    try headers.append("content-type", "application/x-www-form-urlencoded");

    var authPayload = "client_id=hof5gwx0su6owfnys0yan9c87zr6t&client_secret=41vpdji4e9gif29md0ouet6fktd2&grant_type=client_credentials";
    var req = try client.request(.POST, uri, headers, .{});

    try req.start();

    // write payload
    // - why did the example inclued a writer() before writeAll?
    try req.writer().writeAll(authPayload);
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
    try stdout.print("body: {s}\n", .{body});
}
