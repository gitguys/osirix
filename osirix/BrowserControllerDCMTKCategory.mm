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

#import "BrowserControllerDCMTKCategory.h"
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMTransferSyntax.h>
#import "AppController.h"

#undef verify
#include "osconfig.h" /* make sure OS specific configuration is included first */
#include "djdecode.h"  /* for dcmjpeg decoders */
#include "djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */
#include "djrploss.h"
#include "djrplol.h"
#include "dcpixel.h"
#include "dcrlerp.h"

#include "dcdatset.h"
#include "dcmetinf.h"
#include "dcfilefo.h"
#include "dcdebug.h"
#include "dcuid.h"
#include "dcdict.h"
#include "dcdeftag.h"

extern NSRecursiveLock *PapyrusLock;

@implementation BrowserController (BrowserControllerDCMTKCategory)

- (BOOL)compressDICOMWithJPEG:(NSString *)path
{
	DcmFileFormat fileformat;
	OFCondition cond = fileformat.loadFile( [path UTF8String]);
	// if we can't read it stop
	if (!cond.good())
		return NO;
	DcmDataset *dataset = fileformat.getDataset();
	DcmItem *metaInfo = fileformat.getMetaInfo();
	DcmXfer original_xfer(dataset->getOriginalXfer());
	if (original_xfer.isEncapsulated())
	{
		NSLog( @"file already compressed: %@", [path lastPathComponent]);
		return YES;
	}
			
	NSTask *theTask = [[NSTask alloc] init];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useJPEG2000forCompression"])
		[theTask setArguments: [NSArray arrayWithObjects:path, @"compressJPEG2000", nil]];
	else
		[theTask setArguments: [NSArray arrayWithObjects:path, @"compress", nil]];
		
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];

	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest deleteOriginal:(BOOL) deleteOriginal
{
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects:path, @"decompress", dest,  nil]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
	[theTask launch];
	
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	[theTask release];
	
	
	return YES;
}

- (BOOL)decompressDICOM:(NSString *)path to:(NSString*) dest
{
	return [self decompressDICOM: path to: dest deleteOriginal:YES];
}
@end
