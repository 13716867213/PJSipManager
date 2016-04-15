//
//  PJSipManager.h
//  PJSipManager
//
//  Created by 单连超 on 16/4/6.
//  Copyright © 2016年 单连超. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsip.h>
#import <pjsua-lib/pjsua.h>

#import <UIKit/UIKit.h>

@interface  NSString (transform)

+(char *)cStringFromNSString:(NSString *)string;

@end

@implementation NSString (transform)
+(char *)cStringFromNSString:(NSString *)string
{
    if(!string) {
        return nil;
    }
    
    if(string.length == 0) {
        return "";
    }
    
    char *result = calloc([string length] + 1, 1);
    //    char *result = [string cStringUsingEncoding:NSUTF8StringEncoding];
    
    [string getCString:result maxLength:[string length] + 1 encoding:NSUTF8StringEncoding];
    
    
    return result;
}


@end



@interface PJSipManager : NSObject


@property (nonatomic,assign) char *sipServer;
@property (nonatomic,assign) char *sipCode;
@property (nonatomic,assign) char *sipPassWord;
@property (nonatomic,assign) char *sipPort;
@property (nonatomic,assign) int port;

//创建单例
+(PJSipManager *)sharePjsipmanager;

//注册
-(void)resigstFromServer;
//注册账号
-(void)resigstSip;

//删除账号
-(void)deleteSip;

//摧毁
-(void)destory;

//外呼
-(void)makeCallWithNumber:(NSString *)code;

//接听来电
-(void)answerCallWithCallId:(int)accId;

//挂断所有通话
-(void)hangUpAll;
//挂断通话
-(void)hangUpCall:(int)callId;

//通话中 键盘发送指令
-(void)sendCode:(NSString *)code;


//开始录音 有开始 就有结束 结束时需要pjsua_conf_port_id参数
-(pjsua_conf_port_id)startRecordWithCallId:(int)callId;
//结束录音
-(void)stopRecordWith:(pjsua_conf_port_id)recordId;

//静音
-(void)mutethecall;
//不静音
-(void)unmutethecall;



//外放 扩音
-(void)voiceOut;
//听筒
-(void)voice;











@end





