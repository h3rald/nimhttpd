[Package]
name          = "nimhttpd"
version       = "1.0.4"
author        = "Fabio Cevasco"
description   = "A tiny static file web server."
license       = "MIT"
bin           = "nimhttpd"
skipFiles     = @["nakefile.nim"]

[Deps]
requires: "nim >= 0.18.0"
