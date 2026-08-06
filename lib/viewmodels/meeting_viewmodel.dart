import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';

/// Gère les réunions de l'association active. Référence : §3.4.
class MeetingViewModel extends ChangeNotifier {
  final MeetingService _service;
  StreamSubscription<List<MeetingModel>>? _sub;

  MeetingViewModel(this._service);

  List<MeetingModel> reunions = [];
  bool isLoading = true;
  String? errorMessage;

  /// À appeler à chaque basculement d'association (§3.2.4) pour recharger
  /// les réunions propres à la nouvelle association active.
  void ecouterReunions(String associationId) {
    _sub?.cancel();
    isLoading = true;
    notifyListeners();
    _sub = _service.watchReunions(associationId).listen(
      (data) {
        reunions = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> creerReunion(MeetingModel meeting) async {
    try {
      await _service.creerReunion(meeting);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifierReunion(MeetingModel meeting) async {
    try {
      await _service.modifierReunion(meeting);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerReunion(String meetingId) async {
    try {
      await _service.supprimerReunion(meetingId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> participer(String meetingId, String uid) => _service.participer(meetingId, uid);

  Future<void> marquerPresence(String meetingId, List<String> presents) =>
      _service.marquerPresence(meetingId, presents);

  Future<void> cloturerAvecCompteRendu(String meetingId, String compteRendu) =>
      _service.cloturerAvecCompteRendu(meetingId: meetingId, compteRendu: compteRendu);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}