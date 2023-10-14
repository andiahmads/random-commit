const std = @import("std");
const http = std.http;

const RANDOM_MESSAGE_URL = "https://godsays.xyz";

fn getRandomMessage(allocator: std.mem.Allocator) ![]u8 {
    var client = http.Client{ .allocator = allocator };
    // Release all associated resources with the client.
    defer client.deinit();

    // Parse the URI.
    const uri = std.Uri.parse(RANDOM_MESSAGE_URL) catch unreachable;
    // Create the headers that will be sent to the server.
    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    // Accept anything.
    try headers.append("accept", "*/*");

    // make the connecetion to the server
    var request = try client.request(.GET, uri, headers, .{});
    defer request.deinit();

    // send request and headers to the server
    try request.start();

    // wait for the server to send use a response.
    try request.wait();

    return try request.reader().readAllAlloc(allocator, 8192);
}

fn commit(allocator: std.mem.Allocator, message: []const u8) !void {
    var process = std.ChildProcess.init(&[_][]const u8{ "git", "commit", "-m", message }, allocator);
    try process.spawn();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // get random message
    var message = try getRandomMessage(allocator);
    defer allocator.free(message);

    std.log.info("{s}", .{message});
    try commit(allocator, message);
    // create HTTP client
}
