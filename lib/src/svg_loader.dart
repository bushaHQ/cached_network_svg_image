import 'dart:async';

import 'package:cached_network_svg_image/src/svg_loader_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SvgImageLoader extends ValueNotifier<SvgLoadingState> {
  SvgImageLoader({required this.url, required this.cacheManager, this.cacheKey, this.httpHeaders})
    : super(SvgLoading());
    
  final String url;
  final String? cacheKey;
  final Map<String, String>? httpHeaders;
  final BaseCacheManager cacheManager;

  StreamSubscription<FileResponse>? _streamSubscription;

  void load() {
    _streamSubscription?.cancel();
    value = SvgLoading();

    _streamSubscription = cacheManager
        .getFileStream(url, key: cacheKey, withProgress: true, headers: httpHeaders)
        .listen(
          (FileResponse fileResponse) => _setFileResponse(fileResponse),
          onError: (Object error) => value = SvgError(error),
        );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _setFileResponse(FileResponse fileResponse) {
    if (fileResponse is FileInfo) {
      value = SvgLoaded(fileResponse.file);
    } else if (fileResponse is DownloadProgress) {
      value = SvgLoading(fileResponse);
    }
  }
}
