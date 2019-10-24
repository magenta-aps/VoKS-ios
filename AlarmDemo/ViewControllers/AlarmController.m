/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "AlarmController.h"
#import <WebRTC/RTCAVFoundationVideoSource.h>
#import "ARDAppClient+Internal.h"
#import "AppLogger.h"
#import "ARDSettingsModel.h"
#import <WebRTC/RTCMediaConstraints.h>

#define SYSTEM_VERSION_LESS_THAN(v)                                            \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] ==       \
   NSOrderedAscending)

@interface AlarmController () <ARDAppClientDelegate>

@end

@implementation AlarmController {
  ARDAppClient *_client;
}

@synthesize callToShelterButton = _callToShelterButton;
@synthesize chatTextField = _chatTextField;
@synthesize keyboardBottomConstraint = _keyboardBottomConstraint;
@synthesize keyboardBarView = _keyboardBarView;
@synthesize dimView = _dimView;
@synthesize messages = _messages;
@synthesize informationView = _informationView;
//@synthesize prototypeCell = _prototypeCell;
@synthesize tapLabel = _tapLabel;
@synthesize responseData = _responseData;
@synthesize triggerAlarmConnection = _triggerAlarmConnection;
//@synthesize shelterCallState = _shelterCallState;
@synthesize initialDimTimer = _initialDimTimer;
@synthesize disconnectTime = _disconnectTime;
@synthesize dimTapRecognizer = _dimTapRecognizer;

#warning check this
@synthesize prototypeShelterCell = _prototypeShelterCell;
@synthesize prototypeSystemCell = _prototypeSystemCell;
@synthesize prototypeUserCell = _prototypeUserCell;
@synthesize prototypeNotificationCell = _prototypeNotificationCell;

NSString *kDataChannelTypeMessage = @"MESSAGE";
NSString *kDataChannelTypeListening = @"LISTENING";
NSString *kDataChannelTypeVideo = @"VIDEO";
NSString *kDataChannelTypeRequestCall = @"REQUEST_CALL";
NSString *kDataChannelTypeCallState = @"CALL_STATE";
NSString *kDataChannelTypeBatteryLevel = @"BATTERY_LEVEL";
NSString *kDataChannelTypeMessages = @"MESSAGES";

- (void)viewDidLoad {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewDidLoad"];
  [super viewDidLoad];

    
//    RTCAudioSession *session = [RTCAudioSession sharedInstance];
//    session.useManualAudio = useManualAudio;
//    session.isAudioEnabled = NO;

    
  [self prepareTexts];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone; // iOS 7 specific
  self.automaticallyAdjustsScrollViewInsets = NO;

  [self.navigationController.navigationBar setHidden:YES];
  // Do any additional setup after loading the view from its nib.
  _client = [[ARDAppClient alloc] initWithDelegate:self];
   
    
  if (_messages == nil)
    _messages = [NSMutableArray array];
  if (_queuedMessages == nil)
    _queuedMessages = [NSMutableArray array];
  self.tvList.delegate = self;
  self.tvList.dataSource = self;
  //    [self.tvList registerNib:[UINib nibWithNibName:@"MessageCell"
  //    bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"MessageCell"];
  [self.tvList registerNib:[UINib nibWithNibName:@"SystemMessageCell"
                                          bundle:[NSBundle mainBundle]]
      forCellReuseIdentifier:@"SystemMessageCell"];
  [self.tvList registerNib:[UINib nibWithNibName:@"UserMessageCell"
                                          bundle:[NSBundle mainBundle]]
      forCellReuseIdentifier:@"UserMessageCell"];
  [self.tvList registerNib:[UINib nibWithNibName:@"ShelterMessageCell"
                                          bundle:[NSBundle mainBundle]]
      forCellReuseIdentifier:@"ShelterMessageCell"];
    [self.tvList registerNib:[UINib nibWithNibName:@"NotificationMessageCell"
                                            bundle:[NSBundle mainBundle]]
      forCellReuseIdentifier:@"NotificationMessageCell"];

  // self.tvList.estimatedRowHeight = 44;
  // self.tvList.rowHeight = UITableViewAutomaticDimension;
  [self becomeFirstResponder];
  UITapGestureRecognizer *recognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(didTouchView)];
  [self.view addGestureRecognizer:recognizer];

  _dimTapRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(removeDim)];
  [_dimView addGestureRecognizer:_dimTapRecognizer];

  //_shelterCallState = kShelterCallStateNone;
  _chatTextField.delegate = self;
  UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
  _chatTextField.leftView = paddingView;
  _chatTextField.leftViewMode = UITextFieldViewModeAlways;

  [self sendTriggerAlarmRequest:NO];
}

- (void)prepareTexts {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"prepareTexts"];
  [_callPoliceButton setTitle:NSLocalizedString(@"button_call_police", nil)
                     forState:UIControlStateNormal];
  [_hideButton setTitle:NSLocalizedString(@"button_hide", nil)
               forState:UIControlStateNormal];
  [_sendButton setTitle:NSLocalizedString(@"button_send", nil)
               forState:UIControlStateNormal];
  [_tapToHideButton setTitle:NSLocalizedString(@"tap_to_hide", nil)
                    forState:UIControlStateNormal];
  [_alarmIsActiveLabel setText:NSLocalizedString(@"alarm_is_active", nil)];
  [_hideOrCallLabel setText:NSLocalizedString(@"hide_or_call", nil)];
  [_firstCallPoliceButton setTitle:NSLocalizedString(@"button_call_police", nil)
                          forState:UIControlStateNormal];

  [_chatTextField setPlaceholder:NSLocalizedString(@"type_message", nil)];
  [_tapLabel setText:NSLocalizedString(@"tap_to_see", nil)];
    [_tapToChatButton setTitle:NSLocalizedString(@"tap_to_chat", nil) forState:UIControlStateNormal];
    [_tapToChatButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)didTouchView {
  [self becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewWillAppear"];
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(batteryLevelChanged:)
             name:UIDeviceBatteryLevelDidChangeNotification
           object:nil];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillChangeFrame:)
             name:UIKeyboardWillChangeFrameNotification
           object:nil];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillShow:)
             name:UIKeyboardWillShowNotification
           object:nil];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(proximityStateChanged:)
             name:UIDeviceProximityStateDidChangeNotification
           object:nil];

  [UIDevice currentDevice].batteryMonitoringEnabled = YES;
  [UIDevice currentDevice].proximityMonitoringEnabled = YES;

  [self updateBatteryLevel];
}

