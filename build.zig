const std = @import("std");
const Allocator = std.mem.Allocator;

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
    const lhapdf_ddir = b.option([]const u8, "lhapdf-dir", "path to lhapdf data directory containing pdf's");
    const install_pdfs = b.option(bool, "download-pdfs", "whether to download and install pdf's") orelse false;

    const lhapdf = blk: {
        if (lhapdf_ddir) |path| {
            break :blk b.dependency("lhapdf", .{
                .target = target,
                .optimize = optimize,
                .@"data-dir" = path,
                .@"download-pdfs" = install_pdfs
            });
        } else {
            break :blk b.dependency("lhapdf", .{
                .target = target,
                .optimize = optimize,
                .@"download-pdfs" = install_pdfs
            });
        }
    };

    // Create compiled static lib
    const pythia = b.addStaticLibrary(.{
        .name = "pythia_fortrajectum",
        .target = target,
        .optimize = optimize,
    });

    pythia.linkLibrary(lhapdf.artifact("lhapdf-fortrajectum"));

    // Add headers
    pythia.addIncludePath(b.path("include"));
    
    // Add weird plugin source
    pythia.addCSourceFile(.{
        .file = b.path("plugin_src/LHAPDF6.cc"),
        .flags = &.{ "-std=c++11" }
    }); 
    
    // Add source
    const cpp_flags = &.{
        "-std=c++11",
        try std.fmt.allocPrint(alloc, "-DXMLDIR=\"{s}\"", .{ try xml_dir.realpathAlloc(alloc, ".") }),
    };
    pythia.addCSourceFiles(.{ .files = cpp_src, .flags = cpp_flags });   

    // Install headers
    pythia.installHeadersDirectory(b.path("include"), "", .{});

    // Install archive
    b.installArtifact(pythia);
    b.installArtifact(lhapdf.artifact("lhapdf-fortrajectum"));
}

/// List of source files
const cpp_src = &.{
    "src/Analysis.cc",
    "src/Basics.cc",
    "src/BeamParticle.cc",
    "src/BeamRemnants.cc",
    "src/BeamSetup.cc",
    "src/BeamShape.cc",
    "src/BoseEinstein.cc",
    "src/ColourReconnection.cc",
    "src/ColourTracing.cc",
    "src/DeuteronProduction.cc",
    "src/DireBasics.cc",
    "src/Dire.cc",
    "src/DireHistory.cc",
    "src/DireMerging.cc",
    "src/DireMergingHooks.cc",
    "src/DireSpace.cc",
    "src/DireSplitInfo.cc",
    "src/DireSplittingLibrary.cc",
    "src/DireSplittings.cc",
    "src/DireSplittingsEW.cc",
    "src/DireSplittingsQCD.cc",
    "src/DireSplittingsQED.cc",
    "src/DireSplittingsU1new.cc",
    "src/DireTimes.cc",
    "src/DireWeightContainer.cc",
    "src/Event.cc",
    "src/ExternalMEs.cc",
    "src/FJcore.cc",
    "src/FragmentationFlavZpT.cc",
    "src/FragmentationSystems.cc",
    "src/GammaKinematics.cc",
    "src/HadronLevel.cc",
    "src/HadronWidths.cc",
    "src/HardDiffraction.cc",
    "src/HeavyIons.cc",
    "src/HelicityBasics.cc",
    "src/HelicityMatrixElements.cc",
    "src/HiddenValleyFragmentation.cc",
    "src/HIInfo.cc",
    "src/HINucleusModel.cc",
    "src/History.cc",
    "src/HISubCollisionModel.cc",
    "src/Info.cc",
    "src/JunctionSplitting.cc",
    "src/LesHouches.cc",
    "src/LHEF3.cc",
    "src/Logger.cc",
    "src/LowEnergyProcess.cc",
    "src/MathTools.cc",
    "src/Merging.cc",
    "src/MergingHooks.cc",
    "src/MiniStringFragmentation.cc",
    "src/MultipartonInteractions.cc",
    "src/NucleonExcitations.cc",
    "src/ParticleData.cc",
    "src/ParticleDecays.cc",
    "src/PartonDistributions.cc",
    "src/PartonLevel.cc",
    "src/PartonSystems.cc",
    "src/PartonVertex.cc",
    "src/PhaseSpace.cc",
    "src/PhysicsBase.cc",
    "src/Plugins.cc",
    "src/ProcessContainer.cc",
    "src/ProcessLevel.cc",
    "src/Pythia.cc",
    "src/PythiaParallel.cc",
    "src/PythiaStdlib.cc",
    "src/ResonanceDecays.cc",
    "src/ResonanceWidths.cc",
    "src/ResonanceWidthsDM.cc",
    "src/RHadrons.cc",
    "src/Ropewalk.cc",
    "src/Settings.cc",
    "src/ShowerModel.cc",
    "src/SigmaCompositeness.cc",
    "src/SigmaDM.cc",
    "src/SigmaEW.cc",
    "src/SigmaExtraDim.cc",
    "src/SigmaGeneric.cc",
    "src/SigmaHiggs.cc",
    "src/SigmaLeftRightSym.cc",
    "src/SigmaLeptoquark.cc",
    "src/SigmaLowEnergy.cc",
    "src/SigmaNewGaugeBosons.cc",
    "src/SigmaOnia.cc",
    "src/SigmaProcess.cc",
    "src/SigmaQCD.cc",
    "src/SigmaSUSY.cc",
    "src/SigmaTotal.cc",
    "src/SimpleSpaceShower.cc",
    "src/SimpleTimeShower.cc",
    "src/SimpleWeakShowerMEs.cc",
    "src/SLHAinterface.cc",
    "src/SplittingsOnia.cc",
    "src/StandardModel.cc",
    "src/Streams.cc",
    "src/StringFragmentation.cc",
    "src/StringInteractions.cc",
    "src/StringLength.cc",
    "src/SusyCouplings.cc",
    "src/SusyLesHouches.cc",
    "src/SusyResonanceWidths.cc",
    "src/SusyWidthFunctions.cc",
    "src/TauDecays.cc",
    "src/UserHooks.cc",
    "src/VinciaAntennaFunctions.cc",
    "src/Vincia.cc",
    "src/VinciaCommon.cc",
    "src/VinciaDiagnostics.cc",
    "src/VinciaEW.cc",
    "src/VinciaFSR.cc",
    "src/VinciaHistory.cc",
    "src/VinciaISR.cc",
    "src/VinciaMerging.cc",
    "src/VinciaMergingHooks.cc",
    "src/VinciaQED.cc",
    "src/VinciaTrialGenerators.cc",
    "src/VinciaWeights.cc",
    "src/Weights.cc",
};
