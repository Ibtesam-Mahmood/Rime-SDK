import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:rime/api/rime_api.dart';
import 'package:rime/model/channel.dart';
import 'package:rime/state/RimeRepository.dart';
import 'package:rime/state/rime_bloc/rime_bloc_events.dart';
import 'package:rime/state/rime_bloc/rime_bloc_state.dart';



class RimeBloc extends Bloc<RimeEvent, RimeState>{

  /// Instance of rime that connects to the microservices
  final RimeRepository rime;
  
  /// Maps the innitial state for the RimeBloc  
  RimeBloc._(RimeState initialState) 
    : rime = RimeRepository(), super(initialState);

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
    else if(event is CreateChannelEvent){
      yield* _mapCreateChannelToState(event.channel, event.onSuccess);
    }
    else if(event is MessageEvent){
      yield* _mapMessageToState(event.message, event.channel);
    }
    else if(event is DeleteEvent){
      yield* _mapDeleteToState(event.channel);
    }
    else if(event is LeaveEvent){
      yield* _mapLeaveToState(event.channel);
    }
    else if(event is StoreEvent){
      yield* _mapStoreToState(event.channel);
    }
    else if(event is InitChannelEvent){
      yield* _mapInitChannelToState(event.channel);
    }
    else if(event is ClearRimeEvent){
      yield* _mapClearToState();
    }

    


  }

  /// Initializes the pubnub service and requests channels
  Stream<RimeState> _mapInitializeToState(String userID) async* {

    // Initialize rime state
    rime.initializeRime(userID);

    // Retreive channels by userID
    List<RimeChannel> channels = await RimeApi.getChannels(userID);
 

  }

  Stream<RimeState> _mapInitChannelToState(RimeChannel channel) async* {
    
  }

  Stream<RimeState> _mapCreateChannelToState(RimeChannel channel, Function(RimeChannel) onSuccess) async* {
    
  }
  
  Stream<RimeState> _mapMessageToState(BaseMessage message, String channel) async* {
    
  }

  Stream<RimeState> _mapDeleteToState(String channel) async* {

  }

  Stream<RimeState> _mapLeaveToState(String channel) async* {

  }

  Stream<RimeState> _mapStoreToState(RimeChannel channel) async* {

  }

  Stream<RimeState> _mapClearToState() async* {

  }


}