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

#import "RTCICECandidate+JSON.h"

static NSString const *kRTCICECandidateTypeKey = @"type";
static NSString const *kRTCICECandidateTypeValue = @"candidate";
static NSString const *kRTCICECandidateMidKey = @"sdpMid";
static NSString const *kRTCICECandidateMLineIndexKey = @"sdpMLineIndex";
static NSString const *kRTCICECandidateSdpKey = @"candidate";
static NSString const *kRTCICECandidatePayloadKey = @"payload";
static NSString const *kRTCICECandidateDestinationKey = @"dst";
static NSString const *kRTCICECandidateSrcKey = @"src";

//PeerJS

@implementation RTCICECandidate (JSON)

+ (RTCICECandidate *)candidateFromJSONDictionary:(NSDictionary *)dictionary {
//    NSString *mid = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateSdpKey][kRTCICECandidateMidKey];
//  NSString *sdp = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateSdpKey][kRTCICECandidateSdpKey];
//  NSNumber *num = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateSdpKey][kRTCICECandidateMLineIndexKey];
//  NSInteger mLineIndex = [num integerValue];
    
    NSString *mid = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateMidKey];
    NSString *sdp = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateSdpKey];
    NSNumber *num = dictionary[kRTCICECandidatePayloadKey][kRTCICECandidateMLineIndexKey];
    NSInteger mLineIndex = [num integerValue];

  return [[RTCICECandidate alloc] initWithMid:mid index:mLineIndex sdp:sdp];
}

- (NSData *)JSONData:(NSString*) src andDst:(NSString *)dst{
    //OLD
//  NSDictionary *json = @{
//    kRTCICECandidateTypeKey : [kRTCICECandidateTypeValue uppercaseString],
//    kRTCICECandidateDestinationKey : destination,
//    kRTCICECandidatePayloadKey : @{kRTCICECandidateSdpKey : @{kRTCICECandidateSdpKey: self.sdp,kRTCICECandidateMLineIndexKey : @(self.sdpMLineIndex),kRTCICECandidateMidKey : self.sdpMid}, kRTCICECandidateTypeKey : @"media", kRTCICECandidateConnectionIdKey : connectionId}
//  };
    
    // NEW
    NSDictionary *json = @{
                           kRTCICECandidateSrcKey:src,
                           kRTCICECandidateTypeKey : [kRTCICECandidateTypeValue uppercaseString],
                           kRTCICECandidateDestinationKey : dst,
                           kRTCICECandidatePayloadKey : @{kRTCICECandidateSdpKey: self.sdp,kRTCICECandidateMLineIndexKey : @(self.sdpMLineIndex),kRTCICECandidateMidKey : self.sdpMid}
                           };

  NSError *error = nil;
  NSData *data =
      [NSJSONSerialization dataWithJSONObject:json
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];
  if (error) {
    NSLog(@"Error serializing JSON: %@", error);
    return nil;
  }
  return data;
}

@end
