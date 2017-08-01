(*
	Упращает работу с ini-файлами до одной строки на параметр.
*)

unit RazIniFuncs;

interface

uses IniFiles, Variants, SysUtils;

  //Сохранение настроек в ini-файл
function WriteIni(FileName, Section, Param: String; Value: Variant; VarType: Word): Boolean;
  //Получение настроек из ini-файла
function ReadIni(FileName, Section, Param: String; VarType: Word; Default: Variant): Variant;

implementation

//==================================================================================================

function WriteIni(FileName, Section, Param: String; Value: Variant; VarType: Word): Boolean;
var
  Ini: TIniFile;
begin
  (* Сохранение настроек в ini-файл *)

  Result:=False;
  TRY
    If not DirectoryExists(ExtractFileDir(FileName)) then
      ForceDirectories(ExtractFileDir(FileName));
    Ini:=TIniFile.Create(FileName);
    Case VarType of
      varInt64:
        Ini.WriteString(Section, Param, IntToStr(VarAsType(Value, varInt64)));
      varInteger:
        Ini.WriteInteger(Section, Param, VarAsType(Value, varInteger));
      varString:
        Ini.WriteString(Section, Param, VarAsType(Value, varString));
      varBoolean:
        Ini.WriteBool(Section, Param, VarAsType(Value, varBoolean));
      varCurrency, varDouble:
        Ini.WriteFloat(Section, Param, VarAsType(Value, varCurrency));
    End;
    FreeAndNil(Ini);
    Result:=True;
  EXCEPT
    {on E: Exception do
      WriteLog('Ошибка записи в ini: '+E.Message, rtError);}
  END;
end;

function ReadIni(FileName, Section, Param: String; VarType: Word; Default: Variant): Variant;
var
  Ini: TIniFile;
begin
  (* Получение настроек из ini-файла *)

  Result:=Null;
  TRY
    If not FileExists(FileName, False) then
      Result:=Default;

    Ini:=TIniFile.Create(FileName);
    Case VarType of
      varInt64:
          Result:=StrToInt64(Ini.ReadString(Section, Param, VarToStr(Default)));
      varInteger:
          Result:=Ini.ReadInteger(Section, Param, Default);
      varString:
          Result:=Ini.ReadString(Section, Param, Default);
      varBoolean:
          Result:=Ini.ReadBool(Section, Param, Default);
      varCurrency, varDouble, varSingle:
          Result:=Ini.ReadFloat(Section, Param, Default);
    End;
    FreeAndNil(Ini);
  EXCEPT
    Result:=Default;
    {on E: Exception do
      WriteLog('Ошибка чтения из ini: '+E.Message, rtError);}
  END;
end;

end.
