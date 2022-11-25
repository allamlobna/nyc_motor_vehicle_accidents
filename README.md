# nyc_motor_vehicle_accidents
https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95
Collected Nov 13



## **Introduction**
I live in Hoboken, NJ right across the Hudson River from NYC. I have worked in the city and frequently go in for pleasure. My old boss frequently warned our team of the dangerous of driving in the city and to always be on the lookout for distracted drivers due to the high number of motor vehicle incidents.

While I don't doubt that NYC has a high number of vehicle incidents, I wanted to use publically available data to find out what factors caused the most unsafe conditions. This is a personal Exploratory Data Analysis of Motor Vehicle Collisions in  New York City from November 2012 - Novemeber 2022.

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
NYC Open Data is managed by the Open Data Team at the NYC Office of Technology and Innovation (OTI). The police are required to fill out a report out for collisions where someone is injured or killed, or where there is at least $1000 worth of damage. In this project, the data is collected from the [Motor Vehicle Collisions - Crashes](https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95) dataset from July 1, 2012 - November 13, 2022. This infomration falls under the [Open Data Law](https://opendata.cityofnewyork.us/open-data-law/), and is made available for imformational purposes, such as this project.

#### **Data Format**
The data was exported from the [NYC OpenData](https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95) website as a csv. Within it, are 29 columns of varying data types such as crash date, time, location, and additional collision information. The data set does not include any personal information that can be tied to those in the incident.

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
Verified that there were no errors in copying the data:
```sql
--Confirmed all data appears to have been transferred to temp table
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[Motor_Vehicle_Collisions_Crashes]
EXCEPT
SELECT * FROM [nyc_motor_vehicle_collisions].[dbo].[VEHICLE_COLLISIONS_TEMP]
```
### **Data Cleaning**
#### **Cleaning Location Data**

I found that some of the *ZIP_CODE* values were null, so I used a **join** within the table, cross referencing *ON_STREET_NAME* with *CROSS_STREET_NAME*. Afterwards, the values that matched, were populated with the relevant zip codes. **This reduced null zipcodes by 6,530.**

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

-- 597452 ZIP_CODE NULL values, reduced NULL values by 6285
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
#### **Cleaning String Values**
If *CONTRIBUTING_FACTOR_VEHICLE_1* is 'Unspecified', then others are unspecified or null
```sql
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
```
One of the factors was "Illness". However, some were found to be misspelled as "Illnes". To correct this, I replaced all misspelled factors:
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
To make sure that the contributing factors that were used were the same throughout all columns, I compared the columns to check if there were any differences.
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
At first, there were over 60 different











Messy Strings
For CONTRIBUTING_FACTOR_VEHICLE_1:
Illness	2088
Illnes	1440
cleaned to make them all illness

95 instances of "80" and 10 instances of "1". Changed to unspecified

Reduced different groups of contributing factors
initially, there were 59 different kinds of contributing factors
Changes made:
Unspecified: Added 80, 1
Driver Distracted: Driver Inattention/Distraction, 
