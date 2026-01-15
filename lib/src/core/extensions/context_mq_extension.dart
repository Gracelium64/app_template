import 'package:flutter/widgets.dart';

extension ContextScreenSize on BuildContext {
  /// Full logical screen size.
  Size get scrnSize => MediaQuery.sizeOf(this);

  /// Convenience: screen width.
  double get scrnWidth => scrnSize.width;

  /// Convenience: screen height.
  double get scrnHeight => scrnSize.height;

  /// Device pixel ratio if needed elsewhere.
  double get scrnDevicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  EdgeInsets get scrnPadding => MediaQuery.paddingOf(this);

  // double get scrnTextScale => MediaQuery.textScaleFactorOf(this);

  // TextScaler get scrnTextScaler => MediaQuery.textScalerOf(this);
}
