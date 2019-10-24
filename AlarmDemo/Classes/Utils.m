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

NSString *kBaseRegistrationURL = @"https://api.bcomesafe.com";
NSString *kBaseRegistrationDomain = @"api.bcomesafe.com";
NSString *kDefaultLoggerURL = @"https://api.bcomesafe.com/api/device/logger";
NSString *kDefaultCheckURLEnd = @"/check_connection/check.txt";
NSString *kDefaultSheltersUrlEnd = @"bcs/list";

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
    return [uid stringByAppendingString:@"_ios"];
  } else {
    NSString *new_uid =
        [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [self setDeviceUID:new_uid];
      return [new_uid stringByAppendingString:@"_ios"];
  }
}

+ (NSString*)createCheckUrl:(NSString*) url {
   @try {
        NSString *scheme = @"";
        if ([url rangeOfString:@"http://"].location != NSNotFound) {
            scheme = @"http://";
        } else if ([url rangeOfString:@"https://"].location != NSNotFound) {
            scheme = @"https://";
        } else {
            scheme = @"http://";
        }
        
        url = [[url stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByReplacingOccurrencesOfString:@"https://" withString:@""];
       NSArray *parts = [url componentsSeparatedByString:@"/"];
        url = parts[0];
        NSString *combinedUrl = [[scheme stringByAppendingString:url] stringByAppendingString: kDefaultCheckURLEnd];
        return combinedUrl;
    } @catch (NSException *e) {
        return @"";
    }
}

+ (NSString *)language {
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSDictionary *localizationDictionary = [NSLocale componentsFromLocaleIdentifier:language];
    return [localizationDictionary objectForKey:NSLocaleLanguageCode];
}

@end
