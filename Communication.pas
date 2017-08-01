(*
	Вытаскивает из очередей команды, выполняет их, получает результаты.
	Организовывает псевдомногопоточность.
	Чем больше устройств или чем больше приходится читать из них,
	тем заметней тормоза в реакции на изменения состояний устройств.
	Стоит переделать под возможность использования нескольких портов.
*)

unit Communication;
(*
  WC - weight controller
  DXM - DIOM, DIM, DOM
*)

interface

uses Commands, Classes, Windows, SysUtils;

const
  Emulate = True;

type
  TMQT = (mqtControlCommand, mqtInfoCommand, mqtRAMRead, mqtRAMWrite);
  TKBQT = (kbqtRead, kbqtWrite, kbqtCommand);
  TClassMethod = procedure of Object;
  TDXMResult = procedure(Address: Byte; OResult: Boolean; Value: Byte; InData: Boolean) of Object;
  TWCResult = procedure(Address: Byte; OResult: Boolean; Value: Byte) of Object;

  TCommunication = class(TThread)
  private
    const
      cSendCount = 2;
    var
      FWaitingTime: Cardinal;   //Waiting time for reading from Com-port
      FLastResult: Boolean;     //Last result of sending data to Com-port
      FOnAddDXMCommands: TClassMethod;  //Event on adding DXM command
      FOnAddWCCommands: TClassMethod;   //Event on adding WC command
      FOnDXMWrite: TDXMResult;          //Event on DXM write done
      FOnDXMRead: TDXMResult;           //Event on DXM read done
      FOnWCCommand: TWCResult;          //Event on WC command done
      FOnWCRead: TWCResult;             //Event on WC read RAM done
      FOnWCWrite: TWCResult;            //Event on WC write RAM done

      //Adding commands
    procedure AddDXMCommands; //Adds commands to queue of commands for getting active DXM data
    procedure AddWCCommands;  //Adds commands to queue of commands for getting active WC data
      //Processing CRCs
    function CalcCRC16_DXM(pBuf: PByteArray; Len: Integer): Word;   //For DXM
    function CalcCRC_KB(pBuf: PByteArray; Len: Byte): Word;         //For KB
      //Checking answers
    function CheckDXMAnswer(pIn, pOut: PByteArray; Write: Boolean; InSize: Byte): Byte; //For DIOM
    function CheckKBAnswer(Address: Byte; pIn, pOut: PByteArray; InSize: Byte;
      QueryType: TKBQT): Byte;
    function CheckKGDAnswer(Request, Response: AnsiString): Boolean;                          //For KGD

      //Data processing
    procedure RefreshDIOMInData(Address, HiValue, LoValue: Byte);       //For DIOM
    procedure RefreshDIOMOutData(Address, Value: Byte);
    procedure RefreshDIOMOutNeedData(Address, Value: Byte);
    procedure RefreshDIOMCntData(Address, CntNum, HiValue, LoValue: Byte);
    procedure RefreshDIMData(Address, Reg, HiValue, LoValue: Byte);     //For DIM
    procedure RefreshDOMOutData(Address, Reg: Byte; Value: Int64);      //For DOM
    procedure RefreshDOMOutNeedData(Address, Reg: Byte; Value: Int64);

      //Send command
    function Send(Cnt: Byte; OutSize, InSize: Byte; QuickCheck: TFunc<Boolean>): Boolean; overload;
    function Send(Cnt: Byte; Response: AnsiString; QuickCheck: TFunc<Boolean>): Boolean; overload;
      //Write request/response log
    procedure WriteSendLog(Dev: String);

      //Sending commands
    function SendDIOMCommand(Address: Byte; Value: TDIOMVals; Write: Boolean;
      ThrId: Int64=0): Boolean;
    function SendDIMCommand(Address, Reg: Byte; ThrId: Int64=0): Boolean;
    function SendDOMCommand(Address, Reg: Byte; Value: Int64; Write: Boolean;
      ThrId: Int64=0): Boolean;
    function SendKBCommand(Address, Funct, DataLen: Byte; Reg, RegCnt: Word; Data: Array of Byte;
      CommandType: TKBCT; ThrId: Int64=0): Boolean;
    function SendKGDCommand(Address: Byte; Request: AnsiString; ThrId: Int64=0): Boolean;
  protected
    procedure Execute; override;
  public
      //Don't make private. ComEmulation use's it
    OutData: Array [0..12] of Byte;   //Writing data
    InData: Array [0..8] of Byte;     //Reading data

    property LastResult: Boolean read FLastResult;
    property OnAddDXMCommands: TClassMethod read FOnAddDXMCommands write FOnAddDXMCommands;
    property OnAddWCCommands: TClassMethod read FOnAddWCCommands write FOnAddWCCommands;
    property OnDXMWrite: TDXMResult read FOnDXMWrite write FOnDXMWrite;
    property OnDXMRead: TDXMResult read FOnDXMRead write FOnDXMRead;
    property OnWCCommand: TWCResult read FOnWCCommand write FOnWCCommand;
    property OnWCRead: TWCResult read FOnWCRead write FOnWCRead;
    property OnWCWrite: TWCResult read FOnWCWrite write FOnWCWrite;

    function HasCommands: Boolean;
  end;

var
  Commun: TCommunication;

implementation

uses Devices, Com_port, Socket_port, ComEmulation, RazFuncs, RazLogs{, RazIniFuncs};

//==================================================================================================
//_________________________________________TCommunication___________________________________________
//==================================================================================================

procedure TCommunication.AddDXMCommands;
var
  i: Byte;
