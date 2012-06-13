CREATE TABLE DatabaseVersion (
  ChangeNumber BIGINT NOT NULL,
  Project VARCHAR(10) NOT NULL,
  StartDate DATETIME NOT NULL,
  CompletedDate DATETIME NULL,
  AppliedBy VARCHAR(100) NOT NULL,
  FileName VARCHAR(500) NOT NULL
)
GO

ALTER TABLE DatabaseVersion ADD CONSTRAINT PkDatabaseVersion PRIMARY KEY (ChangeNumber, Project)
GO