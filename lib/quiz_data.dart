import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class QuizData {
  static Future<List<Map<String, Object>>> loadQuestions() async {
    final String yamlString = await rootBundle.loadString('assets/questions.yaml');
    final yamlList = loadYaml(yamlString) as List;

    // Convert YamlMap to a standard Map<String, Object>
    return yamlList.map((e) => _convertYamlToMap(e as YamlMap)).toList();
  }

  static Map<String, Object> _convertYamlToMap(YamlMap yamlMap) {
    final map = <String, Object>{};
    yamlMap.forEach((key, value) {
      if (value is YamlMap) {
        map[key] = _convertYamlToMap(value);
      } else if (value is YamlList) {
        map[key] = value.map((item) {
          if (item is YamlMap) {
            return _convertYamlToMap(item);
          }
          return item;
        }).toList();
      } else {
        map[key] = value;
      }
    });
    return map;
  }
}
