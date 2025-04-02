import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_rustore_billing/flutter_rustore_billing.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/utils/FCMManager.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/services/TokenManager.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/chat/data/services/shared_preferences_singleton.dart';
import 'features/chat/data/services/stomp_client.dart';
import 'features/main/data/datasources/main_local_datasource.dart';
import 'features/main/data/datasources/main_remote_datasource.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/entities/profile.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/domain/usecases/get_profile_usecase.dart';
import 'features/profile/domain/usecases/update_profile_usecase.dart';
import 'features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'features/profile/domain/usecases/delete_avatar_usecase.dart';
import 'features/profile/domain/usecases/update_emoji_usecase.dart';
import 'features/profile/domain/usecases/update_premium_usecase.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/data/services/theme_manager.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/domain/usecases/fetch_settings_usecase.dart';
import 'features/settings/domain/usecases/update_settings_usecase.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/chat/data/services/notification_service.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'package:provider/provider.dart';

import 'core/DownloadProgressProvider.dart';
import 'core/app_settings.dart';
import 'features/version/domain/version_checker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  TokenManager();
  await SharedPreferencesSingleton.init();
  bool isWhite = await ThemeManager.getTheme();
  isWhiteNotifier.value = isWhite;
  await initializeDateFormatting('ru_RU');
  if (Platform.isAndroid) {
    final status = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();

    // await RustoreBillingClient.initialize(
    //     "your_console_app_id",
    //     "com.shsh.messenger",
    //     false,
    //   );

    if (status == GooglePlayServicesAvailability.success) {
      FlutterDownloader.initialize();
      await Firebase.initializeApp();
      await init();
    } else {
      // HuaweiPushService().init();
    }
    if (FlutterDownloader.initialized) {
      FlutterDownloader.registerCallback(downloadCallback);
    }
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  final cachedUser = sharedPreferences.getString('cached_user');

  http.Client client;
  if (!kIsWeb) {
    // Инициализация SecurityContext и IOClient только для не-веб платформ
    final context = SecurityContext(withTrustedRoots: true);
    client = IOClient(
      HttpClient(context: context)
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true,
    );
  } else {
    // Для веб-платформы используем стандартный http.Client
    client = http.Client();
  }

  final authRemoteDataSource = AuthRemoteDataSourceImpl(client: client);
  final authLocalDataSource = AuthLocalDataSourceImpl();
  final mainRemoteDataSource = MainRemoteDataSourceImpl(client: client);
  final mainLocalDataSource =
      MainLocalDataSourceImpl(sharedPreferences: sharedPreferences);
  final profileRemoteDataSource = ProfileRemoteDataSourceImpl(client: client);
  final profileLocalDataSource =
      ProfileLocalDataSourceImpl(sharedPreferences: sharedPreferences);
  final settingsLocalDataSource =
      SettingsLocalDataSourceImpl(sharedPreferences: sharedPreferences);

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );
  final profileRepository = ProfileRepositoryImpl(
    remoteDataSource: profileRemoteDataSource,
    localDataSource: profileLocalDataSource,
  );
  final settingsRepository = SettingsRepositoryImpl(
    localDataSource: settingsLocalDataSource,
  );

  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);
  final getProfileUseCase = GetProfileUseCase(profileRepository);
  final updateProfileUseCase = UpdateProfileUseCase(profileRepository);
  final uploadAvatarUseCase = UploadAvatarUseCase(profileRepository);
  final deleteAvatarUseCase = DeleteAvatarUseCase(profileRepository);
  final updateEmojiUseCase = UpdateEmojiUseCase(profileRepository);
  final updatePremiumUseCase = UpdatePremiumUseCase(profileRepository);
  final fetchSettingsUseCase = FetchSettingsUseCase(settingsRepository);
  final updateSettingsUseCase = UpdateSettingsUseCase(settingsRepository);

  final standardProfile = Profile(
    id: "",
    username: "",
    email: "",
    dateOfBirth: null,
    descriptionOfProfile: "",
    registrationDate: DateTime.now(),
    lastUpdated: DateTime.now(),
    gender: null,
    avatarUrl: "",
    chatWallpaperUrl: null,
    premiumExpiresAt: null,
    nicknameEmoji: null,
    active: false,
    premium: false,
    shshDeveloper: false,
    isVerifiedEmail: false,
  );

  final notificationService = NotificationService();
  final webSocketClientService = WebSocketClientService.instance;

  if (cachedUser != null) {
    final userId =
        UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>).id;
    await webSocketClientService.setUserIdAndConnect(userId);
  }

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  // if (!kIsWeb) {
  //   if (!Platform.isWindows) {
  //     flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //     const initializationSettings = InitializationSettings(
  //       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  //       iOS: DarwinInitializationSettings(),
  //     );
  //     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  //   }
  // }

  await AppSettings.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadProgressProvider()),
      ],
      child: MyApp(
        authBloc: AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          authRepository: authRepository,
          webSocketClientService: webSocketClientService,
        ),
        profileBloc: ProfileBloc(
          getProfileUseCase: getProfileUseCase,
          updateProfileUseCase: updateProfileUseCase,
          uploadAvatarUseCase: uploadAvatarUseCase,
          deleteAvatarUseCase: deleteAvatarUseCase,
          updateEmojiUseCase: updateEmojiUseCase,
          updatePremiumUseCase: updatePremiumUseCase,
        ),
        settingsBloc: SettingsBloc(
          fetchSettingsUseCase: fetchSettingsUseCase,
          updateSettingsUseCase: updateSettingsUseCase,
        ),
        standardProfile: standardProfile,
        notificationService: notificationService,
        flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        initialRoute: cachedUser != null ? '/main' : '/auth',
        isWhite: isWhite,
      ),
    ),
  );
  print(1243);
  await _performCachedAction();
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final ProfileBloc profileBloc;
  final SettingsBloc settingsBloc;
  final Profile standardProfile;
  final NotificationService notificationService;
  final FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  final String initialRoute;
  final bool isWhite;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.profileBloc,
    required this.settingsBloc,
    required this.standardProfile,
    required this.notificationService,
    required this.flutterLocalNotificationsPlugin,
    required this.initialRoute,
    required this.isWhite,
  });

  @override
  Widget build(BuildContext context) {
    final versionChecker = VersionChecker();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => authBloc,
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => profileBloc,
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => settingsBloc,
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SHSH Social',
        theme: isWhite ? ThemeData.light() : ThemeData.dark(),
        scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
        initialRoute: initialRoute,
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final args = settings.arguments as ChatPageArguments;
            return MaterialPageRoute(
              builder: (context) => ChatPage(
                chatId: args.chatId,
                userId: args.userId,
                recipientId: args.recipientId,
              ),
            );
          } else if (settings.name == '/') {
            return MaterialPageRoute(
              builder: (context) => SettingsPage(),
            );
          }
          return null;
        },
        routes: {
          '/main': (context) => MainPage(),
          '/auth': (context) => AuthPage(),
          '/profile': (context) => ProfilePage(userId: standardProfile.id),
          '/settings': (context) => SettingsPage(),
        },
        builder: (context, child) {
          if (!kIsWeb) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
          // Проверка версии при входе
          if (initialRoute == '/main') {
            versionChecker.checkVersionOnStart(context);
            // versionChecker.startVersionCheckTimer(context);
          }
          return child!;
        },
      ),
    );
  }
}

