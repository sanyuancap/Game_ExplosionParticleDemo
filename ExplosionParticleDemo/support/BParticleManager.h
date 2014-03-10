/*
 *  BParticleManager.h
 *  FirstGame
 *
 *  Created by Ben Smiley-Andrews on 01/05/2012.
 *  Copyright (c) 2012 Deluge. All rights reserved.
 */

@interface BParticleManager : NSObject { 
    // Map the file name of the emmitter to a tag number which will be set on the emitter
    NSMutableDictionary * _stringToTagMap;

    // Array to store a pool of particles
	NSMutableArray * _particlePool;

	// Store the maximum tag used
	NSInteger _maxTag;
}

-(id) getParticle:(NSString *)type; 
@end
