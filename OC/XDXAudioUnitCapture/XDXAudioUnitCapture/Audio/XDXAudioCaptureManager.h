//
//  XDXAudioCaptureManager.h
//  XDXAudioUnitCapture
//
//  Created by 小东邪 on 2019/5/10.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDXSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDXAudioCaptureManager : NSObject
SingletonH

@property (nonatomic, assign, readonly) BOOL isRunning;

+ (instancetype)getInstance;
- (void)startAudioCapture;
- (void)stopAudioCapture;

- (void)stopRecordFile;
- (void)startRecordFile;
- (void)freeAudioUnit;

@end

NS_ASSUME_NONNULL_END
