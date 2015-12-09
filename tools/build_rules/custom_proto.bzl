# Custom bazel rules for protobuf and grpc, until we get official ones.
# Others worth looking at:
#   https://github.com/mzhaom/trunk/blob/master/third_party/grpc/grpc_proto.bzl
#   https://github.com/google/protobuf/blob/master/protobuf.bzl
#   https://github.com/google/kythe/blob/master/tools/build_rules/proto.bzl

load("/tools/build_rules/go/def", "go_library")

def _GenDir(ctx):
  if not ctx.attr.includes:
    return ""
  if not ctx.attr.includes[0]:
    return ctx.label.package
  if not ctx.label.package:
    return ctx.attr.includes[0]
  return ctx.label.package + '/' + ctx.attr.includes[0]

def _proto_gen_impl(ctx):
  """General implementation for generating protos"""
  srcs = ctx.files.srcs
  deps = []
  deps += ctx.files.srcs
  gen_dir = _GenDir(ctx)
  if gen_dir:
    import_flags = ["-I" + gen_dir]
  else:
    import_flags = ["-I."]

  for dep in ctx.attr.deps:
    import_flags += dep.proto.import_flags
    deps += dep.proto.deps

  args = []
  if ctx.attr.gen_cc:
    args += ["--cpp_out=" + ctx.var["GENDIR"] + "/" + gen_dir]
  if ctx.attr.gen_go:
    args += ["--go_out=" + ctx.var["GENDIR"] + "/" + gen_dir]
  if ctx.attr.gen_py:
    args += ["--python_out=" + ctx.var["GENDIR"] + "/" + gen_dir]

  if args:
    ctx.action(
      inputs=srcs + deps,
      outputs=ctx.outputs.outs,
      arguments=args + import_flags + [s.path for s in srcs],
      executable=ctx.executable.protoc,
    )

  return struct(
    proto=struct(
      srcs=srcs,
      import_flags=import_flags,
      deps=deps,
    ),
  )

_proto_gen = rule(
  attrs = {
    "srcs": attr.label_list(allow_files = True),
    "deps": attr.label_list(providers = ["proto"]),
    "includes": attr.string_list(),
    "protoc": attr.label(
      cfg = HOST_CFG,
      executable = True,
      single_file = True,
      mandatory = True,
    ),
    "gen_cc": attr.bool(),
    "gen_go": attr.bool(),
    "gen_py": attr.bool(),
    "outs": attr.output_list(),
  },
  output_to_genfiles = True,
  implementation = _proto_gen_impl,
)

def _GoOuts(srcs):
  return [s[:-len(".proto")] +  ".pb.go" for s in srcs]

def go_proto_library(name,
                    srcs=[],
                    deps=[],
                    go_libs=[],
                    include=None,
                    protoc="//external:protoc",
                    **kargs):
  """Bazel rule to create a Go protobuf library from proto source files
  Args:
    name: the name of the go_proto_library.
    srcs: the .proto files of the go_proto_library.
    deps: a list of dependency labels; must be go_proto_library.
    go_libs: a list of other go_library targets depended on by the generated
        go_library.
    include: a string indicating the include path of the .proto files.
    protoc: the label of the protocol compiler to generate the sources.
    **kargs: other keyword arguments that are passed to go_library.
  """
  includes = []
  if include != None:
    includes = [include]

  outs = _GoOuts(srcs)
  _proto_gen(
    name=name + "_genproto",
    srcs=srcs,
    deps=[s + "_genproto" for s in deps],
    includes=includes,
    protoc=protoc,
    gen_go=1,
    outs=outs,
    visibility=["//visibility:public"],
  )

  go_library(
    name=name,
    srcs=outs,
    deps=go_libs + deps,
    **kargs)
