/// Flutter OpenIM SDK - 環境切換配置
///
/// 這個文件展示如何在本地和 AWS 之間切換

class OpenIMConfig {
  // ============== 本地測試 ==============
  static const localConfig = {
    'apiAddr': 'http://localhost:10002',
    'wsAddr': 'ws://localhost:10001',
    'objectStorage': 'local',  // 本地存儲
  };

  // ============== AWS 部署 ==============
  static const awsConfig = {
    'apiAddr': 'https://openim-api.your-domain.com',  // 替換為你的域名
    'wsAddr': 'wss://openim-ws.your-domain.com',      // 替換為你的域名
    'objectStorage': 's3',  // AWS S3
  };

  // ============== 統一初始化方法 ==============
  static Future<void> initSDK({bool useAWS = false}) async {
    final config = useAWS ? awsConfig : localConfig;

    await OpenIM.iMManager.initSDK(
      config: IMConfig(
        apiAddr: config['apiAddr']!,
        wsAddr: config['wsAddr']!,
        dataDir: await _getDataDir(),
        objectStorage: config['objectStorage'],
        logLevel: useAWS ? 3 : 5,  // AWS 用較低日誌級別
      ),
      listener: OnConnectListener(
        onConnecting: () => print('連接中...'),
        onConnectSuccess: () => print('連接成功'),
        onConnectFailed: (code, msg) => print('連接失敗: $code $msg'),
      ),
    );
  }

  static Future<String> _getDataDir() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    return './openim_data';
  }
}

// ============== 使用示例 ==============

// 本地測試
void testLocal() async {
  await OpenIMConfig.initSDK(useAWS: false);
  // 消息編輯功能測試...
}

// AWS 生產環境
void testProduction() async {
  await OpenIMConfig.initSDK(useAWS: true);
  // 消息編輯功能使用...
}

// 根據環境變量自動選擇
void main() async {
  const isProduction = bool.fromEnvironment('PRODUCTION');
  await OpenIMConfig.initSDK(useAWS: isProduction);
  runApp(MyApp());
}