program ThreadsInThreadsFMX;
uses
  System.StartUpCopy,
  FMX.Forms,
  uThreadsInThreadsFMX in 'uThreadsInThreadsFMX.pas' {ThreadsInThreadsFMXMain},
  uShowPictureFMX in 'uShowPictureFMX.pas' {ShowPicture},
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uScaleFMX in '..\..\Resampler\uScaleFMX.pas',
  uDirectoryTreeFMX in '..\..\Utilities\UtilitiesFMX\uDirectoryTreeFMX.pas';

{$R *.res}
begin
  Application.Initialize;
  Application.CreateForm(TThreadsInThreadsFMXMain, ThreadsInThreadsFMXMain);
  Application.CreateForm(TShowPicture, ShowPicture);
  Application.Run;
end.
