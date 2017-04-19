/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "AppDelegate.h"
#import "StartController.h"
#import <WebRTC/RTCPeerConnectionFactory.h>
//#import "RTCPeerConnectionFactory.h"
#import "Keychain.h"
#import "AlarmController.h"
#import "StartController.h"
#import "NotificationController.h"
#import "Message.h"
#import "Utils.h"
#import <WebRTC/RTCLogging.h>
#import "MediaPlayer/MPVolumeView.h"
#import "AppLogger.h"

#import <WebRTC/RTCFieldTrials.h>

#import <WebRTC/RTCSSLAdapter.h>
#import <WebRTC/RTCTracing.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

#define SYSTEM_VERSION_EQUAL_TO(v)                                             \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] ==       \
   NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)                                         \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] ==       \
   NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)                             \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] !=       \
   NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                                            \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] ==       \
   NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)                                \
  ([[[UIDevice currentDevice] systemVersion] compare:v                         \
                                             options:NSNumericSearch] !=       \
   NSOrderedDescending)

#define SERVICE_NAME @"BCOMESafe_Service"

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  RTCSetMinDebugLogLevel(RTCLoggingSeverityVerbose);

  UINavigationController *nvController = nil;

  if ([launchOptions
          objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] ||
      [launchOptions
          objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {

    NotificationController *notifController = [[NotificationController alloc]
        initWithNibName:@"NotificationController"
                 bundle:nil];
    NSDictionary *notification = [launchOptions
        objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

    if (![notification count]) {

      UILocalNotification *localNotification = [launchOptions
          objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
      notification = @{
        @"aps" : @{
          @"alert" : localNotification.alertBody,
          @"id" : [localNotification.userInfo objectForKey:@"id"]
        }

      };
    }

    notifController.notification = notification;

    nvController = [[UINavigationController alloc]
        initWithRootViewController:notifController];

    self.window.rootViewController = nvController;

    return YES;

  } else {
    nvController = [[UINavigationController alloc]
        initWithRootViewController:[[StartController alloc]
                                       initWithNibName:@"StartController"
                                                bundle:nil]];
    if ([nvController
            respondsToSelector:@selector(interactivePopGestureRecognizer)])
      [nvController.view
          removeGestureRecognizer:nvController.interactivePopGestureRecognizer];
  }

  [UIApplication sharedApplication].idleTimerDisabled = YES;

  // Override point for customization after application launch.
  //[RTCPeerConnectionFactory initializeSSL];
        NSDictionary *fieldTrials = @{
                                      kRTCFieldTrialImprovedBitrateEstimateKey: kRTCFieldTrialEnabledValue,
                                      kRTCFieldTrialH264HighProfileKey: kRTCFieldTrialEnabledValue,
                                      };
        RTCInitFieldTrialDictionary(fieldTrials);
  RTCInitializeSSL();
  RTCSetupInternalTracer();

  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
    [self registerRemoteNotificationWithActions];
  } else {
    UIRemoteNotificationType remoteTypes = UIRemoteNotificationTypeBadge |
                                           UIRemoteNotificationTypeAlert |
                                           UIRemoteNotificationTypeSound;
    [application registerForRemoteNotificationTypes:remoteTypes];
  }

  self.window.rootViewController = nvController;

//  NSString *str1 = @"etSystemV";
//  NSString *str2 = @"eHUDEnabled";
//  NSString *selectorString =
//      [NSString stringWithFormat:@"s%@olum%@:forAudioCategory:", str1, str2];
//  SEL selector = NSSelectorFromString(selectorString);
//
//  if ([[UIApplication sharedApplication] respondsToSelector:selector]) {
//    NSInvocation *invocation = [NSInvocation
//        invocationWithMethodSignature:
//            [UIApplication instanceMethodSignatureForSelector:selector]];
//    invocation.selector = selector;
//    invocation.target = [UIApplication sharedApplication];
//    BOOL value = NO;
//    [invocation setArgument:&value atIndex:2];
//    __unsafe_unretained NSString *category = @"Ringtone";
//    [invocation setArgument:&category atIndex:3];
//    [invocation invoke];
//  }

//  if ([[UIApplication sharedApplication] respondsToSelector:selector]) {
//    NSInvocation *invocation = [NSInvocation
//        invocationWithMethodSignature:
//            [UIApplication instanceMethodSignatureForSelector:selector]];
//    invocation.selector = selector;
//    invocation.target = [UIApplication sharedApplication];
//    BOOL value = NO;
//    [invocation setArgument:&value atIndex:2];
//    __unsafe_unretained NSString *category = @"Audio/Video";
//    [invocation setArgument:&category atIndex:3];
//    [invocation invoke];
//  }
//
//  float zeroVolume = 0.0f;
//  Class avSystemControllerClass = NSClassFromString(@"AVSystemController");
//  id avSystemControllerInstance = [avSystemControllerClass
//      performSelector:@selector(sharedAVSystemController)];

//  NSString *soundCategory = @"Ringtone";

//    float currentVolumeRinger = 0;
//    NSInvocation *getCurrentVolume = [NSInvocation
//        invocationWithMethodSignature:[avSystemControllerClass
//                                          instanceMethodSignatureForSelector:
//                                              @selector(getVolume:forCategory:)]];
//    [getCurrentVolume setTarget:avSystemControllerInstance];
//    [getCurrentVolume setSelector:@selector(getVolume:forCategory:)];
//    [getCurrentVolume setArgument:&currentVolumeRinger atIndex:2];
//    [getCurrentVolume setArgument:&soundCategory atIndex:3];
//    [getCurrentVolume invoke];
//
//    NSLog(@"Current Volume: %f", currentVolumeRinger);

//  NSInvocation *volumeInvocation = [NSInvocation
//      invocationWithMethodSignature:
//          [avSystemControllerClass
//              instanceMethodSignatureForSelector:@selector(setVolumeTo:
//                                                           forCategory:)]];
//  [volumeInvocation setTarget:avSystemControllerInstance];
//  [volumeInvocation setSelector:@selector(setVolumeTo:forCategory:)];
//  [volumeInvocation setArgument:&zeroVolume atIndex:2];
//  [volumeInvocation setArgument:&soundCategory atIndex:3];
//  [volumeInvocation invoke];

  // Hacky stuff to find Volume View
  MPVolumeView *volumeView = [[MPVolumeView alloc] init];
  volumeView.showsRouteButton = NO;
  volumeView.showsVolumeSlider = NO;

  // find the volumeSlider
  UISlider *volumeViewSlider = nil;
  for (UIView *view in [volumeView subviews]) {
    if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
      volumeViewSlider = (UISlider *)view;
      break;
    }
  }

  _mediaVolume = [volumeViewSlider value];
  [volumeViewSlider setValue:0.0f animated:NO];
  [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];

  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:@"Application launched, starting logging!"];
  [[AppLogger sharedInstance] sendLogsToRemote];

  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
  //[RTCPeerConnectionFactory deinitializeSSL];
  RTCShutdownInternalTracer();
  RTCCleanupSSL();
    
    
  UINavigationController *nvController =
      (UINavigationController *)self.window.rootViewController;

  UIViewController *currentController =
      [[nvController viewControllers] lastObject];

  if ([currentController isKindOfClass:[StartController class]]) {
    if ([((StartController *)currentController).queuedMessages count] != 0) {
      for (Message *msg in((StartController *)currentController)
               .queuedMessages) {
        [self scheduleNotificationWithItem:msg];
      }
    }
  }

  // Hacky stuff to find Volume View
  MPVolumeView *volumeView = [[MPVolumeView alloc] init];
  volumeView.showsRouteButton = NO;
  volumeView.showsVolumeSlider = NO;

  // find the volumeSlider
  UISlider *volumeViewSlider = nil;
  for (UIView *view in [volumeView subviews]) {
    if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
      volumeViewSlider = (UISlider *)view;
      break;
    }
  }

  // Reset Media volume
  [volumeViewSlider setValue:_mediaVolume animated:NO];
  [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];

  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:@"Stopping Logs, Application is terminating"];
  [[AppLogger sharedInstance] sendLogsToRemote];
}
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:
        (UIUserNotificationSettings *)notificationSettings {
  [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"%@",[NSString stringWithFormat:@"%@",deviceToken]);
  NSString *deviceStringToken =
      [[[[NSString stringWithFormat:@"%@", deviceToken]
          stringByReplacingOccurrencesOfString:@"<"
                                    withString:@""]
          stringByReplacingOccurrencesOfString:@" "
                                    withString:@""]
          stringByReplacingOccurrencesOfString:@">"
                                    withString:@""];

  [[AppLogger sharedInstance]
      logClass:NSStringFromClass([self class])
       message:[NSString stringWithFormat:@"Registered for deviceToken: %@",
                                          deviceStringToken]];

  NSString *existing_token =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"APNS_ID"];
  if (existing_token == nil ||
      ![deviceStringToken isEqualToString:existing_token]) {
    [[NSUserDefaults standardUserDefaults] setObject:deviceStringToken
                                              forKey:@"APNS_ID"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (existing_token != nil) { // Force token update
    }
  }
}

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"%@", error);
}

