program ThreadsInThreads;

uses
  Vcl.Forms,
  uThreadsInThreadsMain in 'uThreadsInThreadsMain.pas' {ThreadsInThreadsMain},
  uShowPicture in 'uShowPicture.pas' {ShowPicture},
  Vcl.Themes,
  Vcl.Styles,
  uScale in '..\..\Resampler\uScale.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uDirectoryTree in '..\..\Utilities\UtilitiesVCL\uDirectoryTree.pas',
  uTools in '..\..\Utilities\UtilitiesVCL\uTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 SlateGray');
  Application.CreateForm(TThreadsInThreadsMain, ThreadsInThreadsMain);
  Application.CreateForm(TShowPicture, ShowPicture);
  Application.Run;
end.
