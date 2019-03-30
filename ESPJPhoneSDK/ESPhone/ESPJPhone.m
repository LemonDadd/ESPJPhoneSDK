//
//  ESPJPhone.m
//  VPhone
//
//  Created by 赖长宽 on 2019/1/2.
//  Copyright © 2019年 changkuan.lai.com. All rights reserved.
//

#import "ESPJPhone.h"
#import "PJPhone.h"
#import "SocketRocketUtility.h"
#import "SRWebSocket.h"
#import "ESPlayAudio.h"
#import <pjsua-lib/pjsua.h>

@interface ESPJPhone()

@property (nonatomic, assign) BOOL isCalling;//是否通话中

@end

@implementation ESPJPhone

static  ESPJPhone  *_espjPhone;

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    @synchronized (self) {
        dispatch_once(&onceToken, ^{
            
            _espjPhone = [super allocWithZone:zone];
        });
    }
    
    return _espjPhone;
}

+ (instancetype _Nonnull)sharedESPJPhone
{
    
    return _espjPhone = [[self alloc] init];
}


- (BOOL)startESPJSUA {
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onEventMessageChanged:) name:@"onEventMessageHandler" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ncomingCallNotification:) name:@"SIPIncomingCallNotification" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(callStatusChangedNotification:) name:@"SIPCallStatusChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onHandleRegisterStatus:) name:@"SIPRegisterStatusNotification" object:nil];
    
    return [[PJPhone sharedPJPhone]startpjsua];
}


- (void)onHandleRegisterStatus:(NSNotification *)notification {
    NSDictionary * dict= [notification userInfo];
    
    ESPRegisterMessage *message = [[ESPRegisterMessage alloc]init];
    message.acc_id = dict[@"acc_id"];
    message.status_text = dict[@"status_text"];
    message.status = [dict[@"status"] integerValue];
    
    if (_delegate && [_delegate respondsToSelector:@selector(onHandleRegisterStatus:)]) {
        [_delegate onHandleRegisterStatus:message];
    }
}

//消息的回调
- (void)onEventMessageChanged:(NSNotification *)notification {
    NSDictionary * dict= [notification userInfo];
    
    ESPMessage *message = [[ESPMessage alloc]init];
    message.messageName = dict[@"messageName"];
    message.connId = [dict[@"call_id"] intValue];
    message.ANI = dict[@"From"];
    message.DNIS = dict[@"to"];
    message.errorCode = dict[@"errorCode"];
    message.errorMessage = dict[@"errorMessage"];
    message.callType = 3;
    if (_delegate && [_delegate respondsToSelector:@selector(onEventMessageHandler:)]) {
        [_delegate onEventMessageHandler:message];
    }
}


- (void)ncomingCallNotification:(NSNotification *)notification {
    NSDictionary * dict= [notification userInfo];
    
    ESPMessage *message = [[ESPMessage alloc]init];
    message.connId = [dict[@"call_id"] intValue];
    message.ANI = dict[@"remote_address"];
    message.callType = 2;
    if (_delegate && [_delegate respondsToSelector:@selector(onEventMessageHandler:)]) {
        [_delegate onEventMessageHandler:message];
    }
}

- (void)callStatusChangedNotification:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    ESPCallStatusMessage *message = [[ESPCallStatusMessage alloc]init];
    message.call_id =[dict[@"call_id"] intValue];
    message.state =[dict[@"state"] integerValue];
    message.pjsipConfAudioId =[dict[@"pjsipConfAudioId"] integerValue];
    message.last_status =[dict[@"last_status"] integerValue];
    message.state_text =dict[@"state_text"];
    message.From =dict[@"From"];
    message.to =dict[@"to"];
    
    if (message.state == PJSIP_INV_STATE_DISCONNECTED) {
        pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
        pjsua_call_answer(call_id, 200, NULL, NULL);
    }
    if (_delegate && [_delegate respondsToSelector:@selector(onCallStatusChanged:)]) {
        [_delegate onCallStatusChanged:message];
    }
}

/*
 * @brief 注册分机
 * @param sipServerUrl - sipServer服务器地址
 * @param dnNumber - 分机号码
 * @param dnPassword - 分机密码
 */
-(BOOL)ESClientRegister:(NSString *)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword {
     return [[PJPhone sharedPJPhone]ESClientRegister:sipServerUrl dnNumber:dnNumber dnPassword:dnPassword];
}


/*
 * @brief 分机取消注册
 */
-(BOOL)ESClientUnRegister {
    return [[PJPhone sharedPJPhone] ESClientUnRegister];
}

/*
 * @brief 拨打
 * @param phoneNumber - 呼叫的号码
 */
-(BOOL)ESClientMakeCall:(NSString*)phoneNumber {
    return [[PJPhone sharedPJPhone]ESClientMakeCall:phoneNumber];
}

/*
 * @brief 接听
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientAnswerCall:(NSString*)connId {
    return [[PJPhone sharedPJPhone]ESClientAnswerCall:[connId integerValue]];
}

/*
 * @brief 挂断
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientReleaseCall:(NSString*)connId {
    return [[PJPhone sharedPJPhone]ESClientReleaseCall:[connId integerValue]];
}

/*
 * @brief 保持
 * @param connId - 呼叫标识
 */
-(void)ESClientHoldCall:(NSString*)connId {
    [[PJPhone sharedPJPhone]setCallHold:[connId integerValue]];
}

/*
 * @brief 取回保持
 * @param connId - 呼叫标识
 */
-(void)ESClientRetriveCall:(NSString*)connId {
    [[PJPhone sharedPJPhone]setUhold:[connId integerValue]];
}

/*
 * @brief 转接
 * @param phoneNumber - 转接号码
 * @param connId - 呼叫标识
 */
-(void)ESClientReferCall:(NSString* )phoneNumber connId:(NSString*)connId {
    [[PJPhone sharedPJPhone] calltransfer:[connId integerValue] dnNumber:phoneNumber];
}


/*
 * @brief 会议通话
 * @param phoneNumber - 邀请会议号码
 * @param connId - 呼叫标识
 */
-(void)ESClientConferenceCall:(NSString* )phoneNumber {
    BOOL ismakeCall=  [[PJPhone sharedPJPhone]ESClientMakeCall:phoneNumber];
    if (ismakeCall) self.isConferenceCall=YES;
}

/**
 挂断
 
 @param callid - 呼叫标识
 @param requestMessage - 结束语
 */
-(void)ESClientHangup:(NSInteger)callid requestMessage:(NSString*)requestMessage {
    if(self.isConferenceCall){
        [[SocketRocketUtility instance]hangup];
    }else{
        [[PJPhone sharedPJPhone]sendR:callid requestMessage:requestMessage];
    }
}

/**
 登出
 */
-(BOOL)ESClientLogOut {
    return [[PJPhone sharedPJPhone] deleteAcc];
}

-(void)setIsCalling:(BOOL)isCalling {
    _isCalling = isCalling;
    [PJPhone sharedPJPhone].isCalling = isCalling;
}

-(void)setIsConferenceCall:(BOOL)isConferenceCall {
    _isConferenceCall = isConferenceCall;
    [PJPhone sharedPJPhone].isConferenceCall = isConferenceCall;
}




@end