begin
  If Assigned(FOnAddDXMCommands) then
    FOnAddDXMCommands
  Else
  Begin
    if QueueDXM.Count < (Devs.DIOMCount + Devs.DIMCount + Devs.DIMCount) * 2 then
    begin
      if Devs.DIOMCount > 0 then
        for i:=0 to Devs.DIOMCount-1 do   Devs.DIOM[i].ReadInputs;
      if Devs.DIOMCount > 0 then
        for i:=0 to Devs.DIOMCount-1 do   Devs.DIOM[i].ReadOutputs;
      if Devs.DIMCount > 0 then
        for i:=0 to Devs.DIMCount-1 do    Devs.DIM[i].ReadInputs;
      if Devs.DOMCount > 0 then
        for i:=0 to Devs.DOMCount-1 do    Devs.DOM[i].ReadOutputs;
        //Writing confirmation of outputs
      {for i:=0 to Devs.DIOMCount-1 do
        if Devs.DIOM[i].IsInWork then
          ComComm.ToDIOM(Devs.DIOM[i].Address, 255, 0, True, dcdOutsNeed);}
    end;
  End;
end;

procedure TCommunication.AddWCCommands;
var
  i: Byte;
begin
  If Assigned(FOnAddWCCommands) then
    FOnAddWCCommands
  Else
  Begin
    if QueueWC.Count < (Devs.KBCount) * 2 then
    begin
      if Devs.KBCount > 0 then
        for i:=0 to Devs.KBCount-1 do       Devs.KB[i].ReadState;
      if Devs.KBCount > 0 then
        for i:=0 to Devs.KBCount-1 do       Devs.KB[i].ReadWeight;
    end;
  End;
end;

//-------------------------------

function TCommunication.CalcCRC16_DXM(pBuf: PByteArray; Len: Integer): Word;
const
  CRCHi: Array [0..255] Of Byte = (
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $01, $C0, $80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
  $00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40);

  CRCLo: Array [0..255] Of Byte = (
  $00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06, $07, $C7, $05, $C5, $C4, $04,
  $CC, $0C, $0D, $CD, $0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09, $08, $C8,
  $D8, $18, $19, $D9, $1B, $DB, $DA, $1A, $1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC,
  $14, $D4, $D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3, $11, $D1, $D0, $10,
  $F0, $30, $31, $F1, $33, $F3, $F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
  $3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A, $3B, $FB, $39, $F9, $F8, $38,
  $28, $E8, $E9, $29, $EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED, $EC, $2C,
  $E4, $24, $25, $E5, $27, $E7, $E6, $26, $22, $E2, $E3, $23, $E1, $21, $20, $E0,
  $A0, $60, $61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67, $A5, $65, $64, $A4,
  $6C, $AC, $AD, $6D, $AF, $6F, $6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
  $78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E, $7F, $BF, $7D, $BD, $BC, $7C,
  $B4, $74, $75, $B5, $77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71, $70, $B0,
  $50, $90, $91, $51, $93, $53, $52, $92, $96, $56, $57, $97, $55, $95, $94, $54,
  $9C, $5C, $5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B, $99, $59, $58, $98,
  $88, $48, $49, $89, $4B, $8B, $8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
  $44, $84, $85, $45, $87, $47, $46, $86, $82, $42, $43, $83, $41, $81, $80, $40);
var
  i: Integer;
  ind, Cyc_Hi, Cyc_Lo: Byte;
  CRC: Word;
begin
  Cyc_Hi:=$FF; Cyc_Lo:=$FF;
  For i:=0 to Len-1  do
  Begin
    ind:=Cyc_Lo xor pBuf^[i];
    Cyc_Lo:=Cyc_Hi xor CRCHi[ind];
    Cyc_Hi:=CRCLo[ind];
  End;
  WordRec(CRC).Lo:=Cyc_Lo;
  WordRec(CRC).Hi:=Cyc_Hi;
  Result:=CRC;
end;

function TCommunication.CalcCRC_KB(pBuf: PByteArray; Len: Byte): Word;
var
  i: Integer;

  function _CalcCRC(crc_f: Word; b: Byte): Word;
  var
    ii: Integer;
    x, y: Word;
    ff: Boolean;
  begin
    y:=b;
    x:=crc_f;
    x:=x xor y;

    For ii:=1 to 8 do
    Begin
      ff:=(x and $0001) = 1;
      x:=x shr 1;
      x:=x and $7FFF;
      if ff then
        x:=x xor $A001;
    End;
    Result:=x;
  end;

begin
  Result:=$FFFF;
  For i:=0 to Len-1 do
    Result:=_CalcCRC(Result, pBuf^[i]);
end;

//-------------------------------

function TCommunication.CheckDXMAnswer(pIn, pOut: PByteArray; Write: Boolean; InSize: Byte): Byte;
begin
  Result:=0;
  If Write then
  Begin
    if (pOut^[0] <> pIn^[0]) or
       (pOut^[1] <> pIn^[1]) or
       (pOut^[2] <> pIn^[2]) or
       (pOut^[3] <> pIn^[3]) or
       (pOut^[4] <> pIn^[4]) or
       (pOut^[5] <> pIn^[5]) then
      Result:=1;
  End

  Else //Read
  Begin
    if (pOut^[0] <> pIn^[0]) or
       (pOut^[1] <> pIn^[1]) or
       (pIn^[2] <> 2) then
      Result:=1;
  End;

  {$IF Emulate=False}
  If Result = 0 then
    if (pIn^[InSize-2] <> Lo(CalcCRC16_DXM(pIn, InSize-2))) or  //Проверка контрольной суммы
    (pIn^[InSize-1] <> Hi(CalcCRC16_DXM(pIn, InSize-2))) then
      Result:=2;
  {$IFEND}
end;

function TCommunication.CheckKBAnswer(Address: Byte; pIn, pOut: PByteArray; InSize: Byte;
  QueryType: TKBQT): Byte;
