import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:open_api/v2.dart';
import 'package:open_api_generator/open_api_generator.dart';

Future main(List<String> args) async {
  var p = args.first;
  var f = new File(p);
  var map = json.decode(f.readAsStringSync());
  var doc = new APIDocument.fromMap(map);
  var gen = new Generator("dart", doc, definitionNamer: (s) => s.split(".").last);

  var outputDir = new Directory("output");
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }
  gen.writeToDirectory(outputDir);
}