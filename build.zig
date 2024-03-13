const std = @import("std");

const Allocator = std.mem.Allocator;

 pub fn build(b: *std.Build) !void {
    // // Initialise allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    // Get user-supplied target and optimize functions
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_dir = b.build_root.handle;
    const xml_dir = try root_dir.openDir("share/Pythia8/xmldoc", .{});

    const lhapdf = b.dependency("lhapdf_fortrajectum", .{
        .target = target,
        .optimize = optimize 
    });

    // Create compiled static lib
    const pythia = b.addStaticLibrary(.{
        .name = "pythia_fortrajectum",
        .target = target,
        .optimize = optimize,
    });

    pythia.linkLibrary(lhapdf.artifact("lhapdf-fortrajectum"));

    // Add headers
    pythia.addIncludePath(.{ .path = "include/" });
    pythia.addIncludePath(.{ .path = lhapdf.builder.h_dir });
    
    // Add weird plugin source
    const lhapdf_src_h_path = try root_dir.realpathAlloc(alloc, "plugin_src/LHAPDF6.cc");
    pythia.addCSourceFile(.{
        .file = .{ .path = lhapdf_src_h_path },
        .flags = &.{ "-std=c++11" }
    }); 
    
    // Add source
    const cpp_src = try list_cpp_src(alloc, try root_dir.openDir("src/", .{}));
    const cpp_flags = &.{
        "-std=c++11",
        try std.fmt.allocPrint(alloc, "-DXMLDIR=\"{s}\"", .{ try xml_dir.realpathAlloc(alloc, ".") }),
    };
    pythia.addCSourceFiles(cpp_src.items, cpp_flags);   

    // Install headers
    pythia.installHeadersDirectory("include", "");

    // Install archive
    b.installArtifact(pythia);
}

/// This function traverses the `src_dir` and produces an `ArrayList` of all
/// non-main source files in the `src_dir`.
fn list_cpp_src(alloc: Allocator, src_dir: std.fs.Dir) !std.ArrayList([]u8) {
    var source_files = std.ArrayList([]u8).init(alloc);
    var walker = (try src_dir.openIterableDir(".", .{ .no_follow = true })).iterate();
    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.name, ".cc")) {
            continue;
        }
        const realpath = try src_dir.realpathAlloc(alloc, entry.name);
        try source_files.append(realpath);
    }
    return source_files;
}
