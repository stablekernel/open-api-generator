import 'package:open_api/open_api.dart';
import 'package:open_api/src/property.dart';

typedef String _DefinitionNamer(String longName);

class DartModel {
  DartModel(this.name, this.object, {this.namer}) {
    namer ??= (s) => s;
  }

  _DefinitionNamer namer;
  String name;
  APISchemaObject object;

  Uri get uri {
    return Uri.parse(name.split(".").join("/") + ".dart");
  }

  String get contents {
    if (object.properties != null) {
      StringBuffer buf = new StringBuffer();

      // Import any references...
      var imports = object.properties.values.map((so) {
        if (so.representation == APISchemaRepresentation.structure && so.referenceURI != null) {
          var replaced = so.referenceURI.replaceAll("#/", "").replaceAll(".", "/");
          return "import 'package:kubernetes/$replaced.dart';";
        } else if (so.items?.referenceURI != null && so.items.representation == APISchemaRepresentation.structure ) {
          var replaced = so.items.referenceURI.replaceAll("#/", "").replaceAll(".", "/");
          return "import 'package:kubernetes/$replaced.dart';";
        } else if (so.additionalProperties?.referenceURI != null && so.additionalProperties.representation == APISchemaRepresentation.structure ) {
          var replaced = so.additionalProperties.referenceURI.replaceAll("#/", "").replaceAll(".", "/");
          return "import 'package:kubernetes/$replaced.dart';";
        }
      }).where((s) => s != null);
      var importSet = new Set.from(imports);
      importSet.forEach((e) {
        buf.writeln(e);
      });

      var className = namer(name);
      buf.writeln("class $className {");

      // todo: make all required params final, require them as args to this constructor
      // Type()
      buf.writeln("  $className();");
      buf.writeln("");

      // Type.fromMap(Map values)
      buf.writeln("  $className.fromMap(Map<String, dynamic> values) {");
      object.properties.forEach((propName, nextObject) {
        decodeString(buf, propName, nextObject);
      });
      buf.writeln("  }");
      buf.writeln("");

      // Property definitions;
      object.properties.forEach((propName, nextObject) {
        buf.writeln("  ${typeName(nextObject)} ${symbolicate(propName)};");
      });
      buf.writeln("");

      // Map<String, dynamic> asMap()
      buf.writeln("  Map<String, dynamic> asMap() {");
      buf.writeln("    var output = <String, dynamic>{};");
      object.properties.forEach((propName, nextObject) {
        encodeString(buf, propName, nextObject);
      });
      buf.writeln("    return output;");
      buf.writeln("  }");

      buf.writeln("}");

      return buf.toString();
    }

    return null;
  }

  String encodeString(StringBuffer buffer, String propName, APISchemaObject object) {
    switch (object.representation) {
      case APISchemaRepresentation.unknownOrInvalid:
        break;

      case APISchemaRepresentation.object:
        buffer.writeln("    output[${symbolicateKey(propName)}] = ${symbolicate(propName)};");
        break;

      case APISchemaRepresentation.primitive:
        buffer.writeln("    output[${symbolicateKey(propName)}] = ${symbolicate(propName)};");
        break;

      case APISchemaRepresentation.structure:
        buffer.writeln("    output[${symbolicateKey(propName)}] = ${symbolicate(propName)}?.asMap();");
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          // Then it is a reference to some other type.
          var listFromMap = "${symbolicate(propName)}";
          var constructor = "m.asMap()";
          buffer.writeln("    output[${symbolicateKey(propName)}] = $listFromMap?.map((m) => $constructor)?.toList();");
        } else {
          // Otherwise, it is a list of primitives.
          buffer.writeln("    output[${symbolicateKey(propName)}] = ${symbolicate(propName)};");
        }
        break;
    }

    return "";
  }

  String decodeString(StringBuffer buffer, String propName, APISchemaObject object) {
    switch (object.representation) {
      case APISchemaRepresentation.unknownOrInvalid:
        break;

      case APISchemaRepresentation.object:
        buffer.writeln("    ${symbolicate(propName)} = values[${symbolicateKey(propName)}];");
        break;

      case APISchemaRepresentation.primitive:
        buffer.writeln("    ${symbolicate(propName)} = values[${symbolicateKey(propName)}];");
        break;

      case APISchemaRepresentation.structure:
        var type = typeName(object);
        buffer.writeln("    ${symbolicate(propName)} = new $type.fromMap(values[${symbolicateKey(propName)}]);");
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          var innerType = typeName(object.items);
          var listFromMap = "(values[${symbolicateKey(propName)}] as List<Map<String, dynamic>>)";
          var constructor = "new $innerType.fromMap(m)";
          buffer.writeln("    ${symbolicate(propName)} = $listFromMap?.map((m) => $constructor)?.toList();");
        } else {
          // Otherwise, it is a list of primitives.
          buffer.writeln("    ${symbolicate(propName)} = values[${symbolicateKey(propName)}];");
        }
        break;
    }

    return "";
  }

  String typeName(APISchemaObject object) {
    if (object == null) {
      return "dynamic";
    }

    switch (object.type) {
      case APIType.string:
        return "String";
      case APIType.integer:
        return "int";
      case APIType.number:
        return "num";
      case APIType.boolean:
        return "bool";
      case APIType.array:
        return "List<${typeName(object.items)}>";
      case APIType.file:
        return "dynamic";
      case APIType.object:
        return "Map<String, ${typeName(object.additionalProperties)}>";
    }

    if (object.referenceURI != null) {
      return namer(object.referenceURI);
    }

    return "dynamic";
  }

  String pathify(String name) {
    return name.toLowerCase().replaceAll("-", "_");
  }

  String fileName(String name) {
    return pathify(name) + ".dart";
  }

  static List<String> keywords = [
    "abstract", "deferred", "if", "super", "as", "do", "implements", "switch",
    "assert", "dynamic", "import", "sync", "async", "else", "in", "this",
    "enum", "is", "throw", "await", "export", "library", "true", "break",
    "external", "new", "try", "case", "extends", "null", "typedef",
    "catch", "factory", "operator", "var", "class", "false", "part", "void",
    "const", "final", "rethrow", "while", "continue", "finally", "return",
    "with", "covariant", "for", "set", "yield", "default", "get", "static"
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

    return name;
  }
}