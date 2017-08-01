(*
	Логер.
	Организован в виде потока (thread). Логи пишутся в очередь, откуда потом и пишутся по файлам.
*)

unit RazLogs;

interface

uses Classes, Variants, SysUtils, Windows, Registry, Generics.Collections;

type
    //Тип лога
  TRecordType = (rtOther, rtError, rtXML, rtTest, rtFormCreate, rtQuery, rtScript,
    rtDataBase, rtComm,
    rtService, rtServer, rtClient, rtLogInfo);

    //Хранилище инфы по логам
  TLogInfa = class
  private
    FDateTime: String;        //Дата и время лога
    FErText: String;          //Текст ошибки
    FMarker: String;          //Дополнительная метка ошибки (подтип)
    FRecordType: TRecordType; //Тип лога
  protected
    property DateTime: String read fDateTime;
    property Marker: String read fMarker;
    property ErText: String read fErText;
    property RecordType: TRecordType read fRecordType;

    constructor Create(ErText, Marker: String; RecordType: TRecordType);
  end;

    //Поток записи логов
  TLogWriter = class(TThread)
  private
    FLogsDirPath: String;     //Файл логов
    FAllowWriteLogs: Boolean; //Разрешение на ведение логов
    FFileMark: Word;          //Метка файла (если размер файла превысил допустимый)
    FUserName: String;        //Имя пользователя (пишутся отдельные логи на каждого пользователя)
    FLogList: TObjectList<TLogInfa>;

    function GetLogListCount: Integer;
  private //Взяты из RazFuncs, чтобы не подключать лишний модуль
    function StringsReplace(const S: String; const OldPattern: Array of String; NewStr: String;
      Flags: TReplaceFlags): String;
    function PathClear(Path: String): String;
  protected
    procedure Execute; override;
  public
    property LogsDirPath: String read FLogsDirPath write FLogsDirPath;
    property AllowWriteLogs: Boolean read FAllowWriteLogs write FAllowWriteLogs;
    property UserName: String read FUserName write FUserName;
    property LogListCount: Integer read GetLogListCount;

    constructor Create(ALogsDirPath: String);
    destructor Destroy; override;
  end;

var
  LogWriter: TLogWriter;

//procedure DeleteOldLogs;
procedure WriteLog(const LogText: String; RecordType: TRecordType=rtTest;
  Marker: String='');

implementation

//==============================================================================

