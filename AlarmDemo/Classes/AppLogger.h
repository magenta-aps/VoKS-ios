/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */


#import <Foundation/Foundation.h>

@interface AppLogger : NSObject

@property(nonatomic, retain) NSMutableArray *logs;
@property(nonatomic, retain) NSMutableArray *queuedLogs;
@property(nonatomic, assign) BOOL isSendingLogs;
@property(nonatomic, assign) BOOL isEnabled;
@property(nonatomic, assign) BOOL doSendToRemote;

+ (instancetype)sharedInstance;
- (void)logClass:(NSString *)className message:(NSString *)message;
- (void)sendLogsToRemote;
@end
