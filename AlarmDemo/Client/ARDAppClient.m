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

#import "ARDAppClient+Internal.h"

#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCAVFoundationVideoSource.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCRtpSender.h>
#import <WebRTC/RTCTracing.h>
#import <WebRTC/RTCFileLogger.h>

#import "ARDTURNClient+Internal.h"
#import "ARDMessageResponse.h"
#import "ARDSDPUtils.h"
#import "ARDSignalingMessage.h"
#import "ARDWebSocketChannel.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

#import "Utils.h"
#import "AppLogger.h"
#import <AVFoundation/AVFoundation.h>
#import "ARDSettingsModel.h"

static NSString * const kARDIceServerRequestUrl = @"https://appr.tc/params";

static NSString *const kARDAppClientErrorDomain = @"ARDAppClient";
static NSInteger const kARDAppClientErrorUnknown = -1;
// static NSInteger kARDAppClientErrorRoomFull = -2;
static NSInteger const kARDAppClientErrorCreateSDP = -3;
static NSInteger const kARDAppClientErrorSetSDP = -4;
static NSInteger const kARDAppClientErrorInvalidClient = -5;
static NSInteger const kARDAppClientErrorInvalidRoom = -6;

static NSString * const kARDMediaStreamId = @"ARDAMS";
static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";
static NSString * const kARDVideoTrackKind = @"video";

// TODO(tkchin): Add these as UI options.
static BOOL const kARDAppClientEnableTracing = NO;
static BOOL const kARDAppClientEnableRtcEventLog = YES;
static int64_t const kARDAppClientAecDumpMaxSizeInBytes = 5e6;  // 5 MB.
static int64_t const kARDAppClientRtcEventLogMaxSizeInBytes = 5e6;  // 5 MB.
static int const kKbpsMultiplier = 1000;

// We need a proxy to NSTimer because it causes a strong retain cycle. When
// using the proxy, |invalidate| must be called before it properly deallocs.
@interface ARDTimerProxy : NSObject

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                    timerHandler:(void (^)(void))timerHandler;
- (void)invalidate;

@end

@implementation ARDTimerProxy {
    NSTimer *_timer;
    void (^_timerHandler)(void);
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                    timerHandler:(void (^)(void))timerHandler {
    NSParameterAssert(timerHandler);
    if (self = [super init]) {
        _timerHandler = timerHandler;
        _timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                  target:self
                                                selector:@selector(timerDidFire:)
                                                userInfo:nil
                                                 repeats:repeats];
    }
    return self;
}

- (void)invalidate {
    [_timer invalidate];
}

- (void)timerDidFire:(NSTimer *)timer {
    _timerHandler();
}

@end

@implementation ARDAppClient {
    RTCFileLogger *_fileLogger;
    ARDTimerProxy *_statsTimer;
    RTCMediaConstraints *_cameraConstraints;
    NSNumber *_maxBitrate;
}

@synthesize delegate = _delegate;
@synthesize state = _state;
//@synthesize roomServerClient = _roomServerClient;
@synthesize channel = _channel;
@synthesize turnClient = _turnClient;
@synthesize peerConnection = _peerConnection;
@synthesize factory = _factory;
@synthesize messageQueue = _messageQueue;
@synthesize isTurnComplete = _isTurnComplete;
@synthesize isShelterComplete = _isShelterComplete;
@synthesize hasReceivedSdp = _hasReceivedSdp;
@synthesize roomId = _roomId;
@synthesize clientId = _clientId;
@synthesize iceServers = _iceServers;
@synthesize webSocketURL = _websocketURL;
@synthesize webSocketRestURL = _websocketRestURL;
@synthesize videoTrack = _videoTrack;
@synthesize callState = _callState;
@synthesize remoteAudioTrack = _remoteAudioTrack;
@synthesize shelterState = _shelterState;
@synthesize localVideoState = _videoState;
@synthesize remoteAudioState = _remoteAudioState;
@synthesize peerConnectionState = _peerConnectionState;
@synthesize wifiReachability = _wifiReachability;
@synthesize localMediaStream = _localMediaStream;

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate {
  if (self = [super init]) {
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"initWithDelegate"]];
    _delegate = delegate;
      NSURL *turnRequestURL = [NSURL URLWithString:kARDIceServerRequestUrl];
      _turnClient = [[ARDTURNClient alloc] initWithURL:turnRequestURL];

    [self configure];
  }
  return self;
}

// TODO(tkchin): Provide signaling channel factory interface so we can recreate
// channel if we need to on network failure. Also, make this the default public
// constructor.
- (instancetype)initWithRoomServerClient:(id<ARDRoomServerClient>)rsClient
                        signalingChannel:(id<ARDSignalingChannel>)channel
                              turnClient:(id<ARDTURNClient>)turnClient
                                delegate:(id<ARDAppClientDelegate>)delegate {
  NSParameterAssert(rsClient);
  NSParameterAssert(channel);
  NSParameterAssert(turnClient);
  if (self = [super init]) {
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"initWithRoomServerClient:"
                           @"signalingChannel:turnClient:" @"delegate"]];
    //    _roomServerClient = rsClient;
    _channel = channel;
    _turnClient = turnClient;
    _delegate = delegate;
    [self configure];
  }
  return self;
}

