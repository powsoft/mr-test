USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_AddInSharedShrinkQue]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_AddInSharedShrinkQue]
	@ForSupplierId varchar(10),
	@ForChainId nvarchar(10)
as 

Begin
	Insert into SharedShrinkUpdate values(@ForSupplierId, @ForChainId, Null, NUll)
End
GO
