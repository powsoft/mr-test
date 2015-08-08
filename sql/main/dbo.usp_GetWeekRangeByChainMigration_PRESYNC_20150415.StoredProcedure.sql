USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetWeekRangeByChainMigration_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC usp_GetWeekRangeByChainMigration '02','01/02/2015','01/12/2015'
CREATE PROC [dbo].[usp_GetWeekRangeByChainMigration_PRESYNC_20150415]
(
@ChainIdentifier AS VARCHAR(20),
@StartDate AS VARCHAR(20),
@EndDate AS VARCHAR(20)
)
AS
BEGIN
	/*Declare @StartDate Date =  cast('2015-01-05' AS Date)
	Declare @EndDate Date = Cast('2015-01-15'  AS date)*/
	Declare @oldStartdate Date
	Declare @oldenddate Date
	Declare @newStartdate Date
	Declare @newenddate Date
	Declare @allnew int --0 for old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	
	IF(@ChainIdentifier <> '-1')
		BEGIN
			SELECT @chain_migrated_date = CAST(DateMigrated AS DATE) FROM  DataTrue_Main.dbo.Chains_Migration WHERE  ChainId = @ChainIdentifier
				
			IF(CAST(@chain_migrated_date AS DATE) > CAST('01/01/1900' AS DATE))
				BEGIN
					IF(CAST(@StartDate AS DATE) >= CAST(@chain_migrated_date AS DATE))
						BEGIN
							SET @allnew=1
							SET @newStartdate=@StartDate
							SET @newEnddate=@EndDate
						END
					ELSE IF(CAST(@EndDate AS DATE) < CAST(@chain_migrated_date AS DATE))
						BEGIN
							SET @allnew=0
							SET @oldStartdate=@StartDate
							SET @oldenddate=@EndDate
						END
					ELSE IF(CAST(@EndDate AS DATE) >= CAST(@chain_migrated_date AS DATE) and CAST(@startdate AS DATE) <= CAST(@chain_migrated_date AS DATE))
						BEGIN
							SET @allnew=2
							SET @oldStartdate=@StartDate
							SET @oldenddate=DATEADD(dd, -1, @chain_migrated_date)
							SET @newStartdate=@chain_migrated_date
							SET @newEnddate=@EndDate
						END
				END
			ELSE
				BEGIN
					SET @allnew=0
					SET @oldStartdate=@StartDate
					SET @oldenddate=@EndDate
				END
		END
	ELSE
		BEGIN
			SET @allnew=2
			SET @oldStartdate=@StartDate
			SET @oldenddate=@EndDate
			SET @newStartdate=@StartDate
			SET @newEnddate=@EndDate
		END
		
	
	DECLARE @tbl_SaleDates TABLE
	(
	  DbType Int,
	  OldStartDate Varchar(20),
	  OldEndDate Varchar(20),
	  NewStartDate Varchar(20),
	  NewEndDate Varchar(20)
	)
	
	Insert INTO @tbl_SaleDates Values (@allnew,@oldStartdate,@oldenddate,@newStartdate,@newEnddate);
	
	SELECT * FROM @tbl_SaleDates;
	
END
GO
