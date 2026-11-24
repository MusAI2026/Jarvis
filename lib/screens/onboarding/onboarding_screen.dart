import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/screen_automation_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

/// Multi-page first-run guide: welcome, accessibility setup, AI provider
/// setup and runtime permissions.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  final _automation = ScreenAutomationService.instance;
  final _settings = SettingsService.instance;
  final _apiKeyController = TextEditingController();

  int _page = 0;
  bool _serviceEnabled = false;
  String _provider = 'deepseek';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = _settings.provider;
    _apiKeyController.text = _settings.apiKey;
    _refreshServiceState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshServiceState();
  }

  Future<void> _refreshServiceState() async {
    final enabled = await _automation.isServiceEnabled();
    if (mounted) setState(() => _serviceEnabled = enabled);
  }

  void _next() {
    if (_page < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await _settings.setOnboardingComplete(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  ...List.generate(
                    4,
                    (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcomePage(theme),
                  _accessibilityPage(theme),
                  _aiPage(theme),
                  _permissionsPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Geri'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == 3 ? 'Başla' : 'Devam et'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _pageShell(ThemeData theme,
      {required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _welcomePage(ThemeData theme) {
    return _pageShell(
      theme,
      icon: Icons.shield_outlined,
      title: 'MAX ile tanışın',
      subtitle: 'Yeni nesil Stark yapay zekâ asistanınız ve telefon yardımcınız. '
          'Sesli etkileşim, temassız el hareketleri, canlı şarj verileri, '
          've otonom cihaz kontrolü.',
      children: [
        _featureRow(
          theme,
          Icons.record_voice_over_rounded,
          'Eller serbest sesli asistan',
          'Türkçe doğal ses, günlük takvim ve gündem özetleri ile telefon kontrolü.',
        ),
        _featureRow(
          theme,
          Icons.pan_tool_rounded,
          'Iron Man temassız el hareketleri',
          'Müzik değiştirmek için elinizi sallayın, duraklatmak veya oynatmak için bekletin, ekran görüntüsü için iki kez sallayın.',
        ),
        _featureRow(
          theme,
          Icons.view_in_ar_rounded,
          'Çift 3B hologram ekranı',
          'Dönen Arc Reaktörü ve renklere tepki veren 3B Iron Man hologramı arasında geçiş yapın.',
        ),
        _featureRow(
          theme,
          Icons.security_rounded,
          'Siber savunma ve nöbetçi modu',
          'Hırsızlığa karşı alarm, Code Black acil kilit, Wi-Fi cihaz denetimi ve hava sahası radarı.',
        ),
        _featureRow(
          theme,
          Icons.translate_rounded,
          'Canlı çeviri ve optik çözümleyici',
          '14 ve üzeri dilde canlı sesli çeviri; denklem, kod ve hesaplar için kamera çözümleyicisi.',
        ),
      ],
    );
  }

  Widget _featureRow(
      ThemeData theme, IconData icon, String title, String body) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessibilityPage(ThemeData theme) {
    return _pageShell(
      theme,
      icon: Icons.accessibility_new_outlined,
      title: 'Ekran kontrolünü etkinleştir',
      subtitle: 'MAX, Android erişilebilirlik hizmetini kullanır. '
          'Böylece ekranı okuyabilir ve sizin için düğmelere dokunabilir.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _serviceEnabled
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      _serviceEnabled ? AppTheme.success : AppTheme.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _serviceEnabled
                        ? 'MAX ekran kontrolü açık'
                        : 'MAX ekran kontrolü kapalı',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Tekrar kontrol et',
                  onPressed: _refreshServiceState,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _automation.openAccessibilitySettings(),
          icon: const Icon(Icons.settings_accessibility),
          label: const Text('Erişilebilirlik ayarlarını aç'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _automation.openAppInfoSettings(),
          icon: const Icon(Icons.info_outline),
          label: const Text('Uygulama bilgilerini aç (Android 13+ kısıtlı ayarlar)'),
        ),
        const SizedBox(height: 16),
        Text(
          'On Android 13 and newer you may need to open App Info → ⋮ menu → '
          '"Allow restricted settings" first, then enable "MAX '
          'Screen Control" under Accessibility → Downloaded apps.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }
  Widget _aiPage(ThemeData theme) {
    return _pageShell(
      theme,
      icon: Icons.key_outlined,
      title: 'Yapay zekâya bağlan',
      subtitle: 'OpenAI uyumlu sağlayıcı seçin ve API anahtarınızı yapıştırın. '
          'Bunu istediğiniz zaman Ayarlar bölümünden değiştirebilirsiniz.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in SettingsService.providers.entries)
              ChoiceChip(
                label: Text(entry.value.label),
                selected: _provider == entry.key,
                onSelected: (_) {
                  setState(() => _provider = entry.key);
                  _settings.setProvider(entry.key);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_provider == 'ollama')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Ollama runs fully on your machine — no API key needed. '
              'Start it with OLLAMA_HOST=0.0.0.0 ollama serve, then use '
              'adb reverse tcp:11434 tcp:11434 so the phone can reach it.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
          ),
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          onChanged: (v) => _settings.setApiKey(v),
          decoration: const InputDecoration(
            labelText: 'API anahtarı',
            hintText: 'sk-…',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The key is stored only on this device. The model can be changed '
          'later (default: ${_settings.model}).',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }

  Widget _permissionsPage(ThemeData theme) {
    return _pageShell(
      theme,
      icon: Icons.verified_user_outlined,
      title: 'İsteğe bağlı izinler',
      subtitle: 'Bu izinler sesli komutları, yüzen asistanı '
          'notifications and contact search. Skip anything you don\'t need.',
      children: [
        _permissionTile(
          theme,
          icon: Icons.mic_none,
          title: 'Mikrofon',
          subtitle: 'Görevleri yazmak yerine söyleyin',
          onTap: () async {
          await Permission.microphone.request();
        },
        ),
        _permissionTile(
          theme,
          icon: Icons.notifications_none,
          title: 'Bildirimler',
          subtitle: 'Görev ilerlemesi ve tamamlanma bildirimleri',
          onTap: () async {
            await Permission.notification.request();
          },
        ),
        _permissionTile(
          theme,
          icon: Icons.contacts_outlined,
          title: 'Kişiler',
          subtitle: '“Annemi ara” gibi komutlar',
          onTap: () async {
            await Permission.contacts.request();
          },
        ),
        _permissionTile(
          theme,
          icon: Icons.bubble_chart_outlined,
          title: 'Yüzen asistan',
          subtitle: 'Diğer uygulamaları kullanırken asistanı kontrol edin',
          onTap: () async {
            await FlutterOverlayWindow.requestPermission();
          },
        ),
      ],
    );
  }

  Widget _permissionTile(ThemeData theme,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Future<void> Function() onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          try {
            await onTap();
          } catch (_) {}
        },
      ),
    );
  }
}
