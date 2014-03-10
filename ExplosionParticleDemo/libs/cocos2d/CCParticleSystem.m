/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


// ideas taken from:
//	 . The ocean spray in your face [Jeff Lander]
//		http://www.double.co.nz/dust/col0798.pdf
//	 . Building an Advanced Particle System [John van der Burg]
//		http://www.gamasutra.com/features/20000623/vanderburg_01.htm
//   . LOVE game engine
//		http://love2d.org/
//
//
// Radius mode support, from 71 squared
//		http://particledesigner.71squared.com/
//
// IMPORTANT: Particle Designer is supported by cocos2d, but
// 'Radius Mode' in Particle Designer uses a fixed emit rate of 30 hz. Since that can't be guarateed in cocos2d,
//  cocos2d uses a another approach, but the results are almost identical.
//

// opengl
#import "Platforms/CCGL.h"

// cocos2d
#import "ccConfig.h"
#import "CCParticleSystem.h"
#import "CCParticleBatchNode.h"
#import "CCTextureCache.h"
#import "CCTextureAtlas.h"
#import "ccMacros.h"
#import "Support/CCProfiling.h"

// support
#import "Support/OpenGL_Internal.h"
#import "Support/CGPointExtension.h"
#import "Support/base64.h"
#import "Support/ZipUtils.h"
#import "Support/CCFileUtils.h"

@interface CCParticleSystem ()
-(void) updateBlendFunc;
@end

@implementation CCParticleSystem
@synthesize active, duration;
@synthesize sourcePosition, posVar;
@synthesize particleCount;
@synthesize life, lifeVar;
@synthesize angle, angleVar;
@synthesize startColor, startColorVar, endColor, endColorVar;
@synthesize startSpin, startSpinVar, endSpin, endSpinVar;
@synthesize emissionRate;
@synthesize startSize, startSizeVar;
@synthesize endSize, endSizeVar;
@synthesize opacityModifyRGB = opacityModifyRGB_;
@synthesize blendFunc = blendFunc_;
@synthesize positionType = positionType_;
@synthesize autoRemoveOnFinish = autoRemoveOnFinish_;
@synthesize emitterMode = emitterMode_;
@synthesize atlasIndex = atlasIndex_;
// add for delegate support
@synthesize delegate;
// add for scale support
@synthesize startHeightScale, startHeightScaleVar, endHeightScale, endHeightScaleVar;
@synthesize startWidthScale, startWidthScaleVar, endWidthScale, endWidthScaleVar;
@synthesize animationType=animationType_;

+(id) particleWithFile:(NSString*) plistFile
{
	return [[[self alloc] initWithFile:plistFile] autorelease];
}

+(id) particleWithTotalParticles:(NSUInteger) numberOfParticles
{
	return [[[self alloc] initWithTotalParticles:numberOfParticles] autorelease];
}

-(id) init {
	return [self initWithTotalParticles:150];
}

-(id) initWithFile:(NSString *)plistFile
{
	NSString *path = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:plistFile];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];

	NSAssert( dict != nil, @"Particles: file not found");
	return [self initWithDictionary:dict];
}

