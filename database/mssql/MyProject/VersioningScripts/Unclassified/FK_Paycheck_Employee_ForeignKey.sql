USE [VersionControlSample]
GO
ALTER TABLE [dbo].[Paycheck]  WITH CHECK ADD  CONSTRAINT [FK_Paycheck_Employee] FOREIGN KEY([EmployeeId])
REFERENCES [dbo].[Employee] ([EmployeeId])
GO
ALTER TABLE [dbo].[Paycheck] CHECK CONSTRAINT [FK_Paycheck_Employee]
GO
