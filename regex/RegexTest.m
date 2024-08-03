// RegexTest.m
//
// Copyright (c) 2002 Aram Greenman. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import <AGRegex/AGRegex.h>

int main(int argc, const char *argv[]) {
	NSAutoreleasePool *p =  [[NSAutoreleasePool alloc] init];
	NSString *pat, *str, *sub;
	AGRegex *re;
	
	// Simple find pattern
	pat = @"(paran|andr)oid";
	str = @"paranoid android";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Found \"%@\" in \"%@\": %@", pat, str, [re findInString:str]);
	
	// Find pattern with unmatched subpatterns
	pat = @"(?:(paran)|(andr))oid";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Found \"%@\" in \"%@\": %@", pat, str, [re findInString:str]);
	
	// Find all non-overlapping occurrences of pattern
	NSLog(@"Found all \"%@\" in \"%@\": %@", pat, str, [re findAllInString:str]);
	
	// Simple replace pattern
	pat = @"remote";
	str = @"remote control";
	sub = @"complete";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Replaced \"%@\" with \"%@\" in \"%@\": %@", pat, sub, str, [re replaceWithString:sub inString:str]);
	
	// Replace pattern with captured subpattern in replacement string
	pat = @"[usr]";
	str = @"Back in the ussr";
	sub = @"\\u$&.";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Replaced \"%@\" with \"%@\" in \"%@\": %@", pat, sub, str, [re replaceWithString:sub inString:str]);
	
	// Replace pattern with named subpatterns in replacement string
	pat = @"(?P<who>\\w+) is a (?P<what>\\w+)";
	str = @"Judy is a punk";
	sub = @"Jackie is a $what, $who is a runt";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Replaced \"%@\" with \"%@\" in \"%@\": %@", pat, sub, str, [re replaceWithString:sub inString:str]);
	
	// Simple split string
	pat = @"ea?";
	str = @"Repeater";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Split \"%@\" using \"%@\": %@", str, pat, [re splitString:str]);
	
	// Split string with captured subpattern
	pat = @"e(a)?";
	re = [AGRegex regexWithPattern:pat];
	NSLog(@"Split \"%@\" using \"%@\": %@", str, pat, [re splitString:str]);
	
	[p release];
	return 0;
}