var
  KB: TKB;
begin
  Result:=1;
  KB:=Devs.KBAds[Address];

  If QueryType=kbqtRead then
  Begin
    if (pOut^[0] = pIn^[0]) and
    ((pOut^[1] = pIn^[1]) or (pOut^[1] = pIn^[1]-128)) then
      Result:=0;
  End
  Else if QueryType=kbqtWrite then
  Begin
    if (pOut^[0] = pIn^[0]) and
    ((pOut^[1] = pIn^[1]) or (pOut^[1] = pIn^[1]-128)) then
      Result:=0;
  End
  Else if QueryType=kbqtCommand then
  Begin
    if (pOut^[0] = pIn^[0]) and
    ((pOut^[1] = pIn^[1]) or (pOut^[1] = pIn^[1]-128)) then
      Result:=0;
  End;
  KB.Error:= (pOut^[1] = pIn^[1]-128);

  {$IF Emulate=False}
  If Result = 0 then
    if (pIn^[InSize-2] <> Lo(CalcCRC_KB(pIn, InSize-2))) or   //Проверка контрольной суммы
    (pIn^[InSize-1] <> Hi(CalcCRC_KB(pIn, InSize-2))) then
      Result:=2;
  {$IFEND}
end;

function TCommunication.CheckKGDAnswer(Request, Response: AnsiString): Boolean;
begin
  Result := (Copy(Request, 1, 5) = Copy(Response, 1, 5)) and (Response <> ''); //For example, kgd01
end;

//-------------------------------

procedure TCommunication.RefreshDIOMInData(Address, HiValue, LoValue: Byte);
var
  DIOM: TDIOM;
  i, n: Byte;
begin
  DIOM:=Devs.DIOMAds[Address];

  i:=8;
  While i>0 do
  Begin
    n:=Round(Pow(2, i-1));
    if LoValue>=n then
    begin
      Dec(LoValue, n);
      DIOM.Input[i-1]:=True;
    end
    else DIOM.Input[i-1]:=False;
    Dec(i);
  End;

  i:=4;
  While i>0 do
  Begin
    n:=Round(Pow(2, i-1));
    if HiValue>=n then
    begin
      Dec(HiValue, n);
      DIOM.Input[i+7]:=True;
    end
    else DIOM.Input[i+7]:=False;
    Dec(i);
  End;
end;

procedure TCommunication.RefreshDIOMOutData(Address, Value: Byte);
var
  DIOM: TDIOM;
  i, n: Byte;
begin
  DIOM:=Devs.DIOMAds[Address];

  i:=8;
  While i>0 do
  Begin
    n:=Round(Pow(2, i-1));
    if Value>=n then
    begin
      Dec(Value, n);
      DIOM.Output[i-1]:=True;
    end
    else DIOM.Output[i-1]:=False;
    Dec(i);
  End;
end;

procedure TCommunication.RefreshDIOMOutNeedData(Address, Value: Byte);
var
  DIOM: TDIOM;
  i, n: Byte;
begin
  DIOM:=Devs.DIOMAds[Address];

  i:=8;
  While i>0 do
  Begin
    n:=Round(Pow(2, i-1));
    if Value>=n then
    begin
      Dec(Value, n);
      DIOM.OutNeed[i-1]:=True;
    end
    else DIOM.OutNeed[i-1]:=False;
    Dec(i);
  End;
end;

procedure TCommunication.RefreshDIOMCntData(Address, CntNum, HiValue, LoValue: Byte);
begin
  If HiValue * 256 + LoValue = 0 then Exit;
  Devs.DIOMAds[Address].Counter[CntNum-1]:=HiValue * 256  +LoValue;
end;

procedure TCommunication.RefreshDIMData(Address, Reg, HiValue, LoValue: Byte);
var
  DIM: TDIM;
  i, n, stop, shift: Word;
  Val: Word;
begin
  DIM := Devs.DIMAds[Address];
  If Reg = $33 then
  Begin
    i := DIM.InputCount - 1;
    stop := Word(-1);
    shift := 0;
  End
  Else if Reg = $63 then
  Begin
    i := DIM.InputCount - 1;
    stop := 15;
    shift := 16;
  End
  Else if Reg = $64 then
  Begin
    i := 15;
    stop := Word(-1);
    shift := 0;
  End
  Else Exit;
  Val := (HiValue shl 8) + LoValue;

  While i <= DIM.InputCount do
  Begin
    n := Round(Pow(2, i - shift));
    if Val >= n then
    begin
      Dec(Val, n);
      DIM.Input[i] := True;
    end
    else DIM.Input[i] := False;
    Dec(i);
    if i = stop then Break;
  End;
end;

procedure TCommunication.RefreshDOMOutData(Address, Reg: Byte; Value: Int64);
var
  DOM: TDOM;
  i, n, stop, shift: Word;
begin
  DOM:=Devs.DOMAds[Address];
  If Reg = $61 then
  Begin
    i := DOM.OutputCount - 1;
    stop := 15;
    shift := 16;
  End
  Else if Reg = $62 then
  Begin
    i := 15;
    stop := Word(-1);
    shift := 0;
  End
  Else Exit;

  While i <= DOM.OutputCount do
  Begin
    n := Round(Pow(2, i - shift));
    if Value >= n then
    begin
      Dec(Value, n);
      DOM.Output[i] := True;
    end
    else DOM.Output[i] := False;
    Dec(i);
    if i = stop then Break;
  End;
end;

procedure TCommunication.RefreshDOMOutNeedData(Address, Reg: Byte; Value: Int64);
var
  DOM: TDOM;
  i, n, stop, shift: Word;
