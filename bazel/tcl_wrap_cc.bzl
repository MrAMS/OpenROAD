# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025-2025, The OpenROAD Authors

"""A TCL SWIG wrapping rule for google3.

These rules generate a C++ src file that is expected to be used as srcs in
cc_library or cc_binary rules. See below for expected usage.

cc_library(srcs=[":tcl_foo"])
tcl_wrap_cc(name = "tcl_foo", srcs=["exception.i"],...)
"""
TclSwigInfo = provider(
    "TclSwigInfo for taking dependencies on other swig info rules",
    fields = [
        "transitive_srcs",
        "includes",
        "swig_options",
    ],
)

def _get_transitive_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[TclSwigInfo].transitive_srcs for dep in deps],
    )

def _get_transitive_includes(local_includes, deps):
    return depset(
        local_includes,
        transitive = [dep[TclSwigInfo].includes for dep in deps],
    )

def _get_transitive_options(options, deps):
    return depset(
        options,
        transitive = [dep[TclSwigInfo].swig_options for dep in deps],
    )

def _tcl_wrap_cc_impl(ctx):
    """Generates a single C++ file from the provided srcs in a DefaultInfo.
    """
    if len(ctx.files.srcs) > 1 and not ctx.attr.root_swig_src:
        fail("If multiple src files are provided, root_swig_src must be specified.")

    root_file = ctx.file.root_swig_src or ctx.files.srcs[0]

    outfile_name = ctx.attr.out or (ctx.attr.name + ".cc")
    output_file = ctx.actions.declare_file(outfile_name)

    # Get the directory containing the root file
    # For root_file.path like "external/repo/src/dbSta/src/dbSta.i"
    # We want to get "external/repo/src/dbSta/src"
    root_file_dir = root_file.dirname

    # Calculate workspace prefix from root file path
    # The workspace prefix is everything before the package path
    # For external repos: "external/repo/"
    # For main repo: ""
    workspace_prefix = ""
    if ctx.label.package:
        # Remove package path from root_file_dir to get workspace prefix
        # root_file_dir might be like "external/repo/src/dbSta/src"
        # and package is "src/dbSta"
        # We need to find where package starts in the path
        package_parts = ctx.label.package.split("/")
        dir_parts = root_file_dir.split("/")

        # Find where package starts in the directory path
        for i in range(len(dir_parts)):
            if i + len(package_parts) <= len(dir_parts):
                if dir_parts[i:i+len(package_parts)] == package_parts:
                    # Found the package location
                    workspace_prefix = "/".join(dir_parts[:i])
                    if workspace_prefix:
                        workspace_prefix += "/"
                    break

    # Convert relative includes to absolute paths from workspace root
    absolute_includes = []
    for include in ctx.attr.swig_includes:
        # Normalize the path by resolving ../ and ./
        if ctx.label.package:
            full_path = ctx.label.package + "/" + include
        else:
            full_path = include

        # Normalize the path (remove ../ and ./)
        parts = full_path.split("/")
        normalized = []
        for part in parts:
            if part == "..":
                if normalized:
                    normalized.pop()
            elif part and part != ".":
                normalized.append(part)

        normalized_path = "/".join(normalized)
        absolute_includes.append(workspace_prefix + normalized_path)

    src_inputs = _get_transitive_srcs(ctx.files.srcs + ctx.files.root_swig_src, ctx.attr.deps)
    includes_paths = _get_transitive_includes(
        absolute_includes,
        ctx.attr.deps,
    )
    swig_options = _get_transitive_options(ctx.attr.swig_options, ctx.attr.deps)

    # Add swig lib files to inputs
    swig_lib_files = ctx.attr._swig_lib_tcl.files
    all_inputs = depset(transitive = [src_inputs, swig_lib_files])

    args = ctx.actions.args()
    args.add("-tcl8")
    args.add("-c++")
    if ctx.attr.module:
        args.add("-module")
        args.add(ctx.attr.module)
    if ctx.attr.namespace_prefix:
        args.add("-namespace")
        args.add("-prefix")
        args.add(ctx.attr.namespace_prefix)
    args.add_all(swig_options.to_list())
    args.add_all(includes_paths.to_list(), format_each = "-I%s")

    # Determine SWIG_LIB path for swig library files
    # Swig lib files are in external/swig+/Lib/
    swig_lib_path = None
    if swig_lib_files:
        lib_file = swig_lib_files.to_list()[0]
        # Get the Lib directory path (e.g., external/swig+/Lib)
        lib_path = lib_file.path
        if "/Lib/" in lib_path:
            swig_lib_path = lib_path.split("/Lib/")[0] + "/Lib"
        elif lib_path.endswith("/Lib"):
            swig_lib_path = lib_path
        else:
            swig_lib_path = lib_file.dirname

    # Get swig executable
    swig_exe = [file for file in ctx.files._swig if file.basename == "swig"][0]

    args.add("-o")
    args.add(output_file.path)
    args.add(root_file.path)

    # Set SWIG_LIB environment variable
    env = {}
    if swig_lib_path:
        env["SWIG_LIB"] = swig_lib_path

    ctx.actions.run(
        outputs = [output_file],
        inputs = all_inputs,
        arguments = [args],
        tools = ctx.files._swig,
        executable = swig_exe,
        env = env,
    )

    output_files = [output_file]

    if ctx.attr.runtime_header:
        runtime_header = ctx.actions.declare_file(ctx.attr.runtime_header)
        runtime_args = ctx.actions.args()
        runtime_args.add("-tcl8")
        runtime_args.add("-external-runtime")
        runtime_args.add(runtime_header)
        ctx.actions.run(
            outputs = [runtime_header],
            inputs = [],
            arguments = [runtime_args],
            tools = [ctx.attr._swig.files_to_run],
            executable = ([file for file in ctx.files._swig if file.basename == "swig"][0]),
            toolchain = None,
            env = env,
        )
        output_files.append(runtime_header)

    return [
        DefaultInfo(files = depset(output_files)),
        TclSwigInfo(
            transitive_srcs = src_inputs,
            includes = includes_paths,
            swig_options = swig_options,
        ),
    ]

