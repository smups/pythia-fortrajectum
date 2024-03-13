const std = @import("std");

const Allocator = std.mem.Allocator;

const default_lhapdf_ddir = "lhapdf-dir";

 pub fn build(b: *std.Build) !void {
    // // Initialise allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    
    const root_dir = b.build_root.handle;
    const xml_dir = try root_dir.openDir("share/Pythia8/xmldoc", .{});

    // Get user-supplied target and optimize functions
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add options for lhapdf
    const lhapdf_ddir = b.option([]const u8, "lhapdf-dir", "path to lhapdf data directory containing pdf's")
        orelse try get_default_lhapdfddir_path(alloc, root_dir);
    const install_pdfs = b.option(bool, "download-pdfs", "whether to download and install pdf's") orelse false;

    const lhapdf = b.dependency("lhapdf_fortrajectum", .{
        .target = target,
        .optimize = optimize,
        .@"data-dir" = lhapdf_ddir,
        .@"download-pdfs" = install_pdfs
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

fn get_default_lhapdfddir_path(alloc: Allocator, root: std.fs.Dir) ![]const u8 {
    const ddir = root.makeOpenPath(default_lhapdf_ddir, .{}) catch |err| {
        std.debug.print("Could not create default lhapdf data dir {s}. Err: \"{s}\"", .{
            try root.realpathAlloc(alloc, default_lhapdf_ddir), @errorName(err)
        }); 
        return err; 
    };
    return try ddir.realpathAlloc(alloc, ".");
}