begin
  DOM:=Devs.DOMAds[Address];
  If Reg = $61 then
  Begin
    i := DOM.OutNeedCount - 1;
    stop := 15;
    shift := 16;
  End
  Else if Reg = $62 then
  Begin
    i := 15;
    stop := Word(-1);
    shift := 0;
  End
  Else Exit;

  While i <= DOM.OutNeedCount do
  Begin
    n := Round(Pow(2, i - shift));
    if Value >= n then
    begin
      Dec(Value, n);
      DOM.OutNeed[i] := True;
    end
    else DOM.OutNeed[i] := False;
    Dec(i);
    if i = stop then Break;
  End;
end;

function TCommunication.Send(Cnt: Byte; OutSize, InSize: Byte; QuickCheck: TFunc<Boolean>): Boolean;
var
  i: Byte;
  {$IF Emulate=True}
  EmulData: String;
  {$IFEND}
begin
  Result:=False;
  While (Cnt > 0) and not Terminated do
  Begin
    for i := Low(InData) to High(InData) do InData[i] := 0;

      {$IF Emulate=True}
    for i := Low(OutData) to OutSize-1 do
      EmulData := EmulData + IntToStr(OutData[i]) + ' ';
    Delete(EmulData, Length(EmulData), 1);

    Emulator.Send(EmulData, FWaitingTime);
      {$ELSE}
    ComPort.Write(OutData, OutSize, @InData, InSize);
    ComPort.Wait(FWaitingTime);
      {$IFEND}

    Result := QuickCheck;
    if Result then Break;  //Pre-check
    Dec(Cnt);
    Sleep(10);
  End;
end;

function TCommunication.Send(Cnt: Byte; Response: AnsiString; QuickCheck: TFunc<Boolean>): Boolean;
begin
  Result := False;
  While (Cnt > 0) and not Terminated do
  Begin
      {$IF Emulate=True}
    Emulator.Send(Response, FWaitingTime);
      {$ELSE}
    SocketPort.Send(Response, FWaitingTime);
      {$IFEND}

    Result := QuickCheck;
    if Result then Break;  //Pre-check
    Dec(Cnt);
    Sleep(10);
  End;
end;

procedure TCommunication.WriteSendLog(Dev: String);
var
  i: Byte;
  Str: String;
begin
  Str:='';
  For i:=Low(OutData) to High(OutData) do Str:=Str+IntToStr(OutData[i])+' ';
  WriteLog('Out'+Dev+': '+Str, rtTest);
  Str:='';
  For i:=Low(InData) to High(InData) do Str:=Str+IntToStr(InData[i])+' ';
  WriteLog('In'+Dev+': '+Str, rtTest);
end;

//-------------------------------

function TCommunication.SendDIOMCommand(Address: Byte; Value: TDIOMVals; Write: Boolean;
  ThrId: Int64=0): Boolean;
var
  Reg: Byte;
  Res: Byte;
//  OldOuts: Byte;
begin
  Result:=False;
  Reg:=0;
  If Write then             //Writing data
  Begin
    Reg:=$32;
    if Value=255 then       //Just confirm data
      Value:=0;
  End
  Else if not Write then    //Reading data
  Begin
    if Value=0 then         //Read inputs
      Reg:=$33
    else if Value=255 then  //Read outputs
    begin
      Reg:=$32;
      Value:=0;
    end
    else if Value in [1..12] then
      Reg:=$40 + Value - 1;
  End;
  If Reg=0 then
  Begin
    Result:=True;
    Exit;
  End;

  OutData[0]:=Address;
  OutData[2]:=0;
  OutData[3]:=Reg;
  OutData[4]:=0;
  OutData[5]:=1;

  If Write then
  Begin
    OutData[1]:=16;  //Command for write
    OutData[6]:=0;
    OutData[7]:=0;
    OutData[8]:=Value;
    OutData[9]:=Lo(CalcCRC16_DXM(@OutData, 9));
    OutData[10]:=Hi(CalcCRC16_DXM(@OutData, 9));

    Send(cSendCount, 11, 8,
      function(): Boolean
      begin
        Result:=(InData[0]=OutData[0]) and (InData[3]=OutData[3]);
      end);
      if Terminated then Exit;

    Res:=CheckDXMAnswer(@InData, @OutData, Write, 8);
    Result:=Res<>1;
    FLastResult:=Result;
    if Res<>0 then  //Error
      WriteSendLog('DIOM')
    else    //No errors
    begin
        //Message for waiting thread
      if ThrId<>0 then
        PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

        //Writing new out-needed data
      RefreshDIOMOutNeedData(Address, OutData[8]);
    end;
  End   //Write data
  Else  //Read data
  Begin
    OutData[1]:=4;   //Command for read
    OutData[2]:=0;
    OutData[6]:=Lo(CalcCRC16_DXM(@OutData, 6));
    OutData[7]:=Hi(CalcCRC16_DXM(@OutData, 6));

    Send(cSendCount, 8, 8,
      function(): Boolean
      begin
        Result:=(InData[0]=OutData[0]) and (InData[1]=OutData[1]);
      end);
      if Terminated then Exit;

    Res:=CheckDXMAnswer(@InData, @OutData, Write, 7);
    Result:=Res<>1;
    FLastResult:=Result;
    if Res<>0 then  //Error
      WriteSendLog('DIOM')
    else    //No errors
    begin
        //Message for waiting thread
      if ThrId<>0 then
        PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

        //Reading new in-data
      if Reg=$33 then
        RefreshDIOMInData(Address, InData[3], InData[4])

        //Reading new out-data
      else if Reg=$32 then
      begin
