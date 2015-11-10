/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "StartController.h"

#import "ARDAppClient.h"
#import "AlarmController.h"
#import "Utils.h"
#import <AVFoundation/AVFoundation.h>
#import "AppLogger.h"
#include <arpa/inet.h>

@interface StartController ()

@end

@implementation StartController

@synthesize connectionInfo = _connectionInfo;
@synthesize queuedMessages = _queuedMessages;

- (void)viewDidLoad {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewDidLoad"];
  [super viewDidLoad];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone; // iOS 7 specific

  [self.navigationController.navigationBar setHidden:YES];

  _connectionInfo = nil;
  _connectionInfo =
      [Reachability reachabilityWithHostname:kBaseRegistrationDomain];

  _connectionInfo.reachableOnWWAN = NO;

  _queuedMessages = [NSMutableArray array];

  AVAuthorizationStatus videoPermission =
      [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  AVAuthorizationStatus audioPermission =
      [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];

  if (![[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"] &&
      (videoPermission != AVAuthorizationStatusAuthorized ||
       audioPermission != AVAuthorizationStatusAuthorized ||
       ![self hasPushNotificationPermission])) {
    // not authorized
    _permissionsPopupView.alpha = 1;
    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:@"First time loading, showing permissions popup"];
  } else if (videoPermission != AVAuthorizationStatusAuthorized ||
             audioPermission != AVAuthorizationStatusAuthorized ||
             ![self hasPushNotificationPermission]) {
    UIAlertView *permissionsAlert = [[UIAlertView alloc]
            initWithTitle:@"Warning!"
                  message:@"We need camera, microphone and push notification "
                  @"permissions for "
                  @"application to work as it intended, please give "
                  @"permissions in Settings application."
                 delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];

    [permissionsAlert show];

    [[AppLogger sharedInstance]
        logClass:NSStringFromClass([self class])
         message:[NSString
                     stringWithFormat:
                         @"We don't gave all permissions (Video: %i, Audio: "
                         @"%i, Notifications: %i), showing warning message",
                         videoPermission == AVAuthorizationStatusAuthorized,
                         audioPermission == AVAuthorizationStatusAuthorized,
                         [self hasPushNotificationPermission]]];
  } else {
    _permissionsPopupView.alpha = 0;
  }

  [self prepareTexts];
}

- (void)prepareTexts {
  [_tapToCancelButton setTitle:NSLocalizedString(@"tap_here_cancel", nil)
                      forState:UIControlStateNormal];
  [_checkWifiLabel setText:NSLocalizedString(@"check_connection", nil)];
  [_permissionsPopupTitleLabel
      setText:NSLocalizedString(@"register_title", nil)];
  [_permissionsPopupDetailsLabel
      setText:NSLocalizedString(@"permissions_description", nil)];
  [_permissionsPopupPermissionsList
      setText:NSLocalizedString(@"permissions_text", nil)];
  [_onlyOnceLabel setText:NSLocalizedString(@"permissions_once", nil)];
  [_continueButtonn setTitle:NSLocalizedString(@"button_continue", nil)
                    forState:UIControlStateNormal];
  [_loadingLabel setText:NSLocalizedString(@"loading_please_wait", nil)];
}

- (void)dealloc {
  _queuedMessages = nil;
  _connectionInfo = nil;

  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"dealloc"];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
  [[AppLogger sharedInstance] logClass:NSStringFromClass([self class])
                                message:@"viewWillAppear"];
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(reachabilityChanged:)
             name:kReachabilityChangedNotification
           object:nil];

  [_connectionInfo startNotifier];

  // FIXME: Workaround for IP address
  [self reachabilityChanged:nil];
}

- (void)reachabilityChanged:(NSNotification *)notification {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"ReachabilityChanged: %i",
                                    [_connectionInfo isReachableViaWiFi]]];
  if ([_connectionInfo isReachableViaWiFi]) {
    [UIView animateWithDuration:0.25
                     animations:^{
                       self.loadingLabel.alpha = 1;
                       self.lNetworkError.alpha = 0;
                     }];
    [self registerDevice];
  } else {
    [UIView animateWithDuration:0.25
                     animations:^{
                       self.bStartAlarm.alpha = 0;
                       self.lNetworkError.alpha = 1;
                       self.loadingLabel.alpha = 0;
                     }];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"%@", @"viewWillDisappear"]];
  [super viewWillDisappear:animated];

  [_connectionInfo stopNotifier];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kReachabilityChangedNotification
              object:nil];
}

