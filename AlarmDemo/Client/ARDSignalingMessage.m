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

#import "ARDSignalingMessage.h"

#import "ARDUtilities.h"
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

static NSString const *kARDSignalingMessageTypeKey = @"type";

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
    NSLog(@"Error parsing signaling message JSON.");
    return nil;
  }

  NSString *typeString = values[kARDSignalingMessageTypeKey];
  ARDSignalingMessage *message = nil;
  if ([typeString isEqualToString:@"candidate"]) {
    RTCICECandidate *candidate =
        [RTCICECandidate candidateFromJSONDictionary:values];
    message = [[ARDICECandidateMessage alloc]
        initWithCandidate:candidate
                   andSrc:[values valueForKey:@"src"]
           andDestination:[values valueForKey:@"dst"]];
  } else if ([typeString isEqualToString:@"offer"] ||
             [typeString isEqualToString:@"answer"]) {

    RTCSessionDescription *description =
        [RTCSessionDescription descriptionFromJSONDictionary:values];
    // [RTCSessionDescription descriptionFromJSONDictionary:values];
    message = [[ARDSessionDescriptionMessage alloc]
        initWithDescription:description
                     andSrc:[values valueForKey:@"src"]
             andDestination:[values valueForKey:@"dst"]];
  } else if ([typeString isEqualToString:@"bye"]) {
    message = [[ARDByeMessage alloc] init];
  } else {
    NSLog(@"Unexpected type: %@", typeString);
  }
  return message;
}

+ (ARDSignalingMessage *)messageFromDictionary:(NSDictionary *)dictionary {
  NSString *typeString =
      [dictionary[kARDSignalingMessageTypeKey] lowercaseString];
  ARDSignalingMessage *message = nil;
  if ([typeString isEqualToString:@"candidate"]) {
    RTCICECandidate *candidate =
        [RTCICECandidate candidateFromJSONDictionary:dictionary];
    message =
        [[ARDICECandidateMessage alloc] initWithCandidate:candidate
                                                   andSrc:dictionary[@"src"]
                                           andDestination:dictionary[@"dst"]];
  } else if ([typeString isEqualToString:@"offer"] ||
             [typeString isEqualToString:@"answer"]) {

    RTCSessionDescription *description =
        [RTCSessionDescription descriptionFromJSONDictionary:dictionary];
    // [RTCSessionDescription descriptionFromJSONDictionary:values];
    message = [[ARDSessionDescriptionMessage alloc]
        initWithDescription:description
                     andSrc:dictionary[@"src"]
             andDestination:dictionary[@"dst"]];
  } else if ([typeString isEqualToString:@"ping"]){
      message = [[ARDPingMessage alloc] init];
  } else if ([typeString isEqualToString:@"bye"]) {
    message = [[ARDByeMessage alloc] init];
  } else if ([typeString isEqualToString:@"shelter_status"]) {
    message = [[ARDShelterStatusMessage alloc]
        initWithStatus:[dictionary[@"data"] boolValue]];
  } else if ([typeString isEqualToString:@"shelter_reset"]) {
    message = [[ARDAlarmResetMessage alloc] init];
  } else if ([typeString isEqualToString:@"message"]) {
    Message *incommingMessage =
        [[Message alloc] initWithType:1
                              andText:dictionary[@"data"]
                         andTimestamp:[dictionary[@"timestamp"] longValue]];
    message = [[ARDChatMessage alloc] initWithMessage:incommingMessage
                                               source:dictionary[@"src"]
                                          destination:dictionary[@"dst"]];
  } else if ([typeString isEqualToString:@"video"]) {
    message = [[ARDVideoMessage alloc]
        initWithStatus:[dictionary[@"data"] boolValue]];

  } else if ([typeString isEqualToString:@"listening"]) {
    message = [[ARDListeningMessage alloc]
        initWithStatus:[dictionary[@"data"] boolValue]];
  } else if ([typeString isEqualToString:@"call_state"]) {
    message = [[ARDCallStateMessage alloc]
        initWithState:[dictionary[@"data"] integerValue]];
  } else if ([typeString isEqualToString:@"peer_connection"]) {
    message = [[ARDPeerConnectionMessage alloc]
        initWithConnectionState:[dictionary[@"data"] boolValue]];
  } else {
    NSLog(@"Unexpected type: %@", typeString);
  }
  return message;
}

- (NSData *)JSONData {
  return nil;
}

@end

@implementation ARDICECandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCICECandidate *)candidate
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

@implementation ARDSessionDescriptionMessage

@synthesize sessionDescription = _sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description
                             andSrc:(NSString *)src
                     andDestination:(NSString *)destination {
  ARDSignalingMessageType type = kARDSignalingMessageTypeOffer;
  NSString *typeString = [description.type lowercaseString];
  if ([typeString isEqualToString:@"offer"]) {
    type = kARDSignalingMessageTypeOffer;
  } else if ([typeString isEqualToString:@"answer"]) {
    type = kARDSignalingMessageTypeAnswer;
  } else if ([typeString isEqualToString:@"shelter_status"]) {
    type = kARDSignalingMessageTypeShelterStatus;
  } else {
    NSAssert(NO, @"Unexpected type: %@", typeString);
  }
  if (self = [super initWithType:type]) {
    _sessionDescription = description;
    _src = src;
    _destination = destination;
  }
  return self;
}

//- (instancetype)initWithDescription:(RTCSessionDescription *)description
// destination:(NSString *)destination connectionId:(NSString *) connectionId
// offerType:(NSString *) offerType{
//    ARDSignalingMessageType type = kARDSignalingMessageTypeOffer;
//    NSString *typeString = description.type;
//    if ([typeString isEqualToString:@"offer"]) {
//        type = kARDSignalingMessageTypeOffer;
//    } else if ([typeString isEqualToString:@"answer"]) {
//        type = kARDSignalingMessageTypeAnswer;
//    } else if ([typeString isEqualToString:@"shelter_status"]){
//        type = kARDSignalingMessageTypeShelterStatus;
//    } else {
//        NSAssert(NO, @"Unexpected type: %@", typeString);
//    }
//    if (self = [super initWithType:type]) {
//        _sessionDescription = description;
//    }
//    return self;
//}

- (NSData *)JSONData {
  //    _sessionDescription.destination = self.destination;
  //    _sessionDescription.connectionId = self.connectionId;
  //    _sessionDescription.browser = self.browser;
  return [_sessionDescription JSONData:self.src andDst:self.destination];
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

@implementation ARDByeMessage

- (instancetype)init {
  return [super initWithType:kARDSignalingMessageTypeBye];
}

- (NSData *)JSONData {
  NSDictionary *message = @{ @"type" : @"bye" };
  return [NSJSONSerialization dataWithJSONObject:message
                                         options:NSJSONWritingPrettyPrinted
                                           error:NULL];
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
