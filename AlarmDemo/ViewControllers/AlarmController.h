/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import "MessageCell.h"
#import "Message.h"
#import "ShelterMessageCell.h"
#import "UserMessageCell.h"
#import "SystemMessageCell.h"
#import "NotificationMessageCell.h"

@interface AlarmController
    : UIViewController <UITableViewDataSource, UITableViewDelegate,
                        UITextFieldDelegate, NSURLSessionDelegate>

extern NSString *kDataChannelTypeMessage;
extern NSString *kDataChannelTypeListening;
extern NSString *kDataChannelTypeVideo;
extern NSString *kDataChannelTypeRequestCall;
extern NSString *kDataChannelTypeShelterStatus;
extern NSString *kDataChannelTypeSystemMessage;
extern NSString *kDataChannelTypeCallState;
extern NSString *kDataChannelTypeBatteryLevel;
extern NSString *kDataChannelTypeMessages;

@property(weak, nonatomic) IBOutlet UITableView *tvList;
@property(weak, nonatomic)
    IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property(weak, nonatomic) IBOutlet UIButton *callToShelterButton;
@property(weak, nonatomic) IBOutlet UITextField *chatTextField;
@property(weak, nonatomic) IBOutlet UIView *keyboardBarView;
@property(weak, nonatomic) IBOutlet UIView *dimView;
@property(nonatomic, retain) NSMutableArray *messages;
@property(weak, nonatomic) IBOutlet UIView *informationView;
@property(retain, nonatomic) MessageCell *prototypeCell;
// -------
@property(retain, nonatomic) ShelterMessageCell *prototypeShelterCell;
@property(retain, nonatomic) UserMessageCell *prototypeUserCell;
@property(retain, nonatomic) SystemMessageCell *prototypeSystemCell;
@property(retain, nonatomic) NotificationMessageCell *prototypeNotificationCell;
// -------
@property(weak, nonatomic) IBOutlet UILabel *tapLabel;
@property(nonatomic, retain) NSURLConnection *triggerAlarmConnection;
@property(nonatomic, retain) NSMutableData *responseData;
//@property(nonatomic, assign) ShelterCallState shelterCallState;
@property(nonatomic, retain) NSTimer *initialDimTimer;
@property(nonatomic, retain) NSDate *disconnectTime;
@property(nonatomic, assign) BOOL hasDimmed;

// Rotation
@property(nonatomic, assign) BOOL animatingRotation;
@property(nonatomic, assign) NSTimeInterval animationDuration;
@property(nonatomic, assign) UIViewAnimationCurve animationCurve;

// Proximity
@property(nonatomic, retain) UITapGestureRecognizer *dimTapRecognizer;

@property(nonatomic, assign) BOOL isInsertingMessage;

@property(nonatomic, retain) NSMutableArray *queuedMessages;

// Alarm Reset
@property(nonatomic, assign) BOOL forceReset;

// Keyboard visbility for rotation
@property(nonatomic, assign) BOOL isKeyboardVisible;



// IBActions
- (IBAction)onCallPoliceClicked:(id)sender;
- (IBAction)onHideClicked:(id)sender;
- (IBAction)onSeeChatClicked:(id)sender;
- (IBAction)onSendClicked:(id)sender;
- (IBAction)onCallToShelterClicked:(id)sender;

- (void)insertMessage:(Message *)message;

// Localizable Objects
@property(weak, nonatomic) IBOutlet UIButton *callPoliceButton;
@property(weak, nonatomic) IBOutlet UIButton *hideButton;
@property(weak, nonatomic) IBOutlet UIButton *sendButton;
@property(weak, nonatomic) IBOutlet UIButton *tapToHideButton;
@property (weak, nonatomic) IBOutlet UIButton *tapToChatButton;
@property(weak, nonatomic) IBOutlet UILabel *alarmIsActiveLabel;
@property(weak, nonatomic) IBOutlet UILabel *hideOrCallLabel;
@property(weak, nonatomic) IBOutlet UIButton *firstCallPoliceButton;

@end
