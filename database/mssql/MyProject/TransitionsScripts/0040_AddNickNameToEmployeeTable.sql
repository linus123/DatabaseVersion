ALTER TABLE [dbo].[Employee] ADD NickName NVARCHAR(64)

--//@UNDO

ALTER TABLE [dbo].[Employee] DROP COLUMN NickName
