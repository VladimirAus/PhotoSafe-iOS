//
//  ToDoItem.h
//  HelloWorld
//
//  Created by Erica Sadun on 8/24/09.
//  Copyright 2009 Up To No Good, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface PhotoItem :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * originalName;
@property (nonatomic, retain) NSString * currentName;
@property (nonatomic, retain) NSString * sectionName;

@end



