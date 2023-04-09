program ZoomPan;

uses
  Vcl.Forms,
  uZoomPanMain in 'uZoomPanMain.pas' {ZoomPanMain},
  uScale in '..\Resampler\uScale.pas',
  uTools in 'uTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TZoomPanMain, ZoomPanMain);
  Application.Run;
end.
