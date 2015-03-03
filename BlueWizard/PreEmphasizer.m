#import "PreEmphasizer.h"
#import "Buffer.h"

@implementation PreEmphasizer

+(void)processBuffer:(Buffer *)buffer {
    float preEnergy = [buffer energy];

    float alpha = [self alpha];
    for (int i = 1; i < buffer.size; i++) {
        buffer.samples[i] += buffer.samples[i - 1] * alpha;
    }
    
    [self scaleBuffer:buffer preEnergy:preEnergy postEnergy:[buffer energy]];
}

+(float)alpha {
    return 0.9f;
}

+(void)scaleBuffer:(Buffer *)buffer preEnergy:(float)preEnergy postEnergy:(float)postEnergy {
    float scale = sqrt(preEnergy / postEnergy);
    
    for (int i = 1; i < buffer.size; i++) {
        buffer.samples[i] *= scale;
    }
}

@end