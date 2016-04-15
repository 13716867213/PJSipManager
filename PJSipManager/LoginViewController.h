//
//  LoginViewController.h
//  PJSipManager
//
//  Created by 单连超 on 16/4/6.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *serverTextFiled;

@property (weak, nonatomic) IBOutlet UITextField *code;

@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UITextField *port;


@end
