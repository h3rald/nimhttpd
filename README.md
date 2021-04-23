[![Nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/h3rald/nimhttpd)

![release](https://img.shields.io/github/release/h3rald/nimhttpd/all.svg)
![license](https://img.shields.io/github/license/h3rald/nimhttpd.svg)

# NimHTTPd

_NimHTTPd_ is a minimal web server that can be used to serve static files.

## Usage

**nimhttpd** **[** **-p:**_port_ **-t:**_title_ **-a:**_address_ **]** **[** _directory_ **]**

Where:

* _directory_ is the directory to serve (default: current directory).
* _port_ is the port to listen to (default: 1337). If the specified port is
  unavailable, the number will be incremented until an available port is found.
* _address_ is the address to bind to (default: 0.0.0.0).
* _title_ is the title to use when listing the contents of a directory.
