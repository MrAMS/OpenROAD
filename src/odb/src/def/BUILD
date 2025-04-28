# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025, The OpenROAD Authors

load("@rules_bison//bison:bison.bzl", "bison")

package(
    default_visibility = ["//:__subpackages__"],
    features = ["layering_check"],
)

# TODO: This can probably be broken into smaller, more specific parts.
# TODO: once we establish src/odb as package, make aliases so that we
#  don't need the awkward long path with double src
#  //src/odb/src/def:def but can say //src/odb:def
cc_library(
    name = "def",
    srcs = [
        "def/def_keywords.cpp",
        "def/def_parser.cpp",
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
    hdrs = [
        "def/def_parser.hpp",
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
    ],
    includes = ["def"],
)

genrule(
    name = "def_bison",
    srcs = ["def/def.y"],
    outs = [
        "def/def_parser.cpp",
        "def/def_parser.hpp",
    ],
    cmd = """
    M4=$(M4) $(BISON) \
      --defines=$(@D)/def/def_parser.hpp \
      --output-file=$(@D)/def/def_parser.cpp \
      --name-prefix=defyy $<
    """,
    toolchains = [
        "@rules_bison//bison:current_bison_toolchain",
        "@rules_m4//m4:current_m4_toolchain",
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
        "@zlib",
    ],
)
