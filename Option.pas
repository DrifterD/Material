{*******************************************************}
{                                                       }
{       ����ѡ���װ��                                  }
{       Option.xml ģ��                                 }
{       Option Unit For Windows                         }
{       XuYe                                            }
{       Copyright (R) 2004                              }
{                                                       }
{*******************************************************}
unit Option;

interface

uses Windows, Messages, SysUtils, Classes, Controls, Forms, DB, DBClient, XYCRC, RSA;

type
//*****************************************
//  ����ѡ�����    TOption
//  �ṩѡ��ͨ�ô洢�ӿ�
//*****************************************
  TOption = class
  private
    mLastErrorStr:String;                           //��������
    mOptionFileName:String;                         //�����ļ���
    mClientDataSet:TClientDataSet;                  //��Ҫ�ļ�
  protected
    procedure CreateDefaultOptionXML(OptionFileName:String);     //����Ĭ�ϵ������ļ�

    procedure  AddOptionKey(ModuleName:String;KeyName:String;ValueType:String;Value:String);
    procedure  AddOptionStrKey(ModuleName:String;KeyName:String;Value:String); //���ĳģ����������Ƽ���
    procedure  AddOptionIntKey(ModuleName:String;KeyName:String;Value:Integer); //���ĳģ����������Ƽ���

    function   GetOptionValueEx(ModuleName:String;KeyName:String):String;                  //��ȡ����
    function   GetOptionValue(ModuleName:String;KeyName:String;ValueType:String):String;   //��ȡ����
    function   SetOptionValue(ModuleName:String;KeyName:String;ValueType:String;Value:String):Integer;   //���ò���

    procedure  SetOptionFileName(OptionFileName:String);
    function   GetOptionActived:BOOL;
  public
    constructor Create(OptionFileName:String=''); overload;      //���캯��,Ĭ��ʹ��ʹ������+.config.xml
    destructor Destroy; override;

    function   GetOptionString(ModuleName:String;KeyName:String;Default:String=''):String;   //����ַ�������
    function   GetOptionInt(ModuleName:String;KeyName:String;Default:Integer=0):Integer;     //������ֲ���
    function   GetOptionKeys(ModuleName:String;KeyNames:TStrings):Integer; //���ĳģ����������Ƽ���

    function   SetOptionString(ModuleName:String;KeyName:String;Value:String):Integer;   //����ַ�������
    function   SetOptionInt(ModuleName:String;KeyName:String;Value:Integer):Integer;     //������ֲ���

    function   LoadOptionFile:BOOL;
    function   SaveOptionFile:BOOL;
  published
    property   OptionFileName:String read mOptionFileName write SetOptionFileName;
    property   LastErrorStr:String read mLastErrorStr;
    property   OptionActived:BOOL read GetOptionActived;
  end;

