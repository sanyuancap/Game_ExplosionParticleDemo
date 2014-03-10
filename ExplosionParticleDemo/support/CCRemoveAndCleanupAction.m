#import "CCRemoveAndCleanupAction.h"

@implementation CCRemoveAndCleanupAction

-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	[target_ removeFromParentAndCleanup:YES];
}
@end
