//
//  OSIPoint3D.m
//  OsiriX
//
//  Created by Lance Pysher on 4/26/07.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OSIPoint3D.h"


@implementation OSIPoint3D

- (float)x{
	return _x;
}

- (float)y{
	return _y;
}
- (float)z{
	return _z;
}

- (void)setX:(float)x{
	_x = x;
}

- (void)setY:(float)y{
	_y = y;
}

- (void)setZ:(float)z{
	_z = z;
}

- (void) setX:(float)x y:(float)y z:(float)z{
	_x = x;
	_y = y;
	_z = z;
}

// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	if (self = [super init]) {
		_x = x;
		_y = y;
		_z = z;
		_value = [value retain];
	}
	return self;
}


// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	if (self = [super init]) {
		_x = point.x;
		_y = point.y;
		_z = (float)slice;
		_value = [value retain];
	}
	return self;
}

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value] autorelease];
}


+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value{
	return [[[OSIPoint3D alloc] initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value] autorelease];
}

- (NSNumber *)value {
	return _value;
}

- (void)setValue:(NSNumber *)value{
	[_value release];
	_value = [value retain];
}

- (void)dealloc{
	[_value release];
	[_userInfo release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"OSIPoint\nx = %2.1f y = %2.1f z = %2.1f value: %@", _x, _y, _z, _value];
}


- (void)setUserInfo:(id)userInfo{
	[_userInfo release];
	_userInfo = [userInfo retain];
}


- (id)userInfo{
	return _userInfo;
}

	



@end
