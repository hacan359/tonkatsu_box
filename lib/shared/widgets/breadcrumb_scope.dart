// Scope для накопления хлебных крошек вверх по дереву виджетов.

import 'package:flutter/widgets.dart';

/// Scope для накопления хлебных крошек вверх по дереву.
///
/// Каждый экран оборачивает своё содержимое в [BreadcrumbScope],
/// добавляя свою крошку. [AutoBreadcrumbAppBar] собирает все крошки
/// из цепочки scope'ов автоматически.
///
/// Tab root scope устанавливается в `NavigationShell._buildTabNavigator()`
/// выше `Navigator`, чтобы все routes внутри таба видели его.
///
/// Для pushed routes промежуточные scope'ы устанавливаются
/// в `MaterialPageRoute.builder` при push:
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => BreadcrumbScope(
///     label: 'Debug',           // label текущего экрана
///     child: ChildScreen(),
///   ),
/// ));
/// ```
class BreadcrumbScope extends InheritedWidget {
  /// Создаёт [BreadcrumbScope] с заданным label.
  const BreadcrumbScope({
    super.key,
    required this.label,
    required super.child,
  });

  /// Текст крошки текущего экрана.
  final String label;

  /// Собирает все крошки от корня до текущего scope.
  ///
  /// Обходит ancestor tree вверх, собирая все [BreadcrumbScope].label.
  /// Регистрирует зависимость от ближайшего scope для rebuild
  /// при изменении label (например, loading → loaded).
  static List<String> of(BuildContext context) {
    // Регистрируем зависимость от ближайшего scope для автоматического
    // rebuild при updateShouldNotify (loading '...' → loaded 'Item Name').
    context.dependOnInheritedWidgetOfExactType<BreadcrumbScope>();

    final List<String> crumbs = <String>[];
    context.visitAncestorElements((Element element) {
      if (element.widget is BreadcrumbScope) {
        crumbs.insert(0, (element.widget as BreadcrumbScope).label);
      }
      return true; // продолжать вверх
    });
    return crumbs;
  }

  @override
  bool updateShouldNotify(BreadcrumbScope oldWidget) {
    return label != oldWidget.label;
  }
}
