/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import "MessageCell.h"
#import "Utils.h"

@implementation MessageCell

- (void)awakeFromNib {
    // Initialization code
    //self.vBackground.layer.cornerRadius = 4;
    [super awakeFromNib];
    self.type = -1;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // initialize my stuff
        self.type = -1;
    }
    return self;
}

- (void) setType:(int)type andText:(NSString *) text andUniqueID:(NSNumber *) uniqueID{

    if (self.type != type){
        [self.contentView removeConstraint:self.leftOrRightConstraintByType];
        [self.contentView removeConstraint:self.biggerSpaceFromLeftOrRightConstraint];
        [self.vBackground removeConstraint:self.holderBottomConstraint];
        switch (type){
            case 0:
                if (gotItButton){
                    [gotItButton removeFromSuperview];
                    gotItButton = nil;
                }
                self.contentViewBottomConstraint.constant = 20;
                [self.lText setTextAlignment:NSTextAlignmentLeft];
                [self.lText setTextColor:[UIColor blackColor]];
                [self.vBackground setBackgroundColor:[UIColor clearColor]];
                [self.lText setAttributedText:nil];
                [self.lText setText:text];
                
                self.leftOrRightConstraintByType = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
                self.biggerSpaceFromLeftOrRightConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:15];
                //[self.vBackground setBackgroundColor:[UIColor blueColor]];
                [self.bubbleImage setImage: [[UIImage imageNamed:@"chat_right"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 10, 20, 35) resizingMode:UIImageResizingModeStretch]];
                _holderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.lText attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
                break;
            case 1:
            {
                if (gotItButton){
                    [gotItButton removeFromSuperview];
                    gotItButton = nil;
                }
                self.contentViewBottomConstraint.constant = 20;
                [self.lText setTextColor:[UIColor blackColor]];
                UIColor *color = [UIColor lightGrayColor]; // select needed color
                NSString *string = NSLocalizedString(@"crisis_team_chat",nil);
                NSDictionary *attrs = @{ NSForegroundColorAttributeName : color };
                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
                [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
               
               
                
                [self.lText setTextAlignment:NSTextAlignmentLeft];
                [self.vBackground setBackgroundColor:[UIColor clearColor]];
                self.leftOrRightConstraintByType = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
                self.biggerSpaceFromLeftOrRightConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-15];
                [self.bubbleImage setImage: [[UIImage imageNamed:@"chat_left"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 35, 20, 10) resizingMode:UIImageResizingModeStretch]];
                
                _holderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.lText attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
                
                self.lText.text = text;
                self.lText.attributedText = attrStr;
                [self.lText sizeToFit];
                break;
            }
            case 2:
                if (gotItButton){
                    [gotItButton removeFromSuperview];
                    gotItButton = nil;
                }
                [self.lText setTextColor:[UIColor whiteColor]];
                [self.vBackground setBackgroundColor:[UIColor darkGrayColor]];
                [self.lText setTextAlignment:NSTextAlignmentCenter];
                self.vBackground.layer.cornerRadius = 4.0f;
                self.contentViewBottomConstraint.constant = 5;


            
                self.leftOrRightConstraintByType = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:5];
                self.biggerSpaceFromLeftOrRightConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-5];

                _holderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.lText attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
                
                [self.lText setAttributedText:nil];
                [self.lText setText:text];
                [self.bubbleImage setImage: nil];
                break;
                //[self.vBackground setBackgroundColor:[UIColor darkGrayColor]];
            case 3:
                [self.lText setTextAlignment:NSTextAlignmentCenter];
                [self.bubbleImage setImage: nil];
                [self.lText setAttributedText:nil];
                [self.lText setText:text];
                
                [self.lText setTextColor:[UIColor whiteColor]];
                [self.vBackground setBackgroundColor:[UIColor darkGrayColor]];
                self.vBackground.layer.cornerRadius = 4.0f;
                self.contentViewBottomConstraint.constant = 5;
                self.leftOrRightConstraintByType = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:5];
                self.biggerSpaceFromLeftOrRightConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-5];
                ;
                
                if (gotItButton == nil) {
                    gotItButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    [gotItButton setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [gotItButton setTitle:@"GOT IT" forState:UIControlStateNormal];
                    [gotItButton addTarget:self action:@selector(sendGotIt:) forControlEvents:UIControlEventTouchUpInside];
                    gotItButton.layer.borderWidth = 1;
                    gotItButton.layer.borderColor = [UIColor whiteColor].CGColor;
                    gotItButton.layer.cornerRadius = 4;
                    
                    [self.vBackground addSubview:gotItButton];
                    
                    NSLayoutConstraint *topButtonConstraint = [NSLayoutConstraint constraintWithItem:gotItButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.lText attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
                    
                    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:gotItButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:80];
                    
                    NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:gotItButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.vBackground attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
                    
                    [gotItButton addConstraint:widthConstraint];
                    
                    [self.vBackground addConstraint:topButtonConstraint];
                    [self.vBackground addConstraint:centerConstraint];
                    
                }
                _holderBottomConstraint = [NSLayoutConstraint constraintWithItem:self.vBackground attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:gotItButton attribute:NSLayoutAttributeBottom multiplier:1 constant:10];
                
                [gotItButton setTag:[uniqueID intValue]];
                
                
                break;
                
        }
        // self.lText.preferredMaxLayoutWidth = CGRectGetWidth(self.frame) - 10;
        
        [self.vBackground addConstraint:self.holderBottomConstraint];
        [self.contentView addConstraint:self.leftOrRightConstraintByType];
        [self.contentView addConstraint:self.biggerSpaceFromLeftOrRightConstraint];
        self.type = type;
    } else {
        switch (type){
            case 0:
                [self.lText setText:text];
               
                break;
            case 1:
            {
                UIColor *color = [UIColor lightGrayColor]; // select needed color
                NSString *string = NSLocalizedString(@"crisis_team_chat",nil);
                NSDictionary *attrs = @{ NSForegroundColorAttributeName : color };
                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
                [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
                self.lText.attributedText = attrStr;
                [self.lText sizeToFit];
                break;
            }
            case 2:
                [self.lText setText:text];
               
                break;
            case 3:
                [self.lText setText:text];
                
                break;
        }
    }
}


- (void)sendGotIt:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    NSURLRequest *alarmRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@test/mob_gotit.php?device_id=%@&notification_id=%li",[[NSUserDefaults standardUserDefaults] stringForKey:@"api_url"], [Utils deviceUID], (long)[button tag]]]];
    NSURLConnection *triggerAlarm = [[NSURLConnection alloc] initWithRequest:alarmRequest delegate:self];
    
    [triggerAlarm start];
    
    [self setType:2 andText:[self.lText text] andUniqueID:nil];
    
}


@end
