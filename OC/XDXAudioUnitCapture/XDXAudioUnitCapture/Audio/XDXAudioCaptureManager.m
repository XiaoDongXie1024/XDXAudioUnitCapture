//
//  XDXAudioCaptureManager.m
//  XDXAudioUnitCapture
//
//  Created by 小东邪 on 2019/5/10.
//  Copyright © 2019 小东邪. All rights reserved.
//

#import "XDXAudioCaptureManager.h"
#import <AudioToolbox/AudioToolbox.h>

#define kXDXAudioPCMFramesPerPacket 1
#define KXDXAudioBitsPerChannel 16

#define INPUT_BUS  1      ///< A I/O unit's bus 1 connects to input hardware (microphone).
#define OUTPUT_BUS 0      ///< A I/O unit's bus 0 connects to output hardware (speaker).

const static NSString *kModuleName = @"XDXAudioCapture";

static AudioUnit                    m_audioUnit;
static AudioBufferList              *m_buffList;
static AudioStreamBasicDescription  m_audioDataFormat;

@interface XDXAudioCaptureManager ()

@property (nonatomic, assign, readwrite) BOOL isRunning;

@end

@implementation XDXAudioCaptureManager
SingletonM

static OSStatus AudioCaptureCallback(void                       *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp       *inTimeStamp,
                                     UInt32                     inBusNumber,
                                     UInt32                     inNumberFrames,
                                     AudioBufferList            *ioData) {
    AudioUnitRender(m_audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, m_buffList);
    
    XDXAudioCaptureManager *manager = (__bridge XDXAudioCaptureManager *)inRefCon;
    
    /*  Test audio fps
     static Float64 lastTime = 0;
     Float64 currentTime = CMTimeGetSeconds(CMClockMakeHostTimeFromSystemUnits(inTimeStamp->mHostTime))*1000;
     NSLog(@"Test duration - %f",currentTime - lastTime);
     lastTime = currentTime;
     */
    
    void    *bufferData = m_buffList->mBuffers[0].mData;
    UInt32   bufferSize = m_buffList->mBuffers[0].mDataByteSize;
    
    //    NSLog(@"demon = %d",bufferSize);
    
    struct XDXCaptureAudioData audioData = {
        .data           = bufferData,
        .size           = bufferSize,
        .inNumberFrames = inNumberFrames,
    };
    
    XDXCaptureAudioDataRef audioDataRef = &audioData;
    
    if ([manager.delegate respondsToSelector:@selector(receiveAudioDataByDevice:)]) {
        [manager.delegate receiveAudioDataByDevice:audioDataRef];
    }
        
    return noErr;
}

#pragma mark - Public
+ (instancetype)getInstance {
    return [[self alloc] init];
}

- (void)startAudioCapture {
    [self startAudioCaptureWithAudioUnit:m_audioUnit
                               isRunning:&_isRunning];
}

- (void)stopAudioCapture {
    [self stopAudioCaptureWithAudioUnit:m_audioUnit
                              isRunning:&_isRunning];
}

- (void)freeAudioUnit {
    [self freeAudioUnit:m_audioUnit];
    self.isRunning = NO;
}
- (AudioStreamBasicDescription)getAudioDataFormat {
    return m_audioDataFormat;
}

#pragma mark - Init
- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [super init];
        
        // Note: audioBufferSize couldn't more than durationSec max size.
        [_instace configureAudioInfoWithDataFormat:&m_audioDataFormat
                                          formatID:kAudioFormatLinearPCM
                                        sampleRate:44100
                                      channelCount:1
                                   audioBufferSize:2048
                                       durationSec:0.02
                                          callBack:AudioCaptureCallback];
    });
    return _instace;
}

#pragma mark - Private
- (void)configureAudioInfoWithDataFormat:(AudioStreamBasicDescription *)dataFormat formatID:(UInt32)formatID sampleRate:(Float64)sampleRate channelCount:(UInt32)channelCount audioBufferSize:(int)audioBufferSize durationSec:(float)durationSec callBack:(AURenderCallback)callBack {
    // Configure ASBD
    [self configureAudioToAudioFormat:dataFormat
                      byParamFormatID:formatID
                           sampleRate:sampleRate
                         channelCount:channelCount];
    
    // Set sample time
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:durationSec error:NULL];
    
    // Configure Audio Unit
    m_audioUnit = [self configreAudioUnitWithDataFormat:*dataFormat
                                        audioBufferSize:audioBufferSize
                                               callBack:callBack];
}

