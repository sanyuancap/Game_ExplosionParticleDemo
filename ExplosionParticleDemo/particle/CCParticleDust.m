#import "CCParticleDust.h"
#import "CCMath.h"

#pragma mark - CCParticleDustRise
@implementation CCParticleDustRise
-(id) init {
    if( (self=[self initWithFile:@"dustRise.plist"]) ) {
        self.startWidthScale = 0.2f;
        self.startWidthScaleVar = 0.2f;
        self.endWidthScale = 0.1f;
        
        self.startHeightScale = 0.2f;
        self.startHeightScaleVar = 0.1f;
        self.endHeightScale = 1.2f;
        self.endHeightScaleVar = 0.2f;
        
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSpeed:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    p->mode.A.speed = p->mode.A.orgSpeed * CC_LINEAR(-1.06f, 1.0f, elapsed);
}

@end

#pragma mark - CCParticleDustBurst
@implementation CCParticleDustBurst
-(id) init {
    if( (self=[self initWithFile:@"dustBurst.plist"]) ) {
        self.startWidthScale = 0.2f;
        self.startWidthScaleVar = 0.2f;
        self.endWidthScale = 0.2f;
        
        self.startHeightScale = 0.2f;
        self.startHeightScaleVar = 0.1f;
        self.endHeightScale = 1.2f;
        self.endHeightScaleVar = 0.3f;
        
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSpeed:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (p->elapsed <= 1.0f) {
        p->mode.A.speed = p->mode.A.orgSpeed * CC_LINEAR(-1.0f, 1.0f, elapsed);
    }
    else {
        p->mode.A.speed = 0.0f;
    }
}
@end

#pragma mark - CCParticleDustFlare
@implementation CCParticleDustFlare

-(id) init {
    if( (self=[self initWithFile:@"dustFlare.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    p->size = p->orgSize * CC_LINEAR(1.0f, -1.0f, p->elapsed);
}

-(void) updateParticleSpeed:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (p->elapsed <= 0.03) {
        p->mode.A.speed = p->mode.A.orgSpeed * CC_LINEAR(-1.0f, 0.45f, p->elapsed);
    }
    else if (p->elapsed <= 1.0f){
        p->mode.A.speed = p->mode.A.orgSpeed * CC_LINEAR(-0.34, 0.34, p->elapsed);
    }
    else {
        p->mode.A.speed = 0.0f;
    }
}

@end