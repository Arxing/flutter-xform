import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_databinding/databinding.dart';
import 'package:fluttertoast/fluttertoast.dart';

part 'xform_field.dart';

/// A controller interface for [XForm]'s children(includes [XFormField] and general widgets).
abstract class XFormController {
  /// Validate all fields, return True if all fields are valid.
  bool validate();

  /// Reset all fields.
  void reset();

  /// Find other field's state in [XForm] by field name, return [Null] if not found.
  XFormFieldState<T> findField<T>(String fieldName);

  /// Find other field's binding value in [XForm] by field name, return [Null] if not found.
  T findValue<T>(String fieldName);
}

/// Behavior of [XForm] that how to react while occur error.
enum XFormErrorBehavior { toast, description, none }

/// Advanced [Form] with various functions, like validation, text constraint, length constraint, alignment and more.
class XForm extends StatefulWidget {
  /// Implements this function to construct [XForm]'s children, child can use [XFormController] to interact with [XForm].
  final Widget Function(XFormController) builder;

  /// Set title of children which is horizontal by same width if set true.
  final bool alignTitleInHorizontal;

  /// Default direction of children.
  final Axis direction;

  /// Default error behavior of children.
  final XFormErrorBehavior errorBehavior;

  const XForm({
    Key key,
    @required this.builder,
    this.alignTitleInHorizontal = true,
    this.direction = Axis.vertical,
    this.errorBehavior = XFormErrorBehavior.toast,
  }) : super(key: key);

  @override
  XFormState createState() => XFormState();

  /// Children can use [XForm.of(context)] to find ancestor state of [XForm].
  static XFormState of(BuildContext context) {
    final _XFormScope scope = context.dependOnInheritedWidgetOfExactType(aspect: _XFormScope);
    return scope?._formState;
  }
}

class XFormState extends State<XForm> implements XFormController {
  /// [_XFormScope]'s child will rebuild if [_generation] changed.
  int _generation = 0;

  /// Saves all [XForm]'s children state.
  final Set<XFormFieldState> _fields = Set<XFormFieldState>();

  @override
  void initState() {
    // update children first
    _updateChildren();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _XFormScope(
      formState: this,
      generation: _generation,
      child: widget.builder(this),
    );
  }

  @override
  void didUpdateWidget(XForm oldWidget) {
    // update children after did update widget
    _updateChildren();
    super.didUpdateWidget(oldWidget);
  }

  /// Implementation of [XFormController].
  /// Validate all children and return validation result, this method will run all validator of children.
  @override
  bool validate() {
    _forceRebuild();
    bool hasError = false;
    for (var field in _fields) {
      hasError = !field.validate() || hasError;
    }
    return !hasError;
  }

  /// Implementation of [XFormController].
  /// Reset all children.
  @override
  void reset() {
    _fields.forEach((field) => field.reset());
  }

  /// Implementation of [XFormController].
  /// Find child state by [fieldKey].
  @override
  XFormFieldState<T> findField<T>(String fieldKey) {
    if (_fields.isEmpty || fieldKey == null) return null;
    return _fields.firstWhere((o) => o.widget.fieldKey == fieldKey, orElse: () => null);
  }

  /// Implementation of [XFormController].
  /// Find child value by [fieldKey]
  @override
  T findValue<T>(String fieldKey) => findField(fieldKey)?.value;

  /// Reset all fields's width to null and get real width.
  void _remeasureChildrenWidth() {
    setState(() {
      _fields.forEach((field) => field._boundTitleWidthInHorizontal = null);
    });
  }

  /// <pre>
  /// Sync all children title to same width.
  ///  1. Remeasure all children width.
  ///  2. Find the max width.
  ///  3. Sync all children width.
  void _updateChildrenWidth() {
    // remeasure children width
    _remeasureChildrenWidth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        List<XFormFieldState> horizontalFields;
        if (widget.direction == Axis.horizontal) {
          horizontalFields = _fields.toList();
        } else {
          horizontalFields = _fields.where((state) => state.widget.direction == Axis.horizontal).toList();
        }
        print(horizontalFields);
        double maxWidth = horizontalFields.isEmpty ? 0 : horizontalFields.map((state) => state._titleRealWidth).reduce(max);
        horizontalFields.forEach((state) => state._boundTitleWidthInHorizontal = maxWidth);
      });
    });
  }

  /// [XFormField] call this method to register at fields.
  void _register(XFormFieldState field) => _fields.add(field);

  /// [XFormField] call this method to unregister from fields.
  void _unregister(XFormFieldState field) => _fields.remove(field);

  /// Force [_XFormScope] to rebuild child.
  void _forceRebuild() => setState(() => ++_generation);

  /// Update children's properties.
  void _updateChildren() {
    if (widget.alignTitleInHorizontal)
      _updateChildrenWidth();
    else
      _remeasureChildrenWidth();
  }
}

class _XFormScope extends InheritedWidget {
  final XFormState _formState;
  final int _generation;

  _XFormScope({
    Key key,
    XFormState formState,
    int generation,
    Widget child,
  })  : _formState = formState,
        _generation = generation,
        super(key: key, child: child);

  XForm get form => _formState.widget;

  @override
  bool updateShouldNotify(_XFormScope oldWidget) => _generation != oldWidget._generation;
}
