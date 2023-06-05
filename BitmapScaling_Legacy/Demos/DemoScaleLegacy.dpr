program DemoScaleLegacy;

uses
  Forms,
  uDemoScaleMainLegacy in 'uDemoScaleMainLegacy.pas' {DemoMain},
  uToolsLegacy in '..\Utilities\uToolsLegacy.pas',
  uScaleCommonLegacy in '..\Resampler\uScaleCommonLegacy.pas',
  uScaleLegacy in '..\Resampler\uScaleLegacy.pas',
  uTestBitmapLegacy in '..\Utilities\uTestBitmapLegacy.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDemoMain, DemoMain);
  Application.Run;
end.
