-- OBJECTIVE: Cleaning Data in SQL Queries

SELECT *
FROM nashville_housing
;

-- OBJECTIVE: Standardize Date Format

SELECT 
	SaleDate, 
    DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %d, %Y'), '%Y-%m-%d') AS convertdate
FROM 
	nashville_housing
;

UPDATE nashville_housing
SET SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %d, %Y'), '%Y-%m-%d')
;


-- OBJECTIVE: Populate Property Address Data
	-- Checking the data itself
    
SELECT 
	*
FROM
	nashville_housing
WHERE
	PropertyAddress IS NULL
;

SELECT 
	*
FROM
	nashville_housing
ORDER BY
	ParcelID
;

	-- Checking NULL issues in Property Address

SELECT 
	nv1.ParcelID, 
    nv1.PropertyAddress, 
    nv2.ParcelID, 
    nv2.PropertyAddress, 
    IFNULL(nv1.PropertyAddress,nv2.PropertyAddress)
FROM
	nashville_housing AS nv1
JOIN
	nashville_housing AS nv2
	ON nv1.ParcelID = nv2.ParcelID
	AND nv1.UniqueID != nv2.UniqueID
WHERE
	nv1.PropertyAddress IS NULL
;

	-- Updating the Property Address in the table

UPDATE
	nashville_housing AS nv1
JOIN
	nashville_housing AS nv2
	ON nv1.ParcelID = nv2.ParcelID
	AND nv1.UniqueID != nv2.UniqueID
SET
	nv1.PropertyAddress = IFNULL(nv1.PropertyAddress,nv2.PropertyAddress)
WHERE
	nv1.PropertyAddress IS NULL
;


-- OBJECTIVE: Breaking out address into individual columns (Address, City, State)
	-- Split Address into 3 columns
    
SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1) AS Address,
	SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1) AS Address
FROM
	nashville_housing
;

	-- Add new columns and insert new adress that already been split
		-- ISSUE: In MySQL, it is invalid function to execute NVARCHAR(255): 
			-- 3720 NATIONAL/NCHAR/NVARCHAR implies the character set UTF8MB3, which will be replaced by UTF8MB4 in a future release. Please consider using CHAR(x) CHARACTER SET UTF8MB4 in order to be unambiguous. Records: 0  Duplicates: 0  Warnings: 1
		-- FIX: Use VARCHAR(255) CHARACTER SET utf8mb4 instead NVARCHAR(255) to avoid future warning
        -- BONUS TIPS: NVARCHAR is actually used in SSMS (SQL Server)
        
ALTER TABLE 
	nashville_housing
	ADD PropertySplitAddress NVARCHAR(255)
;
    
UPDATE
	nashville_housing
SET
	PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1)
;

ALTER TABLE 
	nashville_housing
	ADD PropertySplitCity nvarchar(255)
;
   
UPDATE
	nashville_housing
SET
	PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1)
;


	-- Split Owner Address into new each columns
		

SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Part1, 
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS Part2,
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS Part3
FROM
    nashville_housing
;

	-- Update split data from OwnerAddress to their own column

ALTER TABLE 
	nashville_housing
	ADD OwnerSplitAddress VARCHAR(255) CHARACTER SET utf8mb4,
	ADD OwnerSplitCity VARCHAR(255) CHARACTER SET utf8mb4,
    ADD OwnerSplitState VARCHAR(255) CHARACTER SET utf8mb4
;
   
UPDATE
	nashville_housing
SET
	OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
    OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1)
;


-- OBJECTIVE: Change Y and N to Yes and No in "Sold in Vacant" field
	-- Checking the SoldAsVacant column
    
SELECT
	DISTINCT(SoldAsVacant), count(SoldAsVacant)
FROM
	nashville_housing
GROUP BY 
	SoldAsVacant
ORDER BY 2
;

SELECT
	SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END AS Updating_SoldAsVacant
FROM
	nashville_housing
;

	-- Updating changing in SoldAsVacant's column
    
UPDATE
	nashville_housing
SET
	SoldAsVacant = 
		CASE
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
		END
;


-- OBJECTIVE: Remove duplicates
	-- ADDED CTE
    -- IMPORTANT TIPS: Do not removes any data by using a raw data. Best advise is create duplicated data to avoid deleting raw data
    
WITH RowNumCTE AS
(
SELECT 
	*,
    ROW_NUMBER() OVER 
    (PARTITION BY 
		ParcelID, 
        PropertyAddress, 
        SalePrice, 
        SaleDate, 
        LegalReference 
        ORDER BY 
			UniqueID
		) AS row_num
FROM
	nashville_housing
)

DELETE
FROM
	nashville_housing
WHERE
	(ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference) 
    IN (
        SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
        FROM RowNumCTE
        WHERE row_num > 1
        )
;


-- OBJECTIVE: Delete unused columns

ALTER TABLE
	nashville_housing
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict
;

ALTER TABLE
	nashville_housing
DROP COLUMN SaleDate 
;

----------------------- END OF THE PROJECT

-- Double Check the table

SELECT 
	*
FROM
	nashville_housing
;
