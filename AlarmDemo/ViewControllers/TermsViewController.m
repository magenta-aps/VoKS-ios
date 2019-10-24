#import "TermsViewController.h"
#import "ShelterAPI.h"
#import "Utils.h"

@interface TermsViewController ()

@end

@implementation TermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];
}

- (void)prepareUI {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAttributedString *htmlString = [[NSAttributedString alloc] initWithData:[_text dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                    NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                               documentAttributes:nil error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            _termsLabel.attributedText = htmlString;
        });
    });

    [_disagreeButton setTitle:NSLocalizedString(@"tac_decline", nil) forState:UIControlStateNormal];
    [_aggreeButton setTitle:NSLocalizedString(@"tac_accept", nil) forState:UIControlStateNormal];

}


- (IBAction)disagreeAction:(id)sender {
    [ShelterAPI updateDevice: @{@"accepted_tac": @0, @"device_id": [Utils deviceUID]} successBlock:^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"need_tac"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate disagreedTerms];
            [self.navigationController popViewControllerAnimated:true];
        });
    } failureBlock:^{
        [self showError];
    }];
}

- (IBAction)aggreeAction:(id)sender {
    [ShelterAPI updateDevice: @{@"accepted_tac": @1, @"device_id": [Utils deviceUID]} successBlock:^{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"need_tac"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate agreedTerms];
            [self.navigationController popViewControllerAnimated:true];
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

@end
