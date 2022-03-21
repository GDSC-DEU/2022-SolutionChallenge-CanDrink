import 'package:download_assets/download_assets.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:http/http.dart' as http;

class AssetDownloader {
  DownloadAssetsController downloadAssetsController = DownloadAssetsController();

  bool downloaded = false;

  Future initAssetDownloader() async {
    await downloadAssetsController.init();
    downloaded = await downloadAssetsController.assetsDirAlreadyExists();
  }

  Future checkUpdate() async {
    var checkUrl = Uri.parse('http://ssh.qwertycvb.site:8000/check');
    var response = await http.get(checkUrl);
    var doc = htmlparser.parse(response.body);
    var version = doc.body!.text.substring(1, 3);

    if (await downloadAssetsController.assetsFileExists(version)) {
      return true;
    }
    return false;
  }

  Future downloadAsset() async {
    try {
      await downloadAssetsController.startDownload(
          assetsUrl: 'http://ssh.qwertycvb.site:8000/update',
          onProgress: (progressValue) {
            print(progressValue);
            if (progressValue == 100) {
              return true;
            }
          });
    } on DownloadAssetsException catch (e) {
      print(e.toString());
    }
  }

  Future<bool> isDownloaded() async {
    if (await downloadAssetsController.assetsFileExists('candrink_labels.txt')) {
      if (await checkUpdate()) {
        return true;
      }
    }
    return false;
  }
}
