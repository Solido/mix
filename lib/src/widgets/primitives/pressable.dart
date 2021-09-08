import 'package:flutter/material.dart';

import '../../mixer/mix_factory.dart';
import '../../mixer/mixer.dart';
import '../mix_widget.dart';
import 'box.dart';

class Pressable extends MixWidget {
  const Pressable(
    Mix mix, {
    required this.child,
    required this.onPressed,
    this.onLongPressed,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    Key? key,
  }) : super(mix, key: key);

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final mixer = Mixer.build(context, mix);
    return PressableMixerWidget(
      mixer,
      onPressed: onPressed,
      onLongPressed: onLongPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

class PressableMixerWidget extends StatefulWidget {
  const PressableMixerWidget(
    this.mixer, {
    required this.child,
    required this.onPressed,
    this.onLongPressed,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    Key? key,
  }) : super(key: key);

  final Mixer mixer;

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;

  @override
  _PressableMixerWidgetState createState() => _PressableMixerWidgetState();
}

class _PressableMixerWidgetState extends State<PressableMixerWidget> {
  late FocusNode node;

  @override
  void initState() {
    super.initState();
    node = widget.focusNode ?? _createFocusNode();
  }

  @override
  void didUpdateWidget(PressableMixerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      node = widget.focusNode ?? node;
    }
  }

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  bool _hovering = false;
  bool _pressing = false;
  bool _shouldShowFocus = false;

  bool get enabled => widget.onPressed != null || widget.onLongPressed != null;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        focusable: enabled && node.canRequestFocus,
        focused: node.hasFocus,
        child: FocusableActionDetector(
          focusNode: node,
          autofocus: widget.autofocus,
          enabled: enabled,
          onShowFocusHighlight: (v) {
            if (mounted) setState(() => _shouldShowFocus = v);
          },
          onShowHoverHighlight: (v) {
            if (mounted) setState(() => _hovering = v);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onTapDown: (_) {
              if (mounted) setState(() => _pressing = true);
              // widget.onTapDown?.call();
            },
            onTapUp: (_) async {
              // widget.onTapUp?.call();
              if (!enabled) return;
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) setState(() => _pressing = false);
            },
            onTapCancel: () {
              // widget.onTapCancel?.call();
              if (mounted) setState(() => _pressing = false);
            },
            onLongPressStart: (_) {
              // widget.onLongPressStart?.call();
              if (mounted) setState(() => _pressing = true);
            },
            onLongPressEnd: (_) {
              // widget.onLongPressEnd?.call();
              if (mounted) setState(() => _pressing = false);
            },
            child: () {
              final disabled = widget.mixer.disabled;
              final focused = widget.mixer.focused;
              final hovering = widget.mixer.hovering;
              final pressing = widget.mixer.pressing;

              Mix? mix = () {
                if (!enabled && disabled != null) return disabled.mix;
                if (_pressing && pressing != null) return pressing.mix;
                if (_hovering && hovering != null) return hovering.mix;
                if (_shouldShowFocus && focused != null) return focused.mix;
              }();

              return BoxMixerWidget(
                widget.mixer,
                child: () {
                  if (mix != null) {
                    return BoxMixerWidget(
                      Mixer.build(context, mix),
                      child: widget.child,
                    );
                  }
                  return widget.child;
                }(),
              );
            }(),
          ),
        ),
      ),
    );
  }
}
