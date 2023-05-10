unit uShowPictureFMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects;

type
  TShowPicture = class(TForm)
    Rectangle1: TRectangle;
    Image1: TImage;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  ShowPicture: TShowPicture;

implementation

{$R *.fmx}

end.
