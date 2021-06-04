import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

//Enums
import '../enums/theater_type_enum.dart';

//Models
import '../models/seat_model.dart';
import '../models/theater_model.dart';
import '../models/show_seating_model.dart';

//Services
import '../services/repositories/theaters_repository.dart';

//Providers
import 'shows_provider.dart';
import 'all_providers.dart';

final selectedTheaterNameProvider = StateProvider<String>((_)=>"");

final showSeatingFuture = FutureProvider<ShowSeatingModel>((ref) async {
  final _selectedShowTime = ref.watch(selectedShowTimeProvider).state;

  final _theatersProvider = ref.read(theatersProvider);
  final _theaterId = _selectedShowTime.theaterId;
  final theater = await _theatersProvider.getTheaterById(theaterId: _theaterId);

  final _bookingsProvider = ref.watch(bookingsProvider);
  final _showId = _selectedShowTime.showId;
  final bookedSeats = await _bookingsProvider.getShowBookedSeats(showId: _showId);

  ref.read(selectedTheaterNameProvider).state = theater.theaterName;

  return ShowSeatingModel(
    showTime: _selectedShowTime,
    theater: theater,
    bookedSeats: bookedSeats,
  );
});

// ignore: prefer_mixin
class TheatersProvider with ChangeNotifier {
  final TheatersRepository _theatersRepository;

  final List<SeatModel> _selectedSeats = [];

  UnmodifiableListView<SeatModel> get selectedSeats => UnmodifiableListView<SeatModel>(_selectedSeats);

  List<String> get selectedSeatNames {
    return _selectedSeats.map((seat)=>"${seat.seatRow}-${seat.seatNumber}").toList();
  }

  TheatersProvider(this._theatersRepository);

  void toggleSeat({required SeatModel seat, required bool select}){
    if(select) {
      _selectedSeats.add(seat);
    } else {
      _selectedSeats.remove(seat);
    }
    print(_selectedSeats);
    notifyListeners();
  }

  void clearSelectedSeats() => _selectedSeats.clear();

  Future<List<TheaterModel>> getAllTheaters({
    TheaterType? theaterType,
  }) async {
    final Map<String, String>? queryParams = {
      if (theaterType != null) "theater_type": theaterType.toJson,
    };
    return await _theatersRepository.fetchAll(queryParameters: queryParams);
  }

  Future<TheaterModel> getTheaterById({
    required int theaterId,
  }) async {
    return await _theatersRepository.fetchOne(theaterId: theaterId);
  }

  Future<TheaterModel> uploadNewTheater({
    required String theaterName,
    required int numOfRows,
    required int seatsPerRow,
    required TheaterType theaterType,
    required List<SeatModel> missing,
    required List<SeatModel> blocked,
  }) async {
    final theater = TheaterModel(
      theaterId: null,
      theaterName: theaterName,
      numOfRows: numOfRows,
      seatsPerRow: seatsPerRow,
      theaterType: theaterType,
      missing: missing,
      blocked: blocked,
    );
    final theaterId = await _theatersRepository.create(data: theater.toJson());

    return theater.copyWith(theaterId: theaterId);
  }

  Future<String> editTheater({
    required TheaterModel theater,
    String? theaterName,
    int? numOfRows,
    int? seatsPerRow,
    TheaterType? theaterType,
    List<SeatModel>? missing,
    List<SeatModel>? blocked,
  }) async {
    final data = theater.toUpdateJson(
      theaterName: theaterName,
      numOfRows: numOfRows,
      seatsPerRow: seatsPerRow,
      theaterType: theaterType,
      missing: missing,
      blocked: blocked,
    );
    if (data.isEmpty) return "Nothing to update!";
    return await _theatersRepository.update(
        theaterId: theater.theaterId!, data: data);
  }

  Future<String> removeTheater({
    required int theaterId,
  }) async {
    return await _theatersRepository.delete(theaterId: theaterId);
  }

  void cancelNetworkRequest() {
    _theatersRepository.cancelRequests();
  }
}
