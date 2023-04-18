program ZoomPan;

uses
  Vcl.Forms,
  uZoomPanMain in 'uZoomPanMain.pas' {ZoomPanMain},
  uTools in 'uTools.pas',
  uScale in '..\Resampler\uScale.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TZoomPanMain, ZoomPanMain);
  Application.Run;
end.
