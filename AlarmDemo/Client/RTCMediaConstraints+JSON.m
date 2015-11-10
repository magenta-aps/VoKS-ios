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

#import "RTCMediaConstraints+JSON.h"

#import "RTCPair.h"

static NSString const *kRTCMediaConstraintsMandatoryKey = @"mandatory";

@implementation RTCMediaConstraints (JSON)

+ (RTCMediaConstraints *)constraintsFromJSONDictionary:
    (NSDictionary *)dictionary {
  NSDictionary *mandatory = dictionary[kRTCMediaConstraintsMandatoryKey];
  NSMutableArray *mandatoryContraints =
      [NSMutableArray arrayWithCapacity:[mandatory count]];
  [mandatory enumerateKeysAndObjectsUsingBlock:^(
      id key, id obj, BOOL *stop) {
    [mandatoryContraints addObject:[[RTCPair alloc] initWithKey:key
                                                          value:obj]];
  }];
  // TODO(tkchin): figure out json formats for optional constraints.
  RTCMediaConstraints *constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:mandatoryContraints
                   optionalConstraints:nil];
  return constraints;
}

@end