{procedure DeleteOldLogs;
const
  cDays = 14;
var
  SR: TSearchRec;
  FileExt: String;
  SysTime: _SYSTEMTIME;
begin
   Удаление старых логов

    //Получаю первый файл из каталога
  If FindFirst(FirmSettingsPath+CurModuleName+'\Logs\*.*',
    faAnyFile, SR)=0 then
  Begin
      //Бегу по всем файлам
    while True do
    begin
      FileExt:=ExtractFileExt(SR.Name);
      if (FileExt='.log') or (FileExt='.qlog') then
      begin
          //Если дата не сегодняшняя, удаляю
        FileTimeToSystemTime(SR.FindData.ftLastWriteTime, SysTime);
        if Date>StrToDate(IntToStr(SysTime.wDay)+'.'+
        IntToStr(SysTime.wMonth)+'.'+IntToStr(SysTime.wYear))+cDays then
          SysUtils.DeleteFile(FirmSettingsPath+CurModuleName+'\Logs\'+SR.Name);
          //Получаю следующий файл
        if FindNext(SR)<>0 then Break;
      end
      else if FindNext(SR)<>0 then Break; //Получаю следующий файл
    end;//while True do
  End;//If FindFirst()=0 then
end;}

procedure WriteLog(const LogText: String; RecordType: TRecordType=rtTest;
  Marker: String='');
var
  Log: TLogInfa;
begin
  (* Добавление записи в очередь логов *)

  If not Assigned(LogWriter) then Exit;
  If not LogWriter.AllowWriteLogs then Exit;
  Log:=TLogInfa.Create(LogText, Marker, RecordType);
  LogWriter.FLogList.Add(Log);
end;

//==================================================================================================

constructor TLogInfa.Create(ErText, Marker: String; RecordType: TRecordType);
const
  cLogsTimeFormat = 'hh:mm:ss';
{var
  fs: TFormatSettings;}
begin
  (* Создание записи о логе *)

  {fs.DateSeparator:='.';
  fs.TimeSeparator:=':';
  //fs.ShortDateFormat:='dd.mm.yyyy hh:mm:ss';
  fs.ShortDateFormat:='hh:nn:ss';}

  FDateTime:=FormatDateTime(cLogsTimeFormat, Now);//Trim(DateTimeToStr(Now, fs));  //Иначе пробел в конце появляется
  FErText:=ErText;
  FMarker:=Marker;
  FRecordType:=RecordType;
end;

//==================================================================================================

constructor TLogWriter.Create(ALogsDirPath: String);
begin
  inherited Create(False);

    //По умолчанию задаётся путь каталог к файлу
  FLogsDirPath:=ALogsDirPath;
  FAllowWriteLogs:=True;
  FLogList:=TObjectList<TLogInfa>.Create;
  Priority:=tpLower;
end;

destructor TLogWriter.Destroy;
begin
  FreeAndNil(FLogList);
end;

//--------------------------------------------------------------------------------------------------

function TLogWriter.GetLogListCount: Integer;
begin
  Result:=FLogList.Count;
end;

function TLogWriter.StringsReplace(const S: String; const OldPattern: Array of String;
  NewStr: String; Flags: TReplaceFlags): String;
var
  i: Integer;
begin
  (* Замена кусков текста в строке *)

  Result:=S;
  For i:=Low(OldPattern) to High(OldPattern) do
    Result:=StringReplace(Result, OldPattern[i], NewStr, Flags);
end;

function TLogWriter.PathClear(Path: String): String;
begin
  (* Очистка имени и пути файла от запрещённых символов *)
  Result:=StringsReplace(Path, ['/', '\', ':', '*', '?', '"', '<', '>', '|'], '', [rfReplaceAll]);
end;

//--------------------------------------------------------------------------------------------------

procedure TLogWriter.Execute;
const
  cDefExt = '.log';
  cSQLExt = '.qlog';
  cLogsDateFormat = 'yyyy.mm.dd';
var
  FileNE: Boolean;
  F: TextFile;
  DV, Ext: String;
  LogFile, LogType, Stroka: String;

  procedure _SetLogFileName;
  const
    cKey = '\Software\ProgLogInfo';
    cExch = '\data';
  {var
    Reg: TRegistry;
    FN: String;}
  begin
      If FFileMark=0 then
        LogFile:=FLogsDirPath+PathClear(DV+'_'+FUserName+Ext)
      Else
        LogFile:=FLogsDirPath+PathClear(
          DV+'_'+FUserName+'_'+IntToStr(FFileMark)+Ext);

      {If TLogInfa(LogList.Items[0]).RecordType=rtLogInfo then
      Begin
        Reg:=TRegistry.Create;
        Reg.Rootkey:=HKEY_LOCAL_MACHINE;
        if not Reg.KeyExists(cKey) then
          Reg.CreateKey(cKey);
        Reg.OpenKey(cKey+cExch, True);
          Reg.WriteString('lgs', LogFile);
        FreeAndNil(Reg);
      End;}
  end;

begin
  (* Работа потока записи логов *)

  FFileMark:=0;

  WHILE not Terminated DO
  BEGIN
    try
      if FLogList=nil then
        begin   Sleep(100);   Continue;   end
      else if not AllowWriteLogs or (FLogList.Count=0) then
        begin   Sleep(100);   Continue;   end;

      if not Assigned(TLogInfa(FLogList.Items[0])) then
        FLogList.Delete(0);

      if TLogInfa(FLogList.Items[0]).RecordType=rtQuery then
        Ext:=cSQLExt
      else Ext:=cDefExt;

        //Дата и время записи
      {fs.DateSeparator:='.';
      fs.TimeSeparator:=':';
      fs.ShortDateFormat:=cLogsDateFormat;
      DV:=Trim(DateTimeToStr(Now, fs));}
      DV:=FormatDateTime(cLogsDateFormat, Now);

      _SetLogFileName;
      (*{$IF Defined(PROG_SERVICE)}
        if TLogInfa(LogList.Items[0]).RecordType=rtLogInfo then
        begin
          LogList.Delete(0);
          Continue;
        end;
      {$IFEND}*)

        //Создаю каталог
      FileNE:=not FileExists(LogFile);
      if FileNE then
        if not ForceDirectories(FLogsDirPath) then
        begin
          FLogList.Delete(0);  //Не удалось создать файл каталог с логам (возможно, нет доступа)
          Continue;
        end;

//ToDo -cLogs: Если доступ к файлу закрыт, то возникает ошибка при открытии файла. Нужно создавать следующий
        //Проверка размера файла
      while not FileNE do
        with TFileStream.Create(LogFile, fmOpenRead) do
        begin
          if Size>3145728 then //Если превышает 3Мб, то создаю новый
          begin
            Inc(FFileMark);
            _SetLogFileName;
            Free;
            FileNE:=not FileExists(LogFile);
          end
          else
          begin
            Free;
            Break;
          end;
        end;
        //Создаю файл или открываю файл для добавления
      try
        AssignFile(F, LogFile);
        if FileNE then Rewrite(F)
        else Append(F);
      except
        try
          Close(F);
        except
        end;
        Continue;
      end;

        //Запись в файл описания
      If FileNE then
        //Writeln(F, 'Дата Время;'+#9+'Тип сообщения;'+#9+'Текст сообщения');
        Writeln(F, 'Время;'+#9+'Тип сообщения;'+#9+'Текст сообщения');

        //Тип сообщения
      Case TLogInfa(FLogList.Items[0]).RecordType of
        rtOther:        LogType:='Прочее';
        rtError:        LogType:='Ошибка';
        rtXML:          LogType:='XML';
        rtTest:         LogType:='Тест';
        rtQuery:        LogType:=TLogInfa(FLogList.Items[0]).Marker;
        rtDataBase:     LogType:='БазаДанных';
        rtService:      LogType:='Сервис';
        rtServer:       LogType:='Сервер';
        rtClient:       LogType:='Клиент';
      Else
        LogType:='Прочее';
      End;//Case TLogInfa(LogList.Items[0]).RecordType of

        //Текст сообщения
      Case TLogInfa(FLogList.Items[0]).RecordType of
        rtOther:        Stroka:=TLogInfa(FLogList.Items[0]).ErText;
        rtError:        Stroka:=TLogInfa(FLogList.Items[0]).ErText;
        rtXML:          Stroka:=TLogInfa(FLogList.Items[0]).ErText;
        rtTest:         Stroka:=TLogInfa(FLogList.Items[0]).ErText;
        rtQuery:        Stroka:=TLogInfa(FLogList.Items[0]).ErText;
        rtDataBase:     Stroka:=TLogInfa(FLogList.Items[0]).ErText;
      Else
        Stroka:=TLogInfa(FLogList.Items[0]).ErText;
      End;//Case TLogInfa(LogList.Items[0]).RecordType of

      Writeln(F, TLogInfa(FLogList.Items[0]).DateTime+';'+#9+LogType+';'+#9+Stroka);
      Flush(F);
      Close(F);

      FLogList.Delete(0);
    except
    end;//try
  END;//WHILE not Terminated DO
end;

initialization
  //Создаётся в основном модуле программы
finalization
  If Assigned(LogWriter) then
    LogWriter.Terminate;
  FreeAndNil(LogWriter);

end.
