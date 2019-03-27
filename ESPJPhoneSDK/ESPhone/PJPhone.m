//
//  PJPhone.m
//  test1111
//
//  Created by 赖长宽 on 2017/9/8.
//  Copyright © 2017年 ZYY. All rights reserved.
//

#import "PJPhone.h"
#import <pjsua-lib/pjsua.h>
#define THIS_FILE	"pjsua_app.c"
#import "ESPlayAudio.h"

// 来电冲突：CoreTelephony框架监听

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state(pjsua_acc_id acc_id);

static void on_call_tsx_state(pjsua_call_id call_id,
                          pjsip_transaction *tsx,
                          pjsip_event *e);
static  void on_log_tx(int level, const char *data, int len);


@interface PJPhone ()
{
    pjsua_conf_port_id pjsipConfAudioId;
    pjsua_acc_id _acc_id;
}
@property (nonatomic,assign) int callId;

@property (nonatomic,assign) int acct_id;

@property (nonatomic,assign) BOOL iscall;

@property (nonatomic,copy) NSString * server_uri;

@property (nonatomic,strong) ESPlayAudio * play;



@end

@implementation PJPhone
static  PJPhone  *_pJ;

-(ESPlayAudio *)play
{
    if (!_play) {
        _play=[[ESPlayAudio alloc]init];
        [_play initStartAudio];
        [_play setAudioSession];

    }
    return _play;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    @synchronized (self) {
        dispatch_once(&onceToken, ^{
            
            _pJ = [super allocWithZone:zone];
        });
    }
    
    return _pJ;
}

