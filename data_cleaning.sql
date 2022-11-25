SELECT TOP (1000) *
FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
 
-------------------------------------------------------------------------------
-- Create temp table for all changes to avoid permanent changes to raw data --
-------------------------------------------------------------------------------
-- Retrieve current schema
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'Motor_Vehicle_Collisions_Crashes'

--Creates working table names [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]

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
INTO [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
WHERE COLLISION_ID IS NOT NULL

--Confirmed all data appears to have been transferred to temp table
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
EXCEPT
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]

-------------------------------------------------------------------------------
-- Populate ZIP_CODE values that are null using ON_STREET_NAME and CROSS_STREET_NAME --
-------------------------------------------------------------------------------
SELECT TOP (1000) *
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]

-- 603982 ZIP_CODE NULL values
SELECT COUNT(*)
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE ZIP_CODE IS NULL

-- Inner Join to match zipcode of a to b zipcode then populating null zipcodes
UPDATE a
SET ZIP_CODE = ISNULL(a.ZIP_CODE, b.ZIP_CODE)
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] a
JOIN [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] b
    ON a.ON_STREET_NAME = b.ON_STREET_NAME
    AND a.CROSS_STREET_NAME = b.CROSS_STREET_NAME
    AND a.[COLLISION_ID] <> b.[COLLISION_ID]
WHERE a.ZIP_CODE IS NULL

-- 597452 ZIP_CODE NULL values, reduced NULL values by 6285
SELECT COUNT(*)
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE ZIP_CODE IS NULL

-- 48885 instances of no location data recorded. OFF_STREET_NAME not included because it is described area, not location
SELECT COUNT(*)
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
SET
CONTRIBUTING_FACTOR_VEHICLE_1 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_1, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_2 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_2, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_3 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_3, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_4 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_4, 'Illnes', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_5 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_5, 'Illnes', 'Illness')

--Must replace with 'Illnes' to avoid correting 'Illness' to 'Illnesss'
UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
SET
CONTRIBUTING_FACTOR_VEHICLE_1 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_1, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_2 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_2, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_3 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_3, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_4 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_4, 'Illnesss', 'Illness'),
CONTRIBUTING_FACTOR_VEHICLE_5 = REPLACE(CONTRIBUTING_FACTOR_VEHICLE_5, 'Illnesss', 'Illness')

--Checking to see if there were additional contributing factors in columns 2-5 than in 1. There were none that weren't used in CONTRIBUTING_FACTOR_VEHICLE_1
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_1 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_2 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_3 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_4 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_5 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]

SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_1, COUNT(CONTRIBUTING_FACTOR_VEHICLE_1) AS NUM_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY CONTRIBUTING_FACTOR_VEHICLE_1
ORDER BY NUM_1 DESC

SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_2, COUNT(CONTRIBUTING_FACTOR_VEHICLE_2) AS NUM_2
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY CONTRIBUTING_FACTOR_VEHICLE_2
ORDER BY NUM_2 DESC

-------------------------------------------------------------------------------
-- Aggregating the Contributing Factors Columns --
-------------------------------------------------------------------------------
-- Added new columns for new factor grouping
ALTER TABLE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
ADD 
    CONTRIBUTING_FACTORS_1 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_2 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_3 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_4 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_5 VARCHAR(MAX)


ALTER TABLE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Unspecified''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Unspecified'',''80'',''1'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Driver Distracted''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Driver Inattention/Distraction'',
        ''Outside Car Distraction'',
        ''Passenger Distraction'',
        ''Eating or Drinking'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Vehicle Defective''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Brakes Defective'',
        ''Steering Failure'',
        ''Tire Failure/Inadequate'',
        ''Accelerator Defective'',
        ''Tow Hitch Defective'',
        ''Windshield Inadequate'',
        ''Tinted Windows'',
        ''Headlights Defective'',
        ''View Obstructed/Limited'',
        ''Oversized Vehicle'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Driver Error''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Failure to Yield Right-of-Way'',
        ''Following Too Closely'',
        ''Backing Unsafely'',
        ''Passing or Lane Usage Improper'',
        ''Passing Too Closely'',
        ''Turning Improperly'',
        ''Unsafe Lane Changing'',
        ''Driver Inexperience'',
        ''Failure to Keep Right'',
        ''Traffic Control Disregarded'',
        ''Unsafe Speed'',
        ''Aggressive Driving/Road Rage'',
        ''Reaction to Uninvolved Vehicle'',
        ''Reaction to Other Uninvolved Vehicle'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Electronic Device Distraction''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Cell Phone (hand-held)'',
        ''Cell Phone (hands-free)'',
        ''Using On Board Navigation Device'',
        ''Texting'',
        ''Listening/Using Headphones'',
        ''Other Electronic Device'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Diver Under Influence''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Alcohol Involvement'',
        ''Drugs (Illegal)'',
        ''Prescription Medication'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Street Conditions''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Pavement Defective'',
        ''Pavement Slippery'',
        ''Shoulders Defective/Improper'',
        ''Lane Marking Improper/Inadequate'',
        ''Traffic Control Device Improper/Non-Working'',
        ''Other Lighting Defects'',
        ''Obstruction/Debris'',
        ''Glare'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Driver Fatigue''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Fatigued/Drowsy'',
        ''Fell Asleep'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''Driver Illness''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Lost Consciousness'',
        ''Illness'',
        ''Physical Disability'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

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
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''3rd Party''
        WHERE ' + @ORIG_FULL_COL_NAME + ' IN (''Pedestrian/Bicyclist/Other Pedestrian Error/Confusion'',
        ''Driverless/Runaway Vehicle'',
        ''Vehicle Vandalism'',
        ''Animals Action'')'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

