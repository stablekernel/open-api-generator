import 'dart:collection';
import 'dart:convert';

abstract class Codable {
  void decode(Coder object);

  void encode(Coder object);

  Map<String, dynamic> asMap() {
    var json = new Coder();
    encode(json);
    return json.asMap();
  }
}

class JSONCoder<T extends Codable> {
  JSONCoder(String json, T inflate()) {
    final deserialized = JSON.decode(json, reviver: (_, value) {
      if (value is Map) {
        return new Coder._(value);
      }
      return value;
    });

    if (deserialized is List) {
      objectOrObjects = deserialized.map((m) {
        final coder = new Coder._(m);
        final creator = inflate()
          ..decode(coder);
        return creator;
      }).toList();
    } else if (deserialized is Map) {
      final coder = new Coder._(deserialized);
      objectOrObjects = inflate()
        ..decode(coder);
    }
  }

  static String encodeRootObject<T extends Codable>(T root) {
    return JSON.encode(root.asMap());
  }

  static String encodeObjects<T extends Codable>(List<T> objects) {
    return JSON.encode(objects.map((obj) => obj.asMap()).toList());
  }

  dynamic objectOrObjects;

  T get root {
    return objectOrObjects as T;
  }

  List<T> get objects {
    return objectOrObjects as List<T>;
  }
}

class Coder extends Object with MapMixin<String, dynamic> {
  Coder() : this._({});

  Coder._(this._map);

  Coder.primitive(this.primitiveValue);

  bool get hasPrimitiveValue => primitiveValue != null;
  dynamic primitiveValue;
  Map<String, dynamic> _map;

  operator []=(String key, dynamic value) {
    _map[key] = value;
  }

  dynamic operator [](Object key) {
    return _getValue(key);
  }

  Iterable<String> get keys {
    return _map.keys;
  }

  void clear() => _map.clear();

  dynamic remove(Object key) => _map.remove(key);

  dynamic _getValue(String key) {
    if (_map.containsKey(key)) {
      return _map[key];
    }

    return null;
  }

  /* decode */

  T _decodedObject<T extends Codable>(dynamic values, T inflate()) {
    Coder object;
    if (values is Coder) {
      object = values;
    } else {
      object = new Coder.primitive(values);
    }

    return inflate()..decode(object);
  }

  T decode<T extends Codable>(String key, {T inflate()}) {
    var v = _getValue(key);
    if (v == null) {
      return null;
    }

    if (inflate != null) {
      return _decodedObject(v, inflate);
    }

    return v;
  }

  List<T> decodeObjects<T extends Codable>(String key, T inflate()) {
    var contents = _getValue(key);
    if (contents == null) {
      return null;
    }

    return contents.map((v) => _decodedObject(v, inflate)).toList();
  }

  Map<String, T> decodeObjectMap<T extends Codable>(String key, T inflate()) {
    Map<String, dynamic> v = _getValue(key);
    if (v == null) {
      return null;
    }

    return new Map.fromIterable(v.keys,
      key: (k) => k, value: (k) => _decodedObject(v[k], inflate));
  }

  /* encode */

  dynamic _encodedObject(Codable object) {
    var json = new Coder();
    object.encode(json);
    if (json.hasPrimitiveValue) {
      return json.primitiveValue;
    }
    return json.asMap();
  }

  void encode<T>(String key, T value) {
    if (value == null) {
      return;
    }

    _map[key] = value;
  }

  void encodeObject(String key, Codable value) {
    if (value == null) {
      return;
    }

    _map[key] = _encodedObject(value);
  }

  void encodeObjects(String key, List<Codable> value) {
    if (value == null) {
      return;
    }

    _map[key] = value.map((v) => _encodedObject(v)).toList();
  }

  void encodeObjectMap<T extends Codable>(String key, Map<String, T> value) {
    if (value == null) {
      return;
    }

    var object = new Coder();
    value.forEach((k, v) {
      object.encodeObject(k, v);
    });

    _map[key] = object.asMap();
  }

  Map<String, dynamic> asMap() {
    return _map;
  }
}