- (void)configure {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"configure"]];
  _factory = [[RTCPeerConnectionFactory alloc] init];
  _messageQueue = [NSMutableArray array];
  _iceServers = [NSMutableArray array];
  _shelterState = kShelterStateDisconnected;
  _roomId = [[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"];
  _clientId = [Utils deviceUID];

  _websocketURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults]
                                           stringForKey:@"ws_url"]];
  _websocketRestURL = _websocketURL;
  _isICEConnectionClosed = YES;
  _isMicrophoneAvailable = YES;
    
    _factory = [[RTCPeerConnectionFactory alloc] init];
    _messageQueue = [NSMutableArray array];
    _iceServers = [NSMutableArray array];
    _fileLogger = [[RTCFileLogger alloc] init];
    [_fileLogger start];
    
    ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
    RTCMediaConstraints *cameraConstraints = [[RTCMediaConstraints alloc]
                                              initWithMandatoryConstraints:nil
                                              optionalConstraints:[settingsModel
                                                                   currentMediaConstraintFromStoreAsRTCDictionary]];
    [self setMaxBitrate:[settingsModel currentMaxBitrateSettingFromStore]];
    [self setCameraConstraints:cameraConstraints];


  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(microphoneInterruption:)
             name:AVAudioSessionInterruptionNotification
           object:nil];

  [self connectToShelter];
}

- (void)dealloc {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:[NSString stringWithFormat:@"dealloc"]];
  _delegate = nil;
  _channel = nil;
  _localMediaStream = nil;
  _clientId = nil;
  _roomId = nil;
  _websocketURL = nil;
  _websocketRestURL = nil;
  _messageQueue = nil;
  _outgoingChatMessageQueue = nil;
  _iceServers = nil;

  _turnClient = nil;

  //[self disconnect];
}

- (void)setState:(ARDAppClientState)state {
  if (_state == state) {
    return;
  }
  _state = state;
  [_delegate appClient:self didChangeState:_state];
}

- (void) connectToShelter {
    _isLoopback = NO;
    _isAudioOnly = NO;
    _shouldMakeAecDump = NO;
    _shouldUseLevelControl = NO;
    
#if defined(WEBRTC_IOS)
    if (kARDAppClientEnableTracing) {
        NSString *filePath = [self documentsFilePathForFileName:@"webrtc-trace.txt"];
        RTCStartInternalCapture(filePath);
    }
#endif
    
    // Request TURN.
    __weak ARDAppClient *weakSelf = self;
    [_turnClient requestServersWithCompletionHandler:^(NSArray *turnServers,
                                                       NSError *error) {
        if (error) {
            [[AppLogger sharedInstance]
             logClass:NSStringFromClass([self class])
             message:[NSString stringWithFormat:@"Error retrieving TURN servers: %@",
                      error.localizedDescription]];
        }
        ARDAppClient *strongSelf = weakSelf;
        [strongSelf.iceServers addObjectsFromArray:turnServers];
        strongSelf.isTurnComplete = YES;
        if ([self canCreatePeerConnection]) {
            [strongSelf startSignalingIfReady];
        }
    }];
    
    [self registerWithColliderIfReady];
    
}


- (void)disconnect {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"disconnect"]];
  if (_state == kARDAppClientStateDisconnected) {
    return;
  }

  [self destroyPeerConnection];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _channel = nil;

  self.state = kARDAppClientStateDisconnected;
}

- (void)setCameraConstraints:(RTCMediaConstraints *)mediaConstraints {
    _cameraConstraints = mediaConstraints;
}

- (void)setMaxBitrate:(NSNumber *)maxBitrate {
    _maxBitrate = maxBitrate;
}

#pragma mark - ARDSignalingChannelDelegate

- (void)channel:(id<ARDSignalingChannel>)channel
    didReceiveMessage:(ARDSignalingMessage *)message {
    if (!message){
        return;
    }
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"channel:didReceiveMessage type: %i",
                                          message.type]];
  switch (message.type) {
  case kARDSignalingMessageTypeOffer:
  case kARDSignalingMessageTypeAnswer:
    // Offers and answers must be processed before any other message, so we
    // place them at the front of the queue.
    _hasReceivedSdp = YES;
    [_messageQueue insertObject:message atIndex:0];
    break;
  case kARDSignalingMessageTypeCandidate:
    [_messageQueue addObject:message];
    break;

  case kARDSignalingMessageTypeShelterStatus:
    _isShelterComplete = YES;
  case kARDSignalingMessageTypeAlarmReset:
  case kARDSignalingMessageTypeBye:
  case kARDSignalingMessageTypeMessages:
  case kARDSignalingMessageTypeCallState:
  case kARDSignalingMessageTypeRequestCall:
  case kARDSignalingMessageTypeVideo:
  case kARDSignalingMessageTypeListening:
  case kARDSignalingMessageTypeMessage:
  case kARDSignalingMessageTypeBatteryLevel:
  case kARDSignalingMessageTypePeerConnection:
  case kARDSignalingMessageTypePing:
  case kARDSignalingMessageTypePong: // Shouldn't be received
    // Disconnects and Shelter State can be processed immediately.

    [self processSignalingMessage:message];
    return;
      default:
          return;
  }
  [self drainMessageQueueIfReady];
}

