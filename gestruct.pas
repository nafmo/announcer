Unit GeStruct;

Interface

Uses
  MkGlobT;

(*
**  gestruct.inc
**
**  System data file definitions for GEcho 1.20.b9+
**
**  Copyright (C) 1991-1995 Gerard J. van der Land. All rights reserved.
**
**  All information in this document is subject to change at any time
**  without prior notice.
**
**  Last revision: 09-Aug-95
**
**  Strings are NUL padded and NUL terminated arrays of char type.
**  Path names are back slash ('\') terminated.
*)

const
   GE_THISREV = $0002;  (* System file revision level *)
   GE_MAJOR   = 1;      (* GEcho major revision version *)
   GE_MINOR   = 20;     (* GEcho minor revision version *)

   AKAS           = 32;     (* Main + AKAs *)
   OLDAKAS        = 11;     (* Not used *)
   OLDUPLINKS     = 10;     (* Not used *)
   OLDGROUPS      = 26;     (* Not used *)
   USERS          = 10;     (* User names *)
   MAXAREAS       = 10000;  (* Area records *)
   MAXCONNECTIONS = 500;    (* Connections per area *)
   MAXGROUPS      = 256;    (* Group records *)
   MAXNODES       = 5000;   (* Node records *)
   MAXVIAS        = 60;     (* Pack "Via" records *)
   MAXROUTES      = 640;    (* Pack "Routed node" records *)

   GROUPBYTES = ((MAXGROUPS + 7) div 8);


(* --- Datatypes *)

type
   dword = longint;  (* Borland Pascal does not support longword *)
   str9  = array[0.. 8] of char;
   str13 = array[0..12] of char;
   str17 = array[0..16] of char;
   str20 = array[0..19] of char;
   str21 = array[0..20] of char;
   str30 = array[0..29] of char;
   str31 = array[0..30] of char;
   str36 = array[0..35] of char;
   str51 = array[0..50] of char;
   str53 = array[0..52] of char;
   str61 = array[0..60] of char;
   str65 = array[0..64] of char;

   ADDRESS = record
      zone  : word;
      net   : word;
      node  : word;
      point : word;
   end;

   GROUPS = array[0..GROUPBYTES-1] of byte;


(* --- Log levels *)

const
   LOG_INBOUND    = $0001;  (* Inbound activities *)
   LOG_OUTBOUND   = $0002;  (* Outbound activities *)
   LOG_PACKETS    = $0004;  (* Inbound packet info *)
   LOG_UNEXPECT   = $0008;  (* Extended packet info *)
   LOG_AREAMGR    = $0010;  (* Unexpected passwords *)
   LOG_EXTPKTINFO = $0040;  (* AreaMgr messages *)
   LOG_NETEXPORT  = $0100;  (* Exporting of netmail *)
   LOG_NETIMPORT  = $0200;  (* Importing of netmail *)
   LOG_NETPACK    = $0400;  (* Packing of netmail *)
   LOG_NETMOVED   = $0800;  (* Moving Sent/Rcvd mail *)
   LOG_STATISTICS = $2000;  (* GEcho's statistics *)
   LOG_MBUTIL     = $4000;  (* MBUTIL's activities *)
   LOG_DEBUG      = $8000;  (* DEBUG: All of the above *)


(* --- Log styles *)

   LOG_FD      = 0;  (* FrontDoor *)
   LOG_BINK    = 1;  (* BinkleyTerm *)
   LOG_QUICK   = 2;  (* QuickBBS *)
   LOG_DBRIDGE = 3;  (* D'Bridge *)


(* --- Setup option bits *)

   NOKILLNULL = $0001;  (* Don't kill null netmail messages while tossing *)
   RESCANOK   = $0002;  (* Allow %RESCAN *)
   KEEPREQS   = $0004;  (* Keep AreaMgr requests *)
   NONODEADD  = $0008;  (* Don't automatically add NodeMgr records *)
   USEHMBBUF  = $0020;  (* Use Hudson buffers *)
   KEEPNET    = $0040;  (* Don't use Kill/Sent on exported netmail *)
   KEEPMGR    = $0080;  (* Don't use Kill/Sent on MGR receipts *)
   NORRQS     = $0100;  (* Ignore Return receipt Requests *)
   KILLDUPES  = $0200;  (* Kill duplicate messages *)
   DOS32BIT   = $0400;  (* Run 32-bit DOS version on 386+ machines *)
   NOCRSTRIP  = $0800;  (* Don't strip Soft-CRs *)
   REMOVEJUNK = $1000;  (* Remove "Re:" junk from JAM subjects *)
   NOAUTODISC = $2000;  (* Don't automatically disconnect empty PT areas *)
   NOCHECKEND = $4000;  (* Don't check for valid end of archives *)
   SETPVT     = $8000;  (* Set Pvt on imported netmail messages *)


(* --- Extra option bits *)

   NOCHKDEST  = $0001;  (* Don't check packet destination *)
   AUTOCREAT  = $0002;  (* Automatically create message bases *)
   PAUSEEOK   = $0004;  (* Allow %PAUSE *)
   NOTIFYOK   = $0008;  (* Allow %NOTIFY OFF *)
   ADDALLOK   = $0010;  (* Allow %+* *)
   PWDOK      = $0020;  (* Allow %PWD *)
   PKTPWDOK   = $0040;  (* Allow %PKTPWD *)
   NOBADPKTS  = $0080;  (* Don't notify sysop about BAD/DST/LOC packets *)
   PKTPRGONCE = $0100;  (* Run PKT program only before the first PKT *)
   CREATEBUSY = $0200;  (* Create busy flags *)
   COMPRESSOK = $0400;  (* Allow %COMPRESS *)
   FROMOK     = $0800;  (* Allow %FROM *)
   REDIR2NUL  = $1000;  (* Redirect output of external utilities to NUL *)
   NOEXPAND   = $2000;  (* Don't expand filenames of file attaches *)
   LOCALEXPT  = $4000;  (* Export netmail to our own AKA *)
   OPUSDATES  = $8000;  (* Use Opus style binary date/time stamps *)


(* --- Compression types *)

   PR_ARC =  0;  (* Compressed mail files created by ARC or PKPAK *)
   PR_ARJ =  1;  (* Compressed mail files created by ARJ *)
   PR_LZH =  2;  (* Compressed mail files created by LHA *)
   PR_PAK =  3;  (* Compressed mail files created by PAK *)
   PR_ZIP =  4;  (* Compressed mail files created by PKZIP *)
   PR_ZOO =  5;  (* Compressed mail files created by ZOO *)
   PR_SQZ =  6;  (* Compressed mail files created by SQZ *)
   PR_UC2 =  7;  (* Compressed mail files created by UC II *)
   PR_RAR =  8;  (* Compressed mail files created by RAR *)
   PR_PKT = 10;  (* Uncompressed PKT files *)


(* --- Locking method *)

   LOCK_OFF   = 0;  (* Deny Write (Exclusive) *)
   LOCK_RA101 = 1;  (* RemoteAccess 1.01 (SHARE) *)
   LOCK_RA111 = 2;  (* RemoteAccess 1.11 (SHARE) *)


(* --- Semaphore mode *)

   SEMAPHORE_OFF = 0;  (* Don't use semaphores *)
   SEMAPHORE_FD  = 1;  (* FrontDoor 2.1x *)
   SEMAPHORE_IM  = 2;  (* InterMail 2.2x *)
   SEMAPHORE_DB  = 3;  (* D'Bridge 1.5x *)
   SEMAPHORE_BT  = 4;  (* BinkleyTerm 2.5x *)
   SEMAPHORE_MD  = 5;  (* MainDoor *)


(* --- Check user name *)

   CHECK_NOT       = 0;  (* Don't check if user name exists *)
   CHECK_USERFILE  = 1;  (* User file (USERS.BBS) *)
   CHECK_USERINDEX = 2;  (* User index (USERSIDX.BBS / NAMEIDX.BBS) *)


(* --- Mailer type *)

   MAILER_FD = 0;  (* FrontDoor *)
   MAILER_DB = 1;  (* D'Bridge *)
   MAILER_BT = 2;  (* BinkleyTerm *)


(* --- BBS type *)

   BBS_RA111    = 0;  (* RemoteAccess 1.1x *)
   BBS_RA200    = 1;  (* RemoteAccess 2.xx *)
   BBS_QUICK275 = 2;  (* QuickBBS 2.7x *)
   BBS_SBBS116  = 3;  (* SuperBBS 1.16 *)
   BBS_WC400    = 4;  (* Wildcat! 4.x *)


(* --- Change tear line *)

   TEAR_NO      = 0;  (* No *)
   TEAR_DEFAULT = 1;  (* Replace default *)
   TEAR_CUSTOM  = 2;  (* Replace custom *)
   TEAR_EMPTY   = 3;  (* Replace empty *)
   TEAR_REMOVE  = 4;  (* Remove *)


type
   OLDUPLINK = record
      address  : AddrType;  (* Uplink address *)
      areafix  : str9;     (* AreaFix program *)
      password : str17;    (* AreaFix password *)
      filename : str13;    (* "Forward List" filename *)
      unused   : array[1..6] of byte;
      options  : byte;     (* See --- Uplink options bits *)
      filetype : byte;     (* 0 = Random, 1 = "<areaname> <description>" *)
      groups   : dword;    (* Nodes must have one of these groups *)
      origin   : byte;     (* Origin AKA *)
   end;

   AKAMATCH = record
      zone : word;
      net  : word;
      aka  : byte;
   end;

   COLORSET = record
      bg_char     : byte;
      headerframe : byte;
      headertext  : byte;
      background  : byte;
      bottomline  : byte;
      bottomtext  : byte;
      bottomkey   : byte;
      errorframe  : byte;
      errortext   : byte;
      helpframe   : byte;
      helptitle   : byte;
      helptext    : byte;
      helpfound   : byte;
      winframe    : byte;
      wintitle    : byte;
      winline     : byte;
      wintext     : byte;
      winkey      : byte;
      windata     : byte;
      winselect   : byte;
      inputdata   : byte;
      exportonly  : byte;
      importonly  : byte;
      lockedout   : byte;
   end;


(* --- SETUP.GE structure *)

   SETUP_GE = record
      sysrev          : word;   (* Must contain GE_THISREV *)
      options         : word;   (* Options bits, see --- Setup option bits *)
      autorenum       : word;   (* Auto renumber value *)
      maxpktsize      : word;   (* Maximum packet size, 0 = unlimited *)
      logstyle        : byte;   (* See --- Log styles *)
      oldnetmailboard : byte;   (* Netmail board, must be zero now *)
      oldbadboard     : byte;   (* Where bad echomail is stored (0 = path) *)
      olddupboard     : byte;   (* Where duplicates are stored (0 = path) *)
      recoveryboard   : byte;   (* Recovery board (1-200, 0 = delete) *)
      filebuffer      : byte;   (* Size (in KB) of MBU file I/O buffer *)
      days            : byte;   (* Days to keep old mail around *)
      swapping        : byte;   (* Swapping method *)
      compr_default   : byte;   (* Default compresion type *)
      pmcolor : array[1..15] of byte;  (* Not used *)
      oldaka : array[0..OLDAKAS-1] of AddrType;  (* Main address and AKAs *)
      oldpointnet : array[0..OLDAKAS-1] of word;  (* Pointnets for all addresses *)
      gekey    : dword;         (* GEcho registration key *)
      mbukey   : dword;         (* MBUTIL registration key *)
      geregto  : str51;         (* Text used to generate the GEcho key *)
      mburegto : str51;         (* Text used to generate the MBUTIL key *)
      username : array[0..USERS-1] of str36;  (* User names *)
      hmbpath         : str53;  (* Hudson message base path *)
      mailpath        : str53;  (* Netmail path *)
      inbound_path    : str53;  (* Where incoming compressed mail is stored *)
      outbound_path   : str53;  (* Where outgoing compressed mail is stored *)
      echotoss_file   : str65;  (* The ECHOTOSS.LOG used for Squish areas *)
      nodepath        : str53;  (* Not used *)
      areasfile       : str65;  (* AREAS.BBS style file *)
      logfile         : str65;  (* GEcho/MBUTIL log file *)
      mgrlogfile      : str65;  (* AreaMgr log file *)
      swap_path       : str53;  (* Swap path *)
      tear_line       : str31;  (* Tearline to be placed by MBUTIL Export *)
      originline : array[0..19] of str61;  (* Origin lines *)
      compr_prog       : array[0..9] of str13;  (* Compression program filenames *)
      compr_switches   : array[0..9] of str20;  (* Compression program switches *)
      decompr_prog     : array[0..9] of str13;  (* Decompression program filenames *)
      decompr_switches : array[0..9] of str20;  (* Decompression program switches *)
      oldgroups : array[0..25] of str21;  (* Descriptions of area groups *)
      lockmode       : byte;    (* See --- Locking method *)
      secure_path    : str53;   (* From which secure PKTs are tossed *)
      rcvdmailpath   : str53;   (* Directory to which Rcvd netmail is moved *)
      sentmailpath   : str53;   (* Directory to which Sent netmail is moved *)
      semaphorepath  : str53;   (* Where FD rescan files are stored *)
      version_major  : byte;    (* Major GEcho version *)
      version_minor  : byte;    (* Minor GEcho version *)
      semaphore_mode : byte;    (* See --- Semaphore mode *)
      badecho_path   : str53;   (* Where sec. violating and unknown mail is stored *)
      mailer_type    : byte;    (* See --- Mailer type *)
      loglevel       : word;    (* See --- Log level *)
      akamatch : array[0..19] of AKAMATCH;  (* AKA matching table *)
      mbulogfile     : str65;   (* MBUTIL log file *)
      maxqqqs        : word;    (* Max. number of QQQ info stored in memory *)
      maxqqqopen     : byte;    (* Not used *)
      maxhandles     : byte;    (* Max. number of files used by GEcho *)
      maxarcsize     : word;    (* Max. archive size, 0 = unlimited *)
      delfuture      : word;    (* Days to delete messages in the future, 0 = disable *)
      extraoptions   : word;    (* See --- Extra option bits *)
      firstboard     : byte;    (* Not used *)
      reserved1      : word;    (* Reserved *)
      copy_persmail  : word;    (* Not used *)
      oldpersmailboard  : array[0..USERS-1] of byte;  (* Personal mail board (0 = path) *)
      old_public_groups : dword;   (* Public groups (bits 0-25) *)
      dupentries     : word;    (* Number of duplicate entries in ECHODUPE.GE *)
      oldrcvdboard   : byte;    (* Where Rcvd netmail is moved to (0 = path) *)
      oldsentboard   : byte;    (* Where Sent netmail is moved to (0 = path) *)
      oldakaboard    : array[0..OLDAKAS-1] of byte;  (* Netmail boards for AKAs *)
      olduserboard   : array[0..USERS-1] of byte;    (* Netmail boards for system users, 255 = use AKA board *)
      reserved2      : byte;    (* Reserved *)
      uplink : array[0..OLDUPLINKS-1] of OLDUPLINK;  (* Not used *)
      persmail_path  : str53;   (* Not used *)
      outpkts_path   : str53;   (* Where outbound packets are temp. stored *)
      compr_mem : array[0..9] of word;    (* Memory needed for compression programs *)
      decompr_mem : array[0..9] of word;  (* Memory needed for decompression programs *)
      pwdcrc          : dword;   (* CRC-32 of access password, -1L = no password *)
      default_maxmsgs : word;    (* Maximum number of messages       (Purge) *)
      default_maxdays : word;    (* Maximum age of non-Rcvd messages (Purge) *)
      gus_prog        : str13;   (* General Unpack Shell program filename *)
      gus_switches    : str20;   (* GUS switches *)
      gus_mem         : word;    (* Memory needed for GUS *)
      default_maxrcvddays : word;    (* Maximum age of Rcvd messages (Purge) *)
      checkname        : byte;   (* See --- Check user name *)
      maxareacachesize : byte;   (* Area cache size, 0 .. 64 KB *)
      inpkts_path      : str53;  (* Where inbound mail packets should be stored *)
      pkt_prog         : str13;  (* Called before each tossed mail packet *)
      pkt_switches     : str20;  (* Command line switches *)
      pkt_mem          : word;   (* Memory needed *)
      maxareas         : word;   (* Maximum number of areas *)
      maxconnections   : word;   (* Maximum number of connections per area *)
      maxnodes         : word;   (* Maximum number of nodes *)
      default_minmsgs  : word;   (* Minimum number of messages       (Purge) *)
      bbs_type         : byte;   (* See --- BBS type *)
      decompress_ext   : byte;   (* 0 = 0-9, 1 = 0-F, 2 = 0-Z *)
      reserved3        : byte;   (* Reserved *)
      change_tearline  : byte;   (* See --- Change tear line *)
      prog_notavail : word;      (* Bit 0-9, 1 = program not available *)
      gscolor : COLORSET;        (* GSETUP color set, See COLORSET structure *)
      reserved4 : array[1..9] of byte;  (* Reserved *)

      aka : array[0..AKAS-1] of AddrType;         (* Main address and AKAs *)
      pointnet : array[0..AKAS-1] of word;       (* Pointnets for all addresses *)
      akaarea  : array[0..AKAS-1] of word;       (* AKA netmail areas *)
      userarea : array[0..USERS-1] of word;      (* Netmail areas for system users, 0=don't import, 65535 = use AKA board *)
      persmailarea : array[0..USERS-1] of word;  (* Personal mail area (0 = don't copy) *)
      rcvdarea     : word;   (* Rcvd netmail area (0 = don't move) *)
      sentarea     : word;   (* Sent netmail area (0 = don't move) *)
      badarea      : word;   (* Where bad echomail is stored (0 = path) *)
      reserved5    : word;   (* Not used *)
      jampath      : str53;  (* JAM message base path *)
      userbase     : str53;  (* User base path *)
      dos4gw_exe : str65;    (* DOS4GW.EXE protected mode run time file *)
      public_groups : GROUPS;  (* Public groups (bits 0-255) *)
      maxgroupconnections : word;  (* Maximum number of connections per group *)
      maxmsgsize : word;           (* Maximum message size (64-1024 kB) *)
      diskspace_threshold : word;  (* Amount of free disk space that causes packing *)
      pktsort : byte;              (* 0 = No, 1 = Area, 2 = Area + Date/Time *)
      wildcatpath : Str53;         (* Wildcat! home path *)
   end;

(***************************************************************************)

(* --- Area option bits *)

const
   IMPORTSB  = $0001;  (* Import SEEN-BY lines to message base *)
   SECURITY  = $0002;  (* Only accept mail from nodes in connections list *)
   PASSTHRU  = $0004;  (* Mail is not imported, only forwarded *)
   VISIBLE   = $0008;  (* Area is visible for anyone in AreaMgr's %LIST *)
   REMOVED   = $0010;  (* Area should be removed by GSETUP Pack *)
   NOUNLINK  = $0020;  (* Do not allow users to unlink this area *)
   TINYSB    = $0040;  (* Tiny SEEN-BYs with only nodes in connections list *)
   PVT       = $0080;  (* Private bits are preserved and are not stripped *)
   CHECKSB   = $0100;  (* Use SEEN-BYs for duplicate prevention *)
   NOSLEEP   = $0200;  (* Do not allow users to pause this area *)
   SDM       = $0400;  (* Area is stored in *.MSG format *)
   HIDESB    = $0800;  (* Hide imported SEEN-BY lines *)
   NOIMPORT  = $1000;  (* AreaMgr will set new nodes to Export-Only *)
   DELFUTURE = $2000;  (* Del messages dated in the future *)
   NOTIFIED  = $4000;  (* Sysop notified that area was disconnected *)
   UPLDISC   = $8000;  (* Disconnected from uplink (only for PT areas) *)


(* --- Extra area option bits *)

   NODUPECHK = $01;  (* Don't do duplicate checking for this area *)
   NOLINKING = $02;  (* Don't do reply chain linking for this area *)
   HIDDEN    = $04;  (* Area is hidden for everyone *)


(* --- Area type *)

   geECHOMAIL  = 0;
   geNETMAIL   = 1;
   geLOCAL     = 2;
   geBADECHO   = 3;
   gePERSONAL  = 4;
   geNUM_TYPES = 5;


(* --- Area format *)

   FORMAT_PT     = 0;  (* Passthru *)
   FORMAT_HMB    = 1;  (* Hudson Message Base *)
   FORMAT_SDM    = 2;  (* *.MSG base *)
   FORMAT_JAM    = 3;  (* Joaquim-Andrew-Mats message base proposal *)
   FORMAT_PCB    = 4;  (* PCBoard 15.0 *)
   FORMAT_SQUISH = 5;  (* Squish 2.0 *)
   FORMAT_WC     = 6;  (* Wildcat! 4.0 *)
   NUM_FORMATS   = 7;


(* --- AREAFILE.GE header *)

type
   AREAFILE_HDR = record
      hdrsize        : word;  (* sizeof(AREAFILE_HDR) *)
      recsize        : word;  (* sizeof(AREAFILE_GE) *)
      maxconnections : word;  (* Maximum number of entries in connections list *)
   end;


(* --- AREAFILE.GE record *)

   AREAFILE_GE = record
      name         : str51;  (* Area name, must be uppercase, no spaces *)
      comment      : str61;  (* Description of the topics discussed in area *)
      path         : str51;  (* Location where *.MSG files are stored *)
      originline   : str61;  (* Custom origin line, used if origlinenr = 0 *)
      areanumber   : word;   (* Area number (1-200 = Hudson) *)
      group        : char;   (* Group (0-255) *)
      options      : word;   (* See --- Area options bits *)
      originlinenr : byte;   (* Origin line (1-20, 0 = custom) *)
      pkt_origin   : byte;   (* Address for the packet/Origin line (0-31) *)
      seenbys      : dword;  (* Addresses (bits 0-31) to add to the SEEN-BY *)
      maxmsgs      : word;   (* Maximum number of messages       (MBUTIL Purge) *)
      maxdays      : word;   (* Maximum age of non-Rcvd messages (MBUTIL Purge) *)
      maxrcvddays  : word;   (* Maximum age of Rcvd messages     (MBUTIL Purge) *)
      areatype     : byte;   (* See --- Area type *)
      areaformat   : byte;   (* See --- Area format *)
      extraoptions : byte;   (* See --- Extra area option bits *)
   end;


(* --- Connection entry status bits *)

const
   CONN_NOIMPORT = $01;  (* Don't accept mail from this node *)
   CONN_NOEXPORT = $02;  (* Don't forward mail to this node *)
   CONN_PAUSE    = $04;  (* Temporary don't send this area to this node *)
   CONN_NOUNLINK = $08;  (* Don't allow this node to disconnect *)
   CONN_ISUPLINK = $10;  (* Node is uplink for this area *)


(* --- Connections list entry *)

type
   CONNECTION = record
      address : AddrType;
      status  : byte;
   end;


(* --- AREAFILE.GEX record *)

   AREAFILE_GEX = record
      crc32      : longint;  (* CRC-32 on areaname *)
      areanumber : word;     (* Area number (1-200 = Hudson) *)
      offset     : longint;  (* File offset of record in AREAFILE.GE *)
   end;

(***************************************************************************)

(* --- Group option bits *)

const
   GROUP_REMOVED = $01;  (* Group record has been deleted *)
   GROUP_ALWAYS  = $02;  (* Unconditionally forward requests *)


(* --- GRPFILE.GE header *)

type
   GRPFILE_HDR = record
      hdrsize        : word;  (* sizeof(GRPFILE_HDR) *)
      recsize        : word;  (* sizeof(GRPFILE_GE) *)
      arearecsize    : word;  (* sizeof(AREAFILE_GE) *)
      maxconnections : word;  (* Maximum number of entries in connections list *)
   end;

(* --- GRPFILE.GE record *)

type
   GRPFILE_GE = record
      options  : byte;   (* See --- Group option bits *)
      filename : str65;  (* "Forward List" filename *)
      filetype : byte;   (* 0 = Random, 1 = "<areaname> <description>" *)
   end;


(* --- GRPFILE.GEX record *)

   GRPFILE_GEX = record
      address : AddrType;  (* Address of the uplink *)
      offset  : longint;  (* File offset of record in GRPFILE.GE *)
      group   : byte;     (* Group (0-255) *)
   end;

(***************************************************************************)

(* --- Status:
   $0000 = None
   $0002 = Crash
   $0200 = Hold
   $FFFF = Removed entry
*)


(* --- Node option bits *)

const
   REMOTEMAINT = $0001;  (* Allow node to use %FROM *)
   ALLOWRESCAN = $0002;  (* Allow node to use %RESCAN *)
   FORWARDREQ  = $0004;  (* Allow node to forward AreaMgr requests *)
   MAIL_DIRECT = $0008;  (* Use Direct status for mail archives *)
   NONOTIFY    = $0010;  (* Don't send Notify list *)
   PACKNETMAIL = $0020;  (* Pack netmail for this node *)
   CHKPKTPWD   = $0040;  (* Check packet password (auto-enabled) *)
   MGR_DIRECT  = $0080;  (* Use Direct status for AreaMgr messages *)
   ARCMAIL     = $0100;  (* Use ARCmail 0.60 naming for out-of-zone mail *)
   FORWARDPKTS = $0200;  (* Forward packets to this node *)
   DAILY_MAIL  = $0400;  (* Create a new mail archive every day *)
   NOPKTPWDCHK = $0800;  (* Disable check packet password *)


(* --- Uplink option bits *)

   UPLINK_ADDPLUS = $04;  (* Add '+' prefix *)


(* --- Unknown areas *)

   UNKNOWN_BADECHO    = 0;
   UNKNONW_ADDAREA    = 1;
   UNKNOWN_DISCONNECT = 2;
   UNKNOWN_KILLMSGS   = 3;


(* --- NODEFILE.GE header *)

type
   NODEFILE_HDR = record
      hdrsize : word;  (* sizeof(NODEFILE_HDR) *)
      recsize : word;  (* sizeof(NODEFILE_GE) *)
   end;


(* --- NODEFILE.GE record *)

   NODEFILE_GE = record
      address       : AddrType;  (* Address of the node *)
      sysop         : str36;    (* Name of the sysop or point *)
      pktpwd        : str9;     (* Packet (session) password *)
      mgrpwd        : str17;    (* AreaMgr password *)
      oldgroups     : dword;    (* AreaMgr groups (bits 0-25) *)
      options       : word;     (* See --- Node option bits *)
      comprtype     : byte;     (* Compression type (0-9, 10 = PKT) *)
      mailstatus    : word;     (* Mail archive status. See above *)
      route_to      : AddrType;  (* Address to route mail files to *)
      oldreadgroups : dword;    (* Read/write groups (bits 0-25) *)
      mgrstatus     : word;     (* AreaMgr message status *)
      compress_ext  : byte;     (* 0 = 0-9, 1 = 0-F, 2 = 0-Z *)
      maxdays       : word;     (* Maximum age of mail archive, 0 = Unlimited *)
      groups        : GROUPS;   (* Read/write groups (bits 0-255) *)
      readgroups    : GROUPS;   (* Read groups (bits 0-255) *)
      areafix       : str9;     (* AreaFix program *)
      outmgrpwd     : str17;    (* AreaFix password (outbound) *)
      uplinkoptions : byte;     (* See --- Uplink option bits *)
      unknownareas  : byte;     (* See --- Unknown areas *)
      default_group : byte;     (* Default group for added areas *)
   end;


(* --- NODEFILE.GEX index entry *)

   NODEFILE_GEX = record
      address : AddrType;  (* Address of the node *)
      offset  : longint;  (* File offset of record in NODEFILE.GE *)
   end;

(***************************************************************************)

(* --- Routed node status *)

const
   ZONE_ALL = $01;
   NET_ALL  = $02;
   NODE_ALL = $04;


(* --- Routed node entry *)

type
   ROUTE = record
      node   : AddrType;  (* Routed node address *)
      status : byte;     (* See --- Routed node status *)
      via    : byte;     (* Via entry for this routed node (0-59) *)
   end;


(* --- PACKFILE.GE structure *)

   PACKFILE_GE = record
      via   : array[0..MAXVIAS-1] of AddrType;
      route : array[0..MAXROUTES-1] of ROUTE;
   end;

(***************************************************************************)

(* --- ECHODUPE.GE structure *)

   ECHODUPE_GE = record
      pointer : word;  (* Next offset *)
      entries : word;  (* Number of entries in the database *)
(*    crc32_high : array[0..entries-1];  CRC-32's on headers, high portions *)
(*    crc32_low  : array[0..entries-1];  CRC-32's on headers, low portions  *)
   end;

(***************************************************************************)

(* --- FTSCPROD.GE record *)

   FTSCPROD_GE = record
      cap  : byte;   (* Capability: 0 = Type 2.0, 1 = Type 2.1, 2 = Type 2+ *)
      name : str30;  (* Name of product *)
   end;

(***************************************************************************)

(* --- JAM_CONV.GE record *)

   JAMCONV_GE = record
      areanumber : word;
      name       : str51;
      jambase    : str51;
   end;

(***************************************************************************)

(* --- MBUTIL.RNX record *)

   MBUTIL_RNX = record
      old_msgnum : word;
      new_msgnum : word;
   end;

(* end of file "gestruct.inc" *)

Implementation

end.
