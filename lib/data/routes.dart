import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/home/home.dart';
import 'package:saber/tarus/tarus_ikon.dart';

// workaround to assign strings as enum values
abstract class RoutePaths {
  static const home = '$prefixOfHome/:subpage';
  static const edit = '/edit';
  static const login = '/login';
  static const logs = '/logs';

  static const prefixOfHome = '/home';

  static String editFilePath(String filePath) {
    return '$edit?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static String editImportPdf(String filePath, String pdfPath) {
    return '$edit'
        '?path=${Uri.encodeQueryComponent(filePath)}'
        '&pdfPath=${Uri.encodeQueryComponent(pdfPath)}';
  }
}

abstract class HomeRoutes {
  static String browseFilePath(String? filePath) {
    var path = routes[1].path;
    if (filePath != '/' && filePath != '' && filePath != null) {
      path += '?path=${Uri.encodeQueryComponent(filePath)}';
    }
    return path;
  }

  static final PathFunction _homeFunction = pathToFunction(RoutePaths.home);

  static List<HomeRoute> get routes => <HomeRoute>[
    HomeRoute._(
      _homeFunction({'subpage': HomePage.recentSubpage}),
      label: t.home.tabs.home,
      ikon: TarusIkon.hizliBakis,
    ),
    HomeRoute._(
      _homeFunction({'subpage': HomePage.browseSubpage}),
      label: t.home.tabs.browse,
      ikon: TarusIkon.notlar,
    ),
    HomeRoute._(
      _homeFunction({'subpage': HomePage.whiteboardSubpage}),
      label: t.home.tabs.whiteboard,
      ikon: TarusIkon.beyazTahta,
    ),
    HomeRoute._(
      _homeFunction({'subpage': HomePage.settingsSubpage}),
      label: t.home.tabs.settings,
      ikon: TarusIkon.ayarlar,
    ),
  ];
}

/// Ana sekme: adres, etiket ve Lucide ikonu (alt çubuk ve kenar rayı).
class const HomeRoute._(
  final String path, {
  required final String label,
  required final IconData ikon,
});