+ (instancetype _Nonnull)sharedPJPhone
{
    
    return _pJ = [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone
{
    return _pJ;
}
- (id)mutableCopyWithZone:(NSZone *)zone
{
    return _pJ;
}

-(BOOL)deleteAcc
{
    pj_status_t status;
    status =pjsua_acc_del(_acc_id);
    
    return status;
}

-(BOOL)startpjsua
{
    pj_status_t status;
    // 创建SUA
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        NSLog(@"error create pjsua");
        return NO;
    }
    {
      
        // SUA相关配置
        pjsua_config cfg;
        pjsua_media_config media_cfg;
        pjsua_logging_config log_cfg;
        
        pjsua_config_default(&cfg);
        
        // 回调函数配置
        cfg.cb.on_incoming_call = &on_incoming_call; // 来电回调
        cfg.cb.on_call_media_state = &on_call_media_state; // 媒体状态回调（通话建立后，要播放RTP流）
        cfg.cb.on_call_state = &on_call_state; // 电话状态回调
        cfg.cb.on_reg_state = &on_reg_state; // 注册状态回调
        cfg.cb.on_call_tsx_state=&on_call_tsx_state;
        // 媒体相关配置
        pjsua_media_config_default(&media_cfg);
        media_cfg.clock_rate = 16000;
        media_cfg.snd_clock_rate = 16000;
        media_cfg.ec_tail_len = 0;
        pjsua_logging_config_default(&log_cfg);
        

        log_cfg.msg_logging = PJ_TRUE;
        log_cfg.console_level = 4;
        log_cfg.level = 5;
        log_cfg.cb=&on_log_tx;
        // 初始化PJSUA
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        if (status != PJ_SUCCESS) {
            NSLog(@"error init pjsua");
            return NO;
        }
    }
    
    {
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        // 传输类型配置
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"error add transport for pjsua");
            return NO;
        }
    }
   
    
    // 启动PJSUA
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"error start pjsua");
        return NO;
    }
  
    
    return YES;
}
static void on_log_tx(int level, const char *data, int len)
{
    
    NSLog(@"char %s",data);
    
}
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    pjsua_call_info cif;
    pjsua_call_get_info(call_id, &cif);

    NSString *remote_info = [NSString stringWithUTF8String:cif.remote_info.ptr];
    
    NSUInteger startIndex = [remote_info rangeOfString:@"<"].location;
    NSUInteger endIndex = [remote_info rangeOfString:@">"].location;

    NSArray *array = [remote_info componentsSeparatedByString:@"\""]; //从字符A中分隔成2个元素的数组

    NSString *remote_address = [remote_info substringWithRange:NSMakeRange(startIndex , endIndex - startIndex )];
    NSString * remote_infoStr = [remote_info componentsSeparatedByString:@":"][1];
    
    remote_address =[remote_infoStr componentsSeparatedByString:@"@"][0];
    id argument = @{
                    @"call_id":@(call_id),
                    @"remote_address":array.count>=3?array[1]:remote_address
                    };
    NSLog(@"---%@————on_incoming_call",argument);

    [_pJ ringing:call_id];
    _pJ.callId=call_id;
    [_pJ.play playMusic];
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPIncomingCallNotification" object:nil userInfo:argument];
        });
    
    
    
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *event) {
    
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    PJ_UNUSED_ARG(event);
//    if (ci.state==PJSIP_INV_STATE_CALLING) return ;

//    int callType=0;
    int errorcode=0;
    NSString * messageName=@"";
    NSString * errorMessage=@"";

    _pJ.callId=call_id;
    NSString *FromStr=[NSString  stringWithFormat:@"%s",ci.local_info.ptr];
    NSString *ToStr  =[NSString  stringWithFormat:@"%s",ci.remote_info.ptr];
    switch (ci.last_status) {
            
        case PJSIP_SC_RINGING:
//             EventRinging：进线振铃事件

            if (ci.state==PJSIP_INV_STATE_EARLY) {

                NSLog(@"EventRinging：进线振铃事");
                messageName=@"EventRinging";

            }
            break;
        case PJSIP_SC_REQUEST_TERMINATED:
            if (ci.state==PJSIP_INV_STATE_DISCONNECTED) {

                NSLog(@"EventReleased：通话被放弃");
                messageName=@"EventReleased";
                [_pJ.play stop];

            }
            break;
            //                EventReleased：通话挂断事件
        case PJSIP_SC_DECLINE:
            if (ci.state==PJSIP_INV_STATE_DISCONNECTED) {
                
                NSLog(@"EventReleased：通话挂断事件");
                messageName=@"EventReleased";
                [_pJ.play stop];

            }
            break;
     
        case PJSIP_SC_OK:
            
            if (ci.state==PJSIP_INV_STATE_CONFIRMED) {
                
                NSLog(@"EventEstablished：通话接通事件");
                messageName=@"EventEstablished";
                [_pJ.play stop];
            }else if (ci.state==PJSIP_INV_STATE_DISCONNECTED)
            {
                NSLog(@"EventReleased：通话挂断事件");
                messageName=@"EventReleased";
                [_pJ.play stop];
            }
            
            break;
         
        default:
            break;
    }
    if (ci.last_status>=400&&ci.last_status<600&&ci.last_status!=487) {
        
        errorcode=(int)ci.last_status;
        errorMessage=[NSString stringWithFormat:@"%s",ci.last_status_text.ptr];
        
        
    }
    
    if (ci.state == PJSIP_INV_STATE_EARLY) {
        // pj_str_t is a struct with NOT null-terminated string.
        pj_str_t reason;
        pjsip_msg *msg;
        int code;
        
        // This can only occur because of TX or RX message.
        pj_assert(event->type == PJSIP_EVENT_TSX_STATE);
        
        if (event->body.tsx_state.type == PJSIP_EVENT_RX_MSG) {
            msg = event->body.tsx_state.src.rdata->msg_info.msg;
        } else {
            msg = event->body.tsx_state.src.tdata->msg;
        }
        
        code = msg->line.status.code;
        reason = msg->line.status.reason;
        
        
        // Start ringback for 180 for UAC unless there's SDP in 180.
        if (ci.role == PJSIP_ROLE_UAC &&
            code == 180 &&
            msg->body == NULL &&
            ci.media_status == PJSUA_CALL_MEDIA_NONE) {
        }
        
        PJ_LOG(3, (THIS_FILE, "Call %d state changed to %s (%d %.*s)",
                   call_id, ci.state_text.ptr,
                   code, (int)reason.slen, reason.ptr));
    } else {
        PJ_LOG(3, (THIS_FILE, "Call %d state changed to %s", call_id, ci.state_text.ptr));
    }
    
    id argument = @{
                    @"call_id":@(call_id),
                    @"state":@(ci.state),
                    @"pjsipConfAudioId":@(ci.conf_slot),
                    @"last_status":@(ci.last_status),
                    @"state_text":[NSString  stringWithFormat:@"%s",ci.state_text.ptr],
                    @"From":[NSString  stringWithFormat:@"%s",ci.remote_info.ptr],
                    @"to":[NSString  stringWithFormat:@"%s",ci.local_info.ptr]
                    };
    
 
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary*       dict=@{
                        @"messageName":messageName,
                        @"From":FromStr,
                        @"To":ToStr,
                        @"errorCode":@(errorcode),
                        @"errorMessage":errorMessage,
                        @"call_id":@(call_id)
                        };
        
        NSLog(@"------%@ --%@",dict,argument);

        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onEventMessageHandler" object:nil userInfo:dict];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
    });
}

