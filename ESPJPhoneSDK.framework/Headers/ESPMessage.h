//
//  ESPMessage.h
//  ESPJPhoneSDK
//
//  Created by 关云秀 on 2019/3/26.
//  Copyright © 2019 TestProject. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ESPJPhoneCallStatus) {
    ESPJPhoneCallStatus_NULL=0,           /**< 在发送或接收邀请之前*/
    ESPJPhoneCallStatus_CALLING,          /**< 发出邀请后*/
    ESPJPhoneCallStatus_INCOMING,         /**< 收到邀请后*/
    ESPJPhoneCallStatus_EARLY,            /**< 响应*/
    ESPJPhoneCallStatus_CONNECTING,       /**< 呼叫中*/
    ESPJPhoneCallStatus_CONFIRMED,        /**< 接通*/
    ESPJPhoneCallStatus_DISCONNECTED,     /**< 挂断*/
};

NS_ASSUME_NONNULL_BEGIN

@interface ESPMessage : NSObject

/**
 消息名称，此参数都是固定值，具体如下：
 EventRegistered：注册成功事件
 EventUnregistered：取消注册事件
 EventRinging：进线振铃事件
 EventDialing：呼出响铃事件
 EventEstablished：通话接通事件
 EventReleased：通话挂断事件
 EventError：错误事件
 */
@property (nonatomic, copy)NSString *messageName;


/**
 呼叫标识
 */
@property (nonatomic, assign)int connId;

/**
 主叫号码
 */
@property (nonatomic, copy)NSString *ANI;

/**
 被叫号码
 */
@property (nonatomic, copy)NSString *DNIS;

/**
 呼叫类型：
 2：是进线
 3：是呼出
 */
@property (nonatomic, assign)int  callType;

/**
 错误原因码
 */
@property (nonatomic, copy)NSString *errorCode;

/**
 错误原因
 */
@property (nonatomic, copy)NSString *errorMessage;


@end



@interface ESPRegisterMessage : NSObject

//注册后返回的对象模型  status=200 代表注册成功
//status_text 错误信息

@property (nonatomic, copy)NSString *acc_id;
@property (nonatomic, copy)NSString *status_text;
@property (nonatomic, assign)NSInteger status;

@end


@interface ESPCallStatusMessage : NSObject

@property (nonatomic, assign)ESPJPhoneCallStatus  state; //呼叫状态
@property (nonatomic, assign)int call_id;
@property (nonatomic, assign)NSInteger pjsipConfAudioId;     //第一个音频流的会议端口号
@property (nonatomic, assign)NSInteger last_status;        // 最后听到的状态码，可以用作原因码
@property (nonatomic, copy)NSString *state_text;
@property (nonatomic, copy)NSString *From;
@property (nonatomic, copy)NSString *to;

@end

NS_ASSUME_NONNULL_END
