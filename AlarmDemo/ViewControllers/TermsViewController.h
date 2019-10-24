//
//  TermsViewController.h
//  AlarmDemo
//
//  Created by Aurimas Žibas on 2019-07-31.
//  Copyright © 2019 Baltic Amadeus. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TermsViewControllerDelegate <NSObject>
-(void)agreedTerms;
-(void)disagreedTerms;
@end

@interface TermsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *termsLabel;
@property (weak, nonatomic) IBOutlet UIButton *disagreeButton;
@property (weak, nonatomic) IBOutlet UIButton *aggreeButton;

@property (strong, nonatomic) NSString *text;

@property (weak, nonatomic)  id<TermsViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
