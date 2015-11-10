/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>

@interface NotificationController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImage;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic, retain) NSDictionary *notification;
- (IBAction)onCloseClick:(id)sender;
- (void)sendGotIt;
- (void)updateMessage;
@end
