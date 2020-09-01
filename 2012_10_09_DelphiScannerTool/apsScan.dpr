(**
 * Delphi 2009 Scanning tool
 *
 * @package DelphiTwain Example
 * @link http://a32.me/
 * @author Constantin V. Bosneaga, Contact: ameoba32@gmail.com
**)
program apsScan;

uses
  ExceptionLog,
  Windows,
  SysUtils,
  Forms,
  unMain in 'unMain.pas' {fmMain},
  DelphiTwain in 'delphitwain\DelphiTwain.pas',
  DelphiTwainUtils in 'delphitwain\DelphiTwainUtils.pas',
  Twain in 'delphitwain\Twain.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Title := fmMain.Caption;
  Application.Run;
end.
