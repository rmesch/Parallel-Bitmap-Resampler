program ZoomPan;

uses
  Vcl.Forms,
  uZoomPanMain in 'uZoomPanMain.pas' {ZoomPanMain},
  uScale in '..\..\Resampler\uScale.pas',
  uScaleCommon in '..\..\Resampler\uScaleCommon.pas',
  uTestBitmap in '..\..\Utilities\uTestBitmap.pas',
  uTools in '..\..\Utilities\UtilitiesVCL\uTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TZoomPanMain, ZoomPanMain);
  Application.Run;
end.
