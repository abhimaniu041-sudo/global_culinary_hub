import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ar'),
    Locale('zh'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Global Culinary Hub',
      'search': 'Search',
      'favorites': 'Favorites',
      'history': 'History',
      'generate': 'Generate Recipe',
      'home': 'Home',
      'camera': 'Camera',
      'chat': 'AI Chef',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'register': 'Register',
    },
    'hi': {
      'app_name': 'ग्लोबल कलिनरी हब',
      'search': 'खोजें',
      'favorites': 'पसंदीदा',
      'history': 'इतिहास',
      'generate': 'रेसिपी बनाएं',
      'home': 'होम',
      'camera': 'कैमरा',
      'chat': 'AI शेफ',
      'sign_in': 'साइन इन',
      'sign_out': 'साइन आउट',
      'register': 'रजिस्टर',
    },
    'es': {
      'app_name': 'Hub Culinario Global',
      'search': 'Buscar',
      'favorites': 'Favoritos',
      'history': 'Historial',
      'generate': 'Generar Receta',
      'home': 'Inicio',
      'camera': 'Camara',
      'chat': 'Chef IA',
      'sign_in': 'Iniciar Sesion',
      'sign_out': 'Cerrar Sesion',
      'register': 'Registrarse',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String get appName => translate('app_name');
  String get search => translate('search');
  String get favorites => translate('favorites');
  String get history => translate('history');
  String get generate => translate('generate');
  String get home => translate('home');
  String get camera => translate('camera');
  String get chat => translate('chat');
  String get signIn => translate('sign_in');
  String get signOut => translate('sign_out');
  String get register => translate('register');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'pa', 'es', 'fr', 'de', 'ar', 'zh']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
