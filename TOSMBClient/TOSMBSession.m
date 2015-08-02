//
// TOSMBSession.m
// Copyright 2015 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#import <arpa/inet.h>

#import "TOSMBSession.h"
#import "TONetBIOSNameService.h"

#import "smb_session.h"
#import "smb_share.h"
#import "smb_stat.h"

@interface TOSMBSession ()

@property (nonatomic, assign) smb_session *session;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation TOSMBSession

#pragma mark - Class Creation -
- (instancetype)init
{
    if (self = [super init]) {
        _session = smb_session_new();
        if (_session == NULL)
            return nil;
    }
    
    return self;
}

- (instancetype)initWithHostName:(NSString *)name
{
    if (self = [self init]) {
        _hostName = name;
    }
    
    return self;
}

- (instancetype)initWithIPAddress:(NSString *)address
{
    if (self = [self init]) {
        _ipAddress = address;
    }
    
    return self;
}

- (instancetype)initWithHostName:(NSString *)name ipAddress:(NSString *)ipAddress
{
    if (self = [self init]) {
        _hostName = name;
        _ipAddress = ipAddress;
    }
    
    return self;
}

- (void)dealloc
{
    smb_session_destroy(self.session);
}

#pragma mark - Authorization -
- (void)setLoginCredentialsWithUserName:(NSString *)userName password:(NSString *)password
{
    self.userName = userName;
    self.password = password;
}

- (void)connect
{
    struct in_addr addr;
    smb_tid tid;
    
    inet_aton("192.168.1.3", &addr);
    
    if (!smb_session_connect(self.session, "TITANNAS", addr.s_addr, SMB_TRANSPORT_TCP))
    {
        printf("Unable to connect to host\n");
        return;
    }
    
    smb_session_set_creds(self.session, "TITANNAS", "", "");
    if (smb_session_login(self.session))
    {
        if (smb_session_is_guest(self.session))
            printf("Logged in as GUEST \n");
        else
            printf("Successfully logged in\n");
    }
    else
    {
        printf("Auth failed\n");
        return;
    }
    
    smb_share_list list;
    size_t shareCount = smb_share_get_list(self.session, &list);
    for (NSInteger i = 0; i < shareCount; i++)
        printf("Name %s \n", smb_share_list_at(list, i));
    
    
    tid = smb_tree_connect(self.session, "Books");
    if (!tid)
    {
        printf("Unable to connect to share\n");
        return;
    }
    
    smb_stat_list statList = smb_find(self.session, tid, "\\Manga\\ラブひな\\*");
    size_t listCount = smb_stat_list_count(statList);
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        printf("Item : %s\n", smb_stat_name(item));
    }
    
    NSLog(@"WOO");
}

#pragma mark - Accessors -
- (NSInteger)guest
{
    if (self.session == NULL)
        return -1;
    
    return smb_session_is_guest(self.session);
}

- (TOSMBSessionState)state
{
    if (self.session == NULL)
        return TOSMBSessionStateError;
    
    return smb_session_state(self.session);
}

@end