- (IBAction)onStartAlarmClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"%@", @"onStartAlarmClicked"]];
  if ([_connectionInfo isReachableViaWiFi]) {
    AlarmController *alarmController =
        [[AlarmController alloc] initWithNibName:@"AlarmController" bundle:nil];
    if (_queuedMessages != nil && _queuedMessages.count) {
      alarmController.messages = _queuedMessages;
    }
    [[self navigationController] pushViewController:alarmController
                                           animated:NO];
  } else {
    [UIView animateWithDuration:0.25
                     animations:^{
                       self.bStartAlarm.alpha = 1;
                       self.bCancel.alpha = 1;
                       self.lNetworkError.alpha = 0;
                     }];
  }
}

- (IBAction)onStartAlarmTouchDown:(id)sender {
}

- (IBAction)onCancelClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"%@", @"onCancelClicked"]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"If You don't want to trigger alarm, please, close the app in standart way - double click home button and swap application up" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [alert show];
}

- (IBAction)onCancelTouchDown:(id)sender {
}

- (IBAction)onPermissionsContinueClick:(id)sender {
  [UIView animateWithDuration:0.25
                   animations:^{
                     _permissionsPopupView.alpha = 0;
                   }];

  if ([AVCaptureDevice
          respondsToSelector:@selector(requestAccessForMediaType:
                                               completionHandler:)]) {
    [AVCaptureDevice
        requestAccessForMediaType:AVMediaTypeVideo
                completionHandler:^(BOOL granted) {
                  [[AppLogger sharedInstance]
                      logClass:NSStringFromClass([self class])
                       message:[NSString stringWithFormat:
                                             @"Camera permission granted: %i",
                                             granted]];
                  // Will get here on both iOS 7 & 8 even though
                  // camera permissions weren't required
                  // until iOS 8. So for iOS 7 permission will
                  // always be granted.
                  if (granted) {
                    // Permission has been granted. Use
                    // dispatch_async for any UI updating
                    // code because this block may be executed in a
                    // thread.
                  } else {
                    // Permission has been denied.
                  }
                }];
  }

  if ([[AVAudioSession sharedInstance]
          respondsToSelector:@selector(requestRecordPermission:)]) {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
      [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
           message:[NSString
                       stringWithFormat:@"Microphone permission granted: %i",
                                        granted]];

    }];
  }
}
- (IBAction)onPermissionsContinueCancel:(id)sender {
}

- (IBAction)onPermissionsContinueHold:(id)sender {
}

- (void)registerDevice:(void (^)(NSDictionary *response))successBlock
          failureBlock:(void (^)(NSError *error))failureBlock {

  NSURLSession *session = [NSURLSession sharedSession];
  [[session dataTaskWithURL:
                [NSURL URLWithString:
                           [NSString
                               stringWithFormat:
                                   @"%@/api/voks/"
                                   @"register-device?device_type=ios&device_"
                                   @"id=%@&gcm_id=%@&lang=%@",
                                   kBaseRegistrationURL, [Utils deviceUID],
                                   [[NSUserDefaults standardUserDefaults]
                                       stringForKey:@"APNS_ID"]
                                       ? [[NSUserDefaults standardUserDefaults]
                                             stringForKey:@"APNS_ID"]
                                       : @"",[[NSLocale preferredLanguages] objectAtIndex:0]]]
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *errorRequest) {
            // handle response
            if (errorRequest != nil) {
              failureBlock(errorRequest);
            }

            NSError *errorJson = nil;
            NSDictionary *responseDict =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&errorJson];

            if (errorJson != nil) {
              failureBlock(errorJson);
            }

            successBlock(responseDict);

          }] resume];
}

