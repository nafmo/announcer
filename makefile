# makefile f”r LocalPost

.pas.tpu:
  tpc /$D- $*

announce.exe: announce.pas c:\dev\”vers„tt\adir\adir_src\nls.tpu c:\dev\lib\mksm106\MKFile.tpu c:\dev\lib\mksm106\MKString.tpu c:\dev\lib\mksm106\MKMsgAbs.tpu c:\dev\lib\mksm106\MKOpen.tpu c:\dev\lib\mksm106\MKGlobT.tpu c:\dev\lib\mksm106\MKDos.tpu c:\dev\lib\mksm106\MKMisc.tpu crypt.tpu anhelp.tpu anstr.tpu chekdate.tpu pkthead.tpu strutil.tpu cmdline.tpu
  tpc /$D- announce.pas
  lzexe announce.exe
  del announce.old

generate.exe: generate.pas crypt.tpu
  tpc generate.pas

anstr.tpu: anstr.pas c:\dev\”vers„tt\adir\adir_src\nls.tpu
  tpc /$D- anstr.pas

anhelp.tpu: anhelp.pas anstr.tpu
  tpc /$D- anhelp.pas

cmdline.tpu: anstr.tpu strutil.tpu cmdline.pas
  tpc /$D- cmdline.pas

c:\dev\lib\mksm106\mkopen.tpu: c:\dev\lib\mksm106\mkopen.pas c:\dev\lib\mksm106\mkmsgabs.tpu c:\dev\lib\mksm106\mkmsgsqu.tpu c:\dev\lib\mksm106\mkmsgjam.tpu c:\dev\lib\mksm106\mkmsghud.tpu c:\dev\lib\mksm106\mkmsgezy.tpu c:\dev\lib\mksm106\mkdos.tpu
  tpc /$D- c:\dev\lib\mksm106\mkopen.pas

c:\dev\lib\mksm106\mkfile.tpu: c:\dev\lib\mksm106\mkfile.pas
  tpc /$D- c:\dev\lib\mksm106\mkfile.pas

c:\dev\lib\mksm106\mkstring.tpu: c:\dev\lib\mksm106\mkstring.pas
  tpc /$D- c:\dev\lib\mksm106\mkstring.pas

c:\dev\lib\mksm106\mkmsgabs.tpu: c:\dev\lib\mksm106\mkmsgabs.pas c:\dev\lib\mksm106\mkglobt.tpu
  tpc /$D- c:\dev\lib\mksm106\mkmsgabs.pas

c:\dev\lib\mksm106\mkmsgsqu.tpu: c:\dev\lib\mksm106\mkmsgsqu.pas
  tpc /$D- c:\dev\lib\mksm106\mkmsgsqu.pas

c:\dev\lib\mksm106\mkmsgjam.tpu: c:\dev\lib\mksm106\mkmsgjam.pas
  tpc /$D- c:\dev\lib\mksm106\mkmsgjam.pas

c:\dev\lib\mksm106\mkmsghud.tpu: c:\dev\lib\mksm106\mkmsghud.pas
  tpc /$D- c:\dev\lib\mksm106\mkmsghud.pas

c:\dev\lib\mksm106\mkmsgezy.tpu: c:\dev\lib\mksm106\mkmsgezy.pas
  tpc /$D- c:\dev\lib\mksm106\mkmsgezy.pas

c:\dev\lib\mksm106\mkmsgfid.tpu: c:\dev\lib\mksm106\mkmsgfid.pas
  tpc /$D- c:\dev\lib\mksm106\mkmsgfid.pas

c:\dev\lib\mksm106\mkglobt.tpu: c:\dev\lib\mksm106\mkglobt.pas c:\dev\lib\mksm106\mkstring.tpu c:\dev\lib\mksm106\mkmisc.tpu
  tpc /$D- c:\dev\lib\mksm106\mkglobt.pas

c:\dev\lib\mksm106\mkmisc.tpu: c:\dev\lib\mksm106\mkmisc.pas
  tpc /$D- c:\dev\lib\mksm106\mkmisc.pas

c:\dev\lib\mksm106\mkdos.tpu: c:\dev\lib\mksm106\mkdos.pas
  tpc /$D- c:\dev\lib\mksm106\mkdos.pas

strutil.tpu: strutil.pas c:\dev\”vers„tt\adir\adir_src\nls.tpu
  tpc /$D- strutil.pas

c:\dev\”vers„tt\adir\adir_src\nls.tpu: c:\dev\”vers„tt\adir\adir_src\nls.pas
  tpc /$D- c:\dev\”vers„tt\adir\adir_src\nls.pas

clean:
  del c:\dev\”vers„tt\adir\adir_src\nls.tpu c:\dev\lib\mksm106\MKFile.tpu
  del c:\dev\lib\mksm106\MKString.tpu c:\dev\lib\mksm106\MKMsgAbs.tpu
  del c:\dev\lib\mksm106\MKOpen.tpu c:\dev\lib\mksm106\MKGlobT.tpu
  del c:\dev\lib\mksm106\MKDos.tpu c:\dev\lib\mksm106\MKMisc.tpu crypt.tpu
  del anhelp.tpu anstr.tpu chekdate.tpu pkthead.tpu strutil.tpu cmdline.tpu