-(id) initWithDictionary:(NSDictionary *)dictionary
{
	NSUInteger maxParticles = [[dictionary valueForKey:@"maxParticles"] integerValue];
	// self, not super

	if ((self=[self initWithTotalParticles:maxParticles] ) )
	{
		// angle
		angle = [[dictionary valueForKey:@"angle"] floatValue];
		angleVar = [[dictionary valueForKey:@"angleVariance"] floatValue];

		// duration
		duration = [[dictionary valueForKey:@"duration"] floatValue];

		// blend function
		blendFunc_.src = [[dictionary valueForKey:@"blendFuncSource"] intValue];
		blendFunc_.dst = [[dictionary valueForKey:@"blendFuncDestination"] intValue];

		// color
		float r,g,b,a;

		r = [[dictionary valueForKey:@"startColorRed"] floatValue];
		g = [[dictionary valueForKey:@"startColorGreen"] floatValue];
		b = [[dictionary valueForKey:@"startColorBlue"] floatValue];
		a = [[dictionary valueForKey:@"startColorAlpha"] floatValue];
		startColor = (ccColor4F) {r,g,b,a};

		r = [[dictionary valueForKey:@"startColorVarianceRed"] floatValue];
		g = [[dictionary valueForKey:@"startColorVarianceGreen"] floatValue];
		b = [[dictionary valueForKey:@"startColorVarianceBlue"] floatValue];
		a = [[dictionary valueForKey:@"startColorVarianceAlpha"] floatValue];
		startColorVar = (ccColor4F) {r,g,b,a};

		r = [[dictionary valueForKey:@"finishColorRed"] floatValue];
		g = [[dictionary valueForKey:@"finishColorGreen"] floatValue];
		b = [[dictionary valueForKey:@"finishColorBlue"] floatValue];
		a = [[dictionary valueForKey:@"finishColorAlpha"] floatValue];
		endColor = (ccColor4F) {r,g,b,a};

		r = [[dictionary valueForKey:@"finishColorVarianceRed"] floatValue];
		g = [[dictionary valueForKey:@"finishColorVarianceGreen"] floatValue];
		b = [[dictionary valueForKey:@"finishColorVarianceBlue"] floatValue];
		a = [[dictionary valueForKey:@"finishColorVarianceAlpha"] floatValue];
		endColorVar = (ccColor4F) {r,g,b,a};

		// particle size
		startSize = [[dictionary valueForKey:@"startParticleSize"] floatValue];
		startSizeVar = [[dictionary valueForKey:@"startParticleSizeVariance"] floatValue];
		endSize = [[dictionary valueForKey:@"finishParticleSize"] floatValue];
		endSizeVar = [[dictionary valueForKey:@"finishParticleSizeVariance"] floatValue];

		// position
		float x = [[dictionary valueForKey:@"sourcePositionx"] floatValue];
		float y = [[dictionary valueForKey:@"sourcePositiony"] floatValue];
		self.position = ccp(x,y);
		posVar.x = [[dictionary valueForKey:@"sourcePositionVariancex"] floatValue];
		posVar.y = [[dictionary valueForKey:@"sourcePositionVariancey"] floatValue];

		// Spinning
		startSpin = [[dictionary valueForKey:@"rotationStart"] floatValue];
		startSpinVar = [[dictionary valueForKey:@"rotationStartVariance"] floatValue];
		endSpin = [[dictionary valueForKey:@"rotationEnd"] floatValue];
		endSpinVar = [[dictionary valueForKey:@"rotationEndVariance"] floatValue];

		emitterMode_ = [[dictionary valueForKey:@"emitterType"] intValue];
        
        // add for scale support
		startHeightScale = 1.0f; startHeightScaleVar = 0.0f;
		endHeightScale = 1.0f; endHeightScaleVar = 0.0f;
		startWidthScale = 1.0f; startWidthScaleVar = 0.0f;
		endWidthScale = 1.0f; endWidthScaleVar = 0.0f;
		if ([[dictionary allKeys] containsObject:@"startHeightScale"])
		    startHeightScale = [[dictionary valueForKey:@"startHeightScale"] floatValue];
        if ([[dictionary allKeys] containsObject:@"startHeightScaleVar"])
        	startHeightScaleVar = [[dictionary valueForKey:@"startHeightScaleVar"] floatValue];
        if ([[dictionary allKeys] containsObject:@"endHeightScale"])
        	endHeightScale = [[dictionary valueForKey:@"endHeightScale"] floatValue];
        if ([[dictionary allKeys] containsObject:@"endHeightScaleVar"])
        	endHeightScaleVar = [[dictionary valueForKey:@"endHeightScaleVar"] floatValue];
        if ([[dictionary allKeys] containsObject:@"startWidthScale"]) 
        	startWidthScale = [[dictionary valueForKey:@"startWidthScale"] floatValue];
        if ([[dictionary allKeys] containsObject:@"startWidthScaleVar"])
        	startWidthScaleVar = [[dictionary valueForKey:@"startWidthScaleVar"] floatValue];
        if ([[dictionary allKeys] containsObject:@"endWidthScale"])
        	endWidthScale = [[dictionary valueForKey:@"endWidthScale"] floatValue];
        if ([[dictionary allKeys] containsObject:@"endWidthScaleVar"])
        	endWidthScaleVar = [[dictionary valueForKey:@"endWidthScaleVar"] floatValue];
       
		// Mode A: Gravity + tangential accel + radial accel
		if( emitterMode_ == kCCParticleModeGravity ) {
			// gravity
			mode.A.gravity.x = [[dictionary valueForKey:@"gravityx"] floatValue];
			mode.A.gravity.y = [[dictionary valueForKey:@"gravityy"] floatValue];

			//
			// speed
			mode.A.speed = [[dictionary valueForKey:@"speed"] floatValue];
			mode.A.speedVar = [[dictionary valueForKey:@"speedVariance"] floatValue];

			// radial acceleration
			NSString *tmp = [dictionary valueForKey:@"radialAcceleration"];
			mode.A.radialAccel = tmp ? [tmp floatValue] : 0;

			tmp = [dictionary valueForKey:@"radialAccelVariance"];
			mode.A.radialAccelVar = tmp ? [tmp floatValue] : 0;

			// tangential acceleration
			tmp = [dictionary valueForKey:@"tangentialAcceleration"];
			mode.A.tangentialAccel = tmp ? [tmp floatValue] : 0;

			tmp = [dictionary valueForKey:@"tangentialAccelVariance"];
			mode.A.tangentialAccelVar = tmp ? [tmp floatValue] : 0;
		}

		// or Mode B: radius movement
		else if( emitterMode_ == kCCParticleModeRadius ) {
			float maxRadius = [[dictionary valueForKey:@"maxRadius"] floatValue];
			float maxRadiusVar = [[dictionary valueForKey:@"maxRadiusVariance"] floatValue];
			float minRadius = [[dictionary valueForKey:@"minRadius"] floatValue];

			mode.B.startRadius = maxRadius;
			mode.B.startRadiusVar = maxRadiusVar;
			mode.B.endRadius = minRadius;
			mode.B.endRadiusVar = 0;
			mode.B.rotatePerSecond = [[dictionary valueForKey:@"rotatePerSecond"] floatValue];
			mode.B.rotatePerSecondVar = [[dictionary valueForKey:@"rotatePerSecondVariance"] floatValue];

		} else {
			NSAssert( NO, @"Invalid emitterType in config file");
		}

		// life span
		life = [[dictionary valueForKey:@"particleLifespan"] floatValue];
		lifeVar = [[dictionary valueForKey:@"particleLifespanVariance"] floatValue];

		// emission Rate
		emissionRate = totalParticles/life;

		//don't get the internal texture if a batchNode is used
		if (!batchNode_)
		{
			// Set a compatible default for the alpha transfer
			opacityModifyRGB_ = NO;

			// texture
			// Try to get the texture from the cache

			NSString *textureName = [dictionary valueForKey:@"textureFileName"];

			CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:textureName];

			if( tex )
				[self setTexture:tex];
			else {

				NSString *textureData = [dictionary valueForKey:@"textureImageData"];
				NSAssert( textureData, @"CCParticleSystem: Couldn't load texture");

				// if it fails, try to get it from the base64-gzipped data
				unsigned char *buffer = NULL;
				int len = base64Decode((unsigned char*)[textureData UTF8String], (unsigned int)[textureData length], &buffer);
				NSAssert( buffer != NULL, @"CCParticleSystem: error decoding textureImageData");

				unsigned char *deflated = NULL;
				NSUInteger deflatedLen = ccInflateMemory(buffer, len, &deflated);
				free( buffer );

				NSAssert( deflated != NULL, @"CCParticleSystem: error ungzipping textureImageData");
				NSData *data = [[NSData alloc] initWithBytes:deflated length:deflatedLen];

#ifdef __CC_PLATFORM_IOS
				UIImage *image = [[UIImage alloc] initWithData:data];
#elif defined(__CC_PLATFORM_MAC)
				NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData:data];
#endif

				free(deflated); deflated = NULL;

				[self setTexture:  [ [CCTextureCache sharedTextureCache] addCGImage:[image CGImage] forKey:textureName]];
				[data release];
				[image release];
			}

			NSAssert( [self texture] != NULL, @"CCParticleSystem: error loading the texture");
		}
	}

	return self;
}