static pjsua_call_info ciB;

static void on_call_media_state(pjsua_call_id call_id) {
    pjsua_call_info ciA;
    pjsua_call_get_info(call_id, &ciA);

  //判断是否是会议呼叫
    if (_pJ.isConferenceCall) {
        if (ciA.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
            pjsua_conf_connect(ciA.conf_slot, 0);
            pjsua_conf_connect(0, ciA.conf_slot);
            
        pjsua_conf_connect(ciB.conf_slot, ciA.conf_slot);
        pjsua_conf_connect(ciA.conf_slot, ciB.conf_slot);
       
        }
    }else{
        if (ciA.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
            pjsua_conf_connect(ciA.conf_slot, 0);
            pjsua_conf_connect(0, ciA.conf_slot);
            ciB=ciA;
        }
    }
  
    
   
    
    
}

static void on_reg_state(pjsua_acc_id acc_id ) {
    PJ_UNUSED_ARG(acc_id);

    pj_status_t status;
    pjsua_acc_info accinfo;

    status = pjsua_acc_get_info(acc_id, &accinfo);
    
    if (status != PJ_SUCCESS) {


        return;
    }
    _pJ.acct_id=acc_id;
   

    id argument = @{
                                        @"acc_id":@(acc_id),
                                        @"status_text":[NSString stringWithUTF8String:accinfo.status_text.ptr],
                                        @"status":@(accinfo.status)
                                        };

    NSLog(@"分机注册成功%@",argument);
  
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPRegisterStatusNotification" object:nil userInfo:argument];
    });
}

-(BOOL)ESClientAnswerCall:(NSInteger)callid
{
    pj_status_t status;

   status= pjsua_call_answer((pjsua_call_id)callid, 200, NULL, NULL);
    
    if (status != PJ_SUCCESS) return NO;

    return YES;
}
-(void)ringing:(NSInteger)callid
{

        pjsua_call_answer((pjsua_call_id)callid, 180, NULL, NULL);

}
-(BOOL)ESClientReleaseCall:(NSInteger)callid
{
    pj_status_t status;


   status= pjsua_call_hangup((pjsua_call_id)callid, 0, NULL, NULL);
    
    if (status != PJ_SUCCESS) return NO;
    return YES;
}
-(BOOL)ESClientMakeCall:(NSString *)phoneNumber
{
    if (phoneNumber) {
        
        NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@", phoneNumber, _server_uri];
        
        pj_status_t status;
        pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
        
        status = pjsua_call_make_call(_acct_id, &dest_uri, 0, NULL, NULL, &_callId);
        
        if (status != PJ_SUCCESS) {
            char  errMessage[PJ_ERR_MSG_SIZE];
            pj_strerror(status, errMessage, sizeof(errMessage));
            NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
            return NO;
        }

        
    }

    return YES;

}