//        OldOuts:=Devs.DIOMAds[Address].GetOuts;
        RefreshDIOMOutData(Address, InData[4]);

          //Если считанные не соответствуют необходимым, подтверждаю необходимые
        {if InData[4]<>Devs.DIOMAds[Address].GetNeedOuts then
        begin
          Devs.DIOMAds[Address].Write(0, dcdOutsNeed, 0, 15);
          WriteLog('Read '+IntToStr(Address)+' I: '+IntToStr(InData[4])+
            '. X: '+IntToStr(OldOuts)+
            '. Y: '+IntToStr(Devs.DIOMAds[Address].GetNeedOuts),
            rtError);
          WriteSendLog('DIOM');
        end;}
      end
      else if Reg in [$40..$4B] then
        RefreshDIOMCntData(Address, Value, InData[3], InData[4]);
    end;
  End;  //Read data

    //Device connection state
  Devs.DIOMAds[Address].Connected:=Res<>1;
  Result:=Res=0;

  If Write and Assigned(FOnDXMWrite) then
    FOnDXMWrite(Address, Result, Value, False)
  Else if not Write and Assigned(FOnDXMRead) then
    FOnDXMRead(Address, Result, Value, Reg=$33);
end;

function TCommunication.SendDIMCommand(Address, Reg: Byte; ThrId: Int64=0): Boolean;
var
  Res: Byte;
begin
  Result:=False;

  OutData[0]:=Address;
  OutData[1]:=4;   //Command for read
  OutData[2]:=0;
  OutData[3]:=Reg;
  OutData[4]:=0;
  OutData[5]:=1;
  OutData[6]:=Lo(CalcCRC16_DXM(@OutData, 6));
  OutData[7]:=Hi(CalcCRC16_DXM(@OutData, 6));

  Send(5, 8, 8,
    function(): Boolean
    begin
      Result:=(InData[0]=OutData[0]) and (InData[1]=OutData[1]);
    end);
    If Terminated then Exit;

  Res:=CheckDXMAnswer(@InData, @OutData, False, 7);
  Result:=Res<>1;
  FLastResult:=Result;
  If Res<>0 then  //Error
    WriteSendLog('DIM')
  Else    //No errors
  Begin
      //Message for waiting thread
    if ThrId<>0 then
      PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

      //Reading new data
    if Reg in [$33, $63, $64] then
      RefreshDIMData(Address, Reg, InData[3], InData[4])
  End;

    //Device connection state
  Devs.DIMAds[Address].Connected:=Res<>1;
  Result:=Res=0;

  If Assigned(FOnDXMRead) then
    FOnDXMRead(Address, Result, 0, True);
end;

function TCommunication.SendDOMCommand(Address, Reg: Byte; Value: Int64; Write: Boolean;
  ThrId: Int64=0): Boolean;
var
  Res: Byte;
begin
  Result:=False;

  OutData[0]:=Address;  //Адрес
  OutData[2]:=0;        //Регистр
  OutData[3]:=Reg;      //Регистр
  OutData[4]:=0;
  OutData[5]:=1;

  If Write then
  Begin
    OutData[1]:=16;  //Command for write
    OutData[6]:=0;
    OutData[7]:=Hi(Value);  //{!} Поменял местами
    OutData[8]:=Lo(Value);
    OutData[9]:=Lo(CalcCRC16_DXM(@OutData, 9));
    OutData[10]:=Hi(CalcCRC16_DXM(@OutData, 9));

    Send(5, 11, 8,
      function(): Boolean
      begin
        Result:=(InData[0]=OutData[0]) and (InData[3]=OutData[3]);
      end);
      if Terminated then Exit;

    Res:=CheckDXMAnswer(@InData, @OutData, Write, 8);
    Result:=Res<>1;
    FLastResult:=Result;
    if Res<>0 then  //Error
      WriteSendLog('DOM')
    else    //No errors
    begin
        //Message for waiting thread
      if ThrId<>0 then
        PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

        //Writing new out-needed data
      RefreshDOMOutNeedData(Address, Reg, Value);
    end;
  End   //Write data
  Else  //Read data
  Begin
    OutData[1]:=4;   //Command for read
    OutData[2]:=0;
    OutData[6]:=Lo(CalcCRC16_DXM(@OutData, 6));
    OutData[7]:=Hi(CalcCRC16_DXM(@OutData, 6));

    Send(5, 8, 8,
      function(): Boolean
      begin
        Result:=(InData[0]=OutData[0]) and (InData[1]=OutData[1]);
      end);
      if Terminated then Exit;

    Res:=CheckDXMAnswer(@InData, @OutData, Write, 7);
    Result:=Res<>1;
    FLastResult:=Result;
    if Res<>0 then  //Error
      WriteSendLog('DOM')
    else    //No errors
    begin
        //Message for waiting thread
      if ThrId<>0 then
        PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

        //Reading new out-data
      RefreshDOMOutData(Address, Reg, InData[3] * 256 + InData[4]);
    end;
  End;  //Read data

    //Device connection state
  Devs.DOMAds[Address].Connected:=Res<>1;
  Result:=Res=0;

  If Write and Assigned(FOnDXMWrite) then
    FOnDXMWrite(Address, Result, Value, False)
  Else if not Write and Assigned(FOnDXMRead) then
    FOnDXMRead(Address, Result, Reg, False);
end;

function TCommunication.SendKBCommand(Address, Funct, DataLen: Byte; Reg, RegCnt: Word;
  Data: Array of Byte; CommandType: TKBCT; ThrId: Int64=0): Boolean;
var
  i, j, l, li: Byte;
  Cntrlr: TKB;
  CRC: Word;
  kbqt: TKBQT;
  RegData: Word;
  Weight: Single;
  Res: Byte;

  procedure _BeforeExit(Res: Boolean);
  begin
      //Device connection state
    Cntrlr.Connected:=Res;

    Case CommandType of
      kbctRead:
        if Assigned(FOnWCRead) then     FOnWCRead(Address, Res, Reg);
      kbctWrite:
        if Assigned(FOnWCWrite) then    FOnWCWrite(Address, Res, Reg);
      kbctCommand:
        if Assigned(FOnWCCommand) then  FOnWCCommand(Address, Res, Funct);
    End;
  end;