//*****************************************
//  ����ѡ����    TOptionItems
//  �ṩѡ��ͨ�÷��ʽӿ�
//*****************************************
  TChangeEventForOption = procedure(ModuleName:String) of object;

  TOptionItems=class
  private
    m_CurOptionKey:TStrings;
    m_CurOptionValue:TStrings;
    m_CurCRC:Cardinal;
    m_NewOptionKey:TStrings;
    m_NewOptionValue:TStrings;
    m_NewCRC:Cardinal;
    m_Option:TOption;
    m_ModuleName:String;
    m_RunChangEventFlage:BOOL;
    m_OnChangeEventForOption:TChangeEventForOption;
  protected
    function  CalcCRCValue(ParamStr:String):Cardinal;
    procedure AddOption(OptionKey,OptionValue:String);    //New
    procedure LoadOption;
    function  GetOptionIsChanged:BOOL;
  public
    constructor Create(Option:TOption;ModuleName:String); overload;
    destructor Destroy; override;

    procedure ChangedCurrentOption;                      //curr=new

    function  GetOption(OptionKey:String;Default:String=''):String;        //Curr
    procedure SetOption(OptionKey,OptionValue:String);   //New
    procedure FlushOption;

    //�����˼�������ܹ���
    class function   EncryptStr(psw:String):String;  //�����ַ���
    class function   DecryptStr(psw:String):String;  //�����ַ���
  published
    property  IsChanged:BOOL read GetOptionIsChanged;
    property  OnChangeEventForOption:TChangeEventForOption read m_OnChangeEventForOption write m_OnChangeEventForOption;
  end;

  const
  RSA_DEFAULT_CA_PUBLIC_KEY = '++11Ik:FX-nKQd5HffhWpadqr+Geh9Tgtv2MSwCdXT4UiH4ufsFNfkyWh+kiFgTU8jPxqkYh94G5LZWZTw4MHSAhaURqk';
  RSA_DEFAULT_CA_PRIVATE_KEY = 'FX-nKQd5HffhWpadqr+Geh9Tgtv2MSwCdXT4UiH4ufsFNfkyWh+kiFgTU8jPxqkYh94G5LZWZTw4MHSAhaURqk:BU5KMpid-1lQCEqzKXUQe6lL6TnA3zV0vRo9NF6CFeod2RZMdhcph-LSw-BLffV3kcMMpVKoQGSKnH7OW2vN6U';

  TestDigit:TSymKey=($58,$55,$59,$45,$31,$39,$37,$38,$0,$0,$0,$0,$0,$0,$0,$0,
                      $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0);

implementation


constructor TOption.Create(OptionFileName:String='');
begin
  mClientDataSet:=TClientDataSet.Create(nil);
  SetOptionFileName(OptionFileName);
end;

destructor TOption.Destroy;
begin
  mClientDataSet.Close;
  mClientDataSet.Free;
end;

procedure  TOption.CreateDefaultOptionXML(OptionFileName:String);
var
  XMLStr:String;
  XMlStrs:TStringList;
begin
  XMLStr:='<DATAPACKET Version="2.0"><METADATA><FIELDS>'
          +'<FIELD attrname="MODULENAME" fieldtype="STRING" WIDTH="31"/>'
          +'<FIELD attrname="OPTIONKEY" fieldtype="STRING" WIDTH="31"/>'
          +'<FIELD attrname="VLAUETYPE" fieldtype="STRING" WIDTH="31"/>'
          +'<FIELD attrname="VLAUE" fieldtype="STRING" WIDTH="255"/>'
          +'</FIELDS><PARAMS/></METADATA><ROWDATA/></DATAPACKET>';
  XMlStrs:=TStringList.Create;
  XMlStrs.Add(XMLStr);
  try
    XMlStrs.SaveToFile(OptionFileName);
  finally
    XMlStrs.Free;
  end;
end;

procedure  TOption.AddOptionKey(ModuleName:String;KeyName:String;ValueType:String;Value:String);
begin
  if mClientDataSet.Active then
  begin
    mClientDataSet.Insert;
    mClientDataSet.FieldByName('MODULENAME').AsString:=ModuleName;
    mClientDataSet.FieldByName('OPTIONKEY').AsString:=KeyName;
    mClientDataSet.FieldByName('VLAUETYPE').AsString:=ValueType;
    mClientDataSet.FieldByName('VLAUE').AsString:=Value;
    mClientDataSet.Post;
  end;
end;

procedure  TOption.AddOptionStrKey(ModuleName:String;KeyName:String;Value:String);
begin
  AddOptionKey(ModuleName,KeyName,'STRING',Value);
end;

procedure  TOption.AddOptionIntKey(ModuleName:String;KeyName:String;Value:Integer);
begin
  AddOptionKey(ModuleName,KeyName,'INT',IntToStr(Value));
end;

