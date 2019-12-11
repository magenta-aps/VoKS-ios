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
#import "ShelterAPI.h"

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

  _connectionInfo.reachableOnWWAN = YES;
    

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
    
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"].length && [[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_public"] isEqualToString:@"0"]) {
        [self debug:[NSString stringWithFormat:@"there is stored shelter id: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"]]];
        [self checkShelterReachability:^{
            [self callRegisterDevice];
        } failureBlock:^(NSError *error) {
            [self getShelters];
        }];
    } else {
        [self debug:@"no stored shelter id or stored shelter is public"];
        [self getShelters];
    }

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width - 40;
    _sideMenuLeadingConstraint.constant = -screenWidth;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(reachabilityChanged:)
               name:kReachabilityChangedNotification
             object:nil];

    [_connectionInfo startNotifier];
}

- (void) getShelters {
    [self debug:@"getting bcs list from network"];
    [self getShelters:^(NSArray *response) {
        _failCount = 0;
        [self findReachableShelter:response];
    } failureBlock:^(NSError *error) {
        [self debug:@"getting bcs list from network failed"];
        [self getShelters];
    }];
}

- (void)findReachableShelter:(NSArray*) servers {
    [self findReachableShelter:servers index:0 successBlock:^{
        [self callRegisterDevice];
    } failureBlock:^{
        _failCount++;
        if (_failCount == 40) {
            [self getShelters];
        } else {
            [self findReachableShelter:servers];
        }
    }];
}

- (void) findReachableShelter:(NSArray*) shelters index:(int)index successBlock:(void (^)(void))successBlock failureBlock:(void (^)(void))failureBlock {
    
    NSDictionary *shelterInfo = shelters[index];
    
    [[NSUserDefaults standardUserDefaults] setObject:shelterInfo[@"bcs_id"] forKey:@"shelter_id"];
    [[NSUserDefaults standardUserDefaults] setObject:shelterInfo[@"bcs_name"] forKey:@"shelter_name"];
    [[NSUserDefaults standardUserDefaults] setObject:shelterInfo[@"bcs_url"] forKey:@"shelter_url"];
    [[NSUserDefaults standardUserDefaults] setObject:shelterInfo[@"police_number"] forKey:@"police_number"];
    [[NSUserDefaults standardUserDefaults] setObject:shelterInfo[@"public"] forKey:@"shelter_public"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self checkShelterReachability:^{
        successBlock();
    } failureBlock:^(NSError *error) {
        if (index+1 == shelters.count) {
            failureBlock();
        } else {
            [self findReachableShelter:shelters index:index+1 successBlock:successBlock failureBlock:failureBlock];
        }
    }];
    
}

