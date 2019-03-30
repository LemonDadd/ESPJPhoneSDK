//
//  ESPlayAudio.h
//  VPhone
//
//  Created by 赖长宽 on 2018/6/11.
//  Copyright © 2018年 changkuan.lai.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//播放声音的类,在需

@interface ESPlayAudio : NSObject

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;


-(void)initStartAudio;


-(void)playMusic;

-(void)pause;


-(void)stop;

//听筒模式
-(void)setAudioSession;
//扬声器模式
-(void)setAudioWaiFangSession;
@end
