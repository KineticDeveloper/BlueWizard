#import "SpeechSynthesizer.h"
#import "TMS5220Processor.h"
#import "Sampler.h"

@interface SpeechSynthesizer ()

@property (nonatomic, strong) NSDictionary *speechTable;
@property (nonatomic, weak) Sampler *sampler;
@property (nonatomic) NSUInteger sampleRate;

@end

@implementation SpeechSynthesizer

-(instancetype)initWithSampleRate:(NSUInteger)sampleRate sampler:(Sampler *)sampler {
    if (self = [super init]) {
        self.sampleRate = sampleRate;
        self.sampler    = sampler;
        [self loadLPC];
    }
    return self;
}

-(void)speak:(NSString *)speechID {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        TMS5220Processor *processor = [[TMS5220Processor alloc] initWithSampleRate:weakSelf.sampleRate];
 
        NSArray *samples = [processor processLPC:[weakSelf speechDataWithStartAndStopCommandsFor:speechID]];
        
        [weakSelf.sampler stream:samples sampleRate:weakSelf.sampleRate];
    });
}

-(void)stop {
    [self.sampler stop];
}

-(NSArray *)speechDataWithStartAndStopCommandsFor:(NSString *)speechID {
    NSMutableArray *speechData = [[self.speechTable objectForKey:speechID] mutableCopy];
    NSAssert(speechData, ([NSString stringWithFormat:@"Speech data for key not found!", speechID]));
    [speechData insertObject:@0x60 atIndex:0];
    for (int i = 0; i < 16; i++) {
        [speechData addObject:@0xff];
    }
    
    return [speechData copy];
}

-(void)loadLPC {
    NSArray *files = [[NSBundle mainBundle] pathsForResourcesOfType:@"lpc"
                                                        inDirectory:nil];
    NSMutableDictionary *speechTable = [NSMutableDictionary dictionaryWithCapacity:[files count]];
    for (NSString *file in files) {
        NSData *myData = [NSData dataWithContentsOfFile:file];
        NSString *string = [[NSString alloc] initWithData:myData encoding:NSUTF8StringEncoding];
        NSMutableArray *lpc = [NSMutableArray arrayWithCapacity:[string length]];
        for (NSString *hexString in [string componentsSeparatedByString:@","]) {
            NSScanner *scanner = [NSScanner scannerWithString:hexString];
            unsigned int hex;
            [scanner scanHexInt: &hex];
            [lpc addObject:[NSNumber numberWithUnsignedInteger:hex]];
        }
        NSString *key = [[file componentsSeparatedByString:@"/"] lastObject];
        key           = [[[key componentsSeparatedByString:@"."] firstObject] lowercaseString];
        [speechTable setObject:[lpc copy] forKey:key];
    }
    self.speechTable = [speechTable copy];
}

-(float *)samplesAsFloats:(NSArray *)samples {
    NSUInteger numberOfSamples = [samples count];
    float *buffer;
    buffer = (float *)malloc(numberOfSamples * sizeof(float));
    for (int i = 0; i < numberOfSamples; i++) {
        float sample = (float)[[samples objectAtIndex:i] intValue] / (1 << 16);
        buffer[i]    = sample;
    }
    return buffer;
}

@end