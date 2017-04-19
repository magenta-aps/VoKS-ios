/*
* BComeSafe, http://bcomesafe.com 
* Copyright 2015 Magenta ApS, http://magenta.dk
* Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
* Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
*/

#import "Utils.h"
#import "UICKeyChainStore.h"
#import "KeychainItemWrapper.h"


@implementation Utils

NSString *kBaseRegistrationURL = @"https://voks.afk.no";
NSString *kBaseRegistrationDomain = @"voks.afk.no";
NSString *kDefaultLoggerURL = @"https://voks.afk.no/api/device/logger";

+ (void)setDeviceUID:(NSString *)deviceUID {
  KeychainItemWrapper *keychainItem =
      [[KeychainItemWrapper alloc] initWithIdentifier:@"BComeSafeAgent"
                                          accessGroup:nil];

  NSString *currentSecurityLevel =
      [keychainItem objectForKey:(__bridge id)(kSecAttrAccessible)];
  [keychainItem setObject:deviceUID forKey:(__bridge id)(kSecValueData)];
  if (![currentSecurityLevel
          isEqualToString:(__bridge NSString
                               *)(kSecAttrAccessibleAlwaysThisDeviceOnly)]) {
    [keychainItem
        setObject:(__bridge NSString *)kSecAttrAccessibleAlwaysThisDeviceOnly
           forKey:(__bridge id)kSecAttrAccessible];
  }
}

+ (NSString *)deviceUID {
  KeychainItemWrapper *keychainItem =
      [[KeychainItemWrapper alloc] initWithIdentifier:@"BComeSafeAgent"
                                          accessGroup:nil];
  NSString *uid = [keychainItem objectForKey:(__bridge id)(kSecValueData)];
  if (uid != nil && [uid length] > 0) {
    return uid;
  } else {
    NSString *new_uid =
        [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [self setDeviceUID:new_uid];
    return new_uid;
  }
}

@end
