//
//  SocketRocketUtility.h
//  
//
//ddddd
//

#import <Foundation/Foundation.h>
typedef void(^myBlcok)(id success);
@protocol CTIBodyBackDelegate <NSObject>

@required

-(void)CTIdidReceiveMessage:(id)message;
-(void)CTIdidEventReleased;
-(void)CTIdidEventEstablished;
-(void)CTIdidErrorCode;
-(void)CTIdidEventRinging;
-(void)CTIdidEventDialing;

@optional
- (void)SocketOpenSuccess;

- (void)SocketCloseSuccess;

@end

@interface SocketRocketUtility : NSObject
@property (nonatomic,copy)  NSString * userName;
@property (nonatomic,copy)  NSString * CTIserver;
@property (nonatomic,copy)  NSString * CTIpassword;
@property (nonatomic,copy)  NSString * CTIName;
@property (nonatomic,strong) myBlcok block;
@property(nonatomic,weak)id<CTIBodyBackDelegate>   CTIBodyBackDelegate;

+(SocketRocketUtility *)instance;

/*
 *
 * @parmar
 */
-(void)startCTIOpen:(NSString*)userName CTIserver:(NSString*)CTIserver CTIName:(NSString*)CTIName CTIpassword:(NSString*)CTIpassword;
/*
 * 关闭CTi接口关闭socket
 */
-(void)CTIClose;

//登录
-(void)online;

//就绪
-(void)ready;

//未就绪
-(void)notReady;


// 登出
-(void)loginOut;

//boda
-(void)dialingPhoneNumber:(NSString*)phoneNumber;

// 答复
-(void)answer;

// 拒接
-(void)reject;

// 挂断
-(void)hangup;

//静音当前呼叫
-(void)muteCall;


//取消当前静音
-(void)unmuteCall;


-(void)hold;


-(void)retrieve;



-(void)SingleStepTransfer:(NSString* )phoneNumber;
-(void)InitiateTransfer:(NSString* )phoneNumber;
-(void)CompleteTransfer;



-(void)SingleStepConference:(NSString* )phoneNumber;
-(void)InitiateConference:(NSString *)phoneNumber;
-(void)CompleteConference;
-(void)socketOpen;
@end
