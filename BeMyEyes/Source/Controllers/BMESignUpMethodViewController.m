//
//  BMESignUpMethodViewController.m
//  BeMyEyes
//
//  Created by Simon Støvring on 22/02/14.
//  Copyright (c) 2014 Be My Eyes. All rights reserved.
//

#import "BMESignUpMethodViewController.h"
#import <MRProgress/MRProgress.h>
#import <Accounts/Accounts.h>
#import "BMEAppDelegate.h"
#import "BMESignUpViewController.h"
#import "BMEClient.h"
#import "BMEUser.h"
#import "BMEFacebookInfo.h"
#import "NSString+BMEDeviceToken.h"

#define BMESignUpLoggedInSegue @"LoggedIn"
#define BMESignUpMethodSignUpSegue @"SignUp"
#define BMERegisteredSegue @"Registered"

@interface BMESignUpMethodViewController ()
@property (weak, nonatomic) IBOutlet UILabel *signUpTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *signUpBottomLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsBottomLabel;
@property (weak, nonatomic) IBOutlet UILabel *privacyTopLabel;
@property (weak, nonatomic) IBOutlet UILabel *privacyBottomLabel;
@property (weak, nonatomic) IBOutlet UIButton *emailSignUpButton;
@property (weak, nonatomic) IBOutlet UIButton *termsButton;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;
@property (weak, nonatomic) IBOutlet UILabel *facebookFooterLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *facebookFooterHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *facebookFooterTopMarginConstraint;
@end

@implementation BMESignUpMethodViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.signUpTopLabel.isAccessibilityElement = NO;
    self.signUpBottomLabel.isAccessibilityElement = NO;
    self.termsTopLabel.isAccessibilityElement = NO;
    self.termsBottomLabel.isAccessibilityElement = NO;
    self.privacyTopLabel.isAccessibilityElement = NO;
    self.privacyBottomLabel.isAccessibilityElement = NO;
    
    if (self.role == BMERoleHelper) {
        self.facebookFooterLabel.text = nil;
        self.facebookFooterHeightConstraint.constant = 0.0f;
        self.facebookFooterTopMarginConstraint.constant = 0.0f;
    }
}

- (void)shouldLocalize {
    self.emailSignUpButton.accessibilityLabel = MKLocalizedFromTable(BME_SIGN_UP_METHOD_EMAIL_ACCESSIBILITY_LABEL, BMESignUpMethodLocalizationTable);
    self.emailSignUpButton.accessibilityHint = MKLocalizedFromTable(BME_SIGN_UP_METHOD_EMAIL_ACCESSIBILITY_HINT, BMESignUpMethodLocalizationTable);
    
    self.termsButton.accessibilityLabel = MKLocalizedFromTable(BME_SIGN_UP_METHOD_TERMS_ACCESSIBILITY_LABEL, BMESignUpMethodLocalizationTable);
    self.termsButton.accessibilityHint = MKLocalizedFromTable(BME_SIGN_UP_METHOD_TERMS_ACCESSIBILITY_HINT, BMESignUpMethodLocalizationTable);
    
    self.privacyButton.accessibilityLabel = MKLocalizedFromTable(BME_SIGN_UP_METHOD_PRIVACY_ACCESSIBILITY_LABEL, BMESignUpMethodLocalizationTable);
    self.privacyButton.accessibilityHint = MKLocalizedFromTable(BME_SIGN_UP_METHOD_PRIVACY_ACCESSIBILITY_HINT, BMESignUpMethodLocalizationTable);
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)facebookButtonPressed:(id)sender {
    [self performFacebookRegistration];
}

- (IBAction)signUpButtonPressed:(id)sender {
    [self presentSignUp];
}

- (IBAction)signUpButtonTouched:(id)sender {
    self.signUpTopLabel.alpha = 0.50f;
    self.signUpBottomLabel.alpha = 0.50f;
}

- (IBAction)signUpButtonReleased:(id)sender {
    self.signUpTopLabel.alpha = 1.0f;
    self.signUpBottomLabel.alpha = 1.0f;
}

- (IBAction)termsButtonTouched:(id)sender {
    self.termsTopLabel.alpha = 0.50f;
    self.termsBottomLabel.alpha = 0.50f;
}

- (IBAction)termsButtonReleased:(id)sender {
    self.termsTopLabel.alpha = 1.0f;
    self.termsBottomLabel.alpha = 1.0f;
}

- (IBAction)privacyButtonTouched:(id)sender {
    self.privacyTopLabel.alpha = 0.50f;
    self.privacyBottomLabel.alpha = 0.50f;
}

- (IBAction)privacyButtonReleased:(id)sender {
    self.privacyTopLabel.alpha = 1.0f;
    self.privacyBottomLabel.alpha = 1.0f;
}

