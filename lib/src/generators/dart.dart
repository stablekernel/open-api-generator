import 'dart:io';

import 'package:open_api/open_api.dart';
import 'package:open_api/src/property.dart';
import 'dart_model.dart';
import '../generator.dart';

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
  DartGenerator(this.document, this.namer, {this.apiName});

  String apiName;
  APIDocument document;
  _DefinitionNamer namer;

  void writeToDirectory(Directory dir) {
    dir.createSync();

    var pubspec = new File.fromUri(dir.uri.resolve("pubspec.yaml"));
    pubspec.writeAsStringSync("""
name: ${pathify(apiName ?? document.info.title)}
description: ${document.info.description ?? "An API"}
version: 0.0.1

environment:
  sdk: '>=1.20.1 <2.0.0'    
    """);

    var libDir = new Directory.fromUri(dir.uri.resolve("lib/"));
    libDir.createSync();

    var modelDir = libDir.uri.resolve("definitions/");
    var defs = document.definitions.keys.map((defName) => new DartModel(defName, document.definitions[defName], namer: namer));
    defs.forEach((dm) {
      var contents = dm.contents;
      if (contents == null) {
        return;
      }

      var uri = modelDir.resolveUri(dm.uri);
      var containingDirectoryPath = FileSystemEntity.parentOf(uri.path);
      var dir = new Directory(containingDirectoryPath);
      dir.createSync(recursive: true);

      var f = new File.fromUri(uri);
      f.writeAsStringSync(contents);
    });

  }

  Map<String, String> get fileSources {
    var output = <String, String>{};

//    var operations = document.paths.keys.map((path) {
//      return generatePathOperations(path, document.paths[path]);
//    }).toList();
//
//    print("$operations");

    return output;
  }

  String pathify(String name) {
    return name.toLowerCase().replaceAll("-", "_");
  }
  
  String fileName(String name) {
    return pathify(name) + ".dart";
  }

//  String generatePathOperations(String path, APIPath object) {
//    StringBuffer buf = new StringBuffer();
//
//    object.operations.forEach((httpMethod, operation) {
//      var successResponseKey = operation.responses.keys.firstWhere((k) => k.startsWith("2"), orElse: () => null);
//      var returnType = typeName(operation.responses[successResponseKey]?.schema);
//
//      var queryParameters = operation.parameters.where((p) => p.location == APIParameterLocation.query);
//      // url params for get, delete and head
//      var url = "\$scheme://\$host$path";
//
//      if (httpMethod.toLowerCase() == "get" ||
//          httpMethod.toLowerCase() == "delete" ||
//          httpMethod.toLowerCase() == "head") {}
//
//      buf.writeln("Future<Response<$returnType>> ${operation.id}() async {");
//      buf.writeln("  try {");
//      buf.writeln("    var resp = await $execute;");
//      buf.writeln("    if (resp.statusCode == $successResponseKey) {");
//      buf.writeln("      var object = $decode;");
//      buf.writeln("      return new Response<$returnType>(resp.statusCode, resp.headers, object);");
//      buf.writeln("    } else {");
//      buf.writeln("      return ");
//      buf.writeln("    }");
//      buf.writeln("  }");
//      buf.writeln("}");
//    });
//
//    return buf.toString();
//  }
}
