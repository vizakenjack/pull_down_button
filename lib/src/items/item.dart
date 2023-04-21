import 'package:flutter/cupertino.dart';

import '../../pull_down_button.dart';
import '../_internals/animation.dart';
import '../_internals/content_size_category.dart';
import '../_internals/gesture_detector.dart';
import '../_internals/menu_config.dart';
import '../_internals/route.dart';

// Note:
// I am not entirely sure why top and bottom padding values are that much
// different, but only using those values was possible to closely match with
// native counterpart when we have a `PullDownMenuItem.title` long enough to
// overflow to the second row.
const EdgeInsetsDirectional _kItemPadding =
    EdgeInsetsDirectional.only(start: 16, end: 18, top: 10.5, bottom: 11.5);
const EdgeInsetsDirectional _kSelectableItemPadding =
    EdgeInsetsDirectional.only(start: 13, end: 18, top: 10.5, bottom: 11.5);
const EdgeInsetsDirectional _kIconActionPadding = EdgeInsetsDirectional.all(8);

/// Signature used by [PullDownMenuItem] to resolve how [onTap] callback is
/// used.
///
/// Default behavior is to pop the menu and call the [onTap].
///
/// Used by [PullDownMenuItem.tapHandler].
///
/// See also:
///
/// * [PullDownMenuItem.defaultTapHandler], a default tap handler.
/// * [PullDownMenuItem.noPopTapHandler], a tap handler that immediately calls
/// [onTap] without popping the menu.
/// * [PullDownMenuItem.delayedTapHandler], a tap handler that pops the menu,
/// waits for an animation to end and calls the [onTap].
typedef PullDownMenuItemTapHandler = void Function(
  BuildContext context,
  VoidCallback onTap,
);

/// An item in a cupertino style pull-down menu.
///
/// To show a pull-down menu and create a button that shows a pull-down menu
/// use [PullDownButton.buttonBuilder].
///
/// To show a checkmark next to the pull-down menu item (an item with a
/// selection state), consider using [PullDownMenuItem.selectable].
///
/// By default, a [PullDownMenuItem] is a minimum of
/// [kMinInteractiveDimensionCupertino] pixels height.
@immutable
class PullDownMenuItem extends StatelessWidget implements PullDownMenuEntry {
  /// Creates an item for a pull-down menu.
  ///
  /// By default, the item is [enabled].
  const PullDownMenuItem({
    super.key,
    required this.onTap,
    this.tapHandler = defaultTapHandler,
    this.enabled = true,
    required this.title,
    this.icon,
    this.itemTheme,
    this.iconColor,
    this.iconWidget,
    this.isDestructive = false,
  })  : selected = null,
        assert(
          icon == null || iconWidget == null,
          'Please provide either icon or iconWidget',
        );

  /// Creates a selectable item for a pull-down menu.
  ///
  /// By default, the item is [enabled].
  const PullDownMenuItem.selectable({
    super.key,
    required this.onTap,
    this.tapHandler = defaultTapHandler,
    this.enabled = true,
    required this.title,
    this.icon,
    this.itemTheme,
    this.iconColor,
    this.iconWidget,
    this.isDestructive = false,
    this.selected = false,
  }) : assert(
          icon == null || iconWidget == null,
          'Please provide either icon or iconWidget',
        );

  /// The action this item represents.
  ///
  /// To specify how this action is resolved, [tapHandler] is used.
  ///
  /// See also:
  ///
  /// * [defaultTapHandler], a default tap handler.
  /// * [noPopTapHandler], a tap handler that immediately calls [onTap] without
  /// popping the menu.
  /// * [delayedTapHandler], a tap handler that pops the menu, waits for an
  /// animation to end and calls the [onTap].
  final VoidCallback? onTap;

  /// Handler that provides this item's [BuildContext] as well as [onTap] to
  /// resolve how [onTap] callback is used.
  final PullDownMenuItemTapHandler tapHandler;

  /// Whether the user is permitted to tap this item.
  ///
  /// Defaults to true. If this is false, the item will not react to touches,
  /// and item text styles and icon colors will be updated with a lower opacity
  /// to indicate a disabled state.
  final bool enabled;

  /// Title of this [PullDownMenuItem].
  final String title;

  /// Icon of this [PullDownMenuItem].
  ///
  /// If the [iconWidget] is used, this property must be null;
  ///
  /// If used in [PullDownMenuActionsRow], either this or [iconWidget] are
  /// required.
  final IconData? icon;

