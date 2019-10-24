/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import <MessageUI/MessageUI.h>
#import "TermsViewController.h"
#import "PhoneNumberViewController.h"
#import "PhoneConfirmViewController.h"

@interface StartController : UIViewController <NSURLConnectionDelegate, NSURLSessionDelegate, MFMailComposeViewControllerDelegate, TermsViewControllerDelegate, PhoneNumberViewControllerDelegate, PhoneConfirmViewControllerDelegate>

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
@property (weak, nonatomic) IBOutlet UIView *sideMenuView;

@property (assign, nonatomic) int failCount;


// Button events
- (IBAction)onStartAlarmClicked:(id)sender;
- (IBAction)onStartAlarmTouchDown:(id)sender;
- (IBAction)onCancelClicked:(id)sender;
- (IBAction)onCancelTouchDown:(id)sender;
- (IBAction)onPermissionsContinueClick:(id)sender;
- (IBAction)onPermissionsContinueCancel:(id)sender;
- (IBAction)onPermissionsContinueHold:(id)sender;

- (IBAction)onTermsAndConditionsClick:(UIButton *)sender;
- (IBAction)onPhoneNumberClick:(UIButton *)sender;
- (IBAction)onMenuCloseClick:(UIButton *)sender;
- (IBAction)onMenuClick:(UIButton *)sender;

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
@property (weak, nonatomic) IBOutlet UIButton *menuCloseButton;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIButton *termsAndCondidtionsButton;
@property (weak, nonatomic) IBOutlet UIButton *phoneNumberButton;


@property (weak, nonatomic) IBOutlet UILabel *debug1Label;
@property (weak, nonatomic) IBOutlet UILabel *debug2Label;
@property (weak, nonatomic) IBOutlet UILabel *debug3Label;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideMenuLeadingConstraint;

@property (assign, nonatomic) BOOL initializedView;
@end