// WebSocket state changed
- (void)channel:(id<ARDSignalingChannel>)channel
 didChangeState:(ARDSignalingChannelState)state {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"channel:didChangeState: %li",
                                          (long)state]];
  switch (state) {
  case kARDSignalingChannelStateOpen:
    break;
  // WebSocket successfuly connected
  case kARDSignalingChannelStateRegistered: {
    _hasWebSocketSuccessfulyConnected = YES;
    [_delegate appClient:self
        sendSystemMessage:NSLocalizedString(@"connected_to_shelter", nil)];
    // Send chat messages that were queued
    if ([_outgoingChatMessageQueue count]) {
      for (ARDSignalingMessage *message in _outgoingChatMessageQueue) {
        [self sendSignalingMessage:message];
      }

      [_outgoingChatMessageQueue removeAllObjects];
    }
    break;
  }
  // If WebSocket was closed or encoutered error
  case kARDSignalingChannelStateClosed:
  case kARDSignalingChannelStateError: {

    // Set PeerConnectionState
    //_peerConnectionState = NO;
    // Disconnect and destroy current PeerConnection
    [self destroyPeerConnection];

    // If previously successfuly connected to WebSocket - send system message
    // informing about disconnect
    if (_hasP2PSuccessfulyConnected) {
      _hasP2PSuccessfulyConnected = NO;
      [_delegate appClient:self
          sendSystemMessage:NSLocalizedString(@"connection_lost", nil)];
      if (_callState == kShelterCallStateAnswered ||
          _callState == kShelterCallStateOnHold) {
        [_delegate appClient:self
            sendSystemMessage:NSLocalizedString(@"audio_connection_lost", nil)];
      }
    }

    // Set shelter state to unknown
    [self setShelterState:kShelterStateDisconnected];

    // Try to reconnect with WebSocket after 3 seconds
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(reconnectWebSocket)
                                   userInfo:nil
                                    repeats:NO];

    break;
  }
  }
}


#pragma mark - RTCPeerConnectionDelegate
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged {
//    RTCLog(@"Signaling state changed: %ld", (long)stateChanged);
    
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"Signaling state changed: %li",
              (long)stateChanged]];
    
    switch (stateChanged) {
        case RTCSignalingStateStable:
        case RTCSignalingStateHaveLocalOffer:
        case RTCSignalingStateHaveRemoteOffer:
        case RTCSignalingStateHaveLocalPrAnswer:
        case RTCSignalingStateHaveRemotePrAnswer:
            break;
        case RTCSignalingStateClosed: {
            _isPeerConnectionCreating = NO;
            _isPeerConnectionPendingToClose = NO;
            _hasReceivedSdp = NO;
            break;
        }
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AppLogger sharedInstance]
         logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"Received %lu video tracks and %lu audio tracks",
                  (unsigned long)stream.videoTracks.count,
                  (unsigned long)stream.audioTracks.count]];
        
        if (stream.videoTracks.count) {
            RTCVideoTrack *videoTrack = stream.videoTracks[0];
            [_delegate appClient:self didReceiveRemoteVideoTrack:videoTrack];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream {
//    RTCLog(@"Stream was removed.");
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"Stream was removed."]];
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
//    RTCLog(@"WARNING: Renegotiation needed but unimplemented.");
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"WARNING: Renegotiation needed but unimplemented."]];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState {
//    RTCLog(@"ICE state changed: %ld", (long)newState);
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"ICE state changed: %ld", (long)newState]];

    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[AppLogger sharedInstance]
         logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"ICE state changed: %li", (long)newState]];
        
        switch (newState) {
            case RTCIceConnectionStateNew:
                _isICEConnectionClosed = NO;
                break;
            case RTCIceConnectionStateChecking:
                break;
            case RTCIceConnectionStateConnected:
                _isPeerConnectionCreating = NO;
                _hasP2PSuccessfulyConnected = YES;
                break;
            case RTCIceConnectionStateCompleted:
                break;
            case RTCIceConnectionStateDisconnected:
            case RTCIceConnectionStateFailed:
                _isICEConnected = NO;
                [_delegate appClient:self didChangeShelterState:kShelterStateOffline];
                break;
            case RTCIceConnectionStateClosed: {
                _isICEConnected = NO;
                _isICEConnectionClosed = YES;
                break;
            }
            default:
                break;
        }
        
        [_delegate appClient:self didChangeConnectionState:newState];
        
        