  /// Theme of this [PullDownMenuItem].
  ///
  /// If this property is null, then [PullDownMenuItemTheme] from
  /// [PullDownButtonTheme.itemTheme] is used.
  ///
  /// If that's null, then defaults from [PullDownMenuItemTheme.defaults] are
  /// used.
  final PullDownMenuItemTheme? itemTheme;

  /// Color for this [PullDownMenuItem]'s [icon].
  ///
  /// If not provided, `textStyle.color` from [itemTheme] will be used.
  ///
  /// If [PullDownMenuItem] `isDestructive`, then [iconColor] will be ignored.
  final Color? iconColor;

  /// Custom icon widget of this [PullDownMenuItem].
  ///
  /// If the [icon] is used, this property must be null;
  ///
  /// If used in [PullDownMenuActionsRow], either this or [icon] is required.
  final Widget? iconWidget;

  /// Whether this item represents destructive action;
  ///
  /// If this is true, then `destructiveColor` from [itemTheme] is used.
  final bool isDestructive;

  /// Whether to display a checkmark next to the menu item.
  ///
  /// Defaults to `null`.
  ///
  /// If [PullDownMenuItem] is used inside [PullDownMenuActionsRow] this
  /// property will be ignored, and a checkmark will not be shown.
  ///
  /// When true, an [PullDownMenuItemTheme.checkmark] checkmark is displayed
  /// (from [itemTheme]).
  ///
  /// If itemTheme is null, then defaults from [PullDownMenuItemTheme.defaults]
  /// are used.
  final bool? selected;

  /// Default tap handler for [PullDownMenuItem].
  ///
  /// The behavior is to pop the menu and then call the [onTap].
  static void defaultTapHandler(BuildContext context, VoidCallback? onTap) {
    // If the menu was opened from [PullDownButton] or [showPullDownMenu] - pop
    // route.
    if (ModalRoute.of(context) is PullDownMenuRoute) {
      Navigator.pop(context, onTap);
    } else {
      noPopTapHandler(context, onTap);
    }
  }

  /// An additional, pre-made tap handler for [PullDownMenuItem].
  ///
  /// The behavior is to pop the menu, wait until the animation ends, and call
  /// the [onTap].
  ///
  /// This might be useful if [onTap] results in action involved with changing
  /// navigation stack (like opening a new screen or showing dialog) so there
  /// is a smoother transition between the pull-down menu and said navigation
  /// stack changing action.
  static void delayedTapHandler(
    BuildContext context,
    VoidCallback? onTap,
  ) {
    // If the menu was opened from [PullDownButton] or [showPullDownMenu] - pop
    // route.
    if (ModalRoute.of(context) is PullDownMenuRoute) {
      Future<void> future() async {
        await Future<void>.delayed(AnimationUtils.kMenuDuration);

        onTap?.call();
      }

      Navigator.pop(context, future);
    } else {
      noPopTapHandler(context, onTap);
    }
  }

  /// An additional, pre-made tap handler for [PullDownMenuItem].
  ///
  /// The behavior is to call the [onTap] without popping the menu.
  static void noPopTapHandler(
    BuildContext _,
    VoidCallback? onTap,
  ) =>
      onTap?.call();

