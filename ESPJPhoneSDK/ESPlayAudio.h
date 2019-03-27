//
//  ESPlayAudio.h
//  VPhone
//
//  Created by 赖长宽 on 2018/6/11.
//  Copyright © 2018年 changkuan.lai.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface ESPlayAudio : NSObject
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;


-(void)initStartAudio;


-(void)playMusic;

-(void)pause;


-(void)stop;

-(void)setAudioSession;

-(void)setAudioWaiFangSession;
@end
