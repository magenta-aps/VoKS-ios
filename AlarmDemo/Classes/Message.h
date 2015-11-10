/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <Foundation/Foundation.h>

@interface Message : NSObject
@property (nonatomic, assign) int type;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) BOOL hasRead;
@property (nonatomic, assign) long long timestamp;
@property (nonatomic, retain) NSNumber *uniqueId;

-(id) initWithType:(int) type andText:(NSString *) text andTimestamp:(long long)timestamp;


@end
