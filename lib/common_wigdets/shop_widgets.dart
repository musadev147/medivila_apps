import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';
import '../helpers/format_utils.dart';
import 'custom_image_view.dart';
import 'state_view.dart';

/// Network image with a soft placeholder when the URL is missing.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height, this.radius = 0, this.fit = BoxFit.cover, this.icon});

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon ?? Icons.image_outlined, color: AppColors.primary.withValues(alpha: .35), size: 28),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CustomImageView(
      imagePath: url,
      width: width,
      height: height,
      fit: fit,
      radius: BorderRadius.circular(radius),
    );
  }
}

/// Effective price + struck-through regular price + discount.
class PriceView extends StatelessWidget {
  const PriceView({super.key, required this.price, this.regular, this.size = 15, this.showPercent = false});

  final double price;
  final double? regular;
  final double size;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final off = regular == null ? 0 : discountPercent(price, regular!);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(money(price),
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.2)),
        if (off > 0)
          Text(money(regular),
              style: TextStyle(
                fontSize: size * .78,
                color: AppColors.muted,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.muted,
              )),
        if (off > 0 && showPercent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
            child: Text('-$off%',
                style: TextStyle(fontSize: size * .7, color: AppColors.accent, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 14, this.onChanged});

  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = i + 1;
        final icon = rating >= v
            ? Icons.star_rounded
            : rating >= v - .5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        final star = Icon(icon, size: size, color: rating >= v - .5 ? AppColors.star : AppColors.border);
        if (onChanged == null) return star;
        return GestureDetector(
          onTap: () => onChanged!(v),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: star),
        );
      }),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action = 'See all', this.onAction, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action, style: const TextStyle(fontSize: 13)),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ]),
            ),
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 999, this.compact = false});

  final int value;
  final int min;
  final int max;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = compact ? 30.0 : 38.0;
    Widget btn(IconData i, VoidCallback? f) => InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: s,
            height: s,
            child: Icon(i, size: compact ? 16 : 18, color: f == null ? AppColors.muted : AppColors.text),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.remove_rounded, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: compact ? 28 : 36,
          child: Text('$value',
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        btn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ]),
    );
  }
}

/// Shimmer placeholder block.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFECEEF3),
      highlightColor: const Color(0xFFF8F9FB),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 6, this.sliver = false});
  final int count;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    const delegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .62);
    Widget item(_, _) => Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(8),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Skeleton(height: double.infinity, radius: 12)),
            SizedBox(height: 10),
            Skeleton(height: 12),
            SizedBox(height: 6),
            Skeleton(width: 80, height: 12),
            SizedBox(height: 10),
            Skeleton(width: 60, height: 16),
          ]),
        );
    if (sliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(delegate: SliverChildBuilderDelegate(item, childCount: count), gridDelegate: delegate),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      gridDelegate: delegate,
      itemBuilder: item,
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6, this.height = 92});
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Skeleton(height: height, radius: 16),
    );
  }
}

// ── Status colours (guide §21) ──────────────────────────────────────────────
Color statusColor(String s) {
  switch (s) {
    case 'pending':
    case 'requested':
    case 'unpaid':
    case 'initiated':
      return AppColors.warning;
    case 'confirmed':
    case 'shipped':
    case 'in_transit':
    case 'dispatched':
    case 'booked':
    case 'picked_up':
    case 'escalated':
      return AppColors.info;
    case 'processing':
    case 'approved':
      return AppColors.purple;
    case 'delivered':
    case 'paid':
    case 'received':
    case 'refunded':
    case 'partially_refunded':
      return AppColors.success;
    case 'cancelled':
    case 'rejected':
    case 'suspended':
    case 'failed':
      return AppColors.danger;
    default:
      return AppColors.textSoft;
  }
}

String humanize(String s) =>
    s.isEmpty ? '' : s.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

/// Reuses the shared [StatusChip] with the status palette.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = (label == null || label!.isEmpty) ? humanize(status) : label!;
    return StatusChip(label: text.toUpperCase(), color: statusColor(status));
  }
}

/// White rounded section with optional title.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child, this.padding, this.margin});
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    // A Material (not a decorated Container) so ListTiles / InkWells inside
    // paint their ink on the card instead of behind it.
    return Padding(
      padding: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Row(children: [
                  Expanded(
                      child: Text(title!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                  ?trailing,
                ]),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key, this.bold = false, this.color});
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color ?? (bold ? AppColors.text : AppColors.textSoft),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style.copyWith(color: color ?? AppColors.text)),
      ]),
    );
  }
}

/// Coloured hint banner.
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key, this.color = AppColors.info, this.icon = Icons.info_outline_rounded, this.action, this.onAction});
  final String text;
  final Color color;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!, style: TextStyle(color: color))),
      ]),
    );
  }
}

/// Bottom bar with a primary action, sits above the safe area.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x14101828), blurRadius: 20, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: child,
    );
  }
}

/// Primary button with a busy state.
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon, this.color, this.outlined = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: outlined ? AppColors.primaryText : AppColors.onPrimary))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: color == null ? null : OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color!)),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: color == null ? null : ElevatedButton.styleFrom(backgroundColor: color),
      child: child,
    );
  }
}

/// Live "02d 04:12:09" countdown.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.to, this.light = true, this.onDone});
  final DateTime to;
  final bool light;
  final VoidCallback? onDone;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.to.isBefore(DateTime.now())) {
        _t?.cancel();
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var d = widget.to.difference(DateTime.now());
    if (d.isNegative) d = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    final parts = <String>[
      if (d.inDays > 0) '${d.inDays}d',
      two(d.inHours % 24),
      two(d.inMinutes % 60),
      two(d.inSeconds % 60),
    ];
    final bg = widget.light ? Colors.white : AppColors.text;
    final fg = widget.light ? AppColors.accent : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0 && !parts[i - 1].endsWith('d'))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(':', style: TextStyle(color: widget.light ? Colors.white : AppColors.text, fontWeight: FontWeight.w900)),
            )
          else if (i > 0)
            const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Text(parts[i],
                style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ],
    );
  }
}

/// Generic empty / error message used inside slivers and lists.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.title, this.subtitle, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSoft, height: 1.4)),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            SizedBox(width: 200, child: ElevatedButton(onPressed: onAction, child: Text(action!))),
          ],
        ]),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirm = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message, style: const TextStyle(color: AppColors.textSoft, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSoft))),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm, style: TextStyle(color: danger ? AppColors.danger : AppColors.primary)),
        ),
      ],
    ),
  );
  return r == true;
}