tcl_wrap_cc = rule(
    implementation = _tcl_wrap_cc_impl,
    attrs = {
        "deps": attr.label_list(
            allow_empty = True,
            doc = "tcl_wrap_cc dependencies",
            providers = [TclSwigInfo],
        ),
        "module": attr.string(
            mandatory = False,
            default = "",
            doc = "swig module",
        ),
        "namespace_prefix": attr.string(
            mandatory = False,
            default = "",
            doc = "swig namespace prefix",
        ),
        "out": attr.string(
            doc = "The name of the C++ source file generated by these rules. If not set, defaults to '<name>.cc'.",
        ),
        "root_swig_src": attr.label(
            allow_single_file = [".swig", ".i"],
            doc = """If more than one swig file is included in this rule.
            The root file must be explicitly provided. This is the file which will be passed to
            swig for generation.""",
        ),
        "runtime_header": attr.string(),
        "srcs": attr.label_list(
            allow_empty = False,
            allow_files = [".i", ".swig", ".h", ".hpp", ".hh"],
            doc = "Swig files that generate C++ files",
        ),
        "swig_includes": attr.string_list(
            doc = "List of directories relative to the BUILD file to append as -I flags to SWIG",
        ),
        "swig_options": attr.string_list(
            doc = "args to pass directly to the swig binary",
        ),
        "_swig": attr.label(
            default = "@swig//:swig",
            allow_files = True,
            cfg = "exec",
        ),
        "_swig_lib_tcl": attr.label(
            default = "@swig//:lib_tcl",
            allow_files = True,
            cfg = "exec",
        ),
    },
)
