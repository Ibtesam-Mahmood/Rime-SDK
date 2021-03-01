import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';



class RimeBloc extends Bloc<RimeEvent, RimeState>{
  
  /// Maps the innitial state for the RimeBloc  
  RimeBloc._(RimeState initialState) : super(initialState);

  /// Primary contructor for the RimeBloc singleton
  factory RimeBloc(){
    
    //Binds singleton if not bound
    if(GetIt.I.get<RimeBloc>() == null){
      GetIt.I.registerSingleton<RimeBloc>(RimeBloc._(RimeBloc.initialState));
    }

    return GetIt.I.get<RimeBloc>();

  }

  /// Getter for initial state
  static RimeState get initialState => RimeEmptyState();

  
  @override
  Stream<RimeState> mapEventToState(RimeEvent event) async* {
    if(event is RimeInitEvent){
      yield* _mapInitializeToState(event.userID);
    }
  }

  /// Initiializes the pubnub service and requests channels
  Stream<RimeState> _mapInitializeToState(String userID) async* {

    // Iniitalize rime state

    // Retreive channels by userID

    // Run populate event

  }

  
}