- (void)viewWillDisappear:(BOOL)animated {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewWillDisappear"];
  [super viewWillDisappear:animated];
  [_chatTextField resignFirstResponder];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillChangeFrameNotification
              object:nil];

  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIDeviceBatteryLevelDidChangeNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIDeviceProximityStateDidChangeNotification
              object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewDidDisappear"];
  [super viewDidDisappear:animated];
}

- (void)removeDim {
  [UIView animateWithDuration:0.5
      animations:^{
        _dimView.alpha = 0;
      }
      completion:^(BOOL finished) {
        _tapLabel.alpha = 1;
      }];
  self.hasDimmed = YES;
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"removeDim"];
}

- (void)showDim {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"showDim"];
  if (_initialDimTimer) {
    [_initialDimTimer invalidate];
    _initialDimTimer = nil;
  }
  [_chatTextField resignFirstResponder];
  [UIView animateWithDuration:0.5
      animations:^{
        _dimView.alpha = 1;
      }
      completion:^(BOOL finished) {
        if (!_informationView.hidden)
          [_informationView setHidden:YES];
        [UIView animateWithDuration:0.5
            delay:1
            options:UIViewAnimationOptionTransitionNone
            animations:^{
              _tapLabel.alpha = 0;
            }
            completion:^(BOOL finished){
                //
            }];
      }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"didReceivedMemoryWarning"];
  // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewDidAppeaer"];
  [super viewDidAppear:animated];
  if (!self.hasDimmed)
    _initialDimTimer =
        [NSTimer scheduledTimerWithTimeInterval:5
                                         target:self
                                       selector:@selector(showDim)
                                       userInfo:nil
                                        repeats:NO];
}
#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client
   didChangeState:(ARDAppClientState)state {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"Client changed state: %li", (long)state]];
  switch (state) {
  case kARDAppClientStateConnected:
    break;
  case kARDAppClientStateConnecting:
    break;
  case kARDAppClientStateDisconnected:
    //    if (_forceReset) {
    //      [self endAlarm];
    //    }
    //    } else {
    //      _shelterCallState = kShelterCallStateNone;
    //      [_callToShelterButton
    //          setBackgroundImage:[UIImage imageNamed:@"call_inactive"]
    //                    forState:UIControlStateNormal];
    //      [_callToShelterButton
    //          setBackgroundImage:[UIImage imageNamed:@"call_inactive"]
    //                    forState:UIControlStateHighlighted];
    //      _disconnectTime = [NSDate date];
    //    }
    break;
  }
}

- (void)appClient:(ARDAppClient *)client
    didChangeConnectionState:(RTCIceConnectionState)state {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"ICE state changed: %li", (long)state]];
  //    __weak ARDVideoCallViewController *weakSelf = self;
}

- (void)appClient:(ARDAppClient *)client
    didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
  //    if (!_localVideoTrack) {
  //        _localVideoTrack = localVideoTrack;
  //        [_localVideoTrack addRenderer:_videoCallView.localVideoView];
  //    }
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"didReceivedLocalVideoTrack"]];
}

- (void)appClient:(ARDAppClient *)client
    didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
  //  if (!_remoteVideoTrack) {
  //    _remoteVideoTrack = remoteVideoTrack;
  //    [_remoteVideoTrack addRenderer:_videoCallView.remoteVideoView];
  //    _videoCallView.statusLabel.hidden = YES;
  //  }
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
  //    NSString *message =
  //    [NSString stringWithFormat:@"%@", error.localizedDescription];
  //    [self showAlertWithMessage:message];
  //    [self hangup];
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"Client didError: %@", error.description]];
}

- (void)appClient:(ARDAppClient *)client didReceivedMessage:(Message *)message {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"Client didReceivedMessage: %li",
                                          (long)message.type]];
  [self insertMessage:message];
}

- (void)appClient:(ARDAppClient *)client
    didReceivedListeningStateChange:(BOOL)state {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:
                             @"Client didReceivedListeningStateChange: %li",
                             (long)state]];
  if (state) {
    [_client resumeRemoteAudioStreaming];
    if (_client.callState == kShelterCallStateCalling) {
      [_client setCallState:kShelterCallStateAnswered];
      dispatch_async(dispatch_get_main_queue(), ^{

        [_callToShelterButton
            setBackgroundImage:[UIImage imageNamed:@"drop_active"]
                      forState:UIControlStateNormal];
        [_callToShelterButton
            setBackgroundImage:[UIImage imageNamed:@"drop_press"]
                      forState:UIControlStateHighlighted];

      });
      Message *systemMessage = [[Message alloc]
          initWithType:2
               andText:NSLocalizedString(@"crisis_team_answered", nil)
          andTimestamp:-1];
      [self insertMessage:systemMessage];

    } else if (_client.callState == kShelterCallStateOnHold) {
      [_client setCallState:kShelterCallStateAnswered];
      Message *systemMessage = [[Message alloc]
          initWithType:2
               andText:NSLocalizedString(@"crisis_team_resumed", nil)
          andTimestamp:-1];
      [self insertMessage:systemMessage];
    }

  } else {
    if (_client.callState == kShelterCallStateAnswered) {
      [_client setCallState:kShelterCallStateOnHold];
      [_client muteRemoteAudioStreaming];
      Message *systemMessage = [[Message alloc]
          initWithType:2
               andText:NSLocalizedString(@"crisis_team_hold", nil)
          andTimestamp:-1];

      [self insertMessage:systemMessage];
    }
  }
}

