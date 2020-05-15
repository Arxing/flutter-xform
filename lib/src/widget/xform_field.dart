part of 'xform.dart';

typedef TitleBuilder = dynamic Function(BuildContext);

typedef PanelBuilder = Widget Function(Axis, XFormFieldPanel);

class XFormFieldPanel {
  final Widget title;
  final Widget body;
  final Widget helper;
  final Widget error;

  XFormFieldPanel({this.title, this.body, this.helper, this.error});
}

class XFormField<T> extends StatefulWidget {
  /// [XFormField]'s unique key in [XForm].
  final Object fieldKey;

  /// [XFormField]'s body builder.
  final XFormFieldBuilder<T> builder;

  /// [XFormField]'s title builder, return [Widget] or [String].
  final TitleBuilder titleBuilder;

  /// The title widget appear if true, or disappear if false.
  final bool titleVisible;

  /// Direction between title and body.
  final Axis direction;

  /// The helper text show below body.
  final String helperText;

  /// Style of title.
  final TextStyle titleStyle;

  /// Alignment of title.
  final Alignment titleAlignment;

  /// Style of helper text.
  final TextStyle helperStyle;

  /// Alignment of helper text.
  final Alignment helperAlignment;

  /// Style of error text.
  final TextStyle errorStyle;

  /// Alignment of error text.
  final Alignment errorAlignment;

  /// Validation failed callback.
  final XFormValidateFailedCallback onValidateFailed;

  /// Validator that can control validation result.
  final XFormFieldValidator<T> validator;

  /// The error behavior when validation failed.
  final XFormErrorBehavior errorBehavior;

  /// Indicate the field is required or not, validation will fail if [isRequired] set true but [XFormField] has not value.
  final bool isRequired;

  /// Initial value of [XFormField].
  final T initValue;

  /// Binds and synchronize to [ObservableField].
  final ObservableField<T> binding;

  final PanelBuilder panelBuilder;

  const XFormField({
    Key key,
    this.fieldKey,
    this.builder,
    this.titleBuilder,
    this.titleVisible = true,
    this.direction,
    this.helperText,
    this.helperStyle,
    this.errorStyle,
    this.onValidateFailed,
    this.validator,
    this.errorBehavior,
    this.isRequired = false,
    this.initValue,
    this.binding,
    this.titleStyle,
    this.panelBuilder,
    this.titleAlignment = Alignment.centerLeft,
    this.helperAlignment = Alignment.centerLeft,
    this.errorAlignment = Alignment.centerLeft,
  }) : super(key: key);

  @override
  XFormFieldState createState() => XFormFieldState();
}

class XFormFieldState<T> extends State<XFormField<T>> {
  T _value;

  T get value => _value;

  SubmitValidatorNotifier _notifier = SubmitValidatorNotifier._();

  String get _errorText => _notifier.errorMessage;

  Map<String, dynamic> get _bundle => _notifier._bundle;

  double _boundTitleWidthInHorizontal;

  GlobalKey _titleKey = GlobalKey();

  bool _bindingSetFromSelf = false;

  /// Result of validation.
  bool get validateSuccess => _notifier.success;

  XFormErrorBehavior get _effectiveErrorBehavior =>
      widget.errorBehavior ?? XForm.of(context)?.widget?.errorBehavior ?? XFormErrorBehavior.toast;

  double get _titleRealWidth {
    var renderBox = _titleKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox?.hasSize ?? false ? renderBox.size.width : 0;
  }

  Axis get _effectiveDirection => XForm.of(context)?.widget?.direction ?? widget.direction;

  TextStyle get _defaultErrorStyle => TextStyle(
        color: Colors.redAccent,
        fontSize: 16,
      );

  TextStyle get _defaultHelperStyle => TextStyle(
        color: Colors.black54,
        fontSize: 16,
      );

  TextStyle get _defaultTitleStyle => TextStyle(
        color: Colors.black54,
        fontSize: 20,
      );

  Widget get _effectiveTitle {
    if (widget.titleBuilder == null) return Container();
    var title = widget.titleBuilder(context);
    if (title is Widget) return title;
    if (title is! String) return Container();
    return Text(
      title,
      style: _defaultTitleStyle.merge(widget.titleStyle),
    );
  }

  Widget get _effectiveBody => widget.builder(this);

  Widget get _effectiveHelper => Text(widget.helperText ?? "", style: _defaultHelperStyle.merge(widget.helperStyle));

  Widget get _effectiveError => Text(_errorText ?? "", style: _defaultErrorStyle.merge(widget.errorStyle));

