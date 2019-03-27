//
//  ESPlayAudio.m
//  VPhone
//
//  Created by 赖长宽 on 2018/6/11.
//  Copyright © 2018年 changkuan.lai.com. All rights reserved.
//

#import "ESPlayAudio.h"




@implementation ESPlayAudio

-(void)initStartAudio
{
    
    // 1.加载本地的音乐文件
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"iphoneMP3.mp3" withExtension:nil];
    // 2. 创建音乐播放对象
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    // 3.准备播放 (音乐播放的内存空间的开辟等功能)  不写这行代码直接播放也会默认调用prepareToPlay
    [self.audioPlayer prepareToPlay];
    
}
-(void)playMusic
{
    [self.audioPlayer setNumberOfLoops:-1];

    BOOL isplay= [self.audioPlayer play];

    if (!isplay) {
        NSLog(@"音频无法播放");
    }
}
-(void)pause
{
    [self.audioPlayer pause];
}
-(void)stop
{
    [self.audioPlayer stop];
}

//听筒模式
-(void)setAudioSession{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}
//扬声器模式
-(void)setAudioWaiFangSession
{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
}


@end
