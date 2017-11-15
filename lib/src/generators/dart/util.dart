const List<String> keywords = const [
  "abstract",
  "deferred",
  "if",
  "super",
  "as",
  "do",
  "implements",
  "switch",
  "assert",
  "dynamic",
  "import",
  "sync",
  "async",
  "else",
  "in",
  "this",
  "enum",
  "is",
  "throw",
  "await",
  "export",
  "library",
  "true",
  "break",
  "external",
  "new",
  "try",
  "case",
  "extends",
  "null",
  "typedef",
  "catch",
  "factory",
  "operator",
  "var",
  "class",
  "false",
  "part",
  "void",
  "const",
  "final",
  "rethrow",
  "while",
  "continue",
  "finally",
  "return",
  "with",
  "covariant",
  "for",
  "set",
  "yield",
  "default",
  "get",
  "static"
];

String symbolicateKey(String key) {
  if (key.contains(r"$")) {
    return "r'$key'";
  }

  return "'$key'";
}

String symbolicate(String name) {
  if (keywords.contains(name)) {
    name = "${name}_";
  }

  name = name
    .replaceAll(".", "")
    .replaceAll("{", "")
    .replaceAll("}", "");

  return name;
}

String pathify(String name) {
  return name.toLowerCase()
    .replaceAll("-", "_")
    .replaceAll("{", "_")
    .replaceAll("}", "_");
}

String typify(String name) {
  final leading = name.substring(0, 1).toUpperCase();
  final remainder = name.substring(1)
    .replaceAll(".", "");

  return "$leading$remainder";
}

