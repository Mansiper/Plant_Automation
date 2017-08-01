(*
	Это своеобразна¤ фабрика команд, которые формируются для отправки устройствам.
	добавляются в очереди с учётом приоритета, благодаря чему кажется,
	что команды на запись (обычно имеющий высокий приоритет) выполняются мгновенно.
*)

unit Commands;

interface

uses Classes, Generics.Collections;

const
  cDefPriority = 5;   //Default priority

type
    //Device type
  TDevTypeCommand = (dtcDIOM, dtcDIM, dtcDOM, dtcMaster, dtcKB, dtcKGD);
    //DIOM range of data values
  TDIOMVals = -256..256;
    //Master command types
  TMCT = (mctNone, mctRAMRead, mctRAMWrite, mctCommand);
  TKBCT = (kbctNone, kbctRead, kbctWrite, kbctCommand);
    //Types for considering other data of DIOM
  TDOMConsiderData = (dcdNone, dcdOutputs, dcdOutsNeed);

    //Creates and sends a command to the required queue
  TComCommand = class
  public
      //Sends command for DIOM in commands queue
    class procedure ToDIOM(Address: Byte; Value: TDIOMVals; ThreadId: Int64=0; Write: Boolean=True;
      ConsiderOtherData: TDOMConsiderData=dcdOutsNeed; Priority: Byte=cDefPriority);
      //Sends command for DIM in commands queue
    class procedure ToDIM(Address, Reg: Byte; AsCommand: Boolean; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
      //Sends command for DOM in commands queue
    class procedure ToDOM(Address, Reg: Byte; Value: Int64; ThreadId: Int64=0; Write: Boolean=True;
      ConsiderOtherData: TDOMConsiderData=dcdOutsNeed; Priority: Byte=cDefPriority);
      //Sends command for Master in commands queue
    class procedure ToMaster(Address, Value, Reg: Byte; CommandType: TMCT; ThreadId: Int64=0;
      Write: Boolean=True; Priority: Byte=cDefPriority); overload;
    class procedure ToMaster(Address, Command: Byte; ThreadId: Int64=0; Write: Boolean=True;
      Priority: Byte=cDefPriority); overload;
      //Sends command for KB in commands queue
    class procedure ToKB(Address, Comnd: Byte; Reg, RegCnt: Word; CommandType: TKBCT;
      ThreadId: Int64=0; Write: Boolean=False; Priority: Byte=cDefPriority); overload;
    class procedure ToKB(Address, Comnd: Byte; Reg, RegCnt: Word; Data: Array of Byte;
      DataLen: Byte; CommandType: TKBCT=kbctWrite; ThreadId: Int64=0; Write: Boolean=True;
      Priority: Byte=cDefPriority); overload;
      //Sends command for KGD in commands queue
    class procedure ToKGSD(Address: Byte; StrQuery: AnsiString; ThreadId: Int64=0;
      Priority: Byte=cDefPriority);
  end;

    //----------------------------------------------------------------------------------------------

    //Command data for queue
  TCommand = class
  private
    procedure Create;
  protected
      //Creates a command instance
    constructor CreateDIOM(AAddress: Byte; AValue: TDIOMVals; AWrite: Boolean;
      AConsiderOtherData: TDOMConsiderData; AThreadId: Int64; APriority: Byte);
    constructor CreateDIM(AAddress, AReg: Byte; AThreadId: Int64; APriority: Byte);
    constructor CreateDOM(AAddress, AReg: Byte; AValue: Int64; AWrite: Boolean;
      AConsiderOtherData: TDOMConsiderData; AThreadId: Int64; APriority: Byte);
    constructor CreateMaster(AAddress, AValCom, AReg: Byte; ACommandType: TMCT; AThreadId: Int64;
      AWrite: Boolean; APriority: Byte);
    constructor CreateKB(AAddress, AComnd: Byte; AReg, ARegCnt: Word; AData: Array of Byte;
      ADataLen: Byte; ACommandType: TKBCT; AThreadId: Int64; AWrite: Boolean; APriority: Byte);
    constructor CreateKGD(AAddress: Byte; AStrQuery: AnsiString; AThreadId: Int64; APriority: Byte);
  public
      //Info data
    DevType: TDevTypeCommand;   //Device type
      //Main data
    Address: Byte;              //Net address of device (1-256)
    RegDIOM: Byte;              //DIOM/DIM/DOM register
    ValueDIOM: Int64;           //Value for DIOM/DIM/DOM
    ValueMaster: Byte;          //Value for Master
    RegisterMaster: Byte;       //Register address for Master
    CommandTypeMaster: TMCT;    //Master command type
    ThreadId: Int64;            //Thread ID waiting answer from Com-port
    Write: Boolean;             //True - write data, False - read data
    ConsiderOtherData: TDOMConsiderData; //True - consider other outputs of DIOM
    Priority: Byte;             //Priority of command
    CommandKB: Byte;            //KB command
    RegisterKB: Word;           //Starting register address for KB
    RegisterKBCnt: Word;        //Count of registers for KB
    CommandTypeKB: TKBCT;       //KB command type
    Data: Array of Byte;           //Writing data for KB
    DataLen: Byte;              //Writing data length for KB
    StrQuery: AnsiString;       //Query for socket devices
      //Service data
    UseCnt: Byte;               //Count of attempts to send this command
    Time: Cardinal;             //Last time of using
  end;

var     //I suppose it would better to use TQueue, TThreadList or TClassList but there are not enought functions I need
  QueueDXM: TObjectList<TCommand>;      //Queue of commands for getting active DIOM/DIM/DOM data
  QueueWC: TObjectList<TCommand>;       //Queue of commands for getting active Master/KB data
  QueueCommands: TObjectList<TCommand>; //Queue of commands for main work with devices
  ComComm: TComCommand;

implementation

//==================================================================================================
//_________________________________________TComCommand______________________________________________
//==================================================================================================

class procedure TComCommand.ToDIOM(Address: Byte; Value: TDIOMVals; ThreadId: Int64=0;
  Write: Boolean=True; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  Priority: Byte=cDefPriority);
const
  cReadInputs = 0;
  cReadOutputs = 255;
var
  i: Byte;
  Command: TCommand;
begin
    //Creating command
  Command:=TCommand.CreateDIOM(Address, Value, Write, ConsiderOtherData, ThreadId, Priority);

    //Adding to queue
  If Write then
  Begin
    if QueueCommands.Count>0 then
      for i:=1 to QueueCommands.Count-1 do
        if QueueCommands[i].Priority<Priority then
        begin
          QueueCommands.Insert(i, Command);
          Exit;
        end;
    QueueCommands.Add(Command);

      //Next command reads new values
    ToDIOM(Address, cReadInputs, 0, False, dcdNone, Priority);
  End
  Else QueueDXM.Add(Command);
end;

class procedure TComCommand.ToDIM(Address, Reg: Byte; AsCommand: Boolean; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
var
  i: Byte;
  Command: TCommand;
begin                                                                                         
    //Creating command
  Command:=TCommand.CreateDIM(Address, Reg, ThreadId, Priority);

    //Adding to queue
  If AsCommand then
  Begin
    if QueueCommands.Count>0 then
      for i:=1 to QueueCommands.Count-1 do
        if QueueCommands[i].Priority<Priority then
        begin
          QueueCommands.Insert(i, Command);
          Exit;
        end;
    QueueCommands.Add(Command);
  End
  Else QueueDXM.Add(Command);
end;

class procedure TComCommand.ToDOM(Address, Reg: Byte; Value: Int64; ThreadId: Int64=0;
  Write: Boolean=True; ConsiderOtherData: TDOMConsiderData=dcdOutsNeed;
  Priority: Byte=cDefPriority);
var
  i: Byte;
  Command: TCommand;
begin                                                                                         
    //Creating command
  Command:=TCommand.CreateDOM(Address, Reg, Value, Write, ConsiderOtherData, ThreadId, Priority);

    //Adding to queue
  If Write then
  Begin
    if QueueCommands.Count>0 then
      for i:=1 to QueueCommands.Count-1 do
        if QueueCommands[i].Priority<Priority then
        begin
          QueueCommands.Insert(i, Command);
          Exit;
        end;
    QueueCommands.Add(Command);
  End
  Else QueueDXM.Add(Command);
end;

class procedure TComCommand.ToMaster(Address, Value, Reg: Byte; CommandType: TMCT;
  ThreadId: Int64=0; Write: Boolean=True; Priority: Byte=cDefPriority);
var
  i: Byte;
  Command: TCommand;
begin
    //Creating command
  Command:=TCommand.CreateMaster(Address, Value, Reg, CommandType, ThreadId, Write, Priority);

    //Adding to queue
  If Write then
  Begin
    if QueueCommands.Count>0 then
      for i:=1 to QueueCommands.Count-1 do
        if QueueCommands[i].Priority<Priority then
        begin
          QueueCommands.Insert(i, Command);
          Exit;
        end;
    QueueCommands.Add(Command);

      //  !!! Only Master 110.4 !!!
    if CommandType=mctCommand then  //Next command reads new state
      ToMaster(Address, 13(* m1104cState *), 0, False, Priority);
  End
  Else QueueWC.Add(Command);
end;

class procedure TComCommand.ToMaster(Address, Command: Byte; ThreadId: Int64=0; Write: Boolean=True;
  Priority: Byte=cDefPriority);
begin
  ToMaster(Address, Command, 0, mctCommand, ThreadId, Write, Priority);
end;

class procedure TComCommand.ToKB(Address, Comnd: Byte; Reg, RegCnt: Word; CommandType: TKBCT;
  ThreadId: Int64=0; Write: Boolean=False; Priority: Byte=cDefPriority);
begin
  ToKB(Address, Comnd, Reg, RegCnt, [], 0, CommandType, ThreadId, Write, Priority);
end;

class procedure TComCommand.ToKB(Address, Comnd: Byte; Reg, RegCnt: Word; Data: Array of Byte;
  DataLen: Byte; CommandType: TKBCT=kbctWrite; ThreadId: Int64=0; Write: Boolean=True;
  Priority: Byte=cDefPriority);
var
  i: Byte;
  Command: TCommand;
begin
    //Creating command
  Command:=TCommand.CreateKB(Address, Comnd, Reg, RegCnt, Data, DataLen, CommandType,
    ThreadId, Write, Priority);

    //Adding to queue
  If Write then
  Begin
    if QueueCommands.Count>0 then
      for i:=1 to QueueCommands.Count-1 do
        if QueueCommands[i].Priority<Priority then
        begin
          QueueCommands.Insert(i, Command);
          Exit;
        end;
    QueueCommands.Add(Command);

    if CommandType=kbctCommand then //Next command reads new state
      ToKB(Address, 3, 3, 1, kbctRead, ThreadId, Write, Priority);
  End
  Else QueueWC.Add(Command);
end;

class procedure TComCommand.ToKGSD(Address: Byte; StrQuery: AnsiString; ThreadId: Int64=0;
  Priority: Byte=cDefPriority);
var
  i: Byte;
  Command: TCommand;
begin
    //Creating command
  Command:=TCommand.CreateKGD(Address, StrQuery, ThreadId, Priority);

    //Always add into command queue
  If QueueCommands.Count>0 then
    for i:=1 to QueueCommands.Count-1 do
      if QueueCommands[i].Priority<Priority then
      begin
        QueueCommands.Insert(i, Command);
        Exit;
      end;
  QueueCommands.Add(Command);
end;

//==================================================================================================
//___________________________________________TCommand_______________________________________________
//==================================================================================================

procedure TCommand.Create;
begin
  Address:=0;
  RegDIOM:=0;
  ValueDIOM:=0;
  ValueMaster:=0;
  RegisterMaster:=0;
  CommandTypeMaster:=mctNone;
  ThreadId:=0;
  Write:=False;
  ConsiderOtherData:=dcdNone;
  Priority:=cDefPriority;
  CommandKB:=0;
  RegisterKB:=0;
  RegisterKBCnt:=0;
  CommandTypeKB:=kbctNone;
  DataLen:=0;
  StrQuery:='';

  UseCnt:=0;
  Time:=0;
end;

//--------------------------------------------------------------------------------------------------

constructor TCommand.CreateDIOM(AAddress: Byte; AValue: TDIOMVals; AWrite: Boolean;
  AConsiderOtherData: TDOMConsiderData; AThreadId: Int64; APriority: Byte);
begin
  Create;
  DevType:=dtcDIOM;
  Address:=AAddress;
  ValueDIOM:=AValue;
  ThreadId:=AThreadId;
  Write:=AWrite;
  ConsiderOtherData:=AConsiderOtherData;
  Priority:=APriority;
end;

constructor TCommand.CreateDIM(AAddress, AReg: Byte; AThreadId: Int64; APriority: Byte);
begin
  Create;
  DevType:=dtcDIM;
  Address:=AAddress;
  RegDIOM:=AReg;
  ThreadId:=AThreadId;
  Priority:=APriority;
end;

constructor TCommand.CreateDOM(AAddress, AReg: Byte; AValue: Int64; AWrite: Boolean;
  AConsiderOtherData: TDOMConsiderData; AThreadId: Int64; APriority: Byte);
begin
  Create;
  DevType:=dtcDOM;
  Address:=AAddress;
  RegDIOM:=AReg;
  ValueDIOM:=AValue;
  ThreadId:=AThreadId;
  Write:=AWrite;
  ConsiderOtherData:=AConsiderOtherData;
  Priority:=APriority;
end;

constructor TCommand.CreateMaster(AAddress, AValCom, AReg: Byte; ACommandType: TMCT;
  AThreadId: Int64; AWrite: Boolean; APriority: Byte);
begin
  Create;
  DevType:=dtcMaster;
  Address:=AAddress;
  ValueMaster:=AValCom;
  RegisterMaster:=AReg;
  CommandTypeMaster:=ACommandType;
  ThreadId:=AThreadId;
  Write:=AWrite;
  Priority:=APriority;
end;

constructor TCommand.CreateKB(AAddress, AComnd: Byte; AReg, ARegCnt: Word; AData: Array of Byte;
  ADataLen: Byte; ACommandType: TKBCT; AThreadId: Int64; AWrite: Boolean; APriority: Byte);
var
  i: Integer;
begin
  Create;
  DevType:=dtcKB;
  Address:=AAddress;
  ThreadId:=AThreadId;
  Write:=AWrite;
  Priority:=APriority;
  CommandKB:=AComnd;
  RegisterKB:=AReg;
  RegisterKBCnt:=ARegCnt;
  CommandTypeKB:=ACommandType;
  DataLen:=ADataLen;
    SetLength(Data, DataLen);
  For i:=Low(AData) to High(AData) do Data[i]:=AData[i];
end;

constructor TCommand.CreateKGD(AAddress: Byte; AStrQuery: AnsiString; AThreadId: Int64;
  APriority: Byte);
begin
  Create;
  DevType:=dtcKGD;
  Address:=AAddress;
  StrQuery:=AStrQuery;
  ThreadId:=AThreadId;
  Priority:=APriority;
end;

//==================================================================================================

initialization
  ComComm:=TComCommand.Create;
  QueueDXM:=TObjectList<TCommand>.Create;
    QueueDXM.OwnsObjects:=True;
  QueueWC:=TObjectList<TCommand>.Create;
    QueueWC.OwnsObjects:=True;
  QueueCommands:=TObjectList<TCommand>.Create;
    QueueCommands.OwnsObjects:=True;
finalization
  ComComm.Free;
  QueueDXM.Free;
  QueueWC.Free;
  QueueCommands.Free;

end.
