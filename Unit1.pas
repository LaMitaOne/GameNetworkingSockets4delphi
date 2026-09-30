unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, GameNetworkingSockets;

{==============================================================================*
 *  GameNetworkingSockets Test Application
 *------------------------------------------------------------------------------
 *  Author : Lara Miriam Tamy Reschke / LamitaOne
 *  License MIT
 *  Description:
 *    A VCL application demonstrating how to dynamically load and use the
 *    GameNetworkingSockets DLL. It creates a local server and client within
 *    the same application to test ping, message sending, and status updates.
 *=============================================================================}

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnCreateSocketClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnRunCallbacksClick(Sender: TObject);
    procedure btnSendMessageClick(Sender: TObject);
    procedure btnCheckStatusClick(Sender: TObject);
  private
    Memo1: TMemo;
    Panel1: TPanel;
    btnInit: TButton;
    btnCreateSocket: TButton;
    btnConnect: TButton;
    btnRunCallbacks: TButton;
    btnSendMessage: TButton;
    btnCheckStatus: TButton;

    FSocketInterface: ISteamNetworkingSockets;
    FUtilsInterface: ISteamNetworkingUtils;
    FListenSocket: HSteamListenSocket;
    FClientConnection: HSteamNetConnection;
    FPollGroup: HSteamNetPollGroup;

    procedure Log(Msg: string);
    procedure InitUI;
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption := 'GameNetworkingSockets Delphi Test App';
  Position := poScreenCenter;
  Width := 800;
  Height := 600;
  InitUI;
end;

procedure TForm1.InitUI;
begin
  Panel1 := TPanel.Create(Self);
  Panel1.Parent := Self;
  Panel1.Align := alTop;
  Panel1.Height := 40;
  Panel1.BevelOuter := bvNone;
  Panel1.Caption := '';

  Memo1 := TMemo.Create(Self);
  Memo1.Parent := Self;
  Memo1.Align := alClient;
  Memo1.ScrollBars := ssVertical;
  Memo1.ReadOnly := True;
  Memo1.Font.Name := 'Consolas';
  Memo1.Font.Size := 10;

  btnInit := TButton.Create(Self);
  btnInit.Parent := Panel1;
  btnInit.SetBounds(10, 8, 110, 25);
  btnInit.Caption := '1. Init DLL';
  btnInit.OnClick := btnInitClick;

  btnCreateSocket := TButton.Create(Self);
  btnCreateSocket.Parent := Panel1;
  btnCreateSocket.SetBounds(130, 8, 110, 25);
  btnCreateSocket.Caption := '2. Start Server';
  btnCreateSocket.OnClick := btnCreateSocketClick;
  btnCreateSocket.Enabled := False;

  btnConnect := TButton.Create(Self);
  btnConnect.Parent := Panel1;
  btnConnect.SetBounds(250, 8, 110, 25);
  btnConnect.Caption := '3. Connect Client';
  btnConnect.OnClick := btnConnectClick;
  btnConnect.Enabled := False;

  btnRunCallbacks := TButton.Create(Self);
  btnRunCallbacks.Parent := Panel1;
  btnRunCallbacks.SetBounds(370, 8, 110, 25);
  btnRunCallbacks.Caption := '4. Run Callbacks';
  btnRunCallbacks.OnClick := btnRunCallbacksClick;
  btnRunCallbacks.Enabled := False;

  btnSendMessage := TButton.Create(Self);
  btnSendMessage.Parent := Panel1;
  btnSendMessage.SetBounds(490, 8, 110, 25);
  btnSendMessage.Caption := '5. Send Message';
  btnSendMessage.OnClick := btnSendMessageClick;
  btnSendMessage.Enabled := False;

  btnCheckStatus := TButton.Create(Self);
  btnCheckStatus.Parent := Panel1;
  btnCheckStatus.SetBounds(610, 8, 130, 25);
  btnCheckStatus.Caption := '6. Check Status';
  btnCheckStatus.OnClick := btnCheckStatusClick;
  btnCheckStatus.Enabled := False;
end;

procedure TForm1.Log(Msg: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      Memo1.Lines.Add('[' + TimeToStr(Now) + '] ' + Msg);
      SendMessage(Memo1.Handle, EM_SCROLLCARET, 0, 0);
    end);
end;

procedure TForm1.btnInitClick(Sender: TObject);
var
  ErrMsg: SteamNetworkingErrMsg;
begin
  Log('Loading DLL dynamically...');
  if not LoadGameNetworkingSocketsDLL then
  begin
    Log('ERROR: DLL not found!');
    Exit;
  end;

  if Assigned(GameNetworkingSockets_Init) then
  begin
    if GameNetworkingSockets_Init(nil, @ErrMsg) then
      Log('Initialization successful!')
    else
    begin
      Log('ERROR during Init: ' + string(PAnsiChar(@ErrMsg)));
      Exit;
    end;
  end
  else
  begin
    Log('ERROR: Init function missing in DLL!');
    Exit;
  end;

  if Assigned(SteamAPI_SteamNetworkingSockets_v009) then
    FSocketInterface := SteamAPI_SteamNetworkingSockets_v009()
  else
  begin
    Log('ERROR: Sockets Interface missing!');
    Exit;
  end;

  Log('System ready.');
  btnInit.Enabled := False;
  btnCreateSocket.Enabled := True;
  btnConnect.Enabled := True;
  btnRunCallbacks.Enabled := True;
  btnSendMessage.Enabled := True;
  btnCheckStatus.Enabled := True;