- (void)appClientDidResumeCallState:(ARDAppClient *)client {
  dispatch_async(dispatch_get_main_queue(), ^{

    [_callToShelterButton setBackgroundImage:[UIImage imageNamed:@"drop_active"]
                                    forState:UIControlStateNormal];
    [_callToShelterButton setBackgroundImage:[UIImage imageNamed:@"drop_press"]
                                    forState:UIControlStateHighlighted];

  });
}

- (void)appClient:(ARDAppClient *)client
    didChangeShelterState:(ShelterState)state {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"Client didChangeShelterState %li",
                                          (long)state]];
  switch (state) {
  case kShelterStateDisconnected:
  case kShelterStateOffline: {
    [_callToShelterButton
        setBackgroundImage:[UIImage imageNamed:@"call_inactive"]
                  forState:UIControlStateNormal];
    [_callToShelterButton
        setBackgroundImage:[UIImage imageNamed:@"call_inactive"]
                  forState:UIControlStateHighlighted];
    break;
  }
  case kShelterStateOnline: {
    [_callToShelterButton setBackgroundImage:[UIImage imageNamed:@"call_active"]
                                    forState:UIControlStateNormal];
    [_callToShelterButton setBackgroundImage:[UIImage imageNamed:@"call_press"]
                                    forState:UIControlStateHighlighted];
    break;
  }
  }
}

- (void)appClient:(ARDAppClient *)client sendSystemMessage:(NSString *)message {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"Client sendSystemMessage"]];
  Message *systemMsg =
      [[Message alloc] initWithType:2 andText:message andTimestamp:-1];
  [self insertMessage:systemMsg];
}

- (void)appClientDidReceivedAlarmReset:(ARDAppClient *)client {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"Client didReceiveAlarmReset"]];
  _forceReset = YES;
  [self endAlarm];
}

#pragma mark - UITableView delegate

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  Message *message = [_messages objectAtIndex:indexPath.row];

  switch (message.type) {
  case 0: {
    UserMessageCell *cell = (UserMessageCell *)
        [tableView dequeueReusableCellWithIdentifier:@"UserMessageCell"];
    if (cell == nil) {
      // Load the top-level objects from the custom cell XIB.
      NSArray *topLevelObjects =
          [[NSBundle mainBundle] loadNibNamed:@"UserMessageCell"
                                        owner:self
                                      options:nil];
      // Grab a pointer to the first object (presumably the custom cell, as
      // that's all the XIB should contain).

      for (id object in topLevelObjects) {
        if ([object isKindOfClass:[UserMessageCell class]]) {
          cell = (UserMessageCell *)object;
          break;
        }
      }
    }
    //[self configureUserCell:cell withMessage:message];
    return cell;
  }
  case 1: {
    ShelterMessageCell *cell = (ShelterMessageCell *)
        [tableView dequeueReusableCellWithIdentifier:@"ShelterMessageCell"];
    if (cell == nil) {
      // Load the top-level objects from the custom cell XIB.
      NSArray *topLevelObjects =
          [[NSBundle mainBundle] loadNibNamed:@"ShelterMessageCell"
                                        owner:self
                                      options:nil];
      // Grab a pointer to the first object (presumably the custom cell, as
      // that's all the XIB should contain).

      for (id object in topLevelObjects) {
        if ([object isKindOfClass:[ShelterMessageCell class]]) {
          cell = (ShelterMessageCell *)object;
          break;
        }
      }
    }
    // [self configureShelterCell:cell withMessage:message];
    return cell;
  }
  case 2:
      {SystemMessageCell *cell = (SystemMessageCell *)
          [tableView dequeueReusableCellWithIdentifier:@"SystemMessageCell"];
          if (cell == nil) {
              // Load the top-level objects from the custom cell XIB.
              NSArray *topLevelObjects =
              [[NSBundle mainBundle] loadNibNamed:@"SystemMessageCell"
                                            owner:self
                                          options:nil];
              // Grab a pointer to the first object (presumably the custom cell, as
              // that's all the XIB should contain).
              
              for (id object in topLevelObjects) {
                  if ([object isKindOfClass:[SystemMessageCell class]]) {
                      cell = (SystemMessageCell *)object;
                      break;
                  }
              }
          }
           return cell;
      }
  case 3: {
      NotificationMessageCell *cell = (NotificationMessageCell *)
      [tableView dequeueReusableCellWithIdentifier:@"NotificationMessageCell"];
      if (cell == nil) {
          // Load the top-level objects from the custom cell XIB.
          NSArray *topLevelObjects =
          [[NSBundle mainBundle] loadNibNamed:@"NotificationMessageCell"
                                        owner:self
                                      options:nil];
          // Grab a pointer to the first object (presumably the custom cell, as
          // that's all the XIB should contain).
          
          for (id object in topLevelObjects) {
              if ([object isKindOfClass:[NotificationMessageCell class]]) {
                  cell = (NotificationMessageCell *)object;
                  break;
              }
          }
      }
    return cell;
  }
  }

  return nil;

  //    MessageCell *cell = (MessageCell*)[tableView
  //    dequeueReusableCellWithIdentifier:@"MessageCell"];
  //    if (cell == nil) {
  //        // Load the top-level objects from the custom cell XIB.
  //        NSArray *topLevelObjects = [[NSBundle mainBundle]
  //        loadNibNamed:@"MessageCell" owner:self options:nil];
  //        // Grab a pointer to the first object (presumably the custom cell,
  //        as that's all the XIB should contain).
  //
  //        for (id object in topLevelObjects) {
  //            if ([object isKindOfClass:[MessageCell class]]) {
  //                cell = (MessageCell *)object;
  //                break;
  //            }
  //        }
  //    }
  //
  //    [self configureCell:cell atIndexPath:indexPath];
  //    return cell;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  Message *message = [_messages objectAtIndex:indexPath.row];

  if ([cell isKindOfClass:[UserMessageCell class]]) {
    [self configureUserCell:(UserMessageCell *)cell withMessage:message];
  } else if ([cell isKindOfClass:[ShelterMessageCell class]]) {
    [self configureShelterCell:(ShelterMessageCell *)cell withMessage:message];
  } else if ([cell isKindOfClass:[SystemMessageCell class]]) {
    [self configureSystemCell:(SystemMessageCell *)cell
                  withMessage:message];
  } else if ([cell isKindOfClass:[NotificationMessageCell class]]){
      [self configureNotificationCell:(NotificationMessageCell *)cell withMessage:message hasGotItButton:!message.hasRead];
  }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [_messages count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  Message *rowMessage = [_messages objectAtIndex:indexPath.row];

  switch (rowMessage.type) {
  case 0:
    [self configureUserCell:[self prototypeUserCell] withMessage:rowMessage];
    [_prototypeUserCell layoutIfNeeded];

    return [_prototypeUserCell.contentView
               systemLayoutSizeFittingSize:UILayoutFittingCompressedSize]
        .height;
  case 1:
    [self configureShelterCell:[self prototypeShelterCell]
                   withMessage:rowMessage];
    [_prototypeShelterCell layoutIfNeeded];

    return [_prototypeShelterCell.contentView
               systemLayoutSizeFittingSize:UILayoutFittingCompressedSize]
        .height;
  case 2:
          [self configureSystemCell:[self prototypeSystemCell] withMessage:rowMessage];
          [_prototypeSystemCell layoutIfNeeded];
          return [_prototypeSystemCell.contentView
                  systemLayoutSizeFittingSize:UILayoutFittingCompressedSize]
          .height;
  case 3:
    [self configureNotificationCell:[self prototypeNotificationCell]
                  withMessage:rowMessage
               hasGotItButton:!rowMessage.hasRead];
    [_prototypeNotificationCell layoutIfNeeded];
    return [_prototypeNotificationCell.contentView
               systemLayoutSizeFittingSize:UILayoutFittingCompressedSize]
        .height;
  default:
    return 44.0f;
  }
}

