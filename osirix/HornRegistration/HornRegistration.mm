//
//  HornRegistration.mm
//  OsiriX
//
//  Created by joris on 07/03/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "HornRegistration.h"

#include <stdio.h>
#include "etkRegistration.hpp"

@implementation HornRegistration

+ (void) test
{
	double adModelPoints  [][3] = {{0, 0, 0}, {10, 0, 0}, {10, 10, 0}, {0, 10, 0}};
	double adSensorPoints [][3] = {{5, 0, 0}, {5, 10, 0}, {5, 10, 11}, {5, 0, 10}};

	printf ("Horn Registration Test\n\n");

	unsigned u, v;

	// Create the registration structure
	etkRegistration* pReg = etkCreateRegistration ();

	// Set the number of points to register
	pReg->uNbPoints = 4;

	// Copy the model points in the etkRegistration structure
	for (u = 0; u < 4; u++)
	{
		printf ("Model point (#%d): ", u);
		for (v = 0; v < 3; v++)
		{
			pReg->adModelPoints [u][v] = adModelPoints [u][v];
			printf ("\t%3.2f", pReg->adModelPoints [u][v]);
		}
		printf ("\n");
	}
	printf ("\n");

	// Copy the sensor points in the etkRegistration structure
	for (u = 0; u < 4; u++)
	{
		printf ("Sensor point (#%d): ", u);
		for (v = 0; v < 3; v++)
		{
			pReg->adSensorPoints [u][v] = adSensorPoints [u][v];
			printf ("\t%3.2f", pReg->adSensorPoints [u][v]);
		}
		printf ("\n");
	}

	double* adRot = NULL;
	double* adTrans = NULL;

	double dError = etkRegister (pReg, &adRot, &adTrans);

	if (dError < 0.0)
	{
		printf ("Error in etkRegister");
	}
	else
	{
		// Display translation
		printf ("\nTranslation:\n");
		for (u = 0; u < 3; u++)
			printf ("\t%3.2f", adTrans [u]);
		printf ("\n\n");

		// Display rotation
		printf ("Rotation:\n");
		for (u = 0; u < 3; u++)
		{
			for (v = 0; v < 3; v++)
				printf ("\t%3.2f", adRot [u*3+v]);
			printf ("\n");
		}
		printf ("\n\n");

		printf ("Error (RMS):\n\t%lf\n\n", dError);
	}
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		modelPoints = [NSMutableArray arrayWithCapacity:0];
		sensorPoints = [NSMutableArray arrayWithCapacity:0];
	}
	return self;
}

- (void) dealloc
{
	[modelPoints release];
	[sensorPoints release];
	[super dealloc];
}

- (void) addModelPointX: (double) x Y: (double) y Z: (double) z 
{
	//double *modelPoint;
	double *modelPoint = (double*) malloc(3*sizeof(double));
	modelPoint[0]=x;
	modelPoint[1]=y;
	modelPoint[2]=z;
	[self addModelPoint: modelPoint];
}

- (void) addSensorPointX: (double) x Y: (double) y Z: (double) z 
{
	//double *sensorPoint;
	double *sensorPoint = (double*) malloc(3*sizeof(double));
	sensorPoint[0]=x;
	sensorPoint[1]=y;
	sensorPoint[2]=z;
	[self addSensorPoint: sensorPoint];
}

- (void) addModelPoint: (double*) point
{
	[modelPoints addObject:[NSValue valueWithBytes:point objCType:@encode(double[3])]];
}

- (void) addSensorPoint: (double*) point
{
	[sensorPoints addObject:[NSValue valueWithBytes:point objCType:@encode(double[3])]];
}

// You shouldn't call this function directly (or do it when all the points have been added)
- (short) numberOfPoint
{
	short modelCount = [modelPoints count];
	short sensorCount = [sensorPoints count];
	if(modelCount == sensorCount)
	{
		return modelCount;
	}
	else
	{
		return -1;
	}
}

// Call this function when all the points have been added
- (void) compute
{
	short numberOfPoint = [self numberOfPoint];
	
	if (numberOfPoint>0)
	{
		// Create the registration structure
		etkRegistration* pReg = etkCreateRegistration ();

		// Set the number of points to register
		pReg->uNbPoints = numberOfPoint;
		
		unsigned u, v;
		
		// Copy the model points in the etkRegistration structure
		double *modelPoint = (double*) malloc(3*sizeof(double));
		for (u = 0; u < numberOfPoint; u++)
		{
			printf ("Model point (#%d): ", u);
			[[modelPoints objectAtIndex:u] getValue:modelPoint];
			
			for (v = 0; v < 3; v++)
			{
				pReg->adModelPoints[u][v] = modelPoint[v];
				printf ("\t%3.2f", pReg->adModelPoints[u][v]);
			}
			printf ("\n");
		}
		printf ("\n");
		
		// Copy the sensor points in the etkRegistration structure
		double *sensorPoint = (double*) malloc(3*sizeof(double));
		for (u = 0; u < numberOfPoint; u++)
		{
			printf ("Sensor point (#%d): ", u);
			[[sensorPoints objectAtIndex:u] getValue:sensorPoint];
			
			for (v = 0; v < 3; v++)
			{
				pReg->adSensorPoints[u][v] = sensorPoint[v];
				printf ("\t%3.2f", pReg->adSensorPoints[u][v]);
			}
			printf ("\n");
		}
		
		double* adRot = NULL;
		double* adTrans = NULL;

		double dError = etkRegister (pReg, &adRot, &adTrans);

		if (dError < 0.0)
		{
			printf ("Error in etkRegister");
		}
		else
		{
			// Display translation
			printf ("\nTranslation:\n");
			for (u = 0; u < 3; u++)
				printf ("\t%3.2f", adTrans [u]);
			printf ("\n\n");

			// Display rotation
			printf ("Rotation:\n");
			for (u = 0; u < 3; u++)
			{
				for (v = 0; v < 3; v++)
					printf ("\t%3.2f", adRot [u*3+v]);
				printf ("\n");
			}
			printf ("\n\n");

			printf ("Error (RMS):\n\t%lf\n\n", dError);
		}
	}
}

@end
