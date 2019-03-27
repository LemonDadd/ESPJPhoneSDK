//
//  ESPJPhone.h
//  VPhone
//
//  Created by 赖长宽 on 2019/1/2.
//  Copyright © 2019年 changkuan.lai.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTIBodyBackDelegate <NSObject>

@required


//
-(void)CTIdidReceiveMessage:(id)message;


@optional
- (void)SocketOpenSuccess;

- (void)SocketCloseSuccess;

@end


@interface ESPJPhone : NSObject
@property(nonatomic,weak)id<CTIBodyBackDelegate>   CTIBodyBackDelegate;

/*
 * @brief 注册分机
 * @param sipServerUrl - sipServer服务器地址
 * @param dnNumber - 分机号码
 * @param dnPassword - 分机密码
 */
-(BOOL)ESClientRegister:(NSString *)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword;

/*
 * @brief 分机取消注册
 */
-(BOOL)ESClientUnRegister;

/*
 * @brief 初始化CTI接口
 * @param registerSip - 是否注册直接注册分机
 * @param dnNumber - 分机号码
 * @param dnPassword - 分机密码
 * @param ctiUrl - ctiUrl
 * @param sipServerUrl - sipServer服务器地址
 */
-(BOOL)ESClientCTIInit:(BOOL)registerSip ctiUrl:(NSString*)ctiUrl sipServerUrl:(NSString*)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword;


/*
 * @brief 结束初始化接口
 */
-(void)ESClientDeInit;

/*
 * @brief 登入坐席接口
 */
-(void)ESClientOnline;


/*
 * @brief 登出坐席接口
 */
-(void)ESClientOffline;

/*
 * @brief 就绪
 */
-(void)ESClientReady;

/*
 * @brief 取消就绪
 */
-(void)ESClientnotReady;

/*
 * @brief 拨打
 * @param phoneNumber - 呼叫的号码
 */
-(BOOL)ESClientMakeCall:(NSString*)phoneNumber;

/*
 * @brief 接听
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientAnswerCall:(NSString*)connId;

/*
 * @brief 挂断
 * @param connId - 呼叫标识
 */
-(BOOL)ESClientReleaseCall:(NSString*)connId;

/*
 * @brief 保持
 * @param connId - 呼叫标识
 */
-(void)ESClientHoldCall:(NSString*)connId;

/*
 * @brief 取回保持
 * @param connId - 呼叫标识
 */
-(void)ESClientRetriveCall:(NSString*)connId;

/*
 * @brief 取回保持
 * @param phoneNumber - 转接号码
 * @param connId - 呼叫标识
 */
-(void)ESClientReferCall:(NSString* )phoneNumber connId:(NSString*)connId;


/*
 * @brief 取回保持
 * @param phoneNumber - 邀请会议号码
 * @param connId - 呼叫标识
 */
-(void)ESClientConferenceCall:(NSString* )phoneNumber connId:(NSString*)connId;


@end

