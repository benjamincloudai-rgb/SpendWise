import 'package:flutter/material.dart';
import 'package:spendwise/features/settings/screens/lock_screen.dart';
import 'package:spendwise/services/app_lock_controller.dart';

/// Wraps the authenticated app (via `MaterialApp.builder`) and watches the
/// app lifecycle. When App Lock is enabled and the app goes to background
/// (`paused` or `hidden`) the controller is locked, which drops a lock screen
/// overlay on top of the existing navigation stack. Unlocking simply removes
/// the overlay; the stack underneath is never touched.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final AppLockController _controller = AppLockController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            TickerMode(
              enabled: !_controller.isLocked,
              child: child!,
            ),
            if (_controller.isLocked)
              Positioned.fill(
                child: LockScreen(),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
