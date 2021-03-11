# Rime SDK

Rime is a messaging SDK that allows you to more easily integrate the PubNub real-time message system into your application.

## Overview

The goal of this package is to make it easy to implement PubNub's rest API. 

This package helps provide state functionality for PubNub within Flutter application's. This package allows developers
to focus on design rather then Software Requirements when managing chat application's.

The plug and play nature of Rime ensures that the developer does not have to deal with the synchronization of chat data application wide. Rime also formats Pubnub data into user relavent data in the provided models.

#### Authentication and Users
:exclamation::exclamation::exclamation: **IMPORTANT** :exclamation::exclamation::exclamation:
Rime does not provide authentication functionality, that is entirely up to the developer to implement. Rime assumes that each user has a unique userID that can be provided to access a user's Rime account. 

## Installation

To add the state manager to your Dart or Flutter project, add rime as a dependency to your `pubspec.yaml`.
```yaml
dependencies:
    rime: ^0.1.0
```
After adding the dependency to `pubspec.yaml`, run `pub get` command in the root directory of your project.

### Using Git

If you want to use the latest, unreleased version of Rime, add it to your `pubspec.yaml` as a Git package
```yaml
dependencies:
    rime: https://github.com/Ibtesam-Mahmood/Rime-SDK.git
```

## Importing

After installing the Rime package import it in your application.
```dart
import 'package:rime/rime.dart';
```

## Set Up
To sucessfuly integrate rime into your application the following steps must be completed.

#### 1) Generate Pubnub Keyset
Rime requires you to provision thier own Pubnub instance. The SDK adds structure to this instance through its provided functionality.

Start by logging into to the Pubnub admin console at https://www.pubnub.com and sign up to retreive a publish and subscribe keyset.

Create a `.env` file in your root directory (Same directory as `pubspec.yaml`) and copy and paste your publish and subscribe keys there
```
#Pubnub
RIME_PUB_KEY=<Pubnub Publish Key>
RIME_SUB_KEY=<Pubnub Subscribe Key>
```

#### 2) Initialize Rime

Within the `main` of your application, make sure you initialize Rime by passing in the environment variables. This will extract the Pubnub publish and subscribe to store for Rime to connect to a Pubnub instance. Optionally you can pass in any custom functions you want rime to run interally by defining a `RimeDeveloperFunctions` object.
```dart
import 'package:rime/rime.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing');
  await DotEnv.load(fileName: '.env');
  await Rime.initialize(DotEnv.env, RimeDeveloperFunctions(
      //Optional
  ));
  print('Initialized');

  ...
  //run app
}
```

#### 3) Verfying
The following snippet can be run to verify whether `Rime` is initialized.
```dart
print(Rime.INITIALIZED);
```
If this statement is `true` then the rime sdk is correctly set up and can be used.

## Stucture
![Rime Structure](readme_assets/rime_structure.png)
Rime SDK is composed of 3 core elements `RimeApi`, `RimeRepository`, and `RimeBloc`. These 2 work togetehr to provide publish and subscribe functionality fomr pubnub. Along with the management of Rime channel metadata.
### RimeBloc

`RimeBloc` is a Singleton Global State Manager for Rime, it manages application wide buinsess logic for channels; allowing components to directly subscribe to a stream of up-to-date channel data. The RimeBloc acts as the user's primary interface to communicate with Rime and the underlying Pubnub interface safely.

The `RimeBloc` object is an auto-initialized singleton object that is generated using the the [get_it](https://pub.dev/packages/get_it) package. Use the following code to access the object from anywhere in your application.
```dart
RimeBloc();
```
On first access the object is automaically created with a non-initialized state. In this state the `RimeBloc.state` will not contain any channels. It must first be initialized by the developer using a unique userID provided on user authentication.

When initialized the user can push events to the `RimeBloc` to manipulate, create, and leave channels relative the provided UserID. For more information on `RimeEvents` see [Usage](#abcd).

#### flutter_bloc
The `RimeBloc` is implemented using the [flutter_bloc](https://pub.dev/packages/flutter_bloc) package. Please refrence their [online documentation](https://pub.dev/documentation/flutter_bloc/latest/) for information on how to correctly interface with RimeBloc using Bloc.

### RimeRepository

`RimeRepository` is a Singleton Storage Module that maintains the core Pubnub service. 

### RimeApi


## Usage

### Intialize RimeBloc

Upon authentication
```dart
RimeBloc().add(InitializeRime('userID'));
```

### Get Channels

Get the most recent channels in chronological order.
```dart
RimeBloc().add(GetChannelsEvent());
```

### Create Channel

Create an indidual channel by channel id and list of UserID's
```dart
RimeBloc().add(CreateChannelEvent(RimeChannel(), users: ['user1', 'user2'], onSuccess: (channel){}));
```

### Send Message

Send a message through a channel corresponding to a channel id.
```dart
RimeBloc().add(MessageEvent('ChannelID', TextMessage.RIME_MESSAGE_TYPE, TextMessage.toPayload('Hello world')));
```

### Delete channel
Delete a channel from the state corresponding to a channel id. Will only delete for the corresponding userID which intialized Rime.
```dart
RimeBloc().add(DeleteEvent('ChannelID'));
```

### Leave channel
Leave a channel corresponds to a userID and will delete the channel from the state. Will only delete for the corresponding userID which intialized Rime.
```dart
RimeBloc().add(LeaveEvent('ChannelID'));
```

### Store channel
Store a channel inside `RimeBloc()`, this will only store the channel onto the front-end of your application. There is no PubNub API call in this event.
```dart
RimeBloc().add(StoreEvent(RimeChannel()));
```

### Intialize Channel Widget

Create first instance of a channel room by using the widget `ChannelStateProvider.dart`.
```dart
ChannelStateProvider(
    channelID: 'ChannelID',
    controller: ChannelProviderController(),
    builder: (context, channel, messages){
        return Container();
    }
)
```

### Retrieve Channels

Retrieve a list of chronologically ordered channels based off the last message sent from PubNub.
```dart
RimeLiveState liveState = state as RimeLiveState;

List<RimeChannel> channels = liveState.orgainizedChannels.map<RimeChannel>((channel){
    return liveState.storedChannels[channel];
}).toList();
```

###### 





This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
