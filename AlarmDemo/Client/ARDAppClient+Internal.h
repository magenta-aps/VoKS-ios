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

#import "ARDAppClient.h"

#import "ARDRoomServerClient.h"
#import "ARDSignalingChannel.h"
#import "ARDTURNClient.h"
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCAudioTrack.h>
#import "Reachability.h"

@interface ARDAppClient () <
    ARDSignalingChannelDelegate, RTCPeerConnectionDelegate>

// All properties should only be mutated from the main queue.
@property(nonatomic, strong) id<ARDSignalingChannel> channel;
@property(nonatomic, strong) id<ARDTURNClient> turnClient;

@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic, strong) NSMutableArray *outgoingChatMessageQueue;

@property(nonatomic, assign) BOOL isTurnComplete;
@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, readonly) BOOL hasJoinedRoomServerRoom;
@property(nonatomic, assign) BOOL isShelterComplete;

@property(nonatomic, strong) NSString *roomId;
@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, strong) NSMutableArray *iceServers;
@property(nonatomic, strong) NSURL *webSocketURL;
@property(nonatomic, strong) NSURL *webSocketRestURL;
@property(nonatomic, strong) RTCVideoTrack *videoTrack;

@property(nonatomic, strong) RTCAudioTrack *remoteAudioTrack;

@property(nonatomic, assign) ShelterCallState callState;
@property(nonatomic, assign) ShelterState shelterState;

@property(nonatomic, strong)
    RTCMediaConstraints *defaultPeerConnectionConstraints;
@property(nonatomic, readonly) BOOL isLoopback;
@property(nonatomic, readonly) BOOL isAudioOnly;
@property(nonatomic, readonly) BOOL shouldMakeAecDump;
@property(nonatomic, readonly) BOOL shouldUseLevelControl;

@property(nonatomic, assign) BOOL localVideoState;
@property(nonatomic, assign) BOOL peerConnectionState;
@property(nonatomic, assign) BOOL remoteAudioState;
@property(nonatomic, assign) BOOL hasP2PSuccessfulyConnected;
@property(nonatomic, assign) BOOL hasWebSocketSuccessfulyConnected;
@property(nonatomic, assign) BOOL isPeerConnectionClosing;
@property(nonatomic, assign) BOOL isPeerConnectionCreating;
@property(nonatomic, assign) BOOL isICEConnectionClosed;
@property(nonatomic, assign) BOOL isICEConnected;
@property(nonatomic, assign) BOOL isPeerConnectionPendingToClose;
@property(nonatomic, assign) BOOL isMicrophoneAvailable;
@property(nonatomic, assign) BOOL isDisconnecting;
@property(nonatomic, retain) RTCMediaStream *localMediaStream;

// Battery level
@property(nonatomic, assign) NSInteger queuedBatteryLevel;

@property(nonatomic, retain) Reachability *wifiReachability;

- (instancetype)initWithRoomServerClient:(id<ARDRoomServerClient>)rsClient
                        signalingChannel:(id<ARDSignalingChannel>)channel
                              turnClient:(id<ARDTURNClient>)turnClient
                                delegate:(id<ARDAppClientDelegate>)delegate;

@end
