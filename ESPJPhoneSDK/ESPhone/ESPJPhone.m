//
//  ESPJPhone.m
//  VPhone
//
//  Created by 赖长宽 on 2019/1/2.
//  Copyright © 2019年 changkuan.lai.com. All rights reserved.
//

#import "ESPJPhone.h"
#import "PJPhone.h"

@implementation ESPJPhone


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
 * @brief 初始化CTI接口
 * @param registerSip - 是否注册直接注册分机
 * @param dnNumber - 分机号码
 * @param dnPassword - 分机密码
 * @param ctiUrl - ctiUrl
 * @param sipServerUrl - sipServer服务器地址
 */
-(BOOL)ESClientCTIInit:(BOOL)registerSip ctiUrl:(NSString*)ctiUrl sipServerUrl:(NSString*)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword {
    return [PJPhone sharedPJPhone];
}


/*
 * @brief 结束初始化接口
 */
-(void)ESClientDeInit {
    
}

/*
 * @brief 登入坐席接口
 */
-(void)ESClientOnline {
  
}


/*
 * @brief 登出坐席接口
 */
-(void)ESClientOffline {
    
    
}

/*
 * @brief 就绪
 */
-(void)ESClientReady {
    
}

/*
 * @brief 取消就绪
 */
-(void)ESClientnotReady {
    
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
  
}

/*
 * @brief 取回保持
 * @param connId - 呼叫标识
 */
-(void)ESClientRetriveCall:(NSString*)connId {
    
}

/*
 * @brief 取回保持
 * @param phoneNumber - 转接号码
 * @param connId - 呼叫标识
 */
-(void)ESClientReferCall:(NSString* )phoneNumber connId:(NSString*)connId {
    
}


/*
 * @brief 取回保持
 * @param phoneNumber - 邀请会议号码
 * @param connId - 呼叫标识
 */
-(void)ESClientConferenceCall:(NSString* )phoneNumber connId:(NSString*)connId {
    
}


@end
