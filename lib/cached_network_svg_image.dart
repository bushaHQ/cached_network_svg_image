library cached_network_svg_image;

import 'dart:io';

import 'package:cached_network_svg_image/src/svg_loader.dart';
import 'package:cached_network_svg_image/src/svg_loader_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef ImageWidgetBuilder = Widget Function(BuildContext context, Widget imageProvider);

typedef PlaceholderWidgetBuilder = Widget Function(BuildContext context, String url);

typedef ProgressIndicatorBuilder = Widget Function(BuildContext context, String url, DownloadProgress progress);

typedef LoadingErrorWidgetBuilder = Widget Function(BuildContext context, String url, Object error);

class CachedNetworkSVGImage extends StatefulWidget {
  const CachedNetworkSVGImage({
    Key? key,
    required this.imageUrl,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.cacheManager,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.excludeFromSemantics = false,
    this.semanticsLabel,
    this.theme,
    this.colorFilter,
  }) : super(key: key);

  final String imageUrl;
  final ImageWidgetBuilder? imageBuilder;
  final PlaceholderWidgetBuilder? placeholder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration fadeDuration;
  final Map<String, String>? httpHeaders;
  final BaseCacheManager? cacheManager;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool matchTextDirection;
  final bool allowDrawingOutsideViewBox;
  final bool excludeFromSemantics;
  final String? semanticsLabel;
  final SvgTheme? theme;
  final ColorFilter? colorFilter;

  @override
  State<CachedNetworkSVGImage> createState() => _CachedNetworkSVGImageState();
}

class _CachedNetworkSVGImageState extends State<CachedNetworkSVGImage> with SingleTickerProviderStateMixin {
  late SvgImageLoader _loader;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.fadeDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _loader = SvgImageLoader(
      url: widget.imageUrl,
      cacheManager: widget.cacheManager ?? DefaultCacheManager(),
      cacheKey: widget.cacheKey ?? _generateKeyFromUrl(widget.imageUrl),
      httpHeaders: widget.httpHeaders,
    )..load();
  }

  @override
  void didUpdateWidget(CachedNetworkSVGImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loader.dispose();
      _controller.reset();
      _loader = SvgImageLoader(
        url: widget.imageUrl,
        cacheManager: widget.cacheManager ?? DefaultCacheManager(),
        cacheKey: widget.cacheKey,
        httpHeaders: widget.httpHeaders,
      )..load();
    }
  }

  @override
  void dispose() {
    _loader.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder<SvgLoadingState>(
        valueListenable: _loader,
        builder: (context, state, child) {
          if (state is SvgLoading) {
            return _buildLoadingWidget(state.progress);
          } else if (state is SvgLoaded) {
            if (_controller.status != AnimationStatus.forward && _controller.status != AnimationStatus.completed) {
              _controller.forward();
            }
            return _buildSVGImage(state.file);
          } else if (state is SvgError) {
            return _buildErrorWidget(state.error);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoadingWidget(DownloadProgress? progress) {
    if (widget.progressIndicatorBuilder case final indicator?) {
      return indicator(context, widget.imageUrl, progress ?? const DownloadProgress('url', 0, 0));
    }
    return widget.placeholder?.call(context, widget.imageUrl) ?? const SizedBox();
  }

  Widget _buildErrorWidget(Object error) {
    return widget.errorWidget?.call(context, widget.imageUrl, error) ?? _InternalPlaceHolderError(widget: widget);
  }

  Widget _buildSVGImage(File imageFile) {
    final svgWidget = SvgPicture.file(
      imageFile,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      theme: widget.theme ?? const SvgTheme(),
      colorFilter: widget.colorFilter,
    );

    final animatedWidget = FadeTransition(
      opacity: _animation,
      child: widget.imageBuilder != null ? widget.imageBuilder!(context, svgWidget) : svgWidget,
    );

    return animatedWidget;
  }

  String _generateKeyFromUrl(String url) => url.split('?').first;
}

class _InternalPlaceHolderError extends StatelessWidget {
  const _InternalPlaceHolderError({required this.widget});

  final CachedNetworkSVGImage widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(child: Icon(Icons.error)),
    );
  }
}
