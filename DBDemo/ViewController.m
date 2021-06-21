//
//  ViewController.m
//  DBDemo
//
//  Created by 趙乐樂 on 2021/6/21.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

#import <UIKit/UIKit.h>

#import "DDSoundWaveView.h"

#import "UIView+LayoutMethods.h"

@interface ViewController ()

@property (nonatomic, strong) AVAudioRecorder *recorder;

@property (nonatomic, strong) NSTimer *levelTimer;

//录音音量计时器
@property (nonatomic, strong) NSTimer *recorderTimer;

@property (nonatomic, strong) UILabel *showDBLabel;

@property (nonatomic, strong) DDSoundWaveView *waveView;

@end

@implementation ViewController

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self.waveView setCt_size:CGSizeMake(SCREEN_WIDTH, 200)];
    [self.waveView centerXEqualToView:self.view];
    [self.waveView setCt_y:SCREEN_HEIGHT - self.view.safeAreaBottomGap - SCREEN_HEIGHT/2];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.showDBLabel];
    
    [self.view addSubview:self.waveView];
    
    /* 必须添加这句话，否则在模拟器可以，在真机上获取始终是0  */
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
      
        /* 不需要保存录音文件 */
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
      
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                nil];
          
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (self.recorder)
    {
        [self.recorder prepareToRecord];
        self.recorder.meteringEnabled = YES;
        [self.recorder record];
        //时间间隔长，显示数字
        self.levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(levelTimerCallback:) userInfo:nil repeats:YES];
        //时间间隔短，显示波浪
        self.recorderTimer = [NSTimer scheduledTimerWithTimeInterval:0.017f target:self selector:@selector(recorderVoiceChange) userInfo:nil repeats:YES];
    } else {
        NSLog(@"%@", [error description]);
    }
}

/* 该方法确实会随环境音量变化而变化，但具体分贝值是否准确暂时没有研究 */
- (void)levelTimerCallback:(NSTimer *)timer {
    
    [self.recorder updateMeters];
   
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [self.recorder averagePowerForChannel:0];
      
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
          
        level = powf(adjAmp, 1.0f / root);
    }
    
    /* level 范围[0 ~ 1], 转为[0 ~120] 之间 */
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"当前分贝===%.2f",level*120);
        [self.showDBLabel setText:[NSString stringWithFormat:@"当前分贝:%.2f", level*120]];
    });
}

- (void)recorderVoiceChange {
    
    double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    NSLog(@"波浪显示数据*120===%f",lowPassResults*120);
    NSLog(@"波浪显示数据===%f",lowPassResults);
    [self.waveView displayWave:lowPassResults];
}

- (UILabel *)showDBLabel {
    
    if (!_showDBLabel) {
        
        _showDBLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 100, 80, 200, 50)];
        _showDBLabel.textColor = [UIColor blackColor];
        _showDBLabel.textAlignment = NSTextAlignmentCenter;
        _showDBLabel.font = [UIFont fontWithName:@"Helvetica-Bold"size:20];
    }
    return _showDBLabel;
}

- (DDSoundWaveView *)waveView {
    
    if (!_waveView) {
        
        _waveView = [[DDSoundWaveView alloc] init];
    }
    return _waveView;
}

@end