- (void)performFacebookRegistration {
    MRProgressOverlayView *progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view.window animated:YES];
    progressOverlayView.mode = MRProgressOverlayViewModeIndeterminate;
    progressOverlayView.titleLabelText = MKLocalizedFromTable(BME_SIGN_UP_METHOD_OVERLAY_REGISTERING_TITLE, BMESignUpMethodLocalizationTable);
    
    [[BMEClient sharedClient] authenticateWithFacebook:^(BMEFacebookInfo *fbInfo, NSError *error) {
        if (!error) {
            [[BMEClient sharedClient] createFacebookUserId:[fbInfo.userId longLongValue] email:fbInfo.email firstName:fbInfo.firstName lastName:fbInfo.lastName role:self.role completion:^(BOOL success, NSError *error) {
                    if (success && !error) {
                        progressOverlayView.titleLabelText = MKLocalizedFromTable(BME_SIGN_UP_METHOD_OVERLAY_LOGGING_IN_TITLE, BMESignUpMethodLocalizationTable);
                    
                        NSString *tempDeviceToken = [NSString BMETemporaryDeviceToken];
                        [GVUserDefaults standardUserDefaults].deviceToken = tempDeviceToken;
                        [GVUserDefaults standardUserDefaults].isTemporaryDeviceToken = YES;
                        [GVUserDefaults synchronize];
                        
                        [[BMEClient sharedClient] registerDeviceWithAbsoluteDeviceToken:tempDeviceToken active:NO production:BMEIsProductionOrAdHoc completion:^(BOOL success, NSError *error) {
                            if (success && !error) {
                                [[BMEClient sharedClient] loginWithEmail:fbInfo.email userId:[fbInfo.userId longLongValue] deviceToken:tempDeviceToken success:^(BMEToken *token) {
                                    [progressOverlayView hide:YES];
                                    
                                    [self didLogin];
                                } failure:^(NSError *error) {
                                    [progressOverlayView hide:YES];
                                    
                                    [self performSegueWithIdentifier:BMERegisteredSegue sender:self];
                                    
                                    NSLog(@"Failed logging in after sign up: %@", error);
                                }];
                            } else {
                                [progressOverlayView hide:YES];
                                
                                [self performSegueWithIdentifier:BMERegisteredSegue sender:self];
                                
                                NSLog(@"Failed registering device before automatic log in after sign up: %@", error);
                            }
                        }];    
                } else {
                    [progressOverlayView hide:YES];
                    
                    if ([error code] == BMEClientErrorUserEmailAlreadyRegistered)  {
                        NSString *title = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_TITLE, BMESignUpMethodLocalizationTable);
                        NSString *message = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_MESSAGE, BMESignUpMethodLocalizationTable);
                        NSString *cancelButton = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_EMAIL_ALREADY_REGISTERED_CANCEL, BMESignUpMethodLocalizationTable);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                        [alert show];
                    } else {
                        NSString *title = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_TITLE, BMESignUpMethodLocalizationTable);
                        NSString *message = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_MESSAGE, BMESignUpMethodLocalizationTable);
                        NSString *cancelButton = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_SIGN_UP_UNKNOWN_ERROR_CANCEL, BMESignUpMethodLocalizationTable);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }
            }];
        } else {
            [progressOverlayView hide:YES];
            
            if ([error code] == ACErrorAccountNotFound) {
                NSString *title = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_TITLE, BMESignUpMethodLocalizationTable);
                NSString *message = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_MESSAGE, BMESignUpMethodLocalizationTable);
                NSString *cancelButton = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_FACEBOOK_ACCOUNT_NOT_FOUND_CANCEL, BMESignUpMethodLocalizationTable);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil, nil];
                [alert show];
            } else {
                NSString *title = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_NOT_LOGGED_IN_TITLE, BMESignUpMethodLocalizationTable);
                NSString *message = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_NOT_LOGGED_IN_MESSAGE, BMESignUpMethodLocalizationTable);
                NSString *cancelButtonTitle = MKLocalizedFromTable(BME_SIGN_UP_METHOD_ALERT_NOT_LOGGED_IN_CANCEL, BMESignUpMethodLocalizationTable);
            
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }];
}

- (void)presentSignUp {
    [self performSegueWithIdentifier:BMESignUpMethodSignUpSegue sender:self];
}

- (void)didLogin {
    [[BMEClient sharedClient] updateUserInfoWithUTCOffset:nil];
    [[BMEClient sharedClient] updateDeviceWithDeviceToken:[GVUserDefaults standardUserDefaults].deviceToken active:![GVUserDefaults standardUserDefaults].isTemporaryDeviceToken productionOrAdHoc:BMEIsProductionOrAdHoc];
    
    [self performSegueWithIdentifier:BMESignUpLoggedInSegue sender:self];
}

#pragma mark -
#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:BMESignUpMethodSignUpSegue]) {
        ((BMESignUpViewController *)segue.destinationViewController).role = self.role;
    }
}

@end
