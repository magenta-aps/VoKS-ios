/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface StartController : UIViewController <NSURLConnectionDelegate, NSURLSessionDelegate>

// Connection info variable
@property (nonatomic, retain) Reachability *connectionInfo;

// Queued pushed notifications messages
@property (nonatomic, retain) NSMutableArray *queuedMessages;


// Buttons
@property (weak, nonatomic) IBOutlet UIButton *bStartAlarm;
@property (weak, nonatomic) IBOutlet UIButton *bCancel;
@property (weak, nonatomic) IBOutlet UIButton *permissionsContinueButton;


// Other views
@property (weak, nonatomic) IBOutlet UIView *permissionsPopupView;
@property (weak, nonatomic) IBOutlet UILabel *lNetworkError;


// Button events
- (IBAction)onStartAlarmClicked:(id)sender;
- (IBAction)onStartAlarmTouchDown:(id)sender;
- (IBAction)onCancelClicked:(id)sender;
- (IBAction)onCancelTouchDown:(id)sender;
- (IBAction)onPermissionsContinueClick:(id)sender;
- (IBAction)onPermissionsContinueCancel:(id)sender;
- (IBAction)onPermissionsContinueHold:(id)sender;

// Register device response data
@property (nonatomic, retain) NSMutableData *responseData;


// Localizable Objects
@property (weak, nonatomic) IBOutlet UIButton *tapToCancelButton;
@property (weak, nonatomic) IBOutlet UILabel *checkWifiLabel;

// Permissions Popup Localizable Objects
@property (weak, nonatomic) IBOutlet UILabel *permissionsPopupTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *permissionsPopupDetailsLabel;
@property (weak, nonatomic) IBOutlet UILabel *permissionsPopupPermissionsList;
@property (weak, nonatomic) IBOutlet UILabel *onlyOnceLabel;
@property (weak, nonatomic) IBOutlet UIButton *continueButtonn;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;



@end
