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

#import "ARDWebSocketChannel.h"

#import "ARDUtilities.h"
#import "SRWebSocket.h"
#import "AppLogger.h"

// TODO(tkchin): move these to a configuration object.
static NSString const *kARDWSSMessageErrorKey = @"error";
static NSString const *kARDWSSMessagePayloadKey = @"payload";

@interface ARDWebSocketChannel () <SRWebSocketDelegate>
@end

@implementation ARDWebSocketChannel {
  NSURL *_url;
  NSURL *_restURL;
  SRWebSocket *_socket;
}

@synthesize delegate = _delegate;
@synthesize state = _state;

- (instancetype)initWithURL:(NSURL *)url
                    restURL:(NSURL *)restURL
                   delegate:(id<ARDSignalingChannelDelegate>)delegate {
  if (self = [super init]) {
    _url = url;
    _restURL = restURL;
    _delegate = delegate;
    _socket = [[SRWebSocket alloc] initWithURL:url];
    _socket.delegate = self;
    [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                  message:@"Opening WebSocket"];
    [_socket open];
  }
  return self;
}

- (void)dealloc {
  [self disconnect];
}

- (void)setState:(ARDSignalingChannelState)state {
  if (_state == state) {
    return;
  }
  _state = state;
  [_delegate channel:self didChangeState:_state];
}

- (void)sendMessage:(ARDSignalingMessage *)message {
  NSData *data = [message JSONData];
  if (_state == kARDSignalingChannelStateRegistered) {
    NSString *messageString =
        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"C->WSS: %@", messageString]];
    [_socket send:messageString];
  }
}

- (void)disconnect {
  if (_state == kARDSignalingChannelStateClosed ||
      _state == kARDSignalingChannelStateError) {
    return;
  }
  [_socket close];
  //  NSLog(@"C->WSS DELETE");
  //  NSString *urlString =
  //      [NSString stringWithFormat:@"%@/%@/%@",
  //          [_restURL absoluteString], _roomId, _clientId];
  //  NSURL *url = [NSURL URLWithString:urlString];
  //  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  //  request.HTTPMethod = @"DELETE";
  //  request.HTTPBody = nil;
  //  [NSURLConnection sendAsyncRequest:request completionHandler:nil];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"WebSocket connection opened."]];
  self.state = kARDSignalingChannelStateRegistered;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
  NSString *messageString = message;
  NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
  id jsonObject =
      [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
  if (![jsonObject isKindOfClass:[NSDictionary class]]) {
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString
                     stringWithFormat:@"Unexpected object: %@", jsonObject]];
    return;
  }
  NSDictionary *wssMessage = jsonObject;
  NSString *errorString = wssMessage[kARDWSSMessageErrorKey];
  if (errorString.length) {
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"WSS error: %@", errorString]];
    return;
  }

  if ([[wssMessage valueForKey:@"type"] isEqualToString:@"EXPIRE"]) {
    NSLog(@"WSS: EXPIRE message, do nothing");
    return;
  }

  if ([[wssMessage valueForKey:@"type"] isEqualToString:@"SEND OFFER"]) {
    NSLog(@"WSS: SEND OFFER message, do nothing for now!");
    return;
  }

  if ([[wssMessage valueForKey:@"type"] isEqualToString:@"ERROR"]) {
    NSLog(@"WSS: ERROR message, do nothing for now! Error: %@",
          [wssMessage valueForKey:@"data"]);
    return;
  }
  if ([[wssMessage valueForKey:@"type"]
          isEqualToString:@"CHECK_POLICE_STATUS"]) {
    NSLog(@"WSS: CHECK_POLICE_STATUS message, do nothing for now!");
    return;
  }

  ARDSignalingMessage *signalingMessage =
      [ARDSignalingMessage messageFromDictionary:wssMessage];
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"WSS->C: %@", wssMessage]];
  [_delegate channel:self didReceiveMessage:signalingMessage];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"WebSocket error: %@", error]];
  self.state = kARDSignalingChannelStateError;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"WebSocket closed with code: %ld "
                                          @"reason: %@ wasClean: %d",
                                          (long)code, reason, wasClean]];

  NSParameterAssert(_state != kARDSignalingChannelStateError);
  self.state = kARDSignalingChannelStateClosed;
}

@end
