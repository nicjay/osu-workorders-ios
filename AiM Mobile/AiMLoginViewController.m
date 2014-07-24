//
//  AiMLoginViewController.m
//  AiM Mobile
//
//  Created by Nick on 7/22/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "AiMLoginViewController.h"
#import "AiMWorkOrderTableViewController.h"
#import "AiMWorkOrder.h"
#import "AiMUser.h"
#import "SSKeychain.h"
#include <stdlib.h>


#define AUTH_URL @"http://httpbin.org"


@interface AiMLoginViewController () <NSURLSessionDelegate, NSURLSessionDataDelegate, UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *usernameTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *activityIndicatorLabel;
@property (strong, nonatomic)  NSURLProtectionSpace *loginProtectionSpace;
@property (strong, nonatomic) NSString *currentUser;

@property CGPoint startingPosField;
@property CGPoint endingPosField;
@property CGPoint startingPosLabel;
@property CGPoint endingPosLabel;
@property CGPoint hiddenLeftPosLabel;
@property CGPoint hiddenLeftPosField;

@property (strong, nonatomic) NSArray *priorities;
@property (strong, nonatomic) NSString *currentState;

@end

@implementation AiMLoginViewController

- (NSMutableArray *)receivedWorkOrders
{
    if(!_receivedWorkOrders)
    {
        _receivedWorkOrders = [[NSMutableArray alloc] init];
    }
    return _receivedWorkOrders;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AiMWorkOrderPhasePriority*)createPriorityWithName:(NSString*)name andDescription:(NSString*)description andPriorityID:(NSNumber*)priorityID
{
    AiMWorkOrderPhasePriority *priority = [[AiMWorkOrderPhasePriority alloc] init];
    priority.name = name;
    priority.description = description;
    priority.priorityID = priorityID;
    
    return priority;
}