end;

procedure TForm1.btnCreateSocketClick(Sender: TObject);
var
  LocalAddr: SteamNetworkingIPAddr;
begin
  if FSocketInterface = nil then
    Exit;

  SteamAPI_SteamNetworkingIPAddr_Clear(@LocalAddr);
  SteamAPI_SteamNetworkingIPAddr_SetIPv4(@LocalAddr, $7F000001, 27015);

  FListenSocket := SteamAPI_ISteamNetworkingSockets_CreateListenSocketIP(FSocketInterface, @LocalAddr, 0, nil);

  if FListenSocket <> 0 then
  begin
    Log('Server listening on 127.0.0.1:27015');
    // Create a Poll Group for receiving messages (Standard Valve v009 API)
    FPollGroup := SteamAPI_ISteamNetworkingSockets_CreatePollGroup(FSocketInterface);
  end
  else
    Log('ERROR: Server could not be started!');
end;

procedure TForm1.btnConnectClick(Sender: TObject);
var
  Addr: SteamNetworkingIPAddr;
begin
  if FSocketInterface = nil then
    Exit;

  SteamAPI_SteamNetworkingIPAddr_Clear(@Addr);
  SteamAPI_SteamNetworkingIPAddr_SetIPv4(@Addr, $7F000001, 27015);

  FClientConnection := SteamAPI_ISteamNetworkingSockets_ConnectByIPAddress(FSocketInterface, @Addr, 0, nil);

  if FClientConnection <> 0 then
  begin
    Log('Client connecting...');
    // Assign the connection to our poll group so we can receive messages
    if (FPollGroup <> 0) and Assigned(SteamAPI_ISteamNetworkingSockets_SetConnectionPollGroup) then
      SteamAPI_ISteamNetworkingSockets_SetConnectionPollGroup(FSocketInterface, FClientConnection, FPollGroup);
  end
  else
    Log('ERROR: Connection attempt failed!');
end;

procedure TForm1.btnRunCallbacksClick(Sender: TObject);
var
  Msgs: array[0..9] of PSteamNetworkingMessage_t;
  NumMsgs, i: Integer;
  PMsg: PSteamNetworkingMessage_t;
  MsgStr: AnsiString;
begin
  if FSocketInterface = nil then
    Exit;

  // 1. Run callbacks to process connection state changes
  SteamAPI_ISteamNetworkingSockets_RunCallbacks(FSocketInterface);

  // 2. Receive messages via the Poll Group (Correct API for v009)
  if (FPollGroup <> 0) and Assigned(SteamAPI_ISteamNetworkingSockets_ReceiveMessagesOnPollGroup) then
  begin
    NumMsgs := SteamAPI_ISteamNetworkingSockets_ReceiveMessagesOnPollGroup(FSocketInterface, FPollGroup, @Msgs[0], 10);
    for i := 0 to NumMsgs - 1 do
    begin
      PMsg := Msgs[i];
      if Assigned(PMsg) then
      begin
        SetString(MsgStr, PAnsiChar(PMsg^.m_pData), PMsg^.m_cbSize);
        Log('Message received: ' + string(MsgStr));
        SteamAPI_SteamNetworkingMessage_t_Release(PMsg);
      end;
    end;
  end;

  Log('Callbacks executed.');
end;

procedure TForm1.btnSendMessageClick(Sender: TObject);
var
  TestMsg: AnsiString;
  Res: EResult;
begin
  if (FSocketInterface = nil) or (FClientConnection = 0) then
  begin
    Log('No active client connection!');
    Exit;
  end;

  TestMsg := 'Hello from Delphi!';
  // k_nSteamNetworkingSend_Reliable = 8
  Res := SteamAPI_ISteamNetworkingSockets_SendMessageToConnection(FSocketInterface, FClientConnection, @TestMsg[1], Length(TestMsg), 8, nil);

  if Res = 1 then // k_EResultOK
    Log('Message sent!')
  else
    Log('ERROR sending message, Code: ' + IntToStr(Res));
end;

procedure TForm1.btnCheckStatusClick(Sender: TObject);
var
  Status: SteamNetConnectionRealTimeStatus_t;
  Res: EResult;
begin
  if (FSocketInterface = nil) or (FClientConnection = 0) then
    Exit;

  FillChar(Status, SizeOf(Status), 0);
  Res := SteamAPI_ISteamNetworkingSockets_GetConnectionRealTimeStatus(FSocketInterface, FClientConnection, @Status, 0, nil);

  if Res = 1 then
  begin
    Log('--- Client Connection Status ---');
    Log('State: ' + IntToStr(Status.m_eState) + ' (3 = Connected)');
    Log('Ping: ' + IntToStr(Status.m_nPing) + ' ms');
    Log('Send Rate: ' + IntToStr(Status.m_nSendRateBytesPerSecond) + ' B/s');
  end
  else
    Log('ERROR getting status, Code: ' + IntToStr(Res));
end;

end.