SELECT DISTINCT CONTRIBUTING_FACTORS_1, COUNT(CONTRIBUTING_FACTORS_1) AS NUM_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY CONTRIBUTING_FACTORS_1
ORDER BY NUM_1 DESC

-------------------------------------------------------------------------------
-- Cleaning String Values for vehicle_type --
-------------------------------------------------------------------------------
-- 1002 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC

--Group 1: GOVERNMENT
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%GOV%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%gvt%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%feder%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%city%'

--Group 2: PASSENGER VEHICLE
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE (VEHICLE_TYPE_CODE_1 LIKE '%2%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%4%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Sed%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%PAS%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%SUV%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pick%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%door%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%van%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%wagon%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%RV%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mini%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sprin%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sub%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%jeep%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%winn%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%econo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dodge%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ford%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%navi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%chevy%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cher%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%chev%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%open%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%stree%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%road%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%self%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%niss%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%merc%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%toyo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%coup%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%R/V%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%f15%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ram%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%smart%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sona%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%isuzu%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fusion%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%e-350%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%conve%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%econo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sling%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%wine%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%camp%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%convert%')
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%com%'

--Group 3: CONSTRUCTION
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
    OR VEHICLE_TYPE_CODE_1 LIKE '%hopper%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Tract'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bob%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pallet%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trac'
    OR VEHICLE_TYPE_CODE_1 LIKE '%back%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%glass%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%buck%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%john%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%GATOR%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%esca%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%skid%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%stack%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%exca%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bull%'

