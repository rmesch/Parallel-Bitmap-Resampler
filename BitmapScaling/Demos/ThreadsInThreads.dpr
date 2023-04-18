program ThreadsInThreads;

uses
  Vcl.Forms,
  uThreadsInThreadsMain in 'uThreadsInThreadsMain.pas' {ThreadsInThreadsMain},
  uScale in '..\Resampler\uScale.pas',
  uShowPicture in 'uShowPicture.pas' {ShowPicture},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TThreadsInThreadsMain, ThreadsInThreadsMain);
  Application.CreateForm(TShowPicture, ShowPicture);
  Application.Run;
end.
