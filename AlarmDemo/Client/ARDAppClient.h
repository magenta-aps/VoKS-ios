/*
 * libjingle
 * Copyright 2014 Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <Foundation/Foundation.h>

#import "RTCVideoTrack.h"
#import "RTCDataChannel.h"
#import "Message.h"

typedef NS_ENUM(NSInteger, ARDAppClientState) {
  // Disconnected from servers.
  kARDAppClientStateDisconnected,
  // Connecting to servers.
  kARDAppClientStateConnecting,
  // Connected to servers.
  kARDAppClientStateConnected,
};

typedef NS_ENUM(NSInteger, ShelterState) {
  // Not connected with shelter
  kShelterStateDisconnected = -1,
  // Shelter is offline
  kShelterStateOffline,
  // Shelter is online
  kShelterStateOnline
};

typedef NS_ENUM(NSInteger, ShelterCallState) {
  // No active call with shelter
  kShelterCallStateNone,
  // User is calling to shelter
  kShelterCallStateCalling,
  // Shelter answered
  kShelterCallStateAnswered,
  // Shelter put user on hold
  kShelterCallStateOnHold
};

// typedef NS_ENUM(NSInteger, CallButtonState) {
//  kCallButtonStateNone,
//  kCallButtonStateShelterOn,
//  kCallButtonStateConnecting,
//  kCallButtonStateConnected
//};

@class ARDAppClient;
// The delegate is informed of pertinent events and will be called on the
// main queue.
@protocol ARDAppClientDelegate <NSObject>

- (void)appClient:(ARDAppClient *)client
   didChangeState:(ARDAppClientState)state;

- (void)appClient:(ARDAppClient *)client
    didChangeConnectionState:(RTCICEConnectionState)state;

- (void)appClient:(ARDAppClient *)client
    didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack;

- (void)appClient:(ARDAppClient *)client
    didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack;

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error;

- (void)appClient:(ARDAppClient *)client didReceivedMessage:(Message *)message;

- (void)appClient:(ARDAppClient *)client
    didChangeShelterState:(ShelterState)state;

- (void)appClient:(ARDAppClient *)client sendSystemMessage:(NSString *)message;

- (void)appClientDidReceivedAlarmReset:(ARDAppClient *)client;

- (void)appClient:(ARDAppClient *)client
    didReceivedListeningStateChange:(BOOL)state;

- (void)appClientDidResumeCallState:(ARDAppClient *)client;

- (void)appClient:(ARDAppClient *)client
    didReceivedPeerConnectionState:(BOOL)state;
@end

// Handles connections to the AppRTC server for a given room. Methods on this
// class should only be called from the main queue.
@interface ARDAppClient : NSObject

@property(nonatomic, readonly) ARDAppClientState state;
@property(nonatomic, assign) BOOL hasSendDataOffer;
@property(nonatomic, assign) BOOL hasSendMediaOffer;
@property(nonatomic, weak) id<ARDAppClientDelegate> delegate;

// Convenience constructor since all expected use cases will need a delegate
// in order to receive remote tracks.
- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate;

// Establishes a connection with the AppRTC servers for the given room id.
// TODO(tkchin): provide available keys/values for options. This will be used
// for call configurations such as overriding server choice, specifying codecs
// and so on.
- (void)connectToShelter;
// Disconnects from the AppRTC servers and any connected clients.
- (void)disconnect;

//- (void)sendMessageToDataChannel:(NSString *)message;
- (void)resumeVideoStreaming;
- (void)stopVideoStreaming;
- (void)muteRemoteAudioStreaming;
- (void)resumeRemoteAudioStreaming;
- (void)sendChatMessage:(Message *)message;
- (void)sendBatteryLevel:(NSInteger)batteryLevel;
- (void)sendRequestCall:(BOOL)request;
- (void)destroyPeerConnection;
- (void)startPeerConnectionIfReady;

@end
