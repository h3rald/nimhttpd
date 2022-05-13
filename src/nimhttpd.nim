import 
  asyncdispatch,
  asynchttpserver, 
  mimetypes, 
  nativesockets,
  os,
  parseopt,
  strutils, 
  times, 
  uri
  
from httpcore import HttpMethod, HttpHeaders

import
  nimhttpdpkg/config

const
  name = pkgTitle
  version = pkgVersion
  style = "style.css".slurp
  description = pkgDescription
  author = pkgAuthor
  addressDefault = "localhost"
  portDefault = 1337
  
var domain = AF_INET

let usage = """ $1 v$2 - $3
  (c) 2014-2022 $4

  Usage:
    nimhttpd [-p:port] [directory]

  Arguments:
    directory      The directory to serve (default: current directory).

  Options:
    -t, --title    The title to use in index pages (default: Index)
    -p, --port     The port to listen to (default: $5).
    -a, --address  The address to listen to (default: $6). If the specified port is
                   unavailable, the number will be incremented until an available port is found.
    -6, --ipv6     Listen to IPv6 addresses.
""" % [name, version, description, author, $portDefault, $addressDefault]


type 
  NimHttpResponse* = tuple[
    code: HttpCode,
    content: string,
    headers: HttpHeaders]
  NimHttpSettings* = object
    logging*: bool
    directory*: string
    mimes*: MimeDb
    port*: Port
    title*: string
    address*: string
    name*: string
    version*: string

proc h_page(settings:NimHttpSettings, content, title, subtitle: string): string =
  var footer = """<div id="footer">$1 v$2</div>""" % [settings.name, settings.version]
  result = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="$3">
    <title>$1</title>
    <style>$2</style>
  </head>
  <body>
    <h1>$1</h1>
    <h2>$3</h2>
    $4
    $5
  </body>
</html>
  """ % [title, style, subtitle, content, footer]

proc relativePath(path, cwd: string): string =
  var path2 = path
  if cwd == "/":
    return path
  else:
    path2.delete(0..cwd.len-1)
  var relpath = path2.replace("\\", "/")
  if (not relpath.endsWith("/")) and (not path.fileExists):
    relpath = relpath&"/"
  if not relpath.startsWith("/"):
    relpath = "/"&relpath
  return relpath

proc relativeParent(path, cwd: string): string =
  var relparent = path.parentDir.relativePath(cwd)
  if relparent == "":
    return "/"
  else: 
    return relparent

proc sendNotFound(settings: NimHttpSettings, path: string): NimHttpResponse = 
  var content = "<p>The page you requested cannot be found.<p>"
  return (code: Http404, content: h_page(settings, content, $int(Http404), "Not Found"), headers: {"Content-Type": "text/html"}.newHttpHeaders())

proc sendNotImplemented(settings: NimHttpSettings, path: string): NimHttpResponse =
  var content = "<p>This server does not support the functionality required to fulfill the request.</p>"
  return (code: Http501, content: h_page(settings, content, $int(Http501), "Not Implemented"), headers: {"Content-Type": "text/html"}.newHttpHeaders())

proc sendStaticFile(settings: NimHttpSettings, path: string): NimHttpResponse =
  let mimes = settings.mimes
  var ext = path.splitFile.ext
  if ext == "":
    ext = ".txt"
  ext = ext[1 .. ^1]
  let mimetype = mimes.getMimetype(ext.toLowerAscii)
  var file = path.readFile
  return (code: Http200, content: file, headers: {"Content-Type": mimetype}.newHttpHeaders)

proc sendDirContents(settings: NimHttpSettings, dir: string): NimHttpResponse = 
  let cwd = settings.directory.absolutePath
  var res: NimHttpResponse
  var files = newSeq[string](0)
  var path = dir.absolutePath
  if not path.startsWith(cwd):
    path = cwd
  if path != cwd and path != cwd&"/" and path != cwd&"\\":
    files.add """<li class="i-back entypo"><a href="$1">..</a></li>""" % [path.relativeParent(cwd)]
  var title = settings.title
  let subtitle = path.relativePath(cwd)
  for i in walkDir(path):
    let name = i.path.extractFilename
    let relpath = i.path.relativePath(cwd)
    if name == "index.html" or name == "index.htm":
      return sendStaticFile(settings, i.path)
    if i.path.dirExists:
      files.add """<li class="i-folder entypo"><a href="$1">$2</a></li>""" % [relpath, name]
    else:
      files.add """<li class="i-file entypo"><a href="$1">$2</a></li>""" % [relpath, name]
  let ul = """
