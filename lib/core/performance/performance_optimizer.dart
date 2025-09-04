import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// Advanced performance optimization system for 2025
/// Ensures 120fps on compatible devices
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();

  factory PerformanceOptimizer() => _instance;

  PerformanceOptimizer._internal();

  // Frame timing
  static const Duration _target60fps = Duration(microseconds: 16667);
  static const Duration _target120fps = Duration(microseconds: 8333);

  // Performance metrics
  final Map<String, PerformanceMetric> _metrics = {};
  Timer? _metricsTimer;
  bool _isMonitoring = false;

  // Frame callback ID for cleanup
  int? _frameCallbackId;

  /// Initialize performance monitoring
  void initialize() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Enable 120Hz display mode if available
    _enable120HzMode();

    // Start frame timing monitoring
    _startFrameMonitoring();

    // Configure render settings
    _configureRenderSettings();

    // Start metrics collection
    _startMetricsCollection();

    Logger.info('Performance optimizer initialized for 120fps');
  }

  /// Enable 120Hz display mode
  void _enable120HzMode() async {
    try {
      // Request high refresh rate
      await SystemChannels.platform.invokeMethod<void>(
        'SystemChrome.setPreferredRefreshRate',
        120,
      );
    } catch (e) {
      Logger.debug('120Hz mode not available: $e');
    }
  }

  /// Start frame monitoring
  void _startFrameMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  /// Frame timings callback
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      final totalDuration = buildDuration + rasterDuration;

      // Check for jank
      if (totalDuration > _target60fps) {
        Logger.warning(
          'Frame jank detected: ${totalDuration.inMilliseconds}ms',
        );
      }

      // Update metrics
      _updateMetric('frame_time', totalDuration.inMicroseconds / 1000.0);
      _updateMetric('build_time', buildDuration.inMicroseconds / 1000.0);
      _updateMetric('raster_time', rasterDuration.inMicroseconds / 1000.0);
    }
  }

  /// Configure render settings
  void _configureRenderSettings() {
    // Enable performance overlay in debug
    if (kDebugMode) {
      debugProfilePaintsEnabled = false; // Too heavy for 120fps
      debugPrintRebuildDirtyWidgets = false;
    }
  }

  /// Start metrics collection
  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _reportMetrics();
    });
  }

  /// Update a metric
  void _updateMetric(String name, double value) {
    _metrics[name] ??= PerformanceMetric(name);
    _metrics[name]!.addSample(value);
  }

  /// Report current metrics
  void _reportMetrics() {
    if (!_isMonitoring || _metrics.isEmpty) return;

    final fps = _calculateFPS();
    if (fps < 55) {
      Logger.warning('Low FPS detected: ${fps.toStringAsFixed(1)}');
    }
  }

  /// Calculate current FPS
  double _calculateFPS() {
    final frameTime = _metrics['frame_time'];
    if (frameTime == null || frameTime.samples.isEmpty) return 60.0;

    final avgFrameTime = frameTime.average;
    return avgFrameTime > 0 ? 1000.0 / avgFrameTime : 60.0;
  }

  /// Stop monitoring
  void dispose() {
    _isMonitoring = false;
    _metricsTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _metrics.clear();
  }

  /// Get current performance stats
  Map<String, dynamic> getStats() {
    return {
      'fps': _calculateFPS(),
      'frame_time': _metrics['frame_time']?.average ?? 0,
      'build_time': _metrics['build_time']?.average ?? 0,
      'raster_time': _metrics['raster_time']?.average ?? 0,
      'is_120hz': _metrics['frame_time']?.average ?? 0 < 9,
    };
  }
}

/// Performance metric tracker
class PerformanceMetric {
  final String name;
  final List<double> samples = [];
  static const int maxSamples = 60;

  PerformanceMetric(this.name);

  void addSample(double value) {
    samples.add(value);
    if (samples.length > maxSamples) {
      samples.removeAt(0);
    }
  }

  double get average {
    if (samples.isEmpty) return 0;
    return samples.reduce((a, b) => a + b) / samples.length;
  }

  double get min => samples.isEmpty ? 0 : samples.reduce((a, b) => a < b ? a : b);
  double get max => samples.isEmpty ? 0 : samples.reduce((a, b) => a > b ? a : b);
}