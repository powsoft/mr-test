CREATE DATABASE DataTrue_Main
ON (
  NAME = DataTrue_Main_dat,
  FILENAME = 'c:\icontrol-mr\data\DataTrueMain.mdf'
)
LOG ON (
  NAME = DataTrue_Main_log,
  FILENAME = 'c:\icontrol-mr\data-log\DataTrueMain.ldf'
);
CREATE DATABASE DataTrue_EDI
ON (
  NAME = DataTrue_EDI_dat,
  FILENAME = 'c:\icontrol-mr\data\DataTrueEDI.mdf'
)
LOG ON (
  NAME = DataTrue_EDI_log,
  FILENAME = 'c:\icontrol-mr\data-log\DataTrueEDI.ldf'
);