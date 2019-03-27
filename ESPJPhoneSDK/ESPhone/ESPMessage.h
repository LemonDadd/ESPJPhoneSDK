//
//  ESPMessage.h
//  ESPJPhoneSDK
//
//  Created by 关云秀 on 2019/3/26.
//  Copyright © 2019 TestProject. All rights reserved.
//

#import <Foundation/Foundation.h>

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
@property (nonatomic, assign)NSInteger connId;

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

NS_ASSUME_NONNULL_END
