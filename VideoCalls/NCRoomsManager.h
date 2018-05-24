//
//  NCRoomsManager.h
//  VideoCalls
//
//  Created by Ivan Sein on 13.05.18.
//  Copyright © 2018 struktur AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NCRoom.h"

// Room
extern NSString * const NCRoomsManagerDidJoinRoomNotification;
extern NSString * const NCRoomsManagerDidLeaveRoomNotification;
extern NSString * const NCRoomsManagerDidUpdateRoomsNotification;
// Call
extern NSString * const NCRoomsManagerDidStartCallNotification;

@interface NCRoomsManager : NSObject

+ (instancetype)sharedInstance;
// Room
- (void)joinRoom:(NCRoom *)room;
- (void)leaveRoom:(NCRoom *)room;
- (void)updateRooms;
// Chat
- (void)startChatInRoom:(NCRoom *)room;
- (void)sendChatMessage:(NSString *)message toRoom:(NCRoom *)room;
- (void)startReceivingChatMessagesInRoom:(NCRoom *)room;
- (void)stopReceivingChatMessagesInRoom:(NCRoom *)room;
// Call
- (void)startCall:(BOOL)video inRoom:(NCRoom *)room;

@end