function   TOption.GetOptionValue(ModuleName:String;KeyName:String;ValueType:String):String;
begin
  Result:='';
  if not mClientDataSet.Active then
    exit;
  mClientDataSet.First;
  while not mClientDataSet.Eof do
  begin
    if ((mClientDataSet.FieldByName('MODULENAME').AsString=ModuleName)
      and (mClientDataSet.FieldByName('OPTIONKEY').AsString=KeyName)
      and (mClientDataSet.FieldByName('VLAUETYPE').AsString=ValueType)) then
    begin
      Result:=mClientDataSet.FieldByName('VLAUE').AsString;
      break;
    end;
    mClientDataSet.Next;
  end;
end;

function TOption.GetOptionValueEx(ModuleName:String;KeyName:String):String;
begin
  Result:='';
  if not mClientDataSet.Active then
    exit;
  mClientDataSet.First;
  while not mClientDataSet.Eof do
  begin
    if ((mClientDataSet.FieldByName('MODULENAME').AsString=ModuleName)
      and (mClientDataSet.FieldByName('OPTIONKEY').AsString=KeyName)) then
    begin
      Result:=mClientDataSet.FieldByName('VLAUE').AsString;
      break;
    end;
    mClientDataSet.Next;
  end;
end;

procedure  TOption.SetOptionFileName(OptionFileName:String);
begin
  if ((Trim(OptionFileName)='') and (mOptionFileName='')) then
    mOptionFileName:=Application.ExeName+'.Config.xml'
  else
  begin
    if mOptionFileName='' then
      mOptionFileName:=OptionFileName;
  end;
end;

function   TOption.GetOptionActived:BOOL;
begin
  Result:=mClientDataSet.Active;
end;

function   TOption.GetOptionString(ModuleName:String;KeyName:String;Default:String):String;
begin
  Result:=GetOptionValue(ModuleName,KeyName,'STRING');
  if Result='' then
    Result:=Default;
end;

function   TOption.GetOptionInt(ModuleName:String;KeyName:String;Default:Integer):Integer;
var
  sResult:String;
begin
  Result:=Default;
  sResult:=GetOptionValue(ModuleName,KeyName,'STRING');
  if (not (sResult='')) then
  begin
    try
      Result:=StrToInt(sResult);
    except
      ;
    end;
  end;
end;

function   TOption.GetOptionKeys(ModuleName:String;KeyNames:TStrings):Integer;
begin
  Result:=0;
  if ((not mClientDataSet.Active) or (KeyNames=nil)) then
    exit;

  mClientDataSet.First;
  while not mClientDataSet.Eof do
  begin
    if mClientDataSet.FieldByName('MODULENAME').AsString=ModuleName then
    begin
      KeyNames.Add(mClientDataSet.FieldByName('OPTIONKEY').AsString);
    end;
    mClientDataSet.Next;
  end;
  Result:=KeyNames.Count;
end;

function  TOption.SetOptionValue(ModuleName:String;KeyName:String;ValueType:String;Value:String):Integer;
var
  IsEdit:BOOL;
begin
  Result:=0;
  if not mClientDataSet.Active then
    exit;

  IsEdit:=False;
  mClientDataSet.First;
  while not mClientDataSet.Eof do
  begin
    if ((mClientDataSet.FieldByName('MODULENAME').AsString=ModuleName)
      and (mClientDataSet.FieldByName('OPTIONKEY').AsString=KeyName)
      and (mClientDataSet.FieldByName('VLAUETYPE').AsString=ValueType)) then
    begin
      if mClientDataSet.FieldByName('VLAUE').AsString<>Value then
      begin
        mClientDataSet.Edit;
        mClientDataSet.FieldByName('VLAUE').AsString:=Value;
        mClientDataSet.Post;
        Result:=1;
      end;
      IsEdit:=True;
      break;
    end;
    mClientDataSet.Next;
  end;
  if not IsEdit then
  begin
    AddOptionKey(ModuleName,KeyName,ValueType,Value);
    Result:=1;
  end;
end;