void downloadCallback(String id, int status, int progress) {
  print('ID задачи: $id');
  print('Статус: $status');
  print('Прогресс: $progress%');

  if (status == DownloadTaskStatus.complete.index) {
    print('Загрузка завершена: $id');
  } else if (status == DownloadTaskStatus.failed.index) {
    print('Ошибка загрузки: $id');
  }
}

Future<void> _performCachedAction() async {
  final prefs = await SharedPreferences.getInstance();
  final action = prefs.getString('notification_action');
  final dataString = prefs.getString('notification_data');

  print("action: $action");
  print("dataString: $dataString");

  if (action != null && dataString != null) {
    final data = jsonDecode(dataString);

    await prefs.remove('notification_action');
    await prefs.remove('notification_data');
    switch (action) {
      case 'open_chat':
        final chatId = data['chatId'];
        final senderId = data['senderId'];
        if (navigatorKey.currentContext != null) {
          openChatPage(navigatorKey.currentContext!, chatId, senderId);
        }
        break;

      case 'mark_read':
        // _markMessagesAsRead(data['messageId'], data['chatId']);
        break;

      case 'reply':
        // _sendMessage(data);
        break;

      default:
        print('Unknown action: $action');
        break;
    }
  }
}

class ChatPageArguments {
  final String chatId;
  final String userId;
  final String recipientId;

  ChatPageArguments({
    required this.chatId,
    required this.userId,
    required this.recipientId,
  });
}
