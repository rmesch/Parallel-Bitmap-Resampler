program DemoScale;

uses
  Vcl.Forms,
  uDemoScaleMain in 'uDemoScaleMain.pas' {DemoMain},
  Vcl.Themes,
  Vcl.Styles,
  uScale in '..\..\Resampler\uScale.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uTestBitmap in '..\..\Utilities\uTestBitmap.pas',
  uTools in '..\..\Utilities\UtilitiesVCL\uTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDemoMain, DemoMain);
  Application.Run;
end.
