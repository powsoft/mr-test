USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateBaseOrderWHLSRagulate]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[amb_UpdateBaseOrderWHLSRagulate]

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
@webuser varchar(10),
@dbType varchar(20)


AS --exec usp_UpdateBaseOrderWHLS  'TA','TA212100','PRSED',12,3,3,3,3,0,0,0,0,'WR1428','don123'
BEGIN

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
--Update to Old DataBase
	if(@dbType='0')
		begin
			UPDATE   [IC-HQSQL\ICONTROL].iControl.dbo.BaseOrder 
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
		end

	else
		begin
			--Update to New DataBase

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
			where PI.Bipad=@Bipad And S.LegacySystemStoreIdentifier=@StoreID and PI.ProductIdentifierTypeID=8 
		end
END
GO