begin
  Result:=False;

  Cntrlr:=Devs.KBAds[Address];
  li:=0;

  Case CommandType of
    kbctRead:     kbqt := kbqtRead;
    kbctWrite:    kbqt := kbqtWrite;
  else
    //kbctCommand
    kbqt := kbqtCommand;
  End;
  If Reg>100 then
    RegData:=Reg-100
  Else RegData:=Reg;

  OutData[0]:=Address;
  If CommandType=kbctRead then
  Begin
    OutData[1]:=Funct;
    OutData[2]:=Hi(RegData);
    OutData[3]:=Lo(RegData);
    OutData[4]:=Hi(RegCnt);
    OutData[5]:=Lo(RegCnt);
    l:=6;
  End
  Else if CommandType=kbctWrite then
  Begin
    OutData[1]:=Funct;
    OutData[2]:=Hi(RegData);
    OutData[3]:=Lo(RegData);
    OutData[4]:=Hi(RegCnt);
    OutData[5]:=Lo(RegCnt);
    OutData[6]:=DataLen;
    j:=0;
    for i:=7 to 7+DataLen-1 do
    begin
      OutData[i]:=Data[j];
      Inc(j);
    end;
    l:=7 + DataLen;
  End
  Else //if CommandType=kbctCommand then
  Begin
    OutData[1]:=6;
    OutData[2]:=0;
    OutData[3]:=0;
    OutData[4]:=0;
    OutData[5]:=Funct;
    l:=6;
  End;

  CRC:=CalcCRC_KB(@OutData, l);
  OutData[l]:=Lo(CRC);
  OutData[l+1]:=Hi(CRC);

  Case CommandType of
    kbctRead:     li := 5 + RegCnt * 2;
    kbctWrite:    li := 8;
    kbctCommand:  li := 8;
  End;
  Send(cSendCount, l+2, li,
    function(): Boolean
    begin
      Result:=(InData[0]=OutData[0]) and (InData[1]=OutData[1]);
    end);
    If Terminated then Exit;

  Res:=CheckKBAnswer(Address, @InData, @OutData, li, kbqt);
  Result:=Res<>1;
  If Res<>0 then
  Begin
    WriteSendLog('KB');
    _BeforeExit(Result);
    Exit(False);
  End;
  {Else if CommandType=kbctWrite then
    WriteSendLog('KB');}

  If Cntrlr is TKB_001_1102 then
  Begin
    if CommandType=kbctCommand then
      case TKB_001_1102_Command(Funct) of
        k1102cStartDosing:  ;
        k1102cStopDosing:   ;
      end
    else if CommandType=kbctRead then
      case TKB_001_1102_Register(Reg) of
        k1102rWeight:
          begin
            Weight:=BytesToSingle([InData[3], InData[4], InData[5], InData[6]]);
            if Cntrlr.Weight<0 then
              Cntrlr.Weight:=0
            else Cntrlr.Weight:=Weight;
          end;
        k1102rState:
          Cntrlr.State:=InData[3];
        k1102rFloatDigits:
          Cntrlr.Decimal:=InData[4];
      end;
  End//If Cntrlr is TKB_001_1102 then
  Else {if Cntrlr is TKB_001_091 then
  Begin
    if CommandType=kbctCommand then
      case TKB_001_091_Command(Funct) of
        k091cStartDosing: ;//Cntrlr.Status:=wcDosing;
        k091cStopDosing:  ;//Cntrlr.Status:=wcWaiting;
      end
    else if CommandType=kbctRead then
      case TKB_001_091_Register(Reg) of
        k091rWeight:
          begin
            Weight:=BytesToSingle([InData[3], InData[4], InData[5], InData[6]]);
            if Cntrlr.Weight<0 then
              Cntrlr.Weight:=0
            else Cntrlr.Weight:=Weight;
          end;
        k091rState:
          Cntrlr.State:=InData[3];
        k091rFloatDigits:
          Cntrlr.Decimal:=InData[4];
      end;
  End//Else if Cntrlr is TKB_001_091 then
  Else }if Cntrlr is TKB_001_081 then
  Begin
    if CommandType=kbctCommand then
      case TKB_001_081_Command(Funct) of
        k081cStartDosing: ;//Cntrlr.Status:=wcDosing;
        k081cStopDosing:  ;//Cntrlr.Status:=wcWaiting;
      end
    else if CommandType=kbctRead then
      case TKB_001_081_Register(Reg) of
        k081rWeight:
          begin
            Weight:=BytesToSingle([InData[3], InData[4], InData[5], InData[6]]);
            if Cntrlr.Weight<0 then
              Cntrlr.Weight:=0
            else Cntrlr.Weight:=Weight;
          end;
        k081rState:
          Cntrlr.State:=InData[3];
        k081rFloatDigits:
          Cntrlr.Decimal:=InData[4];
      end;
  End//Else if Cntrlr is TKB_001_081 then
  Else if Cntrlr is TPTC_001 then
  Begin
    if CommandType=kbctCommand then
      case TPTC_001_Command(Funct) of
        kPTCcStartDosing: ;//Cntrlr.Status:=wcDosing;
        kPTCcStopDosing:  ;//Cntrlr.Status:=wcWaiting;
      end
    else if CommandType=kbctRead then
      case TPTC_001_Register(Reg) of
        kPTCrWeight:
          begin
			Weight:=BytesToSingle([InData[3], InData[4], InData[5], InData[6]]);
            if Cntrlr.Weight<0 then
              Cntrlr.Weight:=0
            else Cntrlr.Weight:=Weight;
          end;
        kPTCrState:
          Cntrlr.State:=InData[3];
