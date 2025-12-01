class RecruitmentDictionary {
  RecruitmentDictionary._();

  static const Map<String, String> playStyleLabels = {
    'singles': 'Đánh đơn',
    'doubles': 'Đánh đôi',
    'mixed': 'Linh hoạt',
  };

  static const Map<String, String> skillLevelLabels = {
    'Beginner': 'Mới chơi',
    'Lower Intermediate': 'Trung bình yếu',
    'Intermediate': 'Trung bình',
    'Upper Intermediate': 'Trung bình khá',
    'Advanced': 'Nâng cao',
  };

  static String playStyleLabelFromValue(String? value) {
    if (value == null) {
      return 'Không xác định';
    }
    return playStyleLabels[value] ?? value;
  }

  static String skillLabelFromValue(dynamic value) {
    if (value == null) {
      return 'Không xác định';
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
