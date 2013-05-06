//
//  GameScene.m
//  DoodleDrop
//
//  Created by Daniel Barden on 5/6/13.
//  Copyright 2013 Daniel Barden. All rights reserved.
//

#import "GameScene.h"
#import "SimpleAudioEngine.h"

@implementation GameScene

+ (CCScene *)scene
{
    
    CCScene *scene = [CCScene node];
    CCLayer *layer = [GameScene node];
    [scene addChild:layer z:0 tag:1];
    return scene;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        self.accelerometerEnabled = YES;
        
        // Score Labels
        scoreLabel = [CCLabelTTF labelWithString:@"0" fontName:@"Arial" fontSize:48];
        scoreLabel.position = ccp(screenSize.width/2, screenSize.height);
        scoreLabel.anchorPoint = ccp(0.5f, 1.0f);
        [self addChild:scoreLabel z:-1];
        
        player = [CCSprite spriteWithFile:@"alien.png"];
        float imageHeight = [player texture].contentSize.height;
        
        player.position = ccp(screenSize.width/2, imageHeight/2);
        [self addChild:player];
        
        [self scheduleUpdate];
        [self initSpiders];
        
        // Plays sound
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"blues.mp3"];
    }

    return self;
}

- (void)initSpiders
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    
    CCSprite *tempSpider = [CCSprite spriteWithFile:@"spider.png"];
    float imageWidth = [tempSpider contentSize].width;
    
    int numSpiders = screenSize.width/imageWidth;
    
    spiders = [[CCArray alloc] initWithCapacity:numSpiders];
    
    for (int i = 0; i < numSpiders; i++) {
        CCSprite *spider = [CCSprite spriteWithFile:@"spider.png"];
        [spiders addObject:spider];
        [self addChild:spider z:0 tag:2];
    }
    [self resetSpiders];
}

- (void)resetSpiders
{
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CCSprite *tempSpider = [spiders lastObject];
    
    CGSize spiderSize = [tempSpider texture].contentSize;
    
    int numSpiders = [spiders count];
    
    for (int i = 0; i < numSpiders; i++) {
        CCSprite *spider = [spiders objectAtIndex:i];
        spider.position = ccp(spiderSize.width * i + spiderSize.width * 0.5f,
                              screenSize.height + spiderSize.height);
        [spider stopAllActions];
    }
    [self unschedule:@selector(spiderUpdate:)];
    [self schedule:@selector(spiderUpdate:) interval:0.7f];
    
    spidersMoved = 0;
    spiderMoveDuration = 4.0f;
}

- (void)spiderUpdate:(ccTime)delta
{
    for (int i = 0; i < 10; i++) {
        int randomSpiderIndex = CCRANDOM_0_1() * [spiders count];
        CCSprite *spider = [spiders objectAtIndex:randomSpiderIndex];
        if ([spider numberOfRunningActions] == 0) {
            [self runSpiderSequence:spider];
            break;
        }
    }
}

- (void)runSpiderSequence:(CCSprite *)spider
{
    spidersMoved++;
    
    if (spidersMoved % 8 == 0 && spiderMoveDuration > 2.0f) {
        spiderMoveDuration -= 0.1f;
    }
    
    CGPoint belowScreenPosition = ccp(spider.position.x, - [spider texture].contentSize.height);
    CCMoveTo *action = [CCMoveTo actionWithDuration:spiderMoveDuration position:belowScreenPosition];
    CCCallFuncN *callDidDrop = [CCCallFuncN actionWithTarget:self selector:@selector(spiderDidDrop:)];
    CCSequence *seq = [CCSequence actions:action, callDidDrop, nil];
    [spider runAction:seq];
}

- (void)spiderDidDrop:(id)sender
{
    NSAssert([sender isKindOfClass:[CCSprite class]], @"sender is not a CCSprite");
    CCSprite *spider = (CCSprite *)sender;
    
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    CGPoint pos = spider.position;
    
    pos.y = screenSize.height + [spider texture].contentSize.height/2;
    spider.position = pos;
}

- (void)checkForColision
{
    float playerImageSize = [player texture].contentSize.height;
    float spiderImageSize = [[spiders lastObject] texture].contentSize.height;
    
    float playerCollisionRadius = playerImageSize * 0.4f;
    float spiderCollisionRadius = spiderImageSize * 0.4f;
    
    float maxCollisionDistance = playerCollisionRadius + spiderCollisionRadius;
    
    int numSpiders = [spiders count];
    for (int i = 0; i < numSpiders; i++) {
        CCSprite *spider = [spiders objectAtIndex:i];
        if ([spider numberOfRunningActions] == 0)
            continue;
        float actualDistance = ccpDistance(player.position, spider.position);
        if (actualDistance < maxCollisionDistance) {
            [scoreLabel setString:@"0"];
            totalTime = 0;
            score = 0;
            [[SimpleAudioEngine sharedEngine] playEffect:@"alien-sfx.caf"];
            [self resetSpiders];
            break;
        }
    }
}

// Accelerometer input
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    float deceleration = 0.4f;
    float sensitivity = 6.0f;
    float maxVelocity = 100;

    playerVelocity.x = playerVelocity.x * deceleration + acceleration.x * sensitivity;
    
    if (playerVelocity.x > maxVelocity)
        playerVelocity.x = maxVelocity;
    else if (playerVelocity.x < -maxVelocity)
        playerVelocity.x = -maxVelocity;
}

- (void)updatePlayerVelocity
{
    CGPoint pos = player.position;
    pos.x += playerVelocity.x;
    player.position = pos;
    
    CGSize screenSize = [[CCDirector sharedDirector] winSize];
    float imageHalved = [player texture].contentSize.width/2;
    
    float leftBorderLimit = imageHalved;
    float rightBorderLimit = screenSize.width - imageHalved;
    
    if (pos.x < leftBorderLimit) {
        pos.x = imageHalved;
        playerVelocity = CGPointZero;
        
    } else if (pos.x > rightBorderLimit) {
        pos.x = rightBorderLimit;
        playerVelocity = CGPointZero;
    }
    
    player.position = pos;

}

- (void)updateScore:(ccTime)delta
{
    totalTime += delta;
    int currentTime = (int)totalTime;
    if (score < currentTime) {
        score = currentTime;
        [scoreLabel setString:[NSString stringWithFormat:@"%i", score]];
    }
    
}
// updates the spiders velocity
- (void)update:(ccTime)delta
{
    [self updatePlayerVelocity];
    [self checkForColision];
    [self updateScore:delta];
    
}

- (void)dealloc
{
    CCLOG(@"%@: %@", NSStringFromSelector(_cmd), self);
    [spiders release];
    spiders = nil;
    [super dealloc];
}

@end
