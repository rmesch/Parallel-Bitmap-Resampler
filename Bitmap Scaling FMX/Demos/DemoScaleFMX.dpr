program DemoScaleFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  uDemoScaleFMX in 'uDemoScaleFMX.pas' {DemoFMXMain},
  uScaleFMX in '..\Resampler\uScaleFMX.pas',
  uTestBitmap in 'uTestBitmap.pas',
  uToolsFMX in 'uToolsFMX.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDemoFMXMain, DemoFMXMain);
  Application.Run;
end.
