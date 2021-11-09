SELECT * FROM new_housing;

--STANDARDIZE  SaleDate
SELECT SaleDate,CONVERT(DATE,SaleDate) FROM new_housing;

ALTER TABLE new_housing
ADD STD_SaleDate DATE;

UPDATE new_housing
SET STD_SaleDate=CONVERT(DATE,SaleDate) 
FROM new_housing;

ALTER TABLE new_housing
DROP COLUMN SaleDate;

--REPLACE MISSING PropertyAddress
SELECT UniqueID,ParcelID,PropertyAddress,OwnerAddress,ROW_NUMBER() OVER(PARTITION BY ParcelID ORDER BY UniqueID) 
FROM new_housing
WHERE PropertyAddress is null;


SELECT a.PropertyAddress,b.PropertyAddress
FROM new_housing a
JOIN new_housing b
ON a.ParcelID=b.ParcelID and a.UniqueID<>b.UniqueID;


UPDATE a
SET PropertyAddress=b.PropertyAddress
FROM new_housing a
JOIN new_housing b
ON a.ParcelID=b.ParcelID and a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress is null;

--SplitAddress
---PropertyAddress
SELECT SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress))
FROM new_housing; 

ALTER TABLE new_housing
ADD PropertyAddressName varchar(200);
UPDATE new_housing
SET PropertyAddressName=SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)
FROM new_housing;

ALTER TABLE new_housing
ADD PropertyCityName varchar(100);
UPDATE new_housing
SET PropertyCityName=SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress))
FROM new_housing;

---OwnerAddress
SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1),
OwnerAddress
FROM new_housing
;

ALTER TABLE new_housing
ADD OwnerAddressName varchar(200);
UPDATE new_housing
SET OwnerAddressName=PARSENAME(REPLACE(OwnerAddress,',','.'),3)
FROM new_housing;

ALTER TABLE new_housing
ADD OwnerCityName varchar(100);
UPDATE new_housing
SET OwnerCityName=PARSENAME(REPLACE(OwnerAddress,',','.'),2)
FROM new_housing;

ALTER TABLE new_housing
ADD OwnerStateName varchar(50);
UPDATE new_housing
SET OwnerStateName=PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM new_housing;

ALTER TABLE new_housing
DROP COLUMN PropertyAddress;
ALTER TABLE new_housing
DROP Column OwnerAddress;

--CHANGE Y AND N TO YES AND NO IN SoldAsVacant COLUMN
SELECT SoldAsVacant,COUNT(SoldAsVacant) FROM new_housing
GROUP BY SoldAsVacant;

UPDATE new_housing
SET SoldAsVacant='Yes'
WHERE SoldAsVacant='Y';

UPDATE new_housing
SET SoldAsVacant='No'
WHERE SoldAsVacant='N';

--REMOVE DUPLICATES
WITH duplicate_cte AS 
(
SELECT *,ROW_NUMBER()
			OVER(PARTITION BY ParcelID,
							  LandUse,
							  LegalReference,
							  OwnerName,
							  STD_SaleDate,
							  PropertyAddressName,
							  OwnerAddressName
								ORDER BY UniqueID) row_num
FROM new_housing
) DELETE FROM duplicate_cte
WHERE row_num>1;


--DELETE THE REST OF THE UNUSED COLUMN
SELECT * from new_housing;

SELECT OwnerStateName,COUNT(OwnerStateName)
FROM new_housing
GROUP BY OwnerStateName;
----------all the state are the same

ALTER TABLE new_housing
DROP COLUMN TaxDistrict,OwnerStateName;