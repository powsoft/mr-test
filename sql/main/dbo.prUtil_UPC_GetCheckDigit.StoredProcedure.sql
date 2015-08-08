USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_UPC_GetCheckDigit]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tatiana
-- Create date: 2011-03-15
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[prUtil_UPC_GetCheckDigit]
	 @UPC varchar(11),
	 @CheckDigit integer OUT
	
/*
declare @upc11 nvarchar(50)='07294560136'
declare @upc12 nvarchar(50)
declare @checkdigit nvarchar(50)

exec [dbo].[prUtil_UPC_GetCheckDigit]
	 @UPC11,
	 @CheckDigit OUT
	 
print @upc11 + @CheckDigit


*/	
AS
	DECLARE @SumODDNumbers as integer
	DECLARE @SumEvenNumbers as integer
	DECLARE @Total as integer
	DECLARE @Remainder as integer

	DECLARE @Digit1 as integer
	DECLARE @Digit2 as integer
	DECLARE @Digit3 as integer
	DECLARE @Digit4 as integer
	DECLARE @Digit5 as integer
	DECLARE @Digit6 as integer
	DECLARE @Digit7 as integer
	DECLARE @Digit8 as integer
	DECLARE @Digit9 as integer
	DECLARE @Digit10 as integer
	DECLARE @Digit11 as integer

	--DECLARE @CheckDigit as integer
	DECLARE @SQL as VARCHAR (2000)
	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Set @UPC = substring(@UPC,1,11)
	--print (@UPC)
	set @Digit1 =substring(@UPC,1,1)
	set @Digit2 =substring(@UPC,2,1)
	--print(@Digit2)
	set @Digit3 =substring(@UPC,3,1)
	set @Digit4 =substring(@UPC,4,1)
	--print(@Digit4)
	set @Digit5 =substring(@UPC,5,1)
	set @Digit6 =substring(@UPC,6,1)
	set @Digit7 =substring(@UPC,7,1)
	set @Digit8 =substring(@UPC,8,1)
	set @Digit9 =substring(@UPC,9,1)
	set @Digit10 =substring(@UPC,10,1)
	set @Digit11 =substring(@UPC,11,1)
	
	SET @SumODDNumbers =@Digit1+@digit3+@Digit5+@digit7+@digit9+@Digit11
	--print (@SumODDNumbers)
	SET @SumEvenNumbers =@Digit2+@digit4+@Digit6+@digit8+@digit10
	--print (@SumEvenNumbers)
    set @SumODDNumbers = @SumODDNumbers *3
	--print(@SumODDNumbers)
	SET @Total = @SumODDNumbers+@sumevenNumbers
	--print(@Total)


	--SELECT 38 / 5 AS Integer, 38 % 5 AS Remainder ;

	set @Remainder =cast(@total % 10 as integer)
	--print(@Remainder)
	set @CheckDigit = 10 -@Remainder
	if @Remainder = 0 
		SET @CheckDigit =0

	--print (@CheckDigit)
	--Select @Checkdigit

	--SET @CorrectUPC = substring(@UPC,1,11) + cast(@CheckDigit as varchar)
	--print (@UPC)
	--print(substring(@UPC,1,11))
	--print(@CorrectUPC)

	--SELECT @CorrectUPC 

	
	
END
GO