function   TOption.SetOptionString(ModuleName:String;KeyName:String;Value:String):Integer;
begin
  Result:=SetOptionValue(ModuleName,KeyName,'STRING',Value);
end;

function   TOption.SetOptionInt(ModuleName:String;KeyName:String;Value:Integer):Integer;
begin
  Result:=SetOptionValue(ModuleName,KeyName,'INT',IntToStr(Value));
end;

function   TOption.LoadOptionFile():BOOL;
begin
  Result:=False;
  try
    if not FileExists(mOptionFileName) then
      CreateDefaultOptionXML(mOptionFileName);
    mClientDataSet.FileName:=mOptionFileName;
    mClientDataSet.Active:=True;
    Result:=True;
  except
    on E:Exception do
      mLastErrorStr:=E.Message;
  end;
end;

function   TOption.SaveOptionFile():BOOL;
begin
  Result:=False;
  try
    mClientDataSet.MergeChangeLog;
    mClientDataSet.SaveToFile(mOptionFileName,dfXML);
    mClientDataSet.Active:=False;
    mClientDataSet.Active:=True;
    Result:=True;
  except
    ;
  end;
end;

{TOptionItems}
function  TOptionItems.CalcCRCValue(ParamStr:String):Cardinal;
begin
  if not (ParamStr='') then
    Result:=crc32(0,PByte(PChar(ParamStr)),Length(ParamStr))
  else
    Result:=0;
end;

procedure TOptionItems.AddOption(OptionKey,OptionValue:String);    //New
begin
  m_NewOptionKey.Add(OptionKey);
  m_NewOptionValue.Add(OptionValue);
  m_NewCRC:=CalcCRCValue(m_NewOptionValue.Text);
end;

procedure TOptionItems.LoadOption;
var
  i:Integer;
begin
  if Assigned(m_Option) then
  begin
    m_NewOptionKey.Clear;
    m_NewOptionValue.Clear;

    m_Option.GetOptionKeys(m_ModuleName,m_NewOptionKey);
    for i:=0 to (m_NewOptionKey.Count-1) do
       m_NewOptionValue.Add(m_Option.GetOptionValueEx(m_ModuleName,m_NewOptionKey[i]));
    m_NewCRC:=CalcCRCValue(m_NewOptionValue.Text);
  end;
end;

function  TOptionItems.GetOptionIsChanged:BOOL;
begin
  Result:=False;
  if (m_CurCRC<>m_NewCRC) then
    Result:=True;
end;

constructor TOptionItems.Create(Option:TOption;ModuleName:String);
var
  mytest,mytest2,mytest3:String;

begin
  m_CurOptionKey:=TStringList.Create;
  m_CurOptionValue:=TStringList.Create;
  m_CurCRC:=0;
  m_NewOptionKey:=TStringList.Create;
  m_NewOptionValue:=TStringList.Create;
  m_NewCRC:=0;
  m_Option:=Option;
  m_ModuleName:=ModuleName;
  m_RunChangEventFlage:=True;
  m_OnChangeEventForOption:=nil;

  LoadOption;
  ChangedCurrentOption;
end;

destructor TOptionItems.Destroy;
begin
  FlushOption;
  m_CurOptionKey.Free;
  m_CurOptionValue.Free;
  m_NewOptionKey.Free;
  m_NewOptionValue.Free;
  m_Option:=nil;
end;

procedure TOptionItems.ChangedCurrentOption;                      //curr=new
begin
  m_CurOptionKey.Clear;
  m_CurOptionKey.AddStrings(m_NewOptionKey);
  m_CurOptionValue.Clear;
  m_CurOptionValue.AddStrings(m_NewOptionValue);
  m_CurCRC:=m_NewCRC;
end;

function  TOptionItems.GetOption(OptionKey:String;Default:String):String;        //Curr
var
  Index:Integer;
begin
  Index:=m_CurOptionKey.IndexOf(OptionKey);
  if Index>=0 then
    Result:=m_CurOptionValue[Index]
  else
  begin
    SetOption(OptionKey,Default);
    Result:=Default;
  end;
