#import "cocos2d.h"

@interface CCFrameSprite : CCSprite {
	ccColor4B frameBgColor;								
	ccColor4B frameColor;
	float frameWidth;
    float frameHeight;
}

+ (id) frameWithWidth:(float)frameWidth_ height:(float)frameHeight_ frameColor:(ccColor4B)frameColor_ frameBgColor:(ccColor4B)frameBgColor_;
- (id) initWithWidth:(float)frameWidth_ height:(float)frameHeight_ frameColor:(ccColor4B)frameColor_ frameBgColor:(ccColor4B)frameBgColor_;


@property(nonatomic) float frameWidth;
@property(nonatomic) float frameHeight;
@property(nonatomic) ccColor4B frameColor;
@property(nonatomic) ccColor4B frameBgColor;

@end