#pragma mark - PrototypeCell

- (UserMessageCell *)prototypeUserCell {
  if (!_prototypeUserCell) {
    _prototypeUserCell =
        [_tvList dequeueReusableCellWithIdentifier:@"UserMessageCell"];
    _prototypeUserCell.contentView.translatesAutoresizingMaskIntoConstraints =
        NO;
    _prototypeUserCell.messageTextLabel.preferredMaxLayoutWidth =
        self.view.frame.size.width - 10;
  }

  return _prototypeUserCell;
}

- (ShelterMessageCell *)prototypeShelterCell {
  if (!_prototypeShelterCell) {
    _prototypeShelterCell =
        [_tvList dequeueReusableCellWithIdentifier:@"ShelterMessageCell"];
    _prototypeShelterCell.contentView
        .translatesAutoresizingMaskIntoConstraints = NO;
    _prototypeShelterCell.messageTextLabel.preferredMaxLayoutWidth =
        self.view.frame.size.width - 10;
  }

  return _prototypeShelterCell;
}

- (SystemMessageCell *)prototypeSystemCell {
  if (!_prototypeSystemCell) {
    _prototypeSystemCell =
        [_tvList dequeueReusableCellWithIdentifier:@"SystemMessageCell"];
    _prototypeSystemCell.contentView.translatesAutoresizingMaskIntoConstraints =
        NO;
    _prototypeSystemCell.messageTextLabel.preferredMaxLayoutWidth =
        self.view.frame.size.width - 10;
    //        [_prototypeSystemCell.gotItButton
    //        setTranslatesAutoresizingMaskIntoConstraints:NO];
  }

  return _prototypeSystemCell;
}

