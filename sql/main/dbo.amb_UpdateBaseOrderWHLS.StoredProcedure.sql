USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateBaseOrderWHLS]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[amb_UpdateBaseOrderWHLS]

@ChainID NVARCHAR(100),
@StoreID nvarchar(10),
@Bipad nvarchar(5),
@Mon smallint,
@Tue smallint, 
@Wed smallint, 
@Thur smallint, 
@Fri smallint, 
@Sat smallint,
@Sun smallint,
@Holiday bit,
@Stopped bit,
@uname varchar(10),
@webuser varchar(10)
--,@IdentifierValue nvarchar(50)

AS --exec [amb_UpdateBaseOrderWHLS] 'TA','TA212100','PES',10,5,3,3,3,0,0,0,0,'WR1428','don123','019089001259'
BEGIN
	Declare @Dbtype int -- 0 for Old,1 for New
	Declare @Chain_Migarted varchar(100)

	Select  @Chain_Migarted=ChainID from Chains_Migration 
	where ChainId=@ChainID
		If(@Chain_Migarted is null)
				Set @Dbtype=0
		Else
				Set @Dbtype=1
	 
	Create TABLE #TempUname (uname nvarchar(10),webuser nvarchar(10))

	INSERT #TempUname VALUES (@uname, @webuser)

	/*
	INSERT INTO ASP2SQL
	(
	StoreID, Bipad, ChainID, WholesalerID,
	Mon, Tue, Wed, Thur, Fri, Sat, Sun,
	Hol,
	Stopped, Frozen
	uname)
	VALUES(@StoreID, @Bipad, @ChainID, @WholesalerID, 
	@Mon, @Tue, @Wed, @Thur, @Fri, @Sat, @Sun,
	@uname)
	*/
	IF(@Dbtype=0)--Update to Old DataBase
	Begin
			UPDATE  [IC-HQSQL2].iControl.dbo.BaseOrder 
				SET Mon = @Mon, 
				Tue = @Tue, 
				Wed = @Wed,
				Thur = @Thur,
				Fri = @Fri,
				Sat = @Sat,
				Sun = @Sun,
				Hol = @Holiday,
				Stopped = @Stopped
		WHERE StoreID = @StoreID
		AND Bipad = @Bipad
	End

	Else IF(@Dbtype=1)--Update to New DataBase
	Begin
			UPDATE dbo.StoreSetup 
			SET MonLimitQty = @Mon,
				TueLimitQty = @Tue,
				WedLimitQty = @Wed,
				ThuLimitQty = @Thur,
				FriLimitQty = @Fri,
				SatLimitQty = @Sat,
				SunLimitQty = @Sun
				FROM dbo.StoreSetup SS
			inner join dbo.ProductIdentifiers PI on SS.ProductID=PI.ProductID
			inner join dbo.Stores S on SS.StoreID=S.StoreID
			where PI.Bipad=@Bipad And S.LegacySystemStoreIdentifier=@StoreID and PI.ProductIdentifierTypeID=8 --and PI.IdentifierValue=@IdentifierValue
	End
END
	
	
	--Select * FromiControl.dbo.BaseOrder WHERE StoreID = 'TA212100' AND Bipad = 'PES'
	--Select * From dbo.StoreSetup SS inner join dbo.ProductIdentifiers PI on SS.ProductID=PI.ProductID join dbo.Stores S on SS.StoreID=S.StoreID where PI.Bipad='PRSED' And S.LegacySystemStoreIdentifier='TA212100' and  IdentifierValue='654039000014'
GO
