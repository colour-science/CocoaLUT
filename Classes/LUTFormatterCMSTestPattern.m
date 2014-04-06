//
//  LUTFormatterNukeCMSTestPattern.m
//  
//
//  Created by Greg Cotten on 3/30/14.
//
//

#import "LUTFormatterCMSTestPattern.h"
#import "CocoaLUT.h"

@implementation LUTFormatterCMSTestPattern

+ (NSData *)dataFromLUT:(LUT *)lut {
#if TARGET_OS_IPHONE
    return UIImagePNGRepresentation([self imageFromLUT:lut]);
# elif TARGET_OS_MAC
    return [[self imageFromLUT:lut] TIFFRepresentation];
# endif
}

+ (LUT *)LUTFromData:(NSData *)data {
#if TARGET_OS_IPHONE
    return [self LUTFromImage:[[UIImage alloc] initWithData:data]];
# elif TARGET_OS_MAC
    return [self LUTFromImage:[[NSImage alloc] initWithData:data]];
# endif
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageFromLUT:(LUT *)lut {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterCMSTestPattern doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
+ (LUT *)LUTFromImage:(UIImage *)image {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterCMSTestPattern doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
#elif TARGET_OS_MAC

+ (NSImage *)imageFromLUT:(LUT *)lut {
    int cubeSize = (int)lut.lattice.size;
    int height = round(sqrt(cubeSize)*(double)cubeSize);
    int width  = ceil(((double)pow(cubeSize,3))/(double)height);
    
    NSLog(@"w:%i h:%i", width*7, height*7);
    
//    CGColorSpaceRef cgColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
//    NSColorSpace *linearRGBColorSpace = [[NSColorSpace alloc] initWithCGColorSpace:cgColorSpace];
//    CGColorSpaceRelease(cgColorSpace);
    
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                         pixelsWide:(CGFloat)width*7
                                                                         pixelsHigh:(CGFloat)height*7
                                                                      bitsPerSample:16
                                                                    samplesPerPixel:3
                                                                           hasAlpha:NO
                                                                           isPlanar:NO
                                                                     colorSpaceName:NSDeviceRGBColorSpace
                                                                        bytesPerRow:(width*7 * (16 * 3)) / 8
                                                                       bitsPerPixel:16 * 3];
    
    for(int y = 0; y < height; y++){
        for(int x = 0; x < width; x++){
            NSUInteger currentCubeIndex = y*width + x;
            
//                        NSLog(@"ax%i ay%i", x, (int)(height - (y+1)));
//                        NSLog(@"px%i py%i", x*7, (height - (y+1))*7);
            NSUInteger redIndex = currentCubeIndex % cubeSize;
            NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
            NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);
            
            
            if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
                NSColor *color = [[lut.lattice colorAtR:redIndex g:greenIndex b:blueIndex].NSColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
                for(int px = (int)x*7; px < x*7+7; px++){
                    for(int py = (int)(height - (y+1))*7; py < (height - (y+1))*7+7; py++){
                        [imageRep setColor:color atX:px y:py];
                    }
                }
            }
        }
    }
    
    
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromImage:(NSImage *)image {
    int cubeSize = (int)(round(pow((image.size.height/7)*(image.size.height/7), 1.0/3.0)));
    
    int height = round(sqrt(cubeSize)*(double)cubeSize);
    int width  = ceil(((double)pow(cubeSize,3))/(double)height);
    
    NSLog(@"CMS Cube Size: %i", cubeSize);
    
    if (image.size.width != width*7 || image.size.height != height*7) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError"
                                                         reason:@"Image dimensions don't conform to LUTFormatterCMSTestPattern." userInfo:nil];
        @throw exception;
    }
    
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:cubeSize];
    
    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    
    dispatch_apply(height, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t y){
        dispatch_apply(width, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^(size_t x){
            NSUInteger currentCubeIndex = y*width + x;
            
//            NSLog(@"ax%i ay%i", x, (int)(height - (y+1)));
//            NSLog(@"px%i py%i", x*7, (height - (y+1))*7);
            NSUInteger redIndex = currentCubeIndex % cubeSize;
            NSUInteger greenIndex = ( (currentCubeIndex % (cubeSize * cubeSize)) / (cubeSize) );
            NSUInteger blueIndex = currentCubeIndex / (cubeSize * cubeSize);
            
            if(currentCubeIndex < cubeSize*cubeSize*cubeSize){
                    //NSLog(@"%@", [LUTColor colorWithNSColor:[imageRep colorAtX:x*7 y:(height - (y+1))*7]]);
                    [lattice setColor:[LUTColor colorWithNSColor:[imageRep colorAtX:x*7 y:(height - (y+1))*7]] r:redIndex g:greenIndex b:blueIndex];
            }
        });
    });
    
    return [LUT LUTWithLattice:lattice];
}
#endif


@end