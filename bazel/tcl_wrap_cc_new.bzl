# Copyright 2010-2025 Google LLC
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Build definitions for SWIG Tcl.

Adapted from:
https://github.com/google/or-tools/blob/9b77015d9d7162b560b9e772c06ff262d2780844/bazel/swig_java.bzl
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _tcl_wrap_cc_impl(ctx):
    src = ctx.file.src
    outfile = ctx.outputs.outfile \
        if ctx.outputs.outfile != "" \
           else ctx.label.name + ".cc"

    header_sets = []  # depsets of Files
    include_path_sets = []  # depsets of strings

    # Include headers from deps.
    for target in ctx.attr.deps:
        cc_context = target[CcInfo].compilation_context
        header_sets.append(cc_context.headers)
        include_path_sets.append(cc_context.includes)

        # Include workspace root in include path for when target is defined in an
        # external workspace.
        if target.label.workspace_root:
            include_path_sets.append(depset([target.label.workspace_root]))

    swig_args = ctx.actions.args()
    swig_args.add("-c++")
    swig_args.add("-tcl8")
    if ctx.attr.swig_opt:
        swig_args.add(ctx.attr.swig_opt)
    swig_args.add("-o", outfile)
    if ctx.attr.module:
        swig_args.add("-module", ctx.attr.module)
    if ctx.attr.namespace_prefix:
        swig_args.add("-namespace")
        swig_args.add("-prefix")
        swig_args.add(ctx.attr.namespace_prefix)
    for include_path in depset(transitive = include_path_sets).to_list():
        swig_args.add("-I" + include_path)
    swig_args.add(src.path)
    generated_c_files = [outfile]

    # Add swig LIB files.
    swig_lib = {"SWIG_LIB": paths.dirname(ctx.files._swig_lib[0].path)}
    ctx.actions.run(
        outputs = generated_c_files,
        inputs = depset([src] + ctx.files.swig_includes + ctx.files._swig_lib, transitive = header_sets),
        env = swig_lib,
        executable = ctx.executable._swig,
        arguments = [swig_args],
        mnemonic = "SwigCompile",
    )

_tcl_wrap_cc = rule(
    doc = """Wraps C++ in Tcl using Swig.""",
    implementation = _tcl_wrap_cc_impl,
    attrs = {
        "src": attr.label(
            doc = "Single swig source file.",
            allow_single_file = True,
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "C++ dependencies.",
            providers = [CcInfo],
        ),
        "module": attr.string(doc = "Optional Swig module name."),
        "outfile": attr.output(
            doc = "Generated C++ output file.",
            mandatory = True,
        ),
        "namespace_prefix": attr.string(
            mandatory = False,
            default = "",
            doc = "Swig namespace prefix.",
        ),
        "_swig": attr.label(
            default = Label("@swig//:swig"),
            executable = True,
            cfg = "exec",
        ),
        "_swig_lib": attr.label(
            default = Label("@swig//:lib_tcl"),
        ),
        "swig_includes": attr.label_list(
            doc = "SWIG includes.",
            allow_files = True,
        ),
        "swig_opt": attr.string(doc = "Optional Swig opt."),
    },
)

def tcl_wrap_cc(
    name,
    src,
    deps = [],
    swig_opt = "",
    swig_includes = [],
    module = None,
    namespace_prefix = "",
    visibility = None,
    **kwargs
):
    """Wraps C++ in Tcl using Swig.

    Args:
        name: target name.
        src: single .i source file.
        deps: C++ deps.
        module: optional name of Swig module.
        swig_opt: optional defines passed to the swig command.
        swig_includes: list of swig files included by the current swig file.
        visibility: global visibility of the rule.
        **kwargs: extra generic arguments, usually passed to sub-rules.

    Generated targets:
        lib{name}_cc: cc_library
    """
    outfile = name + ".cc"
    _tcl_wrap_cc(
        name = name,
        src = src,
        outfile = outfile,
        deps = deps,
        swig_opt = swig_opt,
        module = module,
        namespace_prefix = namespace_prefix,
        swig_includes = swig_includes,
        **kwargs
    )

def tcl_wrap_cc_library(
    name,
    src,
    deps = [],
    swig_opt = "",
    swig_includes = [],
    module = None,
    namespace_prefix = "",
    visibility = None,
    **kwargs
):
    """Wraps C++ in Tcl using Swig.

    Args:
        name: target name.
        src: single .i source file.
        deps: C++ deps.
        module: optional name of Swig module.
        swig_opt: optional defines passed to the swig command.
        swig_includes: list of swig files included by the current swig file.
        visibility: global visibility of the rule.
        **kwargs: extra generic arguments, usually passed to sub-rules.

    Generated targets:
        lib{name}_cc: cc_library
    """

    wrapper_name = "_" + name + "_wrapper"
    outfile = name + ".cc"

    _tcl_wrap_cc(
        name = wrapper_name,
        src = src,
        outfile = outfile,
        deps = deps,
        swig_opt = swig_opt,
        module = module,
        namespace_prefix = namespace_prefix,
        swig_includes = swig_includes,
        visibility = ["//visibility:private"],
        **kwargs
    )

    native.cc_library(
        name = name,
        srcs = [outfile],
        deps = deps + ["@tk_tcl//:tcl"],
        alwayslink = True,
        visibility = visibility,
        **kwargs
    )
