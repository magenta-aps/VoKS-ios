/*
 *  Copyright 2014 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <Foundation/Foundation.h>

#import "WebRTC/RTCIceCandidate.h"
#import "WebRTC/RTCSessionDescription.h"
#import "Message.h"

typedef enum {
  kARDSignalingMessageTypeCandidate,
  kARDSignalingMessageTypeCandidateRemoval,
  kARDSignalingMessageTypeOffer,
  kARDSignalingMessageTypeAnswer,
  kARDSignalingMessageTypeBye,
    
    kARDSignalingMessageTypeShelterStatus,
    kARDSignalingMessageTypeAlarmReset,
    // From data channel
    kARDSignalingMessageTypeMessage,
    kARDSignalingMessageTypeListening,
    kARDSignalingMessageTypeVideo,
    kARDSignalingMessageTypeRequestCall,
    kARDSignalingMessageTypeCallState,
    kARDSignalingMessageTypeBatteryLevel,
    kARDSignalingMessageTypeMessages,
    // Peer connection
    kARDSignalingMessageTypePeerConnection,
    // Ping Pong
    kARDSignalingMessageTypePing,
    kARDSignalingMessageTypePong
    
} ARDSignalingMessageType;

@interface ARDSignalingMessage : NSObject

@property(nonatomic, readonly) ARDSignalingMessageType type;

+ (ARDSignalingMessage *)messageFromJSONString:(NSString *)jsonString;
- (NSData *)JSONData;

@end

@interface ARDICECandidateMessage : ARDSignalingMessage

@property(nonatomic, readonly) RTCIceCandidate *candidate;
@property(nonatomic, readonly) NSString *src;
@property(nonatomic, readonly) NSString *destination;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate;
- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate andSrc:(NSString *)src
                   andDestination:(NSString *)destination;

@end

@interface ARDICECandidateRemovalMessage : ARDSignalingMessage

@property(nonatomic, readonly) NSArray<RTCIceCandidate *> *candidates;

- (instancetype)initWithRemovedCandidates:
    (NSArray<RTCIceCandidate *> *)candidates;

@end

@interface ARDSessionDescriptionMessage : ARDSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;
@property(nonatomic, readonly) NSString *src;
@property(nonatomic, readonly) NSString *destination;

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                             andSrc:(NSString *)src
                     andDestination:(NSString *)destination;

- (instancetype)initWithDescription:(RTCSessionDescription *)description;

@end

@interface ARDByeMessage : ARDSignalingMessage
@end
// From Data channel

@interface ARDShelterStatusMessage : ARDSignalingMessage

@property(nonatomic, readonly) BOOL shelterStatus;
- (instancetype)initWithStatus:(BOOL)status;

@end

@interface ARDAlarmResetMessage : ARDSignalingMessage
@end

@interface ARDChatMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSString *source;
@property(nonatomic, readonly) NSString *destination;
@property(nonatomic, readonly) Message *message;
- (instancetype)initWithMessage:(Message *)message
                         source:(NSString *)source
                    destination:(NSString *)destination;
@end

@interface ARDListeningMessage : ARDSignalingMessage
@property(nonatomic, readonly) BOOL listeningStatus;
- (instancetype)initWithStatus:(BOOL)status;

@end

@interface ARDVideoMessage : ARDSignalingMessage
@property(nonatomic, readonly) BOOL videoStatus;
- (instancetype)initWithStatus:(BOOL)status;

@end

@interface ARDRequestCallMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSString *source;
@property(nonatomic, readonly) NSString *destination;
@property(nonatomic, readonly) BOOL requestCallState;
- (instancetype)initWithStatus:(BOOL)status
                        source:(NSString *)source
                   destination:(NSString *)destination;

@end

@interface ARDCallStateMessage : ARDSignalingMessage
@property(nonatomic, readonly) BOOL callState;
- (instancetype)initWithState:(BOOL)state;

@end

@interface ARDQueuedChatMessages : ARDSignalingMessage
@property(nonatomic, readonly) NSArray *messages;
- (instancetype)initWithMessages:(NSArray *)messages;

@end

@interface ARDBatteryLevelMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSString *source;
@property(nonatomic, readonly) NSString *destination;
@property(nonatomic, readonly) NSInteger batteryLevel;
- (instancetype)initWithBatteryLevel:(NSInteger)batteryLevel
                              source:(NSString *)source
                         destination:(NSString *)destination;

@end

@interface ARDPeerConnectionMessage : ARDSignalingMessage
@property(nonatomic, readonly) BOOL connectionState;
- (instancetype)initWithConnectionState:(BOOL)state;

@end

@interface ARDPingMessage : ARDSignalingMessage
@end

@interface ARDPongMessage : ARDSignalingMessage
@end
