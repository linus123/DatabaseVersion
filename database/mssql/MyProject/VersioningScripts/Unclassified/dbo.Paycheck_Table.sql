USE [VersionControlSample]
GO
/****** Object:  Table [dbo].[Paycheck]    Script Date: 5/21/2013 12:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Paycheck]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Paycheck](
	[PaycheckNumber] [nvarchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EmployeeId] [int] NOT NULL,
	[PayDate] [date] NOT NULL,
	[Amount] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_Paycheck] PRIMARY KEY CLUSTERED 
(
	[PaycheckNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