-(id) initWithTotalParticles:(NSUInteger) numberOfParticles
{
	if( (self=[super init]) ) {

		totalParticles = numberOfParticles;

		particles = calloc( totalParticles, sizeof(tCCParticle) );

		if( ! particles ) {
			CCLOG(@"Particle system: not enough memory");
			[self release];
			return nil;
		}
        allocatedParticles = numberOfParticles;

		if (batchNode_)
		{
			for (int i = 0; i < totalParticles; i++)
			{
				particles[i].atlasIndex=i;
			}
		}

		// default, active
		active = YES;

		// default blend function
		blendFunc_ = (ccBlendFunc) { CC_BLEND_SRC, CC_BLEND_DST };

		// default movement type;
		positionType_ = kCCPositionTypeFree;

		// by default be in mode A:
		emitterMode_ = kCCParticleModeGravity;

		autoRemoveOnFinish_ = NO;

		// Optimization: compile updateParticle method
		updateParticleSel = @selector(updateQuadWithParticle:newPosition:);
		updateParticleImp = (CC_UPDATE_PARTICLE_IMP) [self methodForSelector:updateParticleSel];

		//for batchNode
		transformSystemDirty_ = NO;
        
        // animation
		useAnimation_ = NO;
		totalFrameCount_ = 0;
		animationFrameData_ = NULL;
		animationType_ = kCCParticleAnimationTypeLoop;

		// update after action in run!
		[self scheduleUpdateWithPriority:1];
	}
	return self;
}

