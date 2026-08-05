import 'package:share_plus/share_plus.dart';

abstract class PrayerSharer {
  Future<void> share(String text);
}

class PlatformPrayerSharer implements PrayerSharer {
  const PlatformPrayerSharer();

  @override
  Future<void> share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}
