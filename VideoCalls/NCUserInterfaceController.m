//
//  NCUserInterfaceController.m
//  VideoCalls
//
//  Created by Ivan Sein on 28.02.18.
//  Copyright © 2018 struktur AG. All rights reserved.
//

#import "NCUserInterfaceController.h"

#import "AFNetworking.h"
#import "AuthenticationViewController.h"
#import "LoginViewController.h"
#import "NCConnectionController.h"
#import "NCRoomsManager.h"
#import "NCSettingsController.h"
#import "JDStatusBarNotification.h"

@interface NCUserInterfaceController () <LoginViewControllerDelegate, AuthenticationViewControllerDelegate>
{
    LoginViewController *_loginViewController;
    AuthenticationViewController *_authViewController;
}

@end

@implementation NCUserInterfaceController

+ (NCUserInterfaceController *)sharedInstance
{
    static dispatch_once_t once;
    static NCUserInterfaceController *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStateHasChanged:) name:NCConnectionStateHasChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentConversationsViewController
{
    [self.mainTabBarController setSelectedIndex:0];
}

- (void)presentContactsViewController
{
    [self.mainTabBarController setSelectedIndex:1];
}

- (void)presentSettingsViewController
{
    [self.mainTabBarController setSelectedIndex:2];
}

- (void)presentLoginViewController
{
    _loginViewController = [[LoginViewController alloc] init];
    _loginViewController.delegate = self;
    [self.mainTabBarController presentViewController:_loginViewController animated:YES completion:nil];
}

- (void)presentAuthenticationViewController
{
    _authViewController = [[AuthenticationViewController alloc] init];
    _authViewController.delegate = self;
    _authViewController.serverUrl = [NCSettingsController sharedInstance].ncServer;
    [self.mainTabBarController presentViewController:_authViewController animated:YES completion:nil];
}

- (void)presentOfflineWarningAlert
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Disconnected"
                                 message:@"It seems that there is no Internet connection."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:nil];
    
    [alert addAction:okButton];
    
    [self.mainTabBarController presentViewController:alert animated:YES completion:nil];
}

- (void)presentChatForPushNotification:(NCPushNotification *)pushNotification
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:pushNotification forKey:@"pushNotification"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NCPushNotificationJoinChatNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)presentAlertForPushNotification:(NCPushNotification *)pushNotification
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:[pushNotification bodyForRemoteAlerts]
                                 message:@"Do you want to join this call?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *joinAudioButton = [UIAlertAction
                                      actionWithTitle:@"Join call (audio only)"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:pushNotification forKey:@"pushNotification"];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:NCPushNotificationJoinAudioCallAcceptedNotification
                                                                                              object:self
                                                                                            userInfo:userInfo];
                                      }];
    
    UIAlertAction *joinVideoButton = [UIAlertAction
                                      actionWithTitle:@"Join call with video"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * _Nonnull action) {
                                          NSDictionary *userInfo = [NSDictionary dictionaryWithObject:pushNotification forKey:@"pushNotification"];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:NCPushNotificationJoinVideoCallAcceptedNotification
                                                                                              object:self
                                                                                            userInfo:userInfo];
                                      }];
    
    UIAlertAction* cancelButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:nil];
    
    [joinAudioButton setValue:[[UIImage imageNamed:@"call-action"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [joinVideoButton setValue:[[UIImage imageNamed:@"videocall-action"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    
    [alert addAction:joinAudioButton];
    [alert addAction:joinVideoButton];
    [alert addAction:cancelButton];
    
    // Do not show join call dialog until we don't handle 'hangup current call'/'join new one' properly.
    if (![NCRoomsManager sharedInstance].callViewController) {
        [self.mainTabBarController dismissViewControllerAnimated:NO completion:nil];
    }

    [self.mainTabBarController presentViewController:alert animated:YES completion:nil];
}

- (void)presentAlertViewController:(UIAlertController *)alertViewController
{
    [self.mainTabBarController presentViewController:alertViewController animated:YES completion:nil];
}

- (void)presentChatViewController:(NCChatViewController *)chatViewController
{
    [self presentConversationsViewController];
    UINavigationController *conversationsNC = [[self.mainTabBarController viewControllers] objectAtIndex:0];
    [conversationsNC popToRootViewControllerAnimated:NO];
    [conversationsNC pushViewController:chatViewController animated:YES];
}

- (void)presentCallViewController:(CallViewController *)callViewController
{
    [self.mainTabBarController presentViewController:callViewController animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)connectionStateHasChanged:(NSNotification *)notification
{
    ConnectionState connectionState = [[notification.userInfo objectForKey:@"connectionState"] intValue];
    switch (connectionState) {
        case kConnectionStateDisconnected:
            [JDStatusBarNotification showWithStatus:@"Network not available" dismissAfter:4.0f styleName:JDStatusBarStyleError];
            break;
            
        case kConnectionStateConnected:
            [JDStatusBarNotification showWithStatus:@"Network available" dismissAfter:4.0f styleName:JDStatusBarStyleSuccess];
            break;
            
        default:
            break;
    }
}

#pragma mark - LoginViewControllerDelegate

- (void)loginViewControllerDidFinish:(LoginViewController *)viewController
{
    [[NCConnectionController sharedInstance] checkAppState];
    [self.mainTabBarController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AuthenticationViewControllerDelegate

- (void)authenticationViewControllerDidFinish:(AuthenticationViewController *)viewController
{
    [[NCConnectionController sharedInstance] checkAppState];
    [self.mainTabBarController dismissViewControllerAnimated:YES completion:nil];
}

@end
