SELECT TOP (1000) *
FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
-------------------------------------------------------------------------------
-- Create temp table for all changes to avoid permanent changes to raw data --
-------------------------------------------------------------------------------
-- Retrieve current schema
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'Motor_Vehicle_Collisions_Crashes'

--Creats temporary table names #VEHICLE_COLLISIONS_TEMP
DROP TABLE [#VEHICLE_COLLISIONS_TEMP]

SELECT 
    CRASH_DATE,
    CRASH_TIME,
    BOROUGH,
    ZIP_CODE,
    LATITUDE,
    LONGITUDE,
    LOCATION,
    ON_STREET_NAME,
    CROSS_STREET_NAME,
    OFF_STREET_NAME,
    NUMBER_OF_PERSONS_INJURED,
    NUMBER_OF_PERSONS_KILLED,
    NUMBER_OF_PEDESTRIANS_INJURED,
    NUMBER_OF_PEDESTRIANS_KILLED,
    NUMBER_OF_CYCLIST_INJURED,
    NUMBER_OF_CYCLIST_KILLED,
    NUMBER_OF_MOTORIST_INJURED,
    NUMBER_OF_MOTORIST_KILLED,
    CONTRIBUTING_FACTOR_VEHICLE_1,
    CONTRIBUTING_FACTOR_VEHICLE_2,
    CONTRIBUTING_FACTOR_VEHICLE_3,
    CONTRIBUTING_FACTOR_VEHICLE_4,
    CONTRIBUTING_FACTOR_VEHICLE_5,
    COLLISION_ID,
    VEHICLE_TYPE_CODE_1,
    VEHICLE_TYPE_CODE_2,
    VEHICLE_TYPE_CODE_3,
    VEHICLE_TYPE_CODE_4,
    VEHICLE_TYPE_CODE_5
INTO #VEHICLE_COLLISIONS_TEMP
FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
WHERE COLLISION_ID IS NOT NULL

--Confirmed all data appears to have been transferred to temp table
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
EXCEPT
SELECT * FROM #VEHICLE_COLLISIONS_TEMP

-------------------------------------------------------------------------------
-- Populate ZIP_CODE values that are null using ON_STREET_NAME and CROSS_STREET_NAME --
-------------------------------------------------------------------------------
SELECT TOP (1000) *
FROM [#VEHICLE_COLLISIONS_TEMP]

-- 603982 ZIP_CODE NULL values
SELECT COUNT(*)
FROM #VEHICLE_COLLISIONS_TEMP
WHERE ZIP_CODE IS NULL

-- Inner Join to match zipcode of a to b zipcode then populating null zipcodes
UPDATE a
SET ZIP_CODE = ISNULL(a.ZIP_CODE, b.ZIP_CODE)
FROM [#VEHICLE_COLLISIONS_TEMP] a
JOIN [#VEHICLE_COLLISIONS_TEMP] b
    ON a.ON_STREET_NAME = b.ON_STREET_NAME
    AND a.CROSS_STREET_NAME = b.CROSS_STREET_NAME
    AND a.[COLLISION_ID] <> b.[COLLISION_ID]
WHERE a.ZIP_CODE IS NULL

-- 597452 ZIP_CODE NULL values, reduced NULL values by 6285
SELECT COUNT(*)
FROM #VEHICLE_COLLISIONS_TEMP
WHERE ZIP_CODE IS NULL

-- 48885 instances of no location data recorded. OFF_STREET_NAME not included because it is described area, not location
SELECT COUNT(*)
FROM #VEHICLE_COLLISIONS_TEMP
WHERE 
    ZIP_CODE IS NULL 
    AND BOROUGH IS NULL
    AND LATITUDE IS NULL
    AND LONGITUDE IS NULL
    AND LOCATION IS NULL
    AND ON_STREET_NAME IS NULL
    AND CROSS_STREET_NAME IS NULL

-- Removed rows with no location data
DELETE 
FROM #VEHICLE_COLLISIONS_TEMP
WHERE 
    ZIP_CODE IS NULL 
    AND BOROUGH IS NULL
    AND LATITUDE IS NULL
    AND LONGITUDE IS NULL
    AND LOCATION IS NULL
    AND ON_STREET_NAME IS NULL
    AND CROSS_STREET_NAME IS NULL

-------------------------------------------------------------------------------
-- Cleaning String Values for Contributing_Factor_Vehicle_N --
-------------------------------------------------------------------------------

-- Confirms that no clerical errors were made. If CONTRIBUTING_FACTOR_VEHICLE_1 is 'Unspecified', then others are unspecified or null
SELECT *
FROM #VEHICLE_COLLISIONS_TEMP
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 = 'Unspecified' AND
    ((CONTRIBUTING_FACTOR_VEHICLE_2 <> 'Unspecified' 
    AND CONTRIBUTING_FACTOR_VEHICLE_2 IS NOT NULL)
    OR (CONTRIBUTING_FACTOR_VEHICLE_3 <> 'Unspecified' 
    AND CONTRIBUTING_FACTOR_VEHICLE_3 IS NOT NULL)
    OR (CONTRIBUTING_FACTOR_VEHICLE_4 <> 'Unspecified' 
    AND CONTRIBUTING_FACTOR_VEHICLE_4 IS NOT NULL)
    OR (CONTRIBUTING_FACTOR_VEHICLE_4 <> 'Unspecified' 
    AND CONTRIBUTING_FACTOR_VEHICLE_4 IS NOT NULL))

-- Illness has misspellings as Illnes. Corrected all misspellings in the 5 columns. 
UPDATE #VEHICLE_COLLISIONS_TEMP
SET
CONTRIBUTING_FACTOR_VEHICLE_1 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_1, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_2 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_2, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_3 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_3, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_4 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_4, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_5 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_5, 'Illnes', 'Illness')

--Must replace with 'Illnes' to avoid correting 'Illness' to 'Illnesss'
UPDATE #VEHICLE_COLLISIONS_TEMP
SET
CONTRIBUTING_FACTOR_VEHICLE_1 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_1, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_2 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_2, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_3 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_3, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_4 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_4, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_5 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_5, 'Illnesss', 'Illness')

--
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_1 FROM #VEHICLE_COLLISIONS_TEMP
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_2 FROM #VEHICLE_COLLISIONS_TEMP
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_3 FROM #VEHICLE_COLLISIONS_TEMP
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_4 FROM #VEHICLE_COLLISIONS_TEMP
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_5 FROM #VEHICLE_COLLISIONS_TEMP



SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_1, COUNT(CONTRIBUTING_FACTOR_VEHICLE_1) AS NUM_1
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY CONTRIBUTING_FACTOR_VEHICLE_1
ORDER BY NUM_1 DESC

SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_2, COUNT(CONTRIBUTING_FACTOR_VEHICLE_2) AS NUM_2
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY CONTRIBUTING_FACTOR_VEHICLE_2
ORDER BY NUM_2 DESC

-------------------------------------------------------------------------------
-- Aggregating the Contributing Factors Columns --
-------------------------------------------------------------------------------

ALTER TABLE #VEHICLE_COLLISIONS_TEMP
ADD 
    CONTRIBUTING_FACTORS_1 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_2 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_3 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_4 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_5 VARCHAR(MAX)

ALTER TABLE #VEHICLE_COLLISIONS_TEMP
DROP COLUMN
    CONTRIBUTING_FACTORS_1,
    CONTRIBUTING_FACTORS_2,
    CONTRIBUTING_FACTORS_3,
    CONTRIBUTING_FACTORS_4,
    CONTRIBUTING_FACTORS_5

DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'CONTRIBUTING_FACTORS_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
DECLARE @ORIG_COL_NAME VARCHAR(MAX) = 'CONTRIBUTING_FACTOR_VEHICLE_'
DECLARE @ORIG_FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @ORIG_FULL_COL_NAME = @ORIG_COL_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [#VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Unspecified''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Unspecified'',''80'',''1'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

SELECT CONTRIBUTING_FACTORS_1
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY CONTRIBUTING_FACTORS_1


BEGIN
UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Unspecified'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Unspecified',
'80', 
'1'
)
END

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Driver Distracted'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Driver Inattention/Distraction',
'Outside Car Distraction',
'Passenger Distraction',
'Eating or Drinking'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Vehicle Defective'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Brakes Defective',
'Steering Failure',
'Tire Failure/Inadequate',
'Accelerator Defective',
'Tow Hitch Defective',
'Windshield Inadequate',
'Tinted Windows',
'Headlights Defective',
'View Obstructed/Limited',
'Oversized Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Driver Error'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Failure to Yield Right-of-Way',
'Following Too Closely',
'Backing Unsafely',
'Passing or Lane Usage Improper',
'Passing Too Closely',
'Turning Improperly',
'Unsafe Lane Changing',
'Driver Inexperience',
'Failure to Keep Right',
'Traffic Control Disregarded',
'Unsafe Speed',
'Aggressive Driving/Road Rage',
'Reaction to Uninvolved Vehicle',
'Reaction to Other Uninvolved Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Electronic Device Distraction'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Cell Phone (hand-held)',
'Cell Phone (hands-free)',
'Using On Board Navigation Device',
'Texting',
'Listening/Using Headphones',
'Other Electronic Device'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Diver Influenced'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Alcohol Involvement',
'Drugs (Illegal)',
'Prescription Medication'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Street Conditions'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Pavement Defective',
'Pavement Slippery',
'Shoulders Defective/Improper',
'Lane Marking Improper/Inadequate',
'Traffic Control Device Improper/Non-Working',
'Other Lighting Defects',
'Obstruction/Debris',
'Glare'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Driver Fatigue'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Fatigued/Drowsy',
'Fell Asleep'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = 'Driver Illness'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Lost Consciousness',
'Illness',
'Physical Disability'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_1 = '3rd Party'
WHERE CONTRIBUTING_FACTOR_VEHICLE_1 IN ('Pedestrian/Bicyclist/Other Pedestrian Error/Confusion',
'Driverless/Runaway Vehicle',
'Vehicle Vandalism',
'Animals Action'
)

SELECT DISTINCT CONTRIBUTING_FACTORS_1, COUNT(CONTRIBUTING_FACTORS_1) AS NUM_1
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY CONTRIBUTING_FACTORS_1
ORDER BY NUM_1 DESC

---------
UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Unspecified'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Unspecified',
'80', 
'1'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Driver Distracted'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Driver Inattention/Distraction',
'Outside Car Distraction',
'Passenger Distraction',
'Eating or Drinking'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Vehicle Defective'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Brakes Defective',
'Steering Failure',
'Tire Failure/Inadequate',
'Accelerator Defective',
'Tow Hitch Defective',
'Windshield Inadequate',
'Tinted Windows',
'Headlights Defective',
'View Obstructed/Limited',
'Oversized Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Driver Error'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Failure to Yield Right-of-Way',
'Following Too Closely',
'Backing Unsafely',
'Passing or Lane Usage Improper',
'Passing Too Closely',
'Turning Improperly',
'Unsafe Lane Changing',
'Driver Inexperience',
'Failure to Keep Right',
'Traffic Control Disregarded',
'Unsafe Speed',
'Aggressive Driving/Road Rage',
'Reaction to Uninvolved Vehicle',
'Reaction to Other Uninvolved Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Electronic Device Distraction'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Cell Phone (hand-held)',
'Cell Phone (hands-free)',
'Using On Board Navigation Device',
'Texting',
'Listening/Using Headphones',
'Other Electronic Device'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Diver Influenced'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Alcohol Involvement',
'Drugs (Illegal)',
'Prescription Medication'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Street Conditions'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Pavement Defective',
'Pavement Slippery',
'Shoulders Defective/Improper',
'Lane Marking Improper/Inadequate',
'Traffic Control Device Improper/Non-Working',
'Other Lighting Defects',
'Obstruction/Debris',
'Glare'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Driver Fatigue'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Fatigued/Drowsy',
'Fell Asleep'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = 'Driver Illness'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Lost Consciousness',
'Illness',
'Physical Disability'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_2 = '3rd Party'
WHERE CONTRIBUTING_FACTOR_VEHICLE_2 IN ('Pedestrian/Bicyclist/Other Pedestrian Error/Confusion',
'Driverless/Runaway Vehicle',
'Vehicle Vandalism',
'Animals Action'
)

----
UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Unspecified'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Unspecified',
'80', 
'1'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Driver Distracted'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Driver Inattention/Distraction',
'Outside Car Distraction',
'Passenger Distraction',
'Eating or Drinking'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Vehicle Defective'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Brakes Defective',
'Steering Failure',
'Tire Failure/Inadequate',
'Accelerator Defective',
'Tow Hitch Defective',
'Windshield Inadequate',
'Tinted Windows',
'Headlights Defective',
'View Obstructed/Limited',
'Oversized Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Driver Error'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Failure to Yield Right-of-Way',
'Following Too Closely',
'Backing Unsafely',
'Passing or Lane Usage Improper',
'Passing Too Closely',
'Turning Improperly',
'Unsafe Lane Changing',
'Driver Inexperience',
'Failure to Keep Right',
'Traffic Control Disregarded',
'Unsafe Speed',
'Aggressive Driving/Road Rage',
'Reaction to Uninvolved Vehicle',
'Reaction to Other Uninvolved Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Electronic Device Distraction'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Cell Phone (hand-held)',
'Cell Phone (hands-free)',
'Using On Board Navigation Device',
'Texting',
'Listening/Using Headphones',
'Other Electronic Device'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Diver Influenced'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Alcohol Involvement',
'Drugs (Illegal)',
'Prescription Medication'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Street Conditions'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Pavement Defective',
'Pavement Slippery',
'Shoulders Defective/Improper',
'Lane Marking Improper/Inadequate',
'Traffic Control Device Improper/Non-Working',
'Other Lighting Defects',
'Obstruction/Debris',
'Glare'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Driver Fatigue'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Fatigued/Drowsy',
'Fell Asleep'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = 'Driver Illness'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Lost Consciousness',
'Illness',
'Physical Disability'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_3 = '3rd Party'
WHERE CONTRIBUTING_FACTOR_VEHICLE_3 IN ('Pedestrian/Bicyclist/Other Pedestrian Error/Confusion',
'Driverless/Runaway Vehicle',
'Vehicle Vandalism',
'Animals Action'
)
------------
UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Unspecified'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Unspecified',
'80', 
'1'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Driver Distracted'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Driver Inattention/Distraction',
'Outside Car Distraction',
'Passenger Distraction',
'Eating or Drinking'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Vehicle Defective'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Brakes Defective',
'Steering Failure',
'Tire Failure/Inadequate',
'Accelerator Defective',
'Tow Hitch Defective',
'Windshield Inadequate',
'Tinted Windows',
'Headlights Defective',
'View Obstructed/Limited',
'Oversized Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Driver Error'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Failure to Yield Right-of-Way',
'Following Too Closely',
'Backing Unsafely',
'Passing or Lane Usage Improper',
'Passing Too Closely',
'Turning Improperly',
'Unsafe Lane Changing',
'Driver Inexperience',
'Failure to Keep Right',
'Traffic Control Disregarded',
'Unsafe Speed',
'Aggressive Driving/Road Rage',
'Reaction to Uninvolved Vehicle',
'Reaction to Other Uninvolved Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Electronic Device Distraction'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Cell Phone (hand-held)',
'Cell Phone (hands-free)',
'Using On Board Navigation Device',
'Texting',
'Listening/Using Headphones',
'Other Electronic Device'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Diver Influenced'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Alcohol Involvement',
'Drugs (Illegal)',
'Prescription Medication'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Street Conditions'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Pavement Defective',
'Pavement Slippery',
'Shoulders Defective/Improper',
'Lane Marking Improper/Inadequate',
'Traffic Control Device Improper/Non-Working',
'Other Lighting Defects',
'Obstruction/Debris',
'Glare'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Driver Fatigue'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Fatigued/Drowsy',
'Fell Asleep'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = 'Driver Illness'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Lost Consciousness',
'Illness',
'Physical Disability'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_4 = '3rd Party'
WHERE CONTRIBUTING_FACTOR_VEHICLE_4 IN ('Pedestrian/Bicyclist/Other Pedestrian Error/Confusion',
'Driverless/Runaway Vehicle',
'Vehicle Vandalism',
'Animals Action'
)


----------
UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Unspecified'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Unspecified',
'80', 
'1'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Driver Distracted'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Driver Inattention/Distraction',
'Outside Car Distraction',
'Passenger Distraction',
'Eating or Drinking'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Vehicle Defective'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Brakes Defective',
'Steering Failure',
'Tire Failure/Inadequate',
'Accelerator Defective',
'Tow Hitch Defective',
'Windshield Inadequate',
'Tinted Windows',
'Headlights Defective',
'View Obstructed/Limited',
'Oversized Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Driver Error'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Failure to Yield Right-of-Way',
'Following Too Closely',
'Backing Unsafely',
'Passing or Lane Usage Improper',
'Passing Too Closely',
'Turning Improperly',
'Unsafe Lane Changing',
'Driver Inexperience',
'Failure to Keep Right',
'Traffic Control Disregarded',
'Unsafe Speed',
'Aggressive Driving/Road Rage',
'Reaction to Uninvolved Vehicle',
'Reaction to Other Uninvolved Vehicle'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Electronic Device Distraction'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Cell Phone (hand-held)',
'Cell Phone (hands-free)',
'Using On Board Navigation Device',
'Texting',
'Listening/Using Headphones',
'Other Electronic Device'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Diver Influenced'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Alcohol Involvement',
'Drugs (Illegal)',
'Prescription Medication'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Street Conditions'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Pavement Defective',
'Pavement Slippery',
'Shoulders Defective/Improper',
'Lane Marking Improper/Inadequate',
'Traffic Control Device Improper/Non-Working',
'Other Lighting Defects',
'Obstruction/Debris',
'Glare'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Driver Fatigue'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Fatigued/Drowsy',
'Fell Asleep'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = 'Driver Illness'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Lost Consciousness',
'Illness',
'Physical Disability'
)

UPDATE #VEHICLE_COLLISIONS_TEMP
SET CONTRIBUTING_FACTORS_5 = '3rd Party'
WHERE CONTRIBUTING_FACTOR_VEHICLE_5 IN ('Pedestrian/Bicyclist/Other Pedestrian Error/Confusion',
'Driverless/Runaway Vehicle',
'Vehicle Vandalism',
'Animals Action'
)

-------------------------------------------------------------------------------
-- Cleaning String Values for vehicle_type --
-------------------------------------------------------------------------------
-- 1002 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%AMB%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%BULA%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hosp%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%med%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'AMBULANCE'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%AMB%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%BULA%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hosp%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%med%'

-- 979 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%GOV%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'GOVERNMENT'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%GOV%'

-- 974 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%FDNY%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%FD%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Fir%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'FDNY'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%FDNY%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%FD%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Fir%'

-- 948 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%2%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%4%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Sed%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%PAS%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%SUV%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pick%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%door%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%van%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'PASSENGER VEHICLE'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%2%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%4%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Sed%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%PAS%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%SUV%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pick%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%door%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%van%'

-- 846 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%PD%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'NYPD'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%PD%'

-- 843 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%cat%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fork%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cons%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tractor'
    OR VEHICLE_TYPE_CODE_1 LIKE '%lift%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%crane%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%boom%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%excav%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dump%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%compactor%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bulldozer%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hoe%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bucket%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%conc%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mix%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cemen%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Tract'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'CONSTRUCTION'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%cat%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fork%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cons%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tractor'
    OR VEHICLE_TYPE_CODE_1 LIKE '%lift%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%crane%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%boom%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%excav%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dump%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%compactor%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bulldozer%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hoe%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bucket%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%conc%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mix%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cemen%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Tract'

-- 785 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE (VEHICLE_TYPE_CODE_1 LIKE '%box%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mack%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%truck%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trail%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%flat%')
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%PICK%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'COMMERCIAL TRUCK'
WHERE (VEHICLE_TYPE_CODE_1 LIKE '%box%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mack%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%truck%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trail%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%flat%')
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%PICK%'

-- 742 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%ups%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fedex%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fdX%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%uhaul%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ship'
    OR VEHICLE_TYPE_CODE_1 LIKE '%usps%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%post%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hau%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%freig%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%deliv%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'DELIVERY'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%ups%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fedex%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fdX%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%uhaul%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ship'
    OR VEHICLE_TYPE_CODE_1 LIKE '%usps%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%post%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hau%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%freig%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%deliv%'

-- 702 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

SELECT VEHICLE_TYPE_CODE_1
FROM #VEHICLE_COLLISIONS_TEMP
WHERE VEHICLE_TYPE_CODE_1 LIKE '%bus%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trans%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%nj%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mta%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%port'
    OR VEHICLE_TYPE_CODE_1 LIKE '%school%'

UPDATE #VEHICLE_COLLISIONS_TEMP
SET
    VEHICLE_TYPE_CODE_1 = 'PUBLIC TRANSPORTATION'
WHERE VEHICLE_TYPE_CODE_1 LIKE '%bus%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trans%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%nj%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mta%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%port'
    OR VEHICLE_TYPE_CODE_1 LIKE '%school%'

-- 702 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM #VEHICLE_COLLISIONS_TEMP
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC