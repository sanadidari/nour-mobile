import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nour/services/evidence_service.dart';

final syncServiceProvider = NotifierProvider<SyncService, SyncState>(
  () => SyncService(),
);

class SyncState {
  final int pendingCount;
  final bool isSyncing;
  final String? currentDossier;
  final String? lastError;

  SyncState({
    required this.pendingCount,
    this.isSyncing = false,
    this.currentDossier,
    this.lastError,
  });

  SyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    String? currentDossier,
    String? lastError,
  }) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      currentDossier: currentDossier ?? this.currentDossier,
      lastError: lastError ?? this.lastError,
    );
  }
}

class SyncService extends Notifier<SyncState> {
  final _evidenceService = EvidenceService();
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  @override
  SyncState build() {
    // Cleanup quand le provider est dispose
    ref.onDispose(_dispose);
    _init();
    return SyncState(pendingCount: 0);
  }

  void _dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _init() async {
    // 1. Check initial queue & Cleanup storage
    await refreshPendingCount();
    _evidenceService.cleanupOldLocalPhotos();

    // 2. Listen to connectivity
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.ethernet)) {
        syncNow();
      }
    });

    // 3. Initial sync attempt if online
    syncNow();

    // 4. Periodic check every 5 minutes (store ref to cancel later)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncNow(),
    );
  }

  Future<void> refreshPendingCount() async {
    final missions = await _evidenceService.getPendingMissions();
    state = state.copyWith(pendingCount: missions.length);
  }

  Future<void> syncNow() async {
    if (_isProcessing) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none))
      return;

    _isProcessing = true;
    state = state.copyWith(isSyncing: true);

    try {
      final missions = await _evidenceService.getPendingMissions();
      state = state.copyWith(pendingCount: missions.length);

      for (var mission in missions) {
        state = state.copyWith(
          currentDossier: mission.dossierId,
          lastError: null,
        );
        try {
          await _evidenceService.uploadMission(mission);
        } catch (e) {
          // On continue si une mission échoue (elle restera dans la file)
          state = state.copyWith(lastError: e.toString());
        }
        await refreshPendingCount();
      }
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      _isProcessing = false;
      state = state.copyWith(isSyncing: false, currentDossier: null);
    }
  }
}
