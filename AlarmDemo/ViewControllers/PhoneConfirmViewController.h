#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PhoneConfirmViewControllerDelegate <NSObject>
-(void)skippedConfirmation;
-(void)confirmedPhone;
@end

@interface PhoneConfirmViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;

@property (weak, nonatomic) id<PhoneConfirmViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
