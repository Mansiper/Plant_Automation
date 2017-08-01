(*
	Отвечает за связь по сокету.
	Нужно было для общения с одной программой, которая в свою очередь общалась с устройством.
*)

unit Socket_port;

interface

uses ScktComp, SyncObjs, SysUtils;

type
  TSocketPort = class
  private
    FCS: TClientSocket;
    FEvent: TEvent;
    FLastResult: AnsiString;

    procedure CSRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure CSError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Send(Str: String; WaitTime: Cardinal);
    property LastResult: AnsiString read FLastResult;
  end;

var
  SocketPort: TSocketPort;

implementation

uses RazIniFuncs;

//==================================================================================================

procedure TSocketPort.CSRead(Sender: TObject; Socket: TCustomWinSocket);
var
  p: Integer;
  Str: AnsiString;
begin
    //Getting answer
  Str:=Socket.ReceiveText;
  Delete(Str, 1, 1);
  p:=Pos(#1, Str);
  If p > 0 then
    FLastResult:=Copy(Str, 1, p-1)
  Else FLastResult:=Str;
  FEvent.SetEvent;  //We've got an answer
end;

procedure TSocketPort.CSError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
  ErrorCode:=0;
end;

//--------------------------------------------------------------------------------------------------

constructor TSocketPort.Create;
begin
  FCS:=TClientSocket.Create(nil);
  FCS.Address:=
    ReadIni(ExtractFilePath(ParamStr(0))+'Sets.ini', 'Server', 'Address', varString, '127.0.0.1');
  FCS.Port:=
    ReadIni(ExtractFilePath(ParamStr(0))+'Sets.ini', 'Server', 'Port', varInteger, 10617);
  FCS.Open;
  FCS.OnRead:=Self.CSRead;
  FCS.OnError:=Self.CSError;

  FEvent:=TEvent.Create(nil, False, False, '');
  Sleep(100);
end;

destructor TSocketPort.Destroy;
begin
  FCS.Close;
  FreeAndNil(FCS);
  FreeAndNil(FEvent);
end;

procedure TSocketPort.Send(Str: String; WaitTime: Cardinal);
begin
  If not Assigned(FCS) then Exit;
  Try
    FLastResult:='';
    FCS.Open;
    FCS.Socket.SendText(#1+Str);  //Sending data
    FEvent.WaitFor(WaitTime);     //Waiting answer
  Except
  End;
end;

//==================================================================================================

initialization
  SocketPort:=TSocketPort.Create;
finalization
  SocketPort.Free;

end.
