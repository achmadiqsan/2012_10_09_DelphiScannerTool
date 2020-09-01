(**
 * Delphi 2009 Scanning tool
 *
 * @package DelphiTwain Example
 * @link http://a32.me/
 * @author Constantin V. Bosneaga, Contact: ameoba32@gmail.com
**)


unit unMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, ShellCtrls, Buttons,
  delphitwain, iniFiles, Menus, ExtDlgs, jpeg, ImgList, ActnList;

type
  TfmMain = class(TForm)
    Panel1: TPanel;
    cbSource: TComboBox;
    Label1: TLabel;
    BotScan: TBitBtn;
    tmScan: TTimer;
    sb: TStatusBar;
    ContainImage: TScrollBox;
    BotAdditional: TBitBtn;
    pnAdditional: TPanel;
    Label2: TLabel;
    cbDPI: TComboBox;
    Label3: TLabel;
    cbColor: TComboBox;
    cbShowUI: TCheckBox;
    BotRotateClockUnW: TBitBtn;
    SavePictureDialog1: TSavePictureDialog;
    BotSaveImageAs: TBitBtn;
    BotRotateClockW: TBitBtn;
    Image1: TImage;
    ChkAutoSave: TCheckBox;
    BotSaveImage: TBitBtn;
    ActLstForm: TActionList;
    ActBotSaveImage: TAction;
    ActBotRotateAntiClockWise: TAction;
    ActBotRotateClockWise: TAction;
    ActBotScan: TAction;
    ActBotSaveImageAs: TAction;
    procedure FormShow(Sender: TObject);
    procedure tmScanTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BotAdditionalClick(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ActBotSaveImageExecute(Sender: TObject);
    procedure ActBotSaveImageUpdate(Sender: TObject);
    procedure ActBotRotateClockWiseExecute(Sender: TObject);
    procedure ActBotRotateClockWiseUpdate(Sender: TObject);
    procedure ActBotScanExecute(Sender: TObject);
    procedure ActBotScanUpdate(Sender: TObject);
    procedure ActBotSaveImageAsExecute(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    {Position when the user clicks over the image}
    ClickPos: TPoint;

    twain : TDelphiTwain;
    scanState : String;
    errorText : String;
    twainSource : Integer;
    FImageChanged: boolean;

    function BMPtoJPG(BitMap: TBitmap; PathToSaveJPG: string): boolean;
    procedure ZoomImage(Perc: cardinal);
    function SZRotateBmp90(Src, Dest: TBitmap; ClockWise: Boolean; Container: TImage=nil): Boolean;
  public
    procedure OnTwainAcquire(Sender: TObject; const Index: Integer; Image: TBitmap; var Cancel: Boolean);
    property ImageChanged: boolean read FImageChanged write FImageChanged;
  end;

var
  fmMain: TfmMain;

implementation

uses Twain;

{$R *.dfm}


procedure TfmMain.ActBotRotateClockWiseExecute(Sender: TObject);
begin
  if TAction(Sender).Name = 'ActBotRotateClockWise' then
    SZRotateBmp90(Image1.Picture.Bitmap , Image1.Picture.Bitmap , True, Image1)
  else
    SZRotateBmp90(Image1.Picture.Bitmap , Image1.Picture.Bitmap , False, Image1);

  ImageChanged := True;

  Self.FormResize(sender);

{  //Questo codice funziona VERAMENTE e fa il Flip Orizzontale e verticale

  if TButton(Sender).Name = 'BotFlipVrt' then
    Image1.Canvas.StretchDraw( Rect( 0, Image1.Height, Image1.Width, 0 ) , Image1.Picture.Bitmap )
  else
    Image1.Canvas.StretchDraw( Rect( Image1.Width, 0, 0, Image1.Height ) , Image1.Picture.Bitmap );
}
end;

procedure TfmMain.ActBotRotateClockWiseUpdate(Sender: TObject);
begin
  Taction(sender).Enabled := (scanState='idle');
end;

procedure TfmMain.ActBotSaveImageExecute(Sender: TObject);
begin
  ActBotSaveImageAsExecute(sender);
end;

procedure TfmMain.ActBotSaveImageUpdate(Sender: TObject);
begin
  Taction(sender).Enabled := (ImageChanged) and (scanState='idle');
end;

procedure TfmMain.ActBotScanExecute(Sender: TObject);
begin
  scanState := 'start';
  sb.Panels[1].Text := '';
end;

procedure TfmMain.ActBotScanUpdate(Sender: TObject);
begin
  Taction(sender).Enabled := (scanState='idle') or (scanState='');
end;

procedure TfmMain.ActBotSaveImageAsExecute(Sender: TObject);
begin

  if FileExists( sb.Panels[1].Text ) then
  begin
    SavePictureDialog1.FileName := sb.Panels[1].Text;

    if TBitBtn(sender).Name = 'ActBotSaveImage' then
    begin
      BMPtoJPG( Image1.Picture.Bitmap ,  SavePictureDialog1.FileName );
      ImageChanged := False;
      Exit;
    end;
  end else
    SavePictureDialog1.FileName := '';


  if SavePictureDialog1.Execute then
  begin
    BMPtoJPG( Image1.Picture.Bitmap ,  SavePictureDialog1.FileName );

    sb.Panels[1].Text := SavePictureDialog1.FileName;
    ImageChanged := False;
  end;

end;

function TfmMain.BMPtoJPG(BitMap: TBitmap; PathToSaveJPG: string): boolean;
var
  JpegImg: TJpegImage;
begin
  Result:=False;

  try
    JpegImg := TJpegImage.Create;

    JpegImg.Assign(BitMap) ;
    JpegImg.SaveToFile(PathToSaveJPG) ;

    Result:=True;
  finally
    JpegImg.Free
  end;

end;


procedure TfmMain.BotAdditionalClick(Sender: TObject);
begin
  pnAdditional.Visible := Not pnAdditional.Visible;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  twain.free;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  // Create twain driver
  twain := TDelphiTwain.Create(nil);
  Twain.OnTwainAcquire := OnTwainAcquire;

   //TODO: OnAcquireCancel
   Twain.TransferMode := ttmMemory;
   //Twain.Info.MinorVersion := 0;
//    Twain.Info.Language := tlUserLocale;
//   Twain.Info.CountryCode := 1;
//   Twain.Info.Groups := [tgControl, tgImage];
//   Twain.Info.VersionInfo := 'Application name';
//   Twain.Info.Manufacturer := 'Application manufacturer';
//   Twain.Info.ProductFamily := 'App product family';
//   Twain.Info.ProductName := 'App product name';
//   Twain.LibraryLoaded := False;
//   Twain.SourceManagerLoaded := False;
end;


procedure TfmMain.FormResize(Sender: TObject);
begin
  ClickPos.X := 0; ClickPos.Y := 0;
  Image1MouseMove(Self, [ssLeft], 0, 0);
end;

procedure TfmMain.FormShow(Sender: TObject);
Var
  I : Integer;
  TmpScanDir: string;
begin
  if Twain.LoadLibrary then begin
    Twain.LoadSourceManager;
    for i  := 0 to Twain.SourceCount - 1 do
      cbSource.Items.Add( Twain.Source[i].ProductName );
//    NewSource := Twain.SelectSource;
    Twain.UnloadLibrary;
  end;

  cbSource.ItemIndex := cbSource.Items.Count-1;
  cbColor.ItemIndex := 1;
  cbDPI.ItemIndex := 2;

  TmpScanDir := ExtractFilePath(Application.ExeName) + 'ScanFile';
  if NOT DirectoryExists( TmpScanDir ) then
    CreateDir( TmpScanDir );

  SavePictureDialog1.InitialDir := TmpScanDir;
  ImageChanged := False;

end;

procedure TfmMain.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ClickPos.x := X;
  ClickPos.y := Y;
end;

procedure TfmMain.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
Const
  SpessoreScrollBar: Integer= 20;  //19
var
  NewPos: TPoint;
begin
  {The left button was pressed}
  with Image1 do
    if ssLeft in Shift then
    begin
      {Calculate new position}
      NewPos.X := Left + x - ClickPos.x;
      NewPos.Y := Top + y - ClickPos.y;
      if NewPos.x + Width < ContainImage.Width-SpessoreScrollBar then
        NewPos.x := ContainImage.Width-SpessoreScrollBar - Width;
      if NewPos.y + Height < ContainImage.Height-SpessoreScrollBar then
        NewPos.y := ContainImage.Height-SpessoreScrollBar - Height;
      if NewPos.X > 0 then
        NewPos.X := 0;
      if NewPos.Y > 0 then
        NewPos.Y := 0;

      Top := NewPos.Y;
      Left := NewPos.X;

    end {if ssLeft in Shift}
end;

procedure TfmMain.OnTwainAcquire(Sender: TObject; const Index: Integer;  Image: TBitmap; var Cancel: Boolean);
var
  NomeFileScan: string;
begin
  Image1.Width := Image.Width;
  Image1.Height := Image.Height;

  with Image1.Picture.Bitmap do begin
    Assign(Image);
    PixelFormat := pf24bit;

    if (ChkAutoSave.Checked) and (SavePictureDialog1.initialDir<>'') then
    begin
      NomeFileScan := SavePictureDialog1.initialDir + '\' + FormatDateTime( 'yyyy_mm_dd__hh_nn_ss' , Now() ) +'__ScanFile.jpg';
      BMPtoJPG( Image1.Picture.Bitmap ,  NomeFileScan );
      sb.Panels[1].Text := NomeFileScan;
      ImageChanged := False;
    end else
      ImageChanged := True;


  end;
end;

procedure TfmMain.tmScanTimer(Sender: TObject);
begin
  tmScan.Enabled := False;

  repeat
  if (scanState = 'idle') OR (scanState = '') then begin
    sb.Panels[0].Text := '';
    break;
  end;

  if (scanState = 'error') then begin
    sb.Panels[0].Text := 'Error: ' + errorText;
    break;
  end;

  if (scanState = 'start') then begin
    twainSource := cbSource.ItemIndex;
    if (twainSource = -1) then begin
      ScanState := 'error';
      errorText := 'No scanner selected';
      break;
    end;

    sb.Panels[0].Text := 'Scanning...';
    {Load library, source manager and source}
    Twain.LoadLibrary;
    Twain.LoadSourceManager;

    Twain.Source[ twainSource ].Loaded := TRUE;
    Twain.Source[ twainSource].TransferMode := ttmMemory;

    // Add additional parameters
    if (pnAdditional.Visible) then begin
      if cbColor.ItemIndex = 0 then Twain.Source[ twainSource ].SetIPixelType( tbdBw );
      if cbColor.ItemIndex = 1 then Twain.Source[ twainSource ].SetIPixelType(tbdGray);
      if cbColor.ItemIndex = 2 then Twain.Source[ twainSource ].SetIPixelType(tbdRgb);

      Twain.Source[ twainSource ].SetIBitDepth( StrToInt(cbDPI.Items[cbDPI.ItemIndex]) );
      Twain.Source[ twainSource ].ShowUI := cbShowUI.Checked;

    end;

    Twain.Source[ twainSource ].EnableSource( cbShowUI.Checked , false);
    scanState := 'scan';
    break;
  end;

  if (scanState = 'scan') then
  begin
    if (not Twain.Source[twainSource].Enabled) then begin
      Twain.UnloadLibrary;
      scanState := 'done';
    end;
    break;
  end;

  if (scanState = 'done') then begin
    sb.Panels[0].Text := 'Done.';
    scanState := 'idle';
    SetFocus;
    break;
  end;

  until false;

  tmScan.Enabled := True;
end;

procedure TfmMain.ZoomImage(Perc: cardinal);
const
  maxWidth = 200;
  maxHeight = 150;
 var
  thumbnail : TBitmap;
  thumbRect : TRect;
begin
  thumbnail := Image1.Picture.Bitmap;
  try
    thumbRect.Left := 0;
    thumbRect.Top  := 0;

    //proportional resize
    if thumbnail.Width > thumbnail.Height then
    begin
      thumbRect.Right := Image1.Width*2;
      thumbRect.Bottom := Image1.Height*2;
    end
    else begin
      thumbRect.Right := Image1.Width*2;
      thumbRect.Bottom := Image1.Height*2;
    end;

    Image1.Width := Image1.Width*2;
    Image1.Height := Image1.Height*2;

    thumbnail.Canvas.StretchDraw(thumbRect, Image1.Picture.Bitmap) ;

    //resize image
    thumbnail.Width := thumbRect.Right;
    thumbnail.Height := thumbRect.Bottom;

    //display in a TImage control
    Image1.Picture.Assign(thumbnail) ;
  finally
    //thumbnail.Free;
  end;
end;



function TfmMain.SZRotateBmp90(Src, Dest: TBitmap; ClockWise: Boolean; Container: TImage=nil ): Boolean;
var
  x, y    : integer;
  dY      : array of PDWORD; // Array for destination scanline
  sH, dH  : integer;         // Height variables
  P       : PDWORD;          // Source pointer
  BmpTmp : TBitmap;
begin
  //Creo un oggetto BitMap e lo riempio con l'immagine destinazione in modo da dupplicare l'immagine destinazione stessa
  BmpTmp := TBitmap.Create;
  BmpTmp.Assign(Dest);

  with BmpTmp do
  begin

    if Src.PixelFormat<>pf32bit then
      Src.PixelFormat := pf32bit;

    if PixelFormat<>pf32bit then
      PixelFormat := pf32bit;

    try
      Width := Src.Height;
      Height := Src.Width;
      sH := Src.Height-1;
      dH := Height-1;

      // Initialize dynamic array
      SetLength(DY,dH+1);

      // Save pointers to array for acceleration
      for y := 0 to dH do
        DY[y] := ScanLine[y];

      if ClockWise then

        // Copy Src horizontal lines to be Dest vertical by +90 degree
        for y := sh downto 0 do
        begin
          P:=Src.ScanLine[y];
          for x := 0 to dH do
          begin
            Dy[x]^:=P^;
            inc(Dy[x]);
            inc(P);
          end;
        end

      else

        // Copy Src horizontal lines to be Dest vertical by -90 degree
        for y := 0 to sH do
        begin
          P:=Src.ScanLine[y];
          for x := dH downto 0 do
          begin
            Dy[x]^:=P^;
            inc(Dy[x]);
            inc(P);
          end;
        end;


    finally
      SetLength(DY,0);

      //copio la BitMap temporanea nella BitMap destinazione e distruggo la temporanea
      if assigned(Container) then
      begin
        Container.Width  := Width;
        Container.Height := Height;
      end;

      Dest.Assign( BmpTmp );
      FreeAndNil ( BmpTmp );
    end;

  end;

end;

end.
