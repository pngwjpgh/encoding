module Test.Tests where

import Data.Encoding
import Data.Encoding.ASCII
import Data.Encoding.UTF8
import Data.Encoding.UTF16
import Test.Tester
import Test.HUnit

asciiTests :: Test
asciiTests = TestList $ map test $
	[EncodingTest ASCII
		"Hello, world!"
		[0x48,0x65,0x6C,0x6C,0x6F,0x2C,0x20,0x77,0x6F,0x72,0x6C,0x64,0x21]
	,EncodingError ASCII
		"\x0041\x2262\x0391\x002E"
		(HasNoRepresentation '\x2262')
	]

utf8Tests :: Test
utf8Tests = TestList $ map test $
	-- Simple encoding tests
	concat [[EncodingTest enc "\x0041\x2262\x0391\x002E"
		[0x41,0xE2,0x89,0xA2,0xCE,0x91,0x2E]
	,EncodingTest enc "\xD55C\xAD6D\xC5B4"
		[0xED,0x95,0x9C,0xEA,0xB5,0xAD,0xEC,0x96,0xB4]
	,EncodingTest enc "\x65E5\x672C\x8A9E"
		[0xE6,0x97,0xA5,0xE6,0x9C,0xAC,0xE8,0xAA,0x9E]
	,EncodingTest enc "\x233B4"
		[0xF0,0xA3,0x8E,0xB4]
	,EncodingTest enc ""
		[]
	-- First possible sequence of a certain length
	,EncodingTest enc "\x0000"
		[0x00]
	,EncodingTest enc "\x0080"
		[0xC2,0x80]
	,EncodingTest enc "\x0800"
		[0xE0,0xA0,0x80]
	,EncodingTest enc "\x10000"
		[0xF0,0x90,0x80,0x80]
	-- Last possible sequence of a certain length
	,EncodingTest enc "\x007F"
		[0x7F]
	,EncodingTest enc "\x07FF"
		[0xDF,0xBF]
	,EncodingTest enc "\xFFFF"
		[0xEF,0xBF,0xBF]
	-- Other boundaries
	,EncodingTest enc "\xD7FF"
		[0xED,0x9F,0xBF]
	,EncodingTest enc "\xE000"
		[0xEE,0x80,0x80]
	,EncodingTest enc "\xFFFD"
		[0xEF,0xBF,0xBD]
	-- Illegal starting characters
	,DecodingError enc
		[0x65,0x55,0x85]
		(IllegalCharacter 0x85)
	-- Unexpected end
	,DecodingError enc
		[0x41,0xE2,0x89,0xA2,0xCE]
		UnexpectedEnd
	,DecodingError enc
		[0x41,0xE2,0x89]
		UnexpectedEnd
	,DecodingError enc
		[0x41,0xE2]
		UnexpectedEnd]
	| enc <- [UTF8,UTF8Strict]
	]++
	[DecodingError UTF8 [0xFE] (IllegalCharacter 0xFE)
	,DecodingError UTF8 [0xFF] (IllegalCharacter 0xFF)
	-- Overlong representations of '/'
	,DecodingError UTF8Strict [0xC0,0xAF]
		(IllegalRepresentation [0xC0,0xAF])
	,DecodingError UTF8Strict [0xE0,0x80,0xAF]
		(IllegalRepresentation [0xE0,0x80,0xAF])
	,DecodingError UTF8Strict [0xF0,0x80,0x80,0xAF]
		(IllegalRepresentation [0xF0,0x80,0x80,0xAF])
	-- Maximum overlong sequences
	,DecodingError UTF8Strict [0xC1,0xBF]
		(IllegalRepresentation [0xC1,0xBF])
	,DecodingError UTF8Strict [0xE0,0x9F,0xBF]
		(IllegalRepresentation [0xE0,0x9F,0xBF])
	,DecodingError UTF8Strict [0xF0,0x8F,0xBF,0xBF]
		(IllegalRepresentation [0xF0,0x8F,0xBF,0xBF])
	-- Overlong represenations of '\NUL'
	,DecodingError UTF8Strict [0xC0,0x80]
		(IllegalRepresentation [0xC0,0x80])
	,DecodingError UTF8Strict [0xE0,0x80,0x80]
		(IllegalRepresentation [0xE0,0x80,0x80])
	,DecodingError UTF8Strict [0xF0,0x80,0x80,0x80]
		(IllegalRepresentation [0xF0,0x80,0x80,0x80])
	-- Invalid extends
	-- 2 of 2
	,DecodingError UTF8Strict [0xCC,0x1C,0xE0]
		(IllegalCharacter 0x1C)
	-- 2 of 3
	,DecodingError UTF8Strict [0xE3,0x6C,0xB3]
		(IllegalCharacter 0x6C)
	-- 3 of 3
	,DecodingError UTF8Strict [0xE3,0xB4,0x6D]
		(IllegalCharacter 0x6D)
	-- 2 of 4
	,DecodingError UTF8Strict [0xF2,0x6C,0xB3,0xB3]
		(IllegalCharacter 0x6C)
	-- 3 of 4
	,DecodingError UTF8Strict [0xF2,0xB3,0x6C,0xB3]
		(IllegalCharacter 0x6C)
	-- 4 of 4
	,DecodingError UTF8Strict [0xF2,0xB3,0xB3,0x6C]
		(IllegalCharacter 0x6C)
	]

utf16Tests :: Test
utf16Tests = TestList $ map test $
	[EncodingTest UTF16BE "z"
		[0x00,0x7A]
	,EncodingTest UTF16BE "\x6C34"
		[0x6C,0x34]
	,EncodingTest UTF16BE "\x1D11E"
		[0xD8,0x34,0xDD,0x1E]
	,EncodingTest UTF16 "\x6C34z\x1D11E"
		[0xFE,0xFF,0x6C,0x34,0x00,0x7A,0xD8,0x34,0xDD,0x1E]
	,EncodingTest UTF16BE "˨"
		[0x02,0xE8]
	,DecodingError UTF16LE [0x65,0xDC]
		(IllegalCharacter 0xDC)
	,DecodingError UTF16BE [0xDC]
		(IllegalCharacter 0xDC)
	,DecodingError UTF16BE [0xD9,0x78,0xDA]
		(IllegalCharacter 0xDA)
	,DecodingError UTF16BE [0xD9,0x78,0xDA,0x66]
		(IllegalCharacter 0xDA)
	]
