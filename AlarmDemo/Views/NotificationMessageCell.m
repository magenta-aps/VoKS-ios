/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "NotificationMessageCell.h"
#import "Utils.h"

@implementation NotificationMessageCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)sendGotIt:(id)sender {
    
    NSString *url = [NSString stringWithFormat:@"%@got-it?device_id=%@&notification_id=%li",[[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"], [Utils deviceUID], [_msg.uniqueId longValue]];
    
    NSURLRequest *alarmRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSURLConnection *triggerAlarm = [[NSURLConnection alloc] initWithRequest:alarmRequest delegate:nil];
    
    [triggerAlarm start];
    
    self.msg.hasRead = YES;
    
    [self.gotItButton removeTarget:self action:@selector(sendGotIt:) forControlEvents:UIControlEventTouchUpInside];
    [self.gotItButton removeFromSuperview];
    self.gotItButton = nil;
    
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.messageTextLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
    
    [self.containerView addConstraint:bottomConstraint];
    
    [self.containerView layoutIfNeeded];
}

@end
