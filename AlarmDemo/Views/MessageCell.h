/*
 * BComeSafe, http://bcomesafe.com
 * Copyright 2015 Magenta ApS, http://magenta.dk
 * Licensed under MPL 2.0, https://www.mozilla.org/MPL/2.0/
 * Developed in co-op with Baltic Amadeus, http://baltic-amadeus.lt
 */

#import <UIKit/UIKit.h>

@interface MessageCell : UITableViewCell {
    UIButton *gotItButton;
}

@property (weak, nonatomic) IBOutlet UILabel *lText;
@property (weak, nonatomic) IBOutlet UIView *vBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftOrRightConstraintByType;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *biggerSpaceFromLeftOrRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *holderBottomConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImage;

@property (assign, nonatomic) int type;

-(void) setType:(int) type andText:(NSString *)text andUniqueID:(NSNumber *) uniqueID;

@end
