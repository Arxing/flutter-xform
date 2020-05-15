import 'dart:math' as math;

class TextLengthConstraint {
  static const _LENGTH_MAX_VALUE = 9223372036854775807;
  static const _LENGTH_MIN_VALUE = 0;
  final int maxValue;
  final int minValue;
  final List<int> specificValues;
  String maxErrorText;
  String minErrorText;

  int get _calcMin => minValue ?? _LENGTH_MIN_VALUE;

  int get _calcMax => maxValue ?? _LENGTH_MAX_VALUE;

  TextLengthConstraint._({
    int min,
    int max,
    List<int> specifics,
    String maxError,
    String minError,
  })  : minValue = min,
        minErrorText = minError,
        maxValue = max,
        maxErrorText = maxError,
        specificValues = specifics.toSet().toList() {
    if (_calcMax < _calcMin) throw "Illegal value: max($_calcMax) must greater than or equals to min($_calcMin)";
  }

  TextLengthConstraint.min(int min, [String errorMessage])
      : this._(
          min: min,
          max: null,
          specifics: [],
          minError: errorMessage,
        );

  TextLengthConstraint.max(int max, [String errorMessage])
      : this._(
          min: null,
          max: max,
          specifics: [],
          maxError: errorMessage,
        );

  TextLengthConstraint.range(int min, int max, {String minErrorMessage, String maxErrorMessage})
      : this._(
          min: min,
          max: max,
          specifics: [],
          minError: minErrorMessage,
          maxError: maxErrorMessage,
        );

  TextLengthConstraint.specific(int length)
      : this._(
          min: null,
          max: null,
          specifics: [length],
        );

  TextLengthConstraint _and(TextLengthConstraint other) {
    int max = other.maxValue ?? this.maxValue;
    int min = other.minValue ?? this.minValue;
    List<int> specifics = List.from(this.specificValues)..addAll(other.specificValues);
    return TextLengthConstraint._(
      min: min,
      max: max,
      specifics: specifics,
      minError: other.minErrorText ?? minErrorText,
      maxError: other.maxErrorText ?? maxErrorText,
    );
  }

  TextLengthConstraint max(int max, [String errorMessage]) => _and(TextLengthConstraint.max(max, errorMessage));

  TextLengthConstraint min(int min, [String errorMessage]) => _and(TextLengthConstraint.min(min, errorMessage));

  TextLengthConstraint range(int min, int max, {String minErrorMessage, String maxErrorMessage}) =>
      _and(TextLengthConstraint.range(min, max, minErrorMessage: minErrorMessage, maxErrorMessage: maxErrorMessage));

  TextLengthConstraint specific(int length) => _and(TextLengthConstraint.specific(length));

  int get calcMaxLength {
    if (maxValue != null) {
      if (specificValues.isEmpty) return maxValue;
      return math.max(maxValue, specificValues.reduce(math.max));
    } else {
      if (specificValues.isNotEmpty) return specificValues.reduce(math.max);
    }
    return _LENGTH_MAX_VALUE;
  }

  int get calcMinLength {
    if (minValue != null) {
      if (specificValues.isEmpty) return minValue;
      return math.min(minValue, specificValues.reduce(math.min));
    } else {
      if (specificValues.isNotEmpty) return specificValues.reduce(math.min);
    }
    return _LENGTH_MIN_VALUE;
  }

  Result validate(int length) {
    if (specificValues.contains(length)) return Result.success();
    if (minValue != null && length < minValue) return Result.failed(minErrorText);
    if (maxValue != null && length > maxValue) return Result.failed(maxErrorText);
    return Result.success();
  }
}

class Result {
  final bool success;
  final String errorText;

  Result(this.success, this.errorText);

  Result.success()
      : success = true,
        errorText = null;

  Result.failed([String message])
      : success = false,
        errorText = message;
}
