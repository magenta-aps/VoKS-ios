#import <UIKit/UIKit.h>

@protocol PhoneNumberViewControllerDelegate <NSObject>
-(void)skippedPhone;
-(void)addedPhone;
@end

@interface PhoneNumberViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (weak, nonatomic) id<PhoneNumberViewControllerDelegate> delegate;
@end
