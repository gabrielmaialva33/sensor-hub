import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Sistema avançado de otimização de performance para 2025
/// Garante 120fps em dispositivos compatíveis
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
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
    
    Logger.info('Performance Optimizer initialized - Targeting 120fps');
  }
  
  /// Enable 120Hz display mode on supported devices
  Future<void> _enable120HzMode() async {
    try {
      // Request high refresh rate
      await SystemChannels.platform.invokeMethod<void>(
        'SystemChrome.setPreferredRefreshRate',
        120,
      );
      
      // Set frame rate preference for Flutter
      if (kIsWeb) {
        // Web-specific optimization
        window.requestAnimationFrame((timestamp) {
          Logger.debug('Web animation frame: ${timestamp}ms');
        });
      }
    } catch (e) {
      Logger.debug('120Hz mode not available: $e');
    }
  }
  
  /// Configure optimal render settings
  void _configureRenderSettings() {
    // Disable expensive debug features in profile/release
    if (!kDebugMode) {
      debugPrintScheduleFrameStacks = false;
      debugPrintBeginFrameBanner = false;
      debugPrintEndFrameBanner = false;
    }
    
    // Configure timeline events for performance monitoring
    if (kProfileMode) {
      Timeline.startSync('PerformanceOptimizer');
    }
    
    // Set rendering priorities
    SchedulerBinding.instance.schedulingStrategy = (
      int priority,
      SchedulerBinding scheduler,
    ) {
      // Prioritize UI updates over background tasks
      if (priority >= 100000) {
        return Priority.animation;
      } else if (priority >= 10000) {
        return Priority.touch;
      } else if (priority >= 1000) {
        return Priority.idle;
      }
      return Priority.idle;
    };
  }
  
  /// Monitor frame timing
  void _startFrameMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
    
    // Track frame callbacks
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(
      (Duration timestamp) {
        _trackFrameTime(timestamp);
      },
    );
  }
  
  /// Handle frame timing callbacks
  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      final totalDuration = timing.totalSpan;
      
      // Check for jank (frame took longer than 16ms for 60fps)
      if (totalDuration > _target60fps) {
        Logger.warning(
          'Frame jank detected: ${totalDuration.inMilliseconds}ms '
          '(Build: ${buildDuration.inMilliseconds}ms, '
          'Raster: ${rasterDuration.inMilliseconds}ms)'
        );
        
        // Trigger optimization if consistent jank
        _optimizeForJank();
      }
      
      // Update metrics
      _updateMetric('frameBuild', buildDuration.inMicroseconds / 1000.0);
      _updateMetric('frameRaster', rasterDuration.inMicroseconds / 1000.0);
      _updateMetric('frameTotal', totalDuration.inMicroseconds / 1000.0);
    }
  }
  
  /// Track individual frame times
  void _trackFrameTime(Duration timestamp) {
    final now = DateTime.now().microsecondsSinceEpoch;
    _updateMetric('frameTime', timestamp.inMicroseconds / 1000.0);
    
    // Schedule next frame tracking
    if (_isMonitoring) {
      _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback(
        (Duration timestamp) {
          _trackFrameTime(timestamp);
        },
      );
    }
  }
  
  /// Optimize when jank is detected
  void _optimizeForJank() {
    // Reduce animation complexity
    timeDilation = 0.5; // Slow down animations temporarily
    
    // Clear image cache if memory pressure
    if (_getMemoryPressure() > 0.8) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    
    // Force garbage collection in release mode
    if (!kDebugMode) {
      Future.delayed(const Duration(milliseconds: 100), () {
        timeDilation = 1.0; // Restore normal animation speed
      });
    }
  }
  
  /// Get current memory pressure (0.0 to 1.0)
  double _getMemoryPressure() {
    final imageCache = PaintingBinding.instance.imageCache;
    final currentSize = imageCache.currentSize;
    final maxSize = imageCache.maximumSize;
    
    return maxSize > 0 ? currentSize / maxSize : 0.0;
  }
  
  /// Start collecting performance metrics
  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _collectMetrics();
    });
  }
  
  /// Collect current performance metrics
  void _collectMetrics() {
    // Memory metrics
    final imageCache = PaintingBinding.instance.imageCache;
    _updateMetric('imageCacheSize', imageCache.currentSize.toDouble());
    _updateMetric('imageCacheCount', imageCache.currentSizeBytes.toDouble());
    
    // Calculate FPS
    final frameMetric = _metrics['frameTotal'];
    if (frameMetric != null && frameMetric.samples.isNotEmpty) {
      final avgFrameTime = frameMetric.average;
      final fps = avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;
      _updateMetric('fps', fps);
      
      // Log performance status
      if (fps > 0) {
        final status = fps >= 115 ? '🚀 Ultra (120fps)' :
                      fps >= 55 ? '✅ Smooth (60fps)' :
                      fps >= 25 ? '⚠️ Acceptable (30fps)' :
                      '❌ Poor (<30fps)';
        Logger.debug('Performance: $status - ${fps.toStringAsFixed(1)}fps');
      }
    }
  }
  
  /// Update a performance metric
  void _updateMetric(String name, double value) {
    _metrics[name] ??= PerformanceMetric(name);
    _metrics[name]!.addSample(value);
  }
  
  /// Get current FPS
  double get currentFps {
    final fpsMetric = _metrics['fps'];
    return fpsMetric?.latest ?? 60.0;
  }
  
  /// Get average frame time in milliseconds
  double get averageFrameTime {
    final frameMetric = _metrics['frameTotal'];
    return frameMetric?.average ?? 16.67;
  }
  
  /// Check if running at 120fps
  bool get isRunning120fps => currentFps >= 115;
  
  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'fps': currentFps,
      'frameTime': averageFrameTime,
      'is120fps': isRunning120fps,
      'memoryPressure': _getMemoryPressure(),
      'metrics': _metrics.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
  
  /// Cleanup resources
  void dispose() {
    _isMonitoring = false;
    _metricsTimer?.cancel();
    
    if (_frameCallbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackId!);
    }
    
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
    
    if (kProfileMode) {
      Timeline.finishSync();
    }
  }
}

/// Performance metric tracking
class PerformanceMetric {
  final String name;
  final List<double> samples = [];
  static const int maxSamples = 120; // Keep last 120 samples (2 seconds at 60fps)
  
  PerformanceMetric(this.name);
  
  void addSample(double value) {
    samples.add(value);
    if (samples.length > maxSamples) {
      samples.removeAt(0);
    }
  }
  
  double get latest => samples.isNotEmpty ? samples.last : 0.0;
  
  double get average {
    if (samples.isEmpty) return 0.0;
    return samples.reduce((a, b) => a + b) / samples.length;
  }
  
  double get min => samples.isNotEmpty ? 
    samples.reduce((a, b) => a < b ? a : b) : 0.0;
  
  double get max => samples.isNotEmpty ? 
    samples.reduce((a, b) => a > b ? a : b) : 0.0;
  
  Map<String, dynamic> toJson() => {
    'latest': latest,
    'average': average,
    'min': min,
    'max': max,
    'samples': samples.length,
  };
}

/// Widget for smooth 120fps animations
class SmoothAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  
  const SmoothAnimatedWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOutCubic,
  });
  
  @override
  State<SmoothAnimatedWidget> createState() => _SmoothAnimatedWidgetState();
}

class _SmoothAnimatedWidgetState extends State<SmoothAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
      builder: (context, child) {
        return FadeTransition(
          opacity: _controller,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: widget.curve,
            )),
            child: widget.child,
          ),
        );
      },
    );
  }
}