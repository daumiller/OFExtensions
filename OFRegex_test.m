/*==================================================================================================================================
Copyright © 2013, Dillon Aumiller <dillonaumiller@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
==================================================================================================================================*/

#import <stdio.h>
#import <ObjFW/ObjFW.h>
#import "OFRegex.h"

int main(int argc, char **argv)
{
  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

  OFRegex *rxA  = [OFRegex regexWithPattern:@"0x[0-9]+"    ];
  OFRegex *rxB  = [OFRegex regexWithPattern:@"([a-zA-Z])([a-zA-Z])([a-zA-Z]+)"   ];
  OFRegex *rxC  = [OFRegex regexWithPattern:@"failure"     ];
  OFRegex *rxD  = [OFRegex regexWithPattern:@"eee\\s"      ];
  OFRegex *rxE  = [OFRegex regexWithPattern:@"([a-zA-Z]+)\\s+([a-zA-Z]+)"];
  OFRegex *rxF  = [OFRegex regexWithPattern:@"e"];
  OFString *tst = @"Helloeee Worldeee of 32 (0x10) Hexadecimaleee Numbers";
  
  OFString *result; OFArray *matches;
  
  result = [OFString stringWithFormat:@"rxA DOES%@ match.", (([rxA matches:tst]) ? (@"") : (@" NOT"))]; printf("%s\n", [result UTF8String]);
  result = [OFString stringWithFormat:@"rxB DOES%@ match.", (([rxB matches:tst]) ? (@"") : (@" NOT"))]; printf("%s\n", [result UTF8String]);
  result = [OFString stringWithFormat:@"rxC DOES%@ match.", (([rxC matches:tst]) ? (@"") : (@" NOT"))]; printf("%s\n", [result UTF8String]);
  printf("\n");

  matches = [rxA execute:tst]; for(int i=0; i<matches.count; i+=2) printf("rxA.match[%d/%lu] == \"%s\"\n", (i>>1)+1, matches.count>>1, [[matches objectAtIndex:i] UTF8String]);
  matches = [rxB execute:tst]; for(int i=0; i<matches.count; i+=2) printf("rxB.match[%d/%lu] == \"%s\"\n", (i>>1)+1, matches.count>>1, [[matches objectAtIndex:i] UTF8String]);
  matches = [rxC execute:tst]; for(int i=0; i<matches.count; i+=2) printf("rxC.match[%d/%lu] == \"%s\"\n", (i>>1)+1, matches.count>>1, [[matches objectAtIndex:i] UTF8String]);
  printf("\n");

  int maxLen = tst.length;
  int index = 0, count = 0;
  matches = [rxB execute:tst fromIndex:index];
  while((matches.count > 0) && (index < maxLen))
  {
    printf("string[%d (%d)] == \"%s\"\n", count++, index, [[matches objectAtIndex:0] UTF8String]);
    index = [[matches objectAtIndex:1] intValue];
    matches = [rxB execute:tst fromIndex:index];
  }
  printf("\n");

  printf("Before \"%s\"\n", [tst UTF8String]);
  OFString *after = [rxD replace:tst withString:@" " globally:YES];
  printf("After \"%s\"\n", [after UTF8String]);
  after = [rxE substitute:after withString:@"$2 $1" globally:NO];
  printf("After \"%s\"\n", [after UTF8String]);
  after = [rxE substitute:after withString:@"$2 $1" globally:YES];
  printf("After \"%s\"\n", [after UTF8String]);
  //testReplacer *replacer = [[[testReplacer alloc] init] autorelease];
  __block int reCount = 0;
  after = [rxF replaceEachMatch: after
                          block: ^(OFString *input, OFArray *matches, id data) { return [OFString stringWithFormat:@"(%@:%d)", [matches objectAtIndex:0], reCount++]; }
                           data: nil ];
  printf("After \"%s\"\n", [after UTF8String]);
  printf("\n");

  [pool drain];
}
