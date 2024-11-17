//
//  CBTStack.h
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

#include "btstack.h"
#include "hci_transport.h"
#include "hci_transport_usb.h"
#include "btstack_run_loop_posix.h"

static l2cap_fixed_channel_t * l2cap_fixed_channel_for_channel_id(uint16_t local_cid);

uint8_t l2cap_send_connectionless(hci_con_handle_t con_handle, uint16_t cid, uint8_t *data, uint16_t len);
