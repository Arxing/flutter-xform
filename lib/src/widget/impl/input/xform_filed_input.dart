import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xform/src/xform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_databinding/databinding.dart' hide ValueChanged;

class XFormFieldInput extends XFormField<String> {
  /// [TextField] hint text.
  final String hintText;

  /// Indicate [TextField] can edit or not.
  final bool editable;

  /// Error text of required validation failed.
  final String errorRequiredText;

  /// Value change callback.
  final ValueChanged<String> onChanged;

  /// Edit complete callback.
  final VoidCallback onEditingComplete;

  /// Indicate [TextField] is obscure or not.
  final bool obscure;

  /// Constraint of each input word.
  final InputConstraint inputConstraint;

  /// Keyboard type of [TextField].
  final TextInputType keyboardType;

  /// Constraint of input text's length.
  final TextLengthConstraint textLengthConstraint;

  XFormFieldInput({
    Key key,
    this.hintText,
    this.editable = true,
    this.errorRequiredText,
    this.onChanged,
    this.onEditingComplete,
    this.obscure = false,
    this.inputConstraint,
    this.keyboardType,
    this.textLengthConstraint,
    String fieldKey,
    bool titleVisible = true,
    Axis direction = Axis.vertical,
    String helperText,
    TextStyle helperStyle,
    TextStyle errorStyle,
    XFormValidateFailedCallback onValidateFailed,
    XFormFieldValidator<String> validator,
    XFormErrorBehavior errorBehavior = XFormErrorBehavior.description,
    bool isRequired = false,
    String initValue,
    ObservableString binding,
    TextStyle titleStyle,
    TitleBuilder titleBuilder,
    PanelBuilder panelBuilder,
    ValueChanged<String> onSubmitted,
    VoidCallback onTap,
    TextStyle inputStyle,
  }) : super(
          key: key,
          fieldKey: fieldKey,
          titleVisible: titleVisible,
          direction: direction,
          helperText: helperText,
          helperStyle: helperStyle,
          errorStyle: errorStyle,
          onValidateFailed: onValidateFailed,
          errorBehavior: errorBehavior,
          isRequired: isRequired,
          initValue: initValue,
          binding: binding,
          titleStyle: titleStyle,
          titleBuilder: titleBuilder,
          panelBuilder: panelBuilder,
          validator: (value, notifier) {
            if (isRequired && (value == null || value.isEmpty)) {
              notifier.notifyFailed(errorRequiredText);
            } else {
              if (textLengthConstraint != null) {
                var result = textLengthConstraint.validate(value?.length ?? 0);
                if (!result.success) {
                  notifier.notifyFailed(result.errorText);
                  return;
                }
              }
              if (validator != null) validator(value, notifier);
            }
          },
          builder: (XFormFieldState<String> field) {
            final XFormFieldInputState state = field;

            InputBorder buildBorder() {
              return OutlineInputBorder(
                borderSide: BorderSide(
                  width: state.validateSuccess ? 1 : 2.5,
                  color: state.validateSuccess ? Colors.black38 : Colors.redAccent,
                ),
                borderRadius: BorderRadius.circular(5),
              );
            }

            return TextField(
              controller: state._controller,
              readOnly: !editable,
              keyboardType: keyboardType,
              obscureText: obscure,
              onChanged: (value) {
                field.didValueChangeFromBody(value);
                if (onChanged != null) onChanged(value);
              },
              onEditingComplete: onEditingComplete,
              onSubmitted: onSubmitted,
              onTap: onTap,
              maxLength: textLengthConstraint?.calcMaxLength,
              inputFormatters: state._effectiveInputFormatters,
              style: _defaultInputStyle.merge(inputStyle),
              decoration: InputDecoration(
                errorStyle: TextStyle(height: 0, fontSize: 0),
                filled: !editable,
                counterText: "",
                hintText: hintText,
                border: buildBorder(),
                enabledBorder: buildBorder(),
                focusedBorder: buildBorder(),
                hintStyle: TextStyle(color: Colors.black38),
              ),
            );
          },
        );
  @override
  XFormFieldState createState() => XFormFieldInputState();

  static TextStyle _defaultInputStyle = TextStyle(
    color: Colors.black38,
    fontSize: 16,
  );
}

class XFormFieldInputState extends XFormFieldState<String> {
  TextEditingController _controller = TextEditingController();

  XFormFieldInput get widget => super.widget;

  List<TextInputFormatter> get _effectiveInputFormatters {
    if (widget.inputConstraint == null) return null;
    return [WhitelistingTextInputFormatter(widget.inputConstraint.regex)];
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initValue ?? "";
  }

  @override
  void updateUI(String value) {
    if (value == null || value.isEmpty)
      _controller?.clear();
    else
      _controller?.text = value;
  }
}
