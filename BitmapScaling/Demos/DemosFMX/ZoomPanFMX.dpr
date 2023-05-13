program ZoomPanFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  uZoomPanFMXMain in 'uZoomPanFMXMain.pas' {ZoomPanFMXMain},
  uTestBitmap in '..\..\Utilities\uTestBitmap.pas',
  uToolsFMX in '..\..\Utilities\UtilitiesFMX\uToolsFMX.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uScaleFMX in '..\..\Resampler\uScaleFMX.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TZoomPanFMXMain, ZoomPanFMXMain);
  Application.Run;
end.
