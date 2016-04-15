//
//  IncommingViewController.h
//  PJSipManager
//
//  Created by 单连超 on 16/4/7.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IncommingViewController : UIViewController


- (instancetype)initWithCode:(NSString *)code;
@property (weak, nonatomic) IBOutlet UILabel *codeLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;


@property (weak, nonatomic) IBOutlet UIButton *answerBtn;

@property (weak, nonatomic) IBOutlet UIButton *hanupBtn;



@end
