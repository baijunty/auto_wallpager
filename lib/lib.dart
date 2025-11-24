import 'dart:math';

import 'package:win32/win32.dart';
export 'client.dart';

void setWallpaper(String imagePath) {
  print('设置壁纸：$imagePath');
  final imagePathPtr = TEXT(imagePath);
  final result = SystemParametersInfo(
    SPI_SETDESKWALLPAPER,
    0,
    imagePathPtr,
    SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
  );

  free(imagePathPtr);

  if (result == 0) {
    print('设置壁纸失败');
  }
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