- (void) checkShelterReachability:(void (^)(void))successBlock
failureBlock:(void (^)(NSError *error))failureBlock {
    
    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString
              stringWithFormat:@"Checking shelter (%@) reachability",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"] ]];
    
    [self debug:[NSString stringWithFormat:@"Checking shelter (%@) reachability",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
    
    NSString *shelterUrl = [Utils createCheckUrl:[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.timeoutIntervalForRequest = 5;
    defaultConfigObject.timeoutIntervalForResource = 10;
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
   
    
    [[defaultSession dataTaskWithURL:
      [NSURL URLWithString:shelterUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          if (error != nil) {
              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString
                        stringWithFormat:@"Shelter %@ is not reachable: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"], error.localizedDescription]];
              
               [self debug:[NSString stringWithFormat:@"Shelter %@ is not reachable",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
              failureBlock(error);
              return;
          }
    
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          
          if (httpResponse.statusCode == 200) {
              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString
                        stringWithFormat:@"Shelter %@ is reachable",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
               [self debug:[NSString stringWithFormat:@"Shelter %@ is reachable",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
              successBlock();
          } else {
              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString
                        stringWithFormat:@"Shelter %@ is not reachable, did not get 200 HTTP status",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
               [self debug:[NSString stringWithFormat:@"Shelter %@ is not reachable, did not get 200 HTTP status",[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]]];
              failureBlock(nil);
          }
          
          //successBlock(responseDict);
          return;
      }] resume];
    
}

- (void) getShelters:(void (^)(NSArray *response))successBlock
        failureBlock:(void (^)(NSError *error))failureBlock {
    
    [[AppLogger sharedInstance]
logClass:NSStringFromClass([self class])
message:[NSString
         stringWithFormat:@"Getting shelters"]];
    
    NSString *sheltersUrl = [NSString stringWithFormat:@"%@/api/%@", kBaseRegistrationURL,kDefaultSheltersUrlEnd];//[Utils createCheckUrl:[[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"]];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    [[defaultSession dataTaskWithURL:
      [NSURL URLWithString:sheltersUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          if (error != nil) {
              [[AppLogger sharedInstance]
          logClass:NSStringFromClass([self class])
          message:[NSString
                   stringWithFormat:@"Error getting shelters: %@",error.localizedDescription]];
              failureBlock(error);
              return;
          }
          
          NSError *errorJson = nil;
          NSArray *responseArray =
          [NSJSONSerialization JSONObjectWithData:data
                                          options:kNilOptions
                                            error:&errorJson];
          
          if (errorJson != nil) {
              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString
                        stringWithFormat:@"Error getting shelters: %@",errorJson.localizedDescription]];
              failureBlock(errorJson);
              return;
          }
          [[AppLogger sharedInstance]
           logClass:NSStringFromClass([self class])
           message:[NSString
                    stringWithFormat:@"Success getting shelters:\n%@",responseArray]];
          successBlock(responseArray);
          return;
      }] resume];
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

    [_termsAndCondidtionsButton setTitle:NSLocalizedString(@"menu_tac", nil) forState:UIControlStateNormal];
    [_phoneNumberButton setTitle:NSLocalizedString(@"menu_phone", nil) forState:UIControlStateNormal];
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


    if (self.initializedView == NO) {
        self.initializedView = YES;
        // FIXME: Workaround for IP address
        [self reachabilityChanged:nil];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString
                   stringWithFormat:@"ReachabilityChanged: %i",
                                    [_connectionInfo isReachable]]];
  if ([_connectionInfo isReachable]) {
    [UIView animateWithDuration:0.25
                     animations:^{
                       self.loadingLabel.alpha = 1;
                       self.lNetworkError.alpha = 0;
                     }];
  //  [self callRegisterDevice];
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
}

- (IBAction)onStartAlarmClicked:(id)sender {
  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"%@", @"onStartAlarmClicked"]];
  if ([_connectionInfo isReachable]) {
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"If You don't want to trigger alarm, please, close the app in standart way" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
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

- (IBAction)onTermsAndConditionsClick:(UIButton *)sender {
    [self onMenuCloseClick:_menuCloseButton];
    [self showTerms:[[NSUserDefaults standardUserDefaults] stringForKey:@"tac_text"]];
}

- (IBAction)onPhoneNumberClick:(UIButton *)sender {
    [self onMenuCloseClick:_menuCloseButton];
    [self showPhoneController];
}

- (IBAction)onMenuCloseClick:(UIButton *)sender {
    _sideMenuLeadingConstraint.constant = -(UIScreen.mainScreen.bounds.size.width - 40);
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)onMenuClick:(UIButton *)sender {
    _sideMenuLeadingConstraint.constant = 0;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)registerDevice:(void (^)(NSDictionary *response))successBlock
          failureBlock:(void (^)(NSError *error))failureBlock {

    [[AppLogger sharedInstance]
     logClass:NSStringFromClass([self class])
     message:[NSString stringWithFormat:@"Starting registering device: %@",[Utils deviceUID]]];
     [self debug:[NSString stringWithFormat:@"Starting registering device: %@",[Utils deviceUID]]];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
  [[defaultSession dataTaskWithURL:
                [NSURL URLWithString:
                           [NSString
                               stringWithFormat:
                                   @"%@/api/device/"
                                   @"register-device?device_type=ios&device_"
                                   @"id=%@&gcm_id=%@&lang=%@",
                                   [[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"], [Utils deviceUID],
                                   [[NSUserDefaults standardUserDefaults]
                                       stringForKey:@"APNS_ID"]
                                       ? [[NSUserDefaults standardUserDefaults]
                                             stringForKey:@"APNS_ID"]
                                       : @"", [Utils language]]]
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *errorRequest) {
            // handle response
            if (errorRequest != nil) {
              failureBlock(errorRequest);
                [[AppLogger sharedInstance]
                 logClass:NSStringFromClass([self class])
                 message:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorRequest.localizedDescription]];
                
                [self debug:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorRequest.localizedDescription]];
                return;
            }

            NSError *errorJson = nil;
            NSDictionary *responseDict =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&errorJson];

            if (errorJson != nil) {
              failureBlock(errorJson);
                [[AppLogger sharedInstance]
                 logClass:NSStringFromClass([self class])
                 message:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorJson.localizedDescription]];
                
                 [self debug:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorJson.localizedDescription]];
                return;
            }

              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString stringWithFormat:@"Success registering device: %@\nResponse:%@",[Utils deviceUID], responseDict]];
              
              [self debug:[NSString stringWithFormat:@"Success registering device"]];
            successBlock(responseDict);
              return;

          }] resume];
}

