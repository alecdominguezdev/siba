import 'package:flutter/material.dart';

import '../theme/siba_theme.dart';
import '../models/mobile_models.dart';

class SibaLogo extends StatelessWidget {
  final double width;
  final bool white;
  const SibaLogo({super.key, this.width = 72, this.white = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/siba_simbolo.png',
      width: width,
      height: width,
      fit: BoxFit.contain,
      semanticLabel: 'SIBA',
    );
  }
}

class SibaAnimatedEntry extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const SibaAnimatedEntry({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 12,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 330 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offsetY),
          child: Transform.scale(
            scale: .985 + (.015 * value),
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

class SibaSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SibaSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class SibaBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? foreground;
  final Color? background;

  const SibaBadge({
    super.key,
    required this.label,
    this.icon,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? SibaColors.primaryDark;
    final bg = background ?? SibaColors.primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class SibaSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const SibaSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = SibaColors.surface,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: SibaColors.line),
        ),
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      );
}

class SibaIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const SibaIconTile({
    super.key,
    required this.icon,
    this.color = SibaColors.primary,
    this.background = SibaColors.primarySoft,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: size * .47),
      );
}

class SibaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool error;

  const SibaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) => SibaSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SibaIconTile(
              icon: icon,
              color: error ? SibaColors.danger : SibaColors.primary,
              background: error ? SibaColors.dangerSoft : SibaColors.primarySoft,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      );
}

class SibaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? helper;
  final Color? accent;

  const SibaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? SibaColors.primary;
    return SibaSurface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SibaIconTile(
            icon: icon,
            color: color,
            background: color.withOpacity(.10),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          if ((helper ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(helper!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class SibaSkeleton extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;

  const SibaSkeleton({
    super.key,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<SibaSkeleton> createState() => _SibaSkeletonState();
}

class _SibaSkeletonState extends State<SibaSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFE9EDEF), const Color(0xFFF7F8F8), _controller.value),
            borderRadius: widget.borderRadius,
          ),
        ),
      );
}

class SibaProjectTile extends StatelessWidget {
 final SibaProject project;final VoidCallback onTap;
 const SibaProjectTile({super.key,required this.project,required this.onTap});
 @override Widget build(BuildContext context){
  final progress=project.lastProgress?.clamp(0,100).toDouble();
  return SibaSurface(onTap:onTap,padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Expanded(child:Text(project.folio.isEmpty?'Proyecto #${project.id}':project.folio,style:const TextStyle(color:SibaColors.primary,fontWeight:FontWeight.w700,fontSize:12))),const Icon(Icons.arrow_forward_rounded,size:18,color:SibaColors.muted)]),
   const SizedBox(height:10),Text(project.title.isEmpty?'Sin nombre':project.title,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleMedium),
   if(project.company.isNotEmpty)...[const SizedBox(height:6),Text(project.company,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall)],const SizedBox(height:14),
   Row(children:[Expanded(child:Text(project.status.isNotEmpty?project.status:project.state,style:Theme.of(context).textTheme.bodySmall,maxLines:1,overflow:TextOverflow.ellipsis)),const SizedBox(width:12),Text(progress==null?'Sin informe':'${progress.toStringAsFixed(0)}%',style:const TextStyle(fontWeight:FontWeight.w700,color:SibaColors.primary))]),
   if(progress!=null)...[const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:progress/100,minHeight:5,backgroundColor:SibaColors.primarySoft))],
  ]));
 }
}
