import 'package:open_api/v2.dart';
import 'package:open_api/src/v2/property.dart';
import 'package:open_api_generator/src/generators/dart/util.dart';

typedef String _DefinitionNamer(String longName);

class DartType {
  DartType(this.packageName, String fullDefinitionName, this.object, {this.namer}) {
    namer ??= (s) => s;
    uri = Uri.parse(fullDefinitionName.split(".").join("/") + ".dart");
    name = namer(fullDefinitionName);
  }

  String packageName;
  _DefinitionNamer namer;
  String name;
  APISchemaObject object;
  Uri uri;

  List<String> get requiredImports {
    return new Set<String>.of(object.properties.values.map((so) {
      if (so.referenceURI != null) {
        var replaced = so.referenceURI.toString().replaceAll("#/", "").replaceAll(".", "/");
        return "package:$packageName$replaced.dart";
      } else if (so.items?.referenceURI != null) {
        var replaced = so.items.referenceURI.toString().replaceAll("#/", "").replaceAll(".", "/");
        return "package:$packageName$replaced.dart";
      } else if (so.additionalProperties?.referenceURI != null) {
        var replaced = so.additionalProperties.referenceURI.toString().replaceAll("#/", "").replaceAll(".", "/");
        return "package:$packageName$replaced.dart";
      }

      return null;
    }).where((s) => s != null)).toList();
  }

  String get contents {
    if (object.properties == null) {
      return _typeAliasContents;
    }

    StringBuffer buf = new StringBuffer();

    requiredImports.forEach((path) {
      buf.writeln("import '$path';");
    });
    buf.writeln("import 'package:$packageName/base.dart';");
    buf.writeln("");

    buf.writeln("class $name extends Codable {");

    // Type()
    final argList = object.required?.map((p) => "this.${symbolicate(p)}")?.join(", ") ?? "";

    buf.writeln("  $name($argList);");
    buf.writeln("");
    buf.writeln("  $name.empty();");
    buf.writeln("");

    // void decode(Coder values)
    final assignments = object.properties.keys
        .map((k) => "    ${decodeString(k, object.properties[k])}")
        .where((s) => s != null)
        .join(";\n");

    buf.writeln("  @override");
    buf.writeln("  void decode(Coder decoder) {");
    buf.writeln(assignments + ";");
    buf.writeln("}");
    buf.writeln("");

    // Property definitions
    final fields = object.properties.keys.map((propName) {
      final type = typeName(object.properties[propName]);
//      final isRequired = object.required?.contains(propName) ?? false;
      final fieldName = symbolicate(propName);

      return "  $type $fieldName";
    });

    fields.forEach((def) {
      buf.writeln("$def;");
    });
    buf.writeln("");

    // void encode(Coder output)
    buf.writeln("  @override");
    buf.writeln("  void encode(Coder encoder) {");
    object.properties.forEach((propName, nextObject) {
      encodeString(buf, propName, nextObject);
    });
    buf.writeln("  }");

    buf.writeln("}");

    return buf.toString();
  }

  String encodeString(StringBuffer buffer, String propName, APISchemaObject object) {
    switch (object.representation) {
      case APISchemaRepresentation.unknownOrInvalid:
        break;

      case APISchemaRepresentation.object:
        if (object.referenceURI != null) {
          buffer.writeln("    encoder.encodeObject(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        } else {
          if (object.additionalProperties?.referenceURI != null) {
            buffer.writeln("    encoder.encodeObjectMap(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
          } else {
            buffer.writeln("    encoder.encode(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
          }
        }
        break;

      case APISchemaRepresentation.primitive:
        if (object.referenceURI != null) {
          buffer.writeln("    encoder.encodeObject(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        } else {
          buffer.writeln("    encoder.encode(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        }
        break;

      case APISchemaRepresentation.structure:
        buffer.writeln("    encoder.encodeObject(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          buffer.writeln("    encoder.encodeObjects(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        } else {
          // Otherwise, it is a list of primitives... probably.
          buffer.writeln("    encoder.encode(${symbolicateKey(propName)}, this.${symbolicate(propName)});");
        }
        break;
    }

    return "";
  }

  String decodeString(String propName, APISchemaObject object) {
    switch (object.representation) {
      case APISchemaRepresentation.unknownOrInvalid:
        break;

      case APISchemaRepresentation.object:
        if (object.referenceURI != null) {
          var type = typeName(object);
          return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)}, inflate: () => new $type.empty())";
        } else {
          if (object.additionalProperties?.referenceURI != null) {
            var type = typeName(object.additionalProperties);
            return "${symbolicate(propName)} = decoder.decodeObjectMap(${symbolicateKey(propName)}, () => new $type.empty())";
          }
          return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)})";
        }
        break;

      case APISchemaRepresentation.primitive:
        if (object.referenceURI != null) {
          var type = typeName(object);
          return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)}, inflate: () => new $type.empty())";
        } else {
          return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)})";
        }
        break;

      case APISchemaRepresentation.structure:
        var type = typeName(object);
        return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)}, inflate: () => new $type.empty())";
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          var innerType = typeName(object.items);
          var constructor = "new $innerType.empty()";
          var decode = "decoder.decodeObjects(${symbolicateKey(propName)}, () => $constructor)";

          return "${symbolicate(propName)} = $decode";
        } else {
          // Otherwise, it is a list of primitives.
          return "${symbolicate(propName)} = decoder.decode(${symbolicateKey(propName)})";
        }
        break;
    }

    return null;
  }

  String typeName(APISchemaObject object) {
    if (object == null) {
      return "dynamic";
    }

    if (object.referenceURI != null) {
      return namer(object.referenceURI.toString());
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

    return "dynamic";
  }

  String fileName(String name) {
    return pathify(name) + ".dart";
  }

  String get _typeAliasContents {
    return """
import 'package:$packageName/base.dart';

//todo: This type could not fully be resolved and may require additional editing.
class $name extends Codable {
  $name(this.value);
  $name.empty();
  
  dynamic value;

  @override
  void encode(Coder encoder) {
    encoder.primitiveValue = value;
  }

  @override
  void decode(Coder decoder) {
    value = decoder.primitiveValue;
  }
}
      """;
    }
}
