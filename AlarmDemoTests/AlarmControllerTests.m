/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AlarmController.h"

@interface AlarmControllerTests : XCTestCase
@property (nonatomic) AlarmController *vcToTest;

@end



@implementation AlarmControllerTests


- (void)setUp {
    [super setUp];
    self.vcToTest = [[AlarmController alloc] init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testMethod
//{
//    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Registering Device"];
//    [self.vcToTest doSomethingThatTakesSomeTimesWithCompletionBlock:^(NSString *result) {
//        XCTAssertEqualObjects(@"result", result, @"Result was not correct!");
//        [completionExpectation fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:5.0 handler:nil];
//}

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