- (void)updateRegistrationInfoWithSuccessBlock:
            (void (^)(NSDictionary *response))successBlock
                                  failureBlock:
                                      (void (^)(NSError *error))failureBlock {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfigObject.timeoutIntervalForRequest = 5;
    defaultConfigObject.timeoutIntervalForResource = 10;
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];


    NSString *urlString = [NSString stringWithFormat:
        @"%@/api/device/"
        @"register-device?device_type=ios&device_"
        @"id=%@&gcm_id=%@&mac_address=%@&shelter_id=%@&lang=%@",
        [[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_url"], [Utils deviceUID],
        [[NSUserDefaults standardUserDefaults]
            stringForKey:@"APNS_ID"]
            ? [[NSUserDefaults standardUserDefaults]
                  stringForKey:@"APNS_ID"]
                                                    : @"", @"00:00:00:00:00", [[NSUserDefaults standardUserDefaults] stringForKey:@"shelter_id"], [Utils language]];
    [[defaultSession dataTaskWithURL:
                [NSURL URLWithString:
                           urlString]
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *errorRequest) {
            // handle response
            if (errorRequest != nil) {
              failureBlock(errorRequest);
                [[AppLogger sharedInstance]
                 logClass:NSStringFromClass([self class])
                 message:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorRequest.localizedDescription]];
              return;
            }

            NSError *errorJson = nil;
            NSDictionary *responseDict =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&errorJson];

              
            if (errorJson != nil) {
              failureBlock(errorJson);
                [[AppLogger sharedInstance]
                 logClass:NSStringFromClass([self class])
                 message:[NSString stringWithFormat:@"Failed registering device: %@\nerror:%@",[Utils deviceUID],errorJson.localizedDescription]];
              return;
            }

              [[AppLogger sharedInstance]
               logClass:NSStringFromClass([self class])
               message:[NSString stringWithFormat:@"Success registering device: %@\nResponse:%@",[Utils deviceUID], responseDict]];
            successBlock(responseDict);

          }] resume];
}

