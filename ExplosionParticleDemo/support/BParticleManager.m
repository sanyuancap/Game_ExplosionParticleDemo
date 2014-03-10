/*
 *  BParticleManager.m
 *  FirstGame
 *
 *  Created by Ben Smiley-Andrews on 01/05/2012.
 *  Copyright (c) 2012 Deluge. All rights reserved.
 */
 

#import "cocos2d.h"
#import "BParticleManager.h"
 
@implementation BParticleManager
 
-(id) init {
    if((self=[super init])) {
        _particlePool = [NSMutableArray new];
        _stringToTagMap = [NSMutableDictionary new];
        _maxTag = 0;
    }
    return self;
}

/*
 * This class will return an CCParticleSystemQuad with the 
 * supplied resource path i.e. .plist file. If a pooled 
 * system is available that will be returned. An system  
 * is considered available if it is inactive and has no 
 * active particles.
 */
-(id) getParticle:(NSString *)type {
    NSNumber * tag = [_stringToTagMap objectForKey:type];
 
    /* 
     * If the mapping doesn't exist in the dictionary add it. We use this
     * mapping because we want to define the particle type by it's .plist
     * file path but the CCParticleSystem object can only tag systems with
     * an int.
     */ 
    if(tag==Nil) {
        tag = [NSNumber numberWithInt:_maxTag++];
        [_stringToTagMap setObject:tag forKey:type];
    }
 
    // If possible return a system from the pool
    // Search through the pool for an available object of the 
    // required type and if one is found return it
    CCParticleSystemQuad * system;
    for(system in _particlePool) {
        if(system.tag==[tag intValue] && (system.particleCount==0 ) && !system.active  ) {
            [system resetSystem];
            return system;
        }
    }
 
    // Otherwise return a new system
    system = [CCParticleSystemQuad particleWithFile:type];
    system.tag = [tag intValue];
    [_particlePool addObject:system];
 
    return system;
}
 
-(void) dealloc {
    [_particlePool release];
    [_stringToTagMap release];
    [super dealloc];
}
@end