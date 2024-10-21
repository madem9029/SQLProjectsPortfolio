/*

Cleaning Data in SQl Queries

*/

Select * 
From projectPortfolio..NashvilleHousing

--1) Standardize/change the sale date format
Select SaleDate--, CONVERT(date,SaleDate)
From projectPortfolio..NashvilleHousing

--Change the data type from "datetime" to "date"
ALTER TABLE NashvilleHousing
ALter Column
SaleDate date

/* or 
ALTER TABLE NashvilleHousing
add SaleDateConverted; 

update NashvilleHousing
Set SaleDateCOnverted = CONVERT(date, SaleDate)

*/

--------------------------------------------------------------------------------
--2) Populate property address data
--(Checking the data)
Select * --PropertyAddress
From projectPortfolio..NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

--Self join on table to look at if 'a.ParcelID' = 'b.ParcelID' then 'a.propertyAddress' = 'b.propertyAddress' 
--in order to get rid of the NULL values. 
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
--Check to see if 'a.propertyAddress' is null and if so populate with 'b.propertyAddress'
ISNULL(a.PropertyAddress, b.PropertyAddress)
From projectPortfolio..NashvilleHousing a
JOIN projectPortfolio..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	--Make sure the 'UniqueID' stays distinct
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--Update the table 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From projectPortfolio..NashvilleHousing a
JOIN projectPortfolio..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	--Make sure the 'UniqueID' stays distinct
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null
--------------------------------------------------------------------------------
--3) Breaking out Address into individual columns (Address, City, State)
--Checking the data
Select PropertyAddress
From projectPortfolio..NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID


Select
--Use "Substring" to extract a portion of the string
--Use "CHARINDEX" to find the first occurence of the character (, ) specified
--Added the -1 to get rid of the comma in the output
Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, 
--Took the 1 out of the "substring" to start at where the "CHARINDEX" is ','
-- Added +1 to start at the comma and go from there
--Added "LEN()" to where it need to go to/finish due to the varying lengths of each address
Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address

From projectPortfolio..NashvilleHousing

--Creating 2 new columns in order to serperate the values from the 'PropertyAddess' column

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--Viewing updated data

Select *
From projectPortfolio..NashvilleHousing

--Doing the same for the 'OwnerAddress'
Select OwnerAddress
From projectPortfolio..NashvilleHousing
--Use "Pasrename" instead of "Substring" and "Charindex"
--Replace the ',' with a 'period' since parsename looks for '.'
--sINCE "PARSENAME" does things backwards we adjust the output accordingly
Select
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
From projectPortfolio..NashvilleHousing

--Altering and updating the data
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)

--View the updated data
Select *
From projectPortfolio..NashvilleHousing
--------------------------------------------------------------------------------
--4) Change Y and N to YEs and No in 'Sold as Vacant' field
--Viewing the data in terms of how much Y and N are in the data 
Select Distinct(SoldAsVacant), count(SoldAsVacant)
From projectPortfolio..NashvilleHousing
group by SoldAsVacant
order by 2

Select SoldAsVacant
--Case statement to change Y to Yes and N to No
, CASE when SoldAsVacant = 'Y' THEN 'Yes'
	   when SoldAsVacant = 'N' THEN 'No'
	   --If the Value is already Yes/No then keep the value the same
	   ELSE SoldAsVacant
	   --Ending the case statement
	   END
From projectPortfolio..NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN 'Yes'
	   when SoldAsVacant = 'N' THEN 'No'
	   --If the Value is already Yes/No then keep the value the same
	   ELSE SoldAsVacant
	   --Ending the case statement
	   END
--------------------------------------------------------------------------------
--5) Remove duplicates
--Create CTE in order to use the column created within the window function
WITH RowNumCTE as (
Select *, 
	--Giving a unique integer to the rows 
	--Will help us find any duplicates in the data
	ROW_NUMBER() OVER(
	--Dividing the result into partitions on data that should be unique to each row
	PARTITION BY ParcelID,
				 PropertyAddress, 
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID) Row_num
from projectPortfolio..NashvilleHousing
)
--Deleating all of the duplicate rows
DELETE
From RowNumCTE
Where Row_num > 1
--------------------------------------------------------------------------------
--6) Delete unused columns ('PropertyAddress', 'OwnerAddress') SInce we made new columns for them
ALTER TABLE projectPortfolio..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress

--Vewing the updated table
Select *
From projectPortfolio..NashvilleHousing