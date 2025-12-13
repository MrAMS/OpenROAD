# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025, The OpenROAD Authors

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_bison//bison:bison.bzl", "bison_cc_library")

package(
    default_visibility = ["//:__subpackages__"],
    features = ["layering_check"],
)

DEF_HEADERS = [
    "def/defiAlias.hpp",
    "def/defiAssertion.hpp",
    "def/defiBlockage.hpp",
    "def/defiComponent.hpp",
    "def/defiDebug.hpp",
    "def/defiDefs.hpp",
    "def/defiFPC.hpp",
    "def/defiFill.hpp",
    "def/defiGroup.hpp",
    "def/defiIOTiming.hpp",
    "def/defiKRDefs.hpp",
    "def/defiMisc.hpp",
    "def/defiNet.hpp",
    "def/defiNonDefault.hpp",
    "def/defiPartition.hpp",
    "def/defiPath.hpp",
    "def/defiPinCap.hpp",
    "def/defiPinProp.hpp",
    "def/defiProp.hpp",
    "def/defiPropType.hpp",
    "def/defiRegion.hpp",
    "def/defiRowTrack.hpp",
    "def/defiScanchain.hpp",
    "def/defiSite.hpp",
    "def/defiSlot.hpp",
    "def/defiTimingDisable.hpp",
    "def/defiUser.hpp",
    "def/defiUtil.hpp",
    "def/defiVia.hpp",
    "def/defrCallBacks.hpp",
    "def/defrData.hpp",
    "def/defrReader.hpp",
    "def/defrSettings.hpp",
    "def/defwWriter.hpp",
    "def/defwWriterCalls.hpp",
]

# Wrapper header to make generated def_bison_lib.h available as def_parser.hpp
# The source code expects def_parser.hpp, but bison_cc_library generates def_bison_lib.h
# This wrapper is created statically without depending on bison output to avoid circular dependency
genrule(
    name = "def_parser_wrapper_gen",
    outs = ["def/def_parser.hpp"],
    cmd = """
        echo '// Wrapper for bison-generated parser header' > $(location def/def_parser.hpp)
        echo '// Bazel generates def_bison_lib.h, but source code expects def_parser.hpp' >> $(location def/def_parser.hpp)
        echo '#ifndef DEF_PARSER_HPP' >> $(location def/def_parser.hpp)
        echo '#define DEF_PARSER_HPP' >> $(location def/def_parser.hpp)
        echo '// Bison header is one directory up from this wrapper' >> $(location def/def_parser.hpp)
        echo '#include "../def_bison_lib.h"' >> $(location def/def_parser.hpp)
        echo '#endif // DEF_PARSER_HPP' >> $(location def/def_parser.hpp)
    """,
)

# Library to properly export the wrapper header
cc_library(
    name = "def_parser_wrapper",
    hdrs = [":def_parser_wrapper_gen"],
    includes = ["def"],
    deps = [":def_bison_lib"],
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
)

# Header-only library for bison to access DEF headers
# Note: Does NOT include def_parser_wrapper to avoid circular dependency
# The wrapper is added to the main def library deps instead
cc_library(
    name = "def_headers",
    hdrs = DEF_HEADERS + [":def_parser_wrapper_gen"],
    features = [
        "-use_header_modules",
    ],
    includes = ["def"],
)

bison_cc_library(
    name = "def_bison_lib",
    src = "def/def.y",
    bison_options = ["-p", "defyy"],  # Match CMake behavior - no skeleton override
    copts = [
        "-x", "c++",
        "-Wno-unused-but-set-variable",
        "-Wno-modules-import-nested-redundant",
        "-Wno-free-nonheap-object",
    ],
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
    deps = [":def_headers"],
)

# TODO: This can probably be broken into smaller, more specific parts.
# TODO: once we establish src/odb as package, make aliases so that we
#  don't need the awkward long path with double src
#  //src/odb/src/def:def but can say //src/odb:def
cc_library(
    name = "def",
    srcs = [
        "def/def_keywords.cpp",
        "def/defiAlias.cpp",
        "def/defiAssertion.cpp",
        "def/defiBlockage.cpp",
        "def/defiComponent.cpp",
        "def/defiDebug.cpp",
        "def/defiFPC.cpp",
        "def/defiFill.cpp",
        "def/defiGroup.cpp",
        "def/defiIOTiming.cpp",
        "def/defiMisc.cpp",
        "def/defiNet.cpp",
        "def/defiNonDefault.cpp",
        "def/defiPartition.cpp",
        "def/defiPath.cpp",
        "def/defiPinCap.cpp",
        "def/defiPinProp.cpp",
        "def/defiProp.cpp",
        "def/defiPropType.cpp",
        "def/defiRegion.cpp",
        "def/defiRowTrack.cpp",
        "def/defiScanchain.cpp",
        "def/defiSite.cpp",
        "def/defiSlot.cpp",
        "def/defiTimingDisable.cpp",
        "def/defiUtil.cpp",
        "def/defiVia.cpp",
        "def/defrCallbacks.cpp",
        "def/defrData.cpp",
        "def/defrReader.cpp",
        "def/defrSettings.cpp",
        "def/defwWriter.cpp",
        "def/defwWriterCalls.cpp",
    ],
    hdrs = DEF_HEADERS,
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
    includes = ["def"],
    deps = [
        ":def_bison_lib",
        ":def_parser_wrapper",
    ],
)

cc_library(
    name = "defzlib",
    srcs = [
        "defzlib/defzlib.cpp",
    ],
    hdrs = [
        "defzlib/defzlib.hpp",
    ],
    includes = ["defzlib"],
    deps = [
        ":def",
        ":def_bison_lib",
        "@zlib",
    ],
)
