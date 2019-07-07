//
//  ViewController.m
//  XDXAudioUnitCapture
//
//  Created by 小东邪 on 2019/5/10.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import "ViewController.h"
#import "XDXAudioCaptureManager.h"
#import <AVFoundation/AVFoundation.h>
#import "XDXAudioFileHandler.h"

@interface ViewController ()<XDXAudioCaptureDelegate>

@property (nonatomic, assign) BOOL isRecordVoice;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [XDXAudioCaptureManager getInstance].delegate = self;
    [[XDXAudioCaptureManager getInstance] startAudioCapture];
}

- (IBAction)startRecord:(id)sender {
    [self startRecordFile];
}

- (IBAction)stopRecord:(id)sender {
    [self stopRecordFile];
}

- (void)dealloc {
    [[XDXAudioCaptureManager getInstance] stopAudioCapture];
}
#pragma mark - Record
- (void)startRecordFile {
    AudioStreamBasicDescription audioFormat = [[XDXAudioCaptureManager getInstance] getAudioDataFormat];
    [[XDXAudioFileHandler getInstance] startVoiceRecordByAudioUnitByAudioConverter:nil
                                                                   needMagicCookie:NO
                                                                         audioDesc:audioFormat];
    self.isRecordVoice = YES;
}

- (void)stopRecordFile {
    self.isRecordVoice = NO;
    [[XDXAudioFileHandler getInstance] stopVoiceRecordAudioConverter:nil
                                                     needMagicCookie:NO];
}
#pragma mark - Delegate
- (void)receiveAudioDataByDevice:(XDXCaptureAudioDataRef)audioDataRef {
    if (self.isRecordVoice) {
        [[XDXAudioFileHandler getInstance] writeFileWithInNumBytes:audioDataRef->size
                                                      ioNumPackets:audioDataRef->inNumberFrames
                                                          inBuffer:audioDataRef->data
                                                      inPacketDesc:NULL];
    }
    
}

@end
