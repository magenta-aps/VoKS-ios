#import "PhoneConfirmViewController.h"
#import "ShelterAPI.h"
#import "Utils.h"

@interface PhoneConfirmViewController ()

@end

@implementation PhoneConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];
}

- (void)prepareUI {
    _explanationLabel.text = NSLocalizedString(@"phone_confirm_explanation", nil);
    [_cancelButton setTitle:NSLocalizedString(@"phone_confirm_cancel", nil) forState: UIControlStateNormal];
    [_submitButton setTitle:NSLocalizedString(@"phone_confirm_submit", nil) forState: UIControlStateNormal];
    [_resendButton setTitle:NSLocalizedString(@"send_code_again", nil) forState: UIControlStateNormal];

    [_tokenTextField setPlaceholder:NSLocalizedString(@"phone_confirm_hint", nil)];
    _tokenTextField.delegate = self;

    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];

    [self.view addGestureRecognizer: tapRecognizer];
}

- (void)closeKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)cancelAction:(id)sender {
    [ShelterAPI updateDevice: @{@"device_id": [Utils deviceUID], @"skip_phone": @"1"} successBlock:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user_phone"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"need_phone"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_phone_confirm"];
        dispatch_async(dispatch_get_main_queue(),^{
            [self.delegate skippedConfirmation];
            [[self navigationController] popViewControllerAnimated:true];
        });
    } failureBlock:^{
        [self showError];
    }];
}
- (IBAction)resendAction:(id)sender {
    [ShelterAPI updateDevice:@{@"device_id": [Utils deviceUID], @"user_phone": [[NSUserDefaults standardUserDefaults] stringForKey:@"user_phone"]} successBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"code_resent", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

            [self presentViewController:alertController animated:true completion:nil];
        });
    } failureBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Something went wrong, try again", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

            [self presentViewController:alertController animated:true completion:nil];

        });
    }];
}

- (IBAction)submitAction:(id)sender {
    NSString *token = [_tokenTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (token.length == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"error_phone_token_empty", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

        [self presentViewController:alertController animated:true completion:nil];
        return;
    }


    [ShelterAPI updateDevice: @{@"device_id": [Utils deviceUID], @"user_phone_token": token} successBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"need_phone"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_phone_confirm"];
            [self.delegate confirmedPhone];
            [[self navigationController] popViewControllerAnimated:true];
        });
    } failureBlock:^{
        [self showError];
    }];
}

- (void)showError {
    dispatch_async(dispatch_get_main_queue(),^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Something went wrong, try again", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

        [self presentViewController:alertController animated:true completion:nil];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

@end