-- Group 4: Commercial Vehicle
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE (VEHICLE_TYPE_CODE_1 LIKE '%box%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mack%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mac%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%LADD%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%C0M%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%18%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%15%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%truck%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%semi%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trail%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%flat%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%16%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tail%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%com%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tractor%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%heavy%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%omm%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Stake or Rack%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trk%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Multi-Wheeled Vehicle%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Bulk Agriculture%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%f65%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trl%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%stak%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%work%'
    OR VEHICLE_TYPE_CODE_1 LIKE 'co'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cargo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%f55%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%f45%')
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%PICK%'

--Group 5: Delivery
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
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
    OR VEHICLE_TYPE_CODE_1 LIKE '%del%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%frht%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mail%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cour%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%uspo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%us po%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mov%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fed%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hal%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dhl%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dil%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%MOBIL%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%oil%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%house%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%pump%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%uhua%'

-- Group 6: Public Transportation
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%bus%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%trans%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%nj%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mta%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%port'
    OR VEHICLE_TYPE_CODE_1 LIKE '%scho%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%omni%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%shutt%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%OMT%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%oml%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%omr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%coach%'

-- Group 7: BICYCLE AND PERSONAL MOBILITY DEVICE
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE (VEHICLE_TYPE_CODE_1 LIKE '%bike%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%e-bike%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%electric%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bicycle%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bik%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%bic%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cycle%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%seg%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%skate%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%board%')
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%Mot%'
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%scoot%'
    AND VEHICLE_TYPE_CODE_1 NOT LIKE '%moped%'

-- Group 8: Utility
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%Util%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sweep%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%con e%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%garb%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sanit%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tow%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%plow%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%shovel%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%snow%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%clean%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%street%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%power%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%uli%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%elec%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dot%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%verizon%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%zion%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%acces%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%SKYWATCH%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%park%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%grid%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%UT%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mower%'

-- Group 9: Motorcycle
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%motor%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mop%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%scoot%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%sco%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%vespa%'

-- Group 10: Taxi Or Limo  
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%tax%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%live%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%limo%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cab%'

-- Group 11: Horse Carriage
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%hors%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%carr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hrse%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hosr%'

--Group 12: FOOD
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%ice%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cream%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%food%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ood%'

-- Group 13: All Terrain
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%golf%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%atv%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%utv%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%3-wh%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%jet%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%boat%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%terrain%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%kar%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%dirt%'

-- Group 14: Emergency Vehicle
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%emer%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%fdny%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%nypd%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ambulance%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%army%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%tank%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%emr%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%armor%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%AMB%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%BULA%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%hosp%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%med%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%emt%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%para%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ems%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%amu%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%mbu%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%e.m.s%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ama%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%FD%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Fir%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%engine%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%PD%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%Pol%'


-- Group 15: Unknown
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 NOT IN ('PASSENGER VEHICLE','TAXI OR LIMO','COMMERCIAL VEHICLE', 'PUBLIC TRANSPORTATION', 'MOTORCYCLE', 'EMERGENCY VEHICLE', 'CONSTRUCTION', 'UTILITY', 'DELIVERY', 'ALL TERRAIN', 'GOVERNMENT', 'FOOD')


 -- Group 1: GOVERNMENT   
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''GOVERNMENT''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%GOV%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%gvt%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%feder%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%city%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

--Group 2:PASSENGER_VEHICLE
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''PASSENGER VEHICLE''
        WHERE (' + @FULL_COL_NAME + ' LIKE ''%2%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%4%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%Sed%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%PAS%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%SUV%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%pick%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%pk%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%door%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dr%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%van%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%wagon%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%RV%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mini%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sprin%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sub%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%jeep%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%winn%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%econo%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dodge%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ford%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%navi%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%chevy%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cher%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%chev%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%open%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%stree%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%road%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%self%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%niss%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%merc%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%toyo%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%coup%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%R/V%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%f15%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ram%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%smart%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sona%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%isuzu%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%fusion%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%e-350%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%conve%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%econo%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sling%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%wine%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%camp%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%convert%'')
        AND ' + @FULL_COL_NAME + ' NOT LIKE ''%com%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

--Group 5: Delivery
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''DELIVERY''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%ups%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%fedex%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%fdX%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%uhaul%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ship''
        OR ' + @FULL_COL_NAME + ' LIKE ''%usps%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%post%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%hau%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%freig%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%deliv%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%del%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%frht%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mail%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cour%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%uspo%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%us po%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mov%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%fed%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%hal%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dhl%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dil%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%MOBIL%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%oil%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%house%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%pump%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%uhua%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 6: Public Transportation
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''PUBLIC TRANSPORTATION''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%bus%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%trans%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%nj%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mta%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%port''
        OR ' + @FULL_COL_NAME + ' LIKE ''%scho%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%omni%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%shutt%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%OMT%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%oml%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%omr%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%coach%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 7: BICYCLE AND PERSONAL MOBILITY DEVICE
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''BICYCLE AND PERSONAL MOBILITY DEVICE''
        WHERE (' + @FULL_COL_NAME + ' LIKE ''%electric%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%bicycle%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%bik%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%bic%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cycle%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%seg%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%skate%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%board%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%e-bike%'')
        AND ' + @FULL_COL_NAME + ' NOT LIKE ''%Mot%''
        AND ' + @FULL_COL_NAME + ' NOT LIKE ''%scoot%''
        AND ' + @FULL_COL_NAME + ' NOT LIKE ''%moped%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 8: Utility
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''UTILITY''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%Util%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sweep%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%con e%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sanit%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%tow''
        OR ' + @FULL_COL_NAME + ' LIKE ''%plow%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%shovel%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%snow%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%clean%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%street%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%power%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%elec%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%uli%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dot%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%verizon%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%zion%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%acces%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%SKYWATCH%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%park%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%UT%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mower%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%grid%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 9: Motorcycle
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''MOTORCYCLE''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%motor%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mop%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%scoot%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%sco%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%vespa%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 10: Taxi or Limo
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''TAXI OR LIMO''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%tax%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%live%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%limo%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cab%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 11: Horse Carriage
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''HORSE CARRIAGE''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%hors%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%carr%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%hrse%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%hosr%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

--Group 12: FOOD
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''FOOD''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%ice%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cream%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%food%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ood%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 13: All Terrain
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''ALL TERRAIN''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%golf%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%atv%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%utv%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%3-wh%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%jet%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%boat%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%kar%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%terrain%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%dirt%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 14: Emergency Vehicle
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''EMERGENCY VEHICLE''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%emer%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%fdny%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%nypd%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ambulance%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%army%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%tank%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%emr%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%armor%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%AMB%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%BULA%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%hosp%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%med%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%emt%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%para%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ems%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%amu%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%mbu%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%e.m.s%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ama%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%FD%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%Fir%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%PD%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%Pol%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%engine%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

-- Group 15: Unknown
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP] 
        SET ' + @FULL_COL_NAME + ' = ''UNKNOWN''
        WHERE ' + @FULL_COL_NAME + ' NOT IN (''PASSENGER VEHICLE'',''TAXI OR LIMO'',''COMMERCIAL VEHICLE'', ''PUBLIC TRANSPORTATION'', ''MOTORCYCLE'', ''EMERGENCY VEHICLE'', ''CONSTRUCTION'', ''UTILITY'', ''DELIVERY'', ''ALL TERRAIN'', ''GOVERNMENT'', ''FOOD'') 
        OR ' + @FULL_COL_NAME + ' IS NULL'
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END

SELECT TOP (1000) *
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]

-- Adding Street Corner Column
ALTER TABLE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
ADD STREET_CORNER VARCHAR(MAX)

UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
SET STREET_CORNER = CONCAT(RTRIM(ON_STREET_NAME), ', ', RTRIM(CROSS_STREET_NAME))
WHERE ON_STREET_NAME IS NOT NULL AND CROSS_STREET_NAME IS NOT NULL


select BOROUGH, count(BOROUGH) NUM
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY BOROUGH
ORDER BY NUM

select CRASH_TIME, count(CRASH_TIME) NUM
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY CRASH_TIME
ORDER BY NUM Desc