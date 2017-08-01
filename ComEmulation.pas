(*
	До того, как шкаф электроники готов, или после того, как уже отдан заказчику,
	программу как-то нужно разрабатывать и тестировать, для чего был создан
	эмулятор устройств который полностью имитировал работу всех устройств на предприятии,
	обеспечивая отсутствие (по крайней мере очевидных) ошибок при обновлении.
	Этот модуль отвечает за связь с эмулятором (имитирует com-порт).
	Возможно, эмулятор тоже как-нибудь выложу.
*)

unit ComEmulation;

interface

uses ScktComp, SyncObjs, SysUtils;

type
  TEmulator = class
  private
    FCS: TClientSocket;
    FEvent: TEvent;

    procedure CSRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Send(Str: String; WaitTime: Cardinal);
  end;

var
  Emulator: TEmulator;

implementation

uses Communication;

//==================================================================================================

procedure TEmulator.CSRead(Sender: TObject; Socket: TCustomWinSocket);
var
  i: Integer;
  Str, st: AnsiString;
  Data: Array of Byte;
begin

    //Getting answer
  Str:=Socket.ReceiveText;
  Delete(Str, 1, 1);
  i:=Pos(#1, Str);                  //Every data begins from #1
  Delete(Str, i, Length(Str)-i+1);  //Delete excess data
  Str:=Str+' ';

    //Parsing answer
  st:='';
  For i:=1 to Length(Str) do
  Begin
    if Str[i] in ['0'..'9'] then
      st:=st+Str[i]
    else
    begin
      SetLength(Data, Length(Data)+1);
      Data[Length(Data)-1]:=StrToInt(st);
      st:='';
    end;
  End;

  If not Commun.Suspended then
    for i:=Low(Data) to High(Data) do
      Commun.InData[i]:=Data[i];

  FEvent.SetEvent;  //We've got an answer
end;

procedure TEmulator.CSError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  ErrorCode:=0;
end;

//--------------------------------------------------------------------------------------------------

constructor TEmulator.Create;
begin
  FCS:=TClientSocket.Create(nil);
  FCS.Address:='127.0.0.1';
  FCS.Port:=1200;
  FCS.Open;
  FCS.OnRead:=Self.CSRead;
  FCS.OnError:=Self.CSError;

  FEvent:=TEvent.Create(nil, False, False, '');
  Sleep(100);
end;

destructor TEmulator.Destroy;
begin
  FCS.Close;
  FreeAndNil(FCS);
  FreeAndNil(FEvent);
end;

procedure TEmulator.Send(Str: String; WaitTime: Cardinal);
begin
  If Commun.Suspended or not Assigned(FCS) then Exit;
  Try
    FCS.Open;
    FCS.Socket.SendText(#1+Str);  //Sending data
    FEvent.WaitFor(WaitTime);     //Waiting answer
  Except
  End;
end;

//==================================================================================================

initialization
  Emulator:=TEmulator.Create;
finalization
  Emulator.Free;

end.