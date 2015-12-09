load("/tools/build_rules/go/def", "go_repositories")

go_repositories()

git_repository(
  name = "protobuf",
  remote = "https://github.com/google/protobuf",
  commit = "b1b9c25",
)

bind(
  name = "protoc",
  actual = "@protobuf//:protoc"
)

new_git_repository(
  name = "go-protobuf",
  remote = "https://github.com/golang/protobuf",
  commit = "68415e7",
  build_file = "tools/build_rules/BUILD.go-protobuf",
)
