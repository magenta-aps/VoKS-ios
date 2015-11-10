/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "NotificationController.h"
#import "Utils.h"
#import "AppDelegate.h"
#import "StartController.h"

@interface NotificationController ()

@end

@implementation NotificationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific

    [self.navigationController.navigationBar setHidden:YES];
    self.closeButton.layer.cornerRadius = 3.f;
    [self updateMessage];
   
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self sendGotIt];
}

- (IBAction)onCloseClick:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    StartController *controller = [[StartController alloc] initWithNibName:@"StartController" bundle:nil];
   
    [UIView transitionWithView:delegate.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ delegate.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: controller]; }
                    completion:nil];
}

- (void)sendGotIt{
    NSURLRequest *alarmRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@got-it?device_id=%@&notification_id=%li",[[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"], [Utils deviceUID], [_notification[@"aps"][@"id"] longValue]]]];
    NSURLConnection *triggerAlarm = [[NSURLConnection alloc] initWithRequest:alarmRequest delegate:self];
    
    [triggerAlarm start];
}

- (void) dealloc {
    _notification = nil;
}

- (void) updateMessage {
    [self.notificationLabel setText:[NSString stringWithFormat:@"%@",_notification[@"aps"][@"alert"]]];
    
    [self.notificationLabel setTextColor:[UIColor blackColor]];
    UIColor *color = [UIColor lightGrayColor]; // select needed color
    NSString *string = NSLocalizedString(@"crisis_team_chat", nil);
    NSDictionary *attrs = @{NSForegroundColorAttributeName : color};
    NSMutableAttributedString *attrStr =
    [[NSMutableAttributedString alloc] initWithString:string
                                           attributes:attrs];
    [attrStr appendAttributedString:[[NSAttributedString alloc]
                                     initWithString:[NSString stringWithFormat:@"%@",_notification[@"aps"][@"alert"]]]];
    self.notificationLabel.attributedText = attrStr;
    [self.notificationLabel sizeToFit];
    
    [self.bubbleImage
     setImage:[[UIImage imageNamed:@"chat_left"]
               resizableImageWithCapInsets:UIEdgeInsetsMake(5, 35, 20, 10)
               resizingMode:UIImageResizingModeStretch]];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
