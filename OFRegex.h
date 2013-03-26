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
#import <ObjFW/ObjFW.h>

//==================================================================================================================================
typedef enum
{
  OF_REGEX_NONE             = 0x00000000, // 
  OF_REGEX_CASE_INSENSITIVE = 0x00000001, // PCRE_CASELESS
  OF_REGEX_MULTILINE        = 0x00000002, // PCRE_MULTILINE
  OF_REGEX_DOT_ALL          = 0x00000004, // PCRE_DOTALL
  OF_REGEX_EXTENDED         = 0x00000008, // PCRE_EXTENDED
  OF_REGEX_ANCHORED         = 0x00000010, // PCRE_ANCHORED
  OF_REGEX_DOLLAR_EOF       = 0x00000020, // PCRE_DOLLAR_ENDONLY
  OF_REGEX_EXTRA            = 0x00000040, // PCRE_EXTRA
  OF_REGEX_UNGREEDY         = 0x00000200, // PCRE_UNGREEDY
  OF_REGEX_NO_AUTOCAPTURE   = 0x00001000, // PCRE_NO_AUTO_CAPTURE
  OF_REGEX_AUTO_CALLOUT     = 0x00004000, // PCRE_AUTO_CALLOUT
  OF_REGEX_FIRSTLINE        = 0x00040000, // PCRE_FIRSTLINE
  OF_REGEX_DUPNAMES         = 0x00080000, // PCRE_DUPNAMES
  OF_REGEX_NEWLINE_CR       = 0x00100000, // PCRE_NEWLINE_CR
  OF_REGEX_NEWLINE_LF       = 0x00200000, // PCRE_NEWLINE_LF
  OF_REGEX_NEWLINE_CRLF     = 0x00300000, // PCRE_NEWLINE_CRLF
  OF_REGEX_NEWLINE_ANY      = 0x00400000, // PCRE_NEWLINE_ANY
  OF_REGEX_NEWLINE_ANYCRLF  = 0x00500000, // PCRE_NEWLINE_ANYCRLF
  OF_REGEX_R_ANYCRLF        = 0x00800000, // PCRE_BSR_ANYCRLF
  OF_REGEX_R_UNICODE        = 0x01000000, // PCRE_BSR_UNICODE
  OF_REGEX_JAVASCRIPT       = 0x02000000, // PCRE_JAVASCRIPT_COMPAT
  OF_REGEX_UCP              = 0x20000000  // PCRE_UCP
} ofRegexOptions;
//----------------------------------------------------------------------------------------------------------------------------------
typedef OFString *(^replaceIterator)(OFString *input, OFArray *matches, id data);

//==================================================================================================================================
@interface OFRegex : OFObject
//----------------------------------------------------------------------------------------------------------------------------------
{
  void        *_pcre;
  void        *_pcreExtra;
  OFString    *_error;
  int          _code;
  int          _offset;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@property (readonly) OFString  *error;
@property (readonly) int        code;
@property (readonly) int        offset;
@property (readonly) BOOL       valid;
//----------------------------------------------------------------------------------------------------------------------------------
+ regexWithPattern:(OFString *)pattern;
+ regexWithPattern:(OFString *)pattern options:(ofRegexOptions)options;
- initWithPattern :(OFString *)pattern options:(ofRegexOptions)options;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
+(OFString *) escapeString:(OFString *)string;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-(BOOL)       matches:(OFString *)string;
-(BOOL)       matches:(OFString *)string fromIndex:(int)index;
-(OFArray *)  execute:(OFString *)string;
-(OFArray *)  execute:(OFString *)string fromIndex:(int)index;
-(OFString *) replace:(OFString *)input  withString:(OFString *)replacement globally:(BOOL)global;
-(OFString *) substitute:(OFString *)input withString:(OFString *)replacement globally:(BOOL)global;
-(OFString *) replaceEachMatch:(OFString *)input block:(replaceIterator)block data:(id)data;
//-(OFString *) replaceEachMatch:(OFString *)input delegate:(id)delegate selector:(SEL)selector;
@end

//==================================================================================================================================
//----------------------------------------------------------------------------------------------------------------------------------
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
