//
//  LoginViewController.m
//  PJSipManager
//
//  Created by 单连超 on 16/4/6.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import "LoginViewController.h"
#import "PJSipManager.h"
#import "CallViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)loginAct:(id)sender {
    
    
    PJSipManager *manager = [PJSipManager sharePjsipmanager];
    manager.sipServer = [NSString cStringFromNSString:self.serverTextFiled.text];
    manager.sipCode = [NSString cStringFromNSString:self.code.text];
    manager.sipPassWord = [NSString cStringFromNSString:self.password.text];
    manager.sipPort = [NSString cStringFromNSString:self.port.text];
    manager.port = [self.port.text intValue];
    [manager resigstFromServer];
    
    CallViewController *call = [[CallViewController alloc] init];
    [self.navigationController presentViewController:call animated:YES completion:nil];
    
    
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
