//  Copyright 2012 Alejandro Isaza.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.

#import "AttributedTextView.h"
#import <CoreText/CoreText.h>

const CGFloat MARGIN = 8;

@interface AttributedTextView ()
- (void)drawLine:(NSRange)range offset:(CGFloat)offset context:(CGContextRef)context;
@end

@implementation AttributedTextView

@synthesize string;

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	self.backgroundColor = [UIColor whiteColor];
	self.userInteractionEnabled = NO;
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (!self)
		return nil;
	
	self.backgroundColor = [UIColor whiteColor];
	self.userInteractionEnabled = NO;
	return self;
}

- (void)dealloc {
	[string release];
	[super dealloc];
}

- (void)drawRect:(CGRect)rect {
	if (string.length == 0)
		return;
	
    CGSize size = self.bounds.size;
    CTFontRef font = (CTFontRef)[string attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:NULL];
    CGFloat lineHeight = [[self class] lineHeight:font];
    
    
//	// flip the coordinate system
//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
//	CGContextTranslateCTM(context, 0, self.bounds.size.height);
//	CGContextScaleCTM(context, 1.0, -1.0);
//	
//	// Get the text bounds
//	CGRect r = CGRectMake(MARGIN, MARGIN, size.width - 2*MARGIN, size.height - 2*MARGIN);
//	
//	// Get line height
//	
//	// Draw lines
//	CGFloat y = r.size.height - MARGIN + 2;
//	NSCharacterSet* cs = [NSCharacterSet newlineCharacterSet];
//	NSRange range = NSMakeRange(0, string.length);
//	while (true) {
//		// Find next line break
//		NSRange next = [string.string rangeOfCharacterFromSet:cs options:NSLiteralSearch range:range];
//		if (next.location == NSNotFound)
//			break;
//		
//		// Keep track of ranges
//		NSUInteger len = next.location - range.location;
//		NSRange lineRange = NSMakeRange(range.location, len);
//		range.location += len + 1;
//		range.length -= len + 1;
//		
//		// Draw line
//		if (len > 0)
//			[self drawLine:lineRange offset:y context:context];
//		y -= lineHeight;
//	}
//	
//	// Draw last line
//	if (range.length > 0)
//		[self drawLine:range offset:y context:context];
    
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0); 
    CGContextSetShouldSmoothFonts(ctx, YES);
    CGContextSetShouldAntialias(ctx, YES);
    CGRect textRect = CGRectMake(MARGIN, MARGIN, size.width - 2*MARGIN, size.height - 2*MARGIN);
    
    //Manual Line braking
    BOOL shouldDrawAnotherLine = YES;
    double width = textRect.size.width;
    CGPoint textPosition = CGPointMake(textRect.origin.x, textRect.origin.y+textRect.size.height-lineHeight+2);
    ;
    // Initialize those variables.
    
    // Create a typesetter using the attributed string.
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)string);
    
    // Find a break for line from the beginning of the string to the given width.
    CFIndex start = 0;
    while (shouldDrawAnotherLine) {
        
        CFIndex count = CTTypesetterSuggestLineBreak(typesetter, start, width);
        
        // Use the returned character count (to the break) to create the line.
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, count));
        
        // Move the given text drawing position by the calculated offset and draw the line.
        CGContextSetTextPosition(ctx, textPosition.x, textPosition.y);
        CTLineDraw(line, ctx);
        if (line!=NULL) {
            CFRelease(line);
        }
        // Move the index beyond the line break.
        
        if (start + count >= [string length]) {
            shouldDrawAnotherLine = NO;
            continue;
        }
        start += count;
        textPosition.y -= lineHeight;
    }
    if (typesetter!=NULL) {
        CFRelease(typesetter);
    }
    
}

- (void)drawLine:(NSRange)range offset:(CGFloat)offset context:(CGContextRef)context {
	// Get one line of text
	NSAttributedString* s = [string attributedSubstringFromRange:range];
	
	// Draw line
	CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)s);
	CGContextSetTextPosition(context, MARGIN, offset);
	CTLineDraw(line, context);
	CFRelease(line);
}

+ (CGFloat)lineHeight:(CTFontRef)font {
	CGFloat ascent = CTFontGetAscent(font);
	CGFloat descent = CTFontGetDescent(font);
	CGFloat leading = CTFontGetLeading(font);
	return ceilf(ascent + descent + leading);
}

@end
