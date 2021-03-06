//
//  NSImage+CocoaLUT.m
//  Pods
//
//  Created by Greg Cotten on 1/30/15.
//
//

#import "NSImage+CocoaLUT.h"

#if defined(COCOAPODS_POD_AVAILABLE_VVSceneLinearImageRep)
#import <VVSceneLinearImageRep/NSImage+SceneLinear.h>
#endif

@implementation NSImage (CocoaLUT)

-(instancetype)cocoaLUT_imageWithDeviceRGBColorspace{
    if (![self.representations.firstObject isKindOfClass:[NSBitmapImageRep class]]) {
        return nil;
    }
    if (![((NSBitmapImageRep *)self.representations.firstObject).colorSpaceName isEqualToString:NSDeviceRGBColorSpace]) {
        //make sure to toss the embedded colorspace if it exists
        NSImage *image = [self copy];
        [(NSBitmapImageRep *)image.representations.firstObject setColorSpaceName:NSDeviceRGBColorSpace];
        return image;
    }
    else{
        return self;
    }
}

-(CGColorSpaceRef)cocoaLUT_cgColorSpaceRef{
    return [((NSBitmapImageRep *)self.representations.firstObject).colorSpace CGColorSpace];
}

- (NSImage *)cocoalut_imageByPreservingEmbeddedColorSpace:(BOOL)preserveEmbeddedColorSpace{
    NSImage *usedNormalImage;
    #if defined(COCOAPODS_POD_AVAILABLE_VVSceneLinearImageRep)
        if ([self isSceneLinear]) {
            if (!preserveEmbeddedColorSpace) {
                usedNormalImage = [[self imageInDeviceRGBColorSpace] imageByDenormalizingSceneLinearData];
            }
            else{
                usedNormalImage = [[self imageInGenericHDRColorSpace] imageByDenormalizingSceneLinearData];
            }
        }
        else{
            usedNormalImage = preserveEmbeddedColorSpace?self:[self cocoaLUT_imageWithDeviceRGBColorspace];
        }
    #else
        usedNormalImage = preserveEmbeddedColorSpace?self:[self cocoaLUT_imageWithDeviceRGBColorspace];
    #endif

    return usedNormalImage;
}

@end
