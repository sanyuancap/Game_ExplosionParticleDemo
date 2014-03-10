#import "cocos2d.h"
#import "CCMenuLayer.h"

@interface HelloWorldLayer : CCLayer
{
    CCArray *canArray;
    int effectIndex;
}

+(CCScene *) scene;

- (void) addCan;
- (void) processExplosionEffectWithCan:(CCSprite *)can;
- (void) playExplosionSE;
- (void) runShakeScreenEffect;
- (void) runShatterEffectWithCan:(CCSprite *)can;
- (void) runEffectAtPosition:(CGPoint)position;

@end