-(void) dealloc
{
	[self unscheduleUpdate];

	free( particles );
    
    if (animationFrameData_)
		free(animationFrameData_);

	[texture_ release];

	[super dealloc];
}

-(void) initParticle: (tCCParticle*) particle
{
	//CGPoint currentPosition = position_;
	// timeToLive
	// no negative life. prevent division by 0
	particle->timeToLive = life + lifeVar * CCRANDOM_MINUS1_1();
	particle->timeToLive = MAX(0, particle->timeToLive);
	particle->elapsed = 0;

	// position
	particle->pos.x = sourcePosition.x + posVar.x * CCRANDOM_MINUS1_1();
	particle->pos.y = sourcePosition.y + posVar.y * CCRANDOM_MINUS1_1();

	// Color
	ccColor4F start;
	start.r = clampf( startColor.r + startColorVar.r * CCRANDOM_MINUS1_1(), 0, 1);
	start.g = clampf( startColor.g + startColorVar.g * CCRANDOM_MINUS1_1(), 0, 1);
	start.b = clampf( startColor.b + startColorVar.b * CCRANDOM_MINUS1_1(), 0, 1);
	start.a = clampf( startColor.a + startColorVar.a * CCRANDOM_MINUS1_1(), 0, 1);

	ccColor4F end;
	end.r = clampf( endColor.r + endColorVar.r * CCRANDOM_MINUS1_1(), 0, 1);
	end.g = clampf( endColor.g + endColorVar.g * CCRANDOM_MINUS1_1(), 0, 1);
	end.b = clampf( endColor.b + endColorVar.b * CCRANDOM_MINUS1_1(), 0, 1);
	end.a = clampf( endColor.a + endColorVar.a * CCRANDOM_MINUS1_1(), 0, 1);

	particle->color = start;
	particle->deltaColor.r = (end.r - start.r) / particle->timeToLive;
	particle->deltaColor.g = (end.g - start.g) / particle->timeToLive;
	particle->deltaColor.b = (end.b - start.b) / particle->timeToLive;
	particle->deltaColor.a = (end.a - start.a) / particle->timeToLive;

	// size
    //to limit increase in byte size of particle, size is used as scale during animation
	if (useAnimation_)
	{
		float startS = startSize + startSizeVar * CCRANDOM_MINUS1_1();
		startS = MAX(0, startS); // No negative value
		
		particle->size = startS;
		if( endSize == kCCParticleStartSizeEqualToEndSize )
			particle->deltaSize = 0;
		else {
			float endS = endSize + endSizeVar * CCRANDOM_MINUS1_1();
			endS = MAX(0, endS);	// No negative values
			particle->deltaSize = (endS - startS) / particle->timeToLive;
		}
	}
    else {
        float startS = startSize + startSizeVar * CCRANDOM_MINUS1_1();
        startS = MAX(0, startS); // No negative value
        
        particle->size = startS;
        if( endSize == kCCParticleStartSizeEqualToEndSize )
            particle->deltaSize = 0;
        else {
            float endS = endSize + endSizeVar * CCRANDOM_MINUS1_1();
            endS = MAX(0, endS);	// No negative values
            particle->deltaSize = (endS - startS) / particle->timeToLive;
        }
    }
    particle->orgSize = particle->size;

	// direction
    float r = CCRANDOM_MINUS1_1();
	float a = CC_DEGREES_TO_RADIANS( angle + angleVar * r );
	// rotation
	float startA = startSpin + startSpinVar * CCRANDOM_MINUS1_1();
	if (startSpin == kCCParticleSpinEqualToAngle) {
		startA = (90 - (angle + angleVar * r));
	}
	
	if (endSpin == kCCParticleStartSpinEqualToEndSpin) {
	    particle->deltaRotation = 0;
	}
	else {
	    float endA = endSpin + endSpinVar * CCRANDOM_MINUS1_1();
	    particle->deltaRotation = (endA - startA) / particle->timeToLive;
	}
	particle->rotation = startA;

	// position
	if( positionType_ == kCCPositionTypeFree )
		particle->startPos = [self convertToWorldSpace:CGPointZero];

	else if( positionType_ == kCCPositionTypeRelative )
		particle->startPos = position_;
    
    // add for scale support
    float startHS = startHeightScale + startHeightScaleVar * CCRANDOM_0_1();
    particle->heightScale = startHS;
    float endHS = endHeightScale + endHeightScaleVar * CCRANDOM_0_1();
    particle->heightScaleDelta = (endHS - startHS) / particle->timeToLive;
    
    float startWS = startWidthScale + startWidthScaleVar * CCRANDOM_0_1();
    particle->widthScale = startWS;
    float endWS = endWidthScale + endWidthScaleVar * CCRANDOM_0_1();
    particle->widthScaleDelta = (endWS - startWS) / particle->timeToLive;
    
	// Mode Gravity: A
	if( emitterMode_ == kCCParticleModeGravity ) {

		particle->mode.A.angle = a;
		
		CGPoint v = {cosf( a ), sinf( a )};
		float s = mode.A.speed + mode.A.speedVar * CCRANDOM_MINUS1_1();

        // speed
        particle->mode.A.speed = s;
        particle->mode.A.orgSpeed = s;
        
		// direction
		particle->mode.A.dir = ccpMult( v, s );

		// radial accel
		particle->mode.A.radialAccel = mode.A.radialAccel + mode.A.radialAccelVar * CCRANDOM_MINUS1_1();

		// tangential accel
		particle->mode.A.tangentialAccel = mode.A.tangentialAccel + mode.A.tangentialAccelVar * CCRANDOM_MINUS1_1();
	}

	// Mode Radius: B
	else {
		// Set the default diameter of the particle from the source position
		float startRadius = mode.B.startRadius + mode.B.startRadiusVar * CCRANDOM_MINUS1_1();
		float endRadius = mode.B.endRadius + mode.B.endRadiusVar * CCRANDOM_MINUS1_1();

		particle->mode.B.radius = startRadius;

		if( mode.B.endRadius == kCCParticleStartRadiusEqualToEndRadius )
			particle->mode.B.deltaRadius = 0;
		else
			particle->mode.B.deltaRadius = (endRadius - startRadius) / particle->timeToLive;

		particle->mode.B.angle = a;
		particle->mode.B.degreesPerSecond = CC_DEGREES_TO_RADIANS(mode.B.rotatePerSecond + mode.B.rotatePerSecondVar * CCRANDOM_MINUS1_1());
	}
    
    // animation
	if (useAnimation_)
	{
		particle->split = 0;
		particle->elapsed = 0;
        
		switch (animationType_) {
			default:
			case kCCParticleAnimationTypeOnce:
			case kCCParticleAnimationTypeLoop: {
				particle->currentFrame = 0;
				break;
			}
			case kCCParticleAnimationTypeRandomFrame:
			case kCCParticleAnimationTypeLoopWithRandomStartFrame: {
				particle->currentFrame = (NSUInteger) roundf((CCRANDOM_0_1() * (totalFrameCount_ -1)));
				break;
			}
		}
	}
}

