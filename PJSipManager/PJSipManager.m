//
//  PJSipManager.m
//  PJSipManager
//
//  Created by 单连超 on 16/4/6.
//  Copyright © 2016年 单连超. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "PJSipManager.h"

#import "IncommingViewController.h"

#define THIS_FILE "APP"
const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;

static void error_exit(const char *title, pj_status_t status);
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state(pjsua_acc_id acc_id);
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info);


@implementation PJSipManager
{
    char *sport;
    pjsua_acc_id _acc_id;
    
}


+(PJSipManager *)sharePjsipmanager
{
    static PJSipManager *install = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        install = [[PJSipManager alloc] init];
    });
    
    return install;

}


-(void)resigstFromServer
{
    
    pj_status_t status;
    
    //ios端的 app后台运行 只能接受tcp 活跃状态最好用udp
    sport = "tcp";
    
    
    //获取状态
    pjsua_state state = pjsua_get_state();
    if (state == PJSUA_STATE_RUNNING) {
        //如果正在运行  摧毁掉
        [self destory];
    }
    
    
    
    //创建
    status = pjsua_create();
    if (state != PJ_SUCCESS) error_exit("Error in pjsua_create()", state);
    
    {
        pjsua_config cfg;
        pjsua_config_default(&cfg);
        cfg.cb.on_call_state = on_call_state;//通话状态回调
        cfg.cb.on_incoming_call = on_incoming_call;//来电回调
        cfg.cb.on_call_media_state = &on_call_media_state;
        cfg.cb.on_reg_state2 = &on_reg_state2;//sip在线状态回调
        cfg.cb.on_reg_state=&on_reg_state;
        
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
        
        //初始化
        status = pjsua_init(&cfg, &log_cfg, NULL);
        if (state != PJ_SUCCESS) error_exit("Error in pjsua_init()", status);
    }
    
    
    //iOS 后台运行是只能用tcp 活跃状态用udp
    //    // Add UDP transport.
    //    {
    //        // Init transport config structure
    //        pjsua_transport_config cfg;
    //        pjsua_transport_config_default(&cfg);
    //        if (self.sipPort.length>0) {
    //            cfg.port = [self.sipPort intValue];
    //        }
    //        // Add TCP transport.
    //        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
    //        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    //    }
    
    // Add TCP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = self.port;
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    
    [self resigstSip];
    
}

//注册账号
-(void)resigstSip
{
    pj_status_t status;

    if ([self pjThreadNotRegister]) {
        return;
    }
    
    
    char proxy[64];
    
    sprintf(proxy, "sip:%s:%s;transport=%s",_sipServer,_sipPort,sport);
    
    pjsua_acc_config cfg;
    pjsua_acc_config_default(&cfg);
    
    
    char sipId[MAX_SIP_ID_LENGTH];
    sprintf(sipId, "sip:%s@%s:%s;transport=%s",_sipCode,_sipServer,_sipPort,sport);
    cfg.id = pj_str(sipId);
    
    //Reg URI
    char regUri[MAX_SIP_REG_URI_LENGTH];
    sprintf(regUri, "sip:%s:%s;transport=%s", _sipServer,_sipPort,sport);
    
    cfg.reg_uri = pj_str(regUri);
    
    // Account cred info
    cfg.cred_count = 1;
    cfg.proxy_cnt=1;
    cfg.proxy[0] = pj_str(proxy);
    cfg.reg_use_proxy=0;
    cfg.reg_timeout = 60;//活跃状态时设置60 - 300 后台待机时设置大于600s
    cfg.cred_info[0].scheme = pj_str("digest");
    cfg.cred_info[0].realm = pj_str(_sipServer);
    cfg.cred_info[0].username = pj_str(_sipCode);
    cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    cfg.cred_info[0].data = pj_str(_sipPassWord);
    
    //添加账号
    status = pjsua_acc_add(&cfg, PJ_TRUE, &_acc_id);
    if (status != PJ_SUCCESS) error_exit("Error in pjsua_acc_add", status);
    
}


//删除账号
-(void)deleteSip
{
    if ([self pjThreadNotRegister]) {
        return;
    }
    
    pjsua_state state;
    
    
    state =  pjsua_acc_del(_acc_id);
    
    if (state != PJ_SUCCESS) error_exit("Error in  pjsua_acc_del", state);
    
}



//摧毁
-(void)destory
{
    pj_status_t status;
    if ([self pjThreadNotRegister]) {
        return;
    }
    status = pjsua_destroy();
    if (status != PJ_SUCCESS) {
        error_exit("Error pjsua_destroy", status);
    }

}


//外呼
-(void)makeCallWithNumber:(NSString *)code
{
    //code不能为空 否则闪退
//    if (IsStrEmpty(code)||[self pjThreadNotRegister]) {
//        return;
//    }
    pj_status_t status;

    
    pj_thread_desc rtpdesc;
    pj_thread_t *thread = 0;
    
    if( !pj_thread_is_registered())
    {
        status = pj_thread_register(NULL,rtpdesc,&thread);
        
        if (status != PJ_SUCCESS) {
            error_exit("Error in  pj_thread_register", status);
            
        }
    }

    
    NSString *sipUriStr = [NSString stringWithFormat:@"sip:%@@%s:%s",code,_sipServer,_sipPort];
    char *sipuri = [NSString cStringFromNSString:sipUriStr];
    
    pj_str_t uri = pj_str(sipuri);
    

    
    status = pjsua_call_make_call(_acc_id, &uri, 0, NULL, NULL, NULL);
    
    if (status != PJ_SUCCESS)
    {
        error_exit("Error making call", status);
    }

}



//接听来电

