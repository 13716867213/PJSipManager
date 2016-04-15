//
//  CallOutViewController.m
//  PJSipManager
//
//  Created by 单连超 on 16/4/7.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import "CallOutViewController.h"
#import "PJSipManager.h"

@interface CallOutViewController ()
{
    
}


@end

@implementation CallOutViewController

- (instancetype)initWithCode:(NSString *)code
{
    self = [super init];
    if (self) {
        
        self.CodeLabel.text = code;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stateLabel.text = @"等待接通";
}

- (IBAction)recordAct:(id)sender {
    
}

- (IBAction)muteAct:(id)sender {
}

- (IBAction)keyboardAct:(id)sender {
}

- (IBAction)voiceOutAct:(id)sender {
}
- (IBAction)hangUpCall:(id)sender {
}
- (IBAction)keyboardNumAct:(id)sender {
    
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