-(BOOL) addParticle
{
	if( [self isFull] )
		return NO;

	tCCParticle * particle = &particles[ particleCount ];

	[self initParticle: particle];
	particleCount++;

	return YES;
}

-(void) stopSystem
{
	active = NO;
	elapsed = duration;
	emitCounter = 0;
}

-(void) resetSystem
{
	active = YES;
	elapsed = 0;
	for(particleIdx = 0; particleIdx < particleCount; ++particleIdx) {
		tCCParticle *p = &particles[particleIdx];
		p->timeToLive = 0;
		p->elapsed = 0;
	}

}

-(BOOL) isFull
{
	return (particleCount == totalParticles);
}

#pragma mark ParticleSystem - MainLoop
-(void) update: (ccTime) dt
{
	CC_PROFILER_START_CATEGORY(kCCProfilerCategoryParticles , @"CCParticleSystem - update");

	if( active && emissionRate ) {
		float rate = 1.0f / emissionRate;
		
		//issue #1201, prevent bursts of particles, due to too high emitCounter
		if (particleCount < totalParticles)
			emitCounter += dt; 
		
		while( particleCount < totalParticles && emitCounter > rate ) {
			[self addParticle];
			emitCounter -= rate;
		}

		elapsed += dt;

		if(duration != -1 && duration < elapsed)
			[self stopSystem];
	}

	particleIdx = 0;

	CGPoint currentPosition = CGPointZero;
	if( positionType_ == kCCPositionTypeFree )
		currentPosition = [self convertToWorldSpace:CGPointZero];

	else if( positionType_ == kCCPositionTypeRelative )
		currentPosition = position_;

	if (visible_)
	{
		while( particleIdx < particleCount )
		{
			tCCParticle *p = &particles[particleIdx];

			// life
			p->timeToLive -= dt;

			if( p->timeToLive > 0 ) {

                if (useAnimation_) {
					switch (animationType_) {
						default:
						case kCCParticleAnimationTypeLoopWithRandomStartFrame:
						case kCCParticleAnimationTypeLoop:
						{
							p->elapsed += dt;
							while (p->elapsed >= p->split) {
								
								p->currentFrame++;
								if (p->currentFrame >= totalFrameCount_)
								{
									p->currentFrame = 0;
									p->elapsed = p->elapsed - p->split;
									p->split = 0.f;
								}
								p->split += animationFrameData_[p->currentFrame].delay;
								
							}
							break;
						}
						case kCCParticleAnimationTypeOnce:
						{
							//stop after one iteration
							if (p->currentFrame != totalFrameCount_)
							{
								p->elapsed += dt;
								while (p->elapsed >= p->split) {
									
									p->currentFrame++;
									if (p->currentFrame >= totalFrameCount_)
									{
										p->currentFrame = totalFrameCount_;
										break;
									}
									p->split += animationFrameData_[p->currentFrame].delay;
								}
							}
							break;
						}
						case kCCParticleAnimationTypeRandomFrame:
						{
							// frame does not change in random mode
							break;
						}
					}
				}
                else {
                    p->elapsed += dt;
                }
                
				// Mode A: gravity, direction, tangential accel & radial accel
				if( emitterMode_ == kCCParticleModeGravity ) {
					CGPoint tmp, radial, tangential;

					if (delegate && [delegate respondsToSelector:@selector(updateParticleSpeed:elapsed:dt:)]) {
						// change of speed will affect direction
						[delegate updateParticleSpeed:p elapsed:elapsed dt:dt];
                        CGPoint v = {cosf( p->mode.A.angle ), sinf( p->mode.A.angle )};
                        p->mode.A.dir = ccpMult( v, p->mode.A.speed );
					}
					if (delegate && [delegate respondsToSelector:@selector(updateParticleAngle:elapsed:dt:)]) {
						// change of speed will affect direction
						[delegate updateParticleAngle:p elapsed:elapsed dt:dt];
						CGPoint v = {cosf( p->mode.A.angle ), sinf( p->mode.A.angle )};
						p->mode.A.dir = ccpMult( v, p->mode.A.speed );
					}
					if (delegate && [delegate respondsToSelector:@selector(updateParticleRadialAccel:elapsed:dt:)])
						[delegate updateParticleRadialAccel:p elapsed:elapsed dt:dt];
					if (delegate && [delegate respondsToSelector:@selector(updateParticleTangentialAccel:elapsed:dt:)])
						[delegate updateParticleTangentialAccel:p elapsed:elapsed dt:dt];
						
					radial = CGPointZero;
					// radial acceleration
					if(p->pos.x || p->pos.y)
						radial = ccpNormalize(p->pos);

					tangential = radial;
					radial = ccpMult(radial, p->mode.A.radialAccel);

					// tangential acceleration
					float newy = tangential.x;
					tangential.x = -tangential.y;
					tangential.y = newy;
					tangential = ccpMult(tangential, p->mode.A.tangentialAccel);

					// (gravity + radial + tangential) * dt
					tmp = ccpAdd( ccpAdd( radial, tangential), mode.A.gravity);
					tmp = ccpMult( tmp, dt);
					p->mode.A.dir = ccpAdd( p->mode.A.dir, tmp);
					tmp = ccpMult(p->mode.A.dir, dt);
					p->pos = ccpAdd( p->pos, tmp );
				}

				// Mode B: radius movement
				else {
					// Update the angle and radius of the particle.
					if (delegate && [delegate respondsToSelector:@selector(updateParticleDegreesPerSecond:elapsed:dt:)])
						[delegate updateParticleDegreesPerSecond:p elapsed:elapsed dt:dt];

					if (delegate && [delegate respondsToSelector:@selector(updateParticleRadius:elapsed:dt:)]) {
						[delegate updateParticleRadius:p elapsed:elapsed dt:dt];
					}
					else {
					    p->mode.B.radius += p->mode.B.deltaRadius * dt;
					}					
										
					if (delegate && [delegate respondsToSelector:@selector(updateParticleAngle:elapsed:dt:)]) {
						[delegate updateParticleAngle:p elapsed:elapsed dt:dt];
					}
					else {
						p->mode.B.angle += p->mode.B.degreesPerSecond * dt;
					}
					
					p->pos.x = - cosf(p->mode.B.angle) * p->mode.B.radius;
					p->pos.y = - sinf(p->mode.B.angle) * p->mode.B.radius;
				}
                
                // add for scale support
				if (delegate && [delegate respondsToSelector:@selector(updateParticleScale:elapsed:dt:)]) {
				    [delegate updateParticleScale:p elapsed:elapsed dt:dt];
				}
                else {
                    p->heightScale += (p->heightScaleDelta * dt);
                    p->heightScale = MAX( 0, p->heightScale );
                    p->widthScale += (p->widthScaleDelta * dt);
                    p->widthScale = MAX( 0, p->widthScale );
                }

				// color
				if (delegate && [delegate respondsToSelector:@selector(updateParticleColor:elapsed:dt:)]) {
				    [delegate updateParticleColor:p elapsed:elapsed dt:dt];
				}
				else {
					p->color.r += (p->deltaColor.r * dt);
					p->color.g += (p->deltaColor.g * dt);
					p->color.b += (p->deltaColor.b * dt);
					p->color.a += (p->deltaColor.a * dt);
				}
				
				// size
				if (delegate && [delegate respondsToSelector:@selector(updateParticleSize:elapsed:dt:)]) {
				    [delegate updateParticleSize:p elapsed:elapsed dt:dt];
				}
				else {
					p->size += (p->deltaSize * dt);
					p->size = MAX( 0, p->size );
				}
                
                // scale
				if (delegate && [delegate respondsToSelector:@selector(updateParticleScale:elapsed:dt:)]) {
				    [delegate updateParticleScale:p elapsed:elapsed dt:dt];
				}

				// angle
				if (delegate && [delegate respondsToSelector:@selector(updateParticleRotation:elapsed:dt:)]) {
				    [delegate updateParticleRotation:p elapsed:elapsed dt:dt];
				}
				else {
					p->rotation += (p->deltaRotation * dt);
				}

				//
				// update values in quad
				//

				CGPoint	newPos;

				if( positionType_ == kCCPositionTypeFree || positionType_ == kCCPositionTypeRelative )
				{
					CGPoint diff = ccpSub( currentPosition, p->startPos );
					newPos = ccpSub(p->pos, diff);
				} else
					newPos = p->pos;

				// translate newPos to correct position, since matrix transform isn't performed in batchnode
				// don't update the particle with the new position information, it will interfere with the radius and tangential calculations
				if (batchNode_)
				{
					newPos.x+=position_.x;
					newPos.y+=position_.y;
				}

				updateParticleImp(self, updateParticleSel, p, newPos);

				// update particle counter
				particleIdx++;

			} else {
				// life < 0
				NSInteger currentIndex = p->atlasIndex;

				if( particleIdx != particleCount-1 )
					particles[particleIdx] = particles[particleCount-1];

				if (batchNode_)
				{
					//disable the switched particle
					[batchNode_ disableParticle:(atlasIndex_+currentIndex)];

					//switch indexes
					particles[particleCount-1].atlasIndex = currentIndex;
				}

				particleCount--;

				if( particleCount == 0 && autoRemoveOnFinish_ ) {
					[self unscheduleUpdate];
					[parent_ removeChild:self cleanup:YES];
					return;
				}
			}
		}//while
		transformSystemDirty_ = NO;
	}

	if (!batchNode_)
		[self postStep];

	CC_PROFILER_STOP_CATEGORY(kCCProfilerCategoryParticles , @"CCParticleSystem - update");
}