- (void) getWorkOrdersJSON
{
    AiMWorkOrderPhasePriority *priority = [[AiMWorkOrderPhasePriority alloc] init];
    priority.name = @"Urgent";
    priority.description = @"Must be done quickly";
    priority.priorityID = @0;
    
    self.priorities = [NSArray arrayWithObjects:[self createPriorityWithName:@"URGENT" andDescription:@"Do this quickly" andPriorityID:@0],
    [self createPriorityWithName:@"GENERAL" andDescription:@"Do this regularly" andPriorityID:@1],
     [self createPriorityWithName:@"DAILY" andDescription:@"Do this daily" andPriorityID:@2], nil];
    
    NSLog(@"This is the array... %@", self.priorities);
    //Get JSON from http
    
    
    
    //Call segue, passing JSON to AiMOverviewTableController
    

}
- (IBAction)backButton:(UIButton *)sender {
    NSLog(@"Back Button Pressed! %@", self.currentState);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.usernameTextField.layer.position = self.startingPosField;
        self.passwordTextField.layer.position = self.hiddenLeftPosField;
        
        self.usernameTextLabel.layer.position = self.startingPosLabel;
        self.passwordTextLabel.layer.position = self.hiddenLeftPosLabel;
        
    }];
    self.currentState = @"username";
    [self.loginButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.usernameTextField becomeFirstResponder];
    self.backButton.hidden = YES;
}
- (IBAction)loginButton:(id)sender
{
  
    [self loginAnimationHandler];
    
}
-(void)loginAnimationHandler
{
    self.startingPosField = self.usernameTextField.layer.position;
    self.endingPosField = CGPointMake(self.startingPosField.x + (self.view.frame.size.width), self.startingPosField.y);
    self.startingPosLabel = self.usernameTextLabel.layer.position;
    self.endingPosLabel = CGPointMake(self.startingPosLabel.x + (self.view.frame.size.width), self.startingPosLabel.y);
    
    
    
    CAKeyframeAnimation * jiggleAnim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    jiggleAnim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    jiggleAnim.autoreverses = YES;  jiggleAnim.repeatCount = 2.0f;  jiggleAnim.duration = 0.07f;
    
    NSLog(@"CurrentState = %@", self.currentState);
    
    if([self.currentState isEqualToString:@"username"])
    {
        if([self.usernameTextField.text length] > 0)
        {
            [self.usernameTextField resignFirstResponder];
            [self.passwordTextField becomeFirstResponder];
            [UIView animateWithDuration:0.5 animations:^{
                self.usernameTextField.layer.position = self.endingPosField;
                self.passwordTextField.layer.position = self.startingPosField;
                
                self.usernameTextLabel.layer.position = self.endingPosLabel;
                self.passwordTextLabel.layer.position = self.startingPosLabel;
                
            }];
            self.currentState = @"password";
            [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
            self.backButton.hidden = NO;
        }else{
            [self.usernameTextLabel.layer addAnimation:jiggleAnim forKey:nil];
            [self.usernameTextField.layer addAnimation:jiggleAnim forKey:nil];
            self.usernameTextLabel.textColor = [UIColor redColor];
            self.usernameTextField.layer.borderColor = (__bridge CGColorRef)([UIColor redColor]);
        }
    }else if([self.currentState isEqualToString:@"password"])
    {
        if([self.passwordTextField.text length] > 0)
        {
            [self.passwordTextField resignFirstResponder];
            [self.usernameTextField becomeFirstResponder];
            [self authenticateUser:self.usernameTextField.text withPassword:self.passwordTextField.text];
            self.passwordTextLabel.hidden = YES;
            //self.activityIndicator.hidden = NO;
            //self.activityIndicatorLabel.hidden = NO;
            
            [UIView animateWithDuration:0.5 animations:^{
                self.passwordTextField.layer.position = self.endingPosField;
                self.passwordTextLabel.layer.position = self.endingPosLabel;
                self.activityIndicatorLabel.layer.opacity = 1.0f;
                self.activityIndicator.layer.opacity = 1.0f;
            }];
            
            
            
        }else{
            [self.passwordTextLabel.layer addAnimation:jiggleAnim forKey:nil];
            [self.passwordTextField.layer addAnimation:jiggleAnim forKey:nil];
            self.passwordTextLabel.textColor = [UIColor redColor];
            self.passwordTextField.layer.borderColor = (__bridge CGColorRef)([UIColor redColor]);
        }
    }
}

- (void) initProtectionSpace
{
    NSURL *url = [NSURL URLWithString:AUTH_URL];
    self.loginProtectionSpace = [[NSURLProtectionSpace alloc] initWithHost:url.host
                                                                      port:[url.port integerValue]
                                                                  protocol:url.scheme
                                                                     realm:nil
                                                      authenticationMethod:NSURLAuthenticationMethodHTTPDigest];

}

- (void) setUserCredential: (NSString *)username withPassword:(NSString *)password
{
    //Check if username already stored before adding
    NSURLCredential *credential;
    NSDictionary *credentials;
    
    credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.loginProtectionSpace];
    credential = [credentials objectForKey:username];
    
    //If this username is not already stored
    if (!credential)
    {
        credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
        [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:self.loginProtectionSpace];
    }

}



- (NSURLCredential *) getUserCredential
{
    //Find and return the first credential found
    
    NSURLCredential *credential;
    NSDictionary *credentials;
    
    credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.loginProtectionSpace];
    credential = [credentials.objectEnumerator nextObject];
    
    return credential;
}


- (void) removeUserCredential: (NSString *)username
{
    NSURLCredential *credential;
    NSDictionary *credentials;
    
    credentials = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:self.loginProtectionSpace];
    
    //Search if it exists before removing
    credential = [credentials objectForKey:username];
    
    if (credential)
    {
        [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:self.loginProtectionSpace];
    } else {
        NSLog(@"Could not find credential to remove");
    }
}




