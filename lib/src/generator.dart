import 'dart:io';

import 'package:open_api/v2.dart';
import 'package:open_api_generator/src/generators/dart/generator.dart';

abstract class Generator {
  factory Generator(String language, APIDocument document, {String definitionNamer(String longName)}) {
    if (language == "dart") {
      return new DartGenerator(document, definitionNamer);
    }

    throw new Exception("Unsupported language '$language'");
  }

  APIDocument get document;

  void writeToDirectory(Directory dir);
}