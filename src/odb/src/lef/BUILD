# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025, The OpenROAD Authors

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_bison//bison:bison.bzl", "bison_cc_library")

package(
    default_visibility = ["//:__subpackages__"],
    features = ["layering_check"],
)

LEF_HEADERS = [
    "lef/crypt.hpp",
    "lef/lefiArray.hpp",
    "lef/lefiCrossTalk.hpp",
    "lef/lefiDebug.hpp",
    "lef/lefiDefs.hpp",
    "lef/lefiEncryptInt.hpp",
    "lef/lefiKRDefs.hpp",
    "lef/lefiLayer.hpp",
    "lef/lefiMacro.hpp",
    "lef/lefiMisc.hpp",
    "lef/lefiNonDefault.hpp",
    "lef/lefiProp.hpp",
    "lef/lefiPropType.hpp",
    "lef/lefiUnits.hpp",
    "lef/lefiUser.hpp",
    "lef/lefiUtil.hpp",
    "lef/lefiVia.hpp",
    "lef/lefiViaRule.hpp",
    "lef/lefrCallBacks.hpp",
    "lef/lefrData.hpp",
    "lef/lefrReader.hpp",
    "lef/lefrSettings.hpp",
    "lef/lefwWriter.hpp",
    "lef/lefwWriterCalls.hpp",
    "lef/lex.h",
]

# Wrapper header to make generated lef_bison_lib.h available as lef_parser.hpp
# The source code expects lef_parser.hpp, but bison_cc_library generates lef_bison_lib.h
# This wrapper is created statically without depending on bison output to avoid circular dependency
genrule(
    name = "lef_parser_wrapper_gen",
    outs = ["lef/lef_parser.hpp"],
    cmd = """
        echo '// Wrapper for bison-generated parser header' > $(location lef/lef_parser.hpp)
        echo '// Bazel generates lef_bison_lib.h, but source code expects lef_parser.hpp' >> $(location lef/lef_parser.hpp)
        echo '#ifndef LEF_PARSER_HPP' >> $(location lef/lef_parser.hpp)
        echo '#define LEF_PARSER_HPP' >> $(location lef/lef_parser.hpp)
        echo '// Bison header is one directory up from this wrapper' >> $(location lef/lef_parser.hpp)
        echo '#include "../lef_bison_lib.h"' >> $(location lef/lef_parser.hpp)
        echo '#endif // LEF_PARSER_HPP' >> $(location lef/lef_parser.hpp)
    """,
)

# Library to properly export the wrapper header
cc_library(
    name = "lef_parser_wrapper",
    hdrs = [":lef_parser_wrapper_gen"],
    includes = ["lef"],
    deps = [":lef_bison_lib"],
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
)

# Header-only library for bison to access LEF headers including lex.h
# Includes wrapper gen to allow .y file to include lef_parser.hpp during bison generation
cc_library(
    name = "lef_headers",
    hdrs = LEF_HEADERS + [":lef_parser_wrapper_gen"],
    features = [
        "-use_header_modules",
    ],
    includes = ["lef"],
)

bison_cc_library(
    name = "lef_bison_lib",
    src = "lef/lef.y",
    bison_options = ["-p", "lefyy"],  # Removed -S lalr1.cc to match CMake behavior
    copts = [
        "-x", "c++",  # Force C++ compilation - bison generates C code despite %language directive
        "-Wno-unused-but-set-variable",
        "-Wno-modules-import-nested-redundant",
        "-Wno-free-nonheap-object",
    ],
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
    deps = [":lef_headers"],
)

# TODO: This can probably be broken into smaller, more specific parts.
# TODO: once we establish src/odb as package, make aliases so that we
#  don't need the awkward long path with double src
#  //src/odb/src/lef:lef but can say //src/odb:lef
cc_library(
    name = "lef",
    srcs = [
        "lef/crypt.cpp",
        "lef/lef_keywords.cpp",
        "lef/lefiArray.cpp",
        "lef/lefiCrossTalk.cpp",
        "lef/lefiDebug.cpp",
        "lef/lefiEncryptInt.cpp",
        "lef/lefiLayer.cpp",
        "lef/lefiMacro.cpp",
        "lef/lefiMisc.cpp",
        "lef/lefiNonDefault.cpp",
        "lef/lefiProp.cpp",
        "lef/lefiPropType.cpp",
        "lef/lefiTBExt.cpp",
        "lef/lefiUnits.cpp",
        "lef/lefiVia.cpp",
        "lef/lefiViaRule.cpp",
        "lef/lefrCallbacks.cpp",
        "lef/lefrData.cpp",
        "lef/lefrReader.cpp",
        "lef/lefrSettings.cpp",
        "lef/lefwWriter.cpp",
        "lef/lefwWriterCalls.cpp",
    ],
    hdrs = LEF_HEADERS,
    features = [
        "-use_header_modules",
        "-layering_check",
    ],
    includes = ["lef"],
    deps = [
        ":lef_bison_lib",
        ":lef_parser_wrapper",
    ],
)

cc_library(
    name = "lefzlib",
    srcs = [
        "lefzlib/lefzlib.cpp",
    ],
    hdrs = [
        "lefzlib/lefzlib.hpp",
    ],
    includes = ["lefzlib"],
    deps = [
        ":lef",
        "@zlib",
    ],
)
