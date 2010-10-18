/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: FileController.m 315 2010-04-23 04:12:45Z Tanaris4 $
 *
 */

#import <Foundation/Foundation.h>

@class FileObject;

@interface FileController : NSObject {

}

// we shouldn't really use this
+ (FileController*)sharedFileController;

// save all objects in the array
- (BOOL)saveObjects:(NSArray*)objects;

// save one object
- (BOOL)saveObject:(FileObject*)obj;

// get all objects with the extension
- (NSArray*)getObjectsWithClass:(Class)class;

// delete the object with this file name
- (BOOL)deleteObjectWithFilename:(NSString*)filename;

// delete an object
- (BOOL)deleteObject:(FileObject*)obj;

// gets the filename (not path) for an object
- (NSString*)filenameForObject:(FileObject*)obj;

// old method
- (NSArray*)dataForKey: (NSString*)key withClass:(Class)class;

// just show an object in the finder
- (void)showInFinder: (id)object;
@end
