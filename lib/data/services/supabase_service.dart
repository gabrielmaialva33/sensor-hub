import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_data.dart';
import '../../core/utils/logger.dart';

/// Service for Supabase integration and cloud storage
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  bool _initialized = false;

  // Supabase configuration
  static const String supabaseUrl = 'https://npqfsynpttyxxzrltjke.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wcWZzeW5wdHR5eHh6cmx0amtlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMDMxNjMsImV4cCI6MjA3MjU3OTE2M30.B_7e5AYj_n_U9YNTSQUpfC26HWEeTq-4QYWVO5IldKI';
  
  // Getters
  SupabaseClient get client => _client;
  bool get isInitialized => _initialized;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _initialized = true;
      
      Logger.success('Supabase initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize Supabase', e);
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
  }

  // =============================================================================
  // AUTHENTICATION
  // =============================================================================

  /// Sign in anonymously for device-specific data
  Future<AuthResponse> signInAnonymously() async {
    _ensureInitialized();
    try {
      final response = await _client.auth.signInAnonymously();
      Logger.success('Anonymous authentication successful');
      return response;
    } catch (e) {
      Logger.error('Anonymous authentication failed', e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    _ensureInitialized();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Logger.success('Email authentication successful');
      return response;
    } catch (e) {
      Logger.error('Email authentication failed', e);
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    _ensureInitialized();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      Logger.success('Email signup successful');
      return response;
    } catch (e) {
      Logger.error('Email signup failed', e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _ensureInitialized();
    try {
      await _client.auth.signOut();
      Logger.success('Sign out successful');
    } catch (e) {
      Logger.error('Sign out failed', e);
      rethrow;
    }
  }

  // =============================================================================
  // SENSOR DATA OPERATIONS
  // =============================================================================

  /// Store sensor data batch
  Future<void> storeSensorData(List<SensorData> sensorDataList) async {
    _ensureInitialized();
    if (!isAuthenticated) {
      await signInAnonymously();
    }

    try {
      final deviceId = await _getDeviceId();
      final dataToInsert = sensorDataList.map((data) => {
        ...data.toJson(),
        'user_id': currentUser!.id,
        'device_id': deviceId,
      }).toList();

      await _client.from('sensor_data').insert(dataToInsert);
      
      Logger.success('Stored ${sensorDataList.length} sensor data points');
    } catch (e) {
      Logger.error('Failed to store sensor data', e);
      rethrow;
    }
  }

  /// Get sensor data by type and time range
  Future<List<Map<String, dynamic>>> getSensorData({
    required String sensorType,
    DateTime? startTime,
    DateTime? endTime,
    int? limit = 1000,
  }) async {
    _ensureInitialized();
    if (!isAuthenticated) return [];

    try {
      var query = _client
          .from('sensor_data')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('sensor_type', sensorType);

      if (startTime != null) {
        query = query.gte('timestamp', startTime.toIso8601String());
      }

      if (endTime != null) {
        query = query.lte('timestamp', endTime.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit ?? 1000);
      Logger.success('Retrieved ${response.length} $sensorType data points');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve sensor data', e);
      return [];
    }
  }

  /// Get all sensor data for today
  Future<Map<String, List<Map<String, dynamic>>>> getTodaysSensorData() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = <String, List<Map<String, dynamic>>>{};
    
    // Available sensor types
    const sensorTypes = [
      'accelerometer',
      'gyroscope',
      'magnetometer',
      'location',
      'battery',
      'light',
      'proximity',
    ];

    for (final sensorType in sensorTypes) {
      results[sensorType] = await getSensorData(
        sensorType: sensorType,
        startTime: startOfDay,
        endTime: endOfDay,
      );
    }

    return results;
  }

  // =============================================================================
  // AI INSIGHTS OPERATIONS
  // =============================================================================

  /// Store AI insight
  Future<void> storeAIInsight({
    required String insightType,
    required Map<String, dynamic> insightData,
    required double confidence,
  }) async {
    _ensureInitialized();
    if (!isAuthenticated) {
      await signInAnonymously();
    }

    try {
      await _client.from('ai_insights').insert({
        'user_id': currentUser!.id,
        'device_id': await _getDeviceId(),
        'insight_type': insightType,
        'insight_data': insightData,
        'confidence': confidence,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Logger.success('Stored AI insight: $insightType');
    } catch (e) {
      Logger.error('Failed to store AI insight', e);
      rethrow;
    }
  }

  /// Get recent AI insights
  Future<List<Map<String, dynamic>>> getAIInsights({
    String? insightType,
    int? limit = 50,
  }) async {
    _ensureInitialized();
    if (!isAuthenticated) return [];

    try {
      var query = _client
          .from('ai_insights')
          .select()
          .eq('user_id', currentUser!.id);

      if (insightType != null) {
        query = query.eq('insight_type', insightType);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit ?? 100);
      Logger.success('Retrieved ${response.length} AI insights');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve AI insights', e);
      return [];
    }
  }

  // =============================================================================
  // DEVICE & USER OPERATIONS
  // =============================================================================

  /// Store device information
  Future<void> storeDeviceInfo(Map<String, dynamic> deviceInfo) async {
    _ensureInitialized();
    if (!isAuthenticated) {
      await signInAnonymously();
    }

    try {
      await _client.from('devices').upsert({
        'user_id': currentUser!.id,
        'device_id': await _getDeviceId(),
        'device_info': deviceInfo,
        'last_seen': DateTime.now().toIso8601String(),
      });

      Logger.success('Device info stored/updated');
    } catch (e) {
      Logger.error('Failed to store device info', e);
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    _ensureInitialized();
    if (!isAuthenticated) return {};

    try {
      // Get sensor data counts
      final sensorStats = await _client.rpc('get_user_sensor_stats', params: {
        'user_id_param': currentUser!.id,
      });

      // Get AI insight counts
      final insightStats = await _client.rpc('get_user_insight_stats', params: {
        'user_id_param': currentUser!.id,
      });

      return {
        'sensor_stats': sensorStats,
        'insight_stats': insightStats,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Failed to get user statistics', e);
      return {};
    }
  }

  // =============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // =============================================================================

  /// Subscribe to real-time sensor data updates
  RealtimeChannel subscribeToSensorUpdates({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    _ensureInitialized();

    final channel = _client.channel('sensor_data_changes');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sensor_data',
      callback: (payload) => onInsert(payload.newRecord),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'sensor_data',
      callback: (payload) => onUpdate(payload.newRecord),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'sensor_data',
      callback: (payload) => onDelete(payload.oldRecord),
    );

    channel.subscribe();
    return channel;
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Get device ID (for demo purposes, using a simple approach)
  Future<String> _getDeviceId() async {
    // In a real app, you'd use device_info_plus to get actual device ID
    return 'demo_device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Delete old data based on retention policies
  Future<void> cleanupOldData() async {
    _ensureInitialized();
    if (!isAuthenticated) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await _client
          .from('sensor_data')
          .delete()
          .eq('user_id', currentUser!.id)
          .lt('timestamp', thirtyDaysAgo.toIso8601String());

      Logger.success('Old sensor data cleaned up');
    } catch (e) {
      Logger.error('Failed to cleanup old data', e);
    }
  }

  /// Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      _ensureInitialized();
      
      // Try a simple query
      await _client.from('sensor_data').select('id').limit(1);
      Logger.success('Supabase connection test successful');
      return true;
    } catch (e) {
      Logger.error('Supabase connection test failed', e);
      return false;
    }
  }

  /// Get current storage usage
  Future<Map<String, int>> getStorageUsage() async {
    _ensureInitialized();
    if (!isAuthenticated) return {};

    try {
      final result = await _client.rpc('get_user_storage_usage', params: {
        'user_id_param': currentUser!.id,
      });

      return Map<String, int>.from(result);
    } catch (e) {
      Logger.error('Failed to get storage usage', e);
      return {};
    }
  }
}