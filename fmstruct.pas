Unit FmStruct;

Interface

Uses
  MkGlobT;

Const
  DATATYPE_CF = $0102;{ not used yet                     }
  DATATYPE_NO = $0202;{ node file                        }
  DATATYPE_AD = $0401;{ area file for echo mail defaults }
  DATATYPE_AE = $0402;{ area file for echo mail          }

  MAX_AKAS      = 32;
  MAX_AKAS_F    = 64;
  MAX_AKAS_OLD  = 16;
  MAX_NA_OLD    = 11;
  MAX_NETAKAS   = 32;
  MAX_NETAKAS_F = 64;
  MAX_USERS     = 16;
  MAX_UPLREQ    = 32;
  MAX_MATCH     = 16;          { not used yet }

  LOG_NEVER     = $0000;
  LOG_INBOUND   = $0001;
  LOG_OUTBOUND  = $0002;
  LOG_PKTINFO   = $0004;
  LOG_XPKTINFO  = $0008;
  LOG_UNEXPPWD  = $0010;
  LOG_SENTRCVD  = $0020;
  LOG_STATS     = $0040;
  LOG_PACK      = $0080;
  LOG_MSGBASE   = $0100;
  LOG_ECHOEXP   = $0200;
  LOG_NETIMP    = $0400;
  LOG_NETEXP    = $0800;
  LOG_OPENERR   = $1000;
  LOG_EXEC      = $2000;
  LOG_NOSCRN    = $4000;
  LOG_ALWAYS    = $8000;
  LOG_DEBUG     = $8000;

  MAX_AREAS     = 4096;
  MAX_FORWARD   = 64;

  MB_PATH_LEN_OLD  = 19;
  MB_PATH_LEN      = 61;
  ECHONAME_LEN_090 = 25;
  ECHONAME_LEN     = 51;
  COMMENT_LEN      = 51;
  ORGLINE_LEN      = 59;

