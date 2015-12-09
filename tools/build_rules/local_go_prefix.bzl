
def _local_go_prefix_impl(ctx):
  """local_go_prefix_impl provides the go prefix to use as a transitive info provider."""
  return struct(go_prefix = ctx.attr.prefix)

def _local_go_prefix(ctx):
  """slash terminated go-prefix"""
  prefix = ctx.attr.go_prefix.go_prefix
  if not prefix.endswith("/"):
    prefix = prefix + "/"
  return prefix

_local_go_prefix_rule = rule(
    _local_go_prefix_impl,
    attrs = {
        "prefix": attr.string(mandatory = True),
    },
)

def local_go_prefix(prefix):
  """local_go_prefix sets the Go import name to be used for this workspace."""
  _local_go_prefix_rule(name = "local_go_prefix",
    prefix = prefix,
    visibility = ["//visibility:public" ]
  )
