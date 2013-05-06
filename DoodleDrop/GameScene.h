//
//  GameScene.h
//  DoodleDrop
//
//  Created by Daniel Barden on 5/6/13.
//  Copyright 2013 Daniel Barden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameScene : CCLayer {
    CCSprite *player;
    CGPoint playerVelocity;
    
    CCArray *spiders;
    float spiderMoveDuration;
    int spidersMoved;
    
    // Score
    CCLabelTTF *scoreLabel;
    int score;
    float totalTime;
}

+ (CCScene *)scene;

@end