- (NotificationMessageCell *)prototypeNotificationCell {
    if (!_prototypeNotificationCell) {
        _prototypeNotificationCell =
        [_tvList dequeueReusableCellWithIdentifier:@"NotificationMessageCell"];
        _prototypeNotificationCell.contentView.translatesAutoresizingMaskIntoConstraints =
        NO;
        _prototypeNotificationCell.messageTextLabel.preferredMaxLayoutWidth =
        self.view.frame.size.width - 10;
        //        [_prototypeSystemCell.gotItButton
        //        setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    
    return _prototypeNotificationCell;
}


#pragma mark - Configure
//- (void) configureCell:(MessageCell*)cell atIndexPath:(NSIndexPath *)
// indexPath {
//    Message *item = [_messages objectAtIndex:indexPath.row];
//    [cell setType:item.type andText:item.text andUniqueID:item.uniqueId];
//}

- (void)configureUserCell:(UserMessageCell *)cell
              withMessage:(Message *)message {
  [cell.messageTextLabel setText:message.text];
  //    [cell.messageTextLabel sizeToFit];
  [cell.bubbleImage
      setImage:[[UIImage imageNamed:@"chat_right"]
                   resizableImageWithCapInsets:UIEdgeInsetsMake(5, 10, 20, 35)
                                  resizingMode:UIImageResizingModeStretch]];
}

- (void)configureShelterCell:(ShelterMessageCell *)cell
                 withMessage:(Message *)message {
  [cell.messageTextLabel setText:message.text];

  [cell.messageTextLabel setTextColor:[UIColor blackColor]];
  UIColor *color = [UIColor lightGrayColor]; // select needed color
  NSString *string = NSLocalizedString(@"crisis_team_chat", nil);
  NSDictionary *attrs = @{NSForegroundColorAttributeName : color};
  NSMutableAttributedString *attrStr =
      [[NSMutableAttributedString alloc] initWithString:string
                                             attributes:attrs];
  [attrStr appendAttributedString:[[NSAttributedString alloc]
                                      initWithString:message.text]];
  cell.messageTextLabel.attributedText = attrStr;
  [cell.messageTextLabel sizeToFit];

  [cell.bubbleImage
      setImage:[[UIImage imageNamed:@"chat_left"]
                   resizableImageWithCapInsets:UIEdgeInsetsMake(5, 35, 20, 10)
                                  resizingMode:UIImageResizingModeStretch]];
}

- (void)configureSystemCell:(SystemMessageCell *)cell withMessage:(Message *)message{
    cell.messageTextLabel.preferredMaxLayoutWidth =
    self.view.frame.size.width - 20;
    cell.containerView.layer.cornerRadius = 4;
    [cell.messageTextLabel setText:message.text];
}

- (void)configureNotificationCell:(NotificationMessageCell *)cell
                withMessage:(Message *)message
             hasGotItButton:(BOOL)hasButton {
  cell.messageTextLabel.preferredMaxLayoutWidth =
      self.view.frame.size.width - 20;
  cell.containerView.layer.cornerRadius = 4;
  [cell.messageTextLabel setText:message.text];

  if (hasButton) {
    cell.msg = message;
    if (cell.gotItButton == nil) {
      for (NSLayoutConstraint *constraint in cell.containerView.constraints) {
        if (((constraint.firstItem == cell.messageTextLabel &&
              constraint.secondItem == cell.containerView) ||
             (constraint.secondItem == cell.messageTextLabel &&
              constraint.firstItem == cell.containerView)) &&
            (constraint.firstAttribute == NSLayoutAttributeBottom ||
             constraint.secondAttribute == NSLayoutAttributeBottom)) {
          [cell.containerView removeConstraint:constraint];
        }
      }

      cell.gotItButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [cell.gotItButton setTranslatesAutoresizingMaskIntoConstraints:NO];
      [cell.gotItButton setTitle:NSLocalizedString(@"got_it_button", nil) forState:UIControlStateNormal];
      [cell.gotItButton addTarget:cell
                           action:@selector(sendGotIt:)
                 forControlEvents:UIControlEventTouchUpInside];
      cell.gotItButton.layer.borderWidth = 1;
      cell.gotItButton.layer.borderColor = [UIColor whiteColor].CGColor;
      cell.gotItButton.layer.cornerRadius = 4;

      [cell.containerView addSubview:cell.gotItButton];

      NSLayoutConstraint *topButtonConstraint =
          [NSLayoutConstraint constraintWithItem:cell.gotItButton
                                       attribute:NSLayoutAttributeTop
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:cell.messageTextLabel
                                       attribute:NSLayoutAttributeBottom
                                      multiplier:1
                                        constant:10];

      NSLayoutConstraint *widthConstraint =
          [NSLayoutConstraint constraintWithItem:cell.gotItButton
                                       attribute:NSLayoutAttributeWidth
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:nil
                                       attribute:NSLayoutAttributeNotAnAttribute
                                      multiplier:1
                                        constant:80];

      NSLayoutConstraint *centerConstraint =
          [NSLayoutConstraint constraintWithItem:cell.gotItButton
                                       attribute:NSLayoutAttributeCenterX
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:cell.containerView
                                       attribute:NSLayoutAttributeCenterX
                                      multiplier:1
                                        constant:0];

      NSLayoutConstraint *bottomConstraint =
          [NSLayoutConstraint constraintWithItem:cell.containerView
                                       attribute:NSLayoutAttributeBottom
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:cell.gotItButton
                                       attribute:NSLayoutAttributeBottom
                                      multiplier:1
                                        constant:10];

      [cell.gotItButton addConstraint:widthConstraint];

      [cell.containerView addConstraint:topButtonConstraint];
      [cell.containerView addConstraint:centerConstraint];
      [cell.containerView addConstraint:bottomConstraint];
    }
    // cell.gotItButton.tag = [message.uniqueId intValue];
  } else {
    if (cell.gotItButton != nil) {
      [cell.gotItButton removeTarget:cell
                              action:@selector(sendGotIt:)
                    forControlEvents:UIControlEventTouchUpInside];
      [cell.gotItButton removeFromSuperview];
      cell.gotItButton = nil;

      NSLayoutConstraint *bottomConstraint =
          [NSLayoutConstraint constraintWithItem:cell.containerView
                                       attribute:NSLayoutAttributeBottom
                                       relatedBy:NSLayoutRelationEqual
                                          toItem:cell.messageTextLabel
                                       attribute:NSLayoutAttributeBottom
                                      multiplier:1
                                        constant:10];

      [cell.containerView addConstraint:bottomConstraint];
    }
  }
}

#pragma mark - private

- (IBAction)onCallPoliceClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"onCallPoliceClicked"]];
  [self sendTriggerAlarmRequest:YES];
    
    NSString *policeNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"police_number"];
    
    if (policeNumber) {
        NSString *phoneNumber = [@"tel://" stringByAppendingString:policeNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
}

- (IBAction)onHideClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"onHideClicked"]];
  [self showDim];
}

- (IBAction)onSeeChatClicked:(id)sender{
    [_initialDimTimer invalidate];
    _initialDimTimer = nil;
    _hasDimmed = YES;
    
    [UIView animateWithDuration:0.5
animations:^{
    _informationView.alpha = 0;
}
completion:^(BOOL finished){
    _informationView.hidden = YES;
}];
}

- (IBAction)onSendClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"onSendClicked"]];
  if (_chatTextField.text.length == 0)
    return;

  Message *outgoingMessage = [[Message alloc] initWithType:0
                                                   andText:_chatTextField.text
                                              andTimestamp:-1];
  [_client sendChatMessage:outgoingMessage];

  [self insertMessage:outgoingMessage];
  _chatTextField.text = @"";
  [UIDevice currentDevice].proximityMonitoringEnabled = YES;
}

