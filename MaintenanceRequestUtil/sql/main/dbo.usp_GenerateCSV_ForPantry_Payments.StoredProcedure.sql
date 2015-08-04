USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateCSV_ForPantry_Payments]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GenerateCSV_ForPantry_Payments]   
 @ChainName VARCHAR(50),  
 @SupplierName VARCHAR(50),
 @Fields VARCHAR(8000),  
 @PaymentId INT,
  @Filename VARCHAR(2000) output
AS  
  
  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 
--IF @Filename = ''
--	BEGIN
		SET @Filename = 'C:\'+ @ChainName + '_' + @SupplierName + '_' + convert(varchar(10),getdate(),112) + '_Payment_' + CONVERT(varchar(50), @PaymentId) + '.csv' 
	--END
	
	--print @Filename
 
  
declare @shellcmd varchar(8000)='sqlcmd -Q "set nocount on;'  
--declare @filename varchar(500) = @ChainIdentifier + '_' + @SupplierIdentifier + '_' + convert(varchar(10),getdate(),112) + '_EFT.csv'   
  
--exec xp_cmdshell 'net use W: /delete /y',no_output  
--exec xp_cmdshell 'net use W: \\ic-hqapp2\Clientsdata /user:icontroldsd\talperovitch tatoshka1*',no_output  
  
set @shellcmd+=@Fields  
set @shellcmd+='" -o' + @Filename + ' -s, -W -S. -Udatatrueadmin -Pdatatrueadmin123'  
    
exec xp_cmdshell @shellcmd
  
--set @shellcmd = 'findstr /V /C:"--" c:\Temp_GenerateCSVPayment.csv > W:' + @folder + @filename  

--exec xp_cmdshell @shellcmd,no_output  

--if @MoveToFTP = 1
--	begin
--		exec xp_cmdshell 'net use X: /delete /y',no_output  
--		exec xp_cmdshell 'net use X: \\172.16.100.67\FTP /user:icontroldsd\talperovitch Password1',no_output
--		set @shellcmd = 'findstr /V /C:"--" c:\Temp_GenerateCSVEFT.csv > X:' + @FTP + @filename  
--		exec xp_cmdshell @shellcmd,no_output  
--	end
  
--exec xp_cmdshell 'del c:\Temp_GenerateCSVPayment.csv',no_output  
  


  
END  
  
--select invoiceno,Storenumber,saledate,upc,title,qty,convert(varchar(8),cost),convert(varchar(8),suggretail),cast(endweek as date)from Temp_GetDataFor810_Newspapers where ChainID ='PJ'  
  
--exec usp_GenerateCSV810 'PJ','select invoiceno,Storenumber,saledate,upc,title,qty,convert(varchar(8),cost)cost,convert(varchar(8),suggretail)retail,cast(endweek as date)date from Temp_GetDataFor810_Newspapers where ChainID =','\test\'
GO