//        kPTCrFloatDigits:
//          Cntrlr.Decimal:=InData[4];
      end;
  End;//Else if Cntrlr is TPTC_001 then

    //Message for waiting thread
  If ThrId<>0 then
    PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

  _BeforeExit(Result);
end;

function TCommunication.SendKGDCommand(Address: Byte; Request: AnsiString; ThrId: Int64=0): Boolean;
var
  Cntrlr: TKGD;
  Response, Str: AnsiString;

  procedure _BeforeExit(Res: Boolean);
  begin
      //Device connection state
    Cntrlr.Connected:=Res;

//    Case CommandType of
//      kbctRead:
//        if Assigned(FOnWCRead) then     FOnWCRead(Address, Res, Reg);
//      kbctWrite:
//        if Assigned(FOnWCWrite) then    FOnWCWrite(Address, Res, Reg);
//      kbctCommand:
//        if Assigned(FOnWCCommand) then  FOnWCCommand(Address, Res, Funct);
//    End;
  end;

begin
  Result:=False;
  Cntrlr:=Devs.KGDAds[Address];

  Send(cSendCount, Request,
    function(): Boolean
    begin
      Result := Copy(Request, 1, 5) = Copy(SocketPort.LastResult, 1, 5);
    end);
    If Terminated then Exit;

  Response:={$IF Emulate=True}Emulator.LastResult{$ELSE}SocketPort.LastResult{$IFEND};
  Result:=CheckKGDAnswer(Request, Response);
  If not Result then
  Begin
    WriteLog('KGDReq: '+Request+'; KGDResp: '+Response);
    Result:=False;
    _BeforeExit(Result);
    Exit;
  End;

  Case TKGD_Command(StrToInt(Copy(Response, 4, 2))) of
    kKGDcStart:   Cntrlr.State:=kKGDsMeasuring;
    kKGDcStop:    Cntrlr.State:=kKGDsWaiting;
    kKGDcResult:  begin
                    Str:=Copy(Response, 7, 4);
                    if Str='good' then
                      Cntrlr.MeasResult:=kKGDrGood
                    else if Str='bad' then
                      Cntrlr.MeasResult:=kKGDrBad
                    else if Str='work' then
                      Cntrlr.MeasResult:=kKGDrWork;
                  end;
    kKGDcSetTime: Cntrlr.MeasTime:=StrToInt(Copy(Request, 7, 6));
  End;

    //Message for waiting thread
  If ThrId <> 0 then
    PostThreadMessage(ThrId, TM_KEEPONWORKING, 0, 0);

  _BeforeExit(Result);
end;

//--------------------------------------------------------------------------------------------------

procedure TCommunication.Execute;
const
  cSleepTime = 10;
var
  MovedToEnd: Boolean;
  Cmnd: TCommand;

  procedure _MoveToEnd; //Adding command into Queue of Postponed Commands
  begin
    MovedToEnd:=False;
    If QueueCommands.First.UseCnt<10 then{!}
    Begin
      QueueCommands.First.UseCnt:=QueueCommands.First.UseCnt+1;
      QueueCommands.Move(0, QueueCommands.IndexOf(QueueCommands.Last));
      MovedToEnd:=True;
    End;
  end;

  procedure _QueueCommands;
  var
    Res: Boolean;
  begin
    While (QueueCommands.Count>0) and not Terminated do
    Begin
      Sleep(cSleepTime);
      Res:=False;
      MovedToEnd:=False;
      Cmnd:=QueueCommands.First;
      if not Assigned(Cmnd) then
        begin end
      else if not Assigned(Devs.FindDeviceByAddress(QueueCommands.First.Address)) then
        begin end
      else if not Devs.FindDeviceByAddress(QueueCommands.First.Address).IsInWork then
        begin end
      else if QueueCommands.First.DevType=dtcKB then
        Res:=SendKBCommand(
                QueueCommands.First.Address,
                QueueCommands.First.CommandKB,
                QueueCommands.First.DataLen,
                QueueCommands.First.RegisterKB,
                QueueCommands.First.RegisterKBCnt,
                QueueCommands.First.Data,
                QueueCommands.First.CommandTypeKB,
                QueueCommands.First.ThreadId)
      else if QueueCommands.First.DevType=dtcKGD then
        Res:=SendKGDCommand(
                QueueCommands.First.Address,
                QueueCommands.First.StrQuery,
                QueueCommands.First.ThreadId)
      else if QueueCommands.First.DevType=dtcDIOM then
      begin
        if QueueCommands.First.ConsiderOtherData=dcdNone then
          Res:=SendDIOMCommand(
                  QueueCommands.First.Address,
                  QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
        else if QueueCommands.First.ConsiderOtherData=dcdOutputs then
          Res:=SendDIOMCommand(
                  QueueCommands.First.Address,
                  Devs.DIOMAds[QueueCommands.First.Address].RecalcChanges(
                    QueueCommands.First.ValueDIOM, 0, dcdOutputs),
//                  Devs.DIOMAds[QueueCommands.First.Address].GetOuts+
//                    QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
        else if QueueCommands.First.ConsiderOtherData=dcdOutsNeed then
          Res:=SendDIOMCommand(
                  QueueCommands.First.Address,
                  Devs.DIOMAds[QueueCommands.First.Address].RecalcChanges(
                    QueueCommands.First.ValueDIOM, 0, dcdOutsNeed),
//                  Devs.DIOMAds[QueueCommands.First.Address].GetNeedOuts+
//                    QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
      end
      else if QueueCommands.First.DevType=dtcDIM then
        Res:=SendDIMCommand(
                QueueCommands.First.Address,
                QueueCommands.First.RegDIOM,
                QueueCommands.First.ThreadId)
      else if QueueCommands.First.DevType=dtcDOM then
      begin
        if QueueCommands.First.ConsiderOtherData=dcdNone then
          Res:=SendDOMCommand(
                  QueueCommands.First.Address,
                  QueueCommands.First.RegDIOM,
                  QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
        else if QueueCommands.First.ConsiderOtherData=dcdOutputs then
          Res:=SendDOMCommand(
                  QueueCommands.First.Address,
                  QueueCommands.First.RegDIOM,
                  Devs.DOMAds[QueueCommands.First.Address].RecalcChanges(
                    QueueCommands.First.ValueDIOM, QueueCommands.First.RegDIOM, dcdOutputs),
//                  Devs.DOMAds[QueueCommands.First.Address].GetOuts(
//                    QueueCommands.First.RegDIOM) + QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
        else if QueueCommands.First.ConsiderOtherData=dcdOutsNeed then
          Res:=SendDOMCommand(
                  QueueCommands.First.Address,
                  QueueCommands.First.RegDIOM,
                  Devs.DOMAds[QueueCommands.First.Address].RecalcChanges(
                    QueueCommands.First.ValueDIOM, QueueCommands.First.RegDIOM, dcdOutsNeed),
//                  Devs.DOMAds[QueueCommands.First.Address].GetNeedOuts(
//                    QueueCommands.First.RegDIOM) + QueueCommands.First.ValueDIOM,
                  QueueCommands.First.Write,
                  QueueCommands.First.ThreadId)
      end;

      if not Res then _MoveToEnd;
      if not MovedToEnd then
      begin
//        QueueCommands.First.Free;
//        try QueueCommands.Delete(0); except end;
        If QueueCommands.Count>0 then QueueCommands.Delete(0);
      end;
    End;//While
  end;

  procedure _DXMComandDelete;
  begin
//    QueueDXM.First.Free;
//    try QueueDXM.Delete(0); except end;
    If QueueDXM.Count>0 then QueueDXM.Delete(0);
  end;

  procedure _WCComandDelete;
  begin
//    QueueWC.First.Free;
//    try QueueWC.Delete(0); except end;
    If QueueWC.Count>0 then QueueWC.Delete(0);
  end;

begin
  {$IF Emulate=True}
    FWaitingTime:=700;  //Emulator needs more time but works quick. It's a kind of magic!
  {$ELSE}
    FWaitingTime:=50;  //Average time between sending and getting answer is 17 ms
  {$IFEND}

  WHILE not Terminated DO
  TRY

      //Commands
    If (QueueCommands.Count>0) and not Terminated then
      _QueueCommands;

    Sleep(cSleepTime);

      //DXM
    If (QueueDXM.Count>0) and not Terminated then
    Begin
      Cmnd:=QueueDXM.First;
      if not Assigned(Cmnd) then
        begin end
      else if not Assigned(Devs.FindDeviceByAddress(QueueDXM.First.Address)) then
        begin end
      else if not Devs.FindDeviceByAddress(QueueDXM.First.Address).IsInWork then
        begin end
      else if QueueDXM.First.DevType=dtcDIOM then
        SendDIOMCommand(QueueDXM.First.Address,
                        QueueDXM.First.ValueDIOM,
                        QueueDXM.First.Write,
                        QueueDXM.First.ThreadId)
      else if QueueDXM.First.DevType=dtcDIM then
        SendDIMCommand(QueueDXM.First.Address,
                       QueueDXM.First.RegDIOM,
                       QueueDXM.First.ThreadId)
      else if QueueDXM.First.DevType=dtcDOM then
        SendDOMCommand(QueueDXM.First.Address,
                       QueueDXM.First.RegDIOM,
                       QueueDXM.First.ValueDIOM,
                       QueueDXM.First.Write,
                       QueueDXM.First.ThreadId);

      _DXMComandDelete;
    End;

      //Commands
    If (QueueCommands.Count>0) and not Terminated then
      _QueueCommands;

    Sleep(cSleepTime);

      //WC
    If (QueueWC.Count>0) and not Terminated then
    Begin
      Cmnd:=QueueWC.First;
      if not Assigned(Cmnd) then
        begin end
      else if not Assigned(Devs.FindDeviceByAddress(QueueWC.First.Address)) then
        begin end
      else if not Devs.FindDeviceByAddress(QueueWC.First.Address).IsInWork then
        begin end
      else if QueueWC.First.DevType=dtcKB then
        SendKBCommand(QueueWC.First.Address,
                      QueueWC.First.CommandKB,
                      QueueWC.First.DataLen,
                      QueueWC.First.RegisterKB,
                      QueueWC.First.RegisterKBCnt,
                      QueueWC.First.Data,
                      QueueWC.First.CommandTypeKB,
                      QueueWC.First.ThreadId);

      _WCComandDelete;
    End;

    //-------------------------------------------

      //Adding new commands
    if not Terminated then AddDXMCommands;
    if not Terminated then AddWCCommands;
  EXCEPT
  END;
end;

//--------------------------------------------------------------------------------------------------

function TCommunication.HasCommands: Boolean;
begin
  Result:=QueueCommands.Count>0;
end;

//==================================================================================================

initialization
  Commun:=TCommunication.Create(True);
    Commun.Priority:=tpNormal;
    Commun.FreeOnTerminate:=True;
    {Commun.FWaitingTime:=ReadIni(ExtractFilePath(ParamStr(0))+'Sets.ini',
      'Communication', 'WaitTime', varInteger, 70);}
finalization

end.