//        [_delegate appClient:self didChangeConnectionState:newState];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState {
//    RTCLog(@"ICE gathering state changed: %ld", (long)newState);
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"ICE gathering state changed: %ld", (long)newState]];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    dispatch_async(dispatch_get_main_queue(), ^{
        ARDICECandidateMessage *message =
        [[ARDICECandidateMessage alloc] initWithCandidate:candidate andSrc:_clientId andDestination:_roomId];
        [self sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
    dispatch_async(dispatch_get_main_queue(), ^{
        ARDICECandidateRemovalMessage *message =
        [[ARDICECandidateRemovalMessage alloc]
         initWithRemovedCandidates:candidates];
        [self sendSignalingMessage:message];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
}

#pragma mark - RTCSessionDescriptionDelegate
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didCreateSessionDescription:(RTCSessionDescription *)sdp
                          error:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
           message:[NSString
                       stringWithFormat:
                           @"Failed to create session description. Error: %@",
                           error]];
      [self destroyPeerConnection];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : @"Failed to create session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorCreateSDP
                                 userInfo:userInfo];
      [_delegate appClient:self didError:sdpError];
      return;
    }
      // Prefer H264 if available.
      RTCSessionDescription *sdpPreferringH264 =
      [ARDSDPUtils descriptionForDescription:sdp
                         preferredVideoCodec:@"H264"];
      __weak ARDAppClient *weakSelf = self;
      [_peerConnection setLocalDescription:sdpPreferringH264
                         completionHandler:^(NSError *error) {
                             ARDAppClient *strongSelf = weakSelf;
                             [strongSelf peerConnection:strongSelf.peerConnection
                      didSetSessionDescriptionWithError:error];
                         }];
      ARDSessionDescriptionMessage *message = [[ARDSessionDescriptionMessage alloc] initWithDescription:sdpPreferringH264 andSrc:_clientId andDestination:_roomId];
      [self sendSignalingMessage:message];
      [self setMaxBitrateForPeerConnectionVideoSender];

  });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didSetSessionDescriptionWithError:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
           message:[NSString
                       stringWithFormat:
                           @"Failed to set session description. Error: %@",
                           error]];
      [self destroyPeerConnection];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey : @"Failed to set session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorSetSDP
                                 userInfo:userInfo];
      [_delegate appClient:self didError:sdpError];
      return;
    }
  });
}

#pragma mark - Private

#if defined(WEBRTC_IOS)

- (NSString *)documentsFilePathForFileName:(NSString *)fileName {
    NSParameterAssert(fileName.length);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = paths.firstObject;
    NSString *filePath =
    [documentsDirPath stringByAppendingPathComponent:fileName];
    return filePath;
}

#endif

- (BOOL)hasJoinedRoomServerRoom {
  return _clientId.length;
}

// Begins the peer connection connection process if we have both joined a room
// on the room server and tried to obtain a TURN server. Otherwise does nothing.
// A peer connection object will be created with a stream that contains local
// audio and video capture. If this client is the caller, an offer is created as
// well, otherwise the client will wait for an offer to arrive.
- (void)startSignalingIfReady {
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"startSignalingIfReady"]];
    if (!_isTurnComplete) {
        return;
    }
    
    if (!_isPeerConnectionCreating) {
        [[AppLogger sharedInstance]
         logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"Creating PeerConnection"]];
        _isPeerConnectionCreating = YES;
        self.state = kARDAppClientStateConnected;
        
        RTCMediaConstraints *constraints = [self defaultOfferConstraints];
        RTCConfiguration *config = [[RTCConfiguration alloc] init];
        config.iceServers = _iceServers;
        _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                        constraints:constraints
                                                           delegate:self];
        // Create AV senders.
        [self createVideoSender];
        [self createAudioSender];
        
        [[AppLogger sharedInstance]
         logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"Sending offer"]];
        // Send offer.
        __weak ARDAppClient *weakSelf = self;
        [_peerConnection offerForConstraints:[self defaultOfferConstraints]
                           completionHandler:^(RTCSessionDescription *sdp,
                                               NSError *error) {
                               ARDAppClient *strongSelf = weakSelf;
                               [strongSelf peerConnection:strongSelf.peerConnection
                              didCreateSessionDescription:sdp
                                                    error:error];
                           }];
    } else {
        [[AppLogger sharedInstance]
         logClass:NSStringFromClass([self class])
         message:[NSString
                  stringWithFormat:@"PeerConnection is already creating"]];
    }
    
#if defined(WEBRTC_IOS)
    // Start event log.
    if (kARDAppClientEnableRtcEventLog) {
        NSString *filePath = [self documentsFilePathForFileName:@"webrtc-rtceventlog"];
        if (![_peerConnection startRtcEventLogWithFilePath:filePath
                                            maxSizeInBytes:kARDAppClientRtcEventLogMaxSizeInBytes]) {
            RTCLogError(@"Failed to start event logging.");
        }
    }
    
    // Start aecdump diagnostic recording.
    if (_shouldMakeAecDump) {
        NSString *filePath = [self documentsFilePathForFileName:@"webrtc-audio.aecdump"];
        if (![_factory startAecDumpWithFilePath:filePath
                                 maxSizeInBytes:kARDAppClientAecDumpMaxSizeInBytes]) {
            RTCLogError(@"Failed to start aec dump.");
        }
    }