-(void) updateWithNoTime
{
	[self update:0.0f];
}

-(void) updateQuadWithParticle:(tCCParticle*)particle newPosition:(CGPoint)pos;
{
	// should be overriden
}

-(void) postStep
{
	// should be overriden
}

#pragma mark ParticleSystem - CCTexture protocol

-(void) setTexture:(CCTexture2D*) texture
{
	if( texture_ != texture ) {
		[texture_ release];
		texture_ = [texture retain];

		[self updateBlendFunc];
	}
}

-(CCTexture2D*) texture
{
	return texture_;
}

#pragma mark ParticleSystem - Additive Blending
-(void) setBlendAdditive:(BOOL)additive
{
	if( additive ) {
		blendFunc_.src = GL_SRC_ALPHA;
		blendFunc_.dst = GL_ONE;

	} else {

		if( texture_ && ! [texture_ hasPremultipliedAlpha] ) {
			blendFunc_.src = GL_SRC_ALPHA;
			blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
		} else {
			blendFunc_.src = CC_BLEND_SRC;
			blendFunc_.dst = CC_BLEND_DST;
		}
	}
}

-(BOOL) blendAdditive
{
	return( blendFunc_.src == GL_SRC_ALPHA && blendFunc_.dst == GL_ONE);
}

-(void) setBlendFunc:(ccBlendFunc)blendFunc
{
	if( blendFunc_.src != blendFunc.src || blendFunc_.dst != blendFunc.dst ) {
		blendFunc_ = blendFunc;
		[self updateBlendFunc];
	}
}
#pragma mark ParticleSystem - Total Particles Property

