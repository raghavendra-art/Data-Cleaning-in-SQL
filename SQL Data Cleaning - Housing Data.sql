select * from Portfolio.dbo.NashvilleHousing

---------------Standardize Dat Format-------------------------------

select SaleDate, convert(Date,Saledate) 
from Portfolio.dbo.NashvilleHousing

--above worked

update portfolio..NashvilleHousing 
set SaleDate = convert(Date,Saledate)

--above didnt work

Alter table portfolio..NashvilleHousing
add SaleDateConverted date;

-- so added a new column

update portfolio..NashvilleHousing
set SaleDateConverted = convert(Date,Saledate)

-- added values to new column above

select SaleDateConverted 
from Portfolio.dbo.NashvilleHousing

-- confirmed new column values above

-----------------------Populate property address------------------------------

Select PropertyAddress
from Portfolio.dbo.NashvilleHousing
where PropertyAddress is null

 ----- usually propert address should never change------------- 
 --------owners address can change but no properties------------

----- After exploring columns, I found that ParceID and PropertyAddress are interlinked------
------Therefore, I populated propertyaddress for those Null values as per their ParcelID

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, isnull(a.PropertyAddress,b.PropertyAddress) as populatedAddress
from Portfolio.dbo.NashvilleHousing a 
join Portfolio.dbo.NashvilleHousing b 
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] != b.[UniqueID ]
	where a.PropertyAddress is null


-- above code--
--- we joined same table on parcel ID but not matching UniqueID(unique) so that we get all values where ParcelID matches
-- and unique doesnt match.. basically.. all ones which are unique but parcelID matches


update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from Portfolio.dbo.NashvilleHousing a 
join Portfolio.dbo.NashvilleHousing b 
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] != b.[UniqueID ]
	where a.PropertyAddress is null

-- above is to update null values of addressproperty

-- Breaking out Address into Individual Columns (Address, City, State)

select PropertyAddress
from Portfolio.dbo.NashvilleHousing

select PropertyAddress, 
SUBSTRING(PropertyAddress,1,Charindex(',',PropertyAddress)-1),
SUBSTRING(PropertyAddress,Charindex(',',PropertyAddress)+1,len(PropertyAddress))
from Portfolio.dbo.NashvilleHousing

--- CharIndex gives the number where the string is located.. therefore -1 is gives until the previous value
--- CharIndex gives the number where the string is located.. therefore +1 is gives until the previous value

-- now create two columns and add those values

ALTER TABLE Portfolio..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update Portfolio..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE Portfolio..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update Portfolio..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

select * 
from Portfolio..NashvilleHousing


--------- Now just like property address.. I have split owner address also----
---------here we need to split address, city and State----------
--------- Therefore, we use Parsename function----------

select
Parsename(Replace(owneraddress,',','.'),3),
Parsename(Replace(owneraddress,',','.'),2),
Parsename(Replace(owneraddress,',','.'),1)
from NashvilleHousing


------------- things to note, parsename looks for '.' to parse---------------\
-------------- Therefore replace commas with periods and then pass in parsename---------------


ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


------ to crosscheck-------
Select *
From Portfolio.dbo.NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant) , count(SoldAsVacant)
From Portfolio.dbo.NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant,
	   case when SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Portfolio.dbo.NashvilleHousing

update Portfolio.dbo.NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Portfolio.dbo.NashvilleHousing


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

--- we can use denserank, rank , row_number() functions to remove duplicates-----
--- here we will be using row_number()

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Portfolio.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

---------above run_num is the alias----------------
---------After running above, i found 104 rows as duplicates.. 
-------- soo we will go ahead and delete those rows.


WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Portfolio.dbo.NashvilleHousing
--order by ParcelID
)
Delete 
From RowNumCTE
Where row_num > 1

-------------above deleted all of them------------------

-- Delete Unused Columns



Select *
From Portfolio.dbo.NashvilleHousing


ALTER TABLE Portfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