- (IBAction)onCallToShelterClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"onCallToShelterClicked, shelterState: "
                                    @"%li , shelterCallState: %li",
                                    _client.shelterState, _client.callState]];
  if (_client.shelterState == kShelterStateDisconnected ||
      _client.shelterState == kShelterStateOffline) {
    return;
  }
  if (_client.shelterState == kShelterStateOnline) {
    switch (_client.callState) {
    case kShelterCallStateNone: {
      [_client sendRequestCall:YES];
      //      [_client sendMessageToDataChannel:
      //                   [NSString
      //                   stringWithFormat:@"{\"type\":\"%@\",\"data\":%i}",
      //                                              kDataChannelTypeRequestCall,
      //                                              1]];
      [_callToShelterButton
          setBackgroundImage:[UIImage imageNamed:@"drop_active"]
                    forState:UIControlStateNormal];
      [_callToShelterButton
          setBackgroundImage:[UIImage imageNamed:@"drop_press"]
                    forState:UIControlStateHighlighted];
      Message *systemMessage = [[Message alloc]
          initWithType:2
               andText:NSLocalizedString(@"calling_crisis_team", nil)
          andTimestamp:-1];
      [self insertMessage:systemMessage];

      [_client setCallState:kShelterCallStateCalling];
      break;
    }
    case kShelterCallStateCalling:
    case kShelterCallStateAnswered:
    case kShelterCallStateOnHold: {
      [_client sendRequestCall:NO];
      //      [_client sendMessageToDataChannel:
      //                   [NSString
      //                   stringWithFormat:@"{\"type\":\"%@\",\"data\":%i}",
      //                                              kDataChannelTypeRequestCall,
      //                                              0]];
      [_callToShelterButton
          setBackgroundImage:[UIImage imageNamed:@"call_active"]
                    forState:UIControlStateNormal];
      [_callToShelterButton
          setBackgroundImage:[UIImage imageNamed:@"call_press"]
                    forState:UIControlStateHighlighted];
      [_client muteRemoteAudioStreaming];
      Message *systemMessage = [[Message alloc]
          initWithType:2
               andText:NSLocalizedString(@"call_crisis_team_ended", nil)
          andTimestamp:-1];
      [self insertMessage:systemMessage];

      [_client setCallState:kShelterCallStateNone];

      break;
    }
    }
  }
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self onSendClicked:textField];
  return YES;
}

- (CGFloat)getListContentInset {
  NSInteger numRows = [_tvList numberOfRowsInSection:0];
  CGFloat contentInsetTop = _tvList.frame.size.height;

  for (int i = 0; i < numRows; i++) {
    contentInsetTop -= [self
                      tableView:_tvList
        heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    if (contentInsetTop <= 0) {
      contentInsetTop = 0;
      break;
    }
  }

  return contentInsetTop;
}

- (CGFloat)getListContentInset:(float)tableViewOffset {
  NSInteger numRows = [_tvList numberOfRowsInSection:0];
  CGFloat contentInsetTop =
      (self.view.frame.size.height - 20 /*Status Bar*/ - 55 /* Nav Bar */ -
       self.keyboardBarView.frame.size.height) +
      tableViewOffset;
  for (int i = 0; i < numRows; i++) {
    contentInsetTop -= [self
                      tableView:_tvList
        heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    if (contentInsetTop <= 0) {
      contentInsetTop = 0;
      break;
    }
  }

  return contentInsetTop;
}

- (CGFloat)getListContentInset:(float)tableViewOffset frameSize:(CGSize)size {
  NSInteger numRows = [_tvList numberOfRowsInSection:0];
  CGFloat contentInsetTop = size.height;
  for (int i = 0; i < numRows; i++) {
    contentInsetTop -= [self
                      tableView:_tvList
        heightForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    if (contentInsetTop <= 0) {
      contentInsetTop = 0;
      break;
    }
  }

  return contentInsetTop;
}

- (int)findIndexToInsert:(Message *)messageToInsert
   shouldIgnoreTimestamp:(BOOL)ignoreTimestamp {
  if (ignoreTimestamp || [_messages count] == 0) {
    return (int)[_messages count];
  }

  for (int i = (int)[_messages count] - 1; i >= 0; i--) {
    Message *listMessage = [_messages objectAtIndex:i];
    if (messageToInsert.timestamp > listMessage.timestamp) {
      return i + 1;
    }
  }

  return 0;
}

- (void)batteryLevelChanged:(NSNotification *)notification {
  [self updateBatteryLevel];
}

- (void)updateBatteryLevel {
  float batteryLevel = [UIDevice currentDevice].batteryLevel;
  if (batteryLevel >
      0.0) { // -1.0 means battery state is UIDeviceBatteryStateUnknown

    //    NSString *message =
    //        [NSString stringWithFormat:@"{\"type\":\"%@\",\"data\":\"%i\"}",
    //                                   kDataChannelTypeBatteryLevel,
    //                                   (int)(batteryLevel * 100)];
    //    if (_client.shelterState == kShelterStateOnline && _client.channel !=
    //    nil) {
    [_client sendBatteryLevel:(int)(batteryLevel * 100)];
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString stringWithFormat:@"updateBatteryLevel: %i",
                                            (int)batteryLevel * 100]];
    //    } else {
    //      [_queuedMessages addObject:message];
    //    }
  }
}

- (void)proximityStateChanged:(NSNotificationCenter *)notification {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"proximityStateChanged, state: %i",
                                    [UIDevice currentDevice].proximityState]];
  if (_dimView.alpha == 0 && [UIDevice currentDevice].proximityState == YES) {
    [self showDim];
    [_dimTapRecognizer setEnabled:NO];
  } else if (![UIDevice currentDevice].proximityState) {
    [_dimTapRecognizer setEnabled:YES];
  }
}

