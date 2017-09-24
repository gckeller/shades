//
//  ShadesApp-Bridging-Header.h
//  ShadesApp
//
//  Created by Manuel M T Chakravarty on 15.08.17.
//  Copyright © 2017 Manuel M T Chakravarty. All rights reserved.
//

#ifndef ShadesApp_Bridging_Header_h
#define ShadesApp_Bridging_Header_h

#import <Foundation/Foundation.h>

// Haskell RTS functions.
void hs_init     (int *argc, char **argv[]);
void hs_exit     (void);

// This is the function exported by the Haskell library containing the Haskell SpriteKit code.
NSObject *game_scene();

#endif /* ShadesApp_Bridging_Header_h */
