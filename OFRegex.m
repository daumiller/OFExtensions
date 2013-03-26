/*==================================================================================================================================
Copyright © 2013 Dillon Aumiller <dillonaumiller@gmail.com>

This file is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

This file is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this file.  If not, see <http://www.gnu.org/licenses/>.
==================================================================================================================================*/
#import "OFRegex.h"
#import <pcre.h>

//==================================================================================================================================
@implementation OFRegex
//----------------------------------------------------------------------------------------------------------------------------------
@synthesize error  = _error;
@synthesize code   = _code;
@synthesize offset = _offset;
-(BOOL) valid { return (_code == 0); }
//----------------------------------------------------------------------------------------------------------------------------------
+(OFRegex *)regexWithPattern:(OFString *)pattern                                 { return [[[OFRegex alloc] initWithPattern:pattern options:OF_REGEX_NONE] autorelease]; }
+(OFRegex *)regexWithPattern:(OFString *)pattern options:(ofRegexOptions)options { return [[[OFRegex alloc] initWithPattern:pattern options:options      ] autorelease]; }
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(id)initWithPattern:(OFString *)pattern options:(ofRegexOptions)options
{
  self = [super init];
  if(self)
  {
    char *cpattern = (char *)[pattern UTF8String];
    options |= PCRE_UTF8 | PCRE_NO_UTF8_CHECK;
    char *errStr;
    _pcre = pcre_compile2(cpattern, options, &_code, (const char **)&errStr, &_offset, NULL);
    if(_pcre == NULL)
    {
      _error = [[OFString stringWithUTF8String:errStr] retain];
      _pcreExtra = NULL;
    }
    else
    {
      _error = nil;
      char *studyError;
      _pcreExtra = pcre_study(_pcre, 0, (const char **)&studyError);
      if(studyError != NULL) if(_pcreExtra != NULL) { pcre_free_study(_pcreExtra); _pcreExtra = NULL; }
    }
  }
  return self;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(void)dealloc
{
  if(_pcreExtra) pcre_free_study(_pcreExtra);
  if(_pcre)      pcre_free(_pcre);
  [_error release];
  [super dealloc];
}
//----------------------------------------------------------------------------------------------------------------------------------
+(OFString *)escapeString:(OFString *)string
{
  OFMutableString *wip = [[OFMutableString alloc] init];
  int len = string.length;
  for(int i=0; i<len; i++)
  {
    of_unichar_t ch = [string characterAtIndex:i];
    switch(ch)
    {
      case '\\': [wip appendString:@"\\\\"]; break;
      case '{' : [wip appendString:@"\\{" ]; break;
      case '}' : [wip appendString:@"\\}" ]; break;
      case '[' : [wip appendString:@"\\[" ]; break;
      case ']' : [wip appendString:@"\\]" ]; break;
      case '(' : [wip appendString:@"\\(" ]; break;
      case ')' : [wip appendString:@"\\)" ]; break;
      case '+' : [wip appendString:@"\\+" ]; break;
      case '*' : [wip appendString:@"\\*" ]; break;
      case '?' : [wip appendString:@"\\?" ]; break;
      case '^' : [wip appendString:@"\\^" ]; break;
      case '$' : [wip appendString:@"\\$" ]; break;
      case '.' : [wip appendString:@"\\." ]; break;
      case '-' : [wip appendString:@"\\-" ]; break;
      default  : [wip appendString:@" "]; [wip setCharacter:ch atIndex:wip.length - 1]; break;
    }
  }

  OFString *retval = [OFString stringWithString:wip];
  [wip release];
  return retval;
}
//----------------------------------------------------------------------------------------------------------------------------------
-(BOOL)matches:(OFString *)string
{
  int vectors[72];
  int status = pcre_exec(_pcre, _pcreExtra, [string UTF8String], string.length, 0, 0, vectors, 72);
  return (status > 0);
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(BOOL)matches:(OFString *)string fromIndex:(int)index
{
  //pcre_exec's startoffset uses byte positions, rather than character indices, for UTF8...
  int olen = string.length; if((index       ) >= olen) return NO;
  int slen = olen - index;  if((index + slen) >  olen) return NO;
  of_range_t range; range.location = index; range.length = slen;
  return [self matches:[string substringWithRange:range]];
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(OFArray *)execute:(OFString *)string
{
  char *cString = (char *)[string UTF8String];

  int status = -1, maxVectors = 16, *vectors = NULL, slen = string.length;
  while((status == -1) && (maxVectors < 4096))
  {
    maxVectors <<= 1; //start with 32 (*3) vectors
    if(vectors) free(vectors);
    vectors = (int *)malloc(sizeof(int) * (maxVectors * 3));
    if(vectors == NULL) return [OFArray array];
    status = pcre_exec(_pcre, _pcreExtra, cString, slen, 0, 0, vectors, (maxVectors * 3));
  }
  if(status < 1) { free(vectors); return [OFArray array]; } //give it up...

  OFMutableArray *working = [[OFMutableArray alloc] init];
  of_range_t rng;
  for(int i=0; i<status; i++)
  {
    rng.location  = vectors[i<<1];
    rng.length    = vectors[(i<<1)+1] - rng.location;
    [working addObject:[string substringWithRange:rng]];
    [working addObject:[OFNumber numberWithInt:(rng.location + rng.length)]];
  }
  free(vectors);

  OFArray *result = [[working copy] autorelease];
  [working release];
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(OFArray *) execute:(OFString *)string fromIndex:(int)index
{
  //pcre_exec's startoffset uses byte positions, rather than character indices, for UTF8...
  int olen = string.length; if((index       ) >= olen) return [OFArray array];
  int slen = olen - index;  if((index + slen) >  olen) return [OFArray array];
  of_range_t range; range.location = index; range.length = slen;
  char *cString = (char *)[[string substringWithRange:range] UTF8String];

  //nearly identical to above function
  int status = 0, maxVectors = 16, *vectors = NULL;
  while((status == 0) && (maxVectors < 4096))
  {
    maxVectors <<= 1; //start with 32 (*3) vectors
    if(vectors) free(vectors);
    vectors = (int *)malloc(sizeof(int) * (maxVectors * 3));
    if(vectors == NULL) return [OFArray array];
    status = pcre_exec(_pcre, _pcreExtra, cString, slen, 0, 0, vectors, (maxVectors * 3));
  }
  if(status < 1) { free(vectors); return [OFArray array]; } //give it up...

  OFMutableArray *working = [[OFMutableArray alloc] init];
  of_range_t rng;
  for(int i=0; i<status; i++)
  {
    rng.location  = vectors[i<<1];
    rng.length = vectors[(i<<1)+1] - rng.location;
    rng.location += index;
    [working addObject:[string substringWithRange:rng]];
    [working addObject:[OFNumber numberWithInt:(rng.location + rng.length)]];
  }

  OFArray *result = [[working copy] autorelease];
  [working release];
  return result;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(OFString *)replace:(OFString *)input withString:(OFString *)replacement globally:(BOOL)global
{
  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

  of_range_t rngReplacement, rngMatched, rngPre, rngPost;
  rngReplacement.location = 0; rngReplacement.length = replacement.length;

  OFMutableString *tmp, *result = [[OFMutableString alloc] init]; [result appendString:input];
  OFArray *matches = [self execute:result fromIndex:0];
  while(matches.count > 0)
  {
    //get component ranges (more than needed going on here...)
    rngMatched.length = [[matches objectAtIndex:0] length];
    rngMatched.location = [[matches objectAtIndex:1] intValue] - rngMatched.length;
    rngPre.location = 0;
    rngPre.length = rngMatched.location;
    rngPost.location = rngMatched.location + rngMatched.length;
    rngPost.length = result.length - (rngMatched.length + rngPre.length);
    //rebuild result string
    tmp = [[OFMutableString alloc] init];
    [tmp appendString:[result substringWithRange:rngPre]];
    [tmp appendString:replacement];
    [tmp appendString:[result substringWithRange:rngPost]];
    [result release];
    result = tmp;
    //manage ARP
    [pool drain];
    pool = [[OFAutoreleasePool alloc] init];
    //replace all occurrences?
    if(!global) break;
    //find next match
    matches = [self execute:result fromIndex:rngPre.length + rngReplacement.length];
  }

  [pool drain];
  OFString *retval = [OFString stringWithString:result];
  [result release];
  return retval;
}
//----------------------------------------------------------------------------------------------------------------------------------
-(OFString *)substitute:(OFString *)input withString:(OFString *)replacement globally:(BOOL)global
{
  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

  of_range_t rngReplacement, rngMatched, rngPre, rngPost;
  rngReplacement.location = 0;

  OFMutableString *tmpResult, *result = [[OFMutableString alloc] init]; [result appendString:input];
  OFString *tmpReplacement; int matchGroups, groupIdx;
  OFArray *matches = [self execute:result fromIndex:0];
  while(matches.count > 0)
  {
    //build replacement string (with substitutions)
    matchGroups = matches.count >> 1;
    tmpReplacement = [OFString stringWithString:replacement];
    for(groupIdx=0; groupIdx<matchGroups; groupIdx++)
      tmpReplacement = [tmpReplacement stringByReplacingOccurrencesOfString: [OFString stringWithFormat:@"$%d", groupIdx]
                                                                 withString: [matches objectAtIndex:groupIdx<<1]];
    rngReplacement.length = tmpReplacement.length;

    //get component ranges (more than needed going on here...)
    rngMatched.length = [[matches objectAtIndex:0] length];
    rngMatched.location  = [[matches objectAtIndex:1] intValue] - rngMatched.length;
    rngPre.location = 0;
    rngPre.length = rngMatched.location;
    rngPost.location = rngMatched.location + rngMatched.length;
    rngPost.length = result.length - (rngMatched.length + rngPre.length);
    //rebuild result string
    tmpResult = [[OFMutableString alloc] init];
    [tmpResult appendString:[result substringWithRange:rngPre]];
    [tmpResult appendString:tmpReplacement];
    [tmpResult appendString:[result substringWithRange:rngPost]];
    [result release];
    result = tmpResult;
    //manage ARP
    [pool drain];
    pool = [[OFAutoreleasePool alloc] init];
    //replace all occurrences?
    if(!global) break;
    //find next match
    matches = [self execute:result fromIndex:rngPre.length + rngReplacement.length];
  }

  [pool drain];
  OFString *retval = [OFString stringWithString:result];
  [result release];
  return retval;
}
//----------------------------------------------------------------------------------------------------------------------------------
-(OFString *)replaceEachMatch:(OFString *)input block:(replaceIterator)block data:(id)data
{
  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

  OFString *replacement;
  of_range_t rngReplacement, rngMatched, rngPre, rngPost;

  OFMutableString *tmp, *result = [[OFMutableString alloc] init]; [result appendString:input];
  OFArray *matches = [self execute:result fromIndex:0];
  while(matches.count > 0)
  {
    //get replacement string from block iterator
    replacement = block(result, matches, data);
    if(replacement == nil) break; //bail?
    rngReplacement.location = 0; rngReplacement.length = replacement.length;
    //get component ranges (more than needed going on here...)
    rngMatched.length = [[matches objectAtIndex:0] length];
    rngMatched.location  = [[matches objectAtIndex:1] intValue] - rngMatched.length;
    rngPre.location = 0;
    rngPre.length = rngMatched.location;
    rngPost.location = rngMatched.location + rngMatched.length;
    rngPost.length = result.length - (rngMatched.length + rngPre.length);
    //rebuild result string
    tmp = [[OFMutableString alloc] init];
    [tmp appendString:[result substringWithRange:rngPre]];
    [tmp appendString:replacement];
    [tmp appendString:[result substringWithRange:rngPost]];
    [result release];
    result = tmp;
    //manage ARP
    [pool drain];
    pool = [[OFAutoreleasePool alloc] init];
    //find next match
    matches = [self execute:result fromIndex:rngPre.length + rngReplacement.length];
  }

  [pool drain];
  OFString *retval = [OFString stringWithString:result];
  [result release];
  return retval;
}
//----------------------------------------------------------------------------------------------------------------------------------
@end

//==================================================================================================================================
//----------------------------------------------------------------------------------------------------------------------------------
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
