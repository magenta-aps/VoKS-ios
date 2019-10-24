#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShelterAPI : NSObject
+ (void)updateDevice:(NSDictionary *)parameters
          successBlock: (void (^)(void))successBlock
          failureBlock: (void (^)(void))failureBlock;
@end

NS_ASSUME_NONNULL_END
