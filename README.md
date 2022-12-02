# nyc_motor_vehicle_accidents
https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95
Collected Nov 13

- [nyc\_motor\_vehicle\_accidents](#nyc_motor_vehicle_accidents)
  - [**Introduction**](#introduction)
  - [**Exploratory Data Analysis Process**](#exploratory-data-analysis-process)
    - [**Ask**](#ask)
      - [**Guiding Questions**](#guiding-questions)
    - [**Prepare**](#prepare)
      - [**Data Source**](#data-source)
      - [**Data Format**](#data-format)
    - [**Process**](#process)
      - [**Tools Used:**](#tools-used)
      - [**Transform the Data**](#transform-the-data)
    - [**Data Cleaning**](#data-cleaning)
      - [**Cleaning Location Data**](#cleaning-location-data)
      - [**Cleaning String Values: Contributing Factors**](#cleaning-string-values-contributing-factors)
      - [**Data Wrangling: Vehicle Type**](#data-wrangling-vehicle-type)
      - [**Data Wrangling: Contributing Factors**](#data-wrangling-contributing-factors)
    - [Analysis and Findings](#analysis-and-findings)


## **Introduction**
I live in Hoboken, NJ right across the Hudson River from NYC. I have worked in the city and go in for pleasure. My old boss frequently warned our team of the dangers of driving in the city and to always be on the lookout for distracted drivers due to the high number of motor vehicle incidents.

While I don't doubt that NYC has a high number of vehicle incidents, I wanted to use publically available data to find out what factors caused the most unsafe conditions. This is a personal Exploratory Data Analysis of Motor Vehicle Collisions in  New York City from November 2012 - November 2022.

## **Exploratory Data Analysis Process**
### **Ask**
#### **Guiding Questions**
- What are the highest risk times for an accident?
- Where do the most accidents occur?
- What are the most frequently involved vehicles?
- Who is more at risk? Pedestrians, passengers, etc.
- Is there anything I can change about how and when I travel in NYC to have a better chance of a safer experience?

### **Prepare**
#### **Data Source**
NYC Open Data is managed by the Open Data Team at the NYC Office of Technology and Innovation (OTI). The police are required to fill out a report for collisions where someone is injured or killed, or where there is at least $1000 worth of damage. In this project, the data is collected from the [Motor Vehicle Collisions - Crashes](https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95) dataset from July 1, 2012 - November 13, 2022. This information falls under the [Open Data Law](https://opendata.cityofnewyork.us/open-data-law/), and is made available for informational purposes, such as this project.

The visualization portion also utilizes publically available climate data to look for any trends. The NYC climate dataset was retrieved from the [National Centers for Environmental Information](https://www.ncei.noaa.gov/cdo-web/datasets/GHCND/locations/FIPS:36061/detail). The dataset was filtered from July 2012 - November 2022 and downloaded as a CSV file.

#### **Data Format**
The collision data was exported from the [NYC Open Data](https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95) website as a csv. Within it, are 29 columns of varying data types such as crash date, time, location, and additional collision information. The data set does not include any personal information that can be tied to those in the incident.

### **Process**
#### **Tools Used:**
 - **SQL Server:** Database used to store the large dataset
 - **TSQL:** Cleaned and aggregated the dataset
 - **Power BI:** Visualize findings

#### **Transform the Data**
I did not want to alter the raw data, so I created a new table with the same information named *VEHICLE_COLLISIONS_TEMP*.

```sql
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
```
Verified that there were no errors in copying the data.
```sql
--Confirmed all data appears to have been transferred to temp table
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
EXCEPT
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
```
### **Data Cleaning**
#### **Cleaning Location Data**

I found that some of the *ZIP_CODE* values were null, so I used a **join** within the table, cross referencing *ON_STREET_NAME* with *CROSS_STREET_NAME*. Afterwards, the values that matched were populated with the relevant zip codes. **This reduced null zipcodes by 6,530.**

```sql
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

-- 597452 ZIP_CODE NULL values, reduced NULL values by 6530
SELECT COUNT(*)
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE ZIP_CODE IS NULL
```
Because my analysis would require some form of location data, I removed the rows without any location data available. **48,885 rows were removed.**

```sql
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
```
Finally, I concatenated the *ON_STREET* and *CROSS_STREET* into *STREET_CORNER*. I did this because I wanted to visualize the top 10 street corners that collisions occur on.
```sql
-- Adding Street Corner Column
ALTER TABLE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
ADD STREET_CORNER VARCHAR(MAX)

UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
SET STREET_CORNER = CONCAT(RTRIM(ON_STREET_NAME), ', ', RTRIM(CROSS_STREET_NAME))
WHERE ON_STREET_NAME IS NOT NULL AND CROSS_STREET_NAME IS NOT NULL
```
#### **Cleaning String Values: Contributing Factors**
One of the factors was "Illness". However, some were found to be misspelled as "Illnes". To correct this, I replaced all misspelled factors.
```sql
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
```
To make sure that the contributing factors were the same throughout all 5 columns, I compared the columns to see if there were any differences.
```sql
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_1 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_2 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_3 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_4 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
EXCEPT
SELECT DISTINCT CONTRIBUTING_FACTOR_VEHICLE_5 FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
```

#### **Data Wrangling: Vehicle Type**
Because the officers can input unstructured text for every vehicle type, there were a lot of different vehicle types recorded, many of which were misspelled or impossible to decipher.

Prior to wrangling, there were 1,002 different vehicle types recorded.
```sql
-- 1002 RESULTS
SELECT VEHICLE_TYPE_CODE_1, COUNT(VEHICLE_TYPE_CODE_1) NUM
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
GROUP BY VEHICLE_TYPE_CODE_1
ORDER BY NUM DESC
```
The vehicle types were sorted into 15 vehicle types:
-  Unknown
-  All Terrain
-  Commercial Vehicle
-  Emergency Vehicle
-  Food
-  Delivery
-  Construction
-  Public Transportaion
-  Government
-  Passenger Vehicle
-  Taxi or Limo
-  Utility
-  Motorcycle
-  Bicycle or Personal Mobility Device
-  Horse Carriage

For every group, I initially checked what the returned values were. This ensured that the correct values were being sorted and that I wasn't accidentally sorting the wrong values. For instance, if I were to find all *VEHICLE_TYPE_CODE_1* values that are *LIKE* %con% to sort those into the construction group, I would also find convertible. Manually checking the returned values prior to altering the table ensured that I didn't make any mistakes like that when sorting. 

Here is an example of how I verified that the returned values were what I wanted to sort.
```sql
SELECT DISTINCT VEHICLE_TYPE_CODE_1
FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
WHERE VEHICLE_TYPE_CODE_1 LIKE '%ice%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%cream%'
    OR VEHICLE_TYPE_CODE_1 LIKE '%ood%'
```
After verifying each group, the vehicle types were sorted into their respective groups using while loops to sort through 5 seperate columns. 
```sql
--Group 12: FOOD
DECLARE @sql varchar(MAX)
DECLARE @COUNT SMALLINT = 1
DECLARE @COLUMN_NAME VARCHAR(MAX) = 'VEHICLE_TYPE_CODE_'
DECLARE @FULL_COL_NAME VARCHAR(MAX)
WHILE @COUNT < 6
BEGIN
    SET @FULL_COL_NAME = @COLUMN_NAME + CAST (@COUNT AS VARCHAR)
    SET @sql = 'UPDATE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP_TABLE] 
        SET ' + @FULL_COL_NAME + ' = ''FOOD''
        WHERE ' + @FULL_COL_NAME + ' LIKE ''%ice%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%cream%''
        OR ' + @FULL_COL_NAME + ' LIKE ''%ood%'''
    EXEC(@sql)
    SET @COUNT = @COUNT + 1
END
```
Null values were kept as-is and anything that hadn't been sorted was set as an unknown vehicle type.

#### **Data Wrangling: Contributing Factors**
At first, there were 59 different contributing factors for collisions. For concise analysis and easy visualization, I  sorted the factors into 10 different groups:
- Unspecified
- Driver Fatigue
- Electronic Device Distraction
- 3rd Party
- Driver Error
- Driver Distracted
- Driver Illness
- Vehicle Defective
- Diver Under Influence
- Street Conditions

I added new columns for each *CONTRIBUTING_FACTOR_VEHICLE_X* column to sort the factors into.
```sql
ALTER TABLE [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
ADD 
    CONTRIBUTING_FACTORS_1 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_2 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_3 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_4 VARCHAR(MAX),
    CONTRIBUTING_FACTORS_5 VARCHAR(MAX)
```
For every contributing factor grouping, I initiated a while loop to sort for the factors throughout all 5 columns. Below is an example of how I sorted for 'Driver Distracted'.
```sql
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
```

### Analysis and Findings
After I was satisfied with the data, I loaded this table into Power BI. The aggregated and visualized data can be found [here](https://github.com/allamlobna/nyc_motor_vehicle_accidents/blob/main/NYC_MOTOR_VEHICLE_COLLISIONS.pdf).

