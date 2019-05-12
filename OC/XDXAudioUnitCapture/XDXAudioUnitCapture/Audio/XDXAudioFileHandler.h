//
//  XDXAudioFileHandler.h
//  XDXAudioQueueRecordAndPlayback
//
//  Created by 小东邪 on 2019/5/3.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "XDXSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDXAudioFileHandler : NSObject
SingletonH

+ (instancetype)getInstance;

/**
 * Write audio data to file.
 */
- (void)writeFileWithInNumBytes:(UInt32)inNumBytes
                   ioNumPackets:(UInt32 )ioNumPackets
                       inBuffer:(const void *)inBuffer
                   inPacketDesc:(nullable const AudioStreamPacketDescription*)inPacketDesc;

#pragma mark - Audio Queue
/**
 * Start / Stop record By Audio Queue.
 */
-(void)startVoiceRecordByAudioQueue:(AudioQueueRef)audioQueue
                  isNeedMagicCookie:(BOOL)isNeedMagicCookie
                          audioDesc:(AudioStreamBasicDescription)audioDesc;

-(void)stopVoiceRecordByAudioQueue:(AudioQueueRef)audioQueue
                   needMagicCookie:(BOOL)isNeedMagicCookie;


/**
 * Start / Stop record By Audio Converter.
 */
-(void)startVoiceRecordByAudioUnitByAudioConverter:(nullable AudioConverterRef)audioConverter
                                   needMagicCookie:(BOOL)isNeedMagicCookie
                                         audioDesc:(AudioStreamBasicDescription)audioDesc;

-(void)stopVoiceRecordAudioConverter:(nullable AudioConverterRef)audioConverter
                     needMagicCookie:(BOOL)isNeedMagicCookie;
@end

NS_ASSUME_NONNULL_END