- (void)insertMessage:(Message *)message {
  if (_forceReset) {
    return;
  }

  if (self.isInsertingMessage) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
                     [self insertMessage:message];
                   });
    return;
  }
  self.isInsertingMessage = YES;

  int index = [self findIndexToInsert:message shouldIgnoreTimestamp:NO];

  BOOL shouldScrollToBottom = NO;

  if ((int)self.tvList.contentOffset.y - (int)(self.tvList.contentSize.height -
                                               self.tvList.frame.size.height) >=
      -42) {
    shouldScrollToBottom = YES;
  }

  UITableViewRowAnimation insertAnimation;

  switch (message.type) {
  case 0:
    insertAnimation = UITableViewRowAnimationRight;
    break;
  case 1:
    insertAnimation = UITableViewRowAnimationLeft;
    break;
  case 2:
  case 3:
  default:
    insertAnimation = UITableViewRowAnimationBottom;
    break;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tvList beginUpdates];
    int testIndex = index;
    if (index == 0) {
      [_messages addObject:message];
      testIndex = (int)[_messages count] - 1;
    } else {
      [_messages insertObject:message atIndex:index];
    }

    [self.tvList insertRowsAtIndexPaths:@[
      [NSIndexPath indexPathForRow:testIndex inSection:0]
    ] withRowAnimation:insertAnimation];

    [self.tvList endUpdates];
    [self.tvList
        setContentInset:UIEdgeInsetsMake([self getListContentInset], 0, 0, 0)];
    // [self.tvList reloadData];
    if (shouldScrollToBottom) {
      [self.tvList
          scrollToRowAtIndexPath:
              [NSIndexPath indexPathForRow:(_messages.count - 1)inSection:0]
                atScrollPosition:UITableViewScrollPositionBottom
                        animated:YES];
    }

    self.isInsertingMessage = NO;
  });
}

#pragma mark - Rotations
// called on iOS-7 and below on step: #1
- (void)willRotateToInterfaceOrientation:
            (UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation
                                 duration:duration];
  self.animatingRotation = YES;
}

// called on iOS-7 and below on step: #3
- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                          duration:duration];

  if (!_isKeyboardVisible) {
    _tvList.contentInset = UIEdgeInsetsMake(
        [self getListContentInset:0
                        frameSize:CGSizeMake(self.view.frame.size.width,
                                             self.view.frame.size.height)],
        0, 0, 0);
    [_tvList scrollToRowAtIndexPath:[NSIndexPath
                                        indexPathForItem:([_messages count] - 1)
                                               inSection:0]
                   atScrollPosition:UITableViewScrollPositionBottom
                           animated:YES];
  }
}

// called on iOS-7 and below on step: #5
- (void)didRotateFromInterfaceOrientation:
    (UIInterfaceOrientation)fromInterfaceOrientation {
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  self.animatingRotation = NO;
}
// called on iOS-8 on step: #1
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
           (id<UIViewControllerTransitionCoordinator>)coordinator {
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone; // iOS 7 specific
  self.automaticallyAdjustsScrollViewInsets = NO;

  //CGFloat contentTopInset = [self getListContentInset:0 frameSize:size];
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  [coordinator animateAlongsideTransition:^(id<
      UIViewControllerTransitionCoordinatorContext> context) {
    // called on step: #2
    self.animationDuration = [context transitionDuration];
    self.animationCurve = [context completionCurve];
    self.animatingRotation = YES;

    // if keyboard isn't visible, update list content size

    if (!_isKeyboardVisible) {
      [self
          adjustViewsForKeyboardFrame:CGRectMake(0, self.view.frame.size.height,
                                                 0, 0)
                withAnimationDuration:self.animationDuration
                       animationCurve:self.animationCurve];
    }
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    // called on step: #5
    self.animatingRotation = NO;

  }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
  _isKeyboardVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
  _isKeyboardVisible = NO;
}

// called on iOS-7 and below on steps: #2, #4
// called on iOS-8 on steps: #3, #4, #6, #7
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
  [self adjustViewForKeyboardNotification:notification];
}