#endif
}

// Processes the messages that we've received from the room server and the
// signaling channel. The offer or answer message must be processed before other
// signaling messages, however they can arrive out of order. Hence, this method
// only processes pending messages if there is a peer connection object and
// if we have received either an offer or answer.
- (void)drainMessageQueueIfReady {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"drainMessageQueueIfReady"]];
  if (!_peerConnection || !_hasReceivedSdp) {
    return;
  }
  for (ARDSignalingMessage *message in _messageQueue) {
    [self processSignalingMessage:message];
  }
  [_messageQueue removeAllObjects];
}

// Processes the given signaling message based on its type.
- (void)processSignalingMessage:(ARDSignalingMessage *)message {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"processSignallingMessage type: %d",
                                          message.type]];
  NSParameterAssert(_peerConnection ||
                    message.type == kARDSignalingMessageTypePing ||
                    message.type == kARDSignalingMessageTypeBye ||
                    message.type == kARDSignalingMessageTypeShelterStatus ||
                    message.type == kARDSignalingMessageTypeAlarmReset ||
                    message.type == kARDSignalingMessageTypePeerConnection ||
                    message.type == kARDSignalingMessageTypeMessages ||
                    message.type == kARDSignalingMessageTypeMessage ||
                    message.type == kARDSignalingMessageTypeVideo ||
                    message.type == kARDSignalingMessageTypeListening ||
                    message.type == kARDSignalingMessageTypeCallState);

    switch (message.type) {
        case kARDSignalingMessageTypeOffer:
        case kARDSignalingMessageTypeAnswer: {
            ARDSessionDescriptionMessage *sdpMessage =
            (ARDSessionDescriptionMessage *)message;
            RTCSessionDescription *description = sdpMessage.sessionDescription;
            // Prefer H264 if available.
            RTCSessionDescription *sdpPreferringH264 =
            [ARDSDPUtils descriptionForDescription:description
                               preferredVideoCodec:@"H264"];
            __weak ARDAppClient *weakSelf = self;
            [_peerConnection setRemoteDescription:sdpPreferringH264
                                completionHandler:^(NSError *error) {
                                    ARDAppClient *strongSelf = weakSelf;
                                    [strongSelf peerConnection:strongSelf.peerConnection
                             didSetSessionDescriptionWithError:error];
                                }];
            break;
        }
        case kARDSignalingMessageTypeCandidate: {
            ARDICECandidateMessage *candidateMessage =
            (ARDICECandidateMessage *)message;
            [_peerConnection addIceCandidate:candidateMessage.candidate];
            
            break;
        }
        case kARDSignalingMessageTypeCandidateRemoval: {
            ARDICECandidateRemovalMessage *candidateMessage =
            (ARDICECandidateRemovalMessage *)message;
            [_peerConnection removeIceCandidates:candidateMessage.candidates];
            break;
        }
            
        case kARDSignalingMessageTypePing:{
            [self sendSignalingMessage:[[ARDPongMessage alloc] init]];
            break;
        }
        case kARDSignalingMessageTypeBye:
        case kARDSignalingMessageTypeAlarmReset:
            // Other client disconnected.
            // TODO(tkchin): support waiting in room for next client. For now just
            // disconnect.
            _isDisconnecting = YES;
            [_delegate appClientDidReceivedAlarmReset:self];
            break;
        case kARDSignalingMessageTypeShelterStatus: {
            
            ARDShelterStatusMessage *shelterStatusMessage =
            (ARDShelterStatusMessage *)message;
            [[AppLogger sharedInstance]
             logClass:NSStringFromClass([self class])
             message:[NSString stringWithFormat:
                      @"ARDSignalingMessageTypeShelterStatus: %d",
                      shelterStatusMessage.shelterStatus]];
            // Check if state changed
            if (_shelterState != shelterStatusMessage.shelterStatus) {
                [[AppLogger sharedInstance]
                 logClass:NSStringFromClass([self class])
                 message:[NSString stringWithFormat:@"shelterState changed"]];
                _shelterState = (ShelterState)shelterStatusMessage.shelterStatus;
                // If Shelter went online
                if (_shelterState == kShelterStateOnline) {
                    // TODO: Check if this is needed. Change call state
                    _callState = kShelterCallStateNone;
                    
                    // If there is no active PeerConnection we should connect
                    [self startPeerConnectionIfReady];
                } else { // If Shelter went offline
                    
                    // Send system message that call was lost
                    if (_callState == kShelterCallStateAnswered ||
                        _callState == kShelterCallStateOnHold) {
                        [_delegate appClient:self
                           sendSystemMessage:NSLocalizedString(@"audio_connection_lost",
                                                               nil)];
                    }
                    // TODO: Check if this is needed. Change call state
                    _callState = kShelterCallStateNone;
                    
                    // Set Shelter state
                    //        _isShelterComplete = NO;
                    
                    // Destroy all connection objects
                    [self destroyPeerConnection];
                }
                // TODO: Check this. Send delegate method for UI???
                [_delegate appClient:self didChangeShelterState:_shelterState];
            }
            break;
        }
        case kARDSignalingMessageTypeRequestCall:
        case kARDSignalingMessageTypeBatteryLevel:
            // NOTHING TODO SHOULDN'T GET THIS
            break;
        case kARDSignalingMessageTypeMessage: {
            ARDChatMessage *chatMessage = (ARDChatMessage *)message;
            [_delegate appClient:self didReceivedMessage:chatMessage.message];
            break;
        }
        case kARDSignalingMessageTypeListening: {
            ARDListeningMessage *listeningMessage = (ARDListeningMessage *)message;
            [_delegate appClient:self
 didReceivedListeningStateChange:listeningMessage.listeningStatus];
            break;
        }
        case kARDSignalingMessageTypeVideo: {
            ARDVideoMessage *videoMessage = (ARDVideoMessage *)message;
            if (_videoState != videoMessage.videoStatus) {
                _videoState = videoMessage.videoStatus;
                [self changeVideoStreaming];
                if (_videoState && _queuedBatteryLevel > 0) {
                    [self sendBatteryLevel:_queuedBatteryLevel];
                }
            }
            break;
        }
        case kARDSignalingMessageTypeCallState: {
            ARDCallStateMessage *callStateMessage = (ARDCallStateMessage *)message;
            if (callStateMessage.callState &&
                (_callState != kShelterCallStateAnswered &&
                 _callState != kShelterCallStateOnHold)) {
                    _callState = kShelterCallStateAnswered;
                    [_delegate appClientDidResumeCallState:self];
                    [_delegate appClient:self
                       sendSystemMessage:NSLocalizedString(@"audio_connection_recreated",
                                                           nil)];
                }
            break;
        }
        case kARDSignalingMessageTypeMessages: {
            ARDQueuedChatMessages *chatMessages = (ARDQueuedChatMessages *)message;
            for (Message *chatMessage in chatMessages.messages) {
                [_delegate appClient:self didReceivedMessage:chatMessage];
            }
            Message *systemMessage = [[Message alloc]
                                      initWithType:2
                                      andText:[NSString stringWithFormat:
                                               @"Added %lu %@, scroll up to see %@",
                                               (unsigned long)[chatMessages.messages count],
                                               [chatMessages.messages count] == 1
                                               ? @"message"
                                                                        : @"messages",
                                               [chatMessages.messages count] == 1 ? @"it"
                                                                        : @"them"]
                                      andTimestamp:-1];
            [_delegate appClient:self didReceivedMessage:systemMessage];
            break;
        }
        case kARDSignalingMessageTypePeerConnection: {
            ARDPeerConnectionMessage *connectionMessage =
            (ARDPeerConnectionMessage *)message;
            
            // Check if state changed
            if (_peerConnectionState != connectionMessage.connectionState) {
                
                // Update current state
                _peerConnectionState = connectionMessage.connectionState;
                
                if (_peerConnectionState) {
                    // If all requirements are good start peer connection
                    [self startPeerConnectionIfReady];
                } else {
                    // Destroy all connection objects
                    [self destroyPeerConnection];
                    // Recreate PeerConnectionFactory
                    //[self recreatePeerConnectionFactory];
                    NSLog(@"Unable to create peer connection at this moment");
                }
            }
            break;
        }
        default:
            break;
    }
}