- (void)application:(UIApplication *)application
    didReceiveLocalNotification:(nonnull UILocalNotification *)notification {
  if (application.applicationState == UIApplicationStateInactive) {

    NSLog(@"Inactive");

    // Show the view with the content of the push

    // completionHandler(UIBackgroundFetchResultNewData);

  } else if (application.applicationState == UIApplicationStateBackground ||
             application.applicationState == UIApplicationStateActive) {

    NSLog(@"Background or Active");

    NSDictionary *userInfo = notification.userInfo;
    UINavigationController *nvController =
        (UINavigationController *)self.window.rootViewController;

    UIViewController *currentController =
        [[nvController viewControllers] lastObject];

    Message *remoteMessage =
        [[Message alloc] initWithType:3
                              andText:[userInfo[@"aps"] valueForKey:@"alert"]
                         andTimestamp:-1];
    remoteMessage.uniqueId = [NSNumber
        numberWithInt:[[userInfo[@"aps"] valueForKey:@"id"] intValue]];

    if ([currentController isKindOfClass:[StartController class]]) {
      [((StartController *)currentController)
              .queuedMessages addObject:remoteMessage];
    } else if ([currentController isKindOfClass:[AlarmController class]]) {
      [((AlarmController *)currentController)insertMessage:remoteMessage];
    } else if ([currentController
                   isKindOfClass:[NotificationController class]]) {
      NotificationController *notificationController =
          (NotificationController *)currentController;

      notificationController.notification = userInfo;
      [notificationController updateMessage];
      [notificationController sendGotIt];
    }

    // completionHandler(UIBackgroundRefreshStatusAvailable);
  }
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo {
  if (application.applicationState == UIApplicationStateActive) {

    NSLog(@"Remote notification received. AppStatus: Active");

    UINavigationController *nvController =
        (UINavigationController *)self.window.rootViewController;

    UIViewController *currentController =
        [[nvController viewControllers] lastObject];

    Message *remoteMessage =
        [[Message alloc] initWithType:3
                              andText:[userInfo[@"aps"] valueForKey:@"alert"]
                         andTimestamp:-1];
    remoteMessage.uniqueId = [NSNumber
        numberWithInt:[[userInfo[@"aps"] valueForKey:@"id"] intValue]];

    if ([currentController isKindOfClass:[StartController class]]) {
      [((StartController *)currentController)
              .queuedMessages addObject:remoteMessage];
    } else if ([currentController isKindOfClass:[AlarmController class]]) {
      [((AlarmController *)currentController)insertMessage:remoteMessage];
    } else if ([currentController
                   isKindOfClass:[NotificationController class]]) {
      NotificationController *notificationController =
          (NotificationController *)currentController;

      notificationController.notification = userInfo;
      [notificationController updateMessage];
      [notificationController sendGotIt];
    }

    // completionHandler(UIBackgroundRefreshStatusAvailable);
  } else if ( application.applicationState == UIApplicationStateBackground || application.applicationState == UIApplicationStateInactive){
     

      
      UINavigationController *nvController =
      (UINavigationController *)self.window.rootViewController;
      
      UIViewController *currentController =
      [[nvController viewControllers] lastObject];

      Message *remoteMessage =
      [[Message alloc] initWithType:3
                            andText:[userInfo[@"aps"] valueForKey:@"alert"]
                       andTimestamp:-1];
      remoteMessage.uniqueId = [NSNumber
                                numberWithInt:[[userInfo[@"aps"] valueForKey:@"id"] intValue]];
      
      if ([currentController isKindOfClass:[StartController class]]) {
          
          NotificationController *notifController = [[NotificationController alloc]
                                                     initWithNibName:@"NotificationController"
                                                     bundle:nil];
          
          notifController.notification = userInfo;
          
          [nvController pushViewController:notifController animated:NO];
          
      } else if ([currentController isKindOfClass:[AlarmController class]]) {
          [((AlarmController *)currentController)insertMessage:remoteMessage];
      } else if ([currentController
                  isKindOfClass:[NotificationController class]]) {
          NotificationController *notificationController =
          (NotificationController *)currentController;
          
          notificationController.notification = userInfo;
          [notificationController updateMessage];
          [notificationController sendGotIt];
      } else {

          NotificationController *notifController = [[NotificationController alloc]
                                                     initWithNibName:@"NotificationController"
                                                     bundle:nil];
          
          notifController.notification = userInfo;
          
          [nvController pushViewController:notifController animated:NO];
      }
  }
}

//-(void) application:(UIApplication *)application
// didReceiveRemoteNotification:(NSDictionary *)userInfo
// fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
//
//
//
//}

- (void)registerRemoteNotificationWithActions {

  // 1. Create action buttons..:)

  UIMutableUserNotificationAction *gotIt =
      [[UIMutableUserNotificationAction alloc] init];
  gotIt.identifier = @"ACTION_GOT_IT";
  gotIt.title = @"Got it!";
  gotIt.activationMode = UIUserNotificationActivationModeBackground;
  gotIt.destructive = NO;
  gotIt.authenticationRequired = NO;

  // 2. Then create the category to group actions.:)

  UIMutableUserNotificationCategory *tagCategory =
      [[UIMutableUserNotificationCategory alloc] init];
  tagCategory.identifier = @"TAG_CATEGORY";
  [tagCategory setActions:@[ gotIt ]
               forContext:UIUserNotificationActionContextDefault];
  [tagCategory setActions:@[ gotIt ]
               forContext:UIUserNotificationActionContextMinimal];

  // 3. Then add categories into one set..:)
  NSSet *categories = [NSSet setWithObjects:tagCategory, nil];

  // 4. Finally register remote notification with this action categories..:)
  UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings
      settingsForTypes:UIUserNotificationTypeAlert |
                       UIUserNotificationTypeBadge | UIUserNotificationTypeSound
            categories:categories];
  [[UIApplication sharedApplication]
      registerUserNotificationSettings:notificationSettings];
}

