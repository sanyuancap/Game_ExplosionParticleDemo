#import "CCParticleGlow.h"
#import "CCMath.h"

#pragma mark - CCParticleCircleGlow
@implementation CCParticleCircleGlow
-(id) init
{
    if( (self=[self initWithFile:@"circleGlow.plist"]) ) {
	}
	return self;
}
@end

#pragma mark - CCParticleStarGlow
@implementation CCParticleStarGlow
-(id) init {
    if( (self=[self initWithFile:@"starGlow.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (elapsed <= 0.6) {
        p->size = p->orgSize * CC_LINEAR(1, 0.8f, elapsed);
    }
}

-(void) updateParticleColor:(tCCParticle *)p elapsed:(float)elapse dt:(float)dt {
    if (elapsed <= 0.03) {
        p->color.a = CC_LINEAR(3, 0, elapsed);
    }
    else {
        p->color.a = CC_LINEAR(-0.9f, 0.9f, elapsed);
    }
}
@end

#pragma mark - CCParticleFadeGlow
@implementation CCParticleFadeGlow
-(id) init {
    if( (self=[self initWithFile:@"fadeGlow.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (p->elapsed > 1.0f) {
        p->size = p->orgSize * CC_LINEAR(-1.0f, 2.0f, p->elapsed);
    }
}
@end

#pragma mark - CCParticleFlatGlow
@implementation CCParticleFlatGlow
-(id) init {
    if( (self=[self initWithFile:@"flatGlow.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleScale:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    // height scale
    if (p->elapsed <= 0.5f) {
        p->heightScale = 0.2f;
    }
    else {
        p->heightScale = CC_LINEAR(-0.4f, 0.4f, p->elapsed);
    }
    // width scale
    if (p->elapsed <= 0.8f) {
        p->widthScale = CC_LINEAR(12.5f, 0, p->elapsed);
    }
    else {
        p->widthScale = CC_LINEAR(80, -54, p->elapsed);
    }
}
@end

#pragma mark - CCParticleImplodingGlow
@implementation CCParticleImplodingGlow
-(id) init {
    if( (self=[self initWithFile:@"implodingGlow.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    if (p->elapsed <= 0.9) {
        p->size = p->orgSize * CC_LINEAR(2.25f, 0.0f, p->elapsed);
    }
    else {
        p->size = p->orgSize * CC_LINEAR(-4.0f, 4.0f, p->elapsed);
    }
}

-(void) updateParticleColor:(tCCParticle *)p elapsed:(float)elapse dt:(float)dt {
    if (p->elapsed <= 0.5) {
        p->color.a = 0.2f;
    }
    else {
        p->color.a = CC_LINEAR(2.0f, -1.0f, p->elapsed);
    }
}
@end

#pragma mark - CCParticleBlastWave
@implementation CCParticleBlastWave
-(id) init
{
    if( (self=[self initWithFile:@"blastWave.plist"]) ) {
        self.delegate = self;
	}
	return self;
}

-(void) updateParticleSize:(tCCParticle *)p elapsed:(float)e dt:(float)dt {
    p->size = p->orgSize * CC_LINEAR(1.0f, 0.0f, p->elapsed);
}
@end
