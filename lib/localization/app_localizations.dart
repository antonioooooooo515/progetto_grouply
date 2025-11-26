import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'it': {
      'app_title': 'Grouply - Team Manager',

      // Login
      'login_title': 'Bentornato!',
      'login_subtitle': 'Accedi per continuare',
      'email_label': 'Email',
      'password_label': 'Password',
      'forgot_password': 'Password dimenticata?',
      'login_button': 'Accedi',
      'login_with_google': 'Accedi con Google',
      'no_account': 'Non hai un account?',
      'go_to_register': 'Registrati',
      'or_label': 'oppure',
      'google_signin_loading': 'Accesso con Google...',
      'google_signup_loading': 'Registrazione con Google...',

      // Register
      'register_title': 'Crea un account',
      'register_subtitle': 'Registrati per iniziare',
      'confirm_password_label': 'Conferma password',
      'register_button': 'Registrati',
      'register_with_google': 'Registrati con Google',
      'registration_success':
      'Registrazione avvenuta con successo.\nTi diamo il benvenuto nell\'app Grouply - Team Manager',
      'go_to_login_button': 'Vai alla pagina di login',
      'have_account': 'Hai già un account?',

      // Home
      'home_title': 'Home',
      'home_message': 'Benvenuto nella Home di Grouply - Team Manager',
      'home_groups_dialog_title': 'Gruppi',
      'home_groups_create': 'Crea nuovo gruppo',
      'home_groups_join': 'Inserisci il codice di un gruppo esistente',
      'home_groups_create_snackbar':
      'Funzione "Crea nuovo gruppo" in sviluppo',
      'home_groups_join_snackbar':
      'Funzione "Inserisci codice gruppo" in sviluppo',
      'close_button': 'Chiudi',

      // Settings
      'settings_title': 'Impostazioni',
      'settings_section_theme': 'Tema',
      'settings_change_theme': 'Cambia tema',
      'settings_theme_dark_active': 'Il tema scuro è attivo',
      'settings_theme_light_active': 'Il tema chiaro è attivo',
      'settings_section_account': 'Account',
      'settings_section_profile': 'Profilo',
      'settings_profile_manage_title': 'Gestione profilo',
      'settings_profile_manage_subtitle':
      'Modifica nome, nascita, ruolo, sport...',
      'settings_section_language': 'Lingua',
      'settings_language_app': 'Lingua dell\'app',
      'settings_language_select_title': 'Seleziona lingua',
      'settings_account_email_subtitle': 'Email collegata all\'account',
      'language_italian': 'Italiano',
      'language_english': 'Inglese',
      'language_spanish': 'Spagnolo',
      'language_changed_snackbar': 'Lingua impostata su {language}',
      'logout_button': 'Esci',

      // Validazione
      'validation_insert_email': 'Inserisci la tua email',
      'validation_email_invalid': 'Email non valida',
      'validation_insert_password': 'Inserisci la password',
      'validation_insert_password_register': 'Inserisci una password',
      'validation_min_6_chars': 'Minimo 6 caratteri',
      'validation_confirm_password': 'Conferma la password',
      'validation_passwords_not_match': 'Le password non coincidono',

      // Errori login/registrazione
      'error_login': 'Errore durante il login',
      'error_register': 'Errore durante la registrazione',
      'error_unexpected_login': 'Errore imprevisto durante il login',
      'error_unexpected_register':
      'Errore imprevisto durante la registrazione',
      'error_user_not_found': 'Utente non trovato',
      'error_wrong_password': 'Password errata',
      'error_invalid_email': 'Email non valida',
      'error_email_in_use': 'Questa email è già registrata',
      'error_weak_password': 'La password è troppo debole',
    },
    'en': {
      'app_title': 'Grouply - Team Manager',

      // Login
      'login_title': 'Welcome back!',
      'login_subtitle': 'Sign in to continue',
      'email_label': 'Email',
      'password_label': 'Password',
      'forgot_password': 'Forgot password?',
      'login_button': 'Sign in',
      'login_with_google': 'Sign in with Google',
      'no_account': 'Don\'t have an account?',
      'go_to_register': 'Register',
      'or_label': 'or',
      'google_signin_loading': 'Signing in with Google...',
      'google_signup_loading': 'Signing up with Google...',

      // Register
      'register_title': 'Create an account',
      'register_subtitle': 'Sign up to get started',
      'confirm_password_label': 'Confirm password',
      'register_button': 'Sign up',
      'register_with_google': 'Sign up with Google',
      'registration_success':
      'Registration completed successfully.\nWelcome to the Grouply - Team Manager app',
      'go_to_login_button': 'Go to login page',
      'have_account': 'Already have an account?',

      // Home
      'home_title': 'Home',
      'home_message': 'Welcome to the Grouply - Team Manager home',
      'home_groups_dialog_title': 'Groups',
      'home_groups_create': 'Create new group',
      'home_groups_join': 'Enter an existing group code',
      'home_groups_create_snackbar':
      '“Create new group” feature under development',
      'home_groups_join_snackbar':
      '“Enter group code” feature under development',
      'close_button': 'Close',

      // Settings
      'settings_title': 'Settings',
      'settings_section_theme': 'Theme',
      'settings_change_theme': 'Change theme',
      'settings_theme_dark_active': 'Dark theme is active',
      'settings_theme_light_active': 'Light theme is active',
      'settings_section_account': 'Account',
      'settings_section_profile': 'Profile',
      'settings_profile_manage_title': 'Manage profile',
      'settings_profile_manage_subtitle':
      'Edit name, birthday, role, sport...',
      'settings_section_language': 'Language',
      'settings_language_app': 'App language',
      'settings_language_select_title': 'Select language',
      'settings_account_email_subtitle': 'Email linked to the account',
      'language_italian': 'Italian',
      'language_english': 'English',
      'language_spanish': 'Spanish',
      'language_changed_snackbar': 'Language set to {language}',
      'logout_button': 'Logout',

      // Validation
      'validation_insert_email': 'Enter your email',
      'validation_email_invalid': 'Invalid email',
      'validation_insert_password': 'Enter your password',
      'validation_insert_password_register': 'Enter a password',
      'validation_min_6_chars': 'Minimum 6 characters',
      'validation_confirm_password': 'Confirm your password',
      'validation_passwords_not_match': 'Passwords do not match',

      // Errors
      'error_login': 'Error during login',
      'error_register': 'Error during registration',
      'error_unexpected_login': 'Unexpected error during login',
      'error_unexpected_register': 'Unexpected error during registration',
      'error_user_not_found': 'User not found',
      'error_wrong_password': 'Wrong password',
      'error_invalid_email': 'Invalid email',
      'error_email_in_use': 'This email is already registered',
      'error_weak_password': 'Password is too weak',
    },
    'es': {
      'app_title': 'Grouply - Team Manager',

      // Login
      'login_title': '¡Bienvenido de nuevo!',
      'login_subtitle': 'Inicia sesión para continuar',
      'email_label': 'Correo electrónico',
      'password_label': 'Contraseña',
      'forgot_password': '¿Olvidaste la contraseña?',
      'login_button': 'Iniciar sesión',
      'login_with_google': 'Iniciar con Google',
      'no_account': '¿No tienes una cuenta?',
      'go_to_register': 'Regístrate',
      'or_label': 'o',
      'google_signin_loading': 'Iniciando con Google...',
      'google_signup_loading': 'Registrando con Google...',

      // Register
      'register_title': 'Crea una cuenta',
      'register_subtitle': 'Regístrate para empezar',
      'confirm_password_label': 'Confirmar contraseña',
      'register_button': 'Registrarse',
      'register_with_google': 'Registrarse con Google',
      'registration_success':
      'Registro completado con éxito.\nTe damos la bienvenida a la app Grouply - Team Manager',
      'go_to_login_button':
      'Ir a la página de inicio de sesión',
      'have_account': '¿Ya tienes una cuenta?',

      // Home
      'home_title': 'Inicio',
      'home_message':
      'Bienvenido al inicio de Grouply - Team Manager',
      'home_groups_dialog_title': 'Grupos',
      'home_groups_create': 'Crear nuevo grupo',
      'home_groups_join': 'Introducir el código de un grupo existente',
      'home_groups_create_snackbar':
      'Función "Crear nuevo grupo" en desarrollo',
      'home_groups_join_snackbar':
      'Función "Introducir código de grupo" en desarrollo',
      'close_button': 'Cerrar',

      // Settings
      'settings_title': 'Ajustes',
      'settings_section_theme': 'Tema',
      'settings_change_theme': 'Cambiar tema',
      'settings_theme_dark_active': 'El tema oscuro está activo',
      'settings_theme_light_active': 'El tema claro está activo',
      'settings_section_account': 'Cuenta',
      'settings_section_profile': 'Perfil',
      'settings_profile_manage_title': 'Gestión del perfil',
      'settings_profile_manage_subtitle':
      'Modificar nombre, fecha de nacimiento, rol, deporte...',
      'settings_section_language': 'Idioma',
      'settings_language_app': 'Idioma de la app',
      'settings_language_select_title': 'Selecciona el idioma',
      'settings_account_email_subtitle':
      'Correo vinculado a la cuenta',
      'language_italian': 'Italiano',
      'language_english': 'Inglés',
      'language_spanish': 'Español',
      'language_changed_snackbar':
      'Idioma establecido en {language}',
      'logout_button': 'Salir',

      // Validación
      'validation_insert_email': 'Introduce tu correo',
      'validation_email_invalid': 'Correo inválido',
      'validation_insert_password':
      'Introduce la contraseña',
      'validation_insert_password_register':
      'Introduce una contraseña',
      'validation_min_6_chars': 'Mínimo 6 caracteres',
      'validation_confirm_password':
      'Confirma la contraseña',
      'validation_passwords_not_match':
      'Las contraseñas no coinciden',

      // Errores
      'error_login': 'Error durante el inicio de sesión',
      'error_register': 'Error durante el registro',
      'error_unexpected_login':
      'Error inesperado durante el inicio',
      'error_unexpected_register':
      'Error inesperado durante el registro',
      'error_user_not_found': 'Usuario no encontrado',
      'error_wrong_password': 'Contraseña incorrecta',
      'error_invalid_email': 'Correo inválido',
      'error_email_in_use':
      'Este correo ya está registrado',
      'error_weak_password':
      'La contraseña es demasiado débil',
    },
  };

  String t(String key, {Map<String, String>? params}) {
    final langCode = _localizedValues.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'en';

    String value =
        _localizedValues[langCode]?[key] ?? _localizedValues['en']?[key] ?? key;

    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['it', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
