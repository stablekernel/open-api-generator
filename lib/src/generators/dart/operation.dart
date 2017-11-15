import 'package:open_api/open_api.dart';
import 'package:open_api/src/property.dart';
import 'package:open_api_generator/src/generators/dart/util.dart';
import 'type.dart';

class DartOperationBuilder {
  DartOperationBuilder(String packageName, Map<String, APIPath> paths, Map<String, DartType> definitions) {
    _root = new DartBuilder(packageName, paths, definitions);
  }

  DartBuilder _root;

  List<DartBuilder> get builders {
    return _root.flattened;
  }
}

class DartBuilder {
  DartBuilder(this.packageName, Map<String, APIPath> paths, Map<String, DartType> definitions, {this.path: const []}) {
    // Find all operation methods
    // - If a path terminates here, i.e. has no more segments
    // - If a subpath contains exactly one more element that is a path variable.
    // Find all builders
    // - Any paths that have more segments than terminate at this node, unless the subpath terminates at the next segment with a path variable.
    // - If a subpath's next segment is a path variable that also has subpaths, then we add
    //   that node's builders to this node and add a path variable to all operation methods in child nodes in that lineage.

    // The keys in [paths] can have trailing and leading we don't care about. We create Uris
    // to make them easier to work with, and [pathMap] allows us to get the original key
    // back from its Uri.
    final Map<Uri, String> pathMap = paths.keys.fold({}, (prev, elem) {
      prev[new Uri(path: elem)] = elem;
      return prev;
    });

    // We collapse each path so that paths that share an ancestor segment are grouped together into the same builder.
    // These matching paths are in childKeys. We get the distinct set of all shared ancestry paths in rootPaths.
    final pathNames = pathMap.keys.toList();
    final childKeys = pathNames.where((k) => k.pathSegments.length != 0).toList();
    final rootPaths = new Set<String>.from(childKeys.map((k) => k.pathSegments.first));

    // If we have operations for the path that terminates at this node, we need to add operations
    // for that path to the builder created by this node.
    final terminated = pathNames.firstWhere((p) => p.pathSegments.length == 0, orElse: () => null);
    if (terminated != null) {
      final ref = paths[""];
      operations.addAll(ref.operations.keys.map((method) => new DartOperationMethod(method, ref.operations[method])));
    }

    // For every root from this node, we find each path that shares the same root.
    // These paths are added as children of this node.
    for (var root in rootPaths) {
      var pathsWithThisRoot = childKeys.where((p) {
        return p.pathSegments.first == root;
      });

      var childPaths = pathsWithThisRoot.fold(<String, APIPath>{}, (prev, element) {
        final segments = new List.from(element.pathSegments);
        segments.remove(root);

        prev[segments.join("/")] = paths[pathMap[element]];
        return prev;
      });

      children[root] = new DartBuilder(packageName, childPaths, definitions, path: [path, [root]].expand((p) => p).toList());
    }
  }

  List<DartOperationMethod> operations = [];
  String packageName;
  List<String> path;
  APIPath reference;
  Map<String, DartBuilder> children = <String, DartBuilder>{};
  bool get hasSubOperations => children.length > 0;
  bool get hasTerminatingPathVariable => path.last.startsWith("{") && path.last.endsWith("}");

  List<DartBuilder> get flattened {
    var nodes = <DartBuilder>[];

    if (path.isNotEmpty && !hasTerminatingPathVariable) {
      nodes.add(this);
    }

    nodes.addAll(children.values.expand((t) => t.flattened));

    return nodes;
  }

  Uri get uri {
    return Uri.parse(path.map((seg) => pathify(seg)).join("/") + ".dart");
  }

  String get contents {
    var buf = new StringBuffer();

    buf.writeln("import 'dart:async';");
    children.forEach((k, v) {
      if (v.path.isNotEmpty && !v.hasTerminatingPathVariable) {
        buf.writeln("import 'package:kubernetes/operations/${v.uri.path}';");
      }

    });
    buf.writeln("");
    buf.writeln("class ${typify(path.last)}Builder {");

    children.forEach((childName, child) {
      if (!child.hasTerminatingPathVariable) {
        final type = "${typify(child.path.last)}Builder";
        buf.writeln("\t$type ${symbolicate(childName)};");
      }
    });

    buf.writeln("");

    if (reference != null) {
      reference.operations.forEach((opKey, op) {
        buf.writeln("\tFuture<${operationReturnType(op)}> ${op.id}() async {}");
      });
    }

    buf.writeln("");

    children.forEach((childName, child) {
      if (child.hasTerminatingPathVariable) {
        if (child.reference != null) {
          child.reference.operations.forEach((opKey, op) {
            buf.writeln("\tFuture ${op.id}(String ${symbolicate(childName)}) async {}");
          });
        }
      }
    });

    buf.writeln("}");

    return buf.toString();
  }

  String operationReturnType(APIOperation operation) {
    var successResponseKeys = operation.responses.keys.where((k) => k.startsWith("2")).toList();
    successResponseKeys.sort((a, b) => a.compareTo(b));
    if (successResponseKeys.length == 0) {
      return "Null";
    }

    var def = operation.responses[successResponseKeys.first];
    if (def.schema.referenceURI != null) {
      return namer(def.schema.referenceURI);
    }

    return "";
  }

  String toString({int depth: 0}) {
    var buf = new StringBuffer();
    for (var i = 0; i < depth; i ++) {
      buf.write("\t");
    }
    buf.writeln("${path.join("/")} -> $reference");
    for (var p in children.keys) {
      buf.write(children[p].toString(depth: depth + 1));
    }

    return buf.toString();
  }
}


class DartOperationMethod {
  DartOperationMethod(String method, APIOperation operation) {

  }
}