- (void)adjustViewForKeyboardNotification:(NSNotification *)notification {
  NSDictionary *notificationInfo = [notification userInfo];

  // Get the end frame of the keyboard in screen coordinates.
  CGRect finalKeyboardFrame = [[notificationInfo
      objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

  // Convert the finalKeyboardFrame to view coordinates to take into account any
  // rotation
  // factors applied to the window’s contents as a result of interface
  // orientation changes.
  finalKeyboardFrame =
      [self.view convertRect:finalKeyboardFrame fromView:self.view.window];

  if (!self.animatingRotation) {
    // Get the animation curve and duration frp, keyboard notification info
    UIViewAnimationCurve animationCurve =
        (UIViewAnimationCurve)[[notificationInfo
            objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval animationDuration = [[notificationInfo
        objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    // On iOS8 if the animationDuration is 0,
    // then the quicktype panel is being shown/hidden and the code executed here
    // will be animated automatically
    if (animationDuration == 0) {
      [self adjustViewsForKeyboardFrame:finalKeyboardFrame
                      adjustListContent:YES];
    } else {
      [self adjustViewsForKeyboardFrame:finalKeyboardFrame
                  withAnimationDuration:animationDuration
                         animationCurve:animationCurve];
    }
  } else {
    if ([UIView areAnimationsEnabled]) {
      [self adjustViewsForKeyboardFrame:finalKeyboardFrame
                      adjustListContent:YES];
    } else {
      [UIView setAnimationsEnabled:YES];
      [self adjustViewsForKeyboardFrame:finalKeyboardFrame
                  withAnimationDuration:self.animationDuration
                         animationCurve:self.animationCurve];
      [UIView setAnimationsEnabled:NO];
    }
  }
}

- (void)adjustViewsForKeyboardFrame:(CGRect)keyboardFrame
              withAnimationDuration:(NSTimeInterval)animationDuration
                     animationCurve:(UIViewAnimationCurve)animationCurve {

  [self adjustViewsForKeyboardFrame:keyboardFrame adjustListContent:NO];

  BOOL shouldScrollToBottom = NO;

  if ([_messages count] != 0 &&
      (int)self.tvList.contentOffset.y - (int)(self.tvList.contentSize.height -
                                               self.tvList.frame.size.height) >=
          -42) {
    shouldScrollToBottom = YES;
  }

  CGFloat contentTopInset =
      [self getListContentInset:-((self.view.frame.size.height -
                                   keyboardFrame.origin.y))];

  [UIView animateWithDuration:animationDuration
      delay:0
      options:animationCurve << 16
      animations:^{
        _tvList.contentInset = UIEdgeInsetsMake(contentTopInset, 0, 0, 0);
        [self.view layoutIfNeeded];
        if (shouldScrollToBottom)
          [_tvList scrollToRowAtIndexPath:
                       [NSIndexPath indexPathForItem:([_messages count] - 1)
                                           inSection:0]
                         atScrollPosition:UITableViewScrollPositionBottom
                                 animated:NO];
      }
      completion:^(BOOL finished){
          // Nothing to do here..
      }];
}

- (void)adjustViewsForKeyboardFrame:(CGRect)keyboardFrame
                  adjustListContent:(BOOL)adjustListContent {
  // Calculate new position of the view
  CGFloat bottom = -((self.view.frame.size.height - keyboardFrame.origin.y));

  // Remove on rotation auto-generated constraints
  for (NSLayoutConstraint *con in self.view.constraints) {
    if (((con.firstItem == _keyboardBarView && con.secondItem == self.view) ||
         (con.firstItem == self.view && con.secondItem == _keyboardBarView)) &&
        (con.firstAttribute == NSLayoutAttributeBottom ||
         con.secondAttribute == NSLayoutAttributeBottom)) {
      [self.view removeConstraint:con];
    }
  }
  // [self.view layoutIfNeeded];

  _keyboardBottomConstraint =
      [NSLayoutConstraint constraintWithItem:_keyboardBarView
                                   attribute:NSLayoutAttributeBottom
                                   relatedBy:NSLayoutRelationEqual
                                      toItem:self.view
                                   attribute:NSLayoutAttributeBottom
                                  multiplier:1
                                    constant:bottom];
  [self.view addConstraint:_keyboardBottomConstraint];

  if (adjustListContent) {
    CGFloat contentTopInset =
        [self getListContentInset:-((self.view.frame.size.height -
                                     keyboardFrame.origin.y))];
    _tvList.contentInset = UIEdgeInsetsMake(contentTopInset, 0, 0, 0);
  }
}

- (void)endAlarm {
  _tvList = nil;
  [_messages removeAllObjects];
  _messages = nil;
  _prototypeCell = nil;
  _prototypeShelterCell = nil;
  _prototypeUserCell = nil;
  _prototypeSystemCell = nil;
  [_triggerAlarmConnection cancel];
  _triggerAlarmConnection = nil;
  _responseData = nil;
  [_initialDimTimer invalidate];
  _initialDimTimer = nil;
  _disconnectTime = nil;
  _dimTapRecognizer = nil;
  [_queuedMessages removeAllObjects];
  _queuedMessages = nil;
    [_client disconnect];

  if (![self isBeingDismissed]) {
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)sendTriggerAlarmRequest:(BOOL)calledPolice {
  [self triggerAlarmHasCalledPolice:calledPolice
      successBlock:^(NSDictionary *response) {
        [self parseTriggerAlarmResponse:response];
      }
      failureBlock:^(NSError *error) {
        [[AppLogger sharedInstance]
            logClass:NSStringFromClass([self class])
             message:[NSString stringWithFormat:@"triggerAlarmRequest failed! "
                                                @"CallPolice: %i, error: %@",
                                                calledPolice,
                                                error.description]];
        [self performSelector:@selector(sendTriggerAlarmRequest:)
                   withObject:calledPolice ? @YES
                                           : @NO
                   afterDelay:3];
      }];
}

- (void)triggerAlarmHasCalledPolice:(BOOL)calledPolice
                       successBlock:
                           (void (^)(NSDictionary *response))successBlock
                       failureBlock:(void (^)(NSError *error))failureBlock {

    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.timeoutIntervalForRequest = 5;
    defaultConfigObject.timeoutIntervalForResource = 10;
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
  [[defaultSession
        dataTaskWithURL:
            [NSURL URLWithString:
                       [NSString
                           stringWithFormat:
                               @"%@trigger-alarm?device_id=%@&call_police=%i",
                               [[NSUserDefaults standardUserDefaults]
                                   stringForKey:@"api_url"],
                               _client.clientId, calledPolice]]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *errorRequest) {
        // handle response
        if (errorRequest != nil) {
          failureBlock(errorRequest);
          return;
        }

        NSLog(
            @"%@",
            [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSError *errorJson = nil;
        NSDictionary *responseDict =
            [NSJSONSerialization JSONObjectWithData:data
                                            options:kNilOptions
                                              error:&errorJson];

        if (errorJson != nil) {
          failureBlock(errorJson);
          return;
        }

        successBlock(responseDict);

      }] resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)parseTriggerAlarmResponse:(NSDictionary *)response {
  NSString *message = [response valueForKey:@"message"];
  if (message) {
    Message *initialCrisisTeamMessage =
        [[Message alloc] initWithType:1 andText:message andTimestamp:-1];
    [self insertMessage:initialCrisisTeamMessage];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"dev_mode"]) {
      Message *shelterIdMessage = [[Message alloc]
          initWithType:2
               andText:[NSString stringWithFormat:
                                     @"Shelter ID: %@",
                                     [[NSUserDefaults standardUserDefaults]
                                         stringForKey:@"shelter_id"]]
          andTimestamp:-1];
      [self insertMessage:shelterIdMessage];
    }
  }
}

@end