- (void)scheduleNotificationWithItem:(Message *)msg {

  UILocalNotification *localNotif = [[UILocalNotification alloc] init];

  if (localNotif == nil)

    return;

  localNotif.fireDate = [[NSDate date] dateByAddingTimeInterval:3];

  localNotif.timeZone = [NSTimeZone defaultTimeZone];

  localNotif.alertBody = msg.text;

  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
    localNotif.alertAction = @"ACTION_GOT_IT";
    localNotif.category = @"TAG_CATEGORY";
  }
  localNotif.soundName = nil;

  NSDictionary *infoDict =
      [NSDictionary dictionaryWithObject:msg.uniqueId forKey:@"id"];

  localNotif.userInfo = infoDict;

  [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
          forLocalNotification:(UILocalNotification *)notification
             completionHandler:(void (^)())completionHandler {
  if ([identifier isEqualToString:@"ACTION_GOT_IT"]) {
    NSDictionary *userInfo = notification.userInfo;
    NSString *url = [NSString
        stringWithFormat:
            @"%@got-it?device_id=%@&notification_id=%i",
            [[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"],
            [Utils deviceUID],
            [[[userInfo objectForKey:@"aps"] objectForKey:@"id"] intValue]];

    NSURLRequest *alarmRequest =
        [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLConnection *triggerAlarm =
        [[NSURLConnection alloc] initWithRequest:alarmRequest delegate:nil];

    [triggerAlarm start];

    completionHandler(UIBackgroundFetchResultNoData);
  }
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)())completionHandler {
  if ([identifier isEqualToString:@"ACTION_GOT_IT"]) {

    NSString *url = [NSString
        stringWithFormat:
            @"%@got-it?device_id=%@&notification_id=%i",
            [[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"],
            [Utils deviceUID],
            [[[userInfo objectForKey:@"aps"] objectForKey:@"id"] intValue]];

    NSURLRequest *alarmRequest =
        [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLConnection *triggerAlarm =
        [[NSURLConnection alloc] initWithRequest:alarmRequest delegate:nil];

    [triggerAlarm start];

    completionHandler(UIBackgroundFetchResultNoData);
  }
}

//- (void) application:(UIApplication *)application
// didReceiveRemoteNotification:(NSDictionary *)userInfo {
//      NSLog(@"Received Push Notification in foreground, userInfo:
//      %@",userInfo);
//}

@end
