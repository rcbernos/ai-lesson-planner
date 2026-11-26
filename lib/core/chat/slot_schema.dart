/// Slot schema for extracting fields from chat messages.
/// Defines what fields can be extracted and their validation rules.
library;

/// Types of slots that can be filled from natural language input.
enum SlotType {
  /// Grade labels (2-6 grades)
  gradeLabels,

  /// Learning area/subject (Science, Math, etc.)
  learningArea,

  /// Session duration in minutes (60, 90, or 120)
  sessionMinutes,

  /// Number of sessions
  sessions,

  /// Output language
  outputLanguage,

  /// Shared sub-theme
  sharedSubTheme,

  /// Teacher name
  teacher,

  /// School name
  school,

  /// Date
  date,

  /// Term
  term,

  /// Student counts (male/female)
  learnerCounts,
}

/// Defines an extractable slot field with its validation rules.
class SlotField {
  const SlotField({
    required this.name,
    required this.type,
    this.required = false,
    this.allowMultiple = false,
  });

  /// Field name in the JSON patch
  final String name;

  /// Type of the slot
  final SlotType type;

  /// Whether this field is required for generation
  final bool required;

  /// Whether multiple values are allowed (e.g., multiple grades)
  final bool allowMultiple;
}

/// Schema defining all extractable slot fields.
class SlotSchema {
  const SlotSchema();

  static const List<SlotField> fields = [
    SlotField(
      name: 'gradeLabels',
      type: SlotType.gradeLabels,
      required: true,
      allowMultiple: true,
    ),
    SlotField(
      name: 'learningArea',
      type: SlotType.learningArea,
      required: true,
    ),
    SlotField(
      name: 'sessionMinutes',
      type: SlotType.sessionMinutes,
      required: true,
    ),
    SlotField(name: 'sessions', type: SlotType.sessions, required: false),
    SlotField(
      name: 'outputLanguage',
      type: SlotType.outputLanguage,
      required: false,
    ),
    SlotField(
      name: 'sharedSubTheme',
      type: SlotType.sharedSubTheme,
      required: true,
    ),
    SlotField(name: 'teacher', type: SlotType.teacher, required: true),
    SlotField(name: 'school', type: SlotType.school, required: true),
    SlotField(name: 'date', type: SlotType.date, required: true),
    SlotField(name: 'term', type: SlotType.term, required: true),
    SlotField(
      name: 'learnerCounts',
      type: SlotType.learnerCounts,
      required: false,
    ),
  ];

  /// Validates a grade label value.
  static bool isValidGradeLabel(String label) {
    final gradePattern = RegExp(
      r'^Grade\s+(\d+|[a-zA-Z]+)',
      caseSensitive: false,
    );
    return gradePattern.hasMatch(label.trim());
  }

  /// Validates session minutes (common values: 60, 90, 120).
  static bool isValidSessionMinutes(int minutes) {
    return [60, 90, 120].contains(minutes);
  }

  /// Validates number of grades (2-6).
  static bool isValidGradeCount(int count) {
    return count >= 2 && count <= 6;
  }

  /// Validates learner counts are non-negative integers.
  static bool isValidLearnerCount(dynamic value) {
    if (value is int) return value >= 0;
    if (value is double) return value >= 0 && value == value.floorToDouble();
    return false;
  }
}

/// Validation result for a slot value.
class SlotValidation {
  const SlotValidation({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  static const SlotValidation valid = SlotValidation(isValid: true);

  static SlotValidation invalid(String message) =>
      SlotValidation(isValid: false, errorMessage: message);
}

/// Validates a single slot value based on the field definition.
SlotValidation validateSlot(
  String fieldName,
  dynamic value, {
  int? currentGradeCount,
}) {
  if (value == null || (value is String && value.isEmpty)) {
    // Empty values are allowed (model should not invent)
    return SlotValidation.valid;
  }

  switch (fieldName) {
    case 'gradeLabels':
      if (value is List) {
        final labels = value.whereType<String>().toList();
        if (labels.isEmpty) return SlotValidation.valid;
        for (final label in labels) {
          if (!SlotSchema.isValidGradeLabel(label)) {
            return SlotValidation.invalid('Invalid grade label: $label');
          }
        }
        if (!SlotSchema.isValidGradeCount(labels.length)) {
          return SlotValidation.invalid('Grade count must be between 2 and 6');
        }
      }
      return SlotValidation.valid;

    case 'learningArea':
      if (value is String && value.trim().isEmpty) {
        return SlotValidation.invalid('Learning area cannot be empty');
      }
      return SlotValidation.valid;

    case 'sessionMinutes':
      if (value is int || value is double) {
        final minutes = value is double ? value.toInt() : value;
        if (!SlotSchema.isValidSessionMinutes(minutes)) {
          return SlotValidation.invalid(
            'Session minutes must be 60, 90, or 120',
          );
        }
      }
      return SlotValidation.valid;

    case 'male':
    case 'female':
      if (!SlotSchema.isValidLearnerCount(value)) {
        return SlotValidation.invalid(
          'Learner count must be a non-negative integer',
        );
      }
      return SlotValidation.valid;

    case 'outputLanguage':
      if (value is String &&
          !['filipino', 'english', 'fil', 'en'].contains(value.toLowerCase())) {
        return SlotValidation.invalid(
          'Output language must be filipino or english',
        );
      }
      return SlotValidation.valid;

    default:
      return SlotValidation.valid;
  }
}
