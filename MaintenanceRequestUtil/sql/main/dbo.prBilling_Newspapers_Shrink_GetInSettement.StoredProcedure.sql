USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prBilling_Newspapers_Shrink_GetInSettement]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prBilling_Newspapers_Shrink_GetInSettement]

AS
BEGIN

	BEGIN TRY

		DECLARE @ChainID INT
		DECLARE @ChainIdentifier VARCHAR(50)
		DECLARE @FirstWeekEndingDate DATE
		DECLARE @FirstSaleDate DATE
		DECLARE @RepEmailAddress VARCHAR(500)
		
		DECLARE @emailTo VARCHAR(500)
		DECLARE @emailSubject VARCHAR(200)
		DECLARE @Filename VARCHAR(500)

		DECLARE ShrinkCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT c.ChainIdentifier, c.ChainID, DATEADD(d, 6, cm.datemigrated), cm.datemigrated, ISNULL(cm.RepEmailAddress, '')
		FROM DataTrue_Main.dbo.chains_migration AS cm WITH (NOLOCK)
		INNER JOIN DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
		ON cm.chainid = c.ChainIdentifier
		WHERE DATEADD(d, 6, cm.datemigrated) < CONVERT(DATE, GETDATE())
		--AND c.ChainIdentifier IN ('CF')
		AND c.ChainIdentifier IN ('CF', 'LG', 'EZM', 'TOP', 'MAV')

		OPEN ShrinkCursor
		FETCH NEXT FROM ShrinkCursor INTO @ChainIdentifier, @ChainID, @FirstWeekEndingDate, @FirstSaleDate, @RepEmailAddress

		WHILE @@FETCH_STATUS = 0
			BEGIN
			
				TRUNCATE TABLE [DataTrue_EDI].[dbo].[WorkingTable_Shrink_ForCSV]
				
				--GET DAY OF WEEK AND SET DATEFIRST
				DECLARE @DayOfWeek INT
				SET @DayOfWeek = DATEPART(dw, @FirstWeekEndingDate)
				
				SET DATEFIRST @DayOfWeek
				
				INSERT INTO DataTrue_EDI.dbo.WorkingTable_Shrink_ForCSV 
				(
				ChainIdentifier, 
				LegacySystemStoreIdentifier, 
				WeekEnding, 
				SettlementShrink$, 
				SettlementShrinkUnits, 
				TotalShrink$, 
				TotalShrinkUnits, 
				SupplierIdentifier
				)
				SELECT 
				c.ChainIdentifier, 
				s.LegacySystemStoreIdentifier, 
				CONVERT(DATE,DATEADD(ww,DATEDIFF(week, DATEADD(dd,-@@datefirst,@FirstSaleDate), DATEADD(dd,-@@datefirst,facts.SaleDateTime)), @FirstWeekEndingDate)) AS WeekEnding, 
				SUM(facts.Shrink$) AS SettlementShrink$,
				SUM(facts.ShrinkUnits) AS SettlementShrinkUnits,
				SUM(facts.Shrink$) AS TotalShrink$,
				SUM(facts.ShrinkUnits) AS TotalShrinkUnits, 
				SupplierIdentifier
				FROM DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Facts AS facts WITH (NOLOCK)
				INNER JOIN DataTrue_Main.dbo.Chains AS c WITH (NOLOCK)
				ON facts.ChainID = c.ChainID
				INNER JOIN DataTrue_Main.dbo.stores AS s WITH (NOLOCK)
				ON facts.StoreID = s.storeid
				INNER JOIN DataTrue_Main.dbo.suppliers AS sp WITH (NOLOCK)
				ON facts.Supplierid = sp.SupplierID
				--LEFT OUTER JOIN DataTrue_Main.dbo.InventoryReport_Newspaper_Shrink_Facts AS facts2 WITH (NOLOCK)
				--ON facts.ChainID = facts2.ChainID
				--AND facts.Supplierid = facts2.Supplierid
				--AND facts.StoreID = facts2.StoreID
				--AND facts.ProductID = facts2.ProductID
				--AND CONVERT(DATE, facts.SaleDateTime) = CONVERT(DATE, facts2.SaleDateTime)
				--AND facts.Status = 2
				--AND facts2.Status = 5
				WHERE facts.ChainID = @ChainID
				AND facts.SaleDateTime BETWEEN (SELECT datemigrated FROM DataTrue_Main.dbo.chains_migration AS cm WITH (NOLOCK) WHERE cm.chainid = c.ChainIdentifier)
										   AND (SELECT DATEADD(dd, -(DATEPART(dw, GETDATE()-7)-1), GETDATE()))
				AND facts.Status  = 2
				AND facts.Shrink$ <> '0.00'
				AND facts.TransactionTypeID = 17
				GROUP BY DATEDIFF(week, DATEADD(dd,-@@datefirst,@FirstSaleDate), DATEADD(dd,-@@datefirst,facts.SaleDateTime)), c.ChainIdentifier, LegacySystemStoreIdentifier, SupplierIdentifier
				ORDER BY DATEDIFF(week, DATEADD(dd,-@@datefirst,@FirstSaleDate), DATEADD(dd,-@@datefirst,facts.SaleDateTime)), c.ChainIdentifier, LegacySystemStoreIdentifier, SupplierIdentifier
				
				IF @@ROWCOUNT > 0
					BEGIN
			
						
						SET @Filename = @ChainIdentifier + '_DCRs_' + CONVERT(VARCHAR(10),GETDATE(),112) + '.csv'
						
						EXEC DataTrue_EDI.dbo.usp_GenerateCSVFromWorkingTable 
						'SELECT * FROM DataTrue_EDI.dbo.WorkingTable_Shrink_ForCSV ORDER BY WeekEnding, LegacySystemStoreIdentifier, SupplierIdentifier',
						@Filename
						
						SET @Filename = 'C:\WorkingTemp\' + @Filename
						SET @emailSubject = @ChainIdentifier + ' Weekly Shrink DCRs'					
						SET @emailTo = 'edi@icucsolutions.com; ' + @RepEmailAddress
						--SET @emailTo = 'william.heine@icucsolutions.com'
						
						EXEC msdb..sp_send_dbmail @profile_name ='datatrue system',@recipients= @emailTo,
							@subject= @emailSubject,
							@body='Please see attached file for IN SETTLEMENT shrink records.',
							@file_attachments=@Filename
							
					END
					
				SET DATEFIRST 7
			
				FETCH NEXT FROM ShrinkCursor INTO @ChainIdentifier, @ChainID, @FirstWeekEndingDate, @FirstSaleDate, @RepEmailAddress
			END
		CLOSE ShrinkCursor
		DEALLOCATE ShrinkCursor
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage VARCHAR(MAX)
		SET @ErrorMessage = ERROR_MESSAGE()
	END CATCH
END
GO
