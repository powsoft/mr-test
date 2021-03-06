USE [DataTrue_EDI]
GO
/****** Object:  Table [dbo].[Exceptions]    Script Date: 06/25/2015 16:58:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exceptions](
	[ExceptionID] [bigint] IDENTITY(1,1) NOT NULL,
	[ExceptionTypeID] [smallint] NOT NULL,
	[ExceptionPartnerID] [nchar](10) NULL,
	[ExceptionSubject] [nvarchar](255) NOT NULL,
	[ExceptionBody] [nvarchar](4000) NOT NULL,
	[ExceptionSenderString] [nvarchar](255) NOT NULL,
	[ExceptionSenderID] [int] NOT NULL,
	[ExceptionFileName] [nchar](255) NULL,
	[ExceptionCreateDateTime] [datetime] NOT NULL,
	[ExceptionLastNotifyDateTime] [datetime] NULL,
	[ExceptionNotifyCount] [int] NOT NULL,
	[ExceptionStatus] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionTypeID]  DEFAULT ((0)) FOR [ExceptionTypeID]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionSubject]  DEFAULT ('NO SUBJECT PROVIDED') FOR [ExceptionSubject]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionBody]  DEFAULT ('NO INFORMATION PROVIDED') FOR [ExceptionBody]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionSenderString]  DEFAULT ('NO SENDER PROVIDED') FOR [ExceptionSenderString]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionSenderID]  DEFAULT ((0)) FOR [ExceptionSenderID]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionCreateDateTime]  DEFAULT (getdate()) FOR [ExceptionCreateDateTime]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionNotifyCount]  DEFAULT ((0)) FOR [ExceptionNotifyCount]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_ExceptionStatus]  DEFAULT ((0)) FOR [ExceptionStatus]
GO
SET IDENTITY_INSERT [dbo].[Exceptions] ON
INSERT [dbo].[Exceptions] ([ExceptionID], [ExceptionTypeID], [ExceptionPartnerID], [ExceptionSubject], [ExceptionBody], [ExceptionSenderString], [ExceptionSenderID], [ExceptionFileName], [ExceptionCreateDateTime], [ExceptionLastNotifyDateTime], [ExceptionNotifyCount], [ExceptionStatus]) VALUES (22232, 0, N'          ', N'852_Deliveries', N'System.Data.DuplicateNameException: A column named ProductIdentifier already belongs to this DataTable.
   at System.Data.DataColumnCollection.RegisterColumnName(String name, DataColumn column, DataTable table)
   at System.Data.DataColumnCollection.BaseAdd(DataColumn column)
   at System.Data.DataColumnCollection.AddAt(Int32 index, DataColumn column)
   at System.Data.DataColumnCollection.Add(String columnName, Type type)
   at Parser.ClsParse852.CreateDataTable_Deliveries(String X12Map) in C:\Users\talperovitch\Documents\Visual Studio 2010\Projects\InboundProcesses\Parser\ClsParse852.vb:line 2553', N'CreateDataTable_deliveries', 1, N'                                                                                                                                                                                                                                                               ', CAST(0x0000A23900000000 AS DateTime), NULL, 0, 0);