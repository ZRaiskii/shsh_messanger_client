import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';
import '../../../../core/widgets/new_year/new_year_snowfall.dart';
import '../../../main/presentation/pages/main_page.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_info.dart';
import '../../../settings/data/services/theme_manager.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../core/utils/AppColors.dart';
import 'qr_code_screen.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_blur_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_crop_rotate_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_emoji_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_filter_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_layer_interaction.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_paint_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_sticker_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_text_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_tune_editor.dart';
import 'package:pro_image_editor/core/models/i18n/i18n_various.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({required this.userId, super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    context.read<ProfileBloc>().add(FetchProfileEvent(userId: widget.userId));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPage()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Преобразуем выбранный файл в объект File
      final File imageFile = File(image.path);

      // Показываем редактор фото
      _showPhotoEditor(imageFile);
    }
  }

  void _showPhotoEditor(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.file(
          imageFile,
          configs: ProImageEditorConfigs(
            i18n: I18n(
              layerInteraction: const I18nLayerInteraction(
                remove: 'Удалить',
                edit: 'Редактировать',
                rotateScale: 'Повернуть и масштабировать',
              ),
              paintEditor: const I18nPaintEditor(
                moveAndZoom: 'Масштаб',
                bottomNavigationBarText: 'Рисование',
                freestyle: 'Свободное рисование',
                arrow: 'Стрелка',
                line: 'Линия',
                rectangle: 'Прямоугольник',
                circle: 'Круг',
                dashLine: 'Пунктирная линия',
                blur: 'Размытие',
                pixelate: 'Пикселизация',
                lineWidth: 'Толщина линии',
                eraser: 'Ластик',
                toggleFill: 'Заливка',
                changeOpacity: 'Изменить прозрачность',
                undo: 'Отменить',
                redo: 'Повторить',
                done: 'Готово',
                back: 'Назад',
                smallScreenMoreTooltip: 'Ещё',
              ),
              textEditor: const I18nTextEditor(
                inputHintText: 'Введите текст',
                bottomNavigationBarText: 'Текст',
                back: 'Назад',
                done: 'Готово',
                textAlign: 'Выравнивание текста',
                fontScale: 'Масштаб шрифта',
                backgroundMode: 'Фоновый режим',
                smallScreenMoreTooltip: 'Ещё',
              ),
              cropRotateEditor: const I18nCropRotateEditor(
                bottomNavigationBarText: 'Обрезка/Поворот',
                rotate: 'Повернуть',
                flip: 'Отразить',
                ratio: 'Соотношение сторон',
                back: 'Назад',
                done: 'Готово',
                cancel: 'Отмена',
                undo: 'Отменить',
                redo: 'Повторить',
                smallScreenMoreTooltip: 'Ещё',
                reset: 'Сбросить',
              ),
              tuneEditor: const I18nTuneEditor(
                bottomNavigationBarText: 'Настройки',
                back: 'Назад',
                done: 'Готово',
                brightness: 'Яркость',
                contrast: 'Контраст',
                saturation: 'Насыщенность',
                exposure: 'Экспозиция',
                hue: 'Тон',
                temperature: 'Температура',
                sharpness: 'Резкость',
                fade: 'Затухание',
                luminance: 'Яркость',
                undo: 'Отменить',
                redo: 'Повторить',
              ),
              filterEditor: const I18nFilterEditor(
                bottomNavigationBarText: 'Фильтры',
                back: 'Назад',
                done: 'Готово',
                filters: const I18nFilters(
                  none: 'Без фильтра',
                  addictiveBlue: 'Синий оттенок',
                  addictiveRed: 'Красный оттенок',
                  aden: 'Aden',
                  amaro: 'Amaro',
                  ashby: 'Ashby',
                  brannan: 'Brannan',
                  brooklyn: 'Brooklyn',
                  charmes: 'Charmes',
                  clarendon: 'Clarendon',
                  crema: 'Crema',
                  dogpatch: 'Dogpatch',
                  earlybird: 'Earlybird',
                  f1977: '1977',
                  gingham: 'Gingham',
                  ginza: 'Ginza',
                  hefe: 'Hefe',
                  helena: 'Helena',
                  hudson: 'Hudson',
                  inkwell: 'Inkwell',
                  juno: 'Juno',
                  kelvin: 'Kelvin',
                  lark: 'Lark',
                  loFi: 'Lo-Fi',
                  ludwig: 'Ludwig',
                  maven: 'Maven',
                  mayfair: 'Mayfair',
                  moon: 'Moon',
                  nashville: 'Nashville',
                  perpetua: 'Perpetua',
                  reyes: 'Reyes',
                  rise: 'Rise',
                  sierra: 'Sierra',
                  skyline: 'Skyline',
                  slumber: 'Slumber',
                  stinson: 'Stinson',
                  sutro: 'Sutro',
                  toaster: 'Toaster',
                  valencia: 'Valencia',
                  vesper: 'Vesper',
                  walden: 'Walden',
                  willow: 'Willow',
                  xProII: 'X-Pro II',
                ),
              ),
              blurEditor: const I18nBlurEditor(
                bottomNavigationBarText: 'Размытие',
                back: 'Назад',
                done: 'Готово',
              ),
              emojiEditor: const I18nEmojiEditor(
                bottomNavigationBarText: 'Эмодзи',
                search: 'Поиск',
                categoryRecent: 'Недавние',
                categorySmileys: 'Смайлы и люди',
                categoryAnimals: 'Животные и природа',
                categoryFood: 'Еда и напитки',
                categoryActivities: 'Активности',
                categoryTravel: 'Путешествия и места',
                categoryObjects: 'Объекты',
                categorySymbols: 'Символы',
                categoryFlags: 'Флаги',
              ),
              stickerEditor: const I18nStickerEditor(
                bottomNavigationBarText: 'Стикеры',
              ),
              various: const I18nVarious(
                loadingDialogMsg: 'Пожалуйста, подождите...',
                closeEditorWarningTitle: 'Закрыть редактор изображений?',
                closeEditorWarningMessage:
                    'Вы уверены, что хотите закрыть редактор изображений? Ваши изменения не будут сохранены.',
                closeEditorWarningConfirmBtn: 'ОК',
                closeEditorWarningCancelBtn: 'Отмена',
              ),
              importStateHistoryMsg: 'Инициализация редактора',
              cancel: 'Отмена',
              undo: 'Отменить',
              redo: 'Повторить',
              done: 'Готово',
              remove: 'Удалить',
              doneLoadingMsg: 'Изменения применяются',
            ),
          ),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              try {
                final tempDir = await getTemporaryDirectory();
                final tempFile = File(
                    '${tempDir.path}/edited_image${DateTime.now().millisecondsSinceEpoch}.png');
                await tempFile.writeAsBytes(bytes);

                // Обрабатываем отредактированное изображение
                _handleEditedImage(tempFile);
              } catch (e) {
                print(e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Произошла ошибка: $e')),
                );
              } finally {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleEditedImage(File editedImageFile) {
    setState(() {
      _selectedImage = editedImageFile;
    });
    print(editedImageFile.path);
    context.read<ProfileBloc>().add(UploadAvatarEvent(
          userId: widget.userId,
          file: editedImageFile,
        ));
  }

  Future<void> _updateEmoji(String emoji) async {
    context.read<ProfileBloc>().add(UpdateEmojiEvent(
          userId: widget.userId,
          emoji: emoji,
        ));
    _fetchProfile();
  }

  Future<void> _updatePremium(bool isPremium) async {
    context.read<ProfileBloc>().add(UpdatePremiumEvent(
          userId: widget.userId,
          isPremium: isPremium,
        ));
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final settingsBloc = BlocProvider.of<SettingsBloc>(context);
    final profileBloc = BlocProvider.of<ProfileBloc>(context);
    final colors = isWhiteNotifier.value
        ? AppColors.light()
        : AppColors.dark(); // Получаем цвета в зависимости от темы

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Профиль',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: colors.textColor, // Используем цвет текста из AppColors
          ),
        ),
        backgroundColor:
            colors.appBarColor, // Используем цвет фона AppBar из AppColors
        iconTheme: IconThemeData(
            color: colors.iconColor), // Используем цвет иконок из AppColors
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            bloc: profileBloc,
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.qr_code, color: colors.iconColor),
                onPressed: () {
                  if (state is ProfileSuccess) {
                    final avatarUrl =
                        state.profile!.avatarUrl; // Извлекаем avatarUrl
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRCodeScreen(
                          userId: state.profile!.id,
                          avatarUrl: avatarUrl,
                          username:
                              state.profile!.username, // Передаем avatarUrl
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Не удалось загрузить аватар')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<SettingsBloc, SettingsState>(
            bloc: settingsBloc,
            builder: (context, state) {
              if (state is SettingsSuccess &&
                  state.settings.snowflakesEnabled) {
                return NewYearSnowfall(
                  isPlaying: false,
                  animationType: "snowflakes",
                  child: Container(),
                );
              } else {
                return Container();
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileInitial) {
                _fetchProfile();
              }
            },
            child: BlocBuilder<ProfileBloc, ProfileState>(
              bloc: profileBloc,
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProfileSuccess) {
                  return ProfileInfo(
                    profile: state.profile!,
                    onPickImage: _pickImage,
                    onUpdateEmoji: _updateEmoji,
                    onUpdatePremium: _updatePremium,
                  );
                } else if (state is ProfileFailure) {
                  return Center(child: Text('Ошибка: ${state.message}'));
                } else {
                  return ProfileInfo(
                    profile: Profile(
                      id: "123456789",
                      username: "traveler123",
                      email: "example@example.com",
                      descriptionOfProfile:
                          "Привет! Я люблю путешествовать и фотографировать природу.",
                      avatarUrl: "https://pixy.org/src2/580/5807568.jpg",
                      active: true,
                      premium: false,
                      shshDeveloper: false,
                      registrationDate: DateTime.now(),
                      lastUpdated: DateTime.now(),
                      gender: null,
                      chatWallpaperUrl: null,
                      premiumExpiresAt: null,
                      nicknameEmoji: '✔️',
                      dateOfBirth: null,
                      isVerifiedEmail: false,
                    ),
                    onPickImage: _pickImage,
                    onUpdateEmoji: _updateEmoji,
                    onUpdatePremium: _updatePremium,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
