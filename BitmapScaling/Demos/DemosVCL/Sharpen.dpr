program Sharpen;

uses
  Vcl.Forms,
  uSharpenMain in 'uSharpenMain.pas' {SharpenMain},
  uTools in '..\..\Utilities\UtilitiesVCL\uTools.pas',
  uScale in '..\..\Resampler\uScale.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSharpenMain, SharpenMain);
  Application.Run;
end.