- (void)parseRegistrationInfo:(NSDictionary *)registrationResponse {
    if ([[registrationResponse valueForKey:@"success"] intValue] != 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lNetworkError.text = [registrationResponse valueForKey:@"message"];
            _lNetworkError.alpha = 1;
            _loadingLabel.alpha = 0;
            [self performSelector:@selector(callRegisterDevice)
                       withObject:nil
                       afterDelay:3];
        });
    } else {
        [[NSUserDefaults standardUserDefaults]
         setBool:[[registrationResponse valueForKey:@"dev_mode"] boolValue]
         forKey:@"dev_mode"];

        [AppLogger sharedInstance].doSendToRemote = [[NSUserDefaults standardUserDefaults] boolForKey:@"dev_mode"];

        [[NSUserDefaults standardUserDefaults]
         setObject:[registrationResponse valueForKey:@"shelter_id"]
         forKey:@"shelter_id"];
        [[NSUserDefaults standardUserDefaults]
         setObject:[registrationResponse valueForKey:@"api_url"]
         forKey:@"api_url"];
        [[NSUserDefaults standardUserDefaults]
         setObject:[registrationResponse valueForKey:@"ws_url"]
         forKey:@"ws_url"];

        BOOL hasTacInfo = false;
        BOOL hasPhoneInfo = false;

        if ([registrationResponse valueForKey:@"user_phone"] != nil && ![[registrationResponse valueForKey:@"user_phone"] isEqual:[NSNull null]]) {
            if ([[registrationResponse valueForKey:@"user_phone"] respondsToSelector:@selector(stringValue)]) {
            [[NSUserDefaults standardUserDefaults] setObject:[[registrationResponse valueForKey:@"user_phone"] stringValue] forKey:@"user_phone"];
            } else {
                [NSString stringWithString:[registrationResponse valueForKey:@"user_phone"]];
            }
        }

        if ([registrationResponse valueForKey:@"user_phone_token"] != nil && ![[registrationResponse valueForKey:@"user_phone_token"] isEqual:[NSNull null]]) {
            if ([[registrationResponse valueForKey:@"user_phone_token"] respondsToSelector:@selector(stringValue)]) {
                       [[NSUserDefaults standardUserDefaults] setObject:[[registrationResponse valueForKey:@"user_phone_token"] stringValue] forKey:@"user_phone_token"];
                       } else {
                           [NSString stringWithString:[registrationResponse valueForKey:@"user_phone_token"]];
                       }
        }

        if ([registrationResponse valueForKey:@"user_phone_confirm"] != nil && ![[registrationResponse valueForKey:@"user_phone_confirm"] isEqual:[NSNull null]]) {
            [[NSUserDefaults standardUserDefaults] setBool:[[registrationResponse valueForKey:@"user_phone_confirm"] boolValue] forKey:@"user_phone_confirm"];
        }

        if ([registrationResponse valueForKey:@"need_tac"] != nil && ![[registrationResponse valueForKey:@"need_tac"] isEqual:[NSNull null]]) {
            hasTacInfo = true;
             [[NSUserDefaults standardUserDefaults] setBool:[[registrationResponse valueForKey:@"need_tac"] boolValue] forKey:@"need_tac"];
        }

        if ([registrationResponse valueForKey:@"tac_text"] != nil && ![[registrationResponse valueForKey:@"tac_text"] isEqual:[NSNull null]]) {
             [[NSUserDefaults standardUserDefaults] setObject:[registrationResponse valueForKey:@"tac_text"] forKey:@"tac_text"];
        }

        if ([registrationResponse valueForKey:@"need_phone"] != nil && ![[registrationResponse valueForKey:@"need_phone"] isEqual:[NSNull null]]) {
            hasPhoneInfo = true;
            [[NSUserDefaults standardUserDefaults] setBool:[[registrationResponse valueForKey:@"need_phone"] boolValue] forKey:@"need_phone"];
        }

        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_menuButton setHidden:(!hasPhoneInfo && !hasTacInfo)];
            [self checkViews:NO fromPhone:NO fromPhoneConfirm:NO];
        });
    }
}
//showAlarmViewsIfUserDataOk(boolean fromResultTac, boolean fromResultPhone, boolean fromResultPhoneConfirm) {

