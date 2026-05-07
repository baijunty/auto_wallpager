import 'dart:math';

import 'package:ffi/ffi.dart' show using;
import 'package:win32/win32.dart';
export 'client.dart';

bool setWallpaper(String imagePath) {
  return using((arena) {
    final result = SystemParametersInfo(
      SPI_SETDESKWALLPAPER,
      0,
      arena.pcwstr(imagePath),
      SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
    );
    return result.value;
  });
}

extension Random64 on Random {
  /// 生成一个 0 到 2^64 之间的随机整数（包含负数，因为 int 是有符号的）
  int nextInt64() {
    // 生成前 32 位
    int top = nextInt(1 << 31);
    // 生成后 32 位
    int bottom = nextInt(1 << 32);

    // 将前 32 位左移，加上后 32 位
    return (top << 32) | bottom;
  }
}
