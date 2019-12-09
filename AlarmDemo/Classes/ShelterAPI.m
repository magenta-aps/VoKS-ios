#import "ShelterAPI.h"
#import "Utils.h"

@implementation ShelterAPI

+ (void)updateDevice:(NSDictionary *)parameters successBlock:(void (^)(void))successBlock failureBlock:(void (^)(void))failureBlock {
    NSURL *url = [NSURL URLWithString:
                  [NSString
                   stringWithFormat:
                   @"%@/api/device/"
                   @"update-device",
                   [[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];

    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:url
                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                        timeoutInterval:60.0];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [request setHTTPMethod:@"POST"];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:0
                                                         error:nil];

    [request setHTTPBody:postData];

    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];


    [[defaultSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            failureBlock();
            return;
        }

        NSError *errorJson = nil;
        NSDictionary *responseDict =
        [NSJSONSerialization JSONObjectWithData:data
                                        options:kNilOptions
                                          error:&errorJson];

        if (errorJson != nil) {
            failureBlock();
            return;
        }
        
        if ([[responseDict valueForKey:@"success"] boolValue] == YES) {
             successBlock();
        } else {
            failureBlock();
        }


        return;
    }] resume];
}
@end
