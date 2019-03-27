//
//  PJPhone.h
//  test1111
//
//  Created by 赖长宽 on 2017/9/8.
//  Copyright © 2017年 ZYY. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PJPhoneDelegate<NSObject>

@optional


@end

/**
 * This enumeration describes  session state.
 */
typedef enum sip_in_state
{
    SIP_IN_STATE_NULL=0,	    /**< Before INVITE is sent or received  */
    SIP_IN_STATE_REGISTERED,	    /**< REGISTERED		successful    */
    SIP_IN_STATE_RINGING,	    /**< After response with To tag.	    */
    SIP_IN_STATE_DIALING,	    /**< After response with To tag.	    */
    SIP_IN_STATE_CONFIRMED,	    /**< After ACK is sent/received.	    */
    SIP_IN_STATE_DISCONNECTED,   /**< Session is terminated. 		    */
} sip_in_state;

@interface PJPhone : NSObject
typedef void(^onEventMessageHandler)(NSDictionary* messageName,NSString*ANI,NSString*DNIS,int callType);

@property (nonatomic, copy) onEventMessageHandler  headlerblock;
@property (nonatomic, assign) BOOL isCTIlogin;
@property (nonatomic,assign) BOOL isConferenceCall;
@property (nonatomic, assign) BOOL isCalling;
+ (instancetype )sharedPJPhone;



// 开始
-(BOOL)startpjsua;

-(BOOL)ESClientUnRegister;

-(BOOL)ESClientAnswerCall:(NSInteger)callid;

-(void)ringing:(NSInteger)callid;

-(BOOL)ESClientReleaseCall:(NSInteger)callid;
-(BOOL)deleteAcc;

-(BOOL)ESClientMakeCall:(NSString *)phoneNumber;

-(void)sdfasd:(char * )str;


-(BOOL)ESClientRegister:(NSString *)sipServerUrl dnNumber:(NSString*)dnNumber dnPassword:(NSString*)dnPassword;
-(void)setUhold:(NSInteger )callid;
-(void)setCallHold:(NSInteger )callId;
-(void)calltransfer:(NSInteger)callid dnNumber:(NSString*)dnNumber;

-(void)sendR:(NSInteger)callid requestMessage:(NSString*)requestMessage;

-(BOOL)ESClientPJCompleteConferenceDnNumber:(NSString*)dnNumbe;

-(void)setnodev;
-(void)setsedDev;
@end

