import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:private_agent/services/settings_service.dart';
import 'package:private_agent/services/jarvis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('MAX accepts Turkish wake phrases and rejects ambient chatter', () {
    expect(JarvisService.extractWakeCommand('Merhaba MAX'), '');
    expect(JarvisService.extractWakeCommand('Hey MAX'), '');
    expect(JarvisService.extractWakeCommand('Merhaba, MAX saat kaç?'), 'saat kaç?');
    expect(JarvisService.extractWakeCommand('Bugün hava çok güzel'), isNull);
  });
  test('Main voice is limited to Ahmet and Emel', () async {
    SharedPreferences.setMockInitialValues({'jarvis_neural_voice': 'en-GB-RyanNeural'});
    final settings = SettingsService.instance;
    await settings.init();
    expect(settings.jarvisNeuralVoice, 'tr-TR-AhmetNeural');
    await settings.setJarvisNeuralVoice('tr-TR-EmelNeural');
    expect(settings.jarvisNeuralVoice, 'tr-TR-EmelNeural');
    await settings.setJarvisNeuralVoice('en-US-GuyNeural');
    expect(settings.jarvisNeuralVoice, 'tr-TR-AhmetNeural');
  });
}
