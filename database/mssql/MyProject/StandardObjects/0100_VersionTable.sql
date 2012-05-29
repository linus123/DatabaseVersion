CREATE TABLE DatabaseVersion (
	change_number BIGINT NOT NULL,
	delta_set VARCHAR(10) NOT NULL,
	start_dt DATETIME NOT NULL,
	complete_dt DATETIME NULL,
	applied_by VARCHAR(100) NOT NULL,
	description VARCHAR(500) NOT NULL
)

ALTER TABLE DatabaseVersion
	ADD CONSTRAINT PK_DatabaseVersion_ChangeNumberDeltaSet PRIMARY KEY (change_number, delta_set)