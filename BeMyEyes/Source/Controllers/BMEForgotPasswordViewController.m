//
//  BMEForgotPasswordViewController.m
//  BeMyEyes
//
//  Created by Simon Støvring on 13/06/14.
//  Copyright (c) 2014 Be My Eyes. All rights reserved.
//

#import "BMEForgotPasswordViewController.h"
#import <MRProgress/MRProgress.h>
#import "BMEEmailValidator.h"
#import "BMEClient.h"

@interface BMEForgotPasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@end

@implementation BMEForgotPasswordViewController

#pragma mark -
#pragma mark Private Methods

- (IBAction)sendNewPasswordButtonPressed:(id)sender {
    if ([self.emailTextField isFirstResponder]) {
        [self.emailTextField resignFirstResponder];
    }
    
    if ([self performEmailValidation]) {
        [self sendNewPasswordToEmail:self.emailTextField.text];
    }
}

- (BOOL)performEmailValidation {
    if ([BMEEmailValidator isEmailValid:self.emailTextField.text]) {
        return YES;
    } else {
        NSString *title = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_EMAIL_NOT_VALID_TITLE, BMEForgotPasswordLocalizationTable);
        NSString *message = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_EMAIL_NOT_VALID_MESSAGE, BMEForgotPasswordLocalizationTable);
        NSString *cancelButton = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_EMAIL_NOT_VALID_CANCEL, BMEForgotPasswordLocalizationTable);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
    }
}

- (void)sendNewPasswordToEmail:(NSString *)email {
    MRProgressOverlayView *progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view.window animated:YES];
    progressOverlayView.mode = MRProgressOverlayViewModeIndeterminate;
    progressOverlayView.titleLabelText = MKLocalizedFromTable(BME_FORGOT_PASSWORD_OVERLAY_SENDING_REQUEST_FOR_NEW_PASSWORD_TITLE, BMEForgotPasswordLocalizationTable);
    
    [[BMEClient sharedClient] sendNewPasswordToEmail:email completion:^(BOOL success, NSError *error) {
        [progressOverlayView hide:YES];
        
        if (error && [error code] != BMEClientErrorUserNotFound && [error code] != BMEClientErrorNotPermitted) {
            NSString *title = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_FAILED_TITLE, BMEForgotPasswordLocalizationTable);
            NSString *message = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_FAILED_MESSAGE, BMEForgotPasswordLocalizationTable);
            NSString *cancelButton = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_FAILED_CANCEL, BMEForgotPasswordLocalizationTable);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
            [alert show];
        } else {
            self.emailTextField.text = nil;
            
            NSString *title = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_SUCCESS_TITLE, BMEForgotPasswordLocalizationTable);
            NSString *message = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_SUCCESS_MESSAGE, BMEForgotPasswordLocalizationTable);
            NSString *cancelButton = MKLocalizedFromTable(BME_FORGOT_PASSWORD_ALERT_SEND_NEW_PASSWORD_REQUEST_SUCCESS_CANCEL, BMEForgotPasswordLocalizationTable);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
            [alert show];
        }
        
        if (error) {
            NSLog(@"Could not send request for new password: %@", error);
        }
    }];
}

#pragma mark -
#pragma mark Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
