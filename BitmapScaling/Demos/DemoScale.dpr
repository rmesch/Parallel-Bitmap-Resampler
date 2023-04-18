program DemoScale;

uses
  Vcl.Forms,
  uDemoScaleMain in 'uDemoScaleMain.pas' {DemoMain},
  uTools in 'uTools.pas',
  Vcl.Themes,
  Vcl.Styles,
  uScale in '..\Resampler\uScale.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDemoMain, DemoMain);
  Application.Run;
end.
