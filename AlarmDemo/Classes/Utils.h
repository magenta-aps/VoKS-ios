/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <Foundation/Foundation.h>

@interface Utils : NSObject

extern NSString *kBaseRegistrationURL;
extern NSString *kBaseRegistrationDomain;
extern NSString *kDefaultLoggerURL;

+ (void)setDeviceUID:(NSString *)deviceUID;
+ (NSString *)deviceUID;
@end
