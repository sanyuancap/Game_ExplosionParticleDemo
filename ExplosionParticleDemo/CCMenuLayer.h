#import "cocos2d.h"
#import "CCSlidingMenuLayer.h"

@protocol CCMenuLayerDelegate<NSObject>
- (void) preEffect;
- (void) nextEffect;
@optional

@end

@interface CCMenuLayer : CCSlidingMenuLayer {
    id<CCMenuLayerDelegate> delegate;
}

- (id) initWithTarget:(id)aDelegate;
- (void) initMenu;
- (void) preEffect:(id)sender;
- (void) nextEffect:(id)sender;

@property (nonatomic, retain) id<CCMenuLayerDelegate> delegate;
@end
