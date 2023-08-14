/*

Cleaning Data in SQL Queries

*/

SELECT * FROM NashvilleHousing;


SELECT 
  ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS recordNumber,
  NashvilleHousing.*
FROM NashvilleHousing;


-- ------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data


SELECT
	*
FROM
	housing.NashvilleHousing 
WHERE
	PropertyAddress IS NULL 
ORDER BY
	ParcelID
-- -----------------------
	
SELECT
  a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS MergedPropertyAddress
FROM
  housing.NashvilleHousing AS a
JOIN housing.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL;

-- -----------------------

UPDATE housing.NashvilleHousing AS a
JOIN housing.NashvilleHousing AS b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID 
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


-- ------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)


SELECT
  SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
  SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1 , LENGTH(PropertyAddress)) AS City
FROM
  housing.NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress =  SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1)



ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1 , LENGTH(PropertyAddress))


SELECT * FROM
  housing.NashvilleHousing;
	
-- ------------------------

SELECT
	OwnerAddress 
FROM
	housing.NashvilleHousing;


	
SELECT 
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1) AS Part1,
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS Part2,
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) AS Part3
FROM
  housing.NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1)




ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity =  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)



ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) 

	
SELECT * FROM
  housing.NashvilleHousing;

-- ------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 ;


SELECT SoldAsVacant,
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END
FROM housing.NashvilleHousing;



UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates



-- looking at the duplicates

WITH RowNumCTE AS(
SELECT
  *,
	ROW_NUMBER() OVER ( PARTITION BY 
	ParcelID,
	PropertyAddress, 
	SalePrice,
	SaleDate,
	LegalReference 
	ORDER BY UniqueID ) AS row_num 
FROM
	housing.NashvilleHousing 
-- ORDER BY ParcelID;
)
SELECT* 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY ParcelID;


-- -------------------
-- Create separate indexes on individual columns
CREATE INDEX idx_duplicate_ParcelID ON housing.NashvilleHousing (ParcelID);
CREATE INDEX idx_duplicate_PropertyAddress ON housing.NashvilleHousing (PropertyAddress);
CREATE INDEX idx_duplicate_SalePrice ON housing.NashvilleHousing (SalePrice);
CREATE INDEX idx_duplicate_SaleDate ON housing.NashvilleHousing (SaleDate);


-- Delete duplicate rows
DELETE t1
FROM housing.NashvilleHousing t1
JOIN housing.NashvilleHousing t2 ON 
  t1.ParcelID = t2.ParcelID AND
  t1.PropertyAddress = t2.PropertyAddress AND
  t1.SalePrice = t2.SalePrice AND
  t1.SaleDate = t2.SaleDate AND
  t1.LegalReference = t2.LegalReference AND
  t1.UniqueID < t2.UniqueID;





-- -------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE housing.NashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;


















