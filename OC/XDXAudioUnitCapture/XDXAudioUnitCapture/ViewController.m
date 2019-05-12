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
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[XDXAudioCaptureManager getInstance] startAudioCapture];
}

- (IBAction)startRecord:(id)sender {
    [[XDXAudioCaptureManager getInstance] startRecordFile];
}

- (IBAction)stopRecord:(id)sender {
    [[XDXAudioCaptureManager getInstance] stopRecordFile];
}

- (void)dealloc {
    [[XDXAudioCaptureManager getInstance] stopAudioCapture];
}

@end