- (void) setTotalParticles:(NSUInteger)tp
{
    NSAssert( tp <= allocatedParticles, @"Particle: resizing particle array only supported for quads");
    totalParticles = tp;
}

- (NSUInteger) totalParticles
{
    return totalParticles;
}

#pragma mark ParticleSystem - Properties of Gravity Mode
-(void) setTangentialAccel:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.tangentialAccel = t;
}
-(float) tangentialAccel
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.tangentialAccel;
}

-(void) setTangentialAccelVar:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.tangentialAccelVar = t;
}
-(float) tangentialAccelVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.tangentialAccelVar;
}

-(void) setRadialAccel:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.radialAccel = t;
}
-(float) radialAccel
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.radialAccel;
}

-(void) setRadialAccelVar:(float)t
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.radialAccelVar = t;
}
-(float) radialAccelVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.radialAccelVar;
}

-(void) setGravity:(CGPoint)g
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.gravity = g;
}
-(CGPoint) gravity
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.gravity;
}

-(void) setSpeed:(float)speed
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.speed = speed;
}
-(float) speed
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.speed;
}

-(void) setSpeedVar:(float)speedVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	mode.A.speedVar = speedVar;
}
-(float) speedVar
{
	NSAssert( emitterMode_ == kCCParticleModeGravity, @"Particle Mode should be Gravity");
	return mode.A.speedVar;
}