<ul>
  $1
</ul>
""" % [files.join("\n")]
  res = (code: Http200, content: h_page(settings, ul, title, subtitle), headers: {"Content-Type": "text/html"}.newHttpHeaders())
  return res

proc printReqInfo(settings: NimHttpSettings, req: Request) =
  if not settings.logging:
    return
  echo getTime().local, " - ", req.hostname, " ", req.reqMethod, " ", req.url.path

proc handleCtrlC() {.noconv.} =
  echo "\nExiting..."
  quit()

setControlCHook(handleCtrlC)

proc genMsg(settings: NimHttpSettings): string =
  let url = "http://$1:$2/" % [settings.address, $settings.port.int]
  let t = now()
  let pid = getCurrentProcessId()
  result = """$1 v$2
Address:       $3 
Directory:     $4
Current Time:  $5 
PID:           $6""" % [settings.name, settings.version, url, settings.directory.quoteShell, $t, $pid]

proc serve*(settings: NimHttpSettings) =
  var server = newAsyncHttpServer()
  proc handleHttpRequest(req: Request): Future[void] {.async.} =
    printReqInfo(settings, req)
    let path = settings.directory/req.url.path.replace("%20", " ").decodeUrl()
    var res: NimHttpResponse 
    if req.reqMethod != HttpGet:
      res = sendNotImplemented(settings, path)
    elif path.dirExists:
      res = sendDirContents(settings, path)
    elif path.fileExists:
      res = sendStaticFile(settings, path)
    else:
      res = sendNotFound(settings, path)
    await req.respond(res.code, res.content, res.headers)
  echo genMsg(settings)
  asyncCheck server.serve(settings.port, handleHttpRequest, settings.address, -1, domain)

when isMainModule:

  var port = portDefault
  var address = addressDefault
  var logging = false
  var www = getCurrentDir()
  var title = "Index"
  
  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case key
      of "log", "l":
        logging = true
      of "help", "h":
        echo usage
        quit(0)
      of "version", "v":
        echo version
        quit(0)
      of "-ipv6", "6":
        domain = AF_INET6
      of "address", "a":
        address = val
      of "title", "t":
        title = val
      of "port", "p":
        try:
          port = val.parseInt
        except:
          if val == "":
            echo "Port not set."
            quit(2)
          else:
            echo "Error: Invalid port: '", val, "'"
            echo "Running on default port instead."
      else:
        discard
    of cmdArgument:
      var dir: string
      if key.isAbsolute:
        dir = key
      else:
        dir = www/key
      if dir.dirExists:
        www = expandFilename dir
      else:
        echo "Error: Directory '"&dir&"' does not exist."
        quit(1)
    else: 
      discard
  
  var addrInfo = getAddrInfo(address, Port(port), domain)  
  if addrInfo == nil:
    echo "Error: Could not resolve address '"&address&"'."
    quit(1)
  
  var settings: NimHttpSettings
  settings.directory = www
  settings.logging = logging
  settings.mimes = newMimeTypes()
  settings.mimes.register("htm", "text/html")
  settings.address = address
  settings.name = name
  settings.title = title
  settings.version = version
  settings.port = Port(port)
  
  serve(settings)
  runForever()
