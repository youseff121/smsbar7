class DeviceBrandHelper {
  static bool isXiaomi(String brand) {
    return brand.toLowerCase().contains('xiaomi');
  }

  static bool isSamsung(String brand) {
    return brand.toLowerCase().contains('samsung');
  }

  static bool isHuawei(String brand) {
    return brand.toLowerCase().contains('huawei');
  }

  // فقط برای AutoStart استفاده میشه
  static String getAutoStartType(String brand) {
    final b = brand.toLowerCase();

    if (b.contains('xiaomi')) {
      return "xiaomi";
    }

    if (b.contains('huawei')) {
      return "huawei";
    }

    if (b.contains('samsung')) {
      return "samsung";
    }

    // پیش‌فرض برای بقیه برندها
    return "default";
  }

  static bool isSupportedBrand(String brand) {
    final b = brand.toLowerCase();
    return b.contains('xiaomi') ||
        b.contains('samsung') ||
        b.contains('huawei');
  }
}