- (void)authenticateUser:(NSString *)username withPassword:(NSString *)password
{
    
    NSString *userDataString = [NSString stringWithFormat:@"username=%@password=%@", username, password];
    
    NSURL *url = [NSURL URLWithString:AUTH_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSData *data = [userDataString dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //[sessionConfiguration setHTTPAdditionalHeaders:@{@"Accept":@"application/json"}];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    //session.delegate = [NSOperationQueue mainQueue];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //NSLog(@"Reponse recieved! Data: %@, Response: %@, Error: %@", data, response, error);

        
        if(!error)
        {
            NSLog(@"User authenticated. Retrieving work orders... %@", data);

            //Assume credentials are valid, attempt to store in keychain for future use
            self.currentUser = username;
            [self setUserCredential:username withPassword:password];

            
            // TODO: set recievedWorkOrders
            //for loop adding each workOrder object to array
            //self.receivedWorkOrders
            for(int i = 0; i < 10; i++)
            {
                AiMWorkOrder *newWorkOrder = [[AiMWorkOrder alloc] init];
                int r = rand() % 1000;
                
                newWorkOrder.taskID = [NSNumber numberWithInt:r];
                newWorkOrder.category = @"TestCategory";
                newWorkOrder.description = @"Test Description";
                newWorkOrder.createdBy = @"Kevin";
                newWorkOrder.dateCreated = [NSDate date];
                newWorkOrder.customerRequest = @12;
                newWorkOrder.type = @"1";
                newWorkOrder.organization = [[AiMOrganization alloc] init];
                newWorkOrder.phase = [[AiMWorkOrderPhase alloc] init];
                
                
                
                
                //NSLog(@"Work order: %@ 1", newWorkOrder.taskID);
                //NSLog(@"Idk what to do %@", self.receivedWorkOrders);
                [self.receivedWorkOrders addObject:newWorkOrder];
                //AiMWorkOrder *test = [self.receivedWorkOrders objectAtIndex:0];
                //NSLog(@"2recievedWorkOrders : %@", test);
            }
            

            dispatch_async(dispatch_get_main_queue(), ^{
                AiMWorkOrderTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"WorkOrderTableView"];
                vc.workOrders = self.receivedWorkOrders;
                NSLog(@"Setting vc.workOrders = %@", _receivedWorkOrders);
                [self.navigationController pushViewController:vc animated:NO];
            });
        }else
        {
            //Alert user. Get new user credentials
            NSLog(@"Failed to authenticate.");
        }
    }];
    [postDataTask resume];

    
   
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getWorkOrdersJSON];
    
    self.currentState = @"username";
    self.activityIndicator.layer.opacity = 0.0f;
    self.activityIndicatorLabel.layer.opacity = 0.0f;
    self.backButton.hidden = YES;
    self.hiddenLeftPosField = self.passwordTextField.layer.position;
    self.hiddenLeftPosLabel = self.passwordTextLabel.layer.position;
    
    [self.usernameTextField setReturnKeyType:UIReturnKeyNext];
    [self.passwordTextField setReturnKeyType:UIReturnKeyGo];
    //[self.usernameTextField becomeFirstResponder];
    
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    [self initProtectionSpace];
    
    self.passwordTextField.secureTextEntry = YES;
 
    

    NSURLCredential *credential = [self getUserCredential];
    
//    if (credential)
//    {
//        NSLog(@"User %@ already connected with password %@", credential.user, credential.password);
//        [self authenticateUser:credential.user withPassword: credential.password];
//
//    } else {
//        NSLog(@"No credentials found.");
//        //Assume user will enter credentials into text fields and press login button
//    }

    
    
    /*
     Check properties for last user
     
    Check if user info is saved in keychain
    if yes
        send credentials
    else
        prompt user for info
        send credentials
     
     
     if credentials ok
        do getworkerjson http stuff
     else 
        prompt user
     
     
     
     
     
     */
    
    
    
    
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
    if(textField == self.usernameTextField)
    {
        if([self.usernameTextField.text length] > 0)
        {
            [textField resignFirstResponder];
            [self.passwordTextField becomeFirstResponder];
            [self loginAnimationHandler];
        }
    }else if(textField == self.passwordTextField)
    {
        if([self.passwordTextField.text length] > 0)
        {
            [textField resignFirstResponder];
            [self loginAnimationHandler];
        }
    }

    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"LoginShowTable"])
    {
        //AiMWorkOrderTableViewController *vc = [segue destinationViewController];
    
    }
    
}





- (IBAction)unwindToLoginView:(UIStoryboardSegue *)segue
{
    NSLog(@"segue: %@", segue.identifier);
    [self removeUserCredential:self.currentUser];

    
}



@end
