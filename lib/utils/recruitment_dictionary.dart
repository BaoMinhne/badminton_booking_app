class RecruitmentDictionary {
  RecruitmentDictionary._();

  static const Map<String, String> playStyleLabels = {
    'singles': 'Singles',
    'doubles': 'Doubles',
    'mixed': 'Flexible',
  };

  static const Map<String, String> skillLevelLabels = {
    'Beginner': 'Beginner',
    'Lower Intermediate': 'Lower intermediate',
    'Intermediate': 'Intermediate',
    'Upper Intermediate': 'Upper intermediate',
    'Advanced': 'Advanced',
  };

  static String playStyleLabelFromValue(String? value) {
    if (value == null) {
      return 'Unknown';
    }
    return playStyleLabels[value] ?? value;
  }

  static String skillLabelFromValue(dynamic value) {
    if (value == null) {
      return 'Unknown';
    }
    final key = value is String ? value : value.toString();
    return skillLevelLabels[key] ?? key;
  }

  static String playStyleValueFromLabel(String label) {
    return _reverseLookup(playStyleLabels, label) ?? 'mixed';
  }

  static String skillValueFromLabel(String label) {
    return _reverseLookup(skillLevelLabels, label) ?? 'Intermediate';
  }

  static List<String> playStyleDisplayOptions() {
    return playStyleLabels.values.toList(growable: false);
  }

  static List<String> skillDisplayOptions() {
    return skillLevelLabels.values.toList(growable: false);
  }

  static String? _reverseLookup(Map<String, String> map, String label) {
    for (final entry in map.entries) {
      if (entry.value == label) {
        return entry.key;
      }
    }
    return null;
  }
}
