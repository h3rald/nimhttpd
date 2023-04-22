import
  os

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

when system.fileExists(thisModuleFile.parentDir / "src/nimhttpdpkg/config.nim"):
  # In the git repository the Nimble sources are in a ``src`` directory.
  import src/nimhttpdpkg/config
else:
  # When the package is installed, the ``src`` directory disappears.
  import nimhttpdpkg/config


# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @["nimhttpd"]
srcDir        = "src"
installExt    = @["nim"]

# Dependencies

requires "nim >= 1.6.12"

const compile = "nim c -d:release"
const linux_x64 = "--cpu:amd64 --os:linux -o:nimhttpd"
const windows_x64 = "--cpu:amd64 --os:windows -o:nimhttpd.exe"
const macosx_x64 = "-o:nimhttpd"
const program = "nimhttpd"
const program_file = "src/nimhttpd.nim"
const zip = "zip -X"

proc shell(command, args: string, dest = "") =
  exec command & " " & args & " " & dest

proc filename_for(os: string, arch: string): string =
  return "nimhttpd" & "_v" & version & "_" & os & "_" & arch & ".zip"

task windows_x64_build, "Build NimHTTPd for Windows (x64)":
  shell compile, windows_x64, program_file

task linux_x64_build, "Build NimHTTPd for Linux (x64)":
  shell compile, linux_x64,  program_file
  
task macosx_x64_build, "Build NimHTTPd for Mac OS X (x64)":
  shell compile, macosx_x64, program_file

task release, "Release NimHTTPd":
  echo "\n\n\n WINDOWS - x64:\n\n"
  windows_x64_buildTask()
  shell zip, filename_for("windows", "x64"), program & ".exe"
  shell "rm", program & ".exe"
  echo "\n\n\n LINUX - x64:\n\n"
  linux_x64_buildTask()
  shell zip, filename_for("linux", "x64"), program 
  shell "rm", program 
  echo "\n\n\n MAC OS X - x64:\n\n"
  macosx_x64_buildTask()
  shell zip, filename_for("macosx", "x64"), program 
  shell "rm", program 
  echo "\n\n\n ALL DONE!"

