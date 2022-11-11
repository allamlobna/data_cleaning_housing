SELECT * 
FROM [data_cleaning_project].[dbo].[nashville_housing]

----------------------------------------------------------------
--  Standardize SaleDate Format --
----------------------------------------------------------------
--Retrieves date only from SaleDate column
SELECT SaleDate, CONVERT (DATE, SaleDate)
FROM [data_cleaning_project].[dbo].[nashville_housing]

--Creates new column with date datatype
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add SaleDateConverted Date

--Updates new caloumn SaleDateConverted with dates, no time
UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET SaleDateConverted = CONVERT (DATE, SaleDate)

----------------------------------------------------------------
--  Populate Property Address Data that are Null --
----------------------------------------------------------------

SELECT *
FROM [data_cleaning_project].[dbo].[nashville_housing]
WHERE PropertyAddress IS NULL;

-- PropertyAddress corresponds to ParcelID. We can use the ParcelID to populate Null PropertyAddress

-- InnerJoin to match ParcelID of null (a) with filled PropertyAddress (b)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [data_cleaning_project].[dbo].[nashville_housing] a
JOIN [data_cleaning_project].[dbo].[nashville_housing] b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- Updated null PropertyAddress 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [data_cleaning_project].[dbo].[nashville_housing] a
JOIN [data_cleaning_project].[dbo].[nashville_housing] b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- Confirmed that there are no null PropertyAddress
SELECT *
FROM [data_cleaning_project].[dbo].[nashville_housing]
WHERE PropertyAddress IS NULL

----------------------------------------------------------------
--  Breaking out PropertyAddress into Individual Columns (address, city, State) Using SUBSTRING() --
----------------------------------------------------------------
-- Delimiter is a comma
SELECT PropertyAddress
FROM [data_cleaning_project].[dbo].[nashville_housing]

-- Seperates street address and city
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address1,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address2
FROM [data_cleaning_project].[dbo].[nashville_housing]

--Creates new column with NVARCHAR datatype and populates with StreetAddress
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add PropertyStreetAddress NVARCHAR(255);

UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

--Creates new column with NVARCHAR datatype and populates with City
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add PropertyCity NVARCHAR(255);

UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

----------------------------------------------------------------
--  Breaking out OwnerAddress into Individual Columns (address, city, State) USING PARSESTRING() --
----------------------------------------------------------------
-- Delimiter is a comma
SELECT OwnerAddress
FROM [data_cleaning_project].[dbo].[nashville_housing]

-- Seperates street address, city and state using PARSENAME()
-- PARSENAME() only works with . not , so changed all , to . in OwnerAddress
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM [data_cleaning_project].[dbo].[nashville_housing]

--Creates new column with NVARCHAR datatype and populates with StreetAddress
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add OwnerStreetAddress NVARCHAR(255);

UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

--Creates new column with NVARCHAR datatype and populates with City
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add OwnerCity NVARCHAR(255);

UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

--Creates new column with NVARCHAR datatype and populates with State
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
Add OwnerState NVARCHAR(255);

UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

----------------------------------------------------------------
--  Change Y/N to Yes and No in SoldAsVacant --
----------------------------------------------------------------

-- Seeing what the current values are and the number of each type
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) NumResponse
FROM [data_cleaning_project].[dbo].[nashville_housing]
GROUP BY SoldAsVacant
ORDER BY NumResponse

-- Converting Y and N to Yes and No
UPDATE [data_cleaning_project].[dbo].[nashville_housing]
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM [data_cleaning_project].[dbo].[nashville_housing]

-- Confirmed that all values are now only Yes and No

----------------------------------------------------------------
--  Remove Duplicates --
----------------------------------------------------------------
-- CTE created to delete the duplicated rows
-- Created row_num column to identify duplicate rows and deleted all duplicate rows
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    ORDER BY
        UniqueID
        ) row_num
FROM [data_cleaning_project].[dbo].[nashville_housing]
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

----------------------------------------------------------------
--  Delete Unused Columns --
----------------------------------------------------------------
ALTER TABLE [data_cleaning_project].[dbo].[nashville_housing]
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate
