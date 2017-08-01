(*
	Приведённый ниже код был найден на просторах интернета,
	с удовольствием использован и дораобтан под свои нужды
*)

unit Com_port;

////////////////////////////////////////////////////////////////////////////////////////////////////
// //
// class: tcomport //
// //
// description: asynchronous (overlapped) com port //
// version: 1.0 //
// date: 10-jun-2003 //
// author: igor pavlov, pavlov_igor@nm.ru //
// //
// copyright: (c) 2003, igor pavlov //
// //
////////////////////////////////////////////////////////////////////////////////////////////////////

//**************************************************************************************************
// *
// edited and putched *
// *
// date: 01/07/2003 *
// author: mukovoz il'ya sergeevich, nuclear@bel.ru *
// *
//**************************************************************************************************

interface

uses
  SysUtils, Windows, Variants, Classes, SyncObjs, IniFiles;

type
  EComPortError = class(Exception);

  TBaudRate = (br110 = CBR_110, br300 = CBR_300, br600 = CBR_600,
              br1200 = CBR_1200, br2400 = CBR_2400, br4800 = CBR_4800,
              br9600 = CBR_9600, br14400 = CBR_14400, br19200 = CBR_19200,
              br38400 = CBR_38400, br56000 = CBR_56000, br57600 = CBR_57600,
              br115200 = CBR_115200, br128000 = CBR_128000, br256000 = CBR_256000);

  TComPort = class;

  TReadThread = class(TThread)
  private
    FBuf: Array [0..$FF] of Byte;
    FTmpIn: Array of Smallint;
    FTmpCnt: Byte;
    FComPort: TComPort;
    FOverRead: TOverlapped;
    FRead: DWORD;
    FTryCnt: Byte;

    procedure DoRead;
  protected
    procedure Execute; override;
  public
    constructor Create(CPort: TComPort);
    destructor Destroy; override;
  end;

  TReadEvent = procedure(Sender: TObject; ReadBytes: Array of Byte) of object;

  TComPort = class
  private
    const
      cBufSize = 64;
    var
      FOverWrite: TOverlapped;
      FPort: THandle;
      FPortName: String;
      FReadEvent: TReadEvent;
      FReadThread: TReadThread;
      FNumber: Byte;
      FSpeed: Cardinal;
      FParity: Byte;
      FDataBits: Byte;
      FStopBits: Byte;
      FComWriteEvent: TEvent;

      FOutArray: PByteArray;
      FOutSize: Byte;
      FDevAddress: Byte;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Write(WriteBytes: Array of Byte; Size: Byte; OutArray: PByteArray; OutSize: Byte);
    procedure Wait(WaitingTime: Cardinal);  //Turns on waiting for answer

    property OnRead: TReadEvent read FReadEvent write FReadEvent;
    property PortName: String read FPortName;
    property Handle: THandle read FPort;
    property Number: Byte read FNumber write FNumber default 1;
    property Speed: Cardinal read FSpeed write FSpeed default CBR_19200;
    property Parity: Byte read FParity write FParity default NOPARITY;
    property DataBits: Byte read FDataBits write FDataBits default DATABITS_8;
    property StopBits: Byte read FStopBits write FStopBits default TWOSTOPBITS;
    property ComWriteEvent: TEvent read FComWriteEvent write FComWriteEvent;
  end;

var
  ComPort: TComPort;

implementation

uses Communication, RazIniFuncs;

//==================================================================================================

constructor TReadThread.Create(CPort: TComPort);
begin
  FComPort:=CPort;
  ZeroMemory(@FOverRead, SizeOf(FOverRead));

  FOverRead.hEvent:=CreateEvent(nil, True, False, nil);

  If FOverRead.hEvent = Null then
    raise EComPortError.Create('Error creating read event');

  Inherited Create(False);
end;

destructor TReadThread.Destroy;
begin
  CloseHandle(FOverRead.hEvent);

  Inherited Destroy;
end;

procedure TReadThread.Execute;
var
  i, Dif: Byte;
  ComStat: TComStat;
  dwMask, dwError: DWORD;
begin
  FreeOnTerminate := True;
  FTryCnt:=0;

  While not Terminated do
  Begin
    if not WaitCommEvent(FComPort.FPort, dwMask, @FOverRead) then
    begin
      if GetLastError = ERROR_IO_PENDING then
        WaitForSingleObject(FOverRead.hEvent, INFINITE)
      else
        raise EComPortError.Create('Error waiting event from port ' +
          FComPort.PortName);
    end;
    if not Terminated then
    begin
      if not ClearCommError(FComPort.FPort, dwError, @ComStat) then
        raise EComPortError.Create('Error cleaning port ' + FComPort.PortName);
    end
    else Break;

    FRead := ComStat.cbInQue;

    if FRead >= FComPort.FOutSize then  ////Из-за проблем с чтением из КВ-001. Было FRead > 1
//    if FRead > 1 then
    begin
      if not ReadFile(FComPort.FPort, FBuf, FRead, FRead, @FOverRead) then
        raise EComPortError.Create('Error reading port ' + FComPort.PortName)
      else
      begin
        if FComPort.FOutArray=nil then
        begin
          ComPort.ComWriteEvent.SetEvent;
          Continue;
        end;

        Dif:=0;
          //Бывает, что в первых байтах приходят последние предыдущего ответа - пропускаем их
        for i:=0 to FComPort.cBufSize-1 do
          if FBuf[i] = FComPort.FDevAddress then
          begin
            Dif := i;
            Break;
          end;
          //Прочитано меньше необходимого. Количество попыток ограничено
        if (FRead < FComPort.FOutSize - Dif) and (FTryCnt > 5) then
        begin
          Inc(FTryCnt);
          Sleep(4);
          Continue;
        end;
        if Dif > 30 then Dif := 0;  //Слишком далеко зашёл

          //Запись результата
        for i:=0 to FComPort.FOutSize-1 do
          FComPort.FOutArray^[i]:=FBuf[i+Dif];

        ComPort.ComWriteEvent.SetEvent;
        FComPort.FOutArray:=nil;
        FTryCnt:=0;
      end;

      DoRead;
    end
    else Sleep(4);  //Из-за проблем с чтением из КВ-001
  End;//while
end;

procedure TReadThread.DoRead;
var
  arrBytes: Array of Byte;
  i: Integer;
begin
  If Assigned(FComPort.FReadEvent) then
  Begin
    SetLength(arrBytes, FRead);
    for i:=Low(FBuf) to FRead-1 do
      arrBytes[i]:=FBuf[i];

    FComPort.FReadEvent(Self, arrBytes);

    arrBytes:=nil;
  End;
end;

//==================================================================================================

constructor TComPort.Create;
const
  cFile = 'com.ini';
  cSection = 'COM-порт';
var
  Dcb: TDcb;
  CTO: TCommTimeouts;
  Path: String;
begin
  inherited Create;

  FComWriteEvent:=TEvent.Create(nil, False, False, '');

    //Default data
  Path:=ExtractFilePath(ParamStr(0))+cFile;
  If FileExists(Path) then
  Begin
    FNumber:=ReadIni(Path, cSection, 'Номер', varInteger, 1);
    FSpeed:=ReadIni(Path, cSection, 'Скорость', varInteger, 19200);
    FParity:=ReadIni(Path, cSection, 'Чётность', varInteger, 0);
    FDataBits:=ReadIni(Path, cSection, 'Размер байт', varInteger, 8);
    FStopBits:=ReadIni(Path, cSection, 'Стоп-биты', varInteger, 2);
  End
  Else
  Begin
    FNumber:=1;
    FSpeed:=19200;
    FParity:=0;
    FDataBits:=8;
    FStopBits:=2;
  End;

  ZeroMemory(@FOverWrite, SizeOf(FOverWrite));
  FPortName := '\\.\COM' + IntToStr(Number);

  FPort := CreateFile(PChar(PortName),
    GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

  If FPort = INVALID_HANDLE_VALUE then
    raise EComPortError.Create('Error open port ' + PortName);

  Try
    if not SetupComm(FPort, cBufSize, cBufSize) then
      raise EComPortError.Create('Error setuping port ' + PortName + ' queue');

    if not GetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error getting state of port ' + PortName + ' state');

    Dcb.BaudRate:=DWORD(Speed);
    Dcb.Parity:=Parity;
    Dcb.ByteSize:=DataBits;
    Dcb.StopBits:=StopBits;

    if not SetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error setting state for port ' + PortName + ' state');

    with CTO do
    begin
//      ReadIntervalTimeout:=MAXDWORD;
//      ReadTotalTimeoutMultiplier:=1;
//      ReadTotalTimeoutConstant:=10;
//      WriteTotalTimeoutMultiplier:=1;
//      WriteTotalTimeoutConstant:=10;
      ReadIntervalTimeout:=ReadIni(Path, cSection, 'RIT', varInt64, MAXDWORD); //Defaults for КВ-001: 10 1 100 1 10
      ReadTotalTimeoutMultiplier:=ReadIni(Path, cSection, 'RTTM', varInteger, 1);
      ReadTotalTimeoutConstant:=ReadIni(Path, cSection, 'RTTC', varInteger, 10);
      WriteTotalTimeoutMultiplier:=ReadIni(Path, cSection, 'WTTM', varInteger, 1);
      WriteTotalTimeoutConstant:=ReadIni(Path, cSection, 'WTTC', varInteger, 10);
    end;
    if not SetCommTimeouts(FPort, CTO) then
      raise EComPortError.Create('Error setting timeouts for port ' + PortName + ' timeouts');

    if not PurgeComm(FPort, PURGE_TXCLEAR or PURGE_RXCLEAR) then
      raise EComPortError.Create('Error purging port ' + PortName);

    if not SetCommMask(FPort, EV_RXCHAR) then
      raise EComPortError.Create('Error setting mask for port ' + PortName + ' mask');

    FOverWrite.hEvent := CreateEvent(nil, True, False, nil);

    if FOverWrite.hEvent = Null then
      raise EComPortError.Create('Error creating writing event');

    FReadThread := TReadThread.Create(Self);
  Except
    CloseHandle(FOverWrite.hEvent);
    CloseHandle(FPort);
    raise;
  End;
end;

destructor TComPort.Destroy;
begin
  If Assigned(FReadThread) then
    FReadThread.Terminate;

  CloseHandle(FOverWrite.hEvent);
  CloseHandle(FPort);
  FComWriteEvent.Free;

  Inherited Destroy;

  //FPort:=INVALID_HANDLE_VALUE;
end;

procedure TComPort.Write(WriteBytes: Array of Byte; Size: Byte; OutArray: PByteArray;
  OutSize: Byte);
var
  i: Byte;
  dwWrite: DWORD;
begin
  FOutArray:=OutArray;
  FOutSize:=OutSize;
  FDevAddress:=WriteBytes[0];

  SetLength(FReadThread.FTmpIn, Size);
  For i:=Low(FReadThread.FTmpIn) to High(FReadThread.FTmpIn) do
    FReadThread.FTmpIn[i]:=-1;
  FReadThread.FTmpCnt:=0;

  If (not WriteFile(FPort, WriteBytes, Size, dwWrite, @FOverWrite))
  and (GetLastError <> ERROR_IO_PENDING) then
    raise EComPortError.Create('Error writing in port ' + PortName);
end;

procedure TComPort.Wait(WaitingTime: Cardinal);
begin
  FComWriteEvent.WaitFor(WaitingTime);
end;

//==================================================================================================

initialization
  {$IF Emulate=False}
  ComPort:=TComPort.Create;
  {$IFEND}
finalization
  {$IF Emulate=False}
  ComPort.Free;
  {$IFEND}

end.