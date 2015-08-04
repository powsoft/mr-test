USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_UpdateWeekLimits]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Exec amb_UpdateWeekLimits 'CVS1583','PRSED','0','0','0','0','0','0','0','WR1428','don123','0'
CREATE PROCEDURE [dbo].[amb_UpdateWeekLimits]

@StoreID nvarchar(10),
@Bipad nvarchar(5),
@Mon smallint,
@Tue smallint, 
@Wed smallint, 
@Thur smallint, 
@Fri smallint, 
@Sat smallint,
@Sun smallint,
@uname varchar(10),
@webuser varchar(10),
@DbType int
AS 

Create TABLE #TempUname (
uname nvarchar(10),
webuser nvarchar(10))

INSERT #TempUname
VALUES (@uname, @webuser)

/*INSERT INTO ASP2SQL
(
StoreID, Bipad, ChainID, WholesalerID,
Mon, Tue, Wed, Thur, Fri, Sat, Sun,
uname)
VALUES(@StoreID, @Bipad, @ChainID, @WholesalerID, 
@Mon, @Tue, @Wed, @Thur, @Fri, @Sat, @Sun,
@uname)*/

 
/*----Update the Old DB----*/
IF(@DbType=0)
	BEGIN
		UPDATE   [IC-HQSQL2].iControl.dbo.BaseOrder 
		SET Mon = @Mon, 
			Tue = @Tue, 
			Wed = @Wed,
			Thur = @Thur,
			Fri = @Fri,
			Sat = @Sat,
			Sun = @Sun
				
	   WHERE StoreID = @StoreID AND Bipad = @Bipad
	END

	
	
/*----Update the New DB----*/	
IF(@DbType=1)
	BEGIN
		Update dbo.StoreSetup 
	    SET MonLimitQty=@Mon ,
	    TueLimitQty=@Tue ,
	    WedLimitQty=@Wed ,
	    ThuLimitQty=@Thur ,
	    FriLimitQty=@Fri ,
	    SatLimitQty=@sat

		FROM dbo.StoreSetup SS
			 INNER JOIN dbo.ProductIdentifier PI ON SS.ProductID=PI.ProductID
			 INNER JOIN dbo.Stores S ON SS.StoreID=S.StoreID

		WHERE PI.Bipad=@Bipad And S.LegacySystemStoreIdentifier=@StoreID 
		      AND PI.ProductIdentifierTypeID=8
	END
GO
