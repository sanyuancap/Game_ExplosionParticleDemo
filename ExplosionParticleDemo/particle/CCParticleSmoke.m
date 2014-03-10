#import "CCParticleSmoke.h"
#import "CCMath.h"

#pragma mark - CCParticleToonCloud
@implementation CCParticleToonCloud
-(id) init {
    if( (self=[self initWithFile:@"toonCloud.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (elapsed <= 0.05) {
        p->size = p->orgSize * CC_QUADRATIC(1, elapsed, 19.35, 0);
    }
    else if (elapsed > 0.05 && elapsed <= 0.65) {
        p->size = p->orgSize * CC_LINEAR(0.05, elapsed, 0.9675);
    }
    else {
        p->size = p->orgSize * CC_LINEAR(-2.85, elapsed, 2.85);
    }
}

-(void) updateParticleSpeed:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    p->mode.A.speed = p->mode.A.orgSpeed * CC_LINEAR(-0.9f, 0.9f, elapsed);
}
@end


#pragma mark - CCParticleArmCloud
@implementation CCParticleArmCloud
-(id) init {
    if( (self=[self initWithFile:@"armCloud.plist"]) ) {
        self.startWidthScale = 0.0f;
        self.startWidthScaleVar = 0.3f;
        self.endWidthScale = 0.2f;
        
        self.startHeightScale = 0.0f;
        self.startHeightScaleVar = 0.2f;
        self.endHeightScale = 1.0f;
        self.endHeightScaleVar = 0.2f;
        
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleColor:(tCCParticle *)p elapsed:(float)elapse dt:(float)dt {
    if (elapsed <= 0.8f) {
        p->color.r = CC_LINEAR(-175, 255, elapsed) / 255.0f;
        p->color.g = CC_LINEAR(-70, 150, elapsed) / 255.0f;
        p->color.b = CC_LINEAR(-10, 90, elapsed) / 255.0f;
        p->color.a = 1.0f;
    }
    else {
        p->color.r = 80.0f / 255.0f;
        p->color.g = 80.0f / 255.0f;
        p->color.b = 80.0f / 255.0f;
        p->color.a = CC_LINEAR(-5, 5, elapsed);
    }
}
@end
