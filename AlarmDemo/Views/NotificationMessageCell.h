/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>
#import "Message.h"

@interface NotificationMessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic)  UIButton *gotItButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTextBottomConstraint;

@property (nonatomic, assign) Message *msg;

- (void)sendGotIt:(id)sender;
@end
