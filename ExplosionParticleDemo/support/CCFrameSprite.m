#import "CCFrameSprite.h"

@implementation CCFrameSprite
@synthesize frameWidth;
@synthesize frameHeight;
@synthesize frameColor;
@synthesize frameBgColor;

+ (id) frameWithWidth:(float)frameWidth_ height:(float)frameHeight_ frameColor:(ccColor4B)frameColor_ frameBgColor:(ccColor4B)frameBgColor_
{
    return [[[self alloc] initWithWidth:frameWidth_ height:frameHeight_ frameColor:frameColor_ frameBgColor:frameBgColor_] autorelease];
}

- (id) initWithWidth:(float)frameWidth_ height:(float)frameHeight_ frameColor:(ccColor4B)frameColor_ frameBgColor:(ccColor4B)frameBgColor_
{
	if( (self = [super init])) {
		self.frameWidth = frameWidth_;
		self.frameHeight = frameHeight_;
		self.frameColor = frameColor_;
        self.frameBgColor = frameBgColor_;
	}
	return self;
}

-(void)draw
{
    CGSize frameSize = CGSizeMake(self.frameWidth - 1, self.frameHeight - 1);
    CGRect rectFrame = CGRectMake(-frameSize.width / 2, -frameSize.height / 2, frameSize.width, frameSize.height);
    
	glLineWidth(1.0f);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    ccDrawColor4B(self.frameColor.r, self.frameColor.g, self.frameColor.b, self.frameColor.a);
    ccDrawRect(rectFrame.origin, ccp(rectFrame.origin.x + rectFrame.size.width, rectFrame.origin.y + rectFrame.size.height));
    CGRect rectFill = CGRectInset(rectFrame, 2, 2);
    ccDrawSolidRect(rectFill.origin, ccp(rectFill.origin.x + rectFill.size.width, rectFill.origin.y + rectFill.size.height), ccc4FFromccc4B(self.frameBgColor));
    
    glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
}
@end