  /// Asserts that an item with sizes [ElementSize.small] or
  /// [ElementSize.medium] has an [icon] or a [iconWidget].
  @protected
  bool _debugActionRowHasIcon(ElementSize size) {
    assert(
      () {
        switch (size) {
          case ElementSize.small:
          case ElementSize.medium:
            return icon != null || iconWidget != null;
          case ElementSize.large:
            return true;
        }
      }(),
      'Either icon or iconWidget should be provided',
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = ActionsRowSizeConfig.of(context);

    assert(_debugActionRowHasIcon(size), '');

    final theme = PullDownMenuItemTheme.resolve(
      context,
      itemTheme: itemTheme,
      enabled: enabled,
      isDestructive: isDestructive,
    );

    final Widget child;

    switch (size) {
      case ElementSize.small:
        child = Padding(
          padding: _kIconActionPadding,
          child: Center(child: iconWidget ?? Icon(icon)),
        );
        break;
      case ElementSize.medium:
        child = _MediumItem(
          icon: iconWidget ?? Icon(icon),
          title: title,
        );
        break;
      case ElementSize.large:
        // Don't do unnecessary checks from inherited widget if [selected] is
        // not null.
        final viewAsSelectable = selected != null || MenuConfig.of(context);

        child = _LargeItem(
          checkmark: viewAsSelectable
              ? _CheckmarkIcon(
                  selected: selected ?? false,
                  checkmark: theme.checkmark!,
                  checkmarkWeight: theme.checkmarkWeight!,
                  checkmarkSize: theme.checkmarkSize!,
                )
              : null,
          title: title,
          icon: icon,
          iconWidget: iconWidget,
        );
        break;
    }

    final style = size == ElementSize.large
        ? theme.textStyle!
        : theme.iconActionTextStyle!;

    final colorIcon =
        !isDestructive && iconColor != null ? iconColor : style.color;

    final hoverTextStyle = theme.onHoverTextStyle!;

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final iconSize = theme.iconSize! * textScaleFactor;

    final isLargeTextScale = TextScaleUtils.isLargeTextScale(textScaleFactor);

    return MergeSemantics(
      child: Semantics(
        enabled: enabled,
        button: true,
        selected: selected,
        child: MenuActionGestureDetector(
          onTap: enabled ? () => tapHandler(context, onTap!) : null,
          pressedColor:
              PullDownMenuDividerTheme.resolve(context).largeDividerColor!,
          hoverColor: theme.onHoverColor!,
          builder: (context, isHovered) {
            var textStyle = style;

            if (isHovered) {
              textStyle = size == ElementSize.large
                  ? hoverTextStyle
                  : hoverTextStyle.copyWith(
                      fontSize: style.fontSize,
                      height: style.height,
                    );
            }

            return IconTheme(
              data: IconThemeData(
                color: isHovered ? hoverTextStyle.color : colorIcon,
                size: iconSize,
              ),
              child: DefaultTextStyle(
                style: textStyle,
                // Seems like for large text scale more lines are allowed.
                maxLines: isLargeTextScale ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// An a [ElementSize.large] menu item.
@immutable
class _LargeItem extends StatelessWidget {
  /// Creates [_LargeItem].
  const _LargeItem({
    required this.checkmark,
    required this.title,
    required this.icon,
    required this.iconWidget,
  });

  final Widget? checkmark;
  final String title;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final minHeight = ElementSize.resolveLarge(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeTextScale = TextScaleUtils.isLargeTextScale(textScaleFactor);

    final isSelectable = checkmark != null;

    return AnimatedMenuContainer(
      alignment: AlignmentDirectional.centerStart,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: isSelectable ? _kSelectableItemPadding : _kItemPadding,
      child: Row(
        children: [
          if (isSelectable)
            AnimatedMenuPadding(
              padding: EdgeInsetsDirectional.only(
                end: 3 * textScaleFactor * (isLargeTextScale ? 2 : 1),
              ),
              child: checkmark,
            ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.start,
            ),
          ),
          if (!isLargeTextScale && (icon != null || iconWidget != null))
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: iconWidget ?? Icon(icon),
            ),
        ],
      ),
    );
  }
}

/// An a [ElementSize.medium] menu item.
@immutable
class _MediumItem extends StatelessWidget {
  /// Creates [_MediumItem].
  const _MediumItem({
    required this.icon,
    required this.title,
  });

  final Widget icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: _kIconActionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      );
}

/// A checkmark widget.
///
/// Replicated the [Icon] logic here to add weight to the checkmark as seen in
/// iOS.
@immutable
class _CheckmarkIcon extends StatelessWidget {
  /// Creates [_CheckmarkIcon].
  const _CheckmarkIcon({
    required this.selected,
    required this.checkmark,
    required this.checkmarkWeight,
    required this.checkmarkSize,
  });

  final IconData checkmark;
  final FontWeight checkmarkWeight;
  final double checkmarkSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return SizedBox.square(dimension: checkmarkSize);
    }

    return SizedBox(
      width: checkmarkSize,
      child: Text.rich(
        TextSpan(
          text: String.fromCharCode(checkmark.codePoint),
          style: TextStyle(
            fontSize: checkmarkSize,
            fontWeight: checkmarkWeight,
            fontFamily: checkmark.fontFamily,
            package: checkmark.fontPackage,
          ),
        ),
      ),
    );
  }
}