  @override
  void initState() {
    super.initState();
    if (widget.initValue != null) setValue(widget.initValue, syncToBinding: true, syncToUI: true);
    if (widget.binding != null) {
      if (widget.initValue != null) widget.binding.set(widget.initValue);
      widget.binding.stream.listen((value) {
        if (_bindingSetFromSelf)
          _bindingSetFromSelf = false;
        else
          setValue(value, syncToBinding: false, syncToUI: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    XForm.of(context)?._register(this);
    if (widget.panelBuilder != null) {
      return widget.panelBuilder(
          widget.direction,
          XFormFieldPanel(
            title: _effectiveTitle,
            body: _effectiveBody,
            error: _effectiveError,
            helper: _effectiveHelper,
          ));
    }
    switch (_effectiveDirection) {
      case Axis.vertical:
        return Column(
          children: <Widget>[
            Visibility(
              child: Container(
                child: Align(
                  child: _effectiveTitle,
                  alignment: widget.titleAlignment,
                ),
                margin: EdgeInsets.only(bottom: 10),
              ),
              visible: widget.titleVisible,
            ),
            Column(
              children: <Widget>[
                _effectiveBody,
                Align(
                  alignment: widget.errorAlignment,
                  child: Visibility(
                    visible: _effectiveErrorBehavior == XFormErrorBehavior.description && !validateSuccess,
                    child: _effectiveError,
                  ),
                ),
                Align(
                  alignment: widget.helperAlignment,
                  child: Visibility(
                    visible: widget.helperText != null,
                    child: _effectiveHelper,
                  ),
                )
              ],
            ),
          ],
        );
      case Axis.horizontal:
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Visibility(
                  visible: widget.titleVisible,
                  child: Container(
                    key: _titleKey,
                    width: _boundTitleWidthInHorizontal,
                    child: _effectiveTitle,
                    margin: EdgeInsets.only(right: 10),
                  ),
                ),
                Expanded(child: _effectiveBody),
              ],
            ),
            Align(
              alignment: widget.errorAlignment,
              child: Visibility(
                visible: _effectiveErrorBehavior == XFormErrorBehavior.description && !validateSuccess,
                child: _effectiveError,
              ),
            ),
            Align(
              alignment: widget.helperAlignment,
              child: Visibility(
                visible: widget.helperText != null,
                child: _effectiveHelper,
              ),
            ),
          ],
        );
    }
    return Container();
  }

  void _notifyValidateFailed() {
    if (widget.onValidateFailed == null) {
      // default behavior
      switch (_effectiveErrorBehavior) {
        case XFormErrorBehavior.toast:
          if (_errorText != null) Fluttertoast.showToast(msg: _errorText);
          break;
        case XFormErrorBehavior.description:
          // UI will sync by error text, so do nothing
          break;
        case XFormErrorBehavior.none:
          // do nothing
          break;
      }
    } else {
      // custom behavior
      widget.onValidateFailed(_errorText, _bundle);
    }
  }

  /// Validate the [XFormField] and return validation result.
  bool validate() {
    setState(() {
      if (widget.validator != null) {
        // reset notifier
        _notifier.resetStatus();
        // run validator
        widget.validator(_value, _notifier);
        // notify if failed
        if (!validateSuccess) _notifyValidateFailed();
      }
    });
    return validateSuccess;
  }

  /// Reset [XFormField] initial value.
  void reset() {
    setState(() {
      setValue(widget.initValue, syncToBinding: true, syncToUI: true);
    });
  }

  /// Value change callback.
  void updateUI(T value) {}

  /// Value changed from body UI, sync to binding and rebuild.
  void didValueChangeFromBody(T value) {
    setState(() {
      setValue(value, syncToBinding: true, syncToUI: false);
    });
    XForm.of(context)?._forceRebuild();
  }

  /// Set current value, trigger binding stream and [updateUI] callback, finally notify ancestor [XForm] to rebuild.
  void setValue(T value, {bool syncToBinding = true, bool syncToUI = true}) {
    _value = value;
    if (syncToBinding) {
      if (widget.binding != null) {
        _bindingSetFromSelf = true;
        widget.binding.set(value);
      }
    }
    if (syncToUI) updateUI(value);
  }

  /// Remove self from [XForm] after deactivated.
  @override
  void deactivate() {
    XForm.of(context)?._unregister(this);
    super.deactivate();
  }
}

/// A notifier for validation that can control validation status to success or failed.
class SubmitValidatorNotifier {
  Map<String, dynamic> _bundle = {};
  bool _isSuccess;
  String _failedMessage;

  SubmitValidatorNotifier._() : _isSuccess = true;

  /// Clear bundle and failed message.
  void resetStatus() {
    _bundle.clear();
    _isSuccess = null;
    _failedMessage = null;
  }

  /// Put data to bundle, it will be called in [XFormValidateFailedCallback] if validation is failed.
  void putData(String key, dynamic val) => _bundle[key] = val;

  /// Set error message, it will be called in [XFormValidateFailedCallback] if validation is failed.
  void putErrorMessage(String errorMessage) => _failedMessage = errorMessage;

  /// Notify validation result.
  void notifyResult(bool success, [String errorMessage]) {
    if (errorMessage != null) putErrorMessage(errorMessage);
    _isSuccess = success;
  }

  /// Notify validation result to success.
  void notifySuccess() => this.notifyResult(true);

  /// Notify validation result to failed
  void notifyFailed([String errorMessage]) {
    if (errorMessage != null) putErrorMessage(errorMessage);
    this.notifyResult(false);
  }

  /// Validation result.
  bool get success => _isSuccess ?? true;

  /// Validation failed message.
  String get errorMessage => _failedMessage;
}

/// [XFormField] validation callback.
typedef XFormFieldValidator<T> = void Function(T value, SubmitValidatorNotifier notifier);

/// [XFormField] validation error callback.
typedef XFormValidateFailedCallback = void Function(String errorMessage, Map<String, dynamic> bundle);

/// [XFormField] widget body builder.
typedef XFormFieldBuilder<T> = Widget Function(XFormFieldState<T> field);