end;

procedure TOptionItems.SetOption(OptionKey,OptionValue:String);   //New
var
  Index:Integer;
begin
  Index:=m_NewOptionKey.IndexOf(OptionKey);
  if Index>=0 then
  begin
    if m_NewOptionValue[Index]=OptionValue then
      exit;
    m_NewOptionValue[Index]:=OptionValue;
  end
  else
  begin
    AddOption(OptionKey,OptionValue);
  end;
  m_NewCRC:=CalcCRCValue(m_NewOptionValue.Text);
  if GetOptionIsChanged then
  begin
    if (m_RunChangEventFlage and Assigned(m_OnChangeEventForOption)) then
      m_OnChangeEventForOption(m_ModuleName);
  end;
end;

procedure TOptionItems.FlushOption;
var
  i:Integer;
begin
  if Assigned(m_Option) then
  begin
    for i:=0 to (m_CurOptionKey.Count-1) do
      begin
         m_Option.SetOptionValue(m_ModuleName,m_CurOptionKey[i],'STRING',m_CurOptionValue[i]);
      end;
    m_Option.SaveOptionFile;      
  end;
end;

//�����˼�������ܹ���
class function  TOptionItems.EncryptStr(psw:String):String;  //�����ַ���
var
  m_Rsa:TRSA;
  TestKey:TSymKey;
  i:Integer;
  ErrorInfo:String;
begin
  m_Rsa:=TRsa.Create(nil);
  m_Rsa.KeyBits := kb0512;
  m_Rsa.Status := 'TRSA using 512 bit key';
  m_Rsa.SymKeyLength := sk64;

  //���鹫Կ˽Կ��
  m_Rsa.PrivateKey:=RSA_DEFAULT_CA_PRIVATE_KEY;
  m_Rsa.PublicKey:=RSA_DEFAULT_CA_PUBLIC_KEY;

  m_Rsa.DecryptKey(m_Rsa.EncryptKey(TestDigit),TestKey);

  for i:=0 to (SizeOf(TestDigit)-1) do
  begin
    if TestDigit[i]<>TestKey[i] then
      begin
        m_Rsa.Free;
        ErrorInfo:='��Կ�Լ�����';
        raise Exception.Create(ErrorInfo);
        Exit;
      end;
  end;

  //��ժҪ��������ǩ��,ʹ��RSA˽Կ����
  try
    m_Rsa.EncryptString(psw,Result);
  except
    ;
  end;
  m_Rsa.Free;
end;

class function  TOptionItems.DecryptStr(psw:String):String;  //�����ַ���
var
  m_Rsa:TRSA;
  TestKey:TSymKey;
  i:Integer;
  ErrorInfo:String;
begin
  m_Rsa:=TRsa.Create(nil);
  m_Rsa.KeyBits := kb0512;
  m_Rsa.Status := 'TRSA using 512 bit key';
  m_Rsa.SymKeyLength := sk64;

  //���鹫Կ˽Կ��
  m_Rsa.PrivateKey:=RSA_DEFAULT_CA_PRIVATE_KEY;
  m_Rsa.PublicKey:=RSA_DEFAULT_CA_PUBLIC_KEY;

  m_Rsa.DecryptKey(m_Rsa.EncryptKey(TestDigit),TestKey);

  for i:=0 to (SizeOf(TestDigit)-1) do
  begin
    if TestDigit[i]<>TestKey[i] then
      begin
        m_Rsa.Free;
        ErrorInfo:='��Կ�Լ�����';
        raise Exception.Create(ErrorInfo);
        Exit;
      end;
  end;

  //��ժҪ��������ǩ��,ʹ��RSA˽Կ����
  try
    m_Rsa.DecryptString(psw,Result);
  except
    ;
  end;
  m_Rsa.Free;
end;

end.