// Sends a signaling message to the other client. The caller will send messages
// through the room server, whereas the callee will send messages over the
// signaling channel.
- (void)sendSignalingMessage:(ARDSignalingMessage *)message {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"sendSignalingMessage type: %d",
                                          message.type]];
  if (_channel && _channel.state == kARDSignalingChannelStateRegistered) {
    [_channel sendMessage:message];
  } else {
    if (message.type == kARDSignalingMessageTypeMessage) {
      [_outgoingChatMessageQueue addObject:message];
    }
  }
}

- (RTCRtpSender *)createVideoSender {
    RTCRtpSender *sender =
    [_peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo
                           streamId:kARDMediaStreamId];
    RTCVideoTrack *track = [self createLocalVideoTrack];
    if (track) {
        sender.track = track;
        [_delegate appClient:self didReceiveLocalVideoTrack:track];
    }
    
    return sender;
}

- (void)setMaxBitrateForPeerConnectionVideoSender {
    for (RTCRtpSender *sender in _peerConnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:kARDVideoTrackKind]) {
                [self setMaxBitrate:_maxBitrate forVideoSender:sender];
            }
        }
    }
}

- (void)setMaxBitrate:(NSNumber *)maxBitrate forVideoSender:(RTCRtpSender *)sender {
    if (maxBitrate.intValue <= 0) {
        return;
    }
    
    RTCRtpParameters *parametersToModify = sender.parameters;
    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
        encoding.maxBitrateBps = @(maxBitrate.intValue * kKbpsMultiplier);
    }
    [sender setParameters:parametersToModify];
}

