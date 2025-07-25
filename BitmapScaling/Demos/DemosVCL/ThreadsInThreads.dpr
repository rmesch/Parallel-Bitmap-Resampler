program ThreadsInThreads;
uses
  Vcl.Forms,
  uThreadsInThreadsMain in 'uThreadsInThreadsMain.pas' {ThreadsInThreadsMain},
  uShowPicture in 'uShowPicture.pas' {ShowPicture},
  uDirectoryTree in '..\..\Utilities\UtilitiesVCL\uDirectoryTree.pas',
  uTools in '..\..\Utilities\UtilitiesVCL\uTools.pas',
  uScale in '..\..\Resampler\uScale.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas';

{$R *.res}
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TThreadsInThreadsMain, ThreadsInThreadsMain);
  Application.CreateForm(TShowPicture, ShowPicture);
  Application.Run;
end.
