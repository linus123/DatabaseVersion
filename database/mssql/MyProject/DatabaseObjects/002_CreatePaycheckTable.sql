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

--//@UNDO

DROP TABLE [dbo].[Paycheck]
