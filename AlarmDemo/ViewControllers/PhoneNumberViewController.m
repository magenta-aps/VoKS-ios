#import "PhoneNumberViewController.h"
#import "Utils.h"
#import "ShelterAPI.h"

@interface PhoneNumberViewController ()

@end

@implementation PhoneNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self prepareUI];
}

- (void)prepareUI {
    _explanationLabel.text = NSLocalizedString(@"phone_explanation", nil);
    _descriptionLabel.text = NSLocalizedString(@"phone_description", nil);
    [_deleteButton setTitle:NSLocalizedString(@"phone_delete", nil) forState:UIControlStateNormal];
    [_skipButton setTitle:NSLocalizedString(@"phone_skip", nil) forState:UIControlStateNormal];
    [_submitButton setTitle:NSLocalizedString(@"phone_submit", nil) forState:UIControlStateNormal];

    [_phoneNumberTextField setPlaceholder:NSLocalizedString(@"phone_hint", nil)];
    _phoneNumberTextField.delegate = self;

    NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_phone"];
    if ([phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        [_deleteButton setHidden:NO];
    } else {
        [_deleteButton setHidden:YES];
    }
    
    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];

    [self.view addGestureRecognizer: tapRecognizer];
}

- (void)closeKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)deleteAction:(id)sender {
    UIAlertController *confirmController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"delete_phone_dialog_title", nil) message:NSLocalizedString(@"delete_phone_dialog_message", nil) preferredStyle:UIAlertControllerStyleAlert];
    [confirmController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"delete_phone_dialog_cancel", nil) style: UIAlertActionStyleCancel handler:nil]];

    [confirmController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"delete_phone_dialog_confirm", nil) style: UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

        parameters[@"device_id"] = [Utils deviceUID];
        parameters[@"user_phone"] = @"";

        [ShelterAPI updateDevice:parameters successBlock:^{
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user_phone"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"need_phone"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_phone_confirm"];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [[self navigationController] popViewControllerAnimated:true];
            });
        } failureBlock:^{
            dispatch_async(dispatch_get_main_queue(),^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Something went wrong, try again", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

                [self presentViewController:alertController animated:true completion:nil];

            });
        }];
    }]];
}
- (IBAction)skipAction:(id)sender {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    parameters[@"device_id"] = [Utils deviceUID];
    parameters[@"skip_phone"] = @"1";

    [ShelterAPI updateDevice:parameters successBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user_phone"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"need_phone"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_phone_confirm"];

            [self.delegate skippedPhone];
            [[self navigationController] popViewControllerAnimated:true];
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

    NSString *phoneNumber = [_phoneNumberTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (phoneNumber.length == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"error_phone_empty", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

        [self presentViewController:alertController animated:true completion:nil];
        return;
    }

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    parameters[@"device_id"] = [Utils deviceUID];
    parameters[@"user_phone"] = phoneNumber;

    [ShelterAPI updateDevice:parameters successBlock:^{
        [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:@"user_phone"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_phone_confirm"];
        dispatch_async(dispatch_get_main_queue(),^{

            [self.delegate addedPhone];
            [[self navigationController] popViewControllerAnimated:true];
        });
    } failureBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Something went wrong, try again", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:true completion:nil];

        });
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}
@end
