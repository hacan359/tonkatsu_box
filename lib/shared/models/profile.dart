// Модель пользовательского профиля.

import 'dart:convert';

import 'package:flutter/material.dart';

/// Пользовательский профиль с изолированной БД и настройками.
class Profile {
  /// Создаёт [Profile].
  const Profile({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  /// Создаёт [Profile] из JSON.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Уникальный идентификатор (slug или UUID).
  final String id;

  /// Отображаемое имя.
  final String name;

  /// Hex цвет профиля (e.g. '#EF7B44').
  final String color;

  /// Дата создания.
  final DateTime createdAt;

  /// Цвет как [Color].
  Color get colorValue => hexToColor(color);

  /// Конвертирует hex строку (e.g. '#EF7B44') в [Color].
  static Color hexToColor(String hex) {
    final String cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  /// Конвертирует [Color] в hex строку в формате '#RRGGBB'.
  static String colorToHex(Color color) {
    final int rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }

  /// Имя папки профиля.
  String get folderName => id;

  /// Сериализация в JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Создаёт копию с изменёнными полями.
  Profile copyWith({
    String? name,
    String? color,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}

/// Данные всех профилей (profiles.json).
class ProfilesData {
  /// Создаёт [ProfilesData].
  const ProfilesData({
    required this.version,
    required this.currentProfileId,
    required this.profiles,
  });

  /// Создаёт [ProfilesData] из JSON.
  factory ProfilesData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> profilesList = json['profiles'] as List<dynamic>;
    return ProfilesData(
      version: json['version'] as int,
      currentProfileId: json['currentProfileId'] as String,
      profiles: profilesList
          .map((dynamic p) =>
              Profile.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Создаёт [ProfilesData] из JSON строки.
  factory ProfilesData.fromJsonString(String jsonString) {
    return ProfilesData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Дефолтные данные для первого запуска.
  factory ProfilesData.defaultData({String authorName = 'Default'}) {
    return ProfilesData(
      version: 1,
      currentProfileId: 'default',
      profiles: <Profile>[
        Profile(
          id: 'default',
          name: authorName,
          color: '#EF7B44',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  /// Версия формата.
  final int version;

  /// ID текущего активного профиля.
  final String currentProfileId;

  /// Список всех профилей.
  final List<Profile> profiles;

  /// Текущий активный профиль.
  ///
  /// Если [currentProfileId] не найден — возвращает первый профиль.
  Profile get currentProfile => profiles.firstWhere(
        (Profile p) => p.id == currentProfileId,
        orElse: () => profiles.first,
      );

  /// Сериализация в JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'currentProfileId': currentProfileId,
      'profiles':
          profiles.map((Profile p) => p.toJson()).toList(),
    };
  }

  /// Сериализация в JSON строку.
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Создаёт копию с изменёнными полями.
  ProfilesData copyWith({
    String? currentProfileId,
    List<Profile>? profiles,
  }) {
    return ProfilesData(
      version: version,
      currentProfileId: currentProfileId ?? this.currentProfileId,
      profiles: profiles ?? this.profiles,
    );
  }
}

/// Статистика профиля.
class ProfileStats {
  /// Создаёт [ProfileStats].
  const ProfileStats({
    required this.collectionsCount,
    required this.itemsCount,
  });

  /// Пустая статистика.
  static const ProfileStats empty = ProfileStats(
    collectionsCount: 0,
    itemsCount: 0,
  );

  /// Количество коллекций.
  final int collectionsCount;

  /// Количество элементов.
  final int itemsCount;
}

/// Предустановленные цвета для профилей.
abstract final class ProfileColors {
  /// Список доступных цветов.
  static const List<String> values = <String>[
    '#EF7B44', // Brand orange
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];
}
