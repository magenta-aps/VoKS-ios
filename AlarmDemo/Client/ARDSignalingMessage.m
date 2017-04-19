/*
 *  Copyright 2014 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDSignalingMessage.h"

#import "WebRTC/RTCLogging.h"

#import "ARDUtilities.h"
#import "RTCIceCandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

static NSString * const kARDSignalingMessageTypeKey = @"type";
static NSString * const kARDTypeValueRemoveCandidates = @"remove-candidates";

@implementation ARDSignalingMessage

@synthesize type = _type;

- (instancetype)initWithType:(ARDSignalingMessageType)type {
  if (self = [super init]) {
    _type = type;
  }
  return self;
}

- (NSString *)description {
  return [[NSString alloc] initWithData:[self JSONData]
                               encoding:NSUTF8StringEncoding];
}

+ (ARDSignalingMessage *)messageFromJSONString:(NSString *)jsonString {
  NSDictionary *values = [NSDictionary dictionaryWithJSONString:jsonString];
  if (!values) {
    RTCLogError(@"Error parsing signaling message JSON.");
    return nil;
  }

  NSString *typeString = [values[kARDSignalingMessageTypeKey] lowercaseString];
  ARDSignalingMessage *message = nil;
  if ([typeString isEqualToString:@"candidate"]) {
//    RTCIceCandidate *candidate =
//        [RTCIceCandidate candidateFromJSONDictionary:values];
//    message = [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
      
      RTCIceCandidate *candidate =
      [RTCIceCandidate candidateFromJSONDictionary:values[@"payload"]];
      message = [[ARDICECandidateMessage alloc]
                 initWithCandidate:candidate
                 andSrc:[values valueForKey:@"src"]
                 andDestination:[values valueForKey:@"dst"]];
      
  } else if ([typeString isEqualToString:kARDTypeValueRemoveCandidates]) {
    RTCLogInfo(@"Received remove-candidates message");
    NSArray<RTCIceCandidate *> *candidates =
        [RTCIceCandidate candidatesFromJSONDictionary:values];
    message = [[ARDICECandidateRemovalMessage alloc]
                  initWithRemovedCandidates:candidates];
  } else if ([typeString isEqualToString:@"offer"] ||
             [typeString isEqualToString:@"answer"]) {
      
      RTCSessionDescription *description =
      [RTCSessionDescription descriptionFromJSONDictionary:values[@"payload"]];
      // [RTCSessionDescription descriptionFromJSONDictionary:values];
      message = [[ARDSessionDescriptionMessage alloc]
                 initWithDescription:description
                 andSrc:[values valueForKey:@"src"]
                 andDestination:[values valueForKey:@"dst"]];
      
      
  } else if ([typeString isEqualToString:@"bye"]) {
    message = [[ARDByeMessage alloc] init];
  } else if ([typeString isEqualToString:@"ping"]){
      message = [[ARDPingMessage alloc] init];
  } else if ([typeString isEqualToString:@"shelter_status"]) {
      message = [[ARDShelterStatusMessage alloc]
                 initWithStatus:[values[@"data"] boolValue]];
  } else if ([typeString isEqualToString:@"shelter_reset"]) {
      message = [[ARDAlarmResetMessage alloc] init];
  } else if ([typeString isEqualToString:@"message"]) {
      Message *incommingMessage =
      [[Message alloc] initWithType:1
                            andText:values[@"data"]
                       andTimestamp:[values[@"timestamp"] longValue]];
      message = [[ARDChatMessage alloc] initWithMessage:incommingMessage
                                                 source:values[@"src"]
                                            destination:values[@"dst"]];
  } else if ([typeString isEqualToString:@"video"]) {
      message = [[ARDVideoMessage alloc]
                 initWithStatus:[values[@"data"] boolValue]];
      
  } else if ([typeString isEqualToString:@"listening"]) {
      message = [[ARDListeningMessage alloc]
                 initWithStatus:[values[@"data"] boolValue]];
  } else if ([typeString isEqualToString:@"call_state"]) {
      message = [[ARDCallStateMessage alloc]
                 initWithState:[values[@"data"] integerValue]];
  } else if ([typeString isEqualToString:@"peer_connection"]) {
      message = [[ARDPeerConnectionMessage alloc]
                 initWithConnectionState:[values[@"data"] boolValue]];
  } else {
    RTCLogError(@"Unexpected type: %@", typeString);
  }
  return message;
}

- (NSData *)JSONData {
  return nil;
}

@end

@implementation ARDICECandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate {
  if (self = [super initWithType:kARDSignalingMessageTypeCandidate]) {
    _candidate = candidate;
  }
  return self;
}

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate
                           andSrc:(NSString *)src
                   andDestination:(NSString *)destination {
    if (self = [super initWithType:kARDSignalingMessageTypeCandidate]) {
        _candidate = candidate;
        _src = src;
        _destination = destination;
    }
    return self;
}

- (NSData *)JSONData {
  return [_candidate JSONData:self.src andDst:self.destination];
}

@end

@implementation ARDICECandidateRemovalMessage

@synthesize candidates = _candidates;

- (instancetype)initWithRemovedCandidates:(
    NSArray<RTCIceCandidate *> *)candidates {
  NSParameterAssert(candidates.count);
  if (self = [super initWithType:kARDSignalingMessageTypeCandidateRemoval]) {
    _candidates = candidates;
  }
  return self;
}

- (NSData *)JSONData {
  return
      [RTCIceCandidate JSONDataForIceCandidates:_candidates
                                       withType:kARDTypeValueRemoveCandidates];
}

@end

@implementation ARDSessionDescriptionMessage

@synthesize sessionDescription = _sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description {
  ARDSignalingMessageType messageType = kARDSignalingMessageTypeOffer;
  RTCSdpType sdpType = description.type;
  switch (sdpType) {
    case RTCSdpTypeOffer:
      messageType = kARDSignalingMessageTypeOffer;
      break;
    case RTCSdpTypeAnswer:
      messageType = kARDSignalingMessageTypeAnswer;
      break;
    case RTCSdpTypePrAnswer:
      NSAssert(NO, @"Unexpected type: %@",
          [RTCSessionDescription stringForType:sdpType]);
      break;
  }
  if (self = [super initWithType:messageType]) {
    _sessionDescription = description;
  }
  return self;
}

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                             andSrc:(NSString *)src
                     andDestination:(NSString *)destination {
    
    //TODO: CHECK THIS, BECAUSE IT HAD "SHELTER_STATUS" in it!!
    
    ARDSignalingMessageType messageType = kARDSignalingMessageTypeOffer;
    RTCSdpType sdpType = description.type;
    switch (sdpType) {
        case RTCSdpTypeOffer:
            messageType = kARDSignalingMessageTypeOffer;
            break;
        case RTCSdpTypeAnswer:
            messageType = kARDSignalingMessageTypeAnswer;
            break;
        case RTCSdpTypePrAnswer:
            NSAssert(NO, @"Unexpected type: %@",
                     [RTCSessionDescription stringForType:sdpType]);
            break;
    }

    if (self = [super initWithType:messageType]) {
        _sessionDescription = description;
        _src = src;
        _destination = destination;
    }
    return self;
}

- (NSData *)JSONData {
  return [_sessionDescription JSONData:self.src andDst:self.destination];
}

@end

@implementation ARDByeMessage

- (instancetype)init {
  return [super initWithType:kARDSignalingMessageTypeBye];
}

- (NSData *)JSONData {
  NSDictionary *message = @{
    @"type": @"bye"
  };
  return [NSJSONSerialization dataWithJSONObject:message
                                         options:NSJSONWritingPrettyPrinted
                                           error:NULL];
}

@end

@implementation ARDShelterStatusMessage

- (instancetype)initWithStatus:(BOOL)status {
    
    if (self == [super initWithType:kARDSignalingMessageTypeShelterStatus]) {
        _shelterStatus = status;
    }
    return self;
}

@end

@implementation ARDAlarmResetMessage

- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypeAlarmReset];
}
@end

@implementation ARDPingMessage

- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypePing];
}

- (NSData *)JSONData {
    NSDictionary *message = @{ @"type" : @"PING" };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

@implementation ARDPongMessage

- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypePong];
}

- (NSData *)JSONData {
    NSDictionary *message = @{ @"type" : @"PONG" };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

// From data channel
@implementation ARDChatMessage

- (instancetype)initWithMessage:(Message *)message
                         source:(NSString *)source
                    destination:(NSString *)destination {
    
    if (self == [super initWithType:kARDSignalingMessageTypeMessage]) {
        _message = message;
        _source = source;
        _destination = destination;
    }
    return self;
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"src" : _source,
                              @"dst" : _destination,
                              @"type" : @"MESSAGE",
                              @"data" : _message.text,
                              @"timestamp" : [NSString stringWithFormat:@"%lli", _message.timestamp]
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

@implementation ARDListeningMessage

- (instancetype)initWithStatus:(BOOL)status {
    if (self == [super initWithType:kARDSignalingMessageTypeListening]) {
        _listeningStatus = status;
    }
    return self;
}

@end

@implementation ARDVideoMessage

- (instancetype)initWithStatus:(BOOL)status {
    if (self == [super initWithType:kARDSignalingMessageTypeVideo]) {
        _videoStatus = status;
    }
    return self;
}

@end

@implementation ARDRequestCallMessage

- (instancetype)initWithStatus:(BOOL)status
                        source:(NSString *)source
                   destination:(NSString *)destination {
    if (self == [super initWithType:kARDSignalingMessageTypeRequestCall]) {
        _requestCallState = status;
        _source = source;
        _destination = destination;
    }
    return self;
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"src" : _source,
                              @"dst" : _destination,
                              @"type" : @"REQUEST_CALL",
                              @"data" : [NSNumber numberWithBool:_requestCallState],
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

@implementation ARDCallStateMessage

- (instancetype)initWithState:(BOOL)state {
    if (self == [super initWithType:kARDSignalingMessageTypeCallState]) {
        _callState = state;
    }
    return self;
}

@end

@implementation ARDQueuedChatMessages

- (instancetype)initWithMessages:(NSArray *)messages {
    if (self == [super initWithType:kARDSignalingMessageTypeMessages]) {
        _messages = messages;
    }
    return self;
}

@end

@implementation ARDBatteryLevelMessage

- (instancetype)initWithBatteryLevel:(NSInteger)batteryLevel
                              source:(NSString *)source
                         destination:(NSString *)destination {
    
    if (self == [super initWithType:kARDSignalingMessageTypeBatteryLevel]) {
        _batteryLevel = batteryLevel;
        _source = source;
        _destination = destination;
    }
    return self;
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"type" : @"BATTERY_LEVEL",
                              @"data" : [NSNumber numberWithInteger:_batteryLevel],
                              @"src" : _source,
                              @"dst" : _destination,
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}

@end

@implementation ARDPeerConnectionMessage

- (instancetype)initWithConnectionState:(BOOL)state {
    if (self == [super initWithType:kARDSignalingMessageTypePeerConnection]) {
        _connectionState = state;
    }
    return self;
}


@end
