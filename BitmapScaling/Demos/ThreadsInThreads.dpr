program ThreadsInThreads;

uses
  Vcl.Forms,
  uThreadsInThreadsMain in 'uThreadsInThreadsMain.pas' {ThreadsInThreadsMain},
  uShowPicture in 'uShowPicture.pas' {ShowPicture},
  Vcl.Themes,
  Vcl.Styles,
  uTools in 'uTools.pas',
  uScale in '..\Resampler\uScale.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TThreadsInThreadsMain, ThreadsInThreadsMain);
  Application.CreateForm(TShowPicture, ShowPicture);
  Application.Run;
end.
