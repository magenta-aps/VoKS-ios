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

#import "RTCICECandidate.h"
#import "RTCSessionDescription.h"
#import "Message.h"

typedef enum {
  kARDSignalingMessageTypeCandidate,
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
  kARDSignalingMessageTypePong,

} ARDSignalingMessageType;

@interface ARDSignalingMessage : NSObject

@property(nonatomic, readonly) ARDSignalingMessageType type;

+ (ARDSignalingMessage *)messageFromJSONString:(NSString *)jsonString;
+ (ARDSignalingMessage *)messageFromDictionary:(NSDictionary *)dictionary;
- (NSData *)JSONData;

@end

@interface ARDICECandidateMessage : ARDSignalingMessage

@property(nonatomic, readonly) RTCICECandidate *candidate;
@property(nonatomic, readonly) NSString *src;
@property(nonatomic, readonly) NSString *destination;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate
                           andSrc:(NSString *)src
                   andDestination:(NSString *)destination;

@end

@interface ARDSessionDescriptionMessage : ARDSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;
@property(nonatomic, readonly) NSString *src;
@property(nonatomic, readonly) NSString *destination;

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                             andSrc:(NSString *)src
                     andDestination:(NSString *)destination;

@end

@interface ARDShelterStatusMessage : ARDSignalingMessage

@property(nonatomic, readonly) BOOL shelterStatus;
- (instancetype)initWithStatus:(BOOL)status;

@end

@interface ARDAlarmResetMessage : ARDSignalingMessage
@end

@interface ARDByeMessage : ARDSignalingMessage
@end

// From Data channel
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
