// Copyright (c) 2017, joeconway. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:open_api/v2.dart';
import 'package:open_api_generator/open_api_generator.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group("Kubernetes spec", () {
    APIDocument doc;
    Map<String, dynamic> original;

    setUpAll(() {
      // Spec file is too large for pub, and no other way to remove from pub publish
      // than putting in .gitignore. Therefore, this file must be downloaded locally
      // to this path, from this path: https://github.com/kubernetes/kubernetes/blob/master/api/openapi-spec/swagger.json.
      var file = new File("test/specs/kubernetes.json");
      var contents = file.readAsStringSync();
      original = json.decode(contents);
      doc = new APIDocument.fromMap(original);
    });

    test("ok", () {
      var gen = new Generator("dart", doc, definitionNamer: (s) => s.split(".").last);
      var directory = new Directory("build/kubernetes_api_test");
      gen.writeToDirectory(directory);
      expect(directory.existsSync(), true);
    });
  });
}
