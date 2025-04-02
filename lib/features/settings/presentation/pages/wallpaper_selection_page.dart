import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:pro_image_editor/features/main_editor/main_editor.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/AppColors.dart';
import '../../data/services/theme_manager.dart'; // Добавляем Provider для доступа к isWhiteNotifier

class WallpaperSelectionPage extends StatefulWidget {
  @override
  _WallpaperSelectionPageState createState() => _WallpaperSelectionPageState();
}

class _WallpaperSelectionPageState extends State<WallpaperSelectionPage> {
  final ImagePicker _picker = ImagePicker();
  final ValueNotifier<String?> _selectedAssetNotifier =
      ValueNotifier<String?>(null);
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadSelectedAsset();
  }

  Future<void> _loadSelectedAsset() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedAsset = prefs.getString('selected');
    if (selectedAsset != null) {
      if (selectedAsset.startsWith('/')) {
        _selectedImage = File(selectedAsset);
      }
      _selectedAssetNotifier.value = selectedAsset;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 1080,
      maxWidth: 1920,
    );

    if (pickedFile != null) {
      final File selectedImageFile = File(pickedFile.path);

      _showPhotoEditor(selectedImageFile);
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
                var tempFile =
                    File('${tempDir.path}/edited_image${DateTime.now()}.png');
                if (Platform.isWindows) {
                  tempFile = File(
                      '${tempDir.path}\\edited_image${DateTime.now().millisecondsSinceEpoch}.png');
                }
                await tempFile.writeAsBytes(bytes);

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

    _saveBackgroundImage(editedImageFile.path);
    _saveBackgroundPath(editedImageFile.path);
    _selectedAssetNotifier.value = editedImageFile.path;
  }

  Future<void> _saveBackgroundImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', imagePath);
  }

  Future<void> _saveBackgroundPath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected', imagePath);
  }

  Future<void> _copyAssetAndSave(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    _saveBackgroundImage(file.path);
    _saveBackgroundPath(assetPath);
    setState(() {
      _selectedImage = null;
    });
    _selectedAssetNotifier.value = assetPath;
  }

  Future<void> _clearSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_image');
    await prefs.remove('selected');
    setState(() {
      _selectedImage = null;
    });
    _selectedAssetNotifier.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = isWhiteNotifier.value ? AppColors.light() : AppColors.dark();

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Обои для чатов',
          style: TextStyle(
              color: colors.textColor), // Используем цвет текста из AppColors
        ),
        backgroundColor:
            colors.appBarColor, // Используем цвет фона AppBar из AppColors
        iconTheme: IconThemeData(
            color: colors.iconColor), // Используем цвет иконок из AppColors
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      colors.appBarColor, // Используем цвет фона из AppColors
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: colors
                          .iconColor, // Используем цвет иконки из AppColors
                      size: 24.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Выбрать из галереи',
                      style: TextStyle(
                        color: colors
                            .textColor, // Используем цвет текста из AppColors
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Стандартные обои',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: colors.textColor, // Используем цвет текста из AppColors
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ValueListenableBuilder<String?>(
                valueListenable: _selectedAssetNotifier,
                builder: (context, selectedAsset, child) {
                  return GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    children: [
                      GestureDetector(
                        onTap: _clearSelection,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red, width: 2.0),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 48.0,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedImage != null)
                        GestureDetector(
                          onTap: () {
                            _saveBackgroundImage(_selectedImage!.path);
                            _saveBackgroundPath(_selectedImage!.path);
                            _selectedAssetNotifier.value = _selectedImage!.path;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.backgroundColor.withOpacity(
                                    0.5), // Используем цвет фона из AppColors
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check,
                                  color: colors
                                      .iconColor, // Используем цвет иконки из AppColors
                                  size: 32.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ...List.generate(10, (index) {
                        final assetPath = 'assets/wallpaper_$index.jpg';
                        return GestureDetector(
                          onTap: () {
                            _copyAssetAndSave(assetPath);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: AssetImage(assetPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: selectedAsset == assetPath
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: colors.backgroundColor.withOpacity(
                                          0.5), // Используем цвет фона из AppColors
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        color: colors
                                            .iconColor, // Используем цвет иконки из AppColors
                                        size: 32.0,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