#pragma mark ParticleSystem - Properties of Radius Mode

-(void) setStartRadius:(float)startRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.startRadius = startRadius;
}
-(float) startRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.startRadius;
}

-(void) setStartRadiusVar:(float)startRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.startRadiusVar = startRadiusVar;
}
-(float) startRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.startRadiusVar;
}

-(void) setEndRadius:(float)endRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.endRadius = endRadius;
}
-(float) endRadius
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.endRadius;
}

-(void) setEndRadiusVar:(float)endRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.endRadiusVar = endRadiusVar;
}
-(float) endRadiusVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.endRadiusVar;
}

-(void) setRotatePerSecond:(float)degrees
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.rotatePerSecond = degrees;
}
-(float) rotatePerSecond
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.rotatePerSecond;
}

-(void) setRotatePerSecondVar:(float)degrees
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	mode.B.rotatePerSecondVar = degrees;
}
-(float) rotatePerSecondVar
{
	NSAssert( emitterMode_ == kCCParticleModeRadius, @"Particle Mode should be Radius");
	return mode.B.rotatePerSecondVar;
}

#pragma mark ParticleSystem - methods for batchNode rendering

-(CCParticleBatchNode*) batchNode
{
	return batchNode_;
}

-(void) setBatchNode:(CCParticleBatchNode*) batchNode
{
	if( batchNode_ != batchNode ) {

		batchNode_ = batchNode; // weak reference

		if( batchNode ) {
			//each particle needs a unique index
			for (int i = 0; i < totalParticles; i++)
			{
				particles[i].atlasIndex=i;
			}
		}
	}
}

//don't use a transform matrix, this is faster
-(void) setScale:(float) s
{
	transformSystemDirty_ = YES;
	[super setScale:s];
}

-(void) setRotation: (float)newRotation
{
	transformSystemDirty_ = YES;
	[super setRotation:newRotation];
}

-(void) setScaleX: (float)newScaleX
{
	transformSystemDirty_ = YES;
	[super setScaleX:newScaleX];
}

-(void) setScaleY: (float)newScaleY
{
	transformSystemDirty_ = YES;
	[super setScaleY:newScaleY];
}

#pragma mark Particle - Helpers

-(void) updateBlendFunc
{
	NSAssert(! batchNode_, @"Can't change blending functions when the particle is being batched");

	BOOL premultiplied = [texture_ hasPremultipliedAlpha];

	opacityModifyRGB_ = NO;

	if( texture_ && ( blendFunc_.src == CC_BLEND_SRC && blendFunc_.dst == CC_BLEND_DST ) ) {
		if( premultiplied )
			opacityModifyRGB_ = YES;
		else {
			blendFunc_.src = GL_SRC_ALPHA;
			blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
		}
	}
}


@end
