USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddFAQ]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AddFAQ]
  @FAQId varchar(10),
  @GroupId varchar(50),
  @Question varchar(max),
  @Answer varchar(max)
  
AS

BEGIN
	if(@FAQId>0)
		Update FAQ set 
		FAQGroupId=@GroupId, 
		Question=@Question, 
		Answer=@Answer
		where FAQId=@FAQId
	else
		Insert INTO FAQ
		(FAQGroupId,
		 Question,
		 Answer
		) 
		values
		(
		@GroupId,
		@Question,
		@Answer
		)
END
GO
