#import <Foundation/Foundation.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCM.h>
#import <OsiriX/DCMTransferSyntax.h>
#import <OsiriX/DCMPixelDataAttribute.h>
#import "DefaultsOsiriX.h"
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

extern void dcmtkSetJPEGColorSpace( int);

// WHY THIS EXTERNAL APPLICATION FOR COMPRESS OR DECOMPRESSION?

// Because if a file is corrupted, it will not crash the OsiriX application, but only this small task.

int compressionForModality( NSArray *array, NSArray *arrayLow, int limit, NSString* mod, int* quality, int resolution)
{
	NSArray *s;
	if( resolution < limit)
		s = arrayLow;
	else
		s = array;
	
	for( NSDictionary *dict in s)
	{
		if( [[dict valueForKey: @"modality"] isEqualToString: mod])
		{
			int compression = compression_none;
			if( [[dict valueForKey: @"compression"] intValue] == compression_sameAsDefault)
				dict = [s objectAtIndex: 0];
			
			compression = [[dict valueForKey: @"compression"] intValue];
			
			if( quality)
			{
				if( compression == compression_JPEG2000)
					*quality = [[dict valueForKey: @"quality"] intValue];
				else
					*quality = 0;
			}
			
			return compression;
		}
	}
	
	if( [s count] == 0)
		return compression_none;
	
	if( quality)
		*quality = [[[s objectAtIndex: 0] valueForKey: @"quality"] intValue];
	
	return [[[s objectAtIndex: 0] valueForKey: @"compression"] intValue];
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	//	argv[ 1] : in path
	//	argv[ 2] : out path
	//	argv[ 2] : what? compress or decompress?
	
	if( argv[ 1] && argv[ 2])
	{
		// register global JPEG decompression codecs
		DJDecoderRegistration::registerCodecs();

		// register global JPEG compression codecs
		DJEncoderRegistration::registerCodecs(
			ECC_lossyYCbCr,
			EUC_default,
			OFFalse,
			OFFalse,
			0,
			0,
			0,
			OFTrue,
			ESS_444,
			OFFalse,
			OFFalse,
			0,
			0,
			0.0,
			0.0,
			0,
			0,
			0,
			0,
			OFTrue,
			OFFalse,
			OFFalse,
			OFFalse,
			OFTrue);

		// register RLE compression codec
		DcmRLEEncoderRegistration::registerCodecs();

		// register RLE decompression codec
		DcmRLEDecoderRegistration::registerCodecs();
		
		NSString	*path = [NSString stringWithCString:argv[ 1]];
		NSString	*what = [NSString stringWithCString:argv[ 2]];
		
		if( [what isEqualToString:@"compress"])
		{
			int quality = [[NSString stringWithCString:argv[ 3]] intValue];
			
			NSMutableDictionary	*dict = [DefaultsOsiriX getDefaults];
			[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
			
			dcmtkSetJPEGColorSpace( [[dict objectForKey:@"UseJPEGColorSpace"] intValue]);
			[DCMPixelDataAttribute setUseOpenJpeg: [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue]];
			
			NSArray *compressionSettings = [dict valueForKey: @"CompressionSettings"];
			NSArray *compressionSettingsLowRes = [dict valueForKey: @"CompressionSettingsLowRes"];
			
			int limit = [[dict objectForKey: @"CompressionResolutionLimit"] intValue];
			
			NSString *destDirec;
			if( [path isEqualToString: @"sameAsDestination"])
				destDirec = nil;
			else
				destDirec = path;
			
			int i;
			for( i = 3; i < argc; i++)
			{
				NSString *curFile = [NSString stringWithCString:argv[ i]];
				OFBool status = YES;
				NSString *curFileDest;
				
				if( destDirec)
					curFileDest = [destDirec stringByAppendingPathComponent: [curFile lastPathComponent]];
				else
					curFileDest = [curFile stringByAppendingString: @" temp"];
				
				DcmFileFormat fileformat;
				OFCondition cond = fileformat.loadFile( [curFile UTF8String]);
				// if we can't read it stop
				if( cond.good())
				{
					DcmDataset *dataset = fileformat.getDataset();
					DcmItem *metaInfo = fileformat.getMetaInfo();
					DcmXfer original_xfer(dataset->getOriginalXfer());
					if (original_xfer.isEncapsulated())
					{
						if( destDirec)
						{
							[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
							[[NSFileManager defaultManager] movePath: curFile toPath: curFileDest handler: nil];
							[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
						}
						NSLog( @"file already compressed: %@", [curFile lastPathComponent]);
					}
					else
					{
						const char *string = NULL;
						NSString *modality;
						if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL)
							modality = [NSString stringWithCString:string encoding: NSASCIIStringEncoding];
						else
							modality = @"OT";
						
						int resolution = 0;
						unsigned short rows = 0;
						if (dataset->findAndGetUint16( DCM_Rows, rows, OFFalse).good())
						{
							if( resolution == 0 || resolution > rows)
								resolution = rows;
						}
						unsigned short columns = 0;
						if (dataset->findAndGetUint16( DCM_Columns, columns, OFFalse).good())
						{
							if( resolution == 0 || resolution > columns)
								resolution = columns;
						}
						
						int quality, compression = compressionForModality( compressionSettings, compressionSettingsLowRes, limit, modality, &quality, resolution);
						
						if( compression == compression_JPEG2000)
						{
							DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData:YES];
							
							BOOL succeed = NO;
							
							@try
							{
								DCMTransferSyntax *tsx = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
								succeed = [dcmObject writeToFile: curFileDest withTransferSyntax: tsx quality: quality AET:@"OsiriX" atomically:YES];
							}
							@catch (NSException *e)
							{
								NSLog( @"dcmObject writeToFile failed: %@", e);
							}
							[dcmObject release];
							
							if( succeed)
							{
								[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
								
								if( destDirec == nil)
									[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
							}
							else
							{
								NSLog( @"failed to compress file: %@", curFile);
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
							}
						}
						else if( compression == compression_JPEG)
						{
							DJ_RPLossless losslessParams(6,0);
							
							DcmRepresentationParameter *params = &losslessParams;
							E_TransferSyntax tSyntax = EXS_JPEGProcess14SV1TransferSyntax;
							
							// this causes the lossless JPEG version of the dataset to be created
							DcmXfer oxferSyn( tSyntax);
							dataset->chooseRepresentation(tSyntax, params);
							
							// check if everything went well
							if (dataset->canWriteXfer(tSyntax))
							{
								// force the meta-header UIDs to be re-generated when storing the file 
								// since the UIDs in the data set may have changed 
								
								//only need to do this for lossy
								delete metaInfo->remove(DCM_MediaStorageSOPClassUID);
								delete metaInfo->remove(DCM_MediaStorageSOPInstanceUID);
								
								// store in lossless JPEG format
								fileformat.loadAllDataIntoMemory();
								
								[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
								cond = fileformat.saveFile( [curFileDest UTF8String], tSyntax);
								status =  (cond.good()) ? YES : NO;
								
								if( destDirec == nil)
									[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
							}
						}
					}
				}
			}
		}
		
		if( [what isEqualToString:@"decompressList"])
		{
			NSMutableDictionary	*dict = [DefaultsOsiriX getDefaults];
			[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"]];
			
			dcmtkSetJPEGColorSpace( [[dict objectForKey:@"UseJPEGColorSpace"] intValue]);
			
			NSString *destDirec;
			if( [path isEqualToString: @"sameAsDestination"])
				destDirec = nil;
			else
				destDirec = path;
			
			int i;
			for( i = 3; i < argc ; i++)
			{
				NSString *curFile = [NSString stringWithCString:argv[ i]];
				
				NSString *curFileDest;
				
				if( destDirec)
					curFileDest = [destDirec stringByAppendingPathComponent: [curFile lastPathComponent]];
				else
					curFileDest = [curFile stringByAppendingString: @" temp"];
					
				OFCondition cond;
				OFBool status = NO;
				const char *fname = (const char *)[curFile UTF8String];
				const char *destination = (const char *)[curFileDest UTF8String];
				
				DcmFileFormat fileformat;
				cond = fileformat.loadFile(fname);
				DcmXfer filexfer(fileformat.getDataset()->getOriginalXfer());
				
				//hopefully dcmtk willsupport jpeg2000 compression and decompression in the future
				
				if (filexfer.getXfer() == EXS_JPEG2000LosslessOnly || filexfer.getXfer() == EXS_JPEG2000)
				{
					[DCMPixelDataAttribute setUseOpenJpeg: [[dict objectForKey:@"UseOpenJpegForJPEG2000"] intValue]];
					DCMObject *dcmObject = [[DCMObject alloc] initWithContentsOfFile: curFile decodingPixelData:YES];
					@try
					{
						status = [dcmObject writeToFile: curFileDest withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:1 AET:@"OsiriX" atomically:YES];
					}
					@catch (NSException *e)
					{
						NSLog( @"dcmObject writeToFile failed: %@", e);
					}
					[dcmObject release];
					
					if( status == NO)
					{
						NSLog(@"decompress error");
						[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
					}
				}
				else if (filexfer.getXfer() != EXS_LittleEndianExplicit)
				{
					DcmDataset *dataset = fileformat.getDataset();
					
					// decompress data set if compressed
					dataset->chooseRepresentation(EXS_LittleEndianExplicit, NULL);
					
					// check if everything went well
					if (dataset->canWriteXfer(EXS_LittleEndianExplicit))
					{
						fileformat.loadAllDataIntoMemory();
						cond = fileformat.saveFile(destination, EXS_LittleEndianExplicit);
						status =  (cond.good()) ? YES : NO;
					}
					else status = NO;
					
					if( status == NO)
					{
						NSLog(@"decompress error");
						[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler:nil];
					}
				}
				else if( destDirec)
				{
					[[NSFileManager defaultManager] removeFileAtPath: curFileDest handler: nil];
					[[NSFileManager defaultManager] movePath: curFile toPath: curFileDest handler: nil];
					[[NSFileManager defaultManager] removeFileAtPath: curFile handler: nil];
				}
				
				if( destDirec == nil)
				{
					if( status)
					{
						[[NSFileManager defaultManager] removeFileAtPath: curFile handler:nil];
						[[NSFileManager defaultManager] movePath: curFileDest toPath: curFile handler: nil];
					}
				}
			}
		}
		
	    // deregister JPEG codecs
		DJDecoderRegistration::cleanup();
		DJEncoderRegistration::cleanup();

		// deregister RLE codecs
		DcmRLEDecoderRegistration::cleanup();
		DcmRLEEncoderRegistration::cleanup();
	}
	
//	[pool release]; We dont care: we are just a small app : our memory will be killed by the system. Dont loose time here !
	
	return 0;
}
