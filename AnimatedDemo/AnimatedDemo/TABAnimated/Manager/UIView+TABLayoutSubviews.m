//
//  UIView+TABLayerout.m
//  AnimatedDemo
//
//  Created by tigerAndBull on 2018/9/21.
//  Copyright © 2018年 tigerAndBull. All rights reserved.
//

#import "UIView+TABLayoutSubviews.h"
#import "TABAnimated.h"

#import <objc/runtime.h>

@implementation UIView (TABLayoutSubviews)

+ (void)load {
    
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        // Gets the layoutSubviews method to the class,whose type is a pointer to a objc_method structure.
        Method originMethod = class_getInstanceMethod([self class], @selector(layoutSubviews));
        // Get the method you created.
        Method newMethod = class_getInstanceMethod([self class], @selector(tab_layoutSubviews));
        // Exchange
        method_exchangeImplementations(originMethod, newMethod);
    });
}

#pragma mark - Exchange Method

- (void)tab_layoutSubviews {
    
    [self tab_layoutSubviews];

    if ([self isKindOfClass:[UITableView class]] ||
        [self isKindOfClass:[UICollectionView class]] ||
        [self isKindOfClass:[UICollectionViewCell class]] ||
        [self isKindOfClass:[UITableViewCell class]]) {
        return;
    }
    
    // start animation/end animation
    dispatch_async(dispatch_get_main_queue(), ^{

        if (nil != self.tabAnimated) {
            
            switch (self.tabAnimated.state) {
                    
                case TABViewAnimationStart: {
                    
                    // change status
                    self.tabAnimated.state = TABViewAnimationRunning;
                    
                    if (nil == self.tabLayer) {
                        self.tabLayer = TABLayer.new;
                        self.tabLayer.frame = self.bounds;
                        self.tabLayer.animatedHeight = self.tabAnimated.animatedHeight;
                        self.tabLayer.animatedCornerRadius = self.tabAnimated.animatedCornerRadius;
                        self.tabLayer.cancelGlobalCornerRadius = self.tabAnimated.cancelGlobalCornerRadius;
                        [self.layer addSublayer:self.tabLayer];
                    }
                    
                    // start animations
                    NSMutableArray <TABComponentLayer *> *array = @[].mutableCopy;
                    [TABManagerMethod getNeedAnimationSubViews:self
                                                 withSuperView:self
                                                  withRootView:self
                                             withRootSuperView:self
                                                  isInNestView:NO
                                                         array:array];
                    
                    self.tabLayer.componentLayerArray = array;
                    
                    __weak typeof(self) weakSelf = self;
                    if (self.tabAnimated.categoryBlock) {
                        self.tabAnimated.categoryBlock(weakSelf);
                    }
                    
                    self.tabLayer.animatedBackgroundColor = self.tabAnimated.animatedBackgroundColor;
                    self.tabLayer.animatedColor = self.tabAnimated.animatedColor;
                    [self.tabLayer updateSublayers:self.tabLayer.componentLayerArray.mutableCopy];
                    
                    if (self.tabLayer.nestView) {
                        self.tabLayer.backgroundColor = UIColor.clearColor.CGColor;
                        [TABManagerMethod resetDataForNormalView:self];
                    }
                    
                    // add shimmer animation
                    if ([TABManagerMethod canAddShimmer:self]) {
                        for (NSInteger i = 0; i < self.tabLayer.resultLayerArray.count; i++) {
                            TABComponentLayer *layer = self.tabLayer.resultLayerArray[i];
                            UIColor *baseColor = [TABAnimated sharedAnimated].shimmerBackColor;
                            CGFloat brigtness = [TABAnimated sharedAnimated].shimmerBrightness;
                            layer.colors = @[
                                             (id)baseColor.CGColor,
                                             (id)[TABAnimationMethod brightenedColor:baseColor brightness:brigtness].CGColor,
                                             (id) baseColor.CGColor
                                             ];
                            [TABAnimationMethod addShimmerAnimationToLayer:layer
                                                                  duration:[TABAnimated sharedAnimated].animatedDurationShimmer
                                                                       key:kTABShimmerAnimation
                                                                 direction:[TABAnimated sharedAnimated].shimmerDirection];
                            
                        }
                        break;
                    }
                    
                    // add bin animation
                    if ([TABManagerMethod canAddBinAnimation:self]) {
                        [TABAnimationMethod addAlphaAnimation:self
                                                     duration:[TABAnimated sharedAnimated].animatedDurationBin key:kTABAlphaAnimation];
                        break;
                    }
                    
                    // add drop animation
                    if ([TABManagerMethod canAddDropAnimation:self]) {
                        
                        UIColor *deepColor;
                        if (self.tabAnimated.dropAnimationDeepColor) {
                            deepColor = self.tabAnimated.dropAnimationDeepColor;
                        }else {
                            deepColor = [TABAnimated sharedAnimated].dropAnimationDeepColor;
                        }
                        
                        CGFloat duration = 0;
                        CGFloat cutTime = 0.02;
                        CGFloat allCutTime = cutTime*(self.tabLayer.resultLayerArray.count-1)*(self.tabLayer.resultLayerArray.count)/2.0;
                        if (self.tabAnimated.dropAnimationDuration != 0.) {
                            duration = self.tabAnimated.dropAnimationDuration;
                        }else {
                            duration = [TABAnimated sharedAnimated].dropAnimationDuration;
                        }
                        
                        for (NSInteger i = 0; i < self.tabLayer.resultLayerArray.count; i++) {
                            TABComponentLayer *layer = self.tabLayer.resultLayerArray[i];
                            if (layer.removeOnDropAnimation) {
                                continue;
                            }
                            [TABAnimationMethod addDropAnimation:layer
                                                           index:layer.dropAnimationIndex
                                                        duration:duration*(self.tabLayer.dropAnimationCount+1)-allCutTime
                                                           count:self.tabLayer.dropAnimationCount+1
                                                        stayTime:layer.dropAnimationStayTime-i*cutTime
                                                       deepColor:deepColor
                                                             key:kTABDropAnimation];
                        }
                    }
                    
                    if (self.tabLayer.nestView) {
                        [self.tabLayer.nestView tab_startAnimation];
                    }
                }
                    
                    break;
                    
                default:
                    break;
            }
        }
    });
}

@end