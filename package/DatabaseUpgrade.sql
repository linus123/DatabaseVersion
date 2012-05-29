-- Script generated at 2012-05-28T10:24:33





--------------- Fragment begins: #1: 001_CreateEmployeeTable.sql ---------------
INSERT INTO DatabaseVersion (change_number, delta_set, start_dt, applied_by, description) VALUES (1, 'MyProject', getdate(), user_name(), '001_CreateEmployeeTable.sql')
GO


-- Change script: #1: 001_CreateEmployeeTable.sql
CREATE TABLE [dbo].[Employee](
	[EmployeeId] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](64) NOT NULL,
	[LastName] [nvarchar](64) NOT NULL,
	[DateOfBirth] [date] NOT NULL,
 CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED 
(
	[EmployeeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO



GO
UPDATE DatabaseVersion SET complete_dt = getdate() WHERE change_number = 1 AND delta_set = 'MyProject'
GO

--------------- Fragment ends: #1: 001_CreateEmployeeTable.sql ---------------

--------------- Fragment begins: #2: 002_CreatePaycheckTable.sql ---------------
INSERT INTO DatabaseVersion (change_number, delta_set, start_dt, applied_by, description) VALUES (2, 'MyProject', getdate(), user_name(), '002_CreatePaycheckTable.sql')
GO


-- Change script: #2: 002_CreatePaycheckTable.sql
CREATE TABLE [dbo].[Paycheck](
	[PaycheckNumber] [nvarchar](16) NOT NULL,
	[EmployeeId] [int] NOT NULL,
	[PayDate] [date] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_Paycheck] PRIMARY KEY CLUSTERED 
(
	[PaycheckNumber] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Paycheck]  WITH CHECK ADD  CONSTRAINT [FK_Paycheck_Employee] FOREIGN KEY([EmployeeId])
REFERENCES [dbo].[Employee] ([EmployeeId])
GO

ALTER TABLE [dbo].[Paycheck] CHECK CONSTRAINT [FK_Paycheck_Employee]
GO



GO
UPDATE DatabaseVersion SET complete_dt = getdate() WHERE change_number = 2 AND delta_set = 'MyProject'
GO

--------------- Fragment ends: #2: 002_CreatePaycheckTable.sql ---------------
