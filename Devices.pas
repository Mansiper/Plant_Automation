(*
	Тут описаны все возможные устройства (которые мы использовали и абстрактные), их действия.
	Некоторые части довольно не просто понять сходу, но я старался делать всё максимально
	универсально на все случаи жизни в сфере наших работ.
*)

unit Devices;

interface

uses Commands, Classes, Windows, SysUtils, Generics.Collections, Math, ExtCtrls;

function BytesToSingle(Data: Array of Byte): Single;
function BytesToInt32(Data: Array of Byte): Int32;
function SingleToBytes(Value: Single): TBytes;
function Int32ToBytes(Value: Int32): TBytes;

type
  TDeviceTypes = (dtUnknown, dtM110_4, dtM110_2, dtM210_1, dtK001_081, dtK001_091, dtK001_D,
    dtK001_1102, dtPTC001, dtDIOM, dtI110_16D, dtI110_32DN, dtO110_32R, dtKGD);
  TKBTypes = (kbtUnknown, kbt001_081, kbt001_091, kbt001_D, kbt001_1102, kbtPTC001);
  TDIMTypes = (ditUnknown, dit110_16D, dit110_32DN);
  TDOMTypes = (dotUnknown, dot110_32R);
  TBatTypes = (btDD, btVD);

    //Parent for all device classes
  TDevice = class(TInterfacedObject)
  private
    FDevType: TDeviceTypes; //Current device type
    FName: String;  //Name or description of device
  public
    constructor Create;
    property Name: String read FName write FName;
    property DevType: TDeviceTypes read FDevType write FDevType;
  end;

  TComDevice = class;
  TWeightController = class;
  TDIOM = class;
  TDIM = class;
  TDOM = class;
  TKB = class;
  TKGD = class;
  TBatcher = class;
  TDropper = class;
  TMixer = class;
    //Container for all devices
  TDevLists = class
  private
    const
      cAlreadyExists = 'Device with this address already exists';
    var
      FDIOM: TObjectList<TDIOM>;        //List of DIOMs				Овен МДВВ
      FDIM: TObjectList<TDIM>;          //List of DIMs				Овен МВ-xxx
      FDOM: TObjectList<TDOM>;          //List of DOMs				Овен МУ-xxx
      FKB: TObjectList<TKB>;            //List of KBs					Вестер КВ-001
      FKGD: TObjectList<TKGD>;          //List of KGDs				Уникальный датчик (экспериментальная разработка. Шансов встретить нет, но пусть будет для истории)
      FBatcher: TObjectList<TBatcher>;  //List of Batchers		Абстрактное устройство дозатор
      FDropper: TObjectList<TDropper>;  //List of Droppers		Абстрактный этап - сброс материала из дозатора в смеситель (или куда там понадобится)
      FMixer: TObjectList<TMixer>;      //List of Mixers			Абстрактное устройство смеситель (для бетона, например)

      //Properties methods
    function GetDIOM(Index: Integer): TDIOM;
    function GetDIM(Index: Integer): TDIM;
    function GetDOM(Index: Integer): TDOM;
    function GetKB(Index: Integer): TKB;
    function GetKGD(Index: Integer): TKGD;
    function GetBatcher(Index: Integer): TBatcher;
    function GetDropper(Index: Integer): TDropper;
    function GetMixer(Index: Integer): TMixer;
    function GetDIOMAds(Address: Byte): TDIOM;
    function GetDIMAds(Address: Byte): TDIM;
    function GetDOMAds(Address: Byte): TDOM;
    function GetKBAds(Address: Byte): TKB;
    function GetKGDAds(Address: Byte): TKGD;
    function GetDIOMName(Name: String): TDIOM;
    function GetDIMName(Name: String): TDIM;
    function GetDOMName(Name: String): TDOM;
    function GetKBName(Name: String): TKB;
    function GetKGDName(Name: String): TKGD;
    function GetDIOMCount: Byte;
    function GetDIMCount: Byte;
    function GetDOMCount: Byte;
    function GetKBCount: Byte;
    function GetKGDCount: Byte;
    function GetBatcherCount: Byte;
    function GetDropperCount: Byte;
    function GetMixerCount: Byte;
      //Additional methods
    function DevByAdsExists(Address: Byte; RaiseExeption: Boolean=True): Boolean;
  protected
    function Get(Address: Byte): TComDevice;
  public
    constructor Create;
    destructor Destroy; override;

    procedure CreateDIOM(Address: Byte);                    //Creates new DIOM
    procedure CreateDIM(Address: Byte; DIMType: TDIMTypes); //Creates new DIM
    procedure CreateDOM(Address: Byte; DOMType: TDOMTypes); //Creates new DOM
    procedure CreateKB(Address: Byte; KBType: TKBTypes);    //Creates new KB
    procedure CreateKGD(Address: Byte);                     //Creates new KGD
    procedure CreateBatcher(Controller: TWeightController; BatcherCnt: Byte; BatType: TBatTypes); //Creates new Batcher
    procedure CreateDropper(DoserCnt: Byte=1);  //Creates new Dropper
    procedure CreateMixer;  //Creates new Mixer

    property ItemByAds[Address: Byte]: TComDevice read Get; default;
      //Devices counts
    property DIOMCount: Byte read GetDIOMCount;
    property DIMCount: Byte read GetDIMCount;
    property DOMCount: Byte read GetDOMCount;
    property KBCount: Byte read GetKBCount;
    property KGDCount: Byte read GetKGDCount;
    property BatcherCount: Byte read GetBatcherCount;
    property DropperCount: Byte read GetDropperCount;
    property MixerCount: Byte read GetMixerCount;
      //Get device by index
    property DIOM[Index: Integer]: TDIOM read GetDIOM;
    property DIM[Index: Integer]: TDIM read GetDIM;
    property DOM[Index: Integer]: TDOM read GetDOM;
    property KB[Index: Integer]: TKB read GetKB;
    property KGD[Index: Integer]: TKGD read GetKGD;
    property Batcher[Index: Integer]: TBatcher read GetBatcher;
    property Dropper[Index: Integer]: TDropper read GetDropper;
    property Mixer[Index: Integer]: TMixer read GetMixer;
      //Get device by address
    property DIOMAds[Address: Byte]: TDIOM read GetDIOMAds;
    property DIMAds[Address: Byte]: TDIM read GetDIMAds;
    property DOMAds[Address: Byte]: TDOM read GetDOMAds;
    property KBAds[Address: Byte]: TKB read GetKBAds;
    property KGDAds[Address: Byte]: TKGD read GetKGDAds;
      //Get device by name
    property DIOMName[Name: String]: TDIOM read GetDIOMName;
    property DIMName[Name: String]: TDIM read GetDIMName;
    property DOMName[Name: String]: TDOM read GetDOMName;
    property KBName[Name: String]: TKB read GetKBName;
    property KGDName[Name: String]: TKGD read GetKGDName;

      //Set all IsInWork properties to True
    procedure TurnOnAllDevices;
      //Find TComDevice by its net address
    function FindDeviceByAddress(Address: Byte): TComDevice;
      //Count of TComDevice objects
    function ComDeviceCount: Word;
  end;

    //Interfase for discrete dosing controllers
  IDIM = interface(IInterface)
  ['{3E96EEFC-2016-4241-A7DC-5A4D2722A1CB}']
  //private
    function GetInData(Index: Byte): Boolean;
    procedure SetInData(Index: Byte; Value: Boolean);
  //public
    property Input[Index: Byte]: Boolean read GetInData write SetInData;

    procedure ReadInputs(AsCommand: Boolean=False; ThreadId: Int64=0; Priority: Byte=cDefPriority); //Reads inputs of device
  end;
    //Interfase for discrete dosing controllers
  IDOM = interface(IInterface)
  ['{E13517FE-C885-4BCB-8D3F-69870B59E00C}']
  //private
    function GetOutData(Index: Byte): Boolean;
    function GetOutNeedData(Index: Byte): Boolean;
    procedure SetOutData(Index: Byte; Value: Boolean);
    procedure SetOutNeedData(Index: Byte; Value: Boolean);
  //public
    property Output[Index: Byte]: Boolean read GetOutData write SetOutData;
    property OutNeed[Index: Byte]: Boolean read GetOutNeedData write SetOutNeedData;

    procedure ReadOutputs(ThreadId: Int64=0; Priority: Byte=cDefPriority);  //Reads outputs of device
    procedure Write(Value: Int64; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);  //Writes output to device
    procedure OutputOn(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);  //Turns on one output
    procedure OutputOff(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);  //Turns off one output
    function GetNeedOuts(Reg: Byte): Word;  //Gets outputs need to turn on
    function GetOuts(Reg: Byte): Word;      //Gets real outputs
    function RecalcChanges(NewVal: Integer; Reg: Byte; PrevVals: TDOMConsiderData): Word;
  end;

    //Interfase for discrete dosing controllers
  IDiscreteDosingController = interface//(IInterface)
  //['{754D4FD9-E21C-4875-BCEA-F211306B0FF1}']
  //private
  //public
    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
  end;

    //Parent for device classes using Com-port or Emulator
  TComDevice = class(TDevice)
  private
    FAddress: Byte;       //Net address of device (1-256)
    FConnected: Boolean;  //Connection status
    FIsInWork: Boolean;   //Working status. If False the commands is not sent

      //Properties methods
    procedure SetIsInWork(InWork: Boolean);
  public
    constructor Create(Address: Byte);

    property Address: Byte read FAddress write FAddress;
    property Connected: Boolean read FConnected write FConnected;
    property IsInWork: Boolean read FIsInWork write SetIsInWork;
  end;

    //----------------------------------------------------------------------------------------------

    //DIOM device class
  TDIOM = class(TComDevice, IDIM, IDOM)
  private
      //From device
    FInData: Array [0..11] of Boolean;      //Inputs data
    FOutData: Array [0..7] of Boolean;      //Outputs data
    FOutDataNeed: Array [0..7] of Boolean;  //Outputs data tried to write

      //Properties methods
    function GetInData(Index: Byte): Boolean;
    function GetOutData(Index: Byte): Boolean;
    function GetOutNeedData(Index: Byte): Boolean;
    procedure SetInData(Index: Byte; Value: Boolean);
    procedure SetOutData(Index: Byte; Value: Boolean);
    procedure SetOutNeedData(Index: Byte; Value: Boolean);
  public
    constructor Create(Address: Byte);

    property Input[Index: Byte]: Boolean read GetInData write SetInData;
    property Output[Index: Byte]: Boolean read GetOutData write SetOutData;
    property OutNeed[Index: Byte]: Boolean read GetOutNeedData write SetOutNeedData;

    procedure ReadInputs(AsCommand: Boolean=False; ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure ReadOutputs(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure Write(Value: Int64; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure OutputOn(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure OutputOff(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);

    function GetNeedOuts(Reg: Byte=0): Word;
    function GetOuts(Reg: Byte=0): Word;
    function RecalcChanges(NewVal: Integer; Reg: Byte; PrevVals: TDOMConsiderData): Word;
  end;

    //----------------------------------------------------------------------------------------------

    //DIM device class
  TDIM = class(TComDevice, IDIM)
  private
      //From device
    FInData: Array of Boolean;    //Inputs data
      //Properties methods
    function GetInData(Index: Byte): Boolean;
    procedure SetInData(Index: Byte; Value: Boolean);
  public
    constructor Create(Address: Byte; DIMType: TDIMTypes);
    property Input[Index: Byte]: Boolean read GetInData write SetInData;
    procedure ReadInputs(AsCommand: Boolean=False; ThreadId: Int64=0; Priority: Byte=cDefPriority);
    function InputCount: Byte;
  end;

    //----------------------------------------------------------------------------------------------

    //DOM device class
  TDOM = class(TComDevice, IDOM)
  private
      //From device
    FOutData: Array of Boolean;     //Outputs data
    FOutDataNeed: Array of Boolean; //Outputs data tried to write

      //Properties methods
    function GetOutData(Index: Byte): Boolean;
    function GetOutNeedData(Index: Byte): Boolean;
    procedure SetOutData(Index: Byte; Value: Boolean);
    procedure SetOutNeedData(Index: Byte; Value: Boolean);
  public
    constructor Create(Address: Byte; DOMType: TDOMTypes);

    property Output[Index: Byte]: Boolean read GetOutData write SetOutData;
    property OutNeed[Index: Byte]: Boolean read GetOutNeedData write SetOutNeedData;

    procedure ReadOutputs(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure Write(Value: Int64; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure OutputOn(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure OutputOff(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);

    function GetNeedOuts(Reg: Byte): Word;
    function GetOuts(Reg: Byte): Word;
    function RecalcChanges(NewVal: Integer; Reg: Byte; PrevVals: TDOMConsiderData): Word;
    function OutputCount: Byte;
    function OutNeedCount: Byte;
  end;

    //----------------------------------------------------------------------------------------------

//  IKB001 = interface(IInterface{IDiscreteDosingController})
//  ['{52234419-345E-4AE4-89B3-7A92D9F7E6A0}']
//  IKB = interface(IDiscreteDosingController)
  IWeightController = interface(IDiscreteDosingController)
  //private
    function GetState: Integer;
    procedure SetState(Value: Integer);
    function GetDecimal: Byte;
    procedure SetDecimal(Value: Byte);
    function GetWeight: Single;
    procedure SetWeight(Value: Single);
    function GetTarget(Index: Byte): Single;
    procedure SetTarget(Index: Byte; Value: Single);
    function GetError: Boolean;
    procedure SetError(Value: Boolean);
  //public
    property State: Integer read GetState write SetState;
    property Decimal: Byte read GetDecimal write SetDecimal;
    property Weight: Single read GetWeight write SetWeight;
    property Targets[Index: Byte]: Single read GetTarget write SetTarget;
    property Error: Boolean read GetError write SetError;
  end;

  TWeightController = class(TComDevice, IWeightController)
  private
      //From device (all float values are 4-bytes)
    FState: Integer;            //State of device
    FDecimal: Byte;             //Decimal point of device
    FWeight: Single;            //Current weight
    FTarget: Array of Single;   //Targets dosings
    FError: Boolean;            //Got an error
    FUseHardAdvance: Boolean;

    function GetState: Integer;
    procedure SetState(Value: Integer);
    function GetDecimal: Byte;
    procedure SetDecimal(Value: Byte);
    function GetWeight: Single;
    procedure SetWeight(Value: Single);
    function GetTarget(Index: Byte): Single;
    procedure SetTarget(Index: Byte; Value: Single);
    function GetError: Boolean;
    procedure SetError(Value: Boolean);
  public
    constructor Create(Address: Byte);

    property State: Integer read GetState write SetState;
    property Decimal: Byte read GetDecimal write SetDecimal;
    property Weight: Single read GetWeight write SetWeight;
    property Targets[Index: Byte]: Single read GetTarget write SetTarget;
    property UseHardAdvance: Boolean read FUseHardAdvance write FUseHardAdvance;
    property Error: Boolean read GetError write SetError;

    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); virtual; abstract;

    function IsDosing: Boolean; virtual; abstract;
  end;

    //Parent for all KB devices
  TKB = class(TWeightController)
  end;

    //----------------------------------------------------------------------------------------------

    //Real states of KB-001
  TKB_001_081_State = (k081stMenu=0, k081stCalibr=1, k081stWaiting=2, k081stDosing=3, k081stPause=4,
    k081stImpulse=5, k081stUnload=6, k081stError=7, k081stUnloadWaiting=9, k081stUnknownError=255);
    //Commands for KB-001 081 device
  TKB_001_081_Command = (
    k081cResetDose=1, k081cStartDosing=2, k081cStopDosing=3,
    k081cReadData=3, k081cWriteData=16);
    //Registers of KB_001 081 device
  TKB_001_081_Register = (
    k081rWeight=0, k081rADC=2, k081rState=3, k081rADCRange=103, k081rADCFrequency=4,
    k081rDiscreteIns=104, k081rFloatDigits=105, k081rMaxWeight=6, k081rCalibrWeight=8,
    k081rCalibrCoeff=10, k081rZeroCode=12, k081rTarget=14, k081rAdvanceHard=16, k081rAdvanceSoft=18,
    k081rZeroZone=20, k081rZeroZoneMax=22, k081rZeroTime=24, k081rDecayTime=26, k081rDosingMode=28,
    k081rFilterSize1=128, k081rFilterSize2=29, k081rNetNumber=129, k081rNetSpeed=30,
    k081rControlMode=130, k081rAutoZeroing=31, k081rShippedWeight=40, k081rWeightCount=42,
    k081rSensorPower=144);

    //KB-001 v081 device class
  TKB_001_081 = class(TKB)
  private
    function GetRegCnt(Regstr: TKB_001_081_Register): Byte;
  public
    constructor Create(Address: Byte);

      //Reads data
    procedure ReadData(Regstr: TKB_001_081_Register; RegCnt: Byte=0; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
      //Writes data
    procedure WriteData(Regstr: TKB_001_081_Register; RegCnt: Byte; Data: TBytes; DataLen: Byte;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
      //Sends a command
    procedure SendCommand(Command: TKB_001_081_Command; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);

      //Interface methods
    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;

    function IsDosing: Boolean; override;
  end;

    //----------------------------------------------------------------------------------------------

    //Real states of KB-001
  {TKB_001_091_State = (k091stMenu=0, k091stCalibr=1, k091stWaiting=2, k091stDosing=3, k091stPause=4,
    k091stImpulse=5, k091stUnload=6, k091stError=7, k091stUnloadWaiting=9, k091stUnknownError=255);
    //Commands for KB-001 091 device
  TKB_001_091_Command = (
    k091cResetDose=1, k091cStartDosing=2, k091cStopDosing=3,
    k091cReadData=3, k091cWriteData=16);
    //Registers of KB_001 091 device
  TKB_001_091_Register = (
    k091rWeight=0, k091rADC=2, k091rState=3, k091rDiscreteOuts=4, k091rDiscreteIns=104,
    k091rADCRange=10, k091rADCFrequency=110, k091rDiscreteness=11, k091rFloatDigits=12,
    k091rPolarity=112, k091rMaxWeight=13, k091rCalibrWeight=15, k091rCalibrCoeff=17,
    k091rZeroCode=19, k091rTarget1=30, k091rTarget2=32, k091rTarget3=34, k091rTarget4=36,
    k091rTarget5=38, k091rTarget6=40, k091rTarget7=42, k091rTarget8=44, k091rTarget9=46,
    k091rAdvanceHard=48, k091rAdvanceSoft=50, k091rTare1=52, k091rTare2=54, k091rTare3=56,
    k091rTare4=58, k091rTare5=60, k091rTare6=62, k091rTare7=64, k091rTare8=66, k091rTare9=68,
    k091rTarePrecisionRange=70, k091rCurrentTarget=72, k091rZeroTime=85, k091rDecayTime=87,
    k091rDosingMode=89, k091rSoftOutMode=90, k091rFilterSize1=91, k091rFilterSize2=92,
    k091rNetNumber=93, k091rNetSpeed=94, k091rControlMode=95, k091rAutoZeroing=96,
    (* Следующие в реальности на 100 меньше *)
    k091rWeightCount=225, k091rDosingCount=227, k091rWeightLast=228);

    //KB-001 v091 device class
  TKB_001_091 = class(TKB)
  public
    constructor Create(Address: Byte);

      //Reads data
    procedure ReadData(Regstr: TKB_001_091_Register; RegCnt: Byte=0; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
      //Writes data
    procedure WriteData(Regstr: TKB_001_091_Register; RegCnt: Byte; Data: TBytes; DataLen: Byte;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
      //Sends a command
    procedure SendCommand(Command: TKB_001_091_Command; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);

      //Interface methods
    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
  end;}

    //----------------------------------------------------------------------------------------------

    //Real states of KB-001
  TKB_001_1102_State = (k1102stMenu=0, k1102stCalibr=1, k1102stWaiting=2, k1102stDosing1=3,
    k1102stPause1=4, k1102stImpulse1=5, k1102stDosing2=6, k1102stPause2=7, k1102stImpulse2=8,
    k1102stDosing3=9, k1102stPause3=10, k1102stImpulse3=11, k1102stWeightGone=12,
    k1102stDosingFinished=13, k1102stUnload=14, k1102stError=15, k1102stUnknownError=255);
    //Commands for KB-001 11.02 device
  TKB_001_1102_Command = (
    k1102cResetDose=1, k1102cStartDosing=2, k1102cStopDosing=3,
    k1102cReadData=3, k1102cWriteData=16);
    //Registers of KB_001 11.02 device
  TKB_001_1102_Register = (k1102rWeight=0, k1102rADC=2, k1102rState=3, k1102rADCRange=3,
    k1102rADCFrequency=4, k1102rDiscreteness=104, k1102rFloatDigits=5, k1102rMaxWeight=6,
    k1102rCalibrWeight=8, k1102rCalibrCoeff=10, k1102rZeroCode=12, k1102rTarget1=14,
    k1102rTarget2=16, k1102rTarget3=18, k1102rAdvanceHard1=20, k1102rAdvanceHard2=22,
    k1102rAdvanceHard3=24, k1102rAdvanceSoft1=26, k1102rAdvanceSoft2=28, k1102rAdvanceSoft3=30,
    k1102rImpulsePause1=32, k1102rImpulsePause2=34, k1102rImpulsePause3=36, k1102rZeroZone=38,
    k1102rZeroTime=40, k1102rDecayTime=42, k1102rFilterSize1=44, k1102rFilterSize2=45,
    k1102rNetNumber=145, k1102rNetSpeed=46, k1102rDiscreteOperMode=146, k1102rAutoZeroing=47,
    k1102rWeightGoneTime=147);

    //KB-001 v11.02 device class
  TKB_001_1102 = class(TKB)
  private
    function GetRegCnt(Regstr: TKB_001_1102_Register): Byte;
  public
    constructor Create(Address: Byte);

      //Reads data
    procedure ReadData(Regstr: TKB_001_1102_Register; RegCnt: Byte=0; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
      //Writes data
    procedure WriteData(Regstr: TKB_001_1102_Register; RegCnt: Byte; Data: TBytes; DataLen: Byte;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
      //Sends a command
    procedure SendCommand(Command: TKB_001_1102_Command; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);

      //Interface methods
    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;

    function IsDosing: Boolean; override;
  end;

    //----------------------------------------------------------------------------------------------

    //Real states of PTC_001
  TPTC_001_State = (kPTCstWaiting=0, kPTCstDosing=1, kPTCstImpulse=2, kPTCstUnknownError=255);
    //Commands for PTC_001 device
  TPTC_001_Command = (
    kPTCcResetDose=1, kPTCcStartDosing=2, kPTCcStopDosing=4,
    kPTCcReadData=3, kPTCcWriteData=16);
    //Registers of PTC_001 device
  TPTC_001_Register = (kPTCrWeight=0, kPTCrADC=2, kPTCrState=3, kPTCrADCRange=103,
    kPTCrADCFrequency=4, kPTCrOutType=104, kPTCrCalibrCoeff=5, kPTCrZeroCode=7, kPTCrPolarity=9,
    kPTCrFilterSize1=109, kPTCrFilterSize2=10, kPTCrNetNumber=110, kPTCrNetSpeed=11,
    kPTCrADCCanal=111, kPTCrAllowDosing=12, kPTCrAutoZeroing=112, kPTCrTarget=13,
    kPTCrAdvanceHard=15, kPTCrAdvanceSoft=17, kPTCrInputs=32, kPTCrOutputs=132);

    //PTC_001 device class
  TPTC_001 = class(TKB)
  private
    function GetRegCnt(Regstr: TPTC_001_Register): Byte;
  public
    constructor Create(Address: Byte);

      //Reads data
    procedure ReadData(Regstr: TPTC_001_Register; RegCnt: Byte=0; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
      //Writes data
    procedure WriteData(Regstr: TPTC_001_Register; RegCnt: Byte; Data: TBytes; DataLen: Byte;
      ThreadId: Int64=0; Priority: Byte=cDefPriority);
      //Sends a command
    procedure SendCommand(Command: TPTC_001_Command; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);

      //Interface methods
    procedure ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;
    procedure WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority); override;

    function IsDosing: Boolean; override;
  end;

    //----------------------------------------------------------------------------------------------

  TMeasDoneProc = procedure(MeasResult: Boolean) of Object; //True - good, False - bad
  TKGD_State = (kKGDsWaiting, kKGDsMeasuring);
  TKGD_Command = (kKGDcStart = 1, kKGDcStop = 2, kKGDcResult = 3, kKGDcSetTime = 4);
  TKGD_Result = (kKGDrGood, kKGDrBad, kKGDrWork, kKGDrUnknown);

  TKGD = class(TComDevice)
  private
    FState: TKGD_State;
    FMeasResult: TKGD_Result;
    FMeasTime: Cardinal;  //Measuring time (ms)

    procedure SetMeasResult(Value: TKGD_Result);
  public
    constructor Create(Address: Byte);  //Don't need address but made for usability
    destructor Destroy; override;

    procedure SendCommand(Command: TKGD_Command; Value: AnsiString; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);

    procedure StartMeasuring(Weight: Cardinal; ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure StopMeasuring(ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure WriteMeasTime(Value: Cardinal; ThreadId: Int64=0; Priority: Byte=cDefPriority);
    procedure ReadResult(ThreadId: Int64=0; Priority: Byte=cDefPriority);

    property State: TKGD_State read FState write FState;
    property MeasResult: TKGD_Result read FMeasResult write SetMeasResult;
    property MeasTime: Cardinal read FMeasTime write FMeasTime default 10000;
  end;

    //----------------------------------------------------------------------------------------------

    //Parent for all dosing threads (it always works)
  TWorkingThread = class(TThread)
  private
    FStop: Boolean;           //Marker for thread stopping
    FStopped: Boolean;        //Instead of Suspended;
    FLastCheckSendResult: Shortint; //Last result on function "CheckSend"
  protected
    property StopWork: Boolean read FStop;
    procedure Start;    //Overrides Start method in Delphi XE and newer
    procedure Stop;
    function CheckSend(CheckStop: Boolean=True): Shortint;
  public
    constructor Create;

    procedure Resume; reintroduce;  //Reintroducing parent Resume for FStopped
    procedure Suspend; reintroduce; //Reintroducing parent Suspend for FStopped

    property Stopped: Boolean read FStopped write FStopped default True;
  end;

    //----------------------------------------------------------------------------------------------

  TDevDXMOpts = class;
  TDevDXMState = procedure(TurnOn: Boolean; Opts: TDevDXMOpts) of Object;

  TDevDXMOpts = class
    //Event, DIM and Inputs are unusable in vibrator options
  private
    FDOM: TDIOM{IDOM};               //DOM for automatic turning on/off (opening/closing)
    FOutput: Byte;            //Output for automatic turning on/off
    FStateWhenOff: Boolean;   //State of DOM output, when it is off or closed
    FDIM: TDIOM{IDIM};               //DIM for automatic turning on/off (opening/closing)
    FInput: Byte;             //Input for checking turning on/off
    FGoodWhenEqual: Boolean;  //State of DIM input in tandem with output for checking turning on/off
    FTimeWait: Cardinal;      //Time between turns on (for dosing helpers). 0 - always works
    FTimeWork: Cardinal;      //Working time (for dosing helpers and droppers). 0 - don't turn on (main)
    FOrder: Byte;             //Dropper order (for droppers)

    FOnChangeSate: TDevDXMState;

    procedure DoChangeState(TurnOn: Boolean);
  public
    constructor Create;

    function OutputIsOff: Boolean;
    function OutputIsOn: Boolean;
      //Just for threads!
    procedure WaitForIndicator;
    procedure WaitForOutputOn;
    procedure WaitForOutputOff;

    property DOM: TDIOM{IDOM} read FDOM write FDOM;
    property Output: Byte read FOutput write FOutput;
    property StateWhenOff: Boolean read FStateWhenOff write FStateWhenOff;
    property DIM: TDIOM{IDIM} read FDIM write FDIM;
    property Input: Byte read FInput write FInput;
    property GoodWhenEqual: Boolean read FGoodWhenEqual write FGoodWhenEqual;
    property TimeWait: Cardinal read FTimeWait write FTimeWait;
    property TimeWork: Cardinal read FTimeWork write FTimeWork;
    property Order: Byte read FOrder write FOrder;

    property OnChangeSate: TDevDXMState read FOnChangeSate write FOnChangeSate;
  end;

    //----------------------------------------------------------------------------------------------

  TBatcherDD = class;
  TBatcherVD = class;

    //States of Batchers
  TBatcherDDStatus = (bDDsWaiting, bDDsDosingPrepare, bDDsStartDosing, bDDsDosing,
    bDDsDosingFinished, bDDsDosingFullDone);
  TBatcherVDStatus = (bVDsWaiting, bVDsDosingPrepare, bVDsStartDosing, bVDsDosing,
    bVDsDosingFinished, bVDsDosingFullDone);

  TBatcherProc = procedure(Sender: TBatcher) of Object;
  TBatcherCheckFunc = function(Bather: TBatcher): Boolean of Object;

  TBatcherSlamOpts = class
  private
    FDoSlamming: Boolean;   //True if need work
    FTimeForOff: Cardinal;  //Time for turning to start state
    FTimeForOn: Cardinal;   //Time for turning to previous state
  public
    property DoSlamming: Boolean read FDoSlamming write FDoSlamming;
    property TimeForOff: Cardinal read FTimeForOff write FTimeForOff;
    property TimeForOn: Cardinal read FTimeForOn write FTimeForOn;
  end;

    //Thread for discrete weight doser
  TBatcherDDThread = class(TWorkingThread)
  private
    FParent: TBatcherDD;      //Parent class
    procedure SetStatus(Value: TBatcherDDStatus);
  protected
    constructor Create;
    procedure Execute; override;
  end;

    //Thread for discrete volume doser
  TBatcherVDThread = class(TWorkingThread)
  private
    FParent: TBatcherVD;      //Parent class
    procedure SetStatus(Value: TBatcherVDStatus);
  protected
    constructor Create;
    procedure Execute; override;
  end;

    //Parent for all batcher devices
  TBatcher = class
  private
    FAuto: Boolean;           //Automatic dosing
    FBatcherCount: Byte;      //Dosing batchers count
    FDosingBatcher: Byte;     //Current dosing batcher
    FDosingCount: Cardinal;   //
    FDosingNumber: Cardinal;  //
    FResultCur: Array of Currency;          //Current dosing result for one batcher
    FResultBat: Array of Currency;          //All dosing of batcher
    FResultAll: Array of Array of Currency; //All dosing results (before dropping) for one batcher by dosing
    FResultDoser: Currency;   //Full weight of doser
    FResultTime: Array of Array of TDateTime;
    FCanDose: Boolean;        //Can make dosing material

    FCanStartNextStep: Boolean;

    FOnBeforeStartDosing: TBatcherProc;
    FOnStatusChanged: TBatcherProc;
    FOnCheckDosing: TBatcherCheckFunc;
    FOnLongDosing: TBatcherProc;
    FOnDosingFinished: TBatcherProc;
    FOnCanStartNextStep: TBatcherCheckFunc;

    FDosing: TWorkingThread;  //Dosing thread

      //Properties methods
    function GetResultCur(BNum: Byte): Currency;
    procedure SetResultCur(BNum: Byte; Value: Currency);
    function GetResultBat(BNum: Byte): Currency;
    procedure SetResultBat(BNum: Byte; Value: Currency);
    function GetResultAll(BNum: Byte; DNum: Cardinal): Currency;
    procedure SetResultAll(BNum: Byte; DNum: Cardinal; Value: Currency);
    function GetResultTime(BNum: Byte; DNum: Cardinal): TDateTime;
    procedure SetResultTime(BNum: Byte; DNum: Cardinal; Value: TDateTime);
    function GetStopped: Boolean;

    procedure DoStatusChanged;
    procedure DoCheckDosing;
    procedure DoLongDosing;
    procedure DoDosingFinished;
    procedure DoCanStartNextStep;
  public
    constructor Create(BatcherCnt: Byte=1);
    destructor Destroy; override;

    function StartDosing(BatcherNumber: Byte=0; Auto: Boolean=True): Boolean;
    procedure Stop;
    procedure Empty(Full: Boolean=False);

    property Auto: Boolean read FAuto;
    property BatcherCount: Byte read FBatcherCount;
    property DosingBatcher: Byte read FDosingBatcher;
    property DosingCount: Cardinal read FDosingCount write FDosingCount;
    property DosingNumber: Cardinal read FDosingNumber;
    property ResultCur[BNum: Byte]: Currency read GetResultCur write SetResultCur;
    property ResultBat[BNum: Byte]: Currency read GetResultBat write SetResultBat;
    property ResultAll[BNum: Byte; DNum: Cardinal]: Currency read GetResultAll write SetResultAll;
    property ResultDoser: Currency read FResultDoser write FResultDoser;
    property ResultTime[BNum: Byte; DNum: Cardinal]: TDateTime read GetResultTime write SetResultTime;
    property CanDose: Boolean read FCanDose write FCanDose;

    property Stopped: Boolean read GetStopped;

    property OnCheckDosing: TBatcherCheckFunc read FOnCheckDosing write FOnCheckDosing;
    property OnBeforeStartDosing: TBatcherProc read FOnBeforeStartDosing write FOnBeforeStartDosing;
    property OnStatusChanged: TBatcherProc read FOnStatusChanged write FOnStatusChanged;
    property OnLongDosing: TBatcherProc read FOnLongDosing write FOnLongDosing;
    property OnDosingFinished: TBatcherProc read FOnDosingFinished write FOnDosingFinished;
    property OnCanStartNextStep: TBatcherCheckFunc read FOnCanStartNextStep write FOnCanStartNextStep;
  end;

    //Batcher for discrete weight dosing
  TBatcherDD = class(TBatcher)
  private
    FStatus: TBatcherDDStatus;  //State of batcher
    FController: TWeightController; //Controller of batcher
    FTask: Array of Currency; //Tasks for dosing batchers
    FTaskReal: Array of Array of Currency;  //Real tasks for dosing batchers
    FRecalcTask: Boolean; //Allow recalc task
    FMinWeight: Currency; //Min task
    FMaxWeight: Currency; //Max task
    FAdvance: Array of Single;  //Advance for controller
    FMaxDosingTime: Word; //Time in seconds after which it means that dosing is been making too long
    FCanalOpts: Array of TDevDXMOpts;       //Canal DXM options
    FDosHelpOpts: Array of TDevDXMOpts;     //Dosing helper (vibrating, aerating) DXM options
    FTimeDamping: Cardinal;   //Weight fixing time

    function GetTask(BNum: Byte): Currency;
    procedure SetTask(BNum: Byte; Value: Currency);
    function GetTaskReal(BNum: Byte; DNum: Cardinal): Currency;
    function GetAdvance(Index: Byte): Single;
    procedure SetAdvance(Index: Byte; Value: Single);
    function GetCanalOpts(Index: Byte): TDevDXMOpts;
    procedure SetCanalOpts(Index: Byte; Value: TDevDXMOpts);
    function GetDosHelpOpts(Index: Byte): TDevDXMOpts;
    procedure SetDosHelpOpts(Index: Byte; Value: TDevDXMOpts);

    function WorkIsDone: Boolean;
  public
    constructor Create(BatcherCnt: Byte=1);
    destructor Destroy; override;

    function StartDosing(BatcherNumber: Byte=0; Auto: Boolean=True): Boolean; reintroduce;
    function HasTask: Boolean;

    property Status: TBatcherDDStatus read FStatus;
    property Controller: TWeightController read FController write FController;
    property Task[BNum: Byte]: Currency read GetTask write SetTask;
    property TaskReal[BNum: Byte; DNum: Cardinal]: Currency read GetTaskReal;
    property RecalcTask: Boolean read FRecalcTask write FRecalcTask;
    property MinWeight: Currency read FMinWeight write FMinWeight;
    property MaxWeight: Currency read FMaxWeight write FMaxWeight;
    property Advance[Index: Byte]: Single read GetAdvance write SetAdvance;
    property MaxDosingTime: Word read FMaxDosingTime write FMaxDosingTime;
    property CanalOpts[Index: Byte]: TDevDXMOpts read GetCanalOpts write SetCanalOpts;
    property DosHelpOpts[Index: Byte]: TDevDXMOpts read GetDosHelpOpts write SetDosHelpOpts;
    property TimeDamping: Cardinal read FTimeDamping write FTimeDamping;
  end;

    //Batcher for volume dosing
  TBatcherVD = class(TBatcher)
  private
    FStatus: TBatcherVDStatus;  //State of batcher
    FFeederOpts: Array of TDevDXMOpts;  //Feeder DXM options
    FSensorOpts: Array of TDevDXMOpts;  //Feeder DXM options
    FMaxDosingTime: Word; //Time in seconds after which it means that dosing is been making too long
    FTimeDamping: Cardinal;   //Weight fixing time
    FController: TWeightController; //Controller of batcher

    function GetFeederOpts(Index: Byte): TDevDXMOpts;
    procedure SetFeederOpts(Index: Byte; Value: TDevDXMOpts);
    function GetSensorOpts(Index: Byte): TDevDXMOpts;
    procedure SetSensorOpts(Index: Byte; Value: TDevDXMOpts);

    function WorkIsDone: Boolean;
  public
    constructor Create(BatcherCnt: Byte=1);
    destructor Destroy; override;

    property Status: TBatcherVDStatus read FStatus;
    property MaxDosingTime: Word read FMaxDosingTime write FMaxDosingTime;
    property FeederOpts[Index: Byte]: TDevDXMOpts read GetFeederOpts write SetFeederOpts;
    property SensorOpts[Index: Byte]: TDevDXMOpts read GetSensorOpts write SetSensorOpts;
    property TimeDamping: Cardinal read FTimeDamping write FTimeDamping;
    property Controller: TWeightController read FController write FController;
  end;

    //----------------------------------------------------------------------------------------------

  TDropperStatus = (dsWaiting, dsStarting, dsMixerOn, dsDroppingPrepare, dsDropping,
    dsDroppingFinished, dsDroppingFinishing, dsDroppingFullDone);
  TDropperProc = procedure(Dropper: TDropper; DoserNum: Byte) of Object;
  TDropperCheckFunc = function(Dropper: TDropper; DoserNum: Byte): Boolean of Object;
  TDropperGetWeightFunc = function(Dropper: TDropper; DoserNum: Byte): Single of Object;

    //Work for dropper
  TDropper = class(TWorkingThread)
  private
    FStatus: TDropperStatus;
    FDoserCount: Byte;
    FShutters: Array of TDevDXMOpts;
    FAllowance: Array of Single;    //Allowance in kg for material while dropping it out
    FMaxDroppingTime: Array of Cardinal;  //
    FDropByTime: Array of Boolean;  //Dropping time insted of Allowance
    FIsEmpty: Array of Boolean;     //Doser is empty
    FDroppable: Array of Boolean;   //Doser will be opened
    FCanClose: Array of Boolean;    //Close/stop doser after drop (only when not DropByTime)
    FMixerEngine: TDevDXMOpts;
    FWaitForAll: Boolean; //Wait all doser to be filled
    FDroppingNum: Byte;

    FAllowDrop: Boolean;
    FAllowMixerOn: Boolean;
    FDoserNumber: Byte;
    FWeightCur: Single;
    FCanStartNextStep: Boolean;
    FFinished: Array of Boolean;

    FOnBeforeMixerOn: TDropperCheckFunc;
    FOnStatusChanged: TDropperProc;
    FOnAllowDrop: TDropperCheckFunc;
    FOnLongDropping: TDropperProc;
    FOnGetWeight: TDropperGetWeightFunc;
    FOnCanStartNextStep: TDropperCheckFunc;

    function GetShutters(Index: Byte): TDevDXMOpts;
    procedure SetShutters(Index: Byte; Value: TDevDXMOpts);
    function GetAllowance(Index: Byte): Single;
    procedure SetAllowance(Index: Byte; Value: Single);
    function GetMaxDroppingTime(Index: Byte): Cardinal;
    procedure SetMaxDroppingTime(Index: Byte; Value: Cardinal);
    function GetDropByTime(Index: Byte): Boolean;
    procedure SetDropByTime(Index: Byte; Value: Boolean);
    function GetIsEmpty(Index: Byte): Boolean;
    procedure SetIsEmpty(Index: Byte; Value: Boolean);
    function GetDroppable(Index: Byte): Boolean;
    procedure SetDroppable(Index: Byte; Value: Boolean);
    function GetCanClose(Index: Byte): Boolean;
    procedure SetCanClose(Index: Byte; Value: Boolean);

    procedure DoBeforeMixerOn;
    procedure DoStatusChanged;
    procedure DoAllowDrop;
    procedure DoLongDropping;
    procedure DoGetWeight;
    procedure DoCanStartNextStep;

    procedure SetStatus(Value: TDropperStatus);
  protected
    procedure Execute; override;
  public
    constructor Create(DoserCnt: Byte);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    property Status: TDropperStatus read FStatus;
    property DoserCount: Byte read FDoserCount write FDoserCount;
    property Shutters[Index: Byte]: TDevDXMOpts read GetShutters write SetShutters;
    property Allowance[Index: Byte]: Single read GetAllowance write SetAllowance;
    property MaxDroppingTime[Index: Byte]: Cardinal read GetMaxDroppingTime write SetMaxDroppingTime;
    property DropByTime[Index: Byte]: Boolean read GetDropByTime write SetDropByTime;
    property MixerEngine: TDevDXMOpts read FMixerEngine write FMixerEngine;
    property IsEmpty[Index: Byte]: Boolean read GetIsEmpty write SetIsEmpty;
    property Droppable[Index: Byte]: Boolean read GetDroppable write SetDroppable;
    property CanClose[Index: Byte]: Boolean read GetCanClose write SetCanClose;
    property WaitForAll: Boolean read FWaitForAll write FWaitForAll;
    property DroppingNum: Byte read FDroppingNum;

    property OnBeforeMixerOn: TDropperCheckFunc read FOnBeforeMixerOn write FOnBeforeMixerOn;
    property OnStatusChanged: TDropperProc read FOnStatusChanged write FOnStatusChanged;
    property OnAllowDrop: TDropperCheckFunc read FOnAllowDrop write FOnAllowDrop;
    property OnLongDropping: TDropperProc read FOnLongDropping write FOnLongDropping;
    property OnGetWeight: TDropperGetWeightFunc read FOnGetWeight write FOnGetWeight;
    property OnCanStartNextStep: TDropperCheckFunc read FOnCanStartNextStep write FOnCanStartNextStep;
  end;

    //----------------------------------------------------------------------------------------------

  TMixerStatus = (msWaiting, msMixing, msBeforeOpening, msOpening, msPreunloading, msUnloading,
    msBeforeClosing, msClosing);
  TMixerCheckStateType = ({mcs1o1i, }mcs1o2i, mcs2o2i, mcs2o3ih);//h - hydraulic
  TMixerProc = procedure(Mixer: TMixer) of Object;
//  TMixerShutterState = procedure(Opening: Boolean; Opts: TBatcherDXMOpts) of Object;

  TMixerShutterOpts = class
  private
    FCheckStateType: TMixerCheckStateType;  //Type of checking shutter state
    FDOMOutOpen: IDOM;        //DOM, opening Mixer
    FOutOpen: Byte;           //Output for opening command
    FOpenedState: Boolean;    //State of output, when shutter is opened
    FDOMOutClose: IDOM;       //DOM, closing Mixer
    FOutClose: Byte;          //Output for closing command
    FClosedState: Boolean;    //State of output, when shutter is closed
    FDIMIndOpened: IDIM;          //DIM with opened indicator
    FIndOpened: Byte;             //Input for opened indicator
    FIndOpenedState: Boolean;     //State of input, when shutter is opened
    FDIMIndHalfOpened: IDIM;      //DIM with half opened indicator
    FIndHalfOpened: Byte;         //Input for half opened indicator
    FIndHalfOpenedState: Boolean; //State of input, when shutter is half opened
    FDIMIndClosed: IDIM;          //DIM with closed indicator
    FIndClosed: Byte;             //Input for closed indicator
    FIndClosedState: Boolean;     //State of input, when shutter is closed
  public
    property CheckStateType: TMixerCheckStateType read FCheckStateType write FCheckStateType;
    property DOMOutOpen: IDOM read FDOMOutOpen write FDOMOutOpen;
    property OutOpen: Byte read FOutOpen write FOutOpen;
    property OpenedState: Boolean read FOpenedState write FOpenedState;
    property DOMOutClose: IDOM read FDOMOutClose write FDOMOutClose;
    property OutClose: Byte read FOutClose write FOutClose;
    property ClosedState: Boolean read FClosedState write FClosedState;
    property DIMIndHalfOpened: IDIM read FDIMIndHalfOpened write FDIMIndHalfOpened;
    property IndHalfOpened: Byte read FIndHalfOpened write FIndHalfOpened;
    property IndHalfOpenedState: Boolean read FIndHalfOpenedState write FIndHalfOpenedState;
    property DIMIndOpened: IDIM read FDIMIndOpened write FDIMIndOpened;
    property IndOpened: Byte read FIndOpened write FIndOpened;
    property IndOpenedState: Boolean read FIndOpenedState write FIndOpenedState;
    property DIMIndClosed: IDIM read FDIMIndClosed write FDIMIndClosed;
    property IndClosed: Byte read FIndClosed write FIndClosed;
    property IndClosedState: Boolean read FIndClosedState write FIndClosedState;
  end;

    //Work of mixer device
  TMixer = class(TWorkingThread)
  private
    FStatus: TMixerStatus;  //State of Mixer
    FTimeMix: Word;         //Mixing time in seconds
    FTimeUnload: Word;      //Unloading time in seconds
    FShutterOpts: TMixerShutterOpts;  //Shutter closing/opening options
    FIsEmpty: Boolean;      //Empty state
    FMixingValue: Currency; //Current mixing value
    FLastMixingValue: Currency; //Last mixing value
    FSumValue: Currency;    //Summary volume of weight that was mixed
    FNotUnload: Boolean;    //Don't unload
    FPreOpenTimeStart: Cardinal;  //Preopening time in ms
    FPreOpenTimeWait: Cardinal;   //Preopening wait time after start in ms

    FOnStatusChanged: TMixerProc;

    procedure DoStatusChanged;
    function ShutterOpen: Boolean;
    function ShutterClose: Boolean;
    function ShutterStop: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Stop;

    function CheckOpened: Boolean;
    function CheckClosed: Boolean;

    property Status: TMixerStatus read FStatus;
    property TimeMix: Word read FTimeMix write FTimeMix;
    property TimeUnload: Word read FTimeUnload write FTimeUnload;
    property ShutterOpts: TMixerShutterOpts read FShutterOpts write FShutterOpts;
    property IsEmpty: Boolean read FIsEmpty write FIsEmpty;
    property MixingValue: Currency read FMixingValue write FMixingValue;
    property LastMixingValue: Currency read FLastMixingValue write FLastMixingValue;
    property SumValue: Currency read FSumValue write FSumValue;
    property NotUnload: Boolean read FNotUnload write FNotUnload;
    property PreOpenTimeStart: Cardinal read FPreOpenTimeStart write FPreOpenTimeStart;
    property PreOpenTimeWait: Cardinal read FPreOpenTimeWait write FPreOpenTimeWait;

    property OnStatusChanged: TMixerProc read FOnStatusChanged write FOnStatusChanged;
  end;

    //----------------------------------------------------------------------------------------------

const
  WM_USER           = $0400;
  TM_KEEPONWORKING  = WM_USER+1;

var
  Devs: TDevLists;

implementation

uses RazFuncs, RazLogs;

//==================================================================================================
//_____________________________________________TDevice______________________________________________
//==================================================================================================

constructor TDevice.Create;
begin
  inherited Create;
  FDevType:=dtUnknown;
  FName:='';
end;

//==================================================================================================
//_______________________________________________TDevs______________________________________________
//==================================================================================================

function TDevLists.GetDIOM(Index: Integer): TDIOM;
begin
  If (FDIOM.Count=0) or (Index<0) or (Index>=FDIOM.Count) then
    Result:=nil
  Else Result:=FDIOM.Items[Index];
end;

function TDevLists.GetDIM(Index: Integer): TDIM;
begin
  If (FDIM.Count=0) or (Index<0) or (Index>=FDIM.Count) then
    Result:=nil
  Else Result:=FDIM.Items[Index];
end;

function TDevLists.GetDOM(Index: Integer): TDOM;
begin

  If (FDOM.Count=0) or (Index<0) or (Index>=FDOM.Count) then
    Result:=nil
  Else Result:=FDOM.Items[Index];
end;

function TDevLists.GetKB(Index: Integer): TKB;
begin
  If (FKB.Count=0) or (Index<0) or (Index>=FKB.Count) then
    Result:=nil
  Else Result:=FKB.Items[Index];
end;

function TDevLists.GetKGD(Index: Integer): TKGD;
begin
  If (FKGD.Count=0) or (Index<0) or (Index>=FKGD.Count) then
    Result:=nil
  Else Result:=FKGD.Items[Index];
end;

function TDevLists.GetBatcher(Index: Integer): TBatcher;
begin
  If (FBatcher.Count=0) or (Index<0) or (Index>=FBatcher.Count) then
    Result:=nil
  Else Result:=FBatcher.Items[Index];
end;

function TDevLists.GetDropper(Index: Integer): TDropper;
begin
  If (FDropper.Count=0) or (Index<0) or (Index>=FDropper.Count) then
    Result:=nil
  Else Result:=FDropper.Items[Index];
end;

function TDevLists.GetMixer(Index: Integer): TMixer;
begin
  If (FMixer.Count=0) or (Index<0) or (Index>=FMixer.Count) then
    Result:=nil
  Else Result:=FMixer.Items[Index];
end;

function TDevLists.GetDIOMAds(Address: Byte): TDIOM;
var
  i: Byte;
begin
  Result:=nil;
  If FDIOM.Count=0 then Exit;
  For i:=0 to FDIOM.Count-1 do
    if GetDIOM(i).FAddress=Address then
      Result:=GetDIOM(i);
end;

function TDevLists.GetDIMAds(Address: Byte): TDIM;
var
  i: Byte;
begin
  Result:=nil;
  If FDIM.Count=0 then Exit;
  For i:=0 to FDIM.Count-1 do
    if GetDIM(i).FAddress=Address then
      Result:=GetDIM(i);
end;

function TDevLists.GetDOMAds(Address: Byte): TDOM;
var
  i: Byte;
begin
  Result:=nil;
  If FDOM.Count=0 then Exit;
  For i:=0 to FDOM.Count-1 do
    if GetDOM(i).FAddress=Address then
      Result:=GetDOM(i);
end;

function TDevLists.GetKBAds(Address: Byte): TKB;
var
  i: Byte;
begin
  Result:=nil;
  If FKB.Count=0 then Exit;
  For i:=0 to FKB.Count-1 do
    if GetKB(i).FAddress=Address then
      Result:=GetKB(i);
end;

function TDevLists.GetKGDAds(Address: Byte): TKGD;
var
  i: Byte;
begin
  Result:=nil;
  If FKGD.Count=0 then Exit;
  For i:=0 to FKGD.Count-1 do
    if GetKGD(i).FAddress=Address then
      Result:=GetKGD(i);
end;

function TDevLists.GetDIOMName(Name: String): TDIOM;
var
  i: Byte;
begin
  Result:=nil;
  If FDIOM.Count=0 then Exit;
  For i:=0 to FDIOM.Count-1 do
    if GetDIOM(i).FName=Name then
      Result:=GetDIOM(i);
end;

function TDevLists.GetDIMName(Name: String): TDIM;
var
  i: Byte;
begin
  Result:=nil;
  If FDIM.Count=0 then Exit;
  For i:=0 to FDIM.Count-1 do
    if GetDIM(i).FName=Name then
      Result:=GetDIM(i);
end;

function TDevLists.GetDOMName(Name: String): TDOM;
var
  i: Byte;
begin
  Result:=nil;
  If FDOM.Count=0 then Exit;
  For i:=0 to FDOM.Count-1 do
    if GetDOM(i).FName=Name then
      Result:=GetDOM(i);
end;

function TDevLists.GetKBName(Name: String): TKB;
var
  i: Byte;
begin
  Result:=nil;
  If FKB.Count=0 then Exit;
  For i:=0 to FKB.Count-1 do
    if GetKB(i).FName=Name then
      Result:=GetKB(i);
end;

function TDevLists.GetKGDName(Name: String): TKGD;
var
  i: Byte;
begin
  Result:=nil;
  If FKGD.Count=0 then Exit;
  For i:=0 to FKGD.Count-1 do
    if GetKGD(i).FName=Name then
      Result:=GetKGD(i);
end;

function TDevLists.GetDIOMCount: Byte;
begin
  Result:=FDIOM.Count;
end;

function TDevLists.GetDIMCount: Byte;
begin
  Result:=FDIM.Count;
end;

function TDevLists.GetDOMCount: Byte;
begin
  Result:=FDOM.Count;
end;

function TDevLists.GetKBCount: Byte;
begin
  Result:=FKB.Count;
end;

function TDevLists.GetKGDCount: Byte;
begin
  Result:=FKGD.Count;
end;

function TDevLists.GetBatcherCount: Byte;
begin
  Result:=FBatcher.Count;
end;

function TDevLists.GetDropperCount: Byte;
begin
  Result:=FDropper.Count;
end;

function TDevLists.GetMixerCount: Byte;
begin
  Result:=FMixer.Count;
end;

function TDevLists.DevByAdsExists(Address: Byte; RaiseExeption: Boolean=True): Boolean;
begin
  Result:=False;
  If Assigned(GetDIOMAds(Address)) or
    Assigned(GetDIMAds(Address)) or Assigned(GetDOMAds(Address)) or
    Assigned(GetKBAds(Address)) then
  Begin
    Result:=True;
    if RaiseExeption then
      raise Exception.Create(cAlreadyExists);
  End;
end;

//--------------------------------------------------------------------------------------------------

function TDevLists.Get(Address: Byte): TComDevice;
begin
  Result:=FindDeviceByAddress(Address);
end;

//--------------------------------------------------------------------------------------------------

constructor TDevLists.Create;
begin
  FDIOM:=TObjectList<TDIOM>.Create;
  FDIM:=TObjectList<TDIM>.Create;
  FDOM:=TObjectList<TDOM>.Create;
  FKB:=TObjectList<TKB>.Create;
  FKGD:=TObjectList<TKGD>.Create;
  FBatcher:=TObjectList<TBatcher>.Create;
  FDropper:=TObjectList<TDropper>.Create;
  FMixer:=TObjectList<TMixer>.Create;
end;

destructor TDevLists.Destroy;
var
  i: Integer;
begin
  If FDIOM.Count>0 then
    for i:=0 to FDIOM.Count-1 do
      FDIOM.Items[i].Free;
  If FDIM.Count>0 then
    for i:=0 to FDIM.Count-1 do
      FDIM.Items[i].Free;
  If FDOM.Count>0 then
    for i:=0 to FDOM.Count-1 do
      FDOM.Items[i].Free;
  If FKB.Count>0 then
    for i:=0 to FKB.Count-1 do
      FKB.Items[i].Free;
  If FKGD.Count>0 then
    for i:=0 to FKGD.Count-1 do
      FKGD.Items[i].Free;
  If FBatcher.Count>0 then
    for i:=0 to FBatcher.Count-1 do
      FBatcher.Items[i].Free;
  If FDropper.Count>0 then
    for i:=0 to FDropper.Count-1 do
      FDropper.Items[i].Free;
  If FMixer.Count>0 then
    for i:=0 to FMixer.Count-1 do
      FMixer.Items[i].Free;

  FDIOM.Free;
  FDIM.Free;
  FDOM.Free;
  FKB.Free;
  FKGD.Free;
  FBatcher.Free;
  FDropper.Free;
  FMixer.Free;
end;

procedure TDevLists.CreateDIOM(Address: Byte);
begin
  DevByAdsExists(Address);
  FDIOM.Add(TDIOM.Create(Address));
end;

procedure TDevLists.CreateDIM(Address: Byte; DIMType: TDIMTypes);
begin
  DevByAdsExists(Address);
  FDIM.Add(TDIM.Create(Address, DIMType));
end;

procedure TDevLists.CreateDOM(Address: Byte; DOMType: TDOMTypes);
begin
  DevByAdsExists(Address);
  FDOM.Add(TDOM.Create(Address, DOMType));
end;

procedure TDevLists.CreateKB(Address: Byte; KBType: TKBTypes);
begin
  DevByAdsExists(Address);
  Case KBType of
    kbt001_081:    FKB.Add(TKB_001_081.Create(Address));
    //kbt001_091:    FKB.Add(TKB_001_091.Create(Address));
    kbt001_1102:  FKB.Add(TKB_001_1102.Create(Address));
    kbtPTC001:    FKB.Add(TPTC_001.Create(Address));
  End;
end;

procedure TDevLists.CreateKGD(Address: Byte);
begin
  DevByAdsExists(Address);
  FKGD.Add(TKGD.Create(Address));
end;

procedure TDevLists.CreateBatcher(Controller: TWeightController; BatcherCnt: Byte;
  BatType: TBatTypes);
begin
  If BatcherCnt = 0 then
    raise Exception.Create('Set count of batchers');

  If BatType = btDD then
  Begin
    if not Assigned(Controller) then
      raise Exception.Create('Set Controller for batcher');
    FBatcher.Add(TBatcherDD.Create(BatcherCnt));
    TBatcherDD(FBatcher.Items[FBatcher.Count-1]).Controller:=Controller;
  End
  Else if BatType = btVD then
  Begin
    FBatcher.Add(TBatcherVD.Create(BatcherCnt));
    TBatcherVD(FBatcher.Items[FBatcher.Count-1]).Controller:=Controller;
  End;
end;

procedure TDevLists.CreateDropper(DoserCnt: Byte=1);
begin
  If DoserCnt = 0 then
    raise Exception.Create('Set count of dosers');
  FDropper.Add(TDropper.Create(DoserCnt));
end;

procedure TDevLists.CreateMixer;
begin
  FMixer.Add(TMixer.Create);
end;

procedure TDevLists.TurnOnAllDevices;
var
  i: Integer;
begin
  For i:=0 to FDIOM.Count-1 do    FDIOM[i].FIsInWork:=True;
  For i:=0 to FDIM.Count-1 do     FDIM[i].FIsInWork:=True;
  For i:=0 to FDOM.Count-1 do     FDOM[i].FIsInWork:=True;
  For i:=0 to FKB.Count-1 do      FKB[i].FIsInWork:=True;
  For i:=0 to FKGD.Count-1 do     FKGD[i].FIsInWork:=True;
end;

function TDevLists.FindDeviceByAddress(Address: Byte): TComDevice;
begin
  Result:=DIOMAds[Address];     If Assigned(Result) then Exit;
  Result:=DIMAds[Address];      If Assigned(Result) then Exit;
  Result:=DOMAds[Address];      If Assigned(Result) then Exit;
  Result:=KBAds[Address];       If Assigned(Result) then Exit;
  Result:=KGDAds[Address];      If Assigned(Result) then Exit;
end;

function TDevLists.ComDeviceCount: Word;
begin
  Result:=FDIOM.Count + FDIM.Count + FDOM.Count + FKB.Count + FKGD.Count;
end;

//==================================================================================================
//_________________________________________TComDevice_______________________________________________
//==================================================================================================

procedure TComDevice.SetIsInWork(InWork: Boolean);
begin
  FIsInWork:=InWork;
end;

//--------------------------------------------------------------------------------------------------

constructor TComDevice.Create(Address: Byte);
begin
  inherited Create;
  FAddress:=Address;
  FIsInWork:=False;
end;

//==================================================================================================
//_____________________________________________TDIOM________________________________________________
//==================================================================================================

function TDIOM.GetInData(Index: Byte): Boolean;
begin
  Result:=FInData[Index];
end;

function TDIOM.GetOutData(Index: Byte): Boolean;
begin
  Result:=FOutData[Index];
end;

function TDIOM.GetOutNeedData(Index: Byte): Boolean;
begin
  Result:=FOutDataNeed[Index];
end;

procedure TDIOM.SetInData(Index: Byte; Value: Boolean);
begin
  FInData[Index]:=Value;
end;

procedure TDIOM.SetoutData(Index: Byte; Value: Boolean);
begin
  FOutData[Index]:=Value;
end;

procedure TDIOM.SetOutNeedData(Index: Byte; Value: Boolean);
begin
  FOutDataNeed[Index]:=Value;
end;

//--------------------------------------------------------------------------------------------------

constructor TDIOM.Create(Address: Byte);
var
  i: Byte;
begin
  inherited Create(Address);
  FDevType:=dtDIOM;
  For i:=Low(FInData) to High(FInData) do FInData[i]:=False;
  For i:=Low(FOutData) to High(FOutData) do FOutData[i]:=False;
  For i:=Low(FOutDataNeed) to High(FOutDataNeed) do FOutDataNeed[i]:=False;
end;

procedure TDIOM.ReadInputs(AsCommand: Boolean=False; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToDIOM(FAddress, 0, ThreadId, AsCommand, dcdNone, Priority);
end;

procedure TDIOM.ReadOutputs(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToDIOM(FAddress, 255, ThreadId, False, dcdNone, Priority);
end;

procedure TDIOM.Write(Value: Int64; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToDIOM(FAddress, Value, ThreadId, True, ConsiderOtherData, Priority);
end;

procedure TDIOM.OutputOn(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If Num>HIgh(FOutData) then Exit;
  ComComm.ToDIOM(FAddress, Round(Pow(2, Num-1)), ThreadId, True, ConsiderOtherData, Priority);
end;

procedure TDIOM.OutputOff(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If Num>HIgh(FOutData) then Exit;
  ComComm.ToDIOM(FAddress, -Round(Pow(2, Num-1)), ThreadId, True, ConsiderOtherData, Priority);
end;

function TDIOM.GetNeedOuts(Reg: Byte=0): Word;
var
  i: Byte;
begin
  //ToDo 1: добавить параметр расчёта суммы без указанного выхода при его включении, или с выходом при выключении
  Result:=0;
  For i:=Low(FOutDataNeed) to High(FOutDataNeed) do
    if FOutDataNeed[i] then
      Result:=Result+Round(Pow(2, i-1));
end;

function TDIOM.GetOuts(Reg: Byte=0): Word;
var
  i: Byte;
begin
  Result:=0;
  For i:=Low(FOutData) to High(FOutData) do
    if FOutData[i] then
      Result:=Result+Round(Pow(2, i-1));
end;

function TDIOM.RecalcChanges(NewVal: Integer; Reg: Byte; PrevVals: TDOMConsiderData): Word;
var
  i: Byte;
  Val: Boolean;
begin
  If PrevVals = dcdNone then Exit(NewVal);

  Result:=0;
  For i:=Low(FOutData) to High(FOutData) do
  Begin
    if PrevVals = dcdOutputs then
      Val:=FOutData[i]
    else Val:=FOutDataNeed[i];

    if NewVal >= 0 then   //Output on
      Val:=Val OR ((NewVal and Round(Pow(2, i))) > 0)
    else
      Val:=Val AND not ((-NewVal and Round(Pow(2, i))) > 0);

    Inc(Result, Round(Pow(2, i)) * Integer(Val));
  End;
end;

//==================================================================================================
//_____________________________________________TDIM_________________________________________________
//==================================================================================================

function TDIM.GetInData(Index: Byte): Boolean;
begin
  Result:=FInData[Index];
end;

procedure TDIM.SetInData(Index: Byte; Value: Boolean);
begin
  FInData[Index]:=Value;
end;

//--------------------------------------------------------------------------------------------------

constructor TDIM.Create(Address: Byte; DIMType: TDIMTypes);
var
  i: Byte;
  InCnt: Byte;
begin
  inherited Create(Address);
  Case DIMType of
    dit110_16D:   begin InCnt:=16;  FDevType:=dtI110_16D;   end;
    dit110_32DN:  begin InCnt:=32;  FDevType:=dtI110_32DN;  end;
  Else
    InCnt:=0;
  End;
  SetLength(FInData, InCnt);
  For i:=Low(FInData) to High(FInData) do FInData[i]:=False;
end;

procedure TDIM.ReadInputs(AsCommand: Boolean=False; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If DevType=dtI110_16D then
    ComComm.ToDIM(FAddress, $33, AsCommand, ThreadId, Priority)
  Else if DevType=dtI110_32DN then
  Begin
    ComComm.ToDIM(FAddress, $63, AsCommand, ThreadId, Priority);
    ComComm.ToDIM(FAddress, $64, AsCommand, ThreadId, Priority);
  End;
end;

function TDIM.InputCount: Byte;
begin
  Result:=Length(FInData);
end;

//==================================================================================================
//______________________________________________TDOM________________________________________________
//==================================================================================================

function TDOM.GetOutData(Index: Byte): Boolean;
begin
  Result:=FOutData[Index];
end;

function TDOM.GetOutNeedData(Index: Byte): Boolean;
begin
  Result:=FOutDataNeed[Index];
end;

procedure TDOM.SetoutData(Index: Byte; Value: Boolean);
begin
  FOutData[Index]:=Value;
end;

procedure TDOM.SetOutNeedData(Index: Byte; Value: Boolean);
begin
  FOutDataNeed[Index]:=Value;
end;

//--------------------------------------------------------------------------------------------------

constructor TDOM.Create(Address: Byte; DOMType: TDOMTypes);
var
  i: Byte;
  OutCnt: Byte;
begin
  inherited Create(Address);
  Case DOMType of
    dot110_32R: begin OutCnt:=32;   FDevType:=dtO110_32R;   end;
  Else
    OutCnt:=0;
  End;
  SetLength(FOutData, OutCnt);
  SetLength(FOutDataNeed, OutCnt);
  For i:=Low(FOutData) to High(FOutData) do FOutData[i]:=False;
  For i:=Low(FOutDataNeed) to High(FOutDataNeed) do FOutDataNeed[i]:=False;
end;

procedure TDOM.ReadOutputs(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToDOM(FAddress, $61, 0, ThreadId, False, dcdNone, Priority);
  ComComm.ToDOM(FAddress, $62, 0, ThreadId, False, dcdNone, Priority);
end;

procedure TDOM.Write(Value: Int64; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToDOM(FAddress, $61, (Value shr 16) and Word(-1), ThreadId, True, ConsiderOtherData, Priority);
  ComComm.ToDOM(FAddress, $62, Value and Word(-1), ThreadId, True, ConsiderOtherData, Priority);
end;

procedure TDOM.OutputOn(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Reg: Byte;
begin
  If not FIsInWork then Exit;
  If Num > High(FOutData) then Exit;
  If Num > 15 then
  Begin
    Reg := $61;
    Dec(Num, 16);
  End
  Else Reg := $62;
  ComComm.ToDOM(FAddress, Reg, Round(Pow(2, Num)), ThreadId, True, ConsiderOtherData, Priority);
end;

procedure TDOM.OutputOff(Num: Byte; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Reg: Byte;
begin
  If not FIsInWork then Exit;
  If Num > High(FOutData) then Exit;
  If Num > 15 then
  Begin
    Reg := $61;
    Dec(Num, 16);
  End
  Else Reg := $62;
  ComComm.ToDOM(FAddress, Reg, -Round(Pow(2, Num)), ThreadId, True, ConsiderOtherData, Priority);
end;

function TDOM.GetNeedOuts(Reg: Byte): Word;
var
  i: Byte;
  Res: Int64;
begin
  Res:=0;
  Result:=0;
  For i:=Low(FOutDataNeed) to High(FOutDataNeed) do
    if FOutDataNeed[i] then
      Res:=Res+Round(Pow(2, i));

    //Убираем старшие 16 бит
  If Reg=97 then  //16-31
    Result := (Res shr 16) and Word(-1)
  Else if Reg=98 then //0-15
    Result := Res and Word(-1);
end;

function TDOM.GetOuts(Reg: Byte): Word;
var
  i: Byte;
  Res: Int64;
begin
  Res:=0;
  Result:=0;
  For i:=Low(FOutData) to High(FOutData) do
    if FOutData[i] then
      Res:=Res+Round(Pow(2, i));

    //Убираем старшие 16 бит
  If Reg=97 then  //16-31
    Result := (Res shr 16) and Word(-1)
  Else if Reg=98 then //0-15
    Result := Res and Word(-1);
end;

function TDOM.RecalcChanges(NewVal: Integer; Reg: Byte; PrevVals: TDOMConsiderData): Word;
var
  i: Byte;
  Res: Int64;
  Val: Boolean;
begin
  Result:=NewVal;
  If PrevVals = dcdNone then Exit;

  If Reg = 97 then
  Begin
    if NewVal >= 0 then
      NewVal:=NewVal shl 16
    else NewVal:=-(-NewVal shl 16);
  End;

  Res:=0;
  For i:=Low(FOutData) to High(FOutData) do
  Begin
    if PrevVals = dcdOutputs then
      Val:=FOutData[i]
    else Val:=FOutDataNeed[i];

    if NewVal >= 0 then   //Output on
      Val:=Val OR ((NewVal and Round(Pow(2, i))) > 0)
    else
      Val:=Val AND not ((-NewVal and Round(Pow(2, i))) > 0);

    Inc(Res, Round(Pow(2, i)) * Integer(Val));
  End;

    //Убираем старшие 16 бит
  If Reg=97 then  //16-31
    Result := (Res shr 16) and Word(-1)
  Else if Reg=98 then //0-15
    Result := Res and Word(-1);
end;

function TDOM.OutputCount: Byte;
begin
  Result:=Length(FOutData);
end;

function TDOM.OutNeedCount: Byte;
begin
  Result:=Length(FOutDataNeed);
end;

//==================================================================================================
//_________________________________________TWeightController________________________________________
//==================================================================================================

function TWeightController.GetState: Integer;
begin
  Result:=FState;
end;

procedure TWeightController.SetState(Value: Integer);
begin
  FState:=Value;
end;

function TWeightController.GetDecimal: Byte;
begin
  Result:=FDecimal;
end;

procedure TWeightController.SetDecimal(Value: Byte);
begin
  FDecimal:=Value;
end;

function TWeightController.GetWeight: Single;
begin
  Result:=FWeight;
end;

procedure TWeightController.SetWeight(Value: Single);
begin
  FWeight:=Value;
end;

function TWeightController.GetTarget(Index: Byte): Single;
begin
  Result:=FTarget[Index];
end;

procedure TWeightController.SetTarget(Index: Byte; Value: Single);
begin
  FTarget[Index]:=Value;
end;

function TWeightController.GetError: Boolean;
begin
  Result:=FError;
end;

procedure TWeightController.SetError(Value: Boolean);
begin
  FError:=Value;
end;

//--------------------------------------------------------------------------------------------------

constructor TWeightController.Create(Address: Byte);
begin
  inherited Create(Address);
  FState:=0;
  FDecimal:=0;
  FWeight:=0;
  FError:=False;
  FUseHardAdvance:=True;
end;

//==================================================================================================
//__________________________________________TKB_001_081_____________________________________________
//==================================================================================================

function TKB_001_081.GetRegCnt(Regstr: TKB_001_081_Register): Byte;
begin
  Case Regstr of
    k081rWeight, k081rMaxWeight, k081rCalibrWeight, k081rCalibrCoeff, k081rZeroCode, k081rTarget,
    k081rAdvanceHard, k081rAdvanceSoft, k081rZeroZone, k081rZeroZoneMax, k081rZeroTime,
    k081rDecayTime, k081rShippedWeight, k081rWeightCount:
      Result:=2;
  Else
    (* k081rADC, k081rState, k081rADCRange, k081rADCFrequency, k081rDiscreteIns, k081rFloatDigits,
    k081rDosingMode, k081rFilterSize1, k081rFilterSize2, k081rNetNumber, k081rNetSpeed,
    k081rControlMode, k081rAutoZeroing, k081rSensorPower *)
    Result:=1;
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TKB_001_081.Create(Address: Byte);
var
  i: Byte;
begin
  inherited Create(Address);
  FDevType:=dtK001_081;
  FState:=Integer(k081stWaiting);
  SetLength(FTarget, 9);
  For i:=Low(FTarget) to High(FTarget) do
    FTarget[i]:=0;
end;

procedure TKB_001_081.ReadData(Regstr: TKB_001_081_Register; RegCnt: Byte=0; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(k081cReadData), Integer(Regstr), RegCnt, kbctRead,
    ThreadId, False, Priority);
end;

procedure TKB_001_081.WriteData(Regstr: TKB_001_081_Register; RegCnt: Byte; Data: TBytes;
  DataLen: Byte; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(k081cWriteData), Integer(Regstr), RegCnt, Data, DataLen, kbctWrite,
    ThreadId, True, Priority);
end;

procedure TKB_001_081.SendCommand(Command: TKB_001_081_Command; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(Command), 0, 0, kbctCommand, ThreadId, True, Priority);
end;

procedure TKB_001_081.ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k081rState, 0, ThreadId, Priority);
end;

procedure TKB_001_081.ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k081rWeight, 0, ThreadId, Priority);
end;

procedure TKB_001_081.StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k081cStartDosing, ThreadId, Priority);
end;

procedure TKB_001_081.StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k081cStopDosing, ThreadId, Priority);
end;

procedure TKB_001_081.ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k081cResetDose, ThreadId, Priority);
end;

procedure TKB_001_081.WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(k081rTarget, 0, Data, 4, ThreadId, Priority);
  FTarget[0]:=Value;
end;

procedure TKB_001_081.WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  If FUseHardAdvance then
    WriteData(k081rAdvanceHard, 0, Data, 4, ThreadId, Priority)
  Else WriteData(k081rAdvanceSoft, 0, Data, 4, ThreadId, Priority);
end;

function TKB_001_081.IsDosing: Boolean;
begin
  Result:=TKB_001_081_State(FState) in [k081stDosing, k081stPause, k081stImpulse];
end;

//==================================================================================================
//__________________________________________TKB_001_091_____________________________________________
//==================================================================================================

{constructor TKB_001_091.Create(Address: Byte);
var
  i: Byte;
begin
  inherited Create(Address);
  FDevType:=dtK001_091;
  FState:=Integer(k091stWaiting);
  SetLength(FTarget, 9);
  For i:=Low(FTarget) to High(FTarget) do
    FTarget[i]:=0;
end;

procedure TKB_001_091.ReadData(Regstr: TKB_001_091_Register; RegCnt: Byte=0; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If RegCnt=0 then
    case Regstr of
      k091rWeight, k091rMaxWeight, k091rCalibrWeight, k091rCalibrCoeff, k091rZeroCode, k091rTarget1,
      k091rTarget2, k091rTarget3, k091rTarget4, k091rTarget5, k091rTarget6, k091rTarget7,
      k091rTarget8, k091rTarget9, k091rAdvanceHard, k091rAdvanceSoft, k091rTare1, k091rTare2,
      k091rTare3, k091rTare4, k091rTare5, k091rTare6, k091rTare7, k091rTare8, k091rTare9,
      k091rTarePrecisionRange, k091rZeroTime, k091rDecayTime, k091rWeightCount, k091rWeightLast:
        RegCnt:=2;
    else
      (* k091rADC, k091rState, k091rDiscreteOuts, k091rDiscreteIns, k091rADCRange,
      k091rADCFrequency, k091rDiscreteness, k091rFloatDigits, k091rPolarity, k091rCurrentTarget,
      k091rDosingMode, k091rSoftOutMode, k091rFilterSize1, k091rFilterSize2, k091rNetNumber,
      k091rNetSpeed, k091rControlMode, k091rAutoZeroing, k091rDosingCount *)
      RegCnt:=1;
    end;

  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(k091cReadData), Integer(Regstr), RegCnt, kbctRead,
    ThreadId, False, Priority);
end;

procedure TKB_001_091.WriteData(Regstr: TKB_001_091_Register; RegCnt: Byte; Data: TBytes;
  DataLen: Byte; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(k091cWriteData), Integer(Regstr), RegCnt, Data, DataLen, kbctWrite,
    ThreadId, True, Priority);
end;

procedure TKB_001_091.SendCommand(Command: TKB_001_091_Command; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(Command), 0, 0, kbctCommand, ThreadId, True, Priority);
end;

procedure TKB_001_091.ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k091rState, 0, ThreadId, Priority);
end;

procedure TKB_001_091.ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k091rWeight, 0, ThreadId, Priority);
end;

procedure TKB_001_091.StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k091cStartDosing, ThreadId, Priority);
end;

procedure TKB_001_091.StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k091cStopDosing, ThreadId, Priority);
end;

procedure TKB_001_091.ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k091cResetDose, ThreadId, Priority);
end;

procedure TKB_001_091.WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(k091rTarget1, 0, Data, 4, ThreadId, Priority);
  FTarget[0]:=Value;
end;

procedure TKB_001_091.WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(k091rAdvanceHard, 0, Data, 4, ThreadId, Priority);
end;}

//==================================================================================================
//_________________________________________TKB_001_1102_____________________________________________
//==================================================================================================

function TKB_001_1102.GetRegCnt(Regstr: TKB_001_1102_Register): Byte;
begin
    //Some default counts (often used)
  Case Regstr of
    k1102rWeight, k1102rMaxWeight, k1102rCalibrWeight, k1102rCalibrCoeff, k1102rZeroCode,
    k1102rTarget1, k1102rTarget2, k1102rTarget3, k1102rAdvanceHard1, k1102rAdvanceHard2,
    k1102rAdvanceHard3, k1102rAdvanceSoft1, k1102rAdvanceSoft2, k1102rAdvanceSoft3,
    k1102rImpulsePause1, k1102rImpulsePause2, k1102rImpulsePause3, k1102rZeroZone, k1102rZeroTime,
    k1102rDecayTime, k1102rWeightGoneTime:
      Result:=2;
  Else
    (* k1102rADC, k1102rState, k1102rADCRange, k1102rADCFrequency, k1102rDiscreteness,
    k1102rFloatDigits, k1102rFilterSize1, k1102rFilterSize2, k1102rNetNumber, k1102rNetSpeed,
    k1102rDiscreteOperMode, k1102rAutoZeroing *)
    Result:=1;
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TKB_001_1102.Create(Address: Byte);
var
  i: Byte;
begin
  inherited Create(Address);
  FDevType:=dtK001_1102;
  FState:=Integer(k1102stWaiting);
  SetLength(FTarget, 9);
  For i:=Low(FTarget) to High(FTarget) do
    FTarget[i]:=0;
end;

procedure TKB_001_1102.ReadData(Regstr: TKB_001_1102_Register; RegCnt: Byte=0; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(k1102cReadData), Integer(Regstr), RegCnt, kbctRead,
    ThreadId, False, Priority);
end;

procedure TKB_001_1102.WriteData(Regstr: TKB_001_1102_Register; RegCnt: Byte; Data: TBytes;
  DataLen: Byte; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(k1102cWriteData), Integer(Regstr), RegCnt, Data, DataLen,
    kbctWrite, ThreadId, True, Priority);
end;

procedure TKB_001_1102.SendCommand(Command: TKB_001_1102_Command; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(Command), 0, 0, kbctCommand, ThreadId, True, Priority);
end;

procedure TKB_001_1102.ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k1102rState, 0, ThreadId, Priority);
end;

procedure TKB_001_1102.ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(k1102rWeight, 0, ThreadId, Priority);
end;

procedure TKB_001_1102.StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k1102cStartDosing, ThreadId, Priority);
end;

procedure TKB_001_1102.StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k1102cStopDosing, ThreadId, Priority);
end;

procedure TKB_001_1102.ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(k1102cResetDose, ThreadId, Priority);
end;

procedure TKB_001_1102.WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(k1102rTarget1, 0, Data, 4, ThreadId, Priority);
  FTarget[0]:=Value;
end;

procedure TKB_001_1102.WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  If FUseHardAdvance then
    WriteData(k1102rAdvanceHard1, 0, Data, 4, ThreadId, Priority)
  Else WriteData(k1102rAdvanceSoft1, 0, Data, 4, ThreadId, Priority);
end;

function TKB_001_1102.IsDosing: Boolean;
begin
  Result:=TKB_001_1102_State(FState) in [k1102stDosing1, k1102stPause1, k1102stImpulse1];
end;

//==================================================================================================
//____________________________________________TPTC_001______________________________________________
//==================================================================================================

function TPTC_001.GetRegCnt(Regstr: TPTC_001_Register): Byte;
begin
    //Some default counts (often used)
  Case Regstr of
    kPTCrWeight, kPTCrCalibrCoeff, kPTCrZeroCode, kPTCrTarget, kPTCrAdvanceHard, kPTCrAdvanceSoft:
      Result:=2;
  Else
    (* kPTCrADC, kPTCrState, kPTCrADCRange, kPTCrADCFrequency, kPTCrOutType,  kPTCrPolarity,
    kPTCrFilterSize1, kPTCrFilterSize2, kPTCrNetNumber, kPTCrNetSpeed, kPTCrADCCanal,
    kPTCrAllowDosing, kPTCrAutoZeroing, kPTCrInputs, kPTCrOutputs *)
    Result:=1;
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TPTC_001.Create(Address: Byte);
var
  i: Byte;
begin
  inherited Create(Address);
  FDevType:=dtPTC001;
  FState:=Integer(kPTCstWaiting);
  SetLength(FTarget, 9);
  For i:=Low(FTarget) to High(FTarget) do
    FTarget[i]:=0;
end;

procedure TPTC_001.ReadData(Regstr: TPTC_001_Register; RegCnt: Byte=0; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(kPTCcReadData), Integer(Regstr), RegCnt, kbctRead,
    ThreadId, False, Priority);
end;

procedure TPTC_001.WriteData(Regstr: TPTC_001_Register; RegCnt: Byte; Data: TBytes;
  DataLen: Byte; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  If RegCnt=0 then RegCnt:=GetRegCnt(Regstr);
  ComComm.ToKB(FAddress, Integer(kPTCcWriteData), Integer(Regstr), RegCnt, Data, DataLen,
    kbctWrite, ThreadId, True, Priority);
end;

procedure TPTC_001.SendCommand(Command: TPTC_001_Command; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
begin
  If not FIsInWork then Exit;
  ComComm.ToKB(FAddress, Integer(Command), 0, 0, kbctCommand, ThreadId, True, Priority);
end;

procedure TPTC_001.ReadState(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(kPTCrState, 0, ThreadId, Priority);
end;

procedure TPTC_001.ReadWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  ReadData(kPTCrWeight, 0, ThreadId, Priority);
end;

procedure TPTC_001.StartDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kPTCcStartDosing, ThreadId, Priority);
end;

procedure TPTC_001.StopDosing(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kPTCcStopDosing, ThreadId, Priority);
end;

procedure TPTC_001.ResetWeight(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kPTCcResetDose, ThreadId, Priority);
end;

procedure TPTC_001.WriteWeight(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(kPTCrTarget, 0, Data, 4, ThreadId, Priority);
  FTarget[0]:=Value;
end;

procedure TPTC_001.WriteAdvance(Value: Single; ThreadId: Int64=0; Priority: Byte=cDefPriority);
var
  Data: TBytes;
begin
  Data:=SingleToBytes(Value);
  WriteData(kPTCrAdvanceHard, 0, Data, 4, ThreadId, Priority);
end;

function TPTC_001.IsDosing: Boolean;
begin
  Result:=TPTC_001_State(FState) in [kPTCstDosing, kPTCstImpulse];
end;

//==================================================================================================
//________________________________________________TKGD______________________________________________
//==================================================================================================

procedure TKGD.SetMeasResult(Value: TKGD_Result);
begin
  If Value in [kKGDrGood, kKGDrBad] then
  Begin
    if FState = kKGDsWaiting then Exit;
    FState:=kKGDsWaiting;
  End;
  FMeasResult:=Value;
end;

//--------------------------------------------------------------------------------------------------

constructor TKGD.Create(Address: Byte);
begin
  inherited Create(Address);
  FDevType:=dtKGD;
  FState:=kKGDsWaiting;
  FMeasResult:=kKGDrUnknown;
  FMeasTime:=10000;
end;

destructor TKGD.Destroy;
begin
  inherited;
end;

procedure TKGD.SendCommand(Command: TKGD_Command; Value: AnsiString; ThreadId: Int64;
  Priority: Byte);
var
  Cmnd, Data: AnsiString;
begin
  If not FIsInWork then Exit;

  If Integer(Command) < 10 then
    Cmnd:='0'+IntToStr(Integer(Command))
  Else Cmnd:=IntToStr(Integer(Command));
  Data:=Value;
  If Data <> '' then Data:=':'+Data;

  ComComm.ToKGSD(FAddress, 'kgd'+Cmnd+Data, ThreadId, Priority);
end;

procedure TKGD.StartMeasuring(Weight: Cardinal; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  FMeasResult:=kKGDrUnknown;
  SendCommand(kKGDcStart, IntToStr(Weight), ThreadId, Priority);  //Weight in grams
end;

procedure TKGD.StopMeasuring(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kKGDcStop, '', ThreadId, Priority);
end;

procedure TKGD.WriteMeasTime(Value: Cardinal; ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kKGDcSetTime, IntToStr(Value), ThreadId, Priority);
end;

procedure TKGD.ReadResult(ThreadId: Int64=0; Priority: Byte=cDefPriority);
begin
  SendCommand(kKGDcResult, '', ThreadId, Priority);
end;

//==================================================================================================
//_________________________________________TWorkingThread___________________________________________
//==================================================================================================

procedure TWorkingThread.Start;
begin
  FStop:=False;
  Resume;
end;

procedure TWorkingThread.Stop;
begin
  FStop:=True;
end;

function TWorkingThread.CheckSend(CheckStop: Boolean=True): Shortint;
var
  TMS: tagMSG;
begin
  (*
    Resut=-1 - terminating.     In code: Break;
    Resut=0  - continue working.
    Resut=1  - stopping.        In code: Continue;
  *)
  Result:=0;

    //Waiting for message from
  While not Terminated AND
    ((not FStop and CheckStop) Or not CheckStop) do
  Begin
    PeekMessage(TMS, 0, 0, 0, PM_REMOVE);
    case TMS.message of
      TM_KEEPONWORKING:     //Continue working
        begin Result:=0; Break; end;
      {TM_STOP:            //Stopping
        begin FStop:=True; Break; end;
      TM_KRYSHKA:         //Terminating
        begin Result:=-1; Break; end;}
    else
      inherited;
    end;
  End;//While not Terminated and not FStop do

  If Terminated then Result:=-1
  Else if FStop and CheckStop then Result:=1;

  FLastCheckSendResult:=Result;
end;

//--------------------------------------------------------------------------------------------------

constructor TWorkingThread.Create;
begin
  FStop:=False;
  FStopped:=True;
  inherited Create(False);
end;

procedure TWorkingThread.Resume;
begin
  FStopped:=False;
end;

procedure TWorkingThread.Suspend;
begin
  FStopped:=True;
  If Self is TBatcherDDThread then
    TBatcherDDThread(Self).SetStatus(bDDsWaiting)
  Else if Self is TBatcherVDThread then
    TBatcherVDThread(Self).SetStatus(bVDsWaiting)
  Else if Self is TDropper then
  Begin
    TDropper(Self).FStatus:=dsWaiting;
    Synchronize(TDropper(Self).DoStatusChanged);
  End
  Else if Self is TMixer then
  Begin
    TMixer(Self).FStatus:=msWaiting;
    Synchronize(TMixer(Self).DoStatusChanged);
  End;

    Priority:=tpLowest;
  While FStopped and not Terminated do Sleep(10);
    Priority:=tpNormal;
end;

//==================================================================================================
//____________________________________________TDevDXMOpts___________________________________________
//==================================================================================================

procedure TDevDXMOpts.DoChangeState(TurnOn: Boolean);
begin
  If Assigned(FOnChangeSate) then FOnChangeSate(TurnOn, Self);
end;

//--------------------------------------------------------------------------------------------------

constructor TDevDXMOpts.Create;
begin
  FDOM:=nil;
  FOutput:=0;
  FStateWhenOff:=False;
  FDIM:=nil;
  FInput:=0;
  FGoodWhenEqual:=False;
  FOnChangeSate:=nil;
end;

function TDevDXMOpts.OutputIsOff: Boolean;
begin
  If Assigned(FDOM) then
    Result:=FDOM.Output[FOutput]=FStateWhenOff
  Else Result:=False;
end;

function TDevDXMOpts.OutputIsOn: Boolean;
begin
  If Assigned(FDOM) then
    Result:=FDOM.Output[FOutput]<>FStateWhenOff
  Else Result:=False;
end;

procedure TDevDXMOpts.WaitForIndicator;
begin
  If Assigned(FDOM) and Assigned(FDIM) then
    while not (
      ((FDOM.Output[FOutput]=FDIM.Input[FInput]) And FGoodWhenEqual) OR
      ((FDOM.Output[FOutput]<>FDIM.Input[FInput]) And not FGoodWhenEqual)
    ) do
      Sleep(50);
end;

procedure TDevDXMOpts.WaitForOutputOn;
begin
  If Assigned(FDOM) then
    while FDOM.Output[FOutput]=FStateWhenOff do Sleep(50);
end;

procedure TDevDXMOpts.WaitForOutputOff;
begin
  If Assigned(FDOM) then
    while FDOM.Output[FOutput]<>FStateWhenOff do Sleep(50);
end;

//==================================================================================================
//_________________________________________TBatcherDDThread_________________________________________
//==================================================================================================

procedure TBatcherDDThread.SetStatus(Value: TBatcherDDStatus);
begin
  FParent.FStatus:=Value;
  Synchronize(FParent.DoStatusChanged);

  FParent.FCanStartNextStep:=False;
  While not FParent.FCanStartNextStep and not Terminated and not FStop do
  Begin
    Synchronize(FParent.DoCanStartNextStep);
    Sleep(10);
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TBatcherDDThread.Create;
begin
  inherited Create;
end;

procedure TBatcherDDThread.Execute;
const
  cDefPriority = 20;
var
  Step, i: Byte;
  Sending: Boolean;
  NoDosing: Boolean;
  DTLTime: Cardinal;  //Dosing/dropping too long
  WasDosing: Boolean;
  GetNextBatcher: Boolean;
  JustStarted: Boolean;
  HelpWaitTime, HelpWorkTime: Cardinal;
  LastWeright: Single;
begin
    //Initializing
  Sleep(50);  //A little sleep for setting all this thread properties
  DTLTime:=0;
  FParent.FStatus:=bDDsWaiting; //Default status
  WasDosing:=False;
  GetNextBatcher:=False;

  Suspend;

  WHILE not Terminated DO
  BEGIN

  If FStop then Suspend;
  If not GetNextBatcher then
    SetStatus(bDDsDosingPrepare)
  Else
  Begin
    SetStatus(bDDsDosingPrepare);
    GetNextBatcher:=False;
  End;
  Step:=1;
  NoDosing:=False;

    //------------------------------------
    //Dosing preparing
  While (FParent.FStatus in [bDDsDosingPrepare, bDDsStartDosing]) and
    not Terminated and not FStop and not NoDosing do
  Begin
    Sleep(10);
    Sending:=False;
    if FParent.FAuto then
      FStop:=(FParent.FBatcherCount=0) or (FParent.FDosingCount=0);
    if FStop then Continue;

    case Step of
      1:
        begin
          if FParent.Auto and (FParent.FDosingBatcher=0) then
            FParent.FNewCycle:=True;

            //Preparing
          if FParent.FAuto and (FParent.FDosingBatcher=0) and (FParent.FDosingNumber=0) then
          begin
            for i:=0 to FParent.FBatcherCount-1 do
            begin
              FParent.FResultCur[i]:=0;
              FParent.FResultBat[i]:=0;
              SetLength(FParent.FTaskReal[i], 0);
              SetLength(FParent.FResultAll[i], 0);
              SetLength(FParent.FResultTime[i], 0);
              SetLength(FParent.FTaskReal[i], FParent.FDosingCount);
              SetLength(FParent.FResultAll[i], FParent.FDosingCount);
              SetLength(FParent.FResultTime[i], FParent.FDosingCount);
            end;
            FParent.FResultDoser:=0;
          end
          else if not FParent.FAuto and (Length(FParent.FTaskReal[0])=0) then //Always one dosing
            for i:=0 to FParent.FBatcherCount-1 do
            begin
              SetLength(FParent.FTaskReal[i], 1);
              SetLength(FParent.FResultAll[i], 1);
              SetLength(FParent.FResultTime[i], 1);
            end;

            //Recalc last task
          with FParent do
          begin
            if FRecalcTask and (FTask[FDosingBatcher]>0) and
              (FDosingNumber = FDosingCount-1) and (FDosingCount > 1) then
            begin
              FTask[FDosingBatcher] :=
                FTask[FDosingBatcher] * FDosingCount - FResultBat[FDosingBatcher];
              if FTask[FDosingBatcher] + FResultDoser > FMaxWeight then
                FTask[FDosingBatcher] := FMaxWeight - FResultDoser;

              FTask[FDosingBatcher] := RoundTo(FTask[FDosingBatcher], -FController.FDecimal);

              if FTask[FDosingBatcher] > FMaxWeight then
                FTask[FDosingBatcher] := FMaxWeight
              else if FTask[FDosingBatcher] < FMinWeight then
                FTask[FDosingBatcher] := 0;
            end;
            FTaskReal[FDosingBatcher, FDosingNumber] := FTask[FDosingBatcher];
          end;

            //Task checking
          if (FParent.FTask[FParent.FDosingBatcher]=0) and FParent.FAuto then
          begin
            if FParent.FDosingBatcher=FParent.FBatcherCount-1 then
            begin
              if WasDosing then
              begin
                SetStatus(bDDsDosingFinished);
                Break;
              end
              else
              begin
                NoDosing:=True;
                FParent.FDosingBatcher:=0;
                Suspend;
                Continue;
              end;
            end
            else
            begin
              if WasDosing then
              begin
                SetStatus(bDDsDosingFinished);
                Break;
              end
              else
              begin
                Inc(FParent.FDosingBatcher);
                Continue;
              end;
            end;
          end
          else if (FParent.FTask[FParent.FDosingBatcher]=0) and
            not FParent.FAuto then
          begin
            NoDosing:=True;
            Suspend;
            Continue;
          end;

            //In automatic work not new cycle starts after 3s pause
          if FParent.Auto and not FParent.FNewCycle then Sleep(3000);

            //Checcking errors before dosing
          FParent.FCanDose:=False;
          while not FParent.FCanDose and not Terminated and not FStop do
          begin
            Synchronize(FParent.DoCheckDosing);
            Sleep(10);
          end;
          FParent.FNewCycle:=False;
        end;

      2:  //Controller settings: Advance writing
        begin
          FParent.FController.WriteAdvance(
            FParent.FAdvance[FParent.FDosingBatcher], ThreadID, cDefPriority);
          Sending:=True;
        end;

      3:  //Additional step
        {if (FParent.FController is TKB_001_1102) then
        begin   //1 16 0 3 0 1 2 2 7 CRC - состояние контроллера 2!, диапазон входного тензоканала 19,53
          TKB_001_1102(FParent.FController).WriteData(k1102rADCRange, 0,
            SingleToBytes(BytesToSingle([2, 7, 0, 0])), 2, ThreadID, cDefPriority);
          Sending:=True;
        end;
        if (FParent.FController is TKB_001_08) and (FParent.FController.FAddress = 1) then
        begin   //13 16 0 28 0 1 2 0 1 CRC - режим дозирования 0!, фильтр 4
          TKB_001_08(FParent.FController).WriteData(k1102rADCRange, 0,
            SingleToBytes(BytesToSingle([0, 1, 0, 0])), 2, ThreadID, cDefPriority);
          Sending:=True;
        end};

      4:  //Sending task
        begin
          FParent.FController.WriteWeight(
            FParent.FTask[FParent.FDosingBatcher], ThreadID, cDefPriority);
          Sending:=True;
        end;

      5:  //Preparing of canals
        with FParent.FCanalOpts[FParent.FDosingBatcher] do
          if Assigned(DOM) then
            if OutputIsOff then
            begin
              DOM.OutputOn(Output, dcdOutsNeed, ThreadID, cDefPriority);
              DoChangeState(True);
              Sending:=True;
            end;

      6:  //Event before start dosing
        begin
          SetStatus(bDDsStartDosing);
        end;

      7:  //Dosing start
        begin
          FParent.FStartWeight:=FParent.FController.FWeight;
          FParent.FController.StartDosing(ThreadID, cDefPriority);
          Sending:=True;
        end;

      8:  //Go to next stage
        begin
            //Принудительное чтение веса, нуля
          FParent.FController.ReadWeight(ThreadID, cDefPriority);

          DTLTime:=GetTickCount + FParent.FMaxDosingTime * 1000;

          Step:=0;
          FParent.FController.FWeight:=0;
          SetStatus(bDDsDosing);

          //Sleep(500);
        end;
    end;//case Step of

      //If there wasn't sending then go to next step
    if not Sending then
      Inc(Step)
    else //if Sending then
      if CheckSend=0 then
        Inc(Step);

  End;//While FParent.FStatus in [bDDsDosingPrepare, bDDsStartDosing] do
  If NoDosing then Continue;

    //------------------------------------
    //Dosing
  JustStarted:=True;
  HelpWaitTime:=0;
  HelpWorkTime:=0;
  LastWeright:=0;
  While (FParent.FStatus=bDDsDosing) and not Terminated do
  Begin
    Sleep(10);

    if JustStarted then //Waiting for start
    begin
      if not FParent.FController.IsDosing and not FStop then Continue;
      JustStarted:=False;
      FParent.FController.FWeight:=0;
    end;

      //Dosing helpers
    with FParent.FDosHelpOpts[FParent.FDosingBatcher] do
      if Assigned(DOM) and (TimeWork > 0) then  //assigned and can help
      begin
        if TimeWork = 0 then  //always works
          HelpWorkTime:=Cardinal(-1)
        else if ((HelpWorkTime > 0) and (GetTickCount >= HelpWorkTime)) OR  //work is done
          ((HelpWorkTime = 0) and (HelpWaitTime = 0)) then  //just begun
        begin
          HelpWorkTime:=0;
          HelpWaitTime:=GetTickCount + TimeWait;
        end
        else if (HelpWaitTime > 0) and (GetTickCount >= HelpWaitTime) then  //waiting is done
        begin
            //weight wasn't changed (more than 2%)
          if Abs(LastWeright - FParent.FController.Weight) <
            FParent.FTask[FParent.FDosingBatcher] * 0.02 then
          begin
            HelpWaitTime:=0;
            HelpWorkTime:=GetTickCount + TimeWork;
          end
          else  //weight has been changed
          begin
            HelpWorkTime:=0;
            HelpWaitTime:=GetTickCount + TimeWait;
          end;
          LastWeright:=FParent.FController.Weight;
        end;

        if OutputIsOff AND (HelpWorkTime > 0) AND
          (FParent.FController.Weight - FParent.FStartWeight < FParent.FTask[FParent.FDosingBatcher] * 0.99) then
        begin
          DOM.OutputOn(Output, dcdOutsNeed, ThreadID, cDefPriority);
          WaitForOutputOn;
        end
        else if OutputIsOn AND ( (HelpWaitTime>0) Or ((HelpWaitTime=0) and (HelpWorkTime=0)) ) then
        begin
          DOM.OutputOff(Output, dcdOutsNeed, ThreadID, cDefPriority);
          WaitForOutputOff;
        end;
      end;

      //Very long dosing. Works just once
    if (GetTickCount>=DTLTime) and (DTLTime>0) then
    begin
      DTLTime:=0;
      Synchronize(FParent.DoLongDosing);
    end;

      //Weight was fixed
    if FParent.WorkIsDone or FStop then
    begin
      DTLTime:=0;
      WasDosing:=True;

        //Turning off canal
      with FParent.FCanalOpts[FParent.FDosingBatcher] do
        if Assigned(DOM) and OutputIsOn then
        begin
          DOM.OutputOff(Output, dcdOutsNeed, 0, cDefPriority);
          DoChangeState(False);
        end;

        //Turning off helper
      with FParent.FDosHelpOpts[FParent.FDosingBatcher] do
        if Assigned(DOM) and (TimeWork > 0) and OutputIsOn then
          DOM.OutputOff(Output, dcdOutsNeed, ThreadID, cDefPriority);

        //Need more weight info!
      FParent.FController.ReadWeight(ThreadID, cDefPriority);
      FParent.FController.ReadWeight(ThreadID, cDefPriority);
      FParent.FController.ReadWeight(ThreadID, cDefPriority);
      FParent.FController.ReadWeight(ThreadID, cDefPriority);
      FParent.FController.ReadWeight(ThreadID, cDefPriority);

      Sleep(FParent.FTimeDamping);  //Waiting for vibration damping

        //Writing result
      with FParent do
      begin
        FResultCur[FDosingBatcher] := FController.FWeight - FStartWeight;
        FResultDoser := FController.FWeight;
        FResultBat[FDosingBatcher] := FResultBat[FDosingBatcher] + FResultCur[FDosingBatcher];
        FResultAll[FDosingBatcher, FDosingNumber] := FResultCur[FDosingBatcher];
        FResultTime[FDosingBatcher, FDosingNumber] := Now;
      end;

        //Stopping dosing
      FParent.FController.StopDosing(ThreadID, cDefPriority);
        Sleep(300);
      FParent.FController.StopDosing(ThreadID, cDefPriority);
        Sleep(300);
      FParent.FController.StopDosing(ThreadID, cDefPriority);
        //Reseting dose
      //FParent.FController.ResetWeight(0, cDefPriority);

        //Finished
      Synchronize(FParent.DoDosingFinished);
      SetStatus(bDDsDosingFinished);
    end;

  End;//While FParent.FStatus=bDDsDosing do

    //Preparing for next bather
  If (FParent.FDosingBatcher = FParent.FBatcherCount-1) and
     (FParent.FDosingNumber < FParent.FDosingCount-1) and FParent.FAuto then
  Begin
    FParent.FDosingBatcher:=0;
    Inc(FParent.FDosingNumber);
    Continue;
  End;
  If (FParent.FStatus=bDDsDosingFinished) and FParent.FAuto and
     (FParent.FDosingBatcher < FParent.FBatcherCount-1) then
  Begin
    GetNextBatcher:=True;
    Inc(FParent.FDosingBatcher);
    Continue;
  End;

    //------------------------------------
    //Dosing full done
  SetStatus(bDDsDosingFullDone);
  Suspend;

  END;//WHILE not Terminated DO
end;

//==================================================================================================
//_________________________________________TBatcherVDThread_________________________________________
//==================================================================================================

procedure TBatcherVDThread.SetStatus(Value: TBatcherVDStatus);
begin
  FParent.FStatus:=Value;
  Synchronize(FParent.DoStatusChanged);

  FParent.FCanStartNextStep:=False;
  While not FParent.FCanStartNextStep and not Terminated and not FStop do
  Begin
    Synchronize(FParent.DoCanStartNextStep);
    Sleep(10);
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TBatcherVDThread.Create;
begin
  inherited Create;
end;

procedure TBatcherVDThread.Execute;
const
  cDefPriority = 20;
var
  Step, i: Byte;
  Sending: Boolean;
  NoDosing: Boolean;
  DTLTime: Cardinal;  //Dosing too long
  WasDosing: Boolean;
begin
    //Initializing

  Suspend;

  WHILE not Terminated DO
  BEGIN

  If FStop then Suspend;
  SetStatus(bVDsDosingPrepare);
  Step:=1;
  NoDosing:=False;

    //------------------------------------
    //Dosing preparing
  While (FParent.FStatus in [bVDsDosingPrepare, bVDsStartDosing]) and
    not Terminated and not FStop and not NoDosing do
  Begin
    Sleep(10);
    Sending:=False;
    if FParent.FAuto then
      FStop:=(FParent.FBatcherCount=0) or (FParent.FDosingCount=0);
    if FStop then Continue;

    case Step of
      1:
        begin
            //Preparing
          if FParent.FAuto and (FParent.FDosingBatcher=0) and (FParent.FDosingNumber=0) then
          begin
            for i:=0 to FParent.FBatcherCount-1 do
            begin
              FParent.FResultCur[i]:=0;
              FParent.FResultBat[i]:=0;
              SetLength(FParent.FResultAll[i], 0);
              SetLength(FParent.FResultTime[i], 0);
              SetLength(FParent.FResultAll[i], FParent.FDosingCount);
              SetLength(FParent.FResultTime[i], FParent.FDosingCount);
            end;
            FParent.FResultDoser:=0;
          end
          else if not FParent.FAuto and (Length(FParent.FResultAll[0])=0) then //Always one dosing
            for i:=0 to FParent.FBatcherCount-1 do
            begin
              SetLength(FParent.FResultAll[i], 1);
              SetLength(FParent.FResultTime[i], 1);
            end;

            //Checcking errors before dosing
          FParent.FCanDose:=False;
          while not FParent.FCanDose and not Terminated and not FStop do
          begin
            Synchronize(FParent.DoCheckDosing);
            Sleep(10);
          end;

            //If work is done, don't start, only finish
          if FParent.WorkIsDone then
          begin
            SetStatus(bVDsDosing);
            DTLTime:=0;
            Break;
          end;
        end;

      2:  //Reset weight
        if Assigned(FParent.FController) then
        begin
          FParent.FController.ResetWeight(ThreadID, cDefPriority);
          Sending:=True;
        end;

      3:  //Event before start dosing
        SetStatus(bVDsStartDosing);

      4:  //Start dosing
        with FParent.FFeederOpts[FParent.FDosingBatcher] do
          if Assigned(DOM) then
            if OutputIsOff then
            begin
              DOM.OutputOn(Output, dcdOutsNeed, ThreadID, cDefPriority);
              DoChangeState(True);
              Sending:=True;
            end;

      5:  //Go to next stage
        begin
          DTLTime:=GetTickCount + FParent.FMaxDosingTime * 1000;

          Step:=0;
          if Assigned(FParent.FController) then
            FParent.FController.FWeight:=0;
          SetStatus(bVDsDosing);
        end;
    end;//case Step of

      //If there wasn't sending then go to next step
    if not Sending then
      Inc(Step)
    else //if Sending then
      if CheckSend=0 then
        Inc(Step);

  End;//While FParent.FStatus in [bDDsDosingPrepare, bDDsStartDosing] do
  If NoDosing then Continue;

    //------------------------------------
    //Dosing
  While (FParent.FStatus = bVDsDosing) and not Terminated do
  Begin
    Sleep(10);

      //Very long dosing. Works just once
    if (GetTickCount >= DTLTime) and (DTLTime > 0) then
    begin
      DTLTime:=0;
      Synchronize(FParent.DoLongDosing);
    end;

      //Work is done
    if FParent.WorkIsDone or FStop then
    begin
      DTLTime:=0;
      WasDosing:=True;

        //Stop dosing
      with FParent.FFeederOpts[FParent.FDosingBatcher] do
        if Assigned(DOM) and OutputIsOn then
        begin
          DOM.OutputOff(Output, dcdOutsNeed, 0, cDefPriority);
          DoChangeState(False);
        end;

      Sleep(FParent.FTimeDamping);  //Waiting for vibration damping

        //Writing result
      with FParent do
      begin
        if Assigned(FController) then
        begin
          FResultCur[FDosingBatcher] := FController.FWeight;
          FResultBat[FDosingBatcher] := FResultBat[FDosingBatcher] + FResultCur[FDosingBatcher];
          FResultAll[FDosingBatcher, FDosingNumber] := FResultCur[FDosingBatcher];
          FResultDoser := FResultDoser + FResultCur[FDosingBatcher];
        end;
        FResultTime[FDosingBatcher, FDosingNumber] := Now;
      end;

        //Finished
      Synchronize(FParent.DoDosingFinished);
      SetStatus(bVDsDosingFinished);
    end;

  End;//While FParent.FStatus = bVDsDosing do

    //Preparing for next bather
  If (FParent.FDosingBatcher = FParent.FBatcherCount-1) and
     (FParent.FDosingNumber < FParent.FDosingCount-1) and FParent.FAuto then
  Begin
    FParent.FDosingBatcher:=0;
    Inc(FParent.FDosingNumber);
    Continue;
  End;
  If (FParent.FStatus=bVDsDosingFinished) and FParent.FAuto and
     (FParent.FDosingBatcher < FParent.FBatcherCount-1) then
  Begin
    Inc(FParent.FDosingBatcher);
    Continue;
  End;

    //------------------------------------
    //Dosing full done
  SetStatus(bVDsDosingFullDone);
  Suspend;

  END;//WHILE not Terminated DO
end;

//==================================================================================================
//_____________________________________________TBatcher_____________________________________________
//==================================================================================================

function TBatcher.GetResultCur(BNum: Byte): Currency;
begin
  If BNum>Length(FResultCur)-1 then Exit(0);
  Result:=FResultCur[BNum];
end;

procedure TBatcher.SetResultCur(BNum: Byte; Value: Currency);
begin
  If BNum>Length(FResultCur)-1 then Exit;
  FResultCur[BNum]:=Value;
end;

function TBatcher.GetResultBat(BNum: Byte): Currency;
begin
  If BNum>Length(FResultBat)-1 then Exit(0);
  Result:=FResultBat[BNum];
end;

procedure TBatcher.SetResultBat(BNum: Byte; Value: Currency);
begin
  If BNum>Length(FResultBat)-1 then Exit;
  FResultBat[BNum]:=Value;
end;

function TBatcher.GetResultAll(BNum: Byte; DNum: Cardinal): Currency;
begin
  If (BNum>Length(FResultAll)-1) or (DNum>Length(FResultAll[BNum])-1) then Exit(0);
  Result:=FResultAll[BNum, DNum];
end;

procedure TBatcher.SetResultAll(BNum: Byte; DNum: Cardinal; Value: Currency);
begin
  If (BNum>Length(FResultAll)-1) or (DNum>Length(FResultAll[BNum])-1) then Exit;
  FResultAll[BNum, DNum]:=Value;
end;

function TBatcher.GetResultTime(BNum: Byte; DNum: Cardinal): TDateTime;
begin
  If (BNum>Length(FResultTime)-1) or (DNum>Length(FResultTime[BNum])-1) then Exit(0);
  Result:=FResultTime[BNum, DNum];
end;

procedure TBatcher.SetResultTime(BNum: Byte; DNum: Cardinal; Value: TDateTime);
begin
  If (BNum>Length(FResultTime)-1) or (DNum>Length(FResultTime[BNum])-1) then Exit;
  FResultTime[BNum, DNum]:=Value;
end;

function TBatcher.GetStopped: Boolean;
begin
  Result:=FDosing.FStopped;
end;

procedure TBatcher.DoStatusChanged;
begin
  If Assigned(FOnStatusChanged) then FOnStatusChanged(Self);
end;

procedure TBatcher.DoCheckDosing;
begin
  If Assigned(FOnCheckDosing) then FCanDose:=FOnCheckDosing(Self);
end;

procedure TBatcher.DoLongDosing;
begin
  If Assigned(FOnLongDosing) then FOnLongDosing(Self);
end;

procedure TBatcher.DoDosingFinished;
begin
  If Assigned(FOnDosingFinished) then FOnDosingFinished(Self);
end;

procedure TBatcher.DoCanStartNextStep;
begin
  If Assigned(FOnCanStartNextStep) then
    FCanStartNextStep:=FOnCanStartNextStep(Self)
  Else FCanStartNextStep:=True;
end;

//--------------------------------------------------------------------------------------------------

constructor TBatcher.Create(BatcherCnt: Byte=1);
begin
  If BatcherCnt=0 then
    raise Exception.Create('You must specify the number of dosing batchers');
  FBatcherCount:=BatcherCnt;
  FDosingBatcher:=0;
  SetLength(FResultCur, BatcherCnt);
  SetLength(FResultBat, BatcherCnt);
  SetLength(FResultAll, BatcherCnt);
  SetLength(FResultTime, BatcherCnt);
  FResultDoser:=0;
  FDosingCount:=0;
  FDosingNumber:=0;
end;

destructor TBatcher.Destroy;
begin
  FDosing.Terminate;
end;

function TBatcher.StartDosing(BatcherNumber: Byte=0; Auto: Boolean=True): Boolean;
begin
  (* If BatcherNumber>0 then it will be dosed only one dosing batcher *)

  Result:=False;
  If BatcherNumber > 0 then
    if BatcherNumber-1 > FBatcherCount-1 then Exit;

  FAuto:=Auto;
  FDosingBatcher:=BatcherNumber;
  FDosingNumber:=0;
  FDosing.Start;
  Result:=True;
end;

procedure TBatcher.Stop;
begin
  FDosing.Stop;
end;

procedure TBatcher.Empty(Full: Boolean=False);
var
  i, j: Byte;
begin
  For i:=0 to FBatcherCount-1 do
  Begin
    ResultCur[i]:=0;
    if Full then
    begin
      ResultBat[i]:=0;
      for j:=0 to FDosingCount-1 do
      begin
        ResultAll[i, j]:=0;
        ResultTime[i, j]:=0;
      end;
    end;
  End;
  ResultDoser:=0;
end;

//==================================================================================================
//___________________________________________TBatcherDD_____________________________________________
//==================================================================================================

function TBatcherDD.GetTask(BNum: Byte): Currency;
begin
  If BNum>Length(FTask)-1 then Exit(0);
  Result:=FTask[BNum];
end;

procedure TBatcherDD.SetTask(BNum: Byte; Value: Currency);
begin
  If BNum>Length(FTask)-1 then Exit;
  FTask[BNum]:=Value;
end;

function TBatcherDD.GetTaskReal(BNum: Byte; DNum: Cardinal): Currency;
begin
  If (BNum>Length(FTaskReal)-1) or (DNum>Length(FTaskReal[BNum])-1) then Exit(0);
  Result:=FTaskReal[BNum, DNum];
end;

function TBatcherDD.GetAdvance(Index: Byte): Single;
begin
  If Index>Length(FAdvance)-1 then Exit(0);
  Result:=FAdvance[Index];
end;

procedure TBatcherDD.SetAdvance(Index: Byte; Value: Single);
begin
  If Index>Length(FAdvance)-1 then Exit;
  FAdvance[Index]:=Value;
end;

function TBatcherDD.GetCanalOpts(Index: Byte): TDevDXMOpts;
begin
  If Index>Length(FCanalOpts)-1 then Exit(nil);
  Result:=FCanalOpts[Index];
end;

procedure TBatcherDD.SetCanalOpts(Index: Byte; Value: TDevDXMOpts);
begin
  If Index>Length(FCanalOpts)-1 then Exit;
  FCanalOpts[Index]:=Value;
end;

function TBatcherDD.GetDosHelpOpts(Index: Byte): TDevDXMOpts;
begin
  If Index>Length(FDosHelpOpts)-1 then Exit(nil);
  Result:=FDosHelpOpts[Index];
end;

procedure TBatcherDD.SetDosHelpOpts(Index: Byte; Value: TDevDXMOpts);
begin
  If Index>Length(FDosHelpOpts)-1 then Exit;
  FDosHelpOpts[Index]:=Value;
end;

function TBatcherDD.WorkIsDone: Boolean;
begin
  If FController is TKB_001_081 then
    Result:=(TKB_001_081_State(FController.FState) in
      [k081stWaiting, k081stUnload, k081stUnloadWaiting]) and
        (FController.FWeight >= FTask[FDosingBatcher] * 0.5)
  Else if FController is TKB_001_1102 then
    Result:=(TKB_001_1102_State(FController.FState) in
      [k1102stWaiting, k1102stUnload, k1102stDosingFinished,
      k1102stDosing2, k1102stPause2, k1102stImpulse2]) and
        (FController.FWeight >= FStartWeight + FTask[FDosingBatcher] * 0.5)
      [kPTCstWaiting]) and (FController.FWeight >= FTask[FDosingBatcher] * 0.5)
  Else
    Result:=False;
end;

//--------------------------------------------------------------------------------------------------

constructor TBatcherDD.Create(BatcherCnt: Byte=1);
var
  i: Integer;
begin
  inherited Create(BatcherCnt);
  FDosing:=TBatcherDDThread.Create;
    TBatcherDDThread(FDosing).FParent:=Self;
    FDosing.Priority:=tpNormal;
    FDosing.FreeOnTerminate:=True;
  FStatus:=bDDsWaiting;
  SetLength(FAdvance, BatcherCnt);
  SetLength(FCanalOpts, BatcherCnt);
  SetLength(FDosHelpOpts, BatcherCnt);
  FMaxDosingTime:=1000;
  FTimeDamping:=2000;
  For i:=0 to Length(FCanalOpts)-1 do
    FCanalOpts[i]:=TDevDXMOpts.Create;
  For i:=0 to Length(FDosHelpOpts)-1 do
    FDosHelpOpts[i]:=TDevDXMOpts.Create;

  SetLength(FTask, BatcherCnt);
  SetLength(FTaskReal, BatcherCnt);
  FRecalcTask:=False;
  FMinWeight:=0;
  FMaxWeight:=1000000;
end;

destructor TBatcherDD.Destroy;
var
  i: Integer;
begin
  For i:=0 to Length(FCanalOpts)-1 do
    FreeAndNil(FCanalOpts[i]);
end;

function TBatcherDD.StartDosing(BatcherNumber: Byte=0; Auto: Boolean=True): Boolean;
begin
  If not HasTask then Exit(False);
  Result:=inherited StartDosing(BatcherNumber, Auto);
end;

function TBatcherDD.HasTask: Boolean;
var
  i: Byte;
begin
  Result := False;
  If Length(FTask) > 0 then
    for i := Low(FTask) to High(FTask) do
      if FTask[i] > 0 then Exit(True);
end;

//==================================================================================================
//___________________________________________TBatcherVD_____________________________________________
//==================================================================================================

function TBatcherVD.GetFeederOpts(Index: Byte): TDevDXMOpts;
begin
  If Index>Length(FFeederOpts)-1 then Exit(nil);
  Result:=FFeederOpts[Index];
end;

procedure TBatcherVD.SetFeederOpts(Index: Byte; Value: TDevDXMOpts);
begin
  If Index>Length(FFeederOpts)-1 then Exit;
  FFeederOpts[Index]:=Value;
end;

function TBatcherVD.GetSensorOpts(Index: Byte): TDevDXMOpts;
begin
  If Index>Length(FSensorOpts)-1 then Exit(nil);
  Result:=FSensorOpts[Index];
end;

procedure TBatcherVD.SetSensorOpts(Index: Byte; Value: TDevDXMOpts);
begin
  If Index>Length(FSensorOpts)-1 then Exit;
  FSensorOpts[Index]:=Value;
end;

function TBatcherVD.WorkIsDone: Boolean;
begin
  Result:=False;
  With FSensorOpts[FDosingBatcher] do
    if Assigned(FDIM) then
      Result := FDIM.Input[FInput] <> FStateWhenOff;
end;

//--------------------------------------------------------------------------------------------------

constructor TBatcherVD.Create(BatcherCnt: Byte=1);
var
  i: Integer;
begin
  inherited Create(BatcherCnt);
  FDosing:=TBatcherVDThread.Create;
    TBatcherVDThread(FDosing).FParent:=Self;
    FDosing.Priority:=tpNormal;
    FDosing.FreeOnTerminate:=True;
  FStatus:=bVDsWaiting;
  FMaxDosingTime:=1000;
  FTimeDamping:=2000;
  SetLength(FFeederOpts, BatcherCnt);
  SetLength(FSensorOpts, BatcherCnt);
  For i:=0 to Length(FFeederOpts)-1 do
    FFeederOpts[i]:=TDevDXMOpts.Create;
  For i:=0 to Length(FSensorOpts)-1 do
    FSensorOpts[i]:=TDevDXMOpts.Create;
end;

destructor TBatcherVD.Destroy;
var
  i: Integer;
begin
  For i:=0 to Length(FFeederOpts)-1 do
    FreeAndNil(FFeederOpts[i]);
  For i:=0 to Length(FSensorOpts)-1 do
    FreeAndNil(FSensorOpts[i]);
end;

//==================================================================================================
//____________________________________________TDropper______________________________________________
//==================================================================================================

function TDropper.GetShutters(Index: Byte): TDevDXMOpts;
begin
  If Index>Length(FShutters)-1 then Exit(nil);
  Result:=FShutters[Index];
end;

procedure TDropper.SetShutters(Index: Byte; Value: TDevDXMOpts);
begin
  If Index>Length(FShutters)-1 then Exit;
  FShutters[Index]:=Value;
end;

function TDropper.GetAllowance(Index: Byte): Single;
begin
  If Index>Length(FAllowance)-1 then Exit(0);
  Result:=FAllowance[Index];
end;

procedure TDropper.SetAllowance(Index: Byte; Value: Single);
begin
  If Index>Length(FAllowance)-1 then Exit;
  FAllowance[Index]:=Value;
end;

function TDropper.GetMaxDroppingTime(Index: Byte): Cardinal;
begin
  If Index>Length(FMaxDroppingTime)-1 then Exit(0);
  Result:=FMaxDroppingTime[Index];
end;

procedure TDropper.SetMaxDroppingTime(Index: Byte; Value: Cardinal);
begin
  If Index>Length(FMaxDroppingTime)-1 then Exit;
  FMaxDroppingTime[Index]:=Value;
end;

function TDropper.GetDropByTime(Index: Byte): Boolean;
begin
  If Index>Length(FDropByTime)-1 then Exit(False);
  Result:=FDropByTime[Index];
end;

procedure TDropper.SetDropByTime(Index: Byte; Value: Boolean);
begin
  If Index>Length(FDropByTime)-1 then Exit;
  FDropByTime[Index]:=Value;
end;

function TDropper.GetIsEmpty(Index: Byte): Boolean;
begin
  If Index>Length(FIsEmpty)-1 then Exit(False);
  Result:=FIsEmpty[Index];
end;

procedure TDropper.SetIsEmpty(Index: Byte; Value: Boolean);
begin
  If Index>Length(FIsEmpty)-1 then Exit;
  FIsEmpty[Index]:=Value;
end;

function TDropper.GetDroppable(Index: Byte): Boolean;
begin
  If Index>Length(FDroppable)-1 then Exit(False);
  Result:=FDroppable[Index];
end;

procedure TDropper.SetDroppable(Index: Byte; Value: Boolean);
begin
  If Index>Length(FDroppable)-1 then Exit;
  FDroppable[Index]:=Value;
end;

function TDropper.GetCanClose(Index: Byte): Boolean;
begin
  If Index>Length(FCanClose)-1 then Exit(False);
  Result:=FCanClose[Index];
end;

procedure TDropper.SetCanClose(Index: Byte; Value: Boolean);
begin
  If Index>Length(FCanClose)-1 then Exit;
  FCanClose[Index]:=Value;
end;

procedure TDropper.DoBeforeMixerOn;
begin
  If Assigned(FOnBeforeMixerOn) then
    FAllowMixerOn:=FOnBeforeMixerOn(Self, FDoserNumber)
  Else FAllowMixerOn:=True;
end;

procedure TDropper.DoStatusChanged;
begin
  If Assigned(FOnStatusChanged) then FOnStatusChanged(Self, FDoserNumber);
end;

procedure TDropper.DoAllowDrop;
begin
  If Assigned(FOnAllowDrop) then
    FAllowDrop:=FOnAllowDrop(Self, FDoserNumber)
  Else FAllowDrop:=True;
end;

procedure TDropper.DoLongDropping;
begin
  If Assigned(FOnLongDropping) then FOnLongDropping(Self, FDoserNumber);
end;

procedure TDropper.DoGetWeight;
begin
  If Assigned(FOnGetWeight) then FWeightCur:=FOnGetWeight(Self, FDoserNumber);
end;

procedure TDropper.DoCanStartNextStep;
begin
  If Assigned(FOnCanStartNextStep) then
    FCanStartNextStep:=FOnCanStartNextStep(Self, FDoserNumber)
  Else FCanStartNextStep:=True;
end;

procedure TDropper.SetStatus(Value: TDropperStatus);
begin
  FStatus:=Value;
  Synchronize(DoStatusChanged);

  FCanStartNextStep:=False;
  While not FCanStartNextStep and not Terminated and not FStop do
  Begin
    Synchronize(DoCanStartNextStep);
    Sleep(10);
  End;
end;

//--------------------------------------------------------------------------------------------------

constructor TDropper.Create(DoserCnt: Byte);
var
  i: Byte;
begin
  If DoserCnt=0 then
    raise Exception.Create('You must specify the number of dosers');

  FStatus:=dsWaiting;
  FDoserCount:=DoserCnt;

  SetLength(FShutters, DoserCnt);
  SetLength(FAllowance, DoserCnt);
  SetLength(FDropByTime, DoserCnt);
  SetLength(FIsEmpty, DoserCnt);
  SetLength(FDroppable, DoserCnt);
  SetLength(FCanClose, DoserCnt);
  SetLength(FMaxDroppingTime, DoserCnt);
  For i:=0 to FDoserCount-1 do
  Begin
    FShutters[i]:=TDevDXMOpts.Create;
    FAllowance[i]:=0;
    FDropByTime[i]:=False;
    FIsEmpty[i]:=True;
    FDroppable[i]:=False;
    FCanClose[i]:=True;
    FMaxDroppingTime[i]:=0;
  End;
  FMixerEngine:=TDevDXMOpts.Create;
  FWaitForAll:=True;
  FDroppingNum:=0;

  SetLength(FFinished, DoserCnt);

  inherited Create;
end;

destructor TDropper.Destroy;
var
  i: Byte;
begin
  For i:=Low(FShutters) to High(FShutters) do
    FreeAndNil(FShutters[i]);
  FreeAndNil(FMixerEngine);
  inherited Destroy;
end;

procedure TDropper.Start;
begin
  FStatus:=dsStarting;
  inherited Start;
end;

procedure TDropper.Stop;
begin
  inherited Stop;
end;

//--------------------------------------------------------------------------------------------------

procedure TDropper.Execute;
var
  i, OrderNum: Byte;
  DTLTime: Cardinal;
  AllReady: Boolean;
  DoNotFinish: Boolean;

  procedure _CheckNotClosing(NoNum: Byte=255);
  var
    ii: Byte;
    DN: Byte;
  begin
    DN:=FDoserNumber;
    for ii:=Low(FShutters) to High(FShutters) do
    begin
      if ii = NoNum then Continue;
      if not FCanClose[ii] and not FDropByTime[ii] then
      begin
        Sleep(10);
        FDoserNumber:=ii;
        Synchronize(DoGetWeight);
        if (FWeightCur <= FAllowance[FDoserNumber]) and not FFinished[FDoserNumber] then
        begin
          with FShutters[FDoserNumber] do
            if Assigned(DOM) then
            begin
                //Doser closing
              if OutputIsOn then
              begin
                if FDoserNumber <> 0 then //Инертные исключаем. Делаем вид, что выключили
                begin
                  DOM.OutputOff(Output, dcdOutsNeed, ThreadID, cDefPriority);
                  if CheckSend<>0 then Break;
                  FIsEmpty[FDoserNumber]:=True;
                end;
                DoChangeState(False);
              end;
            end;
          FFinished[FDoserNumber]:=True;
        end
        else if not FFinished[FDoserNumber] then
          DoNotFinish:=True;
      end;
    end;
    FDoserNumber:=DN;
  end;

begin
  Sleep(50);  //A little sleep for setting all this thread properties
  FStatus:=dsWaiting; //Default status
  OrderNum:=0;
  DTLTime:=0;

  Suspend;

  WHILE not Terminated DO
  BEGIN

  If FStop then Suspend;
  Sleep(10);

    //Dropping start
  If FStatus in [dsStarting] then
  Begin
    FDoserNumber:=0;
    FAllowMixerOn:=True;
    OrderNum:=0;
    FDroppingNum:=0;
    for i:=Low(FFinished) to High(FFinished) do FFinished[i]:=False;

    if WaitForAll then
    begin
      AllReady:=False;
      while not AllReady do
      begin
        AllReady:=True;
        for i:=0 to FDoserCount-1 do
          AllReady:=AllReady AND ((not FIsEmpty[i] and FDroppable[i]) Or not FDroppable[i]);
        Sleep(10);
      end;
    end;

    with FMixerEngine do
      if Assigned(FDOM) then
      begin
        Synchronize(DoBeforeMixerOn);
        if FStop or Terminated then Continue;

          //Mixer start
        if OutputIsOff and FAllowMixerOn then
        begin
          SetStatus(dsMixerOn);
          DOM.OutputOn(Output, dcdOutsNeed, ThreadID, cDefPriority);
          if CheckSend<>0 then Break;
          DoChangeState(True);
        end;

        WaitForOutputOn;
        WaitForIndicator;
      end;
    SetStatus(dsDroppingPrepare);
  End

    //Dropping preparing
  Else if FStatus in [dsDroppingPrepare] then
  Begin
    for i:=Low(FShutters) to High(FShutters) do
      if FShutters[i].Order = OrderNum then
      begin
        FDoserNumber:=i;
        DTLTime:=0;
        Break;
      end;
    if i = High(FShutters)+1 then
    begin
      SetStatus(dsDroppingFinishing);
      //Suspend;
      Continue;
    end
    else if FDroppable[FDoserNumber] then
    begin
      Inc(FDroppingNum);
      while FIsEmpty[FDoserNumber] do
        Sleep(10);
    end
    else //if FIsEmpty[FDoserNumber] then
    begin
      Inc(OrderNum);
      Continue;
    end;

      //Dropping checking
    FAllowDrop:=False;
    while not FAllowDrop and not Terminated and not FStop do
    begin
      Synchronize(DoAllowDrop);
      Sleep(10);
    end;

    with FShutters[FDoserNumber] do
      if Assigned(DOM) then
      begin
          //Doser opening
        if OutputIsOff then
        begin
          DOM.OutputOn(Output, dcdOutsNeed, ThreadID, cDefPriority);
          if CheckSend<>0 then Break;
          DoChangeState(True);
        end;

        WaitForOutputOn;
        WaitForIndicator;
        //FIsEmpty[FDoserNumber]:=True;

        if FDropByTime[FDoserNumber] then
          DTLTime:=GetTickCount + TimeWork * 1000
        else DTLTime:=GetTickCount + FMaxDroppingTime[FDoserNumber] * 1000;
      end;
    SetStatus(dsDropping);
  End

    //Dropping
  Else if FStatus in [dsDropping] then
  Begin
      //Very long dropping. Works just once
    if (GetTickCount >= DTLTime) and (DTLTime > 0) then
    begin
      DTLTime:=0;
      if not FDropByTime[FDoserNumber] then
        Synchronize(DoLongDropping);
    end;

    _CheckNotClosing(FDoserNumber);

    if not FDropByTime[FDoserNumber] then
      Synchronize(DoGetWeight);

      //Material was dropped
    if ((FWeightCur <= FAllowance[FDoserNumber]) and not FDropByTime[FDoserNumber]) Or
       ((DTLTime=0) and FDropByTime[FDoserNumber]) then
    begin
      SetStatus(dsDroppingFinished);

      if FCanClose[FDoserNumber] then
      begin
        with FShutters[FDoserNumber] do
          if Assigned(DOM) then
          begin
              //Doser closing
            if OutputIsOn then
            begin
              DOM.OutputOff(Output, dcdOutsNeed, ThreadID, cDefPriority);
              if CheckSend<>0 then Break;
              DoChangeState(False);
              FIsEmpty[FDoserNumber]:=True;
            end;
          end;
        FFinished[FDoserNumber]:=True;
      end;

      Inc(OrderNum);  //Next doser

      if OrderNum = FDoserCount then
      begin
        SetStatus(dsDroppingFinishing);
        //Suspend;
        //Continue;
      end
      else
        SetStatus(dsDroppingPrepare);
    end;
  End

    //Dropping finishing
  Else if FStatus in [dsDroppingFinishing] then
  Begin
      //Waiting all dosers for afterclosing
    DoNotFinish:=False;
    _CheckNotClosing;
    if not DoNotFinish then
    begin
      SetStatus(dsDroppingFullDone);
      Suspend;
      Continue;
    end;
  End;

  END;
end;

//==================================================================================================
//_____________________________________________TMixer_______________________________________________
//==================================================================================================

constructor TMixer.Create;
begin
  FStatus:=msWaiting;
  FTimeMix:=0;
  FTimeUnload:=0;
  FIsEmpty:=True;
  FMixingValue:=0;
  FLastMixingValue:=0;
  FSumValue:=0;
  FNotUnload:=False;
  FShutterOpts:=TMixerShutterOpts.Create;
  FPreOpenTimeStart:=0;
  FPreOpenTimeWait:=0;
  inherited Create;
end;

destructor TMixer.Destroy;
begin
  FreeAndNil(FShutterOpts);
end;

//--------------------------------------------------------------------------------------------------

procedure TMixer.DoStatusChanged;
begin
  If Assigned(FOnStatusChanged) then FOnStatusChanged(Self);
end;

function TMixer.ShutterOpen: Boolean;
begin
  Result:=False;
  With FShutterOpts do
    case CheckStateType of
      mcs1o2i:
        if DOMOutOpen.Output[OutOpen]<>OpenedState then
        begin
          DOMOutOpen.OutputOn(OutOpen, dcdOutputs, ThreadID, cDefPriority);
          if CheckSend<>0 then Exit;
        end;
      mcs2o2i:
        begin
          if DOMOutClose.Output[OutClose]=ClosedState then
          begin
            DOMOutClose.OutputOff(OutClose, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
          if DOMOutOpen.Output[OutOpen]<>OpenedState then
          begin
            DOMOutOpen.OutputOn(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
      mcs2o3ih:
        begin
          if DOMOutClose.Output[OutClose]<>ClosedState then //Cancel closing
          begin
            DOMOutClose.OutputOff(OutClose, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
          if DOMOutOpen.Output[OutOpen]=OpenedState then  //Opening
          begin
            DOMOutOpen.OutputOn(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
    end;
  Result:=True;
end;

function TMixer.ShutterClose: Boolean;
begin
  Result:=False;
  With FShutterOpts do
    case CheckStateType of
      mcs1o2i:
        if DOMOutOpen.Output[OutOpen]=OpenedState then
        begin
          DOMOutOpen.OutputOff(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
          if CheckSend<>0 then Exit;
        end;
      mcs2o2i:
        begin
          if DOMOutOpen.Output[OutOpen]=OpenedState then
          begin
            DOMOutOpen.OutputOff(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
          if DOMOutClose.Output[OutClose]<>ClosedState then
          begin
            DOMOutClose.OutputOn(OutClose, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
      mcs2o3ih:
        begin
          if DOMOutOpen.Output[OutOpen]<>OpenedState then  //Cancel opening
          begin
            DOMOutOpen.OutputOff(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
          if DOMOutClose.Output[OutClose]=ClosedState then //Closing
          begin
            DOMOutClose.OutputOn(OutClose, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
    end;
  Result:=True;
end;

function TMixer.ShutterStop: Boolean;
begin
  Result:=False;
  With FShutterOpts do
    case CheckStateType of
      mcs1o2i:  ; //Never stops with one output
      mcs2o2i:
        begin
          if DOMOutOpen.Output[OutOpen]=OpenedState then  //Cancel opening
          begin
            DOMOutOpen.OutputOff(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
      mcs2o3ih:
        begin
          if DOMOutOpen.Output[OutOpen]<>OpenedState then //Cancel opening
          begin
            DOMOutOpen.OutputOff(OutOpen, dcdOutsNeed, ThreadID, cDefPriority);
            if CheckSend<>0 then Exit;
          end;
        end;
    end;
  Result:=True;
end;

//--------------------------------------------------------------------------------------------------

procedure TMixer.Start;
begin
  inherited Start;
end;

procedure TMixer.Stop;
begin
  inherited Stop;
end;

function TMixer.CheckOpened: Boolean;
begin
  Result:=True;
  If (FPreOpenTimeStart > 0) and (FPreOpenTimeWait > 0) then Exit;  //

  WITH FShutterOpts DO
  Case FCheckStateType of
    mcs1o2i:
      if Assigned(DOMOutOpen) and
         Assigned(DIMIndOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          (DOMOutOpen.Output[OutOpen] = OpenedState) and
          (DIMIndOpened.Input[IndOpened] = IndOpenedState) and
          (DIMIndClosed.Input[IndClosed] <> IndClosedState);
    mcs2o2i:
      if Assigned(DOMOutOpen) and
         Assigned(DOMOutClose) and
         Assigned(DIMIndOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          (DOMOutOpen.Output[OutOpen] = OpenedState) and  {}{это состояние, возможно, может быть как True, так и False}
          (DOMOutClose.Output[OutClose] <> ClosedState) and
          (DIMIndOpened.Input[IndOpened] = IndOpenedState) and
          (DIMIndClosed.Input[IndClosed] <> IndClosedState);
    mcs2o3ih: //hydraulic
      if {Assigned(DOMOutOpen) and
         Assigned(DOMOutClose) and}
         Assigned(DIMIndOpened) and
         Assigned(DIMIndHalfOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          {(DOMOutOpen.Output[OutOpen] = OpenedState) and
          (DOMOutClose.Output[OutClose] = ClosedState) and}
          ((DIMIndOpened.Input[IndOpened] = IndOpenedState) or
            (DIMIndHalfOpened.Input[IndHalfOpened] = IndHalfOpenedState)) and
          (DIMIndClosed.Input[IndClosed] <> IndClosedState);
  End;
end;

function TMixer.CheckClosed: Boolean;
begin
  Result:=True;
  WITH FShutterOpts DO
  Case FCheckStateType of
    mcs1o2i:
      if Assigned(DOMOutOpen) and
         Assigned(DIMIndOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          (DOMOutOpen.Output[OutOpen] <> OpenedState) and
          (DIMIndOpened.Input[IndOpened] <> IndOpenedState) and
          (DIMIndClosed.Input[IndClosed] = IndClosedState);
    mcs2o2i:
      if Assigned(DOMOutOpen) and
         Assigned(DOMOutClose) and
         Assigned(DIMIndOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          (DOMOutOpen.Output[OutOpen] <> OpenedState) and
          (DOMOutClose.Output[OutClose] = ClosedState) and
          (DIMIndOpened.Input[IndOpened] <> IndOpenedState) and
          (DIMIndClosed.Input[IndClosed] = IndClosedState);
    mcs2o3ih:
      if {Assigned(DOMOutOpen) and
         Assigned(DOMOutClose) and}
         Assigned(DIMIndOpened) and
         Assigned(DIMIndHalfOpened) and
         Assigned(DIMIndClosed) then
        Result:=
          {(DOMOutOpen.Output[OutOpen] = OpenedState) and
          (DOMOutClose.Output[OutClose] = ClosedState) and}
          (DIMIndOpened.Input[IndOpened] <> IndOpenedState) and
          (DIMIndHalfOpened.Input[IndHalfOpened] <> IndHalfOpenedState) and
          (DIMIndClosed.Input[IndClosed] = IndClosedState);
  End;
end;

//--------------------------------------------------------------------------------------------------

procedure TMixer.Execute;
var
  TimerMix: Cardinal;
  TimerUnload: Cardinal;
  PreTimeStart, PreTimeWait: Int64;
begin
  Sleep(50);  //A little sleep for setting all this thread properties
  FStatus:=msWaiting; //Default status
  TimerMix:=0;
  TimerUnload:=0;
  PreTimeStart:=0;
  PreTimeWait:=0;

  Suspend;

  WHILE not Terminated DO
  BEGIN

  If FStop then Suspend;
  Sleep(10);

    //Mixing
  If FStatus in [msWaiting, msMixing] then
  Begin
      //Start timer
    if TimerMix=0 then
    begin
      TimerMix:=GetTickCount + FTimeMix * 1000;
      FStatus:=msMixing;
      Synchronize(DoStatusChanged);
    end
      //Time is expired and can unload
    else if (TimerMix<GetTickCount) and not NotUnload then
    begin
      TimerMix:=0;

      FStatus:=msBeforeOpening;
      Synchronize(DoStatusChanged);

        //Shutter opening
      if not ShutterOpen then Break;
      if (FPreOpenTimeStart > 0) and (FPreOpenTimeWait > 0) then
        FStatus:=msPreunloading
      else FStatus:=msOpening;
      Synchronize(DoStatusChanged);
        //Write values
      FSumValue:=FSumValue + FMixingValue;
      FLastMixingValue:=FMixingValue;
      FMixingValue:=0;
      PreTimeStart:=0;
      PreTimeWait:=0;
    end;
  End

    //Preunloading
  Else if FStatus = msPreunloading then
  Begin
    if PreTimeStart = 0 then
      PreTimeStart:=GetTickCount + FPreOpenTimeStart;
    if PreTimeStart > GetTickCount then Continue;
    if PreTimeStart <> -1 then
      if not ShutterStop then Break;
    PreTimeStart:=-1;
      //Waiting after preunloading
    if PreTimeWait = 0 then
      PreTimeWait:=GetTickCount + FPreOpenTimeWait;
    if PreTimeWait > GetTickCount then Continue;
    if PreTimeWait <> -1 then
      if not ShutterOpen then Break;
    PreTimeWait:=-1;
    FStatus:=msOpening;
    Synchronize(DoStatusChanged);
  End

    //Unloading
  Else If (FStatus = msUnloading) OR ((FStatus = msOpening) And CheckOpened) then
  Begin
    IsEmpty:=True;

      //Start main timer
    if TimerUnload = 0 then
    begin
      TimerUnload:=GetTickCount + FTimeUnload * 1000;
      FStatus:=msUnloading;
      Synchronize(DoStatusChanged);
    end
      //Time is elapsed
    else if TimerUnload < GetTickCount then
    begin
      TimerUnload:=0;

      FStatus:=msBeforeClosing;
      Synchronize(DoStatusChanged);

        //Shutter closing;
      if not ShutterClose then Break;
      FStatus:=msClosing;
      Synchronize(DoStatusChanged);
    end;
  End

    //Checking shutter is closed
  Else if (FStatus=msClosing) and CheckClosed then
  Begin                                           
    FStatus:=msWaiting;
    Synchronize(DoStatusChanged);
    Suspend;
  End;

  END;
end;

//_____________________________________________Functions____________________________________________
//==================================================================================================

function BytesToSingle(Data: Array of Byte): Single;
var
  ResBytes: Array [0..3] of Byte absolute Result;
begin
  ResBytes[0]:=Data[0];
  ResBytes[1]:=Data[1];
  ResBytes[2]:=Data[2];
  ResBytes[3]:=Data[3];
end;

function BytesToInt32(Data: Array of Byte): Int32;
var
  ResBytes: Array [0..3] of Byte absolute Result;
begin
  If Length(Data) = 2 then
  Begin
    ResBytes[0]:=Data[0];
    ResBytes[1]:=Data[1];
    ResBytes[2]:=0;
    ResBytes[3]:=0;
  End
  Else
  Begin
    ResBytes[0]:=Data[0];
    ResBytes[1]:=Data[1];
    ResBytes[2]:=Data[2];
    ResBytes[3]:=Data[3];
  End;
end;

function SingleToBytes(Value: Single): TBytes;
var
  ResBytes: Array [0..3] of Byte absolute Value;
begin
  SetLength(Result, 4);
  Result[0]:=ResBytes[0]; //good work with 091 and 081
  Result[1]:=ResBytes[1];
  Result[2]:=ResBytes[2];
  Result[3]:=ResBytes[3];
end;

function Int32ToBytes(Value: Int32): TBytes;
var
  ResBytes: Array [0..3] of Byte absolute Value;
begin
  SetLength(Result, 4);
  Result[0]:=ResBytes[0]; //good work with 091 and 081
  Result[1]:=ResBytes[1];
  Result[2]:=ResBytes[2];
  Result[3]:=ResBytes[3];
end;

//==================================================================================================

initialization
  Devs:=TDevLists.Create;
finalization
//  Devs.Free;    Если раскомментировать, то при выходе возникает AV

end.