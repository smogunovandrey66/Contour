program Contour;

uses
  Vcl.Forms,
  unMain in 'unMain.pas' {FormMain},
  unApiContour in 'unApiContour.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