- (void)startAudioCaptureWithAudioUnit:(AudioUnit)audioUnit isRunning:(BOOL *)isRunning {
    OSStatus status;
    
    if (*isRunning) {
        NSLog(@"%@:  %s - start recorder repeat \n",kModuleName,__func__);
        return;
    }
    
    status = AudioOutputUnitStart(audioUnit);
    if (status == noErr) {
        *isRunning        = YES;
        NSLog(@"%@:  %s - start audio unit success \n",kModuleName,__func__);
    }else {
        *isRunning  = NO;
        NSLog(@"%@:  %s - start audio unit failed \n",kModuleName,__func__);
    }
}

-(void)stopAudioCaptureWithAudioUnit:(AudioUnit)audioUnit isRunning:(BOOL *)isRunning {
    if (*isRunning == NO) {
        NSLog(@"%@:  %s - stop capture repeat \n",kModuleName,__func__);
        return;
    }
    
    *isRunning = NO;
    if (audioUnit != NULL) {
        OSStatus status = AudioOutputUnitStop(audioUnit);
        if (status != noErr){
            NSLog(@"%@:  %s - stop audio unit failed. \n",kModuleName,__func__);
        }else {
            NSLog(@"%@:  %s - stop audio unit successful",kModuleName,__func__);
        }
    }
}

- (void)freeAudioUnit:(AudioUnit)audioUnit {
    if (!audioUnit) {
        NSLog(@"%@:  %s - repeat call!",kModuleName,__func__);
        return;
    }
    
    OSStatus result = AudioOutputUnitStop(audioUnit);
    if (result != noErr){
        NSLog(@"%@:  %s - stop audio unit failed.",kModuleName,__func__);
    }
    
    result = AudioUnitUninitialize(m_audioUnit);
    if (result != noErr) {
        NSLog(@"%@:  %s - uninitialize audio unit failed, status : %d",kModuleName,__func__,result);
    }
    
    // It will trigger audio route change repeatedly
    result = AudioComponentInstanceDispose(m_audioUnit);
    if (result != noErr) {
        NSLog(@"%@:  %s - dispose audio unit failed. status : %d",kModuleName,__func__,result);
    }else {
        audioUnit = nil;
    }
}

#pragma mark - Audio Unit
- (AudioUnit)configreAudioUnitWithDataFormat:(AudioStreamBasicDescription)dataFormat audioBufferSize:(int)audioBufferSize callBack:(AURenderCallback)callBack {
    AudioUnit audioUnit = [self createAudioUnitObject];
    
    if (!audioUnit) {
        return NULL;
    }
    
    [self initCaptureAudioBufferWithAudioUnit:audioUnit
                                 channelCount:dataFormat.mChannelsPerFrame
                                 dataByteSize:audioBufferSize];
    
    
    [self setAudioUnitPropertyWithAudioUnit:audioUnit
                                 dataFormat:dataFormat];
    
    [self initCaptureCallbackWithAudioUnit:audioUnit callBack:callBack];
    
    // Calls to AudioUnitInitialize() can fail if called back-to-back on different ADM instances. A fall-back solution is to allow multiple sequential calls with as small delay between each. This factor sets the max number of allowed initialization attempts.
    OSStatus status = AudioUnitInitialize(audioUnit);
    if (status != noErr) {
        NSLog(@"%@:  %s - couldn't init audio unit instance, status : %d \n",kModuleName,__func__,status);
    }
    
    return audioUnit;
}

- (AudioUnit)createAudioUnitObject {
    AudioUnit audioUnit;
    AudioComponentDescription audioDesc;
    audioDesc.componentType         = kAudioUnitType_Output;
    audioDesc.componentSubType      = kAudioUnitSubType_VoiceProcessingIO;//kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags        = 0;
    audioDesc.componentFlagsMask    = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    OSStatus status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (status != noErr)  {
        NSLog(@"%@:  %s - create audio unit failed, status : %d \n",kModuleName, __func__, status);
        return NULL;
    }else {
        return audioUnit;
    }
}