- (void)checkViews:(BOOL)fromTac fromPhone:(BOOL)fromPhone fromPhoneConfirm:(BOOL)fromPhoneConfirm {

    BOOL needTac = [[NSUserDefaults standardUserDefaults] boolForKey:@"need_tac"];
    NSString *userPhone = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_phone"];
    BOOL phoneConfirmed = [[NSUserDefaults standardUserDefaults] boolForKey:@"user_phone_confirm"];
    BOOL needsPhone = [[NSUserDefaults standardUserDefaults] boolForKey:@"need_phone"];



    if (needTac == YES) {
        self.lNetworkError.text = NSLocalizedString(@"tac_not_accepted", nil);
        self.lNetworkError.alpha = 1;
        self.loadingLabel.alpha = 0;
        self.bStartAlarm.alpha = 0;
        if (!fromTac) {
            [self showTerms:[[NSUserDefaults standardUserDefaults] stringForKey:@"tac_text"]];
        }
    } else if (needsPhone == YES) {
        _lNetworkError.text = NSLocalizedString(@"phone_not_entered", nil);
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        _bStartAlarm.alpha = 0;
        if (!fromPhone) {
            [self showPhoneController];
        }
    } else if ([userPhone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0 && phoneConfirmed == NO) {
        _lNetworkError.text = NSLocalizedString(@"phone_not_confirmed", nil);
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        _bStartAlarm.alpha = 0;
        if (!fromPhoneConfirm) {
            [self showPhoneConfirmController];
        }
    } else {
        _lNetworkError.alpha = 0;
        _loadingLabel.alpha = 0;
        _bStartAlarm.alpha = 1;
    }
}

- (void)showPhoneController {
    PhoneNumberViewController *phoneController =
    [[PhoneNumberViewController alloc] initWithNibName:@"PhoneNumberViewController" bundle:nil];
    phoneController.delegate = self;
    [[self navigationController] pushViewController:phoneController
                                           animated:NO];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"need_phone"] == YES) {
        _lNetworkError.text = NSLocalizedString(@"phone_not_entered", nil);
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        _bStartAlarm.alpha = 0;
    }

}

- (void)showPhoneConfirmController {
    PhoneConfirmViewController *confirmController =
    [[PhoneConfirmViewController alloc] initWithNibName:@"PhoneConfirmViewController" bundle:nil];
    confirmController.delegate = self;
    [[self navigationController] pushViewController:confirmController
                                           animated:NO];

    _lNetworkError.text = NSLocalizedString(@"phone_not_confirmed", nil);
    _lNetworkError.alpha = 1;
    _loadingLabel.alpha = 0;
    _bStartAlarm.alpha = 0;
}

- (void)callRegisterDevice {
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
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        [self performSelector:@selector(callRegisterDevice)
                   withObject:nil
                   afterDelay:3];
      });

    }];
  } else {
    [self registerDevice:^(NSDictionary *response) {
      [self parseRegistrationInfo:response];
    } failureBlock:^(NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        _lNetworkError.alpha = 1;
        _loadingLabel.alpha = 0;
        [self performSelector:@selector(callRegisterDevice)
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
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

- (IBAction)sendLogs:(id)sender {
    // From within your active view controller
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        
        [mailCont setSubject:@"Logs"];
        [mailCont setToRecipients:[NSArray arrayWithObject:@"tadas.planciunas@gmail.com"]];
        
        NSString *body = @"";
        
        for (NSString *log in [AppLogger sharedInstance].logs) {
            
            body = [body stringByAppendingString:[NSString stringWithFormat:@"\n%@",log]];
        }
        
        [mailCont setMessageBody:body isHTML:NO];
        
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)debug:(NSString*)msg {
    return;
    
     dispatch_async(dispatch_get_main_queue(), ^{
    if (self.debug1Label != nil) {
        self.debug1Label.text = self.debug2Label.text;
        self.debug2Label.text = self.debug3Label.text;
        self.debug3Label.text = msg;
    }
     });
}

- (void)showTerms:(NSString *)text {
    TermsViewController *termsViewController =
    [[TermsViewController alloc] initWithNibName:@"TermsViewController" bundle:nil];
    termsViewController.text = text;
    termsViewController.delegate = self;
    [[self navigationController] pushViewController:termsViewController
                                           animated:NO];


}

#pragma mark - TermsViewControllerDelegate
- (void)agreedTerms {
    [self checkViews:YES fromPhone:NO fromPhoneConfirm:NO];
}

- (void)disagreedTerms {
    [self checkViews:YES fromPhone:NO fromPhoneConfirm:NO];
}

#pragma mark - PhoneViewControllerDelegate
- (void)skippedPhone {
    [self checkViews:NO fromPhone:YES fromPhoneConfirm:NO];
}

- (void)addedPhone {
    [self checkViews:NO fromPhone:YES fromPhoneConfirm:NO];
}

#pragma mark - PhoneConfirmViewControllerDelegate
- (void)skippedConfirmation {
    [self checkViews:NO fromPhone:NO fromPhoneConfirm:YES];
}

- (void)confirmedPhone {
    [self checkViews:NO fromPhone:NO fromPhoneConfirm:YES];
}
@end
