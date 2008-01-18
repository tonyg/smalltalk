"=====================================================================
|
|   MySQL DBI driver - ColumnInfo class
|
|
 ======================================================================"

"======================================================================
|
| Copyright 2002 Josh Miller
| Written by Josh Miller, ported by Markus Fritsche,
| refactored/rewritten by Paolo Bonzini
|
| This file is part of GNU Smalltalk.
|
| The GNU Smalltalk class library is free software; you can redistribute it
| and/or modify it under the terms of the GNU Lesser General Public License
| as published by the Free Software Foundation; either version 2.1, or (at
| your option) any later version.
| 
| The GNU Smalltalk class library is distributed in the hope that it will be
| useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
| General Public License for more details.
| 
| You should have received a copy of the GNU Lesser General Public License
| along with the GNU Smalltalk class library; see the file COPYING.LIB.
| If not, write to the Free Software Foundation, 59 Temple Place - Suite
| 330, Boston, MA 02110-1301, USA.  
|
 ======================================================================"



ColumnInfo subclass: MySQLColumnInfo [
    | table name size type flags decimalPlaces charset index |
    
    <comment: nil>
    <category: 'Mysql-Driver'>

    Types := nil.
    ConverterSelectors := nil.
    TypeNames := nil.

    MySQLColumnInfo class >> writeBoolean: aBoolean on: aStream [
	<category: 'converting-smalltalk'>
	aBoolean 
	    ifTrue: [aStream nextPutAll: 'True']
	    ifFalse: [aStream nextPutAll: 'False']
    ]

    MySQLColumnInfo class >> writeDate: aDate on: aStream [
	<category: 'converting-smalltalk'>
	self printMysqlDate: aDate on: aStream
    ]

    MySQLColumnInfo class >> writeDouble: aDouble on: aStream [
	<category: 'converting-smalltalk'>
	| readStream character |
	readStream := ReadStream on: aDouble printString.
	
	[character := readStream next.
	character isNil] whileFalse: 
		    [character = $d 
			ifTrue: 
			    [character := readStream next.
			    character isNil ifTrue: [^self].
			    aStream nextPut: $e.
			    character = $- ifFalse: [aStream nextPut: $+]].
		    aStream nextPut: character]
    ]

    MySQLColumnInfo class >> writeFloat: aFloat on: aStream [
	<category: 'converting-smalltalk'>
	| readStream character |
	readStream := ReadStream on: aFloat printString.
	
	[character := readStream next.
	character isNil] whileFalse: 
		    [character = $e 
			ifTrue: 
			    [aStream nextPut: character.
			    character := readStream next.
			    character = $- ifFalse: [aStream nextPut: $+]].
		    aStream nextPut: character]
    ]

    MySQLColumnInfo class >> writeMySQLDateTime: aMySQLDateTime on: aStream [
	<category: 'converting-smalltalk'>
	self writeDate: aMySQLDateTime asDate on: aStream.
	aStream nextPut: $ .
	self writeTime: aMySQLDateTime asTime on: aStream
    ]

    MySQLColumnInfo class >> writeQuotedDate: aDate on: aStream [
	<category: 'converting-smalltalk'>
	aStream nextPut: $'.
	self writeDate: aDate on: aStream.
	aStream nextPut: $'
    ]

    MySQLColumnInfo class >> writeQuotedTime: aTime on: aStream [
	<category: 'converting-smalltalk'>
	aStream nextPut: $'.
	self writeTime: aTime on: aStream.
	aStream nextPut: $'
    ]

    MySQLColumnInfo class >> writeQuotedTimestamp: aTimestamp on: aStream [
	<category: 'converting-smalltalk'>
	aStream nextPut: $'.
	self writeMySQLDateTime: aTimestamp on: aStream.
	aStream nextPut: $'
    ]

    MySQLColumnInfo class >> writeTime: aTime on: aStream [
	<category: 'converting-smalltalk'>
	self printMysqlTime: aTime on: aStream
    ]

    MySQLColumnInfo class >> writeTimestamp: aTimestamp on: aStream [
	<category: 'converting-smalltalk'>
	self printMysqlTimestamp: aTimestamp on: aStream
    ]

    MySQLColumnInfo class >> convertToMysql: aValue [
	<category: 'actions'>
	| writeStream |
	writeStream := WriteStream on: String new.
	self convertToMysql: aValue on: writeStream.
	^writeStream contents
    ]

    MySQLColumnInfo class >> convertToMysql: aValue on: aStream [
	<category: 'actions'>
	| aSelector |
	aSelector := ConverterSelectors at: aValue class name
		    ifAbsent: 
			[aValue printOn: aStream.
			^self].
	^self 
	    perform: aSelector
	    with: aValue
	    with: aStream
    ]

    MySQLColumnInfo class >> buildConversionMap [
	<category: 'private-initialize'>
	ConverterSelectors := IdentityDictionary new.
	ConverterSelectors
	    at: #Boolean put: #writeBoolean:on:;
	    at: #FloatD put: #writeDouble:on:;
	    at: #FloatE put: #writeFloat:on:;
	    at: #Time put: #writeQuotedTime:on:;
	    at: #DateTime put: #writeQuotedTimestamp:on:;
	    at: #Date put: #writeQuotedDate:on:
    ]

    MySQLColumnInfo class >> buildTypeNameMap [
	<category: 'private-initialize'>
	TypeNames := Dictionary new.
	TypeNames
	    at: MySQLColumnInfo bitType put: 'bit';
	    at: MySQLColumnInfo tinyType put: 'tinyint';
	    at: MySQLColumnInfo shortType put: 'smallint';
	    at: MySQLColumnInfo int24Type put: 'mediumint';
	    at: MySQLColumnInfo longType put: 'int';
	    at: MySQLColumnInfo longlongType put: 'bigint';
	    at: MySQLColumnInfo floatType put: 'float(4)';
	    at: MySQLColumnInfo doubleType put: 'float(8)';
	    at: MySQLColumnInfo oldDecimalType put: 'decimal';
	    at: MySQLColumnInfo decimalType put: 'decimal';
	    at: MySQLColumnInfo newDateType put: 'date';
	    at: MySQLColumnInfo dateType put: 'date';
	    at: MySQLColumnInfo datetimeType put: 'datetime';
	    at: MySQLColumnInfo timeType put: 'time';
	    at: MySQLColumnInfo timestampType put: 'timestamp';
	    at: MySQLColumnInfo enumType put: 'enum';
	    at: MySQLColumnInfo setType put: 'set';
	    at: MySQLColumnInfo tinyBlobType put: 'tinyblob';
	    at: MySQLColumnInfo mediumBlobType put: 'mediumblob';
	    at: MySQLColumnInfo longBlobType put: 'longblob';
	    at: MySQLColumnInfo blobType put: 'blob';
	    at: MySQLColumnInfo varCharType put: 'varchar';
	    at: MySQLColumnInfo varStringType put: 'varchar';
	    at: MySQLColumnInfo stringType put: 'string'
    ]

    MySQLColumnInfo class >> buildTypeMap [
	<category: 'private-initialize'>
	Types := Dictionary new.
	Types
	    at: MySQLColumnInfo bitType put: #toBoolean:;
	    at: MySQLColumnInfo tinyType put: #toInteger:;
	    at: MySQLColumnInfo shortType put: #toInteger:;
	    at: MySQLColumnInfo longType put: #toInteger:;
	    at: MySQLColumnInfo int24Type put: #toInteger:;
	    at: MySQLColumnInfo longlongType put: #toInteger:;
	    at: MySQLColumnInfo floatType put: #toFloat:;
	    at: MySQLColumnInfo doubleType put: #toDouble:;
	    at: MySQLColumnInfo oldDecimalType put: #toDouble:;
	    at: MySQLColumnInfo decimalType put: #toDouble:;
	    at: MySQLColumnInfo newDateType put: #toDate:;
	    at: MySQLColumnInfo dateType put: #toDate:;
	    at: MySQLColumnInfo datetimeType put: #toDateTime:;
	    at: MySQLColumnInfo timeType put: #toTime:;
	    at: MySQLColumnInfo timestampType put: #toTimestamp:;
	    at: MySQLColumnInfo enumType put: #toString:;
	    at: MySQLColumnInfo setType put: #toSet:;
	    at: MySQLColumnInfo tinyBlobType put: #toByteArray:;
	    at: MySQLColumnInfo mediumBlobType put: #toByteArray:;
	    at: MySQLColumnInfo longBlobType put: #toByteArray:;
	    at: MySQLColumnInfo blobType put: #toByteArray:;
	    at: MySQLColumnInfo varCharType put: #toString:;
	    at: MySQLColumnInfo varStringType put: #toString:;
	    at: MySQLColumnInfo stringType put: #toString:
    ]

    MySQLColumnInfo class >> initialize [
	<category: 'initialize-release'>
	self
	    buildTypeMap;
	    buildTypeNameMap;
	    buildConversionMap
    ]

    MySQLColumnInfo class >> readDateFrom: aStream [
	<category: 'reading mysql'>
	| day month year |
	year := Integer readFrom: aStream.
	aStream next.
	month := Integer readFrom: aStream.
	aStream next.
	day := Integer readFrom: aStream.
	^Date 
	    newDay: day
	    monthIndex: month
	    year: year
    ]

    MySQLColumnInfo class >> readTimeFrom: aStream [
	<category: 'reading mysql'>
	| hour minute second |
	hour := Integer readFrom: aStream.
	aStream next.
	minute := Integer readFrom: aStream.
	aStream next.
	second := Integer readFrom: aStream.
	^Time fromSeconds: 60 * (60 * hour + minute) + second
    ]

    MySQLColumnInfo class >> readTimestampFrom: aStream [
	<category: 'reading mysql'>
	| year month day hour minute second separators |
	year := self readIntegerFrom: aStream next: 4.
	separators := aStream peekFor: $-.
	month := self readIntegerFrom: aStream next: 2.
	separators ifTrue: [aStream next].
	day := self readIntegerFrom: aStream next: 2.
	separators ifTrue: [aStream next].
	hour := self readIntegerFrom: aStream next: 2.
	separators ifTrue: [aStream next].
	minute := self readIntegerFrom: aStream next: 2.
	separators ifTrue: [aStream next].
	second := self readIntegerFrom: aStream next: 2.
	^DateTime 
	    fromDays: (Date 
		    newDay: day
		    monthIndex: month
		    year: year) days
	    seconds: 3600 * hour + (60 * minute) + second
	    offset: Duration zero
    ]

    MySQLColumnInfo class >> readIntegerFrom: aStream next: anInteger [
	<category: 'private-reading'>
	^Integer readFrom: (ReadStream on: (aStream next: anInteger))
    ]

    MySQLColumnInfo class >> printMysqlDate: aDate on: aStream [
	<category: 'reading mysql'>
	aDate year printOn: aStream.
	aStream nextPut: $-.
	self 
	    print: aDate month
	    on: aStream
	    next: 2.
	aStream nextPut: $-.
	self 
	    print: aDate day
	    on: aStream
	    next: 2
    ]

    MySQLColumnInfo class >> printMysqlTime: aTime on: aStream [
	<category: 'reading mysql'>
	self 
	    print: aTime hour
	    on: aStream
	    next: 2.
	aStream nextPut: $:.
	self 
	    print: aTime minute
	    on: aStream
	    next: 2.
	aStream nextPut: $:.
	self 
	    print: aTime second
	    on: aStream
	    next: 2
    ]

    MySQLColumnInfo class >> printMysqlTimestamp: aDateTime on: aStream [
	<category: 'reading mysql'>
	self 
	    print: aDateTime year
	    on: aStream
	    next: 4.
	self 
	    print: aDateTime month
	    on: aStream
	    next: 2.
	self 
	    print: aDateTime day
	    on: aStream
	    next: 2.
	self 
	    print: aDateTime hour
	    on: aStream
	    next: 2.
	self 
	    print: aDateTime minute
	    on: aStream
	    next: 2.
	self 
	    print: aDateTime second
	    on: aStream
	    next: 2
    ]

    MySQLColumnInfo class >> print: anInteger on: aStream next: n [
	<category: 'private-writing'>
	| str |
	str := anInteger printString.
	aStream next: n - str size put: $0.
	aStream nextPutAll: str
    ]

    MySQLColumnInfo class >> bitType [
	<category: 'constants-types'>
	^16
    ]

    MySQLColumnInfo class >> blobType [
	<category: 'constants-types'>
	^252
    ]

    MySQLColumnInfo class >> datetimeType [
	<category: 'constants-types'>
	^12
    ]

    MySQLColumnInfo class >> newDateType [
	<category: 'constants-types'>
	^14
    ]

    MySQLColumnInfo class >> dateType [
	<category: 'constants-types'>
	^10
    ]

    MySQLColumnInfo class >> oldDecimalType [
	<category: 'constants-types'>
	^0
    ]

    MySQLColumnInfo class >> decimalType [
	<category: 'constants-types'>
	^246
    ]

    MySQLColumnInfo class >> doubleType [
	<category: 'constants-types'>
	^5
    ]

    MySQLColumnInfo class >> enumType [
	<category: 'constants-types'>
	^247
    ]

    MySQLColumnInfo class >> floatType [
	<category: 'constants-types'>
	^4
    ]

    MySQLColumnInfo class >> int24Type [
	<category: 'constants-types'>
	^9
    ]

    MySQLColumnInfo class >> longBlobType [
	<category: 'constants-types'>
	^251
    ]

    MySQLColumnInfo class >> longlongType [
	<category: 'constants-types'>
	^8
    ]

    MySQLColumnInfo class >> longType [
	<category: 'constants-types'>
	^3
    ]

    MySQLColumnInfo class >> mediumBlobType [
	<category: 'constants-types'>
	^250
    ]

    MySQLColumnInfo class >> nullType [
	<category: 'constants-types'>
	^6
    ]

    MySQLColumnInfo class >> setType [
	<category: 'constants-types'>
	^248
    ]

    MySQLColumnInfo class >> shortType [
	<category: 'constants-types'>
	^2
    ]

    MySQLColumnInfo class >> stringType [
	<category: 'constants-types'>
	^254
    ]

    MySQLColumnInfo class >> timestampType [
	<category: 'constants-types'>
	^7
    ]

    MySQLColumnInfo class >> timeType [
	<category: 'constants-types'>
	^11
    ]

    MySQLColumnInfo class >> tinyBlobType [
	<category: 'constants-types'>
	^249
    ]

    MySQLColumnInfo class >> tinyType [
	<category: 'constants-types'>
	^1
    ]

    MySQLColumnInfo class >> varCharType [
	<category: 'constants-types'>
	^15
    ]

    MySQLColumnInfo class >> varStringType [
	<category: 'constants-types'>
	^253
    ]

    MySQLColumnInfo class >> yearType [
	<category: 'constants-types'>
	^13
    ]

    MySQLColumnInfo class >> autoIncrementFlag [
	<category: 'constants-flags'>
	^512
    ]

    MySQLColumnInfo class >> binaryFlag [
	<category: 'constants-flags'>
	^128
    ]

    MySQLColumnInfo class >> blobFlag [
	<category: 'constants-flags'>
	^16
    ]

    MySQLColumnInfo class >> enumFlag [
	<category: 'constants-flags'>
	^256
    ]

    MySQLColumnInfo class >> multipleKeyFlag [
	<category: 'constants-flags'>
	^8
    ]

    MySQLColumnInfo class >> notNullFlag [
	<category: 'constants-flags'>
	^1
    ]

    MySQLColumnInfo class >> primaryKeyFlag [
	<category: 'constants-flags'>
	^2
    ]

    MySQLColumnInfo class >> timestampFlag [
	<category: 'constants-flags'>
	^1024
    ]

    MySQLColumnInfo class >> uniqueKeyFlag [
	<category: 'constants-flags'>
	^4
    ]

    MySQLColumnInfo class >> unsignedFlag [
	<category: 'constants-flags'>
	^32
    ]

    MySQLColumnInfo class >> zerofillFlag [
	<category: 'constants-flags'>
	^64
    ]

    MySQLColumnInfo class >> readFrom: aReadStream [
	<category: 'instance creation'>
	^self new readFrom: aReadStream
    ]

    hasFlag: aFlag [
	<category: 'testing'>
	^(self flags bitAnd: aFlag) > 0
    ]

    isAutoIncrement [
	<category: 'testing'>
	^self hasFlag: self class autoIncrementFlag
    ]

    isBinary [
	<category: 'testing'>
	^self hasFlag: self class binaryFlag
    ]

    isBlob [
	<category: 'testing'>
	^self hasFlag: self class blobFlag
    ]

    isEnumeration [
	<category: 'testing'>
	^self hasFlag: self class enumFlag
    ]

    isMultipleKey [
	<category: 'testing'>
	^self hasFlag: self class multipleKeyFlag
    ]

    isNotNull [
	<category: 'testing'>
	^self hasFlag: self class notNullFlag
    ]

    isPrimaryKey [
	<category: 'testing'>
	^self hasFlag: self class primaryKeyFlag
    ]

    isTimestamp [
	<category: 'testing'>
	^self hasFlag: self class timestampFlag
    ]

    isUniqueKey [
	<category: 'testing'>
	^self hasFlag: self class uniqueKeyFlag
    ]

    isZerofill [
	<category: 'testing'>
	^self hasFlag: self class zerofillFlag
    ]

    decimalPlaces [
	<category: 'accessing'>
	^decimalPlaces
    ]

    flags [
	<category: 'accessing'>
	^flags
    ]

    index [
	<category: 'accessing'>
	^index
    ]

    name [
	<category: 'accessing'>
	^name
    ]

    size [
	<category: 'accessing'>
	^size
    ]

    table [
	<category: 'accessing'>
	^table
    ]

    type [
	<category: 'accessing'>
	^TypeNames at: type
    ]

    convert: aValue [
	<category: 'actions'>
	^self perform: (Types at: type) with: aValue
    ]

    toBoolean: aString [
	<category: 'converting'>
	aString isNil ifTrue: [^nil].
	^aString first value = 1
    ]

    toByteArray: aString [
	<category: 'converting'>
	^self isBinary 
	    ifTrue: [aString isNil ifTrue: [nil] ifFalse: [aString asByteArray]]
	    ifFalse: [aString]
    ]

    toDate: aString [
	<category: 'converting'>
	^self class readDateFrom: (ReadStream on: aString)
    ]

    toDateTime: aString [
	<category: 'converting'>
	^self class readTimestampFrom: aString readStream
    ]

    toDouble: aString [
	<category: 'converting'>
	| aStream writeStream character |
	aStream := ReadStream on: aString.
	writeStream := WriteStream on: String new.
	
	[character := aStream next.
	character isNil] whileFalse: 
		    [character = $e 
			ifTrue: 
			    [writeStream nextPut: $d.
			    character := aStream next.
			    character = $+ ifTrue: [character := aStream next]].
		    writeStream nextPut: character].
	^FloatD readFrom: (ReadStream on: writeStream contents)
    ]

    toFloat: aString [
	<category: 'converting'>
	| writeStream character aStream |
	aStream := ReadStream on: aString.
	writeStream := WriteStream on: String new.
	
	[character := aStream next.
	character isNil] 
		whileFalse: [character = $+ ifFalse: [writeStream nextPut: character]].
	^FloatE readFrom: (ReadStream on: writeStream contents)
    ]

    toInteger: aString [
	<category: 'converting'>
	^Integer readFrom: (ReadStream on: aString)
    ]

    toString: aString [
	<category: 'converting'>
	^aString
    ]

    toTime: aString [
	<category: 'converting'>
	^self class readTimeFrom: (ReadStream on: aString)
    ]

    toTimestamp: aString [
	<category: 'converting'>
	^self class readTimestampFrom: (ReadStream on: aString)
    ]

    charset [
	<category: 'reading'>
	^charset
    ]

    readDecimalPlaces: aReadStream [
	<category: 'reading'>
	decimalPlaces := aReadStream next asInteger
    ]

    readFlags: aReadStream [
	<category: 'reading'>
	flags := (aReadStream next: 2) asByteArray asInteger
    ]

    readFrom: aReadStream index: i [
	<category: 'reading'>
	"can be catalogue, db, table, org table, field (and org field follows)
	 or table, field, length, type, flags+decimal"

	| length fields |
	index := i.
	fields := (1 to: 5) 
		    collect: [:i | aReadStream next: aReadStream next asInteger].
	aReadStream atEnd 
	    ifFalse: 
		[table := fields at: 3.
		name := fields at: 5.
		"org field"
		aReadStream next: aReadStream next asInteger.
		length := aReadStream next asInteger - 10.
		self
		    readCharset: aReadStream;
		    readSize: aReadStream;
		    readType: aReadStream;
		    readFlags: aReadStream;
		    readDecimalPlaces: aReadStream.
		aReadStream next: length.
		^self].

	"MySQL 3.x format."
	table := fields at: 1.
	name := fields at: 2.
	size := (fields at: 3) asByteArray asInteger.
	type := (fields at: 4) first asInteger.
	self readFlags: (fields at: 5) readStream.
	decimalPlaces := (fields at: 5) last asInteger
    ]

    readCharset: aReadStream [
	<category: 'reading'>
	charset := (aReadStream next: 2) asByteArray asInteger
    ]

    readName: aReadStream [
	<category: 'reading'>
	name := aReadStream next: aReadStream next asInteger
    ]

    readSize: aReadStream [
	<category: 'reading'>
	size := (aReadStream next: 4) asByteArray asInteger
    ]

    readTable: aReadStream [
	<category: 'reading'>
	table := aReadStream next: aReadStream next asInteger
    ]

    readType: aReadStream [
	<category: 'reading'>
	type := aReadStream next asInteger
    ]
]



Eval [
    MySQLColumnInfo initialize
]