- (void)updateRegistrationInfoWithSuccessBlock:
            (void (^)(NSDictionary *response))successBlock
                                  failureBlock:
                                      (void (^)(NSError *error))failureBlock {
  NSURLSession *session = [NSURLSession sharedSession];
  session.configuration.timeoutIntervalForRequest = 5;
  session.configuration.timeoutIntervalForResource = 10;
  [[session dataTaskWithURL:
                [NSURL URLWithString:
                           [NSString
                               stringWithFormat:
                                   @"%@/api/voks/"
                                   @"register-device?device_type=ios&device_"
                                   @"id=%@&gcm_id=%@&lang=%@",
                                   kBaseRegistrationURL, [Utils deviceUID],
                                   [[NSUserDefaults standardUserDefaults]
                                       stringForKey:@"APNS_ID"]
                                       ? [[NSUserDefaults standardUserDefaults]
                                             stringForKey:@"APNS_ID"]
                                       : @"",[[NSLocale preferredLanguages] objectAtIndex:0]] ]
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *errorRequest) {
            // handle response
            if (errorRequest != nil) {
              failureBlock(errorRequest);
              return;
            }

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

- (void)parseRegistrationInfo:(NSDictionary *)registrationResponse {
  if ([[registrationResponse valueForKey:@"success"] intValue] != 1) {
      dispatch_async(dispatch_get_main_queue(), ^{
          _lNetworkError.text = [registrationResponse valueForKey:@"message"];
          _lNetworkError.alpha = 1;
          _loadingLabel.alpha = 0;
          [self performSelector:@selector(registerDevice)
                     withObject:nil
                     afterDelay:3];
      });
  } else {
    [[NSUserDefaults standardUserDefaults]
        setBool:[[registrationResponse valueForKey:@"dev_mode"] boolValue]
         forKey:@"dev_mode"];
    [[NSUserDefaults standardUserDefaults]
        setObject:[registrationResponse valueForKey:@"shelter_id"]
           forKey:@"shelter_id"];
    [[NSUserDefaults standardUserDefaults]
        setObject:[registrationResponse valueForKey:@"api_url"]
           forKey:@"api_url"];
    [[NSUserDefaults standardUserDefaults]
        setObject:[registrationResponse valueForKey:@"ws_url"]
           forKey:@"ws_url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
      _loadingLabel.alpha = 0;
      _bStartAlarm.alpha = 1;
    });
  }
}

- (void)registerDevice {
  dispatch_async(dispatch_get_main_queue(), ^{
    _lNetworkError.alpha = 0;
    _loadingLabel.alpha = 1;
  });
  if ([[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"]) {
    [self updateRegistrationInfoWithSuccessBlock:^(NSDictionary *response) {
      [self parseRegistrationInfo:response];
    } failureBlock:^(NSError *error) {
      [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
           message:[NSString
                       stringWithFormat:@"Error while updating user device: %@",
                                        error.description]];
      dispatch_async(dispatch_get_main_queue(), ^{
        _lNetworkError.text = NSLocalizedString(@"check_connection", nil);
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        [self performSelector:@selector(registerDevice)
                   withObject:nil
                   afterDelay:3];
      });

    }];
  } else {
    [self registerDevice:^(NSDictionary *response) {
      [self parseRegistrationInfo:response];
    } failureBlock:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        _lNetworkError.text = NSLocalizedString(@"check_connection", nil);
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        [self performSelector:@selector(registerDevice)
                   withObject:nil
                   afterDelay:3];
      });
      [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
           message:[NSString stringWithFormat:@"Error while registering user "
                                              @"device for the first time: %@",
                                              error.description]];

    }];
  }
}

- (BOOL)hasPushNotificationPermission {
  BOOL remoteNotificationsEnabled = NO;

  if ([[UIApplication sharedApplication]
          respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    // iOS8+
    remoteNotificationsEnabled =
        [UIApplication sharedApplication].isRegisteredForRemoteNotifications;

    if (!remoteNotificationsEnabled) {
      return NO;
    }
    UIUserNotificationSettings *userNotificationSettings =
        [UIApplication sharedApplication].currentUserNotificationSettings;

    if (userNotificationSettings.types == UIUserNotificationTypeNone ||
        !(userNotificationSettings.types & UIUserNotificationTypeAlert)) {
      return NO;
    } else {
      return YES;
    }

  } else {
    // iOS7 and below
    UIRemoteNotificationType enabledRemoteNotificationTypes =
        [UIApplication sharedApplication].enabledRemoteNotificationTypes;

    if (enabledRemoteNotificationTypes == UIRemoteNotificationTypeNone ||
        !(enabledRemoteNotificationTypes & UIRemoteNotificationTypeAlert)) {
      return NO;
    } else {
      return YES;
    }
  }
}
@end