- (RTCRtpSender *)createAudioSender {
    RTCMediaConstraints *constraints = [self defaultMediaAudioConstraints];
    RTCAudioSource *source = [_factory audioSourceWithConstraints:constraints];
    RTCAudioTrack *track = [_factory audioTrackWithSource:source
                                                  trackId:kARDAudioTrackId];
    RTCRtpSender *sender =
    [_peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio
                           streamId:kARDMediaStreamId];
    sender.track = track;
    return sender;
}

- (RTCVideoTrack *)createLocalVideoTrack {
    RTCVideoTrack* localVideoTrack = nil;
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
#if !TARGET_IPHONE_SIMULATOR
//    if (!_isAudioOnly) {
        RTCMediaConstraints *cameraConstraints =
        [self cameraConstraints];
        RTCAVFoundationVideoSource *source =
        [_factory avFoundationVideoSourceWithConstraints:cameraConstraints];
        source.useBackCamera = YES;
        localVideoTrack =
        [_factory videoTrackWithSource:source
                               trackId:kARDVideoTrackId];
//    }
#endif
    return localVideoTrack;
}

#pragma mark - Collider methods

- (void)registerWithColliderIfReady {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"registerWithColliderIfReady"]];
  // Open WebSocket connection.
  if (!_channel && !_isDisconnecting) {
    [_delegate appClient:self
        sendSystemMessage:NSLocalizedString(@"connecting_to_shelter", nil)];
    _channel = [[ARDWebSocketChannel alloc] initWithURL:_websocketURL
                                                restURL:_websocketRestURL
                                               delegate:self];
  }
}

#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaAudioConstraints {
    NSString *valueLevelControl = _shouldUseLevelControl ?
    kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse;
    NSDictionary *mandatoryConstraints = @{ kRTCMediaConstraintsLevelControl : valueLevelControl };
    RTCMediaConstraints *constraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                          optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)cameraConstraints {
    return _cameraConstraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"true",
                                           @"OfferToReceiveVideo" : @"true"
                                           };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    if (_defaultPeerConnectionConstraints) {
        return _defaultPeerConnectionConstraints;
    }
    NSString *value = _isLoopback ? @"false" : @"true";
    NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement" : value };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:optionalConstraints];
    return constraints;
}

#pragma mark - Errors

+ (NSError *)errorForMessageResultType:(ARDMessageResultType)resultType {
  NSError *error = nil;
  switch (resultType) {
  case kARDMessageResultTypeSuccess:
    break;
  case kARDMessageResultTypeUnknown:
    error =
        [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                   code:kARDAppClientErrorUnknown
                               userInfo:@{
                                 NSLocalizedDescriptionKey : @"Unknown error.",
                               }];
    break;
  case kARDMessageResultTypeInvalidClient:
    error =
        [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                   code:kARDAppClientErrorInvalidClient
                               userInfo:@{
                                 NSLocalizedDescriptionKey : @"Invalid client.",
                               }];
    break;
  case kARDMessageResultTypeInvalidRoom:
    error =
        [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                   code:kARDAppClientErrorInvalidRoom
                               userInfo:@{
                                 NSLocalizedDescriptionKey : @"Invalid room.",
                               }];
    break;
  }
  return error;
}

#pragma Public

//- (void)sendMessageToDataChannel:(NSString *)message {
//  NSLog(@"Sending message:");
//  NSLog(@"%@", message);
//  [_dataChannel
//      sendData:[[RTCDataBuffer alloc]
//                   initWithData:[message
//                   dataUsingEncoding:NSUTF8StringEncoding]
//                       isBinary:NO]];
//}

- (void)changeVideoStreaming {
    for (RTCRtpSender* sender in _peerConnection.senders) {
        if ([sender.senderId isEqualToString:kARDVideoTrackId]){
            [sender.track setIsEnabled:_videoState];
            break;
        }
    }
}

- (ShelterCallState)callState {
  return _callState;
}

- (void)setCallState:(ShelterCallState)callState {
  _callState = callState;
}

- (void)muteRemoteAudioStreaming {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"muteRemoteAudioStreaming"]];
  [_remoteAudioTrack setIsEnabled:NO];
}

- (void)resumeRemoteAudioStreaming {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"resumeRemoteAudioStreaming"]];
  [_remoteAudioTrack setIsEnabled:YES];
}

- (void)reconnectWebSocket {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"reconnectWebSocket"]];
  _channel = nil;
  if (_hasWebSocketSuccessfulyConnected) {
    _hasWebSocketSuccessfulyConnected = NO;
    [_delegate appClient:self
        sendSystemMessage:NSLocalizedString(@"connecting_to_shelter", nil)];
  }
  _channel = [[ARDWebSocketChannel alloc] initWithURL:_websocketURL
                                              restURL:_websocketRestURL
                                             delegate:self];
}

