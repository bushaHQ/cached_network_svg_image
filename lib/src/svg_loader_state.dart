import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract class SvgLoadingState {}

class SvgLoading extends SvgLoadingState {
  final DownloadProgress? progress;
  SvgLoading([this.progress]);
}

class SvgLoaded extends SvgLoadingState {
  final File file;

  SvgLoaded(this.file);
}

class SvgError extends SvgLoadingState {
  final Object error;
  SvgError(this.error);
}
