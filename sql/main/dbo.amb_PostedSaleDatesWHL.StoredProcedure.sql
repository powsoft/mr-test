USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_PostedSaleDatesWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[amb_PostedSaleDatesWHL]

@uname varchar(20)
as

Begin
		SELECT LastSaleDateReportedPerChain.ChainID, Convert(varchar(12), LastSaleDateReportedPerChain.LastSaleDateInSystem,101) as LastSaleDateInSystem
		FROM [IC-HQSQL2].iControl.dbo.LastSaleDateReportedPerChain INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder ON LastSaleDateReportedPerChain.ChainID = BaseOrder.ChainID 
		WHERE (((BaseOrder.Stopped)=0) AND ((BaseOrder.StoppedIndex)=0) AND ((BaseOrder.WholesalerID)=''+@uname+'')) 
		GROUP BY LastSaleDateReportedPerChain.ChainID, LastSaleDateReportedPerChain.LastSaleDateInSystem

End
GO
