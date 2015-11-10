/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "Message.h"

@implementation Message

-(id) initWithType:(int) type andText:(NSString *) text andTimestamp:(long long)timestamp{
    
    if (self = [super init]){
        self.type = type;
        self.text = text;
        self.timestamp = timestamp == -1 ? [@(floor([[NSDate date]timeIntervalSince1970] * 1000)) longLongValue] : (long long)timestamp;
    }
    
    return self;
}

- (id)init{
    
    if (self = [super init]) {
        [self initializeWithType:0 andText:@""];
    }
    
    return self;
}

-(void) initializeWithType:(int) type andText:(NSString *) text {
    self.type = type;
    self.text = text;
}
@end
