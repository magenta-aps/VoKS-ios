/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "StartController.h"
#import "Utils.h"



// "Private" methods
@interface StartController (Test)
- (void) registerDeviceWithUsername:(NSString *)username andPassword:(NSString *)password successBlock:(void (^)(NSDictionary *response)) successBlock failureBlock:(void (^)(NSError *error))failureBlock;

@end

@interface StartControllerTests : XCTestCase

@property (nonatomic) StartController *vcToTest;

@end

@implementation StartControllerTests

- (void)setUp {
    [super setUp];
    _vcToTest = [[StartController alloc] init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    _vcToTest = nil;
}


- (void)testDeviceUID
{
    NSString *deviceUID = [Utils deviceUID];
    
    XCTAssertNotNil(deviceUID);
}

- (void)testUserRegistrationWithoutUsernameAndPassword
{
   XCTestExpectation *completionExpectation = [self expectationWithDescription:@"User registration method"];
    
    [_vcToTest registerDeviceWithUsername:nil andPassword:nil
        successBlock:^(NSDictionary *response) {
            XCTAssertEqual(1, [[response objectForKey:@"status"]intValue], @"Result was unsuccessful!");
          [completionExpectation fulfill];
        } failureBlock:^(NSError *error) {
            XCTFail(@"Webservice fail");
        }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    XCTAssert(YES, @"Pass");
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
