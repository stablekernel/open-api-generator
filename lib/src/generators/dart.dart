import '../generator.dart';
import 'package:open_api/open_api.dart';

/*
class UserAgentClient extends http.BaseClient {
  final String userAgent;
  final http.Client _inner;

  UserAgentClient(this.userAgent, this._inner);

  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['user-agent'] = userAgent;
    return _inner.send(request);
  }
}
 */

typedef String _DefinitionNamer(String longName);

class DartGenerator implements Generator {
  DartGenerator(this.document, this.namer);

  APIDocument document;
  _DefinitionNamer namer;

  Map<String, String> get fileSources {
    // generate all base models
    var definitions = document.definitions.keys
        .map((name) {
      return generateDefinition(name, document.definitions[name]);
    })
        .where((def) => def != null)
        .toList();

//    print("${definitions}");

    var operations = document.paths.keys.map((path) {
      return generatePathOperations(path, document.paths[path]);
    }).toList();

    print("$operations");

    return {};
  }

  String generatePathOperations(String path, APIPath object) {
    StringBuffer buf = new StringBuffer();

    object.operations.forEach((httpMethod, operation) {
      var successResponseKey = operation.responses.keys.firstWhere((k) => k.startsWith("2"), orElse: () => null);
      var returnType = typeName(operation.responses[successResponseKey]?.schema);

      var queryParameters = operation.parameters.where((p) => p.location == APIParameterLocation.query);
      // url params for get, delete and head
      var url = "\$scheme://\$host$path";

      if (httpMethod.toLowerCase() == "get" || httpMethod.toLowerCase() == "delete" || httpMethod.toLowerCase() == "head") {

      }

      buf.writeln("Future<Response<$returnType>> ${operation.id}() async {");
      buf.writeln("  try {");
      buf.writeln("    var resp = await $execute;");
      buf.writeln("    if (resp.statusCode == $successResponseKey) {");
      buf.writeln("      var object = $decode;");
      buf.writeln("      return new Response<$returnType>(resp.statusCode, resp.headers, object);");
      buf.writeln("    } else {");
      buf.writeln("      return ");
      buf.writeln("    }");
      buf.writeln("  }");
      buf.writeln("}");
    });

    return buf.toString();
  }

  String generateDefinition(String name, APISchemaObject object) {
    if (object.properties != null) {
      StringBuffer buf = new StringBuffer();

      var className = namer(name);

      buf.writeln("class $className {");

      // If items is a ref, then it has a name. if it is an array, then nest one deeper.
      // if it has props/addlProps, then it is a map. Otherwise, it is its type

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
        buf.writeln("  ${typeName(nextObject)} $propName;");
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
        buffer.writeln("    values['$propName'] = $propName;");
        break;

      case APISchemaRepresentation.primitive:
        buffer.writeln("    values['$propName'] = $propName;");
        break;

      case APISchemaRepresentation.structure:
        buffer.writeln("    output['$propName'] = $propName?.asMap();");
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          // Then it is a reference to some other type.
          var listFromMap = "$propName";
          var constructor = "m.asMap()";
          buffer.writeln("    output['$propName'] = $listFromMap?.map((m) => $constructor)?.toList();");
        } else {
          // Otherwise, it is a list of primitives.
          buffer.writeln("    values['$propName'] = $propName;");
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
        buffer.writeln("    $propName = values['$propName'];");
        break;

      case APISchemaRepresentation.primitive:
        buffer.writeln("    $propName = values['$propName'];");
        break;

      case APISchemaRepresentation.structure:
        var type = typeName(object);
        buffer.writeln("    $propName = new $type.fromMap(values['$propName']);");
        break;

      case APISchemaRepresentation.array:
        if (object.items?.representation == APISchemaRepresentation.structure) {
          var innerType = typeName(object.items);
          var listFromMap = "(values['$propName'] as List<Map<String, dynamic>>)";
          var constructor = "new $innerType.fromMap(m)";
          buffer.writeln("    $propName = $listFromMap?.map((m) => $constructor)?.toList();");
        } else {
          // Otherwise, it is a list of primitives.
          buffer.writeln("    $propName = values['$propName'];");
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
}