-(BOOL)ESClientRegister:(NSString *)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword
{
    
    NSLog(@"000%@",sipServerUrl);
    if (!sipServerUrl) return NO;
    
    if (!dnPassword) {
        
        dnPassword=@"";
    }
    
    if (pjsua_acc_get_count() > 0)
    {
        _acc_id=  [self unregisterAccount];
    }
    pjsua_acc_id acc_id;
    pjsua_acc_config cfg;
    
    // 调用这个函数来初始化帐户配置与默认值
    pjsua_acc_config_default(&cfg);
    cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", dnNumber, sipServerUrl].UTF8String);
    // 这是URL放在请求URI的注册，看起来就像“SIP服务提供商”。如果需要注册，则应指定此字段。如果价值是空的，没有帐户注册将被执行。
    cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", sipServerUrl].UTF8String);
    // 在注册失败时指定自动注册重试的时间间隔,0禁用自动重新注册
//    cfg.reg_retry_interval = 0;
    cfg.cred_count = 1;
    // 凭证数组。如果需要注册，通常至少应该有一个凭据指定，成功地对服务提供程序进行身份验证。可以指定更多的凭据，例如，当请求被期望在路由集中的代理受到挑战时。
    cfg.cred_info[0].realm = pj_str("*");
    cfg.cred_info[0].username = pj_str((char *)dnNumber.UTF8String);
    cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    cfg.cred_info[0].data = pj_str((char *)dnPassword.UTF8String);
    
    pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
    if (status != PJ_SUCCESS) {
        NSString *errorMessage = [NSString stringWithFormat:@"登录失败，返回错误号：%d!", status];
        NSLog(@"register error: %@", errorMessage);
    }
    
    self.server_uri=sipServerUrl;

    
//    pjmedia_codec_param param;
//    pjmedia_codec_opus_config opus_cfg;
//    pjmedia_codec_mgr mgr;
//    const pjmedia_codec_info info;
//    pjmedia_codec_mgr_get_default_param(NULL,NULL, &param);
//    pjmedia_codec_opus_get_config(&opus_cfg);
//    //设置VAD
//    param.setting.vad = 1;
//    //设置PLC
//    param.setting.vad = 1;
//    //设置采样率
//    opus_cfg.sample_rate = 16000;
//    //设置频道数
//    opus_cfg.channel_cnt = 2;
//    //设置比特率
//    opus_cfg.bit_rate = 20000;
//    pjmedia_codec_opus_set_default_param(&opus_cfg, &param);

    return YES;
}
- (pjsua_acc_id)unregisterAccount
{
    pjsua_acc_id accountId;
    
    
    @synchronized(self)
    {
        pj_status_t status;
        unsigned    count;
        
        //        [self registerThread];
        
        count = pjsua_acc_get_count();
        
        if (count > 0)
        {
            pjsua_acc_info* info = calloc(count, sizeof(pjsua_acc_info));
            
            for (int n = 0; n < count; n++)
            {
                status = pjsua_acc_enum_info(info, &count);
                
                if (status == PJ_SUCCESS)
                {
                    status = pjsua_acc_del(info[n].id);
                    if (status != PJ_SUCCESS)
                    {
                        NSLog(@"Unregister unsuccessful");
                    }
                }
            }
            
            free(info);
        }
        
        return  accountId = -1;
    }
}
-(BOOL)ESClientUnRegister
{

  pj_status_t status =  pjsua_destroy();
    if(status != PJ_SUCCESS) return NO;
    
    return YES;
}




