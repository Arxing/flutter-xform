class InputConstraint {
  final String _patternSegment;

  RegExp get regex => RegExp("[$_patternSegment]");

  const InputConstraint.custom(this._patternSegment);

  factory InputConstraint.group(List<InputConstraint> validations) {
    return InputConstraint.custom(validations.map((o) => o._patternSegment).join());
  }

  /// Number
  factory InputConstraint.number() => InputConstraint.custom("0-9");

  /// Signed number
  factory InputConstraint.signedInteger() => InputConstraint.custom("-+0-9");

  /// Unsigned number
  factory InputConstraint.unsignedInteger() => InputConstraint.custom("+0-9");

  /// Signed decimal
  factory InputConstraint.signedDecimal() => InputConstraint.custom("-+0-9.");

  /// Unsigned decimal
  factory InputConstraint.unsignedDecimal() => InputConstraint.custom("+0-9.");

  /// Lower case letter
  factory InputConstraint.lowerEnglishWord() => InputConstraint.custom("a-z");

  /// Upper case letter
  factory InputConstraint.upperEnglishWord() => InputConstraint.custom("A-Z");

  /// Lower/upper case letter
  factory InputConstraint.englishWord() => InputConstraint.group([
    InputConstraint.lowerEnglishWord(),
    InputConstraint.upperEnglishWord(),
  ]);

  /// Traditional/simplified chinese
  factory InputConstraint.chineseWord() => InputConstraint.custom("\u4E00-\u9FFF");
}