# Copyright Jerily LTD. All Rights Reserved.
# SPDX-FileCopyrightText: 2024 Neofytos Dimitriou (neo@jerily.cy)
# SPDX-License-Identifier: MIT.

namespace eval ::tsession::valkeystore {
    variable valkey_client
    variable config {
        host localhost
        port 6379
    }

    proc init {config_dict} {
        package require valkey

        variable config
        variable valkey_client

        set config [dict merge $config $config_dict]

        set host [dict get $config host]
        set port [dict get $config port]
        if {[dict exists $config password]} {
            set password [dict get $config password]
            set valkey_client [valkey -host $host -port $port -password $password]
        } else {
            set valkey_client [valkey -host $host -port $port]
        }
    }

    proc retrieve_session {session_id} {
        variable valkey_client

        set session [$valkey_client HGET sessions ${session_id}]

        if { $session ne {} } {

            # check if "session" expired
            set expires [dict get ${session} expires]
            set now [clock seconds]
            if { ${now} > ${expires} } {
                destroy_session ${session_id}
                return {}
            }

            return $session
        }
        return {}
    }

    proc save_session {session_id session_dict} {
        variable valkey_client
        $valkey_client HSET sessions ${session_id} $session_dict
    }

    proc destroy_session {session_id} {
        variable valkey_client
        $valkey_client HDEL sessions ${session_id}
    }

    proc touch_session {session_id session_dict} {
        set current_session_dict [retrieve_session ${session_id}]
        if { ${current_session_dict} ne {} } {
            dict set current_session_dict expires [dict get ${session_dict} expires]
            save_session ${session_id} ${current_session_dict}
        }

    }
}

