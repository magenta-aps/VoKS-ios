/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */


#import "AppLogger.h"
#import "Utils.h"

@implementation AppLogger
+ (instancetype)sharedInstance {
  static AppLogger *_sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[AppLogger alloc] init];
  });

  return _sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _logs = [NSMutableArray array];
    _queuedLogs = [NSMutableArray array];
    _isEnabled = YES;
    _doSendToRemote = NO;
  }

  return self;
}

- (void)logClass:(NSString *)className message:(NSString *)message {

  if (_isEnabled) {
    NSLog(@"%@: %@", className, message);
    if (_doSendToRemote) {
      NSDictionary *logEntry = @{
        @"tag" : className,
        @"message" : message,
        @"timestamp" : [NSString
            stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]
      };

      if (!_isSendingLogs) {
        [_logs addObject:logEntry];

        if ([_logs count] >= 100) {
          [self sendLogsToRemote];
        }
      } else {
        [_queuedLogs addObject:logEntry];
      }
    }
  }
}

- (void)sendLogsToRemote {
  if (_doSendToRemote) {

    if (!_isSendingLogs) {
      _isSendingLogs = YES;

      NSError *error;

      NSURL *url = nil;

      NSURLSession *session = [NSURLSession sharedSession];
      if ([[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"]) {
        url = [NSURL
            URLWithString:[NSString stringWithFormat:
                                        @"%@logger",
                                        [[NSUserDefaults standardUserDefaults]
                                            stringForKey:@"api_url"]]];
      } else {
        url = [NSURL URLWithString:kDefaultLoggerURL];
      }

      NSMutableURLRequest *request =
          [NSMutableURLRequest requestWithURL:url
                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                              timeoutInterval:60.0];

      [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
      [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

      [request setHTTPMethod:@"POST"];

      NSData *jsonMessages =
          [NSJSONSerialization dataWithJSONObject:_logs
                                          options:NSJSONWritingPrettyPrinted
                                            error:&error];

      NSString *jsonMessagesString =
          [[NSString alloc] initWithData:jsonMessages
                                encoding:NSUTF8StringEncoding];

      NSDictionary *mapData = [[NSDictionary alloc]
          initWithObjectsAndKeys:[Utils deviceUID], @"device_id", @"ios",
                                 @"device_type", jsonMessagesString, @"message",
                                 nil];

      NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData
                                                         options:0
                                                           error:&error];
      [request setHTTPBody:postData];

      if (!error) {

        NSURLSessionDataTask *postDataTask = [session
            dataTaskWithRequest:request
              completionHandler:^(NSData *data, NSURLResponse *response,
                                  NSError *error) {

                NSError *errorJson = nil;
                NSDictionary *responseDict =
                    [NSJSONSerialization JSONObjectWithData:data
                                                    options:kNilOptions
                                                      error:&errorJson];

                if (!errorJson && !error) {
                  [_logs removeAllObjects];
                  [_logs addObjectsFromArray:_queuedLogs];
                  [_queuedLogs removeAllObjects];
                  _isSendingLogs = NO;
                }

              }];

        [postDataTask resume];
      }
    }
  }
}

@end
