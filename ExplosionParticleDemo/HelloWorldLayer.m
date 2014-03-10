#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "ShatteredSprite.h"
#import "SimpleAudioEngine.h"
#import "CCShake.h"
#import "CCRemoveAndCleanupAction.h"
#import "CCParticleEffectGenerator.h"

@implementation HelloWorldLayer

static int const effectCount = 8;
static NSString * const effectNames[] = {
	@"Experiment",
	@"Flare",
	@"Chaotic Flare",
    @"Burst Flare",
    @"Ground Explode",
    @"Arm Explode",
    @"Cartoon Explode",
    @"Area Bang",
    @"Big Bang",
	@"empty",
};
static BOOL const enableCans = YES;
static BOOL const enableShake = YES;

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[scene addChild: layer];
	return scene;
}

-(id) init
{
	if( (self=[super init]) ) {
        
		// add bg
		CCSprite *bg = [CCSprite spriteWithFile:@"bg.png"];
		bg.position = ccp(240, 160);
		[self addChild:bg z:0 tag:999];
		
        effectIndex = 0;
        
		// add title
		CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Explode Effect Demo - %@", effectNames[effectIndex]]
                                               fontName:@"Verdana-BoldItalic"
                                               fontSize:18];
		label.position = ccp(240 , 300);
		[self addChild:label z:1 tag:99];
        
        self.isTouchEnabled = YES;
        canArray = [[CCArray alloc] init];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"bomb.wav"];
        CCMenuLayer *menuLayer = [[CCMenuLayer alloc] initWithTarget:self]; 
        [self addChild:menuLayer];
        [self schedule:@selector(addCan) interval:1.0f];
    
        // animation test
//        CCSpriteFrameCache* sfc = [CCSpriteFrameCache sharedSpriteFrameCache];
//        [sfc addSpriteFramesWithFile:@"animated_particles.plist"];
//        
//        CCAnimation* anim2 = [CCAnimation animation];
//        NSMutableArray *animationFramesArray = [[NSMutableArray alloc] init];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_1.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_2.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_3.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_4.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_5.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_4.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_3.png"]];
//        [animationFramesArray addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coco_2.png"]];
//        
//        anim2 = [[CCAnimation alloc] initWithSpriteFrames:animationFramesArray delay:0.1f];
//        CCParticleSystemQuad *system = [[CCParticleSystemQuad alloc] initWithFile:@"OneParticle.plist"];
//        [system setPosition:ccp(240, 200)];
//        [system setTexture: [[sfc spriteFrameByName:@"coco_1.png"] texture]];
//        [system setAnimation:anim2 withAnchorPoint:ccp(0.5f,0.0f)];
//        [system setAnimationType:0];
//        [self addChild: system z:10];
//        [system release];
        
    }
	return self;
}

#pragma mark - CCMenuLayer delegate


- (void) preEffect
{
	effectIndex = (effectIndex <= 1) ? effectCount : effectIndex - 1;
	CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:99];
	if (label) [label setString:[NSString stringWithFormat:@"Explode Effect Demo - %@", effectNames[effectIndex]]];
}

- (void) nextEffect
{
	effectIndex = (effectIndex >= effectCount) ? 1 : effectIndex + 1;
	CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:99];
	if (label) [label setString:[NSString stringWithFormat:@"Explode Effect Demo - %@", effectNames[effectIndex]]];
}

#pragma mark - touch delegate
- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [[touches anyObject] locationInView: [[touches anyObject] view]];
	CGPoint location =  [[CCDirector sharedDirector] convertToGL:touchLocation];
    // fot test effect
    if (effectIndex == 0) {
        [self runEffectAtPosition:location];
        return;
    }
    // for area bang, big bang
    if (effectIndex == 7 || effectIndex == 8) {
        [self processExplosionEffectWithCan:nil];
        return;
    }
    
    for (CCSprite *can in canArray) {
        if (CGRectContainsPoint([can boundingBox], location)) {
            [self processExplosionEffectWithCan:can];
            return;
        }
    }
}

#pragma mark - schedule
- (void) addCan
{
    if ([canArray count] >= 5) return;
    CCSprite *can =[CCSprite spriteWithFile:@"can.png"];
    can.scale = 0.2f + 0.5 * CCRANDOM_0_1();
    can.position = ccp(40 + CCRANDOM_0_1() * 400, 40 + CCRANDOM_0_1() * 240);
    [self addChild:can z:1 tag:[canArray count] + 1];
    [canArray addObject:can];
}


#pragma mark - explosion process
- (void) processExplosionEffectWithCan:(CCSprite *)can
{
	[self runShakeScreenEffect];
	[self playExplosionSE];
    // for area bang, big bang
    if (effectIndex == 7 || effectIndex == 8) {
        for (CCSprite *tmpCan in canArray) {
            [self runShatterEffectWithCan:tmpCan];
        }
        [self runEffectAtPosition:ccp(240, 160)];
        [canArray removeAllObjects];
        return;
    }
    [self runEffectAtPosition:can.position];
    [self runShatterEffectWithCan:can];
    [canArray removeObject:can];
}

- (void) playExplosionSE
{
	[[SimpleAudioEngine sharedEngine] playEffect:@"bomb.wav"];
}

- (void) runShakeScreenEffect
{
    [self runAction:[CCShake actionWithDuration:2.0f
                                      amplitude:ccp(5 + CCRANDOM_0_1() * 5, 5 + CCRANDOM_0_1() * 5)
                                      dampening:YES]];
}

- (void) runShatterEffectWithCan:(CCSprite *)can
{
	ShatteredSprite *shatter = [ShatteredSprite shatterWithSprite:[CCSprite spriteWithTexture:[can texture]] piecesX:8 piecesY:8 speed:20.0 rotation:0.2 radial:YES];
	shatter.position = can.position;
	shatter.subShatterPercent = 100;
	[self addChild:shatter];
	[shatter runAction:[CCSequence actions:[CCFadeOut actionWithDuration:1.0], [CCRemoveAndCleanupAction action], nil]];
	[self removeChild:can cleanup:YES];
}


#pragma mark - explosion effect
- (void) runEffectAtPosition:(CGPoint)position
{
	CCEmitterNode *effectEmitter;
	switch(effectIndex) {
		case 0:
			effectEmitter = [CCParticleEffectGenerator getExperimentEffectEmitter];
			break;
		case 1:
			effectEmitter = [CCParticleEffectGenerator getFlareEffectEmitter];
			break;
		case 2:
			effectEmitter = [CCParticleEffectGenerator getChaoticFlareEffectEmitter];
			break;
        case 3:
            effectEmitter = [CCParticleEffectGenerator getBurstFlareEffectEmitter];
            break;
        case 4:
            effectEmitter = [CCParticleEffectGenerator getGroudExplodeEffectEmitter];
            break;
        case 5:
            effectEmitter = [CCParticleEffectGenerator getArmExplodeEffectEmitter];
            break;
        case 6:
            effectEmitter = [CCParticleEffectGenerator getCartoonExplodeEffectEmitter];
            break;
        case 7:
            effectEmitter = [CCParticleEffectGenerator getAreaBangEffectEmitter];
            break;
        case 8:
            effectEmitter = [CCParticleEffectGenerator getBigBangEffectEmitter];
            break;
		defaule:
			NSAssert(NO, @"Invalid effect index.");
			break;
	}
	NSAssert(effectEmitter != nil, @"CCEmitterNode is nil.");
    effectEmitter.position = position;
	[self addChild:effectEmitter z:1];
}


- (void) dealloc
{
	[canArray removeAllObjects];
	[canArray release];
	[super dealloc];
}
@end
