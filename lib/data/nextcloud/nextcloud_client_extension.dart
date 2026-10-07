import 'dart:io';

import 'package:http/io_client.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud/provisioning_api.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/version.dart';

extension NextcloudClientExtension on NextcloudClient {
  static final Uri defaultNextcloudUri = Uri.parse('https://not.tarus.tr');

  /// Not sunucusu (tarusatolye/not) User-Agent'a bakmaz; ad tarus Not'unki.
  static final userAgent =
      'tarusNot/$buildName '
      '(${Platform.operatingSystem}) '
      'Dart/${Platform.version.split(' ').first}';
  static IOClient newHttpClient() =>
      IOClient(HttpClient()..userAgent = userAgent);

  static const String appRootDirectoryPrefix =
      FileManager.appRootDirectoryPrefix;
  static NextcloudClient? withSavedDetails() {
    if (!stows.loggedIn) return null;

    final url = stows.url.value;
    final username = stows.username.value;
    final ncPassword = stows.ncPassword.value;

    final client = NextcloudClient(
      url.isNotEmpty ? Uri.parse(url) : defaultNextcloudUri,
      loginName: username,
      password: ncPassword,
      appPassword: ncPassword,
      httpClient: NextcloudClientExtension.newHttpClient(),
    );

    void deAuth() {
      // Logout if the username changes
      if (stows.username.value == username) return;
      stows.username.removeListener(deAuth);
      client.authentications?.clear();
    }

    stows.username.addListener(deAuth);

    return client;
  }

  Future<String> getUsername() async {
    final user = await provisioningApi.users.getCurrentUser();
    return user.body.ocs.data.id;
  }
}
