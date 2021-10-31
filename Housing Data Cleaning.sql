/*
	EXPLORATORY ANALYSIS OF PROPERTY DATA
*/

-- Cleaning the Data
SELECT *
FROM FolioProject..NashvilleHousing

-- Changing	Date Format to DATE from DATETIME and Updating Table

SELECT SaleDateConverted, CONVERT(DATE, SaleDate) AS NewSaleDate
FROM FolioProject..NashvilleHousing

/* NOT WORKING DUE TO SOME UNKNOWN ERROR

UPDATE FolioProject..NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate)

*/

-- Using ALTER TABLE then UPDATE-SET
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

-- Analysing the PropertyAddress column

SELECT PropertyAddress
FROM NashvilleHousing
/* 
	1. Duplicates are present 
	2. NULL values present
	3. Street and State are separated by comma.
*/

SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID 
/* 
	Property Address remains the same even if the owner or owner address changes. 
	Therefore we can fill in the NULLs (or) Populate the NULL fields.
	It is clear that identical Parcel Ids are present which have the same address.
	Therefore ParcelIds which have atleast one PropertyAddress value followed by NULLs will have the same PropertyAddress value
*/

-- Populating the PropertyAddress

/*
	Self joining to check for identical ParcelIDs and filling corresponding NULL PropertyAddresses
*/

SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) -- If <first> is NULL show <second>
FROM 
	FolioProject..NashvilleHousing a
JOIN
	FolioProject..NashvilleHousing b
ON 
	a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ] --To not join the same rows
WHERE
	a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM 
	FolioProject..NashvilleHousing a
JOIN
	FolioProject..NashvilleHousing b
ON 
	a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE
	a.PropertyAddress IS NULL

-- Splitting PropertyAddress into individual columns (Address, City, State)

SELECT PropertyAddress
FROM FolioProject..NashvilleHousing 

/* Shows address split by commas */

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	-- Start till comma ('- 1' to exclude the comma)
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
	-- Comma till end ('+ 1' for position just after comma)
FROM FolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)


ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
---------------------------------------------------------------------------------------

/* 
	SHORTER WAY TO SPLIT ADDRESSES
*/
SELECT PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2) AS ParsePropertySplitAddress
FROM FolioProject..NashvilleHousing
-- PARSENAME: Splits into columns using period (.) as delimiter
SELECT PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1) AS ParsePropertySplitCity
FROM FolioProject..NashvilleHousing

/*
	SAVE TABLE AS

ALTER TABLE NashvilleHousing
ADD ParsePropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET ParsePropertySplitAddress = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2)


ALTER TABLE NashvilleHousing
ADD ParsePropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET ParsePropertySplitCity = PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1)
*/

-- Splitting OwnerAddress into individual columns (Address, City, State)

/* 
	Note: Owner Addresses can be NULLs
	Using shorter way	
*/

SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
	PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM FolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

-- Change Y and N to Yes and No respectively

SELECT 
	SoldAsVacant,
	COUNT(SoldAsVacant)
FROM FolioProject..NashvilleHousing
GROUP BY SoldAsVacant

SELECT 
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM FolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET
	SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-- Removing Duplicates

/* Using Row Number to identify duplicates due to the amount of data and the ease in doing it */
WITH RowNumCTE AS( --Using CTE to pick out just the dupicates using WHERE statement
	SELECT 
		*,
		ROW_NUMBER() OVER(
							PARTITION BY ParcelID,
										 PropertyAddress,
										 SalePrice,
										 SaleDate,
										 LegalReference
							ORDER BY UniqueID
							) row_num
	FROM FolioProject..NashvilleHousing
)
/*
	TO DISPLAY THE DUPLICATES
	SELECT *
	FROM RowNumCTE
	WHERE row_num > 1
*/

/* DELETE DATA IF ONLY NECESSARY */
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Delete unused items (NOT RECOMMENDED)

SELECT *
FROM FolioProject..NashvilleHousing

ALTER TABLE FolioProject..NashvilleHousing
DROP COLUMN 
	OwnerAddress,
	TaxDistrict,
	PropertyAddress,
	SaleDate