- (void)initCaptureAudioBufferWithAudioUnit:(AudioUnit)audioUnit channelCount:(int)channelCount dataByteSize:(int)dataByteSize {
    // Disable AU buffer allocation for the recorder, we allocate our own.
    UInt32 flag     = 0;
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_ShouldAllocateBuffer,
                                           kAudioUnitScope_Output,
                                           INPUT_BUS,
                                           &flag,
                                           sizeof(flag));
    if (status != noErr) {
        NSLog(@"%@:  %s - couldn't allocate buffer of callback, status : %d \n", kModuleName, __func__, status);
    }

    AudioBufferList * buffList = (AudioBufferList*)malloc(sizeof(AudioBufferList));
    buffList->mNumberBuffers               = 1;
    buffList->mBuffers[0].mNumberChannels  = channelCount;
    buffList->mBuffers[0].mDataByteSize    = dataByteSize;
    buffList->mBuffers[0].mData            = (UInt32 *)malloc(dataByteSize);
    m_buffList = buffList;
}


- (void)setAudioUnitPropertyWithAudioUnit:(AudioUnit)audioUnit dataFormat:(AudioStreamBasicDescription)dataFormat {
    OSStatus status;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  INPUT_BUS,
                                  &dataFormat,
                                  sizeof(dataFormat));
    if (status != noErr) {
        NSLog(@"%@:  %s - set audio unit stream format failed, status : %d \n",kModuleName, __func__,status);
    }
    
    /*
     // remove echo but can't effect by testing.
     UInt32 echoCancellation = 0;
     AudioUnitSetProperty(m_audioUnit,
     kAUVoiceIOProperty_BypassVoiceProcessing,
     kAudioUnitScope_Global,
     0,
     &echoCancellation,
     sizeof(echoCancellation));
     */
    
    UInt32 enableFlag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  INPUT_BUS,
                                  &enableFlag,
                                  sizeof(enableFlag));
    if (status != noErr) {
        NSLog(@"%@:  %s - could not enable input on AURemoteIO, status : %d \n",kModuleName, __func__, status);
    }
    
    UInt32 disableFlag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  OUTPUT_BUS,
                                  &disableFlag,
                                  sizeof(disableFlag));
    if (status != noErr) {
        NSLog(@"%@:  %s - could not enable output on AURemoteIO, status : %d \n",kModuleName, __func__,status);
    }
}

- (void)initCaptureCallbackWithAudioUnit:(AudioUnit)audioUnit callBack:(AURenderCallback)callBack {
    AURenderCallbackStruct captureCallback;
    captureCallback.inputProc        = callBack;
    captureCallback.inputProcRefCon  = (__bridge void *)self;
    OSStatus status                  = AudioUnitSetProperty(audioUnit,
                                                            kAudioOutputUnitProperty_SetInputCallback,
                                                            kAudioUnitScope_Global,
                                                            INPUT_BUS,
                                                            &captureCallback,
                                                            sizeof(captureCallback));
    
    if (status != noErr) {
        NSLog(@"%@:  %s - Audio Unit set capture callback failed, status : %d \n",kModuleName, __func__,status);
    }
}

#pragma mark - ASBD Audio Format
-(void)configureAudioToAudioFormat:(AudioStreamBasicDescription *)audioFormat byParamFormatID:(UInt32)formatID  sampleRate:(Float64)sampleRate channelCount:(UInt32)channelCount {
    AudioStreamBasicDescription dataFormat = {0};
    UInt32 size = sizeof(dataFormat.mSampleRate);
    // Get hardware origin sample rate. (Recommended it)
    Float64 hardwareSampleRate = 0;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                            &size,
                            &hardwareSampleRate);
    // Manual set sample rate
    dataFormat.mSampleRate = sampleRate;

    size = sizeof(dataFormat.mChannelsPerFrame);
    // Get hardware origin channels number. (Must refer to it)
    UInt32 hardwareNumberChannels = 0;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,
                            &size,
                            &hardwareNumberChannels);
    dataFormat.mChannelsPerFrame = channelCount;
    
    dataFormat.mFormatID = formatID;
    
    if (formatID == kAudioFormatLinearPCM) {
        dataFormat.mFormatFlags     = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        dataFormat.mBitsPerChannel  = KXDXAudioBitsPerChannel;
        dataFormat.mBytesPerPacket  = dataFormat.mBytesPerFrame = (dataFormat.mBitsPerChannel / 8) * dataFormat.mChannelsPerFrame;
        dataFormat.mFramesPerPacket = kXDXAudioPCMFramesPerPacket;
    }

    memcpy(audioFormat, &dataFormat, sizeof(dataFormat));
    NSLog(@"%@:  %s - sample rate:%f, channel count:%d",kModuleName, __func__,sampleRate,channelCount);
}

@end
