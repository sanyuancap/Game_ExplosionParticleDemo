#import "CCMenuLayer.h"
#import "CCFrameSprite.h"

@implementation CCMenuLayer
@synthesize delegate;

- (id) initWithTarget:(id)aDelegate {  
	if (self = [super initWithTarget:nil position:MENU_POSITION_BOTTOM size:CGSizeMake(480, 40) 
						  frameColor:ccc4(255, 200, 0, 200) 
						frameBgColor:ccc4(0, 0, 0, 255) 
						   animation:ANIMATION_TYPE_BLINK]) {
		self.delegate = aDelegate;
        [self initMenu];
    }
	return self;
}

#pragma mark - Main control
- (void) initMenu {
    [CCMenuItemFont setFontName:@"Verdana-BoldItalic"];
    [CCMenuItemFont setFontSize:20];
	CCMenuItemFont *preEffectItem = [CCMenuItemFont itemWithString:@"Pre" target:self selector:@selector(preEffect:)];
    CCMenuItemFont *nextEffectItem = [CCMenuItemFont itemWithString:@"Next" target:self selector:@selector(nextEffect:)];
	CCMenu *changeEffectMenu = [CCMenu menuWithItems:preEffectItem, nextEffectItem, nil];
    changeEffectMenu.position = ccp(240, 20);
    [changeEffectMenu alignItemsHorizontallyWithPadding:20.0f];
    [self addChild:changeEffectMenu z:999];
}

#pragma mark - Story sub menu
- (void) preEffect:(id)sender {
	if (self.delegate) [self.delegate preEffect];
}


- (void) nextEffect:(id)sender {
	if (self.delegate) [self.delegate nextEffect];
}


@end