Type
  { ********** General structures ********** }
  FMailArchiverInfo = record
    ProgramName:        Array[0..45] of Char;
    MemRequired:        Word;
  end;

  FMailPathType = Array[0..47] of Char;

  FMailNodeFakeType = record
    NodeNum:            AddrType;
    FakeNet:            Word;
  end;

  { ********** File header structure ********** }

  FMailHeaderType = record
    VersionString:      Array[0..31] of Char; { Always starts with 'FMail' }
    RevNumber,                                { Is now $0100 }
    DataType,                                 { See Consts above }
    HeaderSize:         Word;
    CreationDate,
    LastModified:       LongInt;
    TotalRecords,
    RecordSize:         Word;
  end;

  { The structure below is used by the Areas File and (only partly)
    by the Config File }

  FMailAreaOptionsTypeSet = (
    Active,      { Bit 0  }
    TinySeenBy,  { Bit 1  }
    Security,    { Bit 2  }
    _AO_Bit3,    { Bit 3  }
    AllowPrivate,{ Bit 4  }
    ImpSeenBy,   { Bit 5  }
    CheckSeenBy, { Bit 6  }
    _AO_Bit7,    { Bit 7  }
    OLocal,      { Bit 8  }
    Disconnected,{ Bit 9  }
    _Reserved,   { Bit 10 }
    AllowAreafix,{ Bit 11 }
    _AO_Bit12,   { Bit 12 }
    _AO_Bit13,   { Bit 13 }
    ArrivalDate, { Bit 14 }
    SysopRead    { Bit 15 }
  );

  FMailAreaOptionsType = Set of FMailAreaOptionsTypeSet;

  { ********** FMAIL.CFG ********** }

  FMail_AkaListType = Array[0..MAX_AKAS_OLD-1] of FMailNodeFakeType;
  FMailAkaListType  = Array[0..MAX_AKAS_F-1] of FMailNodeFakeType;

  FMailGenOptionsTypeSet = (
    UseEMS,     { BIT 0 }
    CheckBreak, { BIT 1 }
    Swap,       { BIT 2 }
    SwapEMS,    { BIT 3 }
    SwapXMS,    { BIT 4 }
    _GO_Bit5,
    Monochrome, { BIT 6 }
    CommentFFD, { BIT 7 }
    PTAreasBBS, { BIT 8 }
    CommentFRA, { BIT 9 }
    _GO_Bit10,  { BIT 10 }
    IncBDRRA,   { BIT 11 }
    _GO_Bit12,  { BIT 12 }
    _GO_Bit13,
    _GO_Bit14,
    _RA2        { BIT 15 }
  );

  FMailGenOptionsType = Set Of FMailGenOptionsTypeSet;

  FMailMailOptionsTypeSet = (
    RemoveNetKludges,{ Bit 0 }
    AddPointToPath,  { Bit 1 }
    CheckPktDest,    { Bit 2 }
    NeverARC060,     { Bit 3 }
    CreateSema,      { Bit 4 }
    DailyMail,       { Bit 5 }
    WarnNewMail,     { bit 6 }
    KillBadFAtt,     { Bit 7 }
    DupDetection,    { Bit 8 }
    IgnoreMSGID,     { Bit 9 }
    ARCmail060,      { Bit 10 }
    ExtNames,        { Bit 11 }
    PersNetmail,     { Bit 12 }
    PrivateImport,   { Bit 13 }
    KeepExpNetmail,  { Bit 14 }
    KillEmptyNetmail { Bit 15 }
  );

  FMailMailOptionsType = Set of FMailMailOptionsTypeSet;

  FMailmbOptionsTypeSet = (
    SortNew,      { bit  0   }
    SortSubject,  { bit  1   }
    UpdateChains, { bit  2   }
    ReTear,       { bit  3   }
    _MB_Bit4,     { bit  4   }
    _MB_Bit5,     { bit  5   }
    RemoveRe,     { bit  6   }
    RemoveLfSr,   { bit  7   }
    ScanAlways,   { bit  8   }
    ScanUpdate,   { bit  9   }
    MultiLine,    { bit 10   }
    _MB_Bit11,    { bit 11   }
    QuickToss,    { bit 12   }
    _MB_Bit13,    { bit 13   }
    _MB_Bit14,    { bit 14   }
    SysopImport   { bit 15   }
  );

  FMailmbOptionsType = Set of FMailmbOptionsTypeSet;

  FMailMgrOptionsTypeSet = (
    KeepRequest,  { Bit  0 }
    KeepReceipt,  { Bit  1 }
    _MGR_Bit2,    { Bit 2-3 }
    _MGR_Bit3,
    AutoDiscArea, { Bit  4 }
    AutoDiscDel,  { Bit  5 has temp. no effect, rec is always deleted }
    _MGR_Bit6,    { Bit 6-8 }
    _MGR_Bit7,    { Bit 6-8 }
    _MGR_Bit8,    { Bit 6-8 }
    AllowAddAll,  { Bit  9 }
    AllowActive,  { Bit 10 }
    _MGR_Bit11,   { Bit 11 }
    AllowPassword,{ Bit 12 }
    AllowPktPwd,  { Bit 13 }
    AllowNotify,  { Bit 14 }
    AllowCompr    { Bit 15 }
  );

  FMailMgrOptionsType = Set of FMailMgrOptionsTypeSet;

  FMailUplOptTypeSet = (
    AddPlusPrefix, { Bit 0 }
    _UPL_Bit1,
    _UPL_Bit2,
    _UPL_Bit3,
    Unconditional, { Bit 4 }
    _UPL_Bit5,
    _UPL_Bit6,
    _UPL_Bit7,
    _UPL_Bit8,
    _UPL_Bit9,
    _UPL_Bit10,
    _UPL_Bit11,
    _UPL_Bit12,
    _UPL_Bit13,
    _UPL_Bit14,
    _UPL_Bit15
  );

  FMailUplOptType = Set of FMailUplOptTypeSet;

  FMailUserType = record
    UserName:  Array[0..35] of Char;
    Reserved:  Array[0..27] of Char;
  end;

  FMailUplinkReqType = record
    Node:       AddrType;
    Program_:   Array[0..8] of Char;
    Password:   Array[0..16] of Char;
    FileName:   Array[0..12] of Char;
    FileType:   Byte;
    Groups:     LongInt;
    OriginAKA:  Byte;
    Options:    FMailUplOptType;
    Reserverd:  Array[0..8] of Char;
  end;

  FMailAkaMatchNodeType = record
    Valid, Zone, Net, Node:     Word;
  end;

  FMailAkaMatchType = record
    AmNode:     FMailAkaMatchNodeType;
    Aka:        Word;
  end;

  { ATTENTION: FMAIL.CFG does NOT use the new config file type yet (no header) !!! }

  FMailconfigType = record
    VersionMajor,
    VersionMinor:       Byte;
    CreatioNDate,
    Key,
    ReservedKey,
    RelKey1,
    RelKey2:            LongInt;
    Reserverd1:         Array[0..21] of Char;
    MgrOptions:         FMailMgrOptionsType;
    _AkaList:           FMail_akaListType;
    _NetMailBoard:      Array[0..MAX_NA_OLD-1] of Word;
    _ReservedNet:       Array[0..15-MAX_NA_OLD] of Word;
    GenOptions:         FMailGenOptionsType;
    MbOptions:          FMailmbOptionsType;
    MailOptions:        FMailMailOptionsType;
    MaxPktSize,
    kDupRecs,
    Mailer,
    BBSprogram,
    MaxBundleSize,
    ExtraHandles,                                               { 0 - 255 }
    AutoRenumber,
    BufSize,
    FtBufSize,
    AllowedNumNetmail,
    LogInfo,
    LogStyle:           Word;
    Reserved2:          Array[0..67] of Char;
    ColorSet:           Word;
    SysopName:          Array[0..35] of Char;
    DefaultArc,
    _adiscDaysNode,
    _adiscDaysPoint,
    _adiscSizeNode,
    _adiscSizePoint:    Word;
    Reserved3:          Array[0..15] of Char;
    TearType:           Byte;
    TearLine:           Array[0..24] of Char;
    SummaryLongName:    FMailPathType;
    RecBoard,
    BadBoard,
    DupBoard:           Word;
    Topic1,
    Topic2:             Array[0..15] of Char;
    BBSPath,
    NetPath,
    SentPath,
    RcvdPath,
    InPath,
    OutPath,
    SecurePath,
    LogName,
    SwapPath,
    SemaphorePath,
    PmailPath,
    AreaMgrLogName,
    AutoRAPath,
    AutoFolderFdPath,
    AutoAreasBBSPath,
    AutoGoldEdAreasPath:FMailPathType;
    unArc,
    unZip,
    unLzh,
    unPak,
    unZoo,
    unArj,
    unSqz,
    GUS,
    arc,
    zip,
    lzh,
    pak,
    zoo,
    arj,
    sqz,
    customArc:          FMailArchiverInfo;
    AutoFMail102Path:   FMailPathType;
    Reserved4:          Array[0..34] of Char;
    _optionsAKA:        Array[0..MAX_NA_OLD-1] of FMailAreaOptionsType;
    _groupsQBBS:        Array[0..MAX_NA_OLD-1] of Char;
    _templateSecQBBS:   Array[0..MAX_NA_OLD-1] of Word;
    _templateFlagsQBBS: Array[0..MAX_NA_OLD-1] of Array[0..3] of Char;
    _attr2RA:           Array[0..MAX_NA_OLD-1] of Char;
    _aliasesQBBS:       Array[0..MAX_NA_OLD-1] of Char;
    _groupRA:           Array[0..MAX_NA_OLD-1] of Word;
    _altGroupRA:        Array[0..MAX_NA_OLD-1] of Array[0..2] of Word;
    _qwkName:           Array[0..MAX_NA_OLD-1] of Array[0..12] of Char;
    _minAgeSBBS:        Array[0..MAX_NA_OLD-1] of Word;
    _daysRcvdAKA:       Array[0..MAX_NA_OLD-1] of Word;
    _replyStatSBBS:     Array[0..MAX_NA_OLD-1] of Char;
    _attrSBBS:          Array[0..MAX_NA_OLD-1] of Word;
    GroupDescr:         Array[0..25] of Array[0..26] of Char;
    Reserved5:          Array[0..8] of Char;
    _msgKindsRA:        Array[0..MAX_NA_OLD-1] of Char;
    _attrRA:            Array[0..MAX_NA_OLD-1] of Char;
    _readSecRA:         Array[0..MAX_NA_OLD-1] of Word;
    _readFlagsRA:       Array[0..MAX_NA_OLD-1] of Array[0..3] of Char;
    _writeSecRA:        Array[0..MAX_NA_OLD-1] of Word;
    _writeFlagsRA:      Array[0..MAX_NA_OLD-1] of Array[0..3] of Char;
    _sysopSecRA:        Array[0..MAX_NA_OLD-1] of Word;
    _sysopFlagsRA:      Array[0..MAX_NA_OLD-1] of Array[0..3] of Char;
    _daysAKA:           Array[0..MAX_NA_OLD-1] of Word;
    _msgsAKA:           Array[0..MAX_NA_OLD-1] of Word;
    _descrAKA:          Array[0..MAX_NA_OLD-1] of Array[0..50] of Char;
    Users:              Array[0..MAX_USERS-1] of FMailUserType;
    AkaMatch:           Array[0..MAX_MATCH-1] of FMailAkaMatchType; { Not used yet }
    Reserved6:          Array[1..1040-10*MAX_MATCH] of Char;
    SentEchoPath:       FMailPathType;
    PreUnarc,
    PostUnarc,
    PreArc,
    PostArc,
    UnUc2,
    UnRar:              FMailArchiverInfo;
    ResUnpack:          Array[0..5] of FMaiLArchiverInfo;
    Uc2,
    Rar:                FMailArchiverInfo;
    ResPack:            Array[0..5] of FMailArchiverInfo;
    UplinkReq:          Array[0..MAX_UPLREQ+31] of FMailUplinkReqType;
    UnArc32,
    UnZip32,
    UnLzh32,
    UnPak32,
    UnZoo32,
    UnArj32,
    UnSqz32,
    UnUc232,
    UnRar32,
    GUS32:              FMailArchiverInfo;
    ResUnpack32:        Array[0..5] of FMailArchiverInfo;
    PreUnarc32,
    PostUnarc32,
    Arc32,
    Zip32,
    Lzh32,
    Pak32,
    Zoo32,
    Arj32,
    Sqz32,
    Uc232,
    Rar32,
    CustomArc32:        FMailArchiverInfo;
    ResPack32:          Array[0..5] of FMailArchiverInfo;
    PreArc32,
    PostArc32:          FMailArchiverInfo;
    descrAKA:           Array[0..MAX_NETAKAS-1] of Array[0..50] of Char;
    qwkName:            Array[0..MAX_NETAKAS-1] of Array[0..12] of Char;
    optionsAKA:         Array[0..MAX_NETAKAS-1] of FMailAreaOptionsType;
    msgKindsRA:         Array[0..MAX_NETAKAS-1] of Char;
    daysAKA:            Array[0..MAX_NETAKAS-1] of Word;
    msgsAKA:            Array[0..MAX_NETAKAS-1] of Word;
    groupsQBBS:         Array[0..MAX_NETAKAS-1] of Char;
    attrRA:             Array[0..MAX_NETAKAS-1] of Char;
    attr2RA:            Array[0..MAX_NETAKAS-1] of Char;
    attrSBBS:           Array[0..MAX_NETAKAS-1] of Word;
    aliasesQBBS:        Array[0..MAX_NETAKAS-1] of Char;
    groupRA:            Array[0..MAX_NETAKAS-1] of Word;
    altGroupRA:         Array[0..MAX_NETAKAS-1] of Array[0..2] of Word;
    minAgeSBBS:         Array[0..MAX_NETAKAS-1] of Word;
    daysRcvdAKA:        Array[0..MAX_NETAKAS-1] of Word;
    replyStatSBBS:      Array[0..MAX_NETAKAS-1] of Char;
    readSecRA:          Array[0..MAX_NETAKAS-1] of Word;
    readFlagsRA:        Array[0..MAX_NETAKAS-1] of Array[0..7] of Char;
    writeSecRA:         Array[0..MAX_NETAKAS-1] of Word;
    writeFlagsRA:       Array[0..MAX_NETAKAS-1] of Array[0..7] of Char;
    sysopSecRA:         Array[0..MAX_NETAKAS-1] of Word;
    sysopFlagsRA:       Array[0..MAX_NETAKAS-1] of Array[0..7] of Char;
    templateSecQBBS:    Array[0..MAX_NETAKAS-1] of Word;
    templateFlagsQBBS:  Array[0..MAX_NETAKAS-1] of Array[0..7] of Char;
    Reserved7:          Array[0..511] of Char;
    netmailBoard:       Array[0..MAX_NETAKAS_F-1] of Word;
    AkaList:            FMailakaListType;
  end;

  { ********** FMAIL.AR ********** }

  FMailAreaNameType = Array[0..ECHONAME_LEN-1] of Char;

  { See Area File for file header structure !!! }

  FMailAreaStatTypeSet = (
    TossedTo, { Bit 0   }
    _ST_Bit1, { Bit 1-15 }
    _ST_Bit2, { Bit 1-15 }
    _ST_Bit3, { Bit 1-15 }
    _ST_Bit4, { Bit 1-15 }
    _ST_Bit5, { Bit 1-15 }
    _ST_Bit6, { Bit 1-15 }
    _ST_Bit7, { Bit 1-15 }
    _ST_Bit8, { Bit 1-15 }
    _ST_Bit9, { Bit 1-15 }
    _ST_Bit10,{ Bit 1-15 }
    _ST_Bit11,{ Bit 1-15 }
    _ST_Bit12,{ Bit 1-15 }
    _ST_Bit13,{ Bit 1-15 }
    _ST_Bit14,{ Bit 1-15 }
    _ST_Bit15 { Bit 1-15 }
  );

  FMailAreaStatType = Set of FMailAreaStatTypeSet;

  FMailRawEchoType = record
    Signature:          Array[0..1] of Char;
                              { contains "AE" for echo areas in FMAIL.AR and }
                              { "AD" for default settings in FMAIL.ARD       }
    WriteLevel:         Word;
    AreaName:           FMailAreaNameType;
    Comment:            Array[0..COMMENT_LEN-1] of Char;
    Options:            FMailAreaOptionsType;
    BoardNumRA:         Word;
    MsgBaseType:        Byte;
    MsgBasePath:        Array[0..MB_PATH_LEN-1] of Char;
    Board:              Word;
    OriginLine:         Array[0..ORGLINE_LEN-1] of Char;
    Address:            Word;
    Group:              LongInt;
    _alsoSeenBy,                  { obsolete: see the 32-bit alsoSeenBy below }
    msgs,
    days,
    daysRcvd:           Word;

    Export:             Array[0..MAX_FORWARD-1] of AddrType;

    ReadSecRA:          Word;
    FlagsRdRA:          Array[0..3] of Char;
    FlagsRdNotRA:       Array[0..3] of Char;
    WriteSecRA:         Word;
    flagsWrRA:          Array[0..3] of Char;
    flagsWrNotRA:       Array[0..3] of Char;
    SysopSecRA:         Word;
    FlagsSysRA:         Array[0..3] of Char;
    FlagsSysNotRA:      Array[0..3] of Char;
    TemplateSecQBBS:    Word;
    FlagsTemplateQBBS:  Array[0..3] of Char;
    _internalUse:       Char;
    NetReplyBoardRA:    Word;
    BoardTypeRA,
    AttrRA,
    Attr2RA:            Char;
    GroupRA:            Word;
    AltGroupRA:         Array[0..2] of Word;
    msgKindsRA:         Char;
    QwkName:            Array[0..12] of Char;
    minAgeSBBS,
    AttrSBBS:           Word;
    replyStatSBBS,
    groupsQBBS,
    aliasesQBBS:        Char;
    lastMsgTossDat,
    lastMsgScanDat,
    alsoSeenBy:         LongInt;
    Stat:               FMailAreaStatType;
    Reserved:           Array[0..179] of Char;
  end;

Implementation

end.
