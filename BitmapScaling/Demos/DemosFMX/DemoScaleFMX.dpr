program DemoScaleFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  uDemoScaleFMX in 'uDemoScaleFMX.pas' {DemoFMXMain},
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uScaleFMX in '..\..\Resampler\uScaleFMX.pas',
  uTestBitmap in '..\..\Utilities\uTestBitmap.pas',
  uToolsFMX in '..\..\Utilities\UtilitiesFMX\uToolsFMX.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDemoFMXMain, DemoFMXMain);
  Application.Run;
end.
