//
//  CallViewController.m
//  PJSipManager
//
//  Created by 单连超 on 16/4/7.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import "CallViewController.h"
#import "PJSipManager.h"

@interface CallViewController ()

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}
- (IBAction)CallOutAct:(id)sender {


    if (!IsStrEmpty(self.CodeTextFiled.text)) {
        [[PJSipManager sharePjsipmanager] makeCallWithNumber:self.CodeTextFiled.text];

    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请输入号码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }

    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