static void on_call_tsx_state(pjsua_call_id call_id,
                              pjsip_transaction *tsx,
                              pjsip_event *e)
{

    NSLog(@" - %s -  " ,tsx->transaction_key.ptr);
    
    const pjsip_method info_method =
    {
        PJSIP_OTHER_METHOD,
        { "INFO", 4 }
    };
    
    if (pjsip_method_cmp(&tsx->method, &info_method)==0) {
        /*
         * Handle INFO method.
         */
        const pj_str_t STR_APPLICATION = { "application", 11};
        const pj_str_t STR_DTMF_RELAY  = { "dtmf-relay", 10 };
        pjsip_msg_body *body = NULL;
        pj_bool_t dtmf_info = PJ_FALSE;
        
        if (tsx->role == PJSIP_ROLE_UAC) {
            if (e->body.tsx_state.type == PJSIP_EVENT_TX_MSG)
                body = e->body.tsx_state.src.tdata->msg->body;
            else
                body = e->body.tsx_state.tsx->last_tx->msg->body;
        } else {
            if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG)
                body = e->body.tsx_state.src.rdata->msg_info.msg->body;
        }
        
        /* Check DTMF content in the INFO message */
        if (body && body->len &&
            pj_stricmp(&body->content_type.type, &STR_APPLICATION)==0 &&
            pj_stricmp(&body->content_type.subtype, &STR_DTMF_RELAY)==0)
        {
            dtmf_info = PJ_TRUE;
            
        }
        
        if (dtmf_info && tsx->role == PJSIP_ROLE_UAC &&
            (tsx->state == PJSIP_TSX_STATE_COMPLETED ||
             (tsx->state == PJSIP_TSX_STATE_TERMINATED &&
              e->body.tsx_state.prev_state != PJSIP_TSX_STATE_COMPLETED)))
        {
            /* Status of outgoing INFO request */
            if (tsx->status_code >= 200 && tsx->status_code < 300) {
                PJ_LOG(4,(THIS_FILE,
                          "Call %d: DTMF sent successfully with INFO",
                          call_id));
            } else if (tsx->status_code >= 300) {
                PJ_LOG(4,(THIS_FILE,
                          "Call %d: Failed to send DTMF with INFO: %d/%.*s",
                          call_id,
                          tsx->status_code,
                          (int)tsx->status_text.slen,
                          tsx->status_text.ptr));
            }
        } else if (dtmf_info && tsx->role == PJSIP_ROLE_UAS &&
                   tsx->state == PJSIP_TSX_STATE_TRYING)
        {
            /* Answer incoming INFO with 200/OK */
            pjsip_rx_data *rdata;
            pjsip_tx_data *tdata;
            pj_status_t status;
            
            rdata = e->body.tsx_state.src.rdata;
            
            if (rdata->msg_info.msg->body) {
                status = pjsip_endpt_create_response(tsx->endpt, rdata,
                                                     200, NULL, &tdata);
                if (status == PJ_SUCCESS)
                    status = pjsip_tsx_send_msg(tsx, tdata);
                
                PJ_LOG(3,(THIS_FILE, "Call %d: incoming INFO:\n%.*s",
                          call_id,
                          (int)rdata->msg_info.msg->body->len,
                          rdata->msg_info.msg->body->data));
            } else {
                status = pjsip_endpt_create_response(tsx->endpt, rdata,
                                                     400, NULL, &tdata);
                if (status == PJ_SUCCESS)
                    status = pjsip_tsx_send_msg(tsx, tdata);
            }
        }
    }
}




-(void)sdfasd:(char * )str
{
    
    pjsua_call_id        current_call = 0;
    
    char * cc="sip:7007@192.168.0.201:5060";
    
   pj_str_t pjstr= pj_str(cc);
    
    pj_status_t  status =   pjsua_call_xfer(current_call , &pjstr, NULL);
    if (status!=PJ_SUCCESS) {
        
        NSLog(@"这个呼叫转接错误了");
    }else{
        
        NSLog(@"这个呼叫转接成功了");

        
    }
    
}



-(void)setCallHold:(NSInteger )callId
{
    pjsua_call_set_hold((pjsua_call_id)callId, NULL);
    
}
-(void)setUhold:(NSInteger )callid
{
    
   pj_status_t staus = pjsua_call_reinvite((pjsua_call_id)callid, PJ_TRUE, NULL);
    
}
-(void)calltransfer:(NSInteger)callid dnNumber:(NSString*)dnNumber
{
    NSLog(@"callidcallid%@",dnNumber);
    pj_str_t tttt = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", dnNumber, self.server_uri].UTF8String);
    
    pjsua_call_xfer((pjsua_call_id)callid, &tttt, NULL);
    
}
-(void)sendR:(NSInteger)callid requestMessage:(NSString*)requestMessage
{
    pj_str_t tttt = pj_str((char *)requestMessage.UTF8String);
    pjsua_call_send_request((pjsua_call_id)callid,&tttt , NULL);
}

-(void)setnodev {

    pjsua_set_no_snd_dev();
    
}
-(void)setsedDev
{
    int  capture_dev,playback_dev;
    pjsua_get_snd_dev(&capture_dev, &playback_dev);
    pjsua_set_snd_dev(capture_dev, playback_dev);
}

@end