- (void)sendChatMessage:(Message *)message {
  ARDChatMessage *chatSignalingMessage =
      [[ARDChatMessage alloc] initWithMessage:message
                                       source:_clientId
                                  destination:_roomId];
  [self sendSignalingMessage:chatSignalingMessage];
}
- (void)sendBatteryLevel:(NSInteger)batteryLevel {
  if (_shelterState != kShelterStateOnline) {
    _queuedBatteryLevel = batteryLevel;
  } else {
    _queuedBatteryLevel = -1;
    ARDBatteryLevelMessage *batterySignalingMessage =
        [[ARDBatteryLevelMessage alloc] initWithBatteryLevel:batteryLevel
                                                      source:_clientId
                                                 destination:_roomId];
    [self sendSignalingMessage:batterySignalingMessage];
  }
}
- (void)sendRequestCall:(BOOL)request {
  ARDRequestCallMessage *requestCallSignalingMessage =
      [[ARDRequestCallMessage alloc] initWithStatus:request
                                             source:_clientId
                                        destination:_roomId];
  [self sendSignalingMessage:requestCallSignalingMessage];
}

- (BOOL)canCreatePeerConnection {
  NSLog(@"shelterState: %d", _shelterState == kShelterStateOnline);
  NSLog(@"channel.state: %d",
        _channel.state == kARDSignalingChannelStateRegistered);
  NSLog(@"!_isICEConnected: %d", !_isICEConnected);
  NSLog(@"!_isPeerConnectionPendingToClose: %d",
        !_isPeerConnectionPendingToClose);
  NSLog(@"_peerConnectionState: %d", _peerConnectionState);
  NSLog(@"_isICEConnectionClosed: %d", _isICEConnectionClosed);
  NSLog(@"_isMicrophoneAvailable: %d", _isMicrophoneAvailable);

  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:
                       @"canCreatePeerConnection: %d",
                       (_shelterState == kShelterStateOnline &&
                        _channel.state == kARDSignalingChannelStateRegistered &&
                        !_isICEConnected && !_isPeerConnectionPendingToClose &&
                        _peerConnectionState && _isICEConnectionClosed &&
                        _isMicrophoneAvailable)]];
  return (_shelterState == kShelterStateOnline &&
          _channel.state == kARDSignalingChannelStateRegistered &&
          !_isICEConnected && !_isPeerConnectionPendingToClose &&
          _peerConnectionState && _isICEConnectionClosed &&
          _isMicrophoneAvailable);
}

- (void)setShelterState:(ShelterState)shelterState {
  _shelterState = shelterState;
  [_delegate appClient:self didChangeShelterState:_shelterState];
}

- (void)destroyPeerConnection {
  if (!_isPeerConnectionCreating && !_isPeerConnectionPendingToClose &&
      _peerConnection) {
    _isPeerConnectionPendingToClose = YES;
      if (_localMediaStream != nil) {
    [_peerConnection removeStream:_localMediaStream];
      }
    [_peerConnection close];
    _peerConnection = nil;
    _isPeerConnectionPendingToClose = NO;
  }
}

- (void)startPeerConnectionIfReady {
  if ([self canCreatePeerConnection]) {
    //  log("Creating peer connection");
    [self startSignalingIfReady];
  } else {
    // log("Not creating peer connection");
  }
}

- (void)microphoneInterruption:(NSNotification *)notification {
  // get the user info dictionary
  NSDictionary *interuptionDict = notification.userInfo;
  // get the AVAudioSessionInterruptionTypeKey enum from the dictionary
  NSInteger interuptionType = [[interuptionDict
      valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
  // decide what to do based on interruption type here...
  switch (interuptionType) {
  case AVAudioSessionInterruptionTypeBegan:
    NSLog(@"Audio Session Interruption case started.");
    _isMicrophoneAvailable = NO;
    for (RTCAudioTrack *audioTrack in _localMediaStream.audioTracks) {
      [audioTrack setIsEnabled:NO];
    }
    [_remoteAudioTrack setIsEnabled:NO];

    //  [self destroyPeerConnection];
    // fork to handling method here...
    // EG:[self handleInterruptionStarted];
    break;

  case AVAudioSessionInterruptionTypeEnded:
    NSLog(@"Audio Session Interruption case ended.");
    _isMicrophoneAvailable = YES;
    for (RTCAudioTrack *audioTrack in _localMediaStream.audioTracks) {
      if (audioTrack == _remoteAudioTrack) {
        [audioTrack setIsEnabled:_remoteAudioState];
      } else {
        [audioTrack setIsEnabled:YES];
      }
    }
    [_remoteAudioTrack setIsEnabled:_remoteAudioState];

    // [self startPeerConnectionIfReady];
    // fork to handling method here...
    // EG:[self handleInterruptionEnded];
    break;
  default:
    NSLog(@"Audio Session Interruption Notification case default.");
    break;
  }
}

@end
