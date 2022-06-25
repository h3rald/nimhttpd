[![Nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://nimble.directory/pkg/nimhttpd)

[![Release](https://img.shields.io/github/release/h3rald/nimhttpd.svg)](https://github.com/h3rald/nimhttpd/releases/latest)
[![License](https://img.shields.io/github/license/h3rald/nimhttpd.svg)](https://raw.githubusercontent.com/h3rald/nimhttpd/master/LICENSE)

# NimHTTPd

_NimHTTPd_ is a minimal web server that can be used to serve static files.

## Usage

**nimhttpd** **[** **-4 or -6** **-g** **-p:**_port_ **-t:**_title_ **-a:**_address_ **]** **[** _directory_ **]**

Where:

- _directory_ is the directory to serve (default: current directory).
- _port_ is the port to listen to (default: 1337). If the specified port is unavailable, the number will be incremented until an available port is found.
- _address_ is the address to bind to (default: localhost).
- _title_ is the title to use when listing the contents of a directory.
- _-g_ enables all addresses to receive requests (should account for 4/6 flags)
- _-4_ enables only IPv4
- _-6_ enables only IPv6