-(void)answerCallWithCallId:(int)accId
{
    if ([self pjThreadNotRegister]) {
        return;
    }
    
    pj_status_t status;
    status = pjsua_call_answer(accId, 200, NULL, NULL);
    if (status != PJ_SUCCESS) {
        error_exit("Error in pjsua_call_answer", status);
    }
}

//挂断所有通话
-(void)hangUpAll
{
    if ([self pjThreadNotRegister]) {
        return;
    }
    pjsua_call_hangup_all();

}



//开始录音
-(pjsua_recorder_id)startRecordWithCallId:(int)callId
{
    //文件路径  文件必须是wav格式的
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [doc stringByAppendingPathComponent:@"record.wav"];
    char *file = [NSString cStringFromNSString:path];
    pj_str_t path1 = pj_str(file);
    
    pjsua_recorder_id recorder_id;

    pj_status_t state = pjsua_recorder_create(&path1, 0, NULL, 0, 0, &recorder_id);
    if (state != PJ_SUCCESS)
    {
        error_exit("Error making record", state);
    }
    
    pjsua_conf_port_id recordId = pjsua_recorder_get_conf_port(recorder_id);
    pjsua_conf_port_id call_id = pjsua_call_get_conf_port(callId);
    
    state = pjsua_conf_connect(0, recordId);
    if (state != PJ_SUCCESS)
    {
        error_exit("Error making record", state);
    }

    
    //录对面的声音
    state = pjsua_conf_connect(call_id, recordId);
    
    if (state != PJ_SUCCESS)
    {
        error_exit("Error making record", state);
    }
    
    
    //结束录音的时候 需要这个参数
    return recorder_id;

}

//结束录音
-(void)stopRecordWith:(pjsua_recorder_id)recordId
{
    pj_status_t state;
    if ([self pjThreadNotRegister]) {
        return;
    }
    state = pjsua_recorder_destroy(recordId);
    if (state != PJ_SUCCESS)
    {
        error_exit("Error pjsua_recorder_destroy", state);
    }
}

//通话中 键盘发送指令
-(void)sendCode:(NSString *)code withCallId:(int)callId
{
    if ([self pjThreadNotRegister]) {
        return;
    }
    
    pj_status_t status;
    char *number = [NSString cStringFromNSString:code];
    pj_str_t uri = pj_str(number);
    status = pjsua_call_dial_dtmf(callId,&uri);
    if (status != PJ_SUCCESS)
    {
        error_exit("Error pjsua_call_dial_dtmf", status);
    }

}


//静音
-(void)mutethecall
{
    pj_status_t status;
    if ([self pjThreadNotRegister]) {
        return;
    }
    status =   pjsua_conf_adjust_rx_level (0,0);
    if (status != PJ_SUCCESS) {
        error_exit("Error mutethecall", status);
    }
}


//关闭静音
-(void)unmutethecall
{
    pj_status_t status;
    if ([self pjThreadNotRegister]) {
        return;
    }

    status =   pjsua_conf_adjust_rx_level (0,1);
    if (status != PJ_SUCCESS) {
        error_exit("Error unmutethecall", status);
    }
    
    
}


//外放 扩音
-(void)voiceOut
{
    dispatch_async(dispatch_get_main_queue(), ^{
       [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    });
    
   

}
//听筒
-(void)voice
{
    dispatch_async(dispatch_get_main_queue(), ^{
       [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    });
}







//线程注册  每次调用函数的时候 都要先判断一下 当前线程有没有注册
-(BOOL)pjThreadNotRegister
{
    pj_status_t status;
    pj_thread_desc rtpdesc;
    pj_thread_t *thread = 0;
    
    if( !pj_thread_is_registered())
    {
        status = pj_thread_register(NULL,rtpdesc,&thread);
        
        if (status != PJ_SUCCESS) {
            error_exit("Error in  pj_thread_register", status);
            return YES;
        }
    }
    
    return NO;
}

//-(char *)cStringFromNSString:(NSString *)string {
//    if(!string) {
//        return nil;
//    }
//    
//    if(string.length == 0) {
//        return "";
//    }
//    
//    char *result = calloc([string length] + 1, 1);
//    //    char *result = [string cStringUsingEncoding:NSUTF8StringEncoding];
//    
//    [string getCString:result maxLength:[string length] + 1 encoding:NSUTF8StringEncoding];
//    
//    
//    return result;
//}


@end

//通话状态改变回调
/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(e);
    pjsua_call_get_info(call_id, &ci);
    NSString *state = [NSString stringWithFormat:@"%d",ci.state];
    [[NSNotificationCenter defaultCenter] postNotificationName:callStateChange object:state];
}

//来电回调
/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    //回复 接收到了
    pjsua_call_answer(call_id, 180, NULL, NULL);
    pjsua_call_info ci;
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    pjsua_call_get_info(call_id, &ci);
    
    char * uri=malloc(256);
    strcpy(uri, ci.buf_.local_info);
    strcat(uri,"|");
    strcat(uri, ci.buf_.remote_contact);
    NSString * str = [NSString stringWithFormat:@"%s",ci.buf_.remote_info];
    
    NSArray * array=[str componentsSeparatedByString:@"@"];
    array = [array[0] componentsSeparatedByString:@":"];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            IncommingViewController *incomming = [[IncommingViewController alloc] initWithCode:array[1]];
            [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:incomming animated:YES completion:nil];
        });
        
    }else{
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"%@ 的来电!",array[1]];
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    
}

static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info)
{
    
}


static void on_reg_state(pjsua_acc_id acc_id)
{
    PJ_UNUSED_ARG(acc_id);
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }

}


static void error_exit(const char *title, pj_status_t status)
{
    pjsua_perror(THIS_FILE, title, status);
    exit(1);
}














