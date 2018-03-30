import 'dart:io';

import 'package:open_api/v2.dart';
import 'package:open_api_generator/src/generators/dart/type.dart';
import 'package:open_api_generator/src/generators/dart/operation.dart';
import '../../generator.dart';
import 'package:open_api_generator/src/generators/dart/util.dart';

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
  DartGenerator(this.document, _DefinitionNamer namer) {
    document.definitions.forEach((defName, definition) {
      definitions[defName] = new DartType(document.info.title.toLowerCase(), defName, definition, namer: namer);
    });


//    final ops = new DartOperationBuilder(document.info.title, document.paths, definitions);
//    operations.addAll(ops.builders);
  }

  final APIDocument document;
  final Map<String, DartType> definitions = <String, DartType>{};
  final List<DartBuilder> operations = <DartBuilder>[];

  void writeToDirectory(Directory dir) {
    final libDir = new Directory.fromUri(dir.uri.resolve("lib/"));
    writePubspec(dir.uri);
    writeSharedSource(libDir.uri);
    writeDefinitions(libDir.uri);
//    writeOperationBuilders(libDir.uri);
  }

  void writeOperationBuilders(Uri parentDirectory) {
    final opDir = new Directory.fromUri(parentDirectory.resolve("operations/"));

    operations.forEach((op) {
      final uri = opDir.uri.resolveUri(op.uri);
      write(uri, op.contents);
    });
  }

  void writeDefinitions(Uri parentDirectory) {
    final modelDir = parentDirectory.resolve("definitions/");

    definitions.values.forEach((dm) {
      var uri = modelDir.resolveUri(dm.uri);
      write(uri, dm.contents);
    });
  }

  void writeSharedSource(Uri parentDirectory) {
    final baseTypeFile = new File("lib/src/generators/dart/base_type.dart");

    write(parentDirectory.resolve("base.dart"), baseTypeFile.readAsStringSync());
  }

  void writePubspec(Uri parentDirectory) {
    write(parentDirectory.resolve("pubspec.yaml"),
"""
name: ${pathify(document.info.title)}
description: ${document.info.description ?? "An API"}
version: 0.0.1

environment:
  sdk: '>=1.20.1 <2.0.0'    
""");
  }
  
  String fileName(String name) {
    return pathify(name) + ".dart";
  }

  void write(Uri uri, String contents) {
    if (contents == null || uri == null) {
      return;
    }
    var containingDirectoryPath = FileSystemEntity.parentOf(uri.path);
    var dir = new Directory(containingDirectoryPath);
    dir.createSync(recursive: true);

    var f = new File.fromUri(uri);
    f.writeAsStringSync(contents);
  }
}

