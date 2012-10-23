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

#import "JavascriptSyntaxHighlighter.h"
#import <CoreText/CoreText.h>


@implementation JavascriptSyntaxHighlighter

@synthesize font = _font;
@synthesize defaultColor = _defaultColor;
@synthesize commentColor = _commentColor;
@synthesize keywordColor = _keywordColor;
@synthesize stringColor = _stringColor;
@synthesize commandLineMode = _commandLineMode;

- (id)init {
	self = [super init];
	if (!self)
		return nil;
	
	self.font = [UIFont fontWithName:@"CourierNewPSMT" size:16.f];
	self.defaultColor = [UIColor blackColor];
	self.commentColor = [UIColor colorWithRed:0 green:.5f blue:0 alpha:1];
	self.keywordColor = [UIColor blueColor];
	self.stringColor = [UIColor colorWithRed:.64f green:.08f blue:.08f alpha:1];
	return self;
}

- (void)dealloc {
	[_font release];
	[_defaultColor release];
	[_commentColor release];
	[_keywordColor release];
	[_stringColor release];
	[super dealloc];
}

- (NSAttributedString*)highlight:(NSString*)text {
	if (text == nil)
		return nil;
	
	NSMutableAttributedString* string = [[[NSMutableAttributedString alloc] initWithString:text] autorelease];
	NSUInteger length = [string length];
	NSRange wholeRange = NSMakeRange(0, length);
	
	// The font has to match what is set for the text vuew
	CTFontRef ctFont = CTFontCreateWithName(CFSTR("CourierNewPSMT"), _font.pointSize, NULL);
	[string addAttribute:(id)kCTFontAttributeName
				   value:(id)ctFont
				   range:wholeRange];
	CFRelease(ctFont);
	
	// Set the default text color
	[string addAttribute:(id)kCTForegroundColorAttributeName
				   value:(id)_defaultColor.CGColor
				   range:wholeRange];
	
	// Disable ligatures if you are using a fixed-width font
	[string addAttribute:(id)kCTLigatureAttributeName
				   value:[NSNumber numberWithInt:0]
				   range:wholeRange];
	
	// Set of highlighted keywords
	static NSSet* keywords;
    if (!keywords) {
        keywords = [[NSSet alloc] initWithObjects:
                    @"break",
                    @"case",
                    @"catch",
                    @"continue",
                    @"debugger",
                    @"default",
                    @"delete",
                    @"do",
                    @"else",
                    @"finally",
                    @"for",
                    @"function",
                    @"if",
                    @"in",
                    @"instanceof",
                    @"new",
                    @"return",
                    @"switch",
                    @"this",
                    @"throw",
                    @"try",
                    @"typeof",
                    @"var",
                    @"void",
                    @"while",
                    @"with",
                    @"class",
                    @"enum",
                    @"export",
                    @"extends",
                    @"import",
                    @"super",
                    @"implements",
                    @"interface",
                    @"let",
                    @"package",
                    @"private",
                    @"protected",
                    @"public",
                    @"static",
                    @"yield",
                    nil];
    }
	
	NSRange wordRange;
	NSRange stringRange;
	NSRange commentRange;
	BOOL isWord = NO;
	BOOL isEscaped = NO;
	BOOL isString = NO;
	BOOL isComment = NO;
    BOOL ignoreLine = NO;
    char quoteType = '\0';
	for (NSUInteger i = 0; i < length; i++) {
		// Ignore escaped characters
		if (isEscaped) {
			isEscaped = NO;
			continue;
		}
		
		unichar c = [text characterAtIndex:i];
		
        if (_commandLineMode) {
            if (ignoreLine) {
                while (c != '\n') {
                    c = [text characterAtIndex:++i];
                }
            }
            if (c == '\n') {
                if (i != text.length - 1 && [text characterAtIndex:i+1] != '>') {
                    ignoreLine = YES;
                } else {
                    ignoreLine = NO;
                }
            }
        }
        
		// Start of a word
		if (!isWord && !isComment && !isString && (isalpha(c) || c == '_')) {
			isWord = YES;
			wordRange.location = i;
		}
		
		// End of a word
		if (isWord && !isalnum(c) && c != '_') {
			isWord = NO;
			wordRange.length = i - wordRange.location;
			NSString* word = [text substringWithRange:wordRange];
			if ([keywords containsObject:word]) {
				[string addAttribute:(id)kCTForegroundColorAttributeName
							   value:(id)_keywordColor.CGColor
							   range:wordRange];
			}
		}
		
		// Start/end of a string
		if (!isEscaped &&
            !isComment &&
            ((isString && (c == quoteType || c == '\n')) ||  (!isString && (c == '"' || c == '\''))) ) {
			if (isString) {
				stringRange.length = i - stringRange.location + 1;
				[string addAttribute:(id)kCTForegroundColorAttributeName
							   value:(id)_stringColor.CGColor
							   range:stringRange];
				stringRange = NSMakeRange(NSNotFound, 0);
			} else {
                quoteType = c;
				stringRange.location = i;
			}
			isString = !isString;
		}
		
		if (!isEscaped && c == '\\')
			isEscaped = YES;
		
		// Start of a comment
		if (!isString && c == '/' && i < text.length - 1 && [text characterAtIndex:i+1] == '/') {
			isComment = YES;
			commentRange.location = i;
		}
		
		// End of a comment
		if ([text characterAtIndex:i] == '\n' || [text characterAtIndex:i] == '\r') {
			if (isComment) {
				commentRange.length = i - commentRange.location + 1;
				[string addAttribute:(id)kCTForegroundColorAttributeName
							   value:(id)_commentColor.CGColor
							   range:commentRange];
				commentRange = NSMakeRange(NSNotFound, 0);
			}
			isComment = NO;
		}
	}
	
	// Wrap up any partial words, strings or comments
	if (isWord) {
		wordRange.length = text.length - wordRange.location;
		NSString* word = [text substringWithRange:wordRange];
		if ([keywords containsObject:word]) {
			[string addAttribute:(id)kCTForegroundColorAttributeName
						   value:(id)_keywordColor.CGColor
						   range:wordRange];
		}
	} else if (isString) {
		stringRange.length = text.length - stringRange.location;
		[string addAttribute:(id)kCTForegroundColorAttributeName
					   value:(id)_stringColor.CGColor
					   range:stringRange];
	} else if (isComment) {
		commentRange.length = text.length - commentRange.location;
		[string addAttribute:(id)kCTForegroundColorAttributeName
					   value:(id)_commentColor.CGColor
					   range:commentRange];
	}
	
	return